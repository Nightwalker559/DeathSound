-- DeathSound - DeathSound.lua
-- Entry point (loaded last, see TOC): init on ADDON_LOADED, death/revive events, slash commands.

local ADDON_NAME, ns = ...
local L      = ns.L
local PREFIX = ns.PREFIX

-- ============================================================
-- Events
-- ============================================================

local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        self:UnregisterEvent("ADDON_LOADED")
        ns.InitDB()
        ns.InitOverlays()
        ns.BuildOptionsPanel()
        self:RegisterEvent("PLAYER_DEAD")
        self:RegisterEvent("PLAYER_ALIVE")
        self:RegisterEvent("PLAYER_UNGHOST")

    elseif event == "PLAYER_DEAD" then
        if not ns.isDead then
            ns.isDead = true
            ns.PlaySelectedSound()
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
        ns.PlaySelectedSound(true)

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
