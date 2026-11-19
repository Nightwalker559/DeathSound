-- DeathSound - OptionsPanel.lua
-- Options panel in the Settings window: header, tab buttons and tab frames.
-- The tab contents come from SoundTab.lua, EmoteTab.lua and GroupTab.lua.

local ADDON_NAME, ns = ...
local L = ns.L

local CONTENT_WIDTH = 560

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
    ns.BuildSoundTab(tabs[1].content)
    ns.BuildEmoteTab(tabs[2].content)
    ns.BuildGroupTab(tabs[3].content)

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
