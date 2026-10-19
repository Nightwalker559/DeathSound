-- DeathSound - DeathSound.lua
-- WoW Midnight 12.1
-- Kern: Sound, Datenbank-Init, gemeinsame Helfer (ns.*), Optionspanel.
-- Gemeinsamer Namespace `ns` (siehe TOC-Reihenfolge): ns.L (Locale), ns.SoundList,
-- ns.ImageList (generiert von UpdateLists.bat), ns.defaults, ns.skin (fuer ElvUI_Skin).

local ADDON_NAME, ns = ...
local L = ns.L

local SOUND_PATH = "Interface\\AddOns\\DeathSound\\Media\\Sounds\\"
local PREFIX     = "|cff00ccff[DeathSound]|r "

ns.PREFIX          = PREFIX
ns.DROPDOWN_WIDTH  = 160
ns.COL_WIDTH       = 350   -- linke Spalte der Tabs
ns.SoundList       = ns.SoundList or {}
ns.ImageList       = ns.ImageList or {}
ns.isDead          = false

-- Defaults aller Dateien; DeathOverlay.lua ergaenzt seine Keys beim Laden.
ns.defaults = {
    enabled      = true,
    gameSoundID  = "",
    randomSound  = false,
    soundName    = "",   -- gespeicherter Name des gewaehlten Sounds
    useGameSound = false,
}

-- Widgets, die ElvUI_Skin anfasst (Helfer unten tragen sich selbst ein).
ns.skin = { button = {}, checkbox = {}, editbox = {}, dropdown = {} }

-- ============================================================
-- Gemeinsame Helfer
-- ============================================================

-- Index des gespeicherten Namens in einer Liste (Fallback: 1)
function ns.ResolveIndex(list, name)
    if name and name ~= "" then
        for i, entry in ipairs(list) do
            if entry.name == name then return i end
        end
    end
    return 1
end

-- Zufaelliger Index 1..count, nie gleich `current` (setzt count > 1 voraus)
function ns.PickRandomIndex(count, current)
    local idx = math.random(1, count - 1)
    if idx >= current then idx = idx + 1 end
    return idx
end

-- Tooltip fuer ein Widget; text darf ein String oder eine Funktion sein.
-- HookScript statt SetScript, damit Template-Handler (Buttons, Dropdowns) erhalten bleiben.
function ns.SetTooltip(widget, text, anchor)
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, anchor or "ANCHOR_RIGHT")
        GameTooltip:SetText(type(text) == "function" and text() or text, 1, 1, 1)
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.CreateCheckBox(parent, name, text, tooltip, checked, onClick)
    -- Wie das veraltete InterfaceOptionsCheckButtonTemplate: 26x26, Label in .Text
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb.Text:SetText(text)
    cb:SetChecked(checked)
    if onClick then cb:SetScript("OnClick", onClick) end
    if tooltip then ns.SetTooltip(cb, tooltip) end
    ns.skin.checkbox[#ns.skin.checkbox + 1] = cb
    return cb
end

function ns.CreateButton(parent, name, width, height, text, tooltip, onClick)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, height)
    btn:SetText(text)
    if onClick then btn:SetScript("OnClick", onClick) end
    if tooltip then ns.SetTooltip(btn, tooltip) end
    ns.skin.button[#ns.skin.button + 1] = btn
    return btn
end

-- Zahlenfeld: Enter/Fokusverlust uebernimmt, Escape verwirft. Ein leeres Feld behaelt den
-- aktuellen Wert. apply(wert) setzt den (geklemmten) Wert und gibt ihn zurueck.
function ns.CreateNumberBox(parent, name, width, maxLetters, getValue, apply)
    local box = CreateFrame("EditBox", name, parent, "InputBoxTemplate")
    box:SetSize(width, 26)
    box:SetAutoFocus(false)
    box:SetNumeric(true)
    box:SetMaxLetters(maxLetters)
    box:SetText(tostring(getValue()))

    local function commit(self)
        self:SetText(tostring(apply(tonumber(self:GetText()) or getValue())))
    end
    box:SetScript("OnEnterPressed", function(self) commit(self); self:ClearFocus() end)
    box:SetScript("OnEscapePressed", function(self) self:SetText(tostring(getValue())); self:ClearFocus() end)
    box:SetScript("OnEditFocusLost", commit)

    ns.skin.editbox[#ns.skin.editbox + 1] = box
    return box
end

-- Radio-Dropdown (Menu-API, kein Taint auf UIDROPDOWNMENU_*) ueber eine Name/Datei-Liste.
-- getName liefert den gespeicherten Namen, onSelect(entry) speichert die Auswahl.
function ns.CreateListDropdown(parent, name, list, emptyText, getName, onSelect)
    local dd = CreateFrame("DropdownButton", name, parent, "WowStyle1DropdownTemplate")
    dd:SetWidth(ns.DROPDOWN_WIDTH)
    dd:SetupMenu(function(_, root)
        if #list == 0 then
            dd:OverrideText("---")
            root:CreateTitle(emptyText)
            return
        end
        root:SetScrollMode(20 * 20)
        for i, entry in ipairs(list) do
            root:CreateRadio(entry.name,
                function() return i == ns.ResolveIndex(list, getName()) end,
                function() onSelect(entry) end)
        end
    end)
    ns.skin.dropdown[#ns.skin.dropdown + 1] = { dd, ns.DROPDOWN_WIDTH }
    return dd
end

-- ---- Layout-Helfer fuer das Optionspanel ----

-- Abschnitts-Ueberschrift mit Linie darunter (Position setzt der Aufrufer)
function ns.CreateHeader(parent, text, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    fs:SetText(text)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    line:SetSize(width, 1)
    line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
    return fs
end

-- Grauer Erklaerungstext (Position setzt der Aufrufer)
function ns.CreateHint(parent, text, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    fs:SetJustifyH("LEFT")
    fs:SetWidth(width)
    fs:SetText(text)
    return fs
end

-- Hinweis zu eigenen Dateien am unteren Rand eines Tabs, mit Linie darueber
function ns.CreateFooter(parent, text)
    local fs = ns.CreateHint(parent, text, 560)
    fs:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.25, 0.25, 0.25, 0.6)
    line:SetSize(560, 1)
    line:SetPoint("BOTTOMLEFT", fs, "TOPLEFT", 0, 6)
    return fs
end

-- ============================================================
-- Datenbank
-- ============================================================

-- Alter Index-Key (z.B. soundIndex) -> gespeicherter Name
local function MigrateIndexToName(db, nameKey, indexKey, list)
    if db[nameKey] == nil or db[nameKey] == "" then
        local entry = db[indexKey] and list[db[indexKey]] or list[1]
        if entry then db[nameKey] = entry.name end
    end
    db[indexKey] = nil
end

local function InitDB()
    if type(DeathSoundDB) ~= "table" then DeathSoundDB = {} end
    local db = DeathSoundDB
    for k, v in pairs(ns.defaults) do
        if db[k] == nil then db[k] = v end
    end
    MigrateIndexToName(db, "soundName",             "soundIndex",             ns.SoundList)
    MigrateIndexToName(db, "overlayImageName",      "overlayImageIndex",      ns.ImageList)
    MigrateIndexToName(db, "partyOverlayImageName", "partyOverlayImageIndex", ns.ImageList)
end

-- ============================================================
-- Sound
-- ============================================================

local currentSoundHandle = nil
local dropdownRef        = nil

local function StopCurrentSound()
    if currentSoundHandle then
        StopSound(currentSoundHandle)
        currentSoundHandle = nil
    end
end

local function PlayGameSound(rawID)
    local id = tonumber(rawID)
    if not id or id <= 0 then
        print(PREFIX .. L("MSG_INVALID_ID"))
        return
    end
    StopCurrentSound()
    local ok, handle = PlaySound(id, "Master")
    if ok then
        currentSoundHandle = handle
    else
        print(PREFIX .. L("MSG_ID_ERROR") .. id)
    end
end

local function PlaySelectedSound(force)
    local db = DeathSoundDB
    if not force and not db.enabled then return end

    if db.useGameSound then
        PlayGameSound(db.gameSoundID)
        return
    end

    local list = ns.SoundList
    if #list == 0 then
        print(PREFIX .. L("MSG_NO_SOUNDS"))
        return
    end

    local entry
    if db.randomSound and #list > 1 then
        entry = list[ns.PickRandomIndex(#list, ns.ResolveIndex(list, db.soundName))]
        db.soundName = entry.name
        if dropdownRef then dropdownRef:GenerateMenu() end
    else
        entry = list[ns.ResolveIndex(list, db.soundName)]
    end

    StopCurrentSound()
    local path = SOUND_PATH .. entry.file
    local ok, handle = PlaySoundFile(path, "Master")
    if ok then
        currentSoundHandle = handle
    else
        print(PREFIX .. L("MSG_FILE_ERROR") .. path)
        print(PREFIX .. L("MSG_FILE_HINT"))
    end
end

-- ============================================================
-- Options Panel
-- ============================================================

local COL_WIDTH     = ns.COL_WIDTH
local CONTENT_WIDTH = 560

local function BuildSoundTab(soundFrame)
    local db = DeathSoundDB
    local UpdateModeUI  -- forward declaration

    -- ---- Sounddatei ----
    local hdrFile = ns.CreateHeader(soundFrame, L("SECTION_SOUND_FILE"), COL_WIDTH)
    hdrFile:SetPoint("TOPLEFT", soundFrame, "TOPLEFT", 0, 0)

    local fileCB = ns.CreateCheckBox(soundFrame, "DeathSoundFileCB", L("OPT_USE_FILE"), nil, not db.useGameSound,
        function() db.useGameSound = false; UpdateModeUI() end)
    fileCB:SetPoint("TOPLEFT", hdrFile, "BOTTOMLEFT", 0, -10)

    local dd = ns.CreateListDropdown(soundFrame, "DeathSoundDropdown", ns.SoundList, L("DD_NO_SOUNDS"),
        function() return db.soundName end,
        function(entry) db.soundName = entry.name end)
    dd:SetPoint("TOPLEFT", fileCB, "BOTTOMLEFT", 4, -8)
    dropdownRef = dd

    local testFileBtn = ns.CreateButton(soundFrame, "DeathSoundTestButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_TEST_TOOLTIP"), function() PlaySelectedSound(true) end)
    testFileBtn:SetPoint("LEFT", dd, "RIGHT", 8, 0)

    local randomCB = ns.CreateCheckBox(soundFrame, "DeathSoundRandomCB", L("OPT_RANDOM"), nil,
        db.randomSound, function(self) db.randomSound = self:GetChecked(); UpdateModeUI() end)
    randomCB:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", -4, -6)
    local randomHint = ns.CreateHint(soundFrame, L("OPT_RANDOM_TOOLTIP"), COL_WIDTH - 26)
    randomHint:SetPoint("TOPLEFT", randomCB, "BOTTOMLEFT", 26, 0)

    -- ---- WoW Sound-ID ----
    local hdrID = ns.CreateHeader(soundFrame, L("SECTION_SOUND_ID"), COL_WIDTH)
    hdrID:SetPoint("TOPLEFT", randomHint, "BOTTOMLEFT", -26, -22)

    local idCB = ns.CreateCheckBox(soundFrame, "DeathSoundIDCB", L("OPT_USE_ID"), nil, db.useGameSound,
        function() db.useGameSound = true; UpdateModeUI() end)
    idCB:SetPoint("TOPLEFT", hdrID, "BOTTOMLEFT", 0, -10)

    local idLabel = soundFrame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    idLabel:SetPoint("TOPLEFT", idCB, "BOTTOMLEFT", 4, -8)
    idLabel:SetText(L("OPT_ID_LABEL"))

    -- Die ID wird bei jeder Aenderung gespeichert (OnTextChanged), Escape stellt den Stand
    -- vom Fokus-Beginn wieder her.
    local idBox = CreateFrame("EditBox", "DeathSoundIDBox", soundFrame, "InputBoxTemplate")
    idBox:SetSize(120, 26)
    idBox:SetPoint("TOPLEFT", idLabel, "BOTTOMLEFT", 0, -6)
    idBox:SetAutoFocus(false)
    idBox:SetNumeric(true)
    idBox:SetMaxLetters(10)
    idBox:SetText(db.gameSoundID or "")
    ns.skin.editbox[#ns.skin.editbox + 1] = idBox
    local idSnapshot = db.gameSoundID or ""
    idBox:SetScript("OnEditFocusGained", function() idSnapshot = db.gameSoundID or "" end)
    idBox:SetScript("OnTextChanged",     function(self) db.gameSoundID = self:GetText() end)
    idBox:SetScript("OnEnterPressed",    function(self) self:ClearFocus() end)
    idBox:SetScript("OnEscapePressed",   function(self)
        db.gameSoundID = idSnapshot
        self:SetText(idSnapshot)
        self:ClearFocus()
    end)

    local testIDBtn = ns.CreateButton(soundFrame, "DeathSoundTestIDButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_TEST_TOOLTIP"), function() PlayGameSound(idBox:GetText()) end)
    testIDBtn:SetPoint("LEFT", idBox, "RIGHT", 10, 0)

    ns.CreateFooter(soundFrame, L("HINT_FILES_SOUND"))

    UpdateModeUI = function()
        local useID      = db.useGameSound
        local fileDimmed = useID
        local ddDimmed   = useID or db.randomSound

        dd:SetAlpha(ddDimmed and 0.4 or 1)
        dd:SetEnabled(not ddDimmed)
        testFileBtn:SetEnabled(not fileDimmed)
        randomCB:SetEnabled(not fileDimmed)
        randomCB:SetAlpha(fileDimmed and 0.4 or 1)
        randomHint:SetAlpha(fileDimmed and 0.4 or 1)

        local idAlpha = useID and 1 or 0.4
        idBox:SetEnabled(useID)
        idBox:SetAlpha(idAlpha)
        idLabel:SetAlpha(idAlpha)
        testIDBtn:SetEnabled(useID)

        fileCB:SetChecked(not useID)
        idCB:SetChecked(useID)
    end
    UpdateModeUI()
end

-- Tab-Button im flachen Stil: Text, Hover-Schimmer, farbige Linie wenn aktiv.
local function CreateTab(parent, name, label)
    local btn = CreateFrame("Button", name, parent)
    btn:SetSize(110, 28)

    btn.text = btn:CreateFontString(nil, "ARTWORK", "GameFontNormal")
    btn.text:SetPoint("CENTER", 0, 1)
    btn.text:SetText(label)

    btn.underline = btn:CreateTexture(nil, "OVERLAY")
    btn.underline:SetColorTexture(0, 0.8, 1, 1)
    btn.underline:SetHeight(2)
    btn.underline:SetPoint("BOTTOMLEFT", btn, "BOTTOMLEFT", 0, 0)
    btn.underline:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)

    local hover = btn:CreateTexture(nil, "HIGHLIGHT")
    hover:SetAllPoints()
    hover:SetColorTexture(1, 1, 1, 0.06)

    function btn:SetActive(active)
        self.underline:SetShown(active)
        if active then
            self.text:SetTextColor(0, 0.8, 1)
        else
            self.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end
    return btn
end

local function BuildOptionsPanel()
    local db = DeathSoundDB

    local panel = CreateFrame("Frame")
    panel.name  = ADDON_NAME

    -- ---- Kopf: Titel, Version, Untertitel ----
    local title = panel:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)
    title:SetText("|cff00ccff" .. L("ADDON_TITLE") .. "|r")

    local version = panel:CreateFontString(nil, "ARTWORK", "GameFontDisableSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)
    version:SetText("v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"))

    local subtitle = panel:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)
    subtitle:SetJustifyH("LEFT")
    subtitle:SetWidth(CONTENT_WIDTH)
    subtitle:SetText(L("ADDON_SUBTITLE"))

    local cb = ns.CreateCheckBox(panel, "DeathSoundEnabledCB", L("OPT_ENABLE"), L("OPT_ENABLE_TOOLTIP"),
        db.enabled, function(self) db.enabled = self:GetChecked() end)
    cb:SetPoint("TOPLEFT", subtitle, "BOTTOMLEFT", 0, -12)

    -- ---- Tabs ----
    local tabs = {
        { label = "TAB_SOUND", name = "DeathSoundTabSound" },
        { label = "TAB_IMAGE", name = "DeathSoundTabImage" },
        { label = "TAB_GROUP", name = "DeathSoundTabGroup" },
    }
    local prev
    for _, tab in ipairs(tabs) do
        tab.button = CreateTab(panel, tab.name, L(tab.label))
        if prev then
            tab.button:SetPoint("LEFT", prev, "RIGHT", 4, 0)
        else
            tab.button:SetPoint("TOPLEFT", cb, "BOTTOMLEFT", 0, -12)
        end
        prev = tab.button
    end

    local tabSep = panel:CreateTexture(nil, "ARTWORK")
    tabSep:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    tabSep:SetSize(CONTENT_WIDTH, 1)
    tabSep:SetPoint("TOPLEFT", tabs[1].button, "BOTTOMLEFT", 0, 0)

    for _, tab in ipairs(tabs) do
        tab.content = CreateFrame("Frame", nil, panel)
        tab.content:SetPoint("TOPLEFT", tabSep, "BOTTOMLEFT", 0, -14)
        tab.content:SetSize(CONTENT_WIDTH, 350)
    end

    -- Die Frames fuer Overlay/Party-Emote existieren (ns.InitOverlays) bevor dieses Panel gebaut wird.
    BuildSoundTab(tabs[1].content)
    ns.BuildOverlaySection(tabs[2].content)
    ns.BuildPartySection(tabs[3].content)

    local function SetTab(active)
        for i, tab in ipairs(tabs) do
            tab.content:SetShown(i == active)
            tab.button:SetActive(i == active)
        end
    end
    for i, tab in ipairs(tabs) do
        tab.button:SetScript("OnClick", function() SetTab(i) end)
    end
    SetTab(1)  -- Sound-Tab standardmaessig aktiv

    -- Panel registrieren
    panel.category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
    Settings.RegisterAddOnCategory(panel.category)
    ns.optionsPanel = panel
end

-- ============================================================
-- Events
-- ============================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        InitDB()
        ns.InitOverlays()
        BuildOptionsPanel()
        self:RegisterEvent("PLAYER_DEAD")
        self:RegisterEvent("PLAYER_ALIVE")
        self:RegisterEvent("PLAYER_UNGHOST")

    elseif event == "PLAYER_DEAD" then
        if not ns.isDead then
            ns.isDead = true
            PlaySelectedSound()
            ns.ShowDeathOverlay()
        end

    else  -- PLAYER_ALIVE / PLAYER_UNGHOST
        ns.isDead = false
        ns.HideDeathOverlay()
    end
end)

-- ============================================================
-- Slash Commands
-- ============================================================

SLASH_DEATHSOUND1 = "/deathsound"
SLASH_DEATHSOUND2 = "/ds"

SlashCmdList["DEATHSOUND"] = function(msg)
    msg = strtrim(msg or ""):lower()

    if msg == "" then
        if ns.optionsPanel then Settings.OpenToCategory(ns.optionsPanel.category:GetID()) end

    elseif msg == "test" then
        PlaySelectedSound(true)

    elseif msg == "on" then
        DeathSoundDB.enabled = true
        print(PREFIX .. L("MSG_ENABLED"))

    elseif msg == "off" then
        DeathSoundDB.enabled = false
        print(PREFIX .. L("MSG_DISABLED"))

    else
        print(PREFIX .. L("MSG_HELP"))
        print(L("MSG_HELP_OPEN"))
        print(L("MSG_HELP_TEST"))
        print(L("MSG_HELP_ON"))
        print(L("MSG_HELP_OFF"))
    end
end
