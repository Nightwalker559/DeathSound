-- DeathSound - OptionsPanel.lua
-- Options panel in the Settings window: header, tabs and the Sound tab.
-- The Image and Group tabs are built by DeathOverlay.lua (ns.BuildOverlaySection / ns.BuildPartySection).

local ADDON_NAME, ns = ...
local L = ns.L

local COL_WIDTH     = ns.COL_WIDTH
local CONTENT_WIDTH = 560

local function BuildSoundTab(soundFrame)
    local db = DeathSoundDB
    local UpdateModeUI  -- forward declaration

    -- ---- Sound file ----
    local hdrFile = ns.CreateHeader(soundFrame, L("SECTION_SOUND_FILE"), COL_WIDTH)
    hdrFile:SetPoint("TOPLEFT", soundFrame, "TOPLEFT", 0, 0)

    local fileCB = ns.CreateCheckBox(soundFrame, "DeathSoundFileCB", L("OPT_USE_FILE"), nil, not db.useGameSound,
        function() db.useGameSound = false; UpdateModeUI() end)
    fileCB:SetPoint("TOPLEFT", hdrFile, "BOTTOMLEFT", 0, -10)

    local dd = ns.CreateListDropdown(soundFrame, "DeathSoundDropdown", ns.SoundList, L("DD_NO_SOUNDS"),
        function() return db.soundName end,
        function(entry) db.soundName = entry.name end)
    dd:SetPoint("TOPLEFT", fileCB, "BOTTOMLEFT", 4, -8)
    ns.soundDropdown = dd

    local testFileBtn = ns.CreateButton(soundFrame, "DeathSoundTestButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_TEST_TOOLTIP"), function() ns.PlaySelectedSound(true) end)
    testFileBtn:SetPoint("LEFT", dd, "RIGHT", 8, 0)

    local randomCB = ns.CreateCheckBox(soundFrame, "DeathSoundRandomCB", L("OPT_RANDOM"), nil,
        db.randomSound, function(self) db.randomSound = self:GetChecked(); UpdateModeUI() end)
    randomCB:SetPoint("TOPLEFT", dd, "BOTTOMLEFT", -4, -6)
    local randomHint = ns.CreateHint(soundFrame, L("OPT_RANDOM_TOOLTIP"), COL_WIDTH - 26)
    randomHint:SetPoint("TOPLEFT", randomCB, "BOTTOMLEFT", 26, 0)

    -- ---- WoW sound ID ----
    local hdrID = ns.CreateHeader(soundFrame, L("SECTION_SOUND_ID"), COL_WIDTH)
    hdrID:SetPoint("TOPLEFT", randomHint, "BOTTOMLEFT", -26, -22)

    local idCB = ns.CreateCheckBox(soundFrame, "DeathSoundIDCB", L("OPT_USE_ID"), nil, db.useGameSound,
        function() db.useGameSound = true; UpdateModeUI() end)
    idCB:SetPoint("TOPLEFT", hdrID, "BOTTOMLEFT", 0, -10)

    local idLabel = ns.CreateLabel(soundFrame, L("OPT_ID_LABEL"))
    idLabel:SetPoint("TOPLEFT", idCB, "BOTTOMLEFT", 4, -8)

    -- The ID is saved on every change (OnTextChanged), Escape restores the state
    -- from when the box got focus.
    local idBox = CreateFrame("EditBox", "DeathSoundIDBox", soundFrame, "InputBoxTemplate")
    idBox:SetSize(120, 26)
    idBox:SetPoint("TOPLEFT", idLabel, "BOTTOMLEFT", 0, -6)
    idBox:SetAutoFocus(false)
    idBox:SetNumeric(true)
    idBox:SetMaxLetters(10)
    idBox:SetText(db.gameSoundID or "")
    ns.RegisterSkin("editbox", idBox)
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
        L("OPT_TEST_BUTTON"), L("OPT_TEST_TOOLTIP"), function() ns.PlayGameSound(idBox:GetText()) end)
    testIDBtn:SetPoint("LEFT", idBox, "RIGHT", 10, 0)

    ns.CreateFooter(soundFrame, L("HINT_FILES_SOUND"))

    UpdateModeUI = function()
        local useID = db.useGameSound

        ns.SetDimmed(dd, useID or db.randomSound)
        testFileBtn:SetEnabled(not useID)
        ns.SetDimmed(randomCB, useID)
        ns.SetDimmed(randomHint, useID)

        ns.SetDimmed(idBox, not useID)
        ns.SetDimmed(idLabel, not useID)
        testIDBtn:SetEnabled(useID)

        fileCB:SetChecked(not useID)
        idCB:SetChecked(useID)
    end
    UpdateModeUI()
end

-- Tab button in the flat style: text, hover highlight, coloured line when active.
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

function ns.BuildOptionsPanel()
    local db = DeathSoundDB

    local panel = CreateFrame("Frame")
    panel.name  = ADDON_NAME

    -- ---- Header: title, version, subtitle ----
    local title = ns.CreateLabel(panel, "|cff00ccff" .. L("ADDON_TITLE") .. "|r", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", 16, -16)

    local version = ns.CreateLabel(panel, "v" .. (C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version") or "?"),
        "GameFontDisableSmall")
    version:SetPoint("LEFT", title, "RIGHT", 8, -1)

    local subtitle = ns.CreateLabel(panel, L("ADDON_SUBTITLE"), nil, CONTENT_WIDTH)
    subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -4)

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

    -- The overlay/party emote frames already exist (ns.InitOverlays) before this panel is built.
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
    SetTab(1)  -- Sound tab is active by default

    -- Register the panel
    panel.category = Settings.RegisterCanvasLayoutCategory(panel, ADDON_NAME)
    Settings.RegisterAddOnCategory(panel.category)
    ns.optionsPanel = panel
end
