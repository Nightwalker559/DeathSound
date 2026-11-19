-- DeathSound - DeathOverlay.lua
-- Death overlay (own character) and group emote (party members): logic and public API.
-- Initialised by DeathSound.lua (ns.InitOverlays); the settings tabs (UI\EmoteTab.lua,
-- UI\GroupTab.lua) use the ns.* functions exported at the end of this file.

local _, ns = ...
local L      = ns.L
local PREFIX = ns.PREFIX

local IMAGE_PATH        = "Interface\\AddOns\\DeathSound\\Media\\Images\\"
local PARTY_MAX_SIZE_TB = 96   -- max px for top/bottom
local PREVIEW_SECONDS   = 6

for k, v in pairs({
    overlayAnchorToPopup  = false,
    overlayEnabled        = false,
    overlayImageName      = "",   -- saved name of the selected emote image
    overlayLocked         = true,
    overlayPoint          = "CENTER",
    overlayRandom         = false,
    overlaySize           = 64,   -- px, square
    overlayX              = 0,
    overlayY              = 0,
    -- Party Overlay
    partyOverlayAnchor    = "LEFT",  -- LEFT | RIGHT | TOP | BOTTOM
    partyOverlayEnabled   = false,
    partyOverlayImageName = "",   -- saved name of the selected party emote image
    partyOverlayOffset    = 4,       -- px gap between emote and party frame
    partyOverlayRandom    = false,
}) do
    ns.defaults[k] = v
end

-- Party emote: side of the party frame -> anchor points and direction of the gap
local PARTY_ANCHORS = {
    LEFT   = { point = "RIGHT",  relPoint = "LEFT",   x = -1, y = 0 },
    RIGHT  = { point = "LEFT",   relPoint = "RIGHT",  x = 1,  y = 0 },
    TOP    = { point = "BOTTOM", relPoint = "TOP",    x = 0,  y = 1, vertical = true },
    BOTTOM = { point = "TOP",    relPoint = "BOTTOM", x = 0,  y = -1, vertical = true },
}
local PARTY_SLOT = { party1 = 1, party2 = 2, party3 = 3, party4 = 4 }

-- Module state
local overlayFrame   = nil
local overlayTexture = nil
local overlayBorder  = nil
local partyFrames    = {}   -- [1..4] = overlay frame (with .tex) for party1..party4
local partyTestTimer = nil  -- handle of the running party preview timer
local partyUpdatePending = false

-- ============================================================
-- Images
-- ============================================================

local function EntryPath(entry)
    return entry and (IMAGE_PATH .. entry.file)
end

local function ImageTexturePath(name)
    return EntryPath(ns.ResolveEntry(ns.ImageList, name))
end

-- Picks a random image (never the same as last time) and saves the name under `key`.
local function PickRandomImage(key)
    local db, list = DeathSoundDB, ns.ImageList
    if #list <= 1 then return end
    db[key] = list[ns.PickRandomIndex(#list, ns.ResolveIndex(list, db[key]))].name
end

-- ============================================================
-- Overlay logic
-- ============================================================

local function SavePosition()
    local db = DeathSoundDB
    local point, _, _, x, y = overlayFrame:GetPoint(1)
    db.overlayPoint = point
    db.overlayX     = math.floor(x)
    db.overlayY     = math.floor(y)
end

local function ApplyImage()
    overlayTexture:SetTexture(ImageTexturePath(DeathSoundDB.overlayImageName))
end

local function SetEditMode(enabled)
    DeathSoundDB.overlayLocked = not enabled
    overlayFrame:SetMovable(enabled)
    overlayFrame:EnableMouse(enabled)
    overlayBorder:SetShown(enabled)
end

-- Anchors the overlay to the "Release Spirit" popup (to its left, size = popup height).
-- The popup is not necessarily StaticPopup1 (e.g. when another popup is already open).
-- Returns the applied size, or nil when the popup is not shown.
local function AnchorToPopup()
    local _, popup = StaticPopup_Visible("DEATH")
    if not popup then return nil end
    local size = math.floor(popup:GetHeight())
    overlayFrame:SetSize(size, size)
    overlayFrame:ClearAllPoints()
    overlayFrame:SetPoint("RIGHT", popup, "LEFT", -8, 0)
    return size
end

local function ApplySavedPosition()
    local db = DeathSoundDB
    overlayFrame:SetSize(db.overlaySize, db.overlaySize)
    overlayFrame:ClearAllPoints()
    overlayFrame:SetPoint(db.overlayPoint, UIParent, db.overlayPoint, db.overlayX, db.overlayY)
end

-- Popup anchor if wanted and the popup is open, otherwise the saved position
local function PlaceOverlay()
    if not (DeathSoundDB.overlayAnchorToPopup and AnchorToPopup()) then
        ApplySavedPosition()
    end
end

local function ShowOverlay()
    local db = DeathSoundDB
    if not (db.enabled and db.overlayEnabled) or #ns.ImageList == 0 then return end

    if db.overlayRandom then PickRandomImage("overlayImageName") end
    ApplyImage()

    -- Always end edit mode on a real death
    SetEditMode(false)
    PlaceOverlay()
    overlayFrame:Show()

    if db.overlayAnchorToPopup then
        -- Blizzard fills the DEATH popup text deferred, which changes its height. Re-anchor in the
        -- next frame; if the size is still the placeholder size (or the popup is not up yet), the
        -- text was not set by then and a short timer catches it.
        local shownSize = math.floor(overlayFrame:GetWidth())
        RunNextFrame(function()
            local size = AnchorToPopup()
            if not size or size == shownSize then C_Timer.After(0.15, AnchorToPopup) end
        end)
    end
end

-- Hide on revive unless edit mode is open
local function HideOverlay()
    if not DeathSoundDB.overlayLocked then return end
    overlayFrame:Hide()
end

-- Lock/unlock button: edit mode shows the overlay for dragging, locking hides it again
-- (unless the character is dead and the overlay belongs to that death).
local function ToggleEditMode()
    local unlocking = DeathSoundDB.overlayLocked
    SetEditMode(unlocking)
    if unlocking then
        ApplyImage()
        overlayFrame:Show()
    elseif not ns.isDead then
        overlayFrame:Hide()
    end
end

local function ResetPosition()
    local db = DeathSoundDB
    db.overlayPoint = "CENTER"
    db.overlayX     = 0
    db.overlayY     = 0
    ApplySavedPosition()
end

-- Clamps, saves and applies the overlay size; returns the value that was set.
local function SetOverlaySize(val)
    val = math.floor(math.min(128, math.max(32, val)))
    DeathSoundDB.overlaySize = val
    overlayFrame:SetSize(val, val)
    return val
end

local function CreateOverlayFrame()
    overlayFrame = CreateFrame("Frame", "DeathSoundOverlayFrame", UIParent)
    overlayFrame:SetFrameStrata("MEDIUM")
    overlayFrame:SetClampedToScreen(true)
    ApplySavedPosition()
    overlayFrame:RegisterForDrag("LeftButton")
    overlayFrame:SetScript("OnDragStart", function(self) self:StartMoving() end)
    overlayFrame:SetScript("OnDragStop",  function(self)
        self:StopMovingOrSizing()
        SavePosition()
    end)
    -- The mouse is only enabled in edit mode, so the tooltip only shows there
    ns.SetTooltip(overlayFrame, L("OVERLAY_DRAG_TIP"), "ANCHOR_TOP")
    overlayFrame:Hide()

    overlayTexture = overlayFrame:CreateTexture(nil, "ARTWORK")
    overlayTexture:SetAllPoints()
    overlayTexture:SetBlendMode("BLEND")

    overlayBorder = CreateFrame("Frame", nil, overlayFrame, "BackdropTemplate")
    overlayBorder:SetAllPoints()
    overlayBorder:SetBackdrop({
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        edgeSize = 8,
    })
    overlayBorder:SetBackdropBorderColor(0, 0.8, 1, 0.9)

    ApplyImage()
    SetEditMode(false)   -- edit mode does not persist across /reload (the overlay is hidden here)
end

-- ============================================================
-- Party overlay logic
-- ============================================================

-- Sources of the group frames in priority order: ElvUI, the raid-style party
-- (CompactPartyFrame) and PartyFrame.MemberFrame1..4. Frames are named <prefix>1..count and live
-- in `parent()` (otherwise _G).
local PARTY_SOURCES = {
    { prefix = "ElvUF_PartyGroup1UnitButton", count = 5, available = function() return ElvUI end },
    { prefix = "CompactPartyFrameMember",     count = 5,
      available = function() return CompactPartyFrame and CompactPartyFrame:IsShown() end },
    { prefix = "MemberFrame",                 count = 4, parent = function() return PartyFrame end,
      available = function() return PartyFrame and PartyFrame:IsShown() end },
}

-- The visible frame number i of a source, or nil.
local function SourceFrame(source, i)
    local parent = source.parent and source.parent() or _G
    local f = parent[source.prefix .. i]
    if f and f:IsShown() then return f end
end

-- Returns the party frame for slot 1-4 (unit "party<slot>"), or nil.
-- Matching is done by unit, not by frame index: ElvUI and CompactPartyFrame
-- can show the player too, which shifts the positions.
local function GetPartyFrame(slot)
    local unit = "party" .. slot
    for _, source in ipairs(PARTY_SOURCES) do
        if source.available() then
            for i = 1, source.count do
                local f = SourceFrame(source, i)
                if f and f.unit and UnitIsUnit(f.unit, unit) then return f end
            end
        end
    end
end

-- Creates the 4 party overlay frames once.
local function CreatePartyOverlayFrames()
    for i = 1, 4 do
        local f = CreateFrame("Frame", "DeathSoundPartyOverlay" .. i, UIParent)
        f:SetFrameStrata("MEDIUM")
        f:SetSize(64, 64)
        f:Hide()

        f.tex = f:CreateTexture(nil, "ARTWORK")
        f.tex:SetAllPoints()
        f.tex:SetBlendMode("BLEND")

        partyFrames[i] = f
    end
end

-- Sets the image (by name) on a party overlay.
local function SetPartyImage(frame, name)
    frame.imageName = name
    frame.tex:SetTexture(ImageTexturePath(name))
end

-- Sets the saved image on all party overlays (dropdown selection).
local function ApplyPartyImage()
    for i = 1, 4 do
        SetPartyImage(partyFrames[i], DeathSoundDB.partyOverlayImageName)
    end
end

-- Image name for a party overlay: the selected image, or with "Random" an own image per
-- member. Random never picks the last chosen one or one that is currently shown on another
-- party overlay (as long as the list is big enough).
local function PickPartyImageName(frame)
    local db, list = DeathSoundDB, ns.ImageList
    if not db.partyOverlayRandom or #list <= 1 then return db.partyOverlayImageName end

    local used = { [db.partyOverlayImageName] = true }
    for _, other in ipairs(partyFrames) do
        if other ~= frame and other:IsShown() and other.imageName then used[other.imageName] = true end
    end
    local pool = {}
    for _, entry in ipairs(list) do
        if not used[entry.name] then pool[#pool + 1] = entry end
    end
    if #pool == 0 then pool = list end

    local name = pool[math.random(#pool)].name
    db.partyOverlayImageName = name   -- "last chosen"; the preview in the panel shows it
    return name
end

-- Sets size and anchor of the party emote relative to the party frame and shows it.
local function PositionPartyOverlay(frame, partyFrame)
    local db     = DeathSoundDB
    local anchor = PARTY_ANCHORS[db.partyOverlayAnchor] or PARTY_ANCHORS.LEFT
    local size
    if anchor.vertical then
        size = math.min(math.floor(partyFrame:GetWidth()), PARTY_MAX_SIZE_TB)
    else
        size = math.floor(partyFrame:GetHeight())
    end
    local off = db.partyOverlayOffset

    frame:SetSize(size, size)
    frame:ClearAllPoints()
    frame:SetPoint(anchor.point, partyFrame, anchor.relPoint, anchor.x * off, anchor.y * off)
    frame:Show()
end

-- True in a raid group OR in a raid instance. The latter is needed because
-- e.g. with two players in a raid the group stays a normal party (IsInRaid() = false).
local function IsInRaidContent()
    if IsInRaid() then return true end
    local _, instanceType = IsInInstance()
    return instanceType == "raid"
end

-- Shows or hides the party overlay for a given slot.
local function UpdatePartyOverlay(slot)
    local db    = DeathSoundDB
    local frame = partyFrames[slot]
    local unit  = "party" .. slot

    -- UNIT_HEALTH fires often: cheap checks first, unit death before the raid query
    local partyFrame
    if db.enabled and db.partyOverlayEnabled and UnitIsDeadOrGhost(unit)
        and UnitExists(unit) and UnitIsConnected(unit) and not IsInRaidContent() then
        partyFrame = GetPartyFrame(slot)
    end
    if not partyFrame then
        frame:Hide()
        return
    end

    -- On death (frame was still hidden) pick the image for exactly this slot
    if not frame:IsShown() then
        SetPartyImage(frame, PickPartyImageName(frame))
    end
    PositionPartyOverlay(frame, partyFrame)
end

local function UpdateAllPartyOverlays()
    for i = 1, 4 do
        UpdatePartyOverlay(i)
    end
end

-- Group/zone changes come bundled; the Blizzard party frames are only updated in the same
-- frame after the event -> evaluate once in the next frame.
local function ScheduleUpdateAllPartyOverlays()
    if partyUpdatePending then return end
    partyUpdatePending = true
    RunNextFrame(function()
        partyUpdatePending = false
        UpdateAllPartyOverlays()
    end)
end

-- All visible frames of the first source that has any (max. 4), also without a group: ElvUI can
-- show the group solo, Blizzard in Edit Mode (there with the player as a placeholder).
local function GetPreviewFrames()
    local out = {}
    for _, source in ipairs(PARTY_SOURCES) do
        if source.available() then
            for i = 1, source.count do
                local f = SourceFrame(source, i)
                if f and #out < 4 then out[#out + 1] = f end
            end
            if #out > 0 then break end
        end
    end
    return out
end

-- Test button: show the emote on all visible group frames (with Random, each frame gets its own image)
local function PreviewPartyOverlays()
    if #ns.ImageList == 0 then
        print(PREFIX .. L("DD_NO_IMAGES"))
        return
    end

    local targets = GetPreviewFrames()
    if #targets == 0 then
        print(PREFIX .. L("MSG_NO_PARTY"))
        return
    end

    for i = 1, 4 do partyFrames[i]:Hide() end
    for i, partyFrame in ipairs(targets) do
        local frame = partyFrames[i]
        SetPartyImage(frame, PickPartyImageName(frame))
        PositionPartyOverlay(frame, partyFrame)
    end

    -- After the preview, reset to the real state (a running timer is replaced)
    if partyTestTimer then partyTestTimer:Cancel() end
    partyTestTimer = C_Timer.NewTimer(PREVIEW_SECONDS, function()
        partyTestTimer = nil
        UpdateAllPartyOverlays()
    end)
end

-- ============================================================
-- Init / Events
-- ============================================================

-- Called by DeathSound.lua after the DB init and before the options panel.
function ns.InitOverlays()
    CreateOverlayFrame()
    CreatePartyOverlayFrames()

    local f = CreateFrame("Frame")
    -- UNIT_HEALTH only for the party units (otherwise it fires for every unit in the raid/nameplates)
    f:RegisterUnitEvent("UNIT_HEALTH", "party1", "party2", "party3", "party4")
    f:RegisterEvent("GROUP_ROSTER_UPDATE")
    f:RegisterEvent("PLAYER_ENTERING_WORLD")
    f:SetScript("OnEvent", function(_, event, unit)
        if event == "UNIT_HEALTH" then
            local slot = PARTY_SLOT[unit]
            if slot then UpdatePartyOverlay(slot) end
        else
            ScheduleUpdateAllPartyOverlays()
        end
    end)
end

-- ============================================================
-- Public API (settings tabs, DeathSound.lua)
-- ============================================================

ns.ShowDeathOverlay         = ShowOverlay
ns.HideDeathOverlay         = HideOverlay
ns.ToggleOverlayEditMode    = ToggleEditMode
ns.ResetOverlayPosition     = ResetPosition
ns.SetOverlaySize           = SetOverlaySize
ns.ApplyImage               = ApplyImage
ns.PickRandomImage          = PickRandomImage
ns.ImagePath                = EntryPath
ns.ApplyPartyImage          = ApplyPartyImage
ns.PreviewPartyOverlays     = PreviewPartyOverlays
ns.UpdateAllPartyOverlays   = UpdateAllPartyOverlays
