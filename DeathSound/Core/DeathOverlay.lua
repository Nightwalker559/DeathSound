-- DeathSound - DeathOverlay.lua
-- Death overlay (own character) and group emote (party members).
-- Initialised by DeathSound.lua (ns.InitOverlays); only calls ns helpers from there.

local _, ns = ...
local L      = ns.L
local PREFIX = ns.PREFIX

local IMAGE_PATH        = "Interface\\AddOns\\DeathSound\\Media\\Images\\"
local PARTY_MAX_SIZE_TB = 96   -- max px for top/bottom
local PREVIEW_SECONDS   = 6

for k, v in pairs({
    overlayAnchorToPopup  = false,
    overlayEnabled        = false,
    overlayHeight         = 64,
    overlayImageName      = "",   -- saved name of the selected emote image
    overlayLocked         = true,
    overlayPoint          = "CENTER",
    overlayRandom         = false,
    overlayWidth          = 64,
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
local function AnchorToPopup()
    local _, popup = StaticPopup_Visible("DEATH")
    if not popup then return false end
    local size = math.floor(popup:GetHeight())
    overlayFrame:SetSize(size, size)
    overlayFrame:ClearAllPoints()
    overlayFrame:SetPoint("RIGHT", popup, "LEFT", -8, 0)
    return true
end

local function ApplySavedPosition()
    local db = DeathSoundDB
    overlayFrame:SetSize(db.overlayWidth, db.overlayHeight)
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
        -- The DEATH popup text is set deferred and changes the height
        C_Timer.After(0.15, AnchorToPopup)
    end
end

-- Hide on revive unless edit mode is open
local function HideOverlay()
    if not DeathSoundDB.overlayLocked then return end
    overlayFrame:Hide()
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

ns.ShowDeathOverlay = ShowOverlay
ns.HideDeathOverlay = HideOverlay

-- ============================================================
-- Options Section Builder
-- ============================================================

local COL_WIDTH = ns.COL_WIDTH
local PREVIEW_X = 390   -- preview column to the right of the settings

-- Preview box of the selected image; returns an update function.
local function CreatePreview(parent, getName)
    local hdr = ns.CreateHeader(parent, L("SECTION_PREVIEW"), 150)
    hdr:SetPoint("TOPLEFT", parent, "TOPLEFT", PREVIEW_X, 0)

    local box = CreateFrame("Frame", nil, parent, "BackdropTemplate")
    box:SetSize(150, 150)
    box:SetPoint("TOPLEFT", hdr, "BOTTOMLEFT", 0, -10)
    box:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    box:SetBackdropColor(0, 0, 0, 0.35)
    box:SetBackdropBorderColor(0.4, 0.4, 0.4, 0.8)

    local tex = box:CreateTexture(nil, "ARTWORK")
    tex:SetSize(128, 128)
    tex:SetPoint("CENTER")

    local caption = ns.CreateHint(parent, "", 150)
    caption:SetPoint("TOPLEFT", box, "BOTTOMLEFT", 0, -4)

    return function()
        local entry = ns.ResolveEntry(ns.ImageList, getName())
        tex:SetTexture(EntryPath(entry))
        caption:SetText(entry and entry.name or "")
    end
end

function ns.BuildOverlaySection(imageFrame)
    local db = DeathSoundDB
    local UpdatePopupMode, UpdateRandomMode, UpdateLockBtn, UpdatePreview  -- forward declarations

    -- ---- Image ----
    local hdrImage = ns.CreateHeader(imageFrame, L("SECTION_IMAGE"), COL_WIDTH)
    hdrImage:SetPoint("TOPLEFT", imageFrame, "TOPLEFT", 0, 0)

    local enableCB = ns.CreateCheckBox(imageFrame, "DeathSoundOverlayCB", L("OPT_OVERLAY_ENABLE"),
        L("OPT_OVERLAY_ENABLE_TOOLTIP"), db.overlayEnabled,
        function(self) db.overlayEnabled = self:GetChecked() end)
    enableCB:SetPoint("TOPLEFT", hdrImage, "BOTTOMLEFT", 0, -10)

    local dd = ns.CreateListDropdown(imageFrame, "DeathSoundImageDropdown", ns.ImageList, L("DD_NO_IMAGES"),
        function() return db.overlayImageName end,
        function(entry)
            db.overlayImageName = entry.name
            ApplyImage()
            UpdatePreview()
        end)
    dd:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 4, -8)

    -- Test button: with "Random" picks a new image and shows it in the preview (not on screen)
    local testEmoteBtn = ns.CreateButton(imageFrame, "DeathSoundTestEmoteButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_TEST_EMOTE_TOOLTIP"),
        function()
            PickRandomImage("overlayImageName")
            ApplyImage()
            UpdatePreview()
        end)
    testEmoteBtn:SetPoint("LEFT", dd, "RIGHT", 8, 0)

    local randomEmoteCB = ns.CreateCheckBox(imageFrame, "DeathSoundRandomEmoteCB", L("OPT_RANDOM"), nil,
        db.overlayRandom,
        function(self)
            db.overlayRandom = self:GetChecked()
            UpdateRandomMode()
        end)
    randomEmoteCB:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", -4, -6)
    local randomHint = ns.CreateHint(imageFrame, L("OPT_RANDOM_EMOTE_TOOLTIP"), COL_WIDTH - 26)
    randomHint:SetPoint("TOPLEFT", randomEmoteCB, "BOTTOMLEFT", 26, 0)

    -- ---- Position and size ----
    local hdrPos = ns.CreateHeader(imageFrame, L("SECTION_POSITION"), COL_WIDTH)
    hdrPos:SetPoint("TOPLEFT", randomHint, "BOTTOMLEFT", -26, -22)

    local popupCB = ns.CreateCheckBox(imageFrame, "DeathSoundPopupCB", L("OPT_OVERLAY_ANCHOR_POPUP"),
        L("OPT_OVERLAY_ANCHOR_POPUP_TIP"), db.overlayAnchorToPopup,
        function(self)
            db.overlayAnchorToPopup = self:GetChecked()
            UpdatePopupMode()
        end)
    popupCB:SetPoint("TOPLEFT", hdrPos, "BOTTOMLEFT", 0, -10)
    local popupHint = ns.CreateHint(imageFrame, L("HINT_POPUP_MODE"), COL_WIDTH - 26)
    popupHint:SetPoint("TOPLEFT", popupCB, "BOTTOMLEFT", 26, 0)

    local sizeLabel = ns.CreateLabel(imageFrame, L("OPT_OVERLAY_SIZE"))
    sizeLabel:SetPoint("TOPLEFT", popupCB, "BOTTOMLEFT", 4, -26)

    local sizeBox = ns.CreateNumberBox(imageFrame, "DeathSoundSizeBox", 60, 3,
        function() return db.overlayWidth end,
        function(val)
            val = math.floor(math.min(128, math.max(32, val)))
            db.overlayWidth  = val
            db.overlayHeight = val
            overlayFrame:SetSize(val, val)
            return val
        end)
    sizeBox:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)

    local pxLabel = ns.CreateLabel(imageFrame, L("OPT_OVERLAY_SIZE_UNIT"), "GameFontDisableSmall")
    pxLabel:SetPoint("LEFT", sizeBox, "RIGHT", 6, 0)

    -- ---- Lock/Unlock Button ----
    local lockBtn = ns.CreateButton(imageFrame, "DeathSoundLockButton", 150, 26, "",
        function() return db.overlayLocked and L("OPT_OVERLAY_UNLOCK_TIP") or L("OPT_OVERLAY_LOCK_TIP") end,
        function()
            local nowUnlocking = db.overlayLocked
            SetEditMode(nowUnlocking)
            if nowUnlocking then
                ApplyImage()
                overlayFrame:Show()
            elseif not ns.isDead then
                overlayFrame:Hide()
            end
            UpdateLockBtn()
        end)
    lockBtn:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", -4, -14)

    -- ---- Reset Position Button ----
    local resetBtn = ns.CreateButton(imageFrame, "DeathSoundResetButton", 150, 26,
        L("OPT_OVERLAY_RESET"), L("OPT_OVERLAY_RESET_TIP"),
        function()
            db.overlayPoint = "CENTER"
            db.overlayX     = 0
            db.overlayY     = 0
            ApplySavedPosition()
        end)
    resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)

    -- ---- Preview and file hint ----
    UpdatePreview = CreatePreview(imageFrame, function() return db.overlayImageName end)
    ns.CreateFooter(imageFrame, L("HINT_FILES_IMAGE"))

    UpdateLockBtn = function()
        lockBtn:SetText(db.overlayLocked and L("OPT_OVERLAY_UNLOCK") or L("OPT_OVERLAY_LOCK"))
    end

    -- Death ends edit mode and Random changes the image -> refresh when the tab is shown
    imageFrame:SetScript("OnShow", function()
        UpdateLockBtn()
        UpdatePreview()
    end)

    -- ---- Mode-dependent dimming (defined after all widgets) ----
    UpdatePopupMode = function()
        local anchored = db.overlayAnchorToPopup
        for _, widget in ipairs({ sizeBox, sizeLabel, pxLabel, lockBtn, resetBtn }) do
            ns.SetDimmed(widget, anchored)
        end
        popupHint:SetShown(anchored)
    end

    -- The Random checkbox also dims the dropdown (the selection is irrelevant with Random)
    UpdateRandomMode = function()
        ns.SetDimmed(dd, db.overlayRandom)
        testEmoteBtn:SetEnabled(db.overlayRandom)
    end

    UpdateLockBtn()
    UpdatePreview()
    UpdateRandomMode()
    UpdatePopupMode()
end

-- ============================================================
-- Party Section Builder (own tab)
-- ============================================================

function ns.BuildPartySection(groupFrame)
    local db = DeathSoundDB
    local UpdatePreview, UpdateRandomMode  -- forward declarations

    -- ---- Group emote ----
    local hdrParty = ns.CreateHeader(groupFrame, L("SECTION_PARTY"), COL_WIDTH)
    hdrParty:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 0, 0)

    local partyCB = ns.CreateCheckBox(groupFrame, "DeathSoundPartyCB", L("OPT_PARTY_ENABLE"),
        L("OPT_PARTY_ENABLE_TOOLTIP"), db.partyOverlayEnabled,
        function(self)
            db.partyOverlayEnabled = self:GetChecked()
            UpdateAllPartyOverlays()
        end)
    partyCB:SetPoint("TOPLEFT", hdrParty, "BOTTOMLEFT", 0, -10)

    local partyDD = ns.CreateListDropdown(groupFrame, "DeathSoundPartyDropdown", ns.ImageList, L("DD_NO_IMAGES"),
        function() return db.partyOverlayImageName end,
        function(entry)
            db.partyOverlayImageName = entry.name
            ApplyPartyImage()
            UpdatePreview()
        end)
    partyDD:SetPoint("TOPLEFT", partyCB, "BOTTOMLEFT", 4, -8)

    local partyTestBtn = ns.CreateButton(groupFrame, "DeathSoundPartyTestButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_PARTY_TEST_TOOLTIP"),
        function()
            PreviewPartyOverlays()
            UpdatePreview()
        end)
    partyTestBtn:SetPoint("LEFT", partyDD, "RIGHT", 8, 0)

    local partyRandomCB = ns.CreateCheckBox(groupFrame, "DeathSoundPartyRandomCB", L("OPT_RANDOM"), nil,
        db.partyOverlayRandom,
        function(self)
            db.partyOverlayRandom = self:GetChecked()
            UpdateRandomMode()
        end)
    partyRandomCB:SetPoint("TOPLEFT", partyDD, "BOTTOMLEFT", -4, -6)
    local randomHint = ns.CreateHint(groupFrame, L("OPT_PARTY_RANDOM_TOOLTIP"), COL_WIDTH - 26)
    randomHint:SetPoint("TOPLEFT", partyRandomCB, "BOTTOMLEFT", 26, 0)

    -- ---- Position ----
    local hdrPos = ns.CreateHeader(groupFrame, L("SECTION_PARTY_POSITION"), COL_WIDTH)
    hdrPos:SetPoint("TOPLEFT", randomHint, "BOTTOMLEFT", -26, -22)

    local anchorLabel = ns.CreateLabel(groupFrame, L("OPT_PARTY_ANCHOR"), nil, 100)
    anchorLabel:SetPoint("TOPLEFT", hdrPos, "BOTTOMLEFT", 4, -18)

    local anchorDD = CreateFrame("DropdownButton", "DeathSoundPartyAnchorDropdown", groupFrame, "WowStyle1DropdownTemplate")
    anchorDD:SetPoint("LEFT", anchorLabel, "RIGHT", 8, 0)
    anchorDD:SetWidth(100)
    ns.RegisterSkin("dropdown", anchorDD, 100)
    ns.SetTooltip(anchorDD, L("OPT_PARTY_ANCHOR_TIP"))

    anchorDD:SetupMenu(function(_, root)
        for _, val in ipairs({ "LEFT", "RIGHT", "TOP", "BOTTOM" }) do
            root:CreateRadio(L("OPT_PARTY_ANCHOR_" .. val),
                function() return db.partyOverlayAnchor == val end,
                function()
                    db.partyOverlayAnchor = val
                    UpdateAllPartyOverlays()
                end)
        end
    end)

    local offsetLabel = ns.CreateLabel(groupFrame, L("OPT_PARTY_OFFSET"), nil, 100)
    offsetLabel:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -26)

    local offsetBox = ns.CreateNumberBox(groupFrame, "DeathSoundPartyOffsetBox", 50, 3,
        function() return db.partyOverlayOffset end,
        function(val)
            val = math.floor(math.min(64, math.max(0, val)))
            db.partyOverlayOffset = val
            UpdateAllPartyOverlays()
            return val
        end)
    offsetBox:SetPoint("LEFT", offsetLabel, "RIGHT", 8, 0)

    local offsetPxLabel = ns.CreateLabel(groupFrame, "px (0 - 64)", "GameFontDisableSmall")
    offsetPxLabel:SetPoint("LEFT", offsetBox, "RIGHT", 6, 0)

    -- ---- Preview and file hint ----
    UpdatePreview = CreatePreview(groupFrame, function() return db.partyOverlayImageName end)
    ns.CreateFooter(groupFrame, L("HINT_FILES_IMAGE"))

    -- The Random checkbox also dims the dropdown (the selection is irrelevant with Random)
    UpdateRandomMode = function()
        ns.SetDimmed(partyDD, db.partyOverlayRandom)
    end

    groupFrame:SetScript("OnShow", UpdatePreview)
    UpdateRandomMode()
    UpdatePreview()
end
