-- DeathSound - SoundTab.lua
-- Sound tab of the options panel (built by OptionsPanel.lua).

local _, ns = ...
local L = ns.L

local COL_WIDTH = ns.COL_WIDTH

function ns.BuildSoundTab(soundFrame)
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
