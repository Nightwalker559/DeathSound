-- DeathSound - EmoteTab.lua
-- Emote tab of the options panel (built by OptionsPanel.lua): image, position and size of the
-- death overlay. The overlay itself lives in Core\DeathOverlay.lua (ns.* API).

local _, ns = ...
local L = ns.L

local COL_WIDTH = ns.COL_WIDTH

function ns.BuildEmoteTab(imageFrame)
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
            ns.ApplyImage()
            UpdatePreview()
        end)
    dd:SetPoint("TOPLEFT", enableCB, "BOTTOMLEFT", 4, -8)

    -- Test button: with "Random" picks a new image and shows it in the preview (not on screen)
    local testEmoteBtn = ns.CreateButton(imageFrame, "DeathSoundTestEmoteButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_TEST_EMOTE_TOOLTIP"),
        function()
            ns.PickRandomImage("overlayImageName")
            ns.ApplyImage()
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
        function() return db.overlaySize end, ns.SetOverlaySize)
    sizeBox:SetPoint("LEFT", sizeLabel, "RIGHT", 10, 0)

    local pxLabel = ns.CreateLabel(imageFrame, L("OPT_OVERLAY_SIZE_UNIT"), "GameFontDisableSmall")
    pxLabel:SetPoint("LEFT", sizeBox, "RIGHT", 6, 0)

    -- ---- Lock/Unlock Button ----
    local lockBtn = ns.CreateButton(imageFrame, "DeathSoundLockButton", 150, 26, "",
        function() return db.overlayLocked and L("OPT_OVERLAY_UNLOCK_TIP") or L("OPT_OVERLAY_LOCK_TIP") end,
        function()
            ns.ToggleOverlayEditMode()
            UpdateLockBtn()
        end)
    lockBtn:SetPoint("TOPLEFT", sizeLabel, "BOTTOMLEFT", -4, -14)

    -- ---- Reset Position Button ----
    local resetBtn = ns.CreateButton(imageFrame, "DeathSoundResetButton", 150, 26,
        L("OPT_OVERLAY_RESET"), L("OPT_OVERLAY_RESET_TIP"), ns.ResetOverlayPosition)
    resetBtn:SetPoint("LEFT", lockBtn, "RIGHT", 8, 0)

    -- ---- Preview and file hint ----
    UpdatePreview = ns.CreatePreview(imageFrame, function() return db.overlayImageName end)
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
