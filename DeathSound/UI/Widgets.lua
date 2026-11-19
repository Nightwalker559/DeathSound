-- DeathSound - Widgets.lua
-- Shared widget and layout helpers (ns.Create*, ns.SetTooltip, ns.SetDimmed) used by the
-- options panel and its tabs. Every skinnable widget registers itself in ns.skin,
-- which UI\ElvUI_Skin.lua walks.

local _, ns = ...

-- Widgets that ElvUI_Skin touches (the helpers below register themselves).
ns.skin = { button = {}, checkbox = {}, editbox = {}, dropdown = {} }

-- Adds a widget to the skin registry; `extra` (e.g. the dropdown width) is stored with it.
function ns.RegisterSkin(kind, widget, extra)
    local registry = ns.skin[kind]
    registry[#registry + 1] = extra and { widget, extra } or widget
end

-- Dims a widget and disables it (FontStrings have no SetEnabled).
function ns.SetDimmed(widget, dimmed)
    widget:SetAlpha(dimmed and 0.4 or 1)
    if widget.SetEnabled then widget:SetEnabled(not dimmed) end
end

-- Text label; with `width` it is left-aligned and wraps.
function ns.CreateLabel(parent, text, template, width)
    local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlightSmall")
    if width then
        fs:SetJustifyH("LEFT")
        fs:SetWidth(width)
    end
    fs:SetText(text)
    return fs
end

-- Tooltip for a widget; text may be a string or a function.
-- HookScript instead of SetScript so template handlers (buttons, dropdowns) are kept.
function ns.SetTooltip(widget, text, anchor)
    widget:HookScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, anchor or "ANCHOR_RIGHT")
        GameTooltip:SetText(type(text) == "function" and text() or text, 1, 1, 1)
        GameTooltip:Show()
    end)
    widget:HookScript("OnLeave", function() GameTooltip:Hide() end)
end

function ns.CreateCheckBox(parent, name, text, tooltip, checked, onClick)
    -- Like the deprecated InterfaceOptionsCheckButtonTemplate: 26x26, label in .Text
    local cb = CreateFrame("CheckButton", name, parent, "UICheckButtonTemplate")
    cb:SetSize(26, 26)
    cb.Text:SetText(text)
    cb:SetChecked(checked)
    if onClick then cb:SetScript("OnClick", onClick) end
    if tooltip then ns.SetTooltip(cb, tooltip) end
    ns.RegisterSkin("checkbox", cb)
    return cb
end

function ns.CreateButton(parent, name, width, height, text, tooltip, onClick)
    local btn = CreateFrame("Button", name, parent, "UIPanelButtonTemplate")
    btn:SetSize(width, height)
    btn:SetText(text)
    if onClick then btn:SetScript("OnClick", onClick) end
    if tooltip then ns.SetTooltip(btn, tooltip) end
    ns.RegisterSkin("button", btn)
    return btn
end

-- Number box: Enter/focus loss commits, Escape discards. An empty box keeps the
-- current value. apply(value) sets the (clamped) value and returns it.
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

    ns.RegisterSkin("editbox", box)
    return box
end

-- Radio dropdown (menu API, no taint on UIDROPDOWNMENU_*) over a name/file list.
-- getName returns the saved name, onSelect(entry) saves the selection.
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
    ns.RegisterSkin("dropdown", dd, ns.DROPDOWN_WIDTH)
    return dd
end

-- ---- Layout helpers for the options panel ----

-- Section heading with a line below it (the caller sets the position)
function ns.CreateHeader(parent, text, width)
    local fs = ns.CreateLabel(parent, text, "GameFontNormal")
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.3, 0.3, 0.3, 0.8)
    line:SetSize(width, 1)
    line:SetPoint("TOPLEFT", fs, "BOTTOMLEFT", 0, -4)
    return fs
end

-- Grey explanatory text (the caller sets the position)
function ns.CreateHint(parent, text, width)
    return ns.CreateLabel(parent, text, "GameFontDisableSmall", width)
end

-- Hint about custom files at the bottom of a tab, with a line above it
function ns.CreateFooter(parent, text)
    local fs = ns.CreateHint(parent, text, 560)
    fs:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 0, 0)
    local line = parent:CreateTexture(nil, "ARTWORK")
    line:SetColorTexture(0.25, 0.25, 0.25, 0.6)
    line:SetSize(560, 1)
    line:SetPoint("BOTTOMLEFT", fs, "TOPLEFT", 0, 6)
    return fs
end

-- Preview box of the selected image (Emote and Group tab); returns an update function.
local PREVIEW_X = 390   -- preview column to the right of the settings

function ns.CreatePreview(parent, getName)
    local hdr = ns.CreateHeader(parent, ns.L("SECTION_PREVIEW"), 150)
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
        tex:SetTexture(ns.ImagePath(entry))
        caption:SetText(entry and entry.name or "")
    end
end
