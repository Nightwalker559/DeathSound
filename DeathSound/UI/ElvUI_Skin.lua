-- DeathSound - ElvUI_Skin.lua
-- Optionaler ElvUI-Skin. Greift nur wenn ElvUI aktiv ist.
-- Die Widgets kommen aus der Registry ns.skin (siehe Helfer in DeathSound.lua).

if not ElvUI then return end

local ADDON_NAME, ns = ...
local E = unpack(ElvUI)
local S = E:GetModule("Skins")

local function ApplySkin()
    local panel = ns.optionsPanel
    if not panel then return end

    panel:SetTemplate("Transparent")

    for _, btn in ipairs(ns.skin.button)     do S:HandleButton(btn) end
    for _, cb  in ipairs(ns.skin.checkbox)   do S:HandleCheckBox(cb) end
    for _, box in ipairs(ns.skin.editbox)    do S:HandleEditBox(box) end

    -- Moderne Dropdowns (DropdownButton): ElvUI skinnt sie selbst mit
    -- S:HandleDropDownBox(frame, width) (siehe ElvUI Config.lua / RaidUtility.lua).
    -- HandleDropDownBox setzt die Breite selbst, daher wird sie hier mitgegeben.
    for _, entry in ipairs(ns.skin.dropdown) do S:HandleDropDownBox(entry[1], entry[2]) end
end

local f = CreateFrame("Frame")
f:RegisterEvent("ADDON_LOADED")
f:SetScript("OnEvent", function(self, _, arg1)
    if arg1 ~= ADDON_NAME then return end
    self:UnregisterEvent("ADDON_LOADED")
    RunNextFrame(function()
        if E.private.skins and E.private.skins.blizzard and E.private.skins.blizzard.enable then
            ApplySkin()
        end
    end)
end)
