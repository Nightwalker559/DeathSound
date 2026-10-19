-- DeathSound - DeathOverlay.lua
-- WoW Midnight 12.1
-- Todes-Overlay (eigener Charakter) und Gruppen-Emote (Party-Mitglieder).
-- Wird von DeathSound.lua initialisiert (ns.InitOverlays) und ruft nur ns-Helfer von dort auf.

local _, ns = ...
local L      = ns.L
local PREFIX = ns.PREFIX

local IMAGE_PATH        = "Interface\\AddOns\\DeathSound\\Media\\Images\\"
local PARTY_MAX_SIZE_TB = 96   -- max px fuer Oben/Unten
local PREVIEW_SECONDS   = 6

for k, v in pairs({
    overlayAnchorToPopup  = false,
    overlayEnabled        = false,
    overlayHeight         = 64,
    overlayImageName      = "",   -- gespeicherter Name des gewaehlten Emote-Bildes
    overlayLocked         = true,
    overlayPoint          = "CENTER",
    overlayRandom         = false,
    overlayWidth          = 64,
    overlayX              = 0,
    overlayY              = 0,
    -- Party Overlay
    partyOverlayAnchor    = "LEFT",  -- LEFT | RIGHT | TOP | BOTTOM
    partyOverlayEnabled   = false,
    partyOverlayImageName = "",   -- gespeicherter Name des gewaehlten Party-Emote-Bildes
    partyOverlayOffset    = 4,       -- px Abstand zwischen Emote und PartyFrame
    partyOverlayRandom    = false,
}) do
    ns.defaults[k] = v
end

-- Party-Emote: Seite des Party-Frames -> Ankerpunkte und Richtung des Abstands
local PARTY_ANCHORS = {
    LEFT   = { point = "RIGHT",  relPoint = "LEFT",   x = -1, y = 0 },
    RIGHT  = { point = "LEFT",   relPoint = "RIGHT",  x = 1,  y = 0 },
    TOP    = { point = "BOTTOM", relPoint = "TOP",    x = 0,  y = 1, vertical = true },
    BOTTOM = { point = "TOP",    relPoint = "BOTTOM", x = 0,  y = -1, vertical = true },
}
local PARTY_SLOT = { party1 = 1, party2 = 2, party3 = 3, party4 = 4 }

-- Modul-State
local overlayFrame   = nil
local overlayTexture = nil
local overlayBorder  = nil
local partyFrames    = {}   -- [1..4] = Overlay-Frame (mit .tex) fuer party1..party4
local partyTestTimer = nil  -- Handle fuer laufenden Party-Vorschau-Timer
local partyUpdatePending = false

-- ============================================================
-- Bilder
-- ============================================================

local function ImageTexturePath(name)
    local list  = ns.ImageList
    local entry = list[ns.ResolveIndex(list, name)]
    return entry and (IMAGE_PATH .. entry.file)
end

-- Waehlt ein zufaelliges Bild (nie das gleiche wie zuletzt) und speichert den Namen unter `key`.
local function PickRandomImage(key)
    local db, list = DeathSoundDB, ns.ImageList
    if #list <= 1 then return end
    db[key] = list[ns.PickRandomIndex(#list, ns.ResolveIndex(list, db[key]))].name
end

-- Startet den Vorschau-Timer neu (ein laufender wird abgebrochen).
local function RestartPreviewTimer(timer, fn)
    if timer then timer:Cancel() end
    return C_Timer.NewTimer(PREVIEW_SECONDS, fn)
end

-- ============================================================
-- Overlay Logik
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

-- Ankert das Overlay am "Geist freilassen"-Popup (links davon, Groesse = Popup-Hoehe).
-- Das Popup ist nicht zwingend StaticPopup1 (z.B. wenn schon ein anderes Popup offen ist).
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

-- Popup-Anker, wenn gewuenscht und das Popup offen ist, sonst gespeicherte Position
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

    -- Edit-Mode immer beenden beim echten Tod
    SetEditMode(false)
    PlaceOverlay()
    overlayFrame:Show()

    if db.overlayAnchorToPopup then
        -- Der Text des DEATH-Popups wird verzoegert gesetzt (Deferred) und aendert dabei die Hoehe
        C_Timer.After(0.15, AnchorToPopup)
    end
end

-- Bei Wiederbelebung verstecken, ausser der Edit-Mode ist offen
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
    -- Maus ist nur im Edit-Mode aktiv, der Tooltip erscheint also nur dort
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
    SetEditMode(not DeathSoundDB.overlayLocked)
end

-- ============================================================
-- Party Overlay Logik
-- ============================================================

-- Sucht unter den Frames <prefix>1..count (aus `parent`, sonst _G) den sichtbaren Frame der Einheit.
local function FindUnitFrame(unit, parent, prefix, count)
    parent = parent or _G
    for i = 1, count do
        local f = parent[prefix .. i]
        if f and f:IsShown() and f.unit and UnitIsUnit(f.unit, unit) then return f end
    end
end

-- Gibt den Party-Frame fuer slot 1-4 (Einheit "party<slot>") zurueck oder nil.
-- Unterstuetzt ElvUI, die Raid-Style-Party (CompactPartyFrame) und PartyFrame.MemberFrame1..4.
-- Die Zuordnung laeuft ueber die Einheit, nicht ueber den Frame-Index: ElvUI und CompactPartyFrame
-- koennen den eigenen Spieler mit anzeigen und verschieben die Positionen.
local function GetPartyFrame(slot)
    local unit = "party" .. slot

    if ElvUI then
        local f = FindUnitFrame(unit, nil, "ElvUF_PartyGroup1UnitButton", 5)
        if f then return f end
    end

    if CompactPartyFrame and CompactPartyFrame:IsShown() then
        return FindUnitFrame(unit, nil, "CompactPartyFrameMember", 5)
    end

    if PartyFrame and PartyFrame:IsShown() then
        return FindUnitFrame(unit, PartyFrame, "MemberFrame", 4)
    end
end

-- Erstellt die 4 Party-Overlay-Frames einmalig.
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

-- Setzt Bild (nach Name) auf einem Party-Overlay.
local function SetPartyImage(frame, name)
    frame.imageName = name
    frame.tex:SetTexture(ImageTexturePath(name))
end

-- Setzt das gespeicherte Bild auf allen Party-Overlays (Auswahl im Dropdown).
local function ApplyPartyImage()
    for i = 1, 4 do
        SetPartyImage(partyFrames[i], DeathSoundDB.partyOverlayImageName)
    end
end

-- Bildname fuer ein Party-Overlay: das gewaehlte Bild, oder bei "Zufaellig" ein eigenes Bild pro
-- Mitglied. Zufall nimmt nie das zuletzt gewaehlte und keins, das gerade an einem anderen
-- Party-Overlay zu sehen ist (solange die Liste dafuer gross genug ist).
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
    db.partyOverlayImageName = name   -- "zuletzt gewaehlt"; die Vorschau im Panel zeigt es
    return name
end

-- Groesse und Anker des Party-Emotes relativ zum Party-Frame setzen und anzeigen.
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

-- True in einer Raidgruppe ODER in einer Raid-Instanz. Letzteres ist noetig, weil
-- z.B. zu zweit in einem Raid die Gruppe eine normale Party bleibt (IsInRaid() = false).
local function IsInRaidContent()
    if IsInRaid() then return true end
    local _, instanceType = IsInInstance()
    return instanceType == "raid"
end

-- Zeigt oder versteckt das Party-Overlay fuer einen bestimmten Slot.
local function UpdatePartyOverlay(slot)
    local db    = DeathSoundDB
    local frame = partyFrames[slot]
    local unit  = "party" .. slot

    local partyFrame
    if db.enabled and db.partyOverlayEnabled and not IsInRaidContent()
        and UnitExists(unit) and UnitIsConnected(unit) and UnitIsDeadOrGhost(unit) then
        partyFrame = GetPartyFrame(slot)
    end
    if not partyFrame then
        frame:Hide()
        return
    end

    -- Beim Tod (Frame war noch versteckt) das Bild fuer genau diesen Slot waehlen
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

-- Gruppen-/Zonenwechsel kommen gebuendelt; die Blizzard-Party-Frames werden erst im selben
-- Frame nach dem Event aktualisiert -> einmal im naechsten Frame auswerten.
local function ScheduleUpdateAllPartyOverlays()
    if partyUpdatePending then return end
    partyUpdatePending = true
    RunNextFrame(function()
        partyUpdatePending = false
        UpdateAllPartyOverlays()
    end)
end

-- Alle sichtbaren Frames des Gruppenfensters (max. 4), auch ohne Gruppe: ElvUI kann die Gruppe
-- solo anzeigen, Blizzard im Bearbeitungsmodus (dort mit dem eigenen Spieler als Platzhalter).
local function CollectShownFrames(out, parent, prefix, count)
    parent = parent or _G
    for i = 1, count do
        local f = parent[prefix .. i]
        if f and f:IsShown() then out[#out + 1] = f end
    end
end

local function GetPreviewFrames()
    local out = {}
    if ElvUI then CollectShownFrames(out, nil, "ElvUF_PartyGroup1UnitButton", 5) end
    if #out == 0 and CompactPartyFrame and CompactPartyFrame:IsShown() then
        CollectShownFrames(out, nil, "CompactPartyFrameMember", 5)
    end
    if #out == 0 and PartyFrame and PartyFrame:IsShown() then
        CollectShownFrames(out, PartyFrame, "MemberFrame", 4)
    end
    while #out > 4 do out[#out] = nil end
    return out
end

-- Test-Button: Emote an allen sichtbaren Gruppenfenstern anzeigen (mit Zufall je Fenster ein eigenes Bild)
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

    -- Nach der Vorschau wieder auf den echten Zustand zuruecksetzen
    partyTestTimer = RestartPreviewTimer(partyTestTimer, function()
        partyTestTimer = nil
        UpdateAllPartyOverlays()
    end)
end

-- ============================================================
-- Init / Events
-- ============================================================

-- Wird von DeathSound.lua nach dem DB-Init und vor dem Optionspanel aufgerufen.
function ns.InitOverlays()
    CreateOverlayFrame()
    CreatePartyOverlayFrames()

    local f = CreateFrame("Frame")
    -- UNIT_HEALTH nur fuer die Party-Einheiten (sonst feuert es fuer jede Einheit im Raid/Nameplates)
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
local PREVIEW_X = 390   -- Vorschau-Spalte rechts neben den Einstellungen

-- Vorschau-Kasten des gewaehlten Bildes; gibt eine Update-Funktion zurueck.
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
        local list  = ns.ImageList
        local entry = list[ns.ResolveIndex(list, getName())]
        tex:SetTexture(entry and (IMAGE_PATH .. entry.file) or nil)
        caption:SetText(entry and entry.name or "")
    end
end

function ns.BuildOverlaySection(imageFrame)
    local db = DeathSoundDB
    local UpdatePopupMode, UpdateRandomMode, UpdateLockBtn, UpdatePreview  -- forward declarations

    -- ---- Bild ----
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

    -- Test-Button: waehlt bei "Zufaellig" ein neues Bild und zeigt es in der Vorschau (nicht auf dem Bildschirm)
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

    -- ---- Position und Groesse ----
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

    local sizeLabel = imageFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    sizeLabel:SetPoint("TOPLEFT", popupCB, "BOTTOMLEFT", 4, -26)
    sizeLabel:SetText(L("OPT_OVERLAY_SIZE"))

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

    local pxLabel = imageFrame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    pxLabel:SetPoint("LEFT", sizeBox, "RIGHT", 6, 0)
    pxLabel:SetText(L("OPT_OVERLAY_SIZE_UNIT"))

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

    -- ---- Vorschau und Dateihinweis ----
    UpdatePreview = CreatePreview(imageFrame, function() return db.overlayImageName end)
    ns.CreateFooter(imageFrame, L("HINT_FILES_IMAGE"))

    UpdateLockBtn = function()
        lockBtn:SetText(db.overlayLocked and L("OPT_OVERLAY_UNLOCK") or L("OPT_OVERLAY_LOCK"))
    end

    -- Tod beendet den Edit-Mode, Zufall aendert das Bild -> beim Anzeigen des Tabs auffrischen
    imageFrame:SetScript("OnShow", function()
        UpdateLockBtn()
        UpdatePreview()
    end)

    -- ---- Modus-abhaengiges Abdunkeln (nach allen Widgets definiert) ----
    UpdatePopupMode = function()
        local anchored = db.overlayAnchorToPopup
        local alpha    = anchored and 0.4 or 1
        sizeBox:SetEnabled(not anchored)
        sizeBox:SetAlpha(alpha)
        sizeLabel:SetAlpha(alpha)
        pxLabel:SetAlpha(alpha)
        lockBtn:SetEnabled(not anchored)
        lockBtn:SetAlpha(alpha)
        resetBtn:SetEnabled(not anchored)
        resetBtn:SetAlpha(alpha)
        popupHint:SetShown(anchored)
    end

    -- Random-Checkbox dimmt auch den Dropdown (Auswahl irrelevant wenn Random)
    UpdateRandomMode = function()
        local dimDD = db.overlayRandom
        testEmoteBtn:SetEnabled(dimDD)
        dd:SetAlpha(dimDD and 0.4 or 1)
        dd:SetEnabled(not dimDD)
    end

    UpdateLockBtn()
    UpdatePreview()
    UpdateRandomMode()
    UpdatePopupMode()
end

-- ============================================================
-- Party Section Builder (eigener Tab)
-- ============================================================

function ns.BuildPartySection(groupFrame)
    local db = DeathSoundDB
    local UpdatePreview, UpdateRandomMode  -- forward declarations

    -- ---- Gruppen-Emote ----
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

    local anchorLabel = groupFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    anchorLabel:SetPoint("TOPLEFT", hdrPos, "BOTTOMLEFT", 4, -18)
    anchorLabel:SetJustifyH("LEFT")
    anchorLabel:SetWidth(100)
    anchorLabel:SetText(L("OPT_PARTY_ANCHOR"))

    local anchorDD = CreateFrame("DropdownButton", "DeathSoundPartyAnchorDropdown", groupFrame, "WowStyle1DropdownTemplate")
    anchorDD:SetPoint("LEFT", anchorLabel, "RIGHT", 8, 0)
    anchorDD:SetWidth(100)
    ns.skin.dropdown[#ns.skin.dropdown + 1] = { anchorDD, 100 }
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

    local offsetLabel = groupFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    offsetLabel:SetPoint("TOPLEFT", anchorLabel, "BOTTOMLEFT", 0, -26)
    offsetLabel:SetJustifyH("LEFT")
    offsetLabel:SetWidth(100)
    offsetLabel:SetText(L("OPT_PARTY_OFFSET"))

    local offsetBox = ns.CreateNumberBox(groupFrame, "DeathSoundPartyOffsetBox", 50, 3,
        function() return db.partyOverlayOffset end,
        function(val)
            val = math.floor(math.min(64, math.max(0, val)))
            db.partyOverlayOffset = val
            UpdateAllPartyOverlays()
            return val
        end)
    offsetBox:SetPoint("LEFT", offsetLabel, "RIGHT", 8, 0)

    local offsetPxLabel = groupFrame:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    offsetPxLabel:SetPoint("LEFT", offsetBox, "RIGHT", 6, 0)
    offsetPxLabel:SetText("px (0 - 64)")

    -- ---- Vorschau und Dateihinweis ----
    UpdatePreview = CreatePreview(groupFrame, function() return db.partyOverlayImageName end)
    ns.CreateFooter(groupFrame, L("HINT_FILES_IMAGE"))

    -- Random-Checkbox dimmt auch den Dropdown (Auswahl irrelevant wenn Random)
    UpdateRandomMode = function()
        partyDD:SetAlpha(db.partyOverlayRandom and 0.4 or 1)
        partyDD:SetEnabled(not db.partyOverlayRandom)
    end

    groupFrame:SetScript("OnShow", UpdatePreview)
    UpdateRandomMode()
    UpdatePreview()
end
