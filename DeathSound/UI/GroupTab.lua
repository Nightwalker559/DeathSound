-- DeathSound - GroupTab.lua
-- Group tab of the options panel (built by OptionsPanel.lua): emote next to the party frames.
-- The party overlay itself lives in Core\DeathOverlay.lua (ns.* API).

local _, ns = ...
local L = ns.L

local COL_WIDTH = ns.COL_WIDTH

function ns.BuildGroupTab(groupFrame)
    local db = DeathSoundDB
    local UpdatePreview, UpdateRandomMode  -- forward declarations

    -- ---- Group emote ----
    local hdrParty = ns.CreateHeader(groupFrame, L("SECTION_PARTY"), COL_WIDTH)
    hdrParty:SetPoint("TOPLEFT", groupFrame, "TOPLEFT", 0, 0)

    local partyCB = ns.CreateCheckBox(groupFrame, "DeathSoundPartyCB", L("OPT_PARTY_ENABLE"),
        L("OPT_PARTY_ENABLE_TOOLTIP"), db.partyOverlayEnabled,
        function(self)
            db.partyOverlayEnabled = self:GetChecked()
            ns.UpdateAllPartyOverlays()
        end)
    partyCB:SetPoint("TOPLEFT", hdrParty, "BOTTOMLEFT", 0, -10)

    local partyDD = ns.CreateListDropdown(groupFrame, "DeathSoundPartyDropdown", ns.ImageList, L("DD_NO_IMAGES"),
        function() return db.partyOverlayImageName end,
        function(entry)
            db.partyOverlayImageName = entry.name
            ns.ApplyPartyImage()
            UpdatePreview()
        end)
    partyDD:SetPoint("TOPLEFT", partyCB, "BOTTOMLEFT", 4, -8)

    local partyTestBtn = ns.CreateButton(groupFrame, "DeathSoundPartyTestButton", 100, 26,
        L("OPT_TEST_BUTTON"), L("OPT_PARTY_TEST_TOOLTIP"),
        function()
            ns.PreviewPartyOverlays()
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
                    ns.UpdateAllPartyOverlays()
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
            ns.UpdateAllPartyOverlays()
            return val
        end)
    offsetBox:SetPoint("LEFT", offsetLabel, "RIGHT", 8, 0)

    local offsetPxLabel = ns.CreateLabel(groupFrame, "px (0 - 64)", "GameFontDisableSmall")
    offsetPxLabel:SetPoint("LEFT", offsetBox, "RIGHT", 6, 0)

    -- ---- Preview and file hint ----
    UpdatePreview = ns.CreatePreview(groupFrame, function() return db.partyOverlayImageName end)
    ns.CreateFooter(groupFrame, L("HINT_FILES_IMAGE"))

    -- The Random checkbox also dims the dropdown (the selection is irrelevant with Random)
    UpdateRandomMode = function()
        ns.SetDimmed(partyDD, db.partyOverlayRandom)
    end

    groupFrame:SetScript("OnShow", UpdatePreview)
    UpdateRandomMode()
    UpdatePreview()
end
