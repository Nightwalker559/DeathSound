-- DeathSound - Locale\Locale.lua
-- Initialisiert die Locale-Tabelle (ns.L). Die Locale-Dateien schreiben L["KEY"] = "...",
-- der Code liest L("KEY"). Fallback: Key-Name wenn String fehlt.

local _, ns = ...

ns.L = setmetatable({}, {
    __index = function(_, key)
        return "[" .. tostring(key) .. "]"
    end,
    __call = function(self, key)
        return self[key]
    end,
})
