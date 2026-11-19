-- DeathSound - Database.lua
-- SavedVariables init: fills defaults and migrates saved selections.

local _, ns = ...

-- Old index key (e.g. soundIndex) -> saved name
local function MigrateIndexToName(db, nameKey, indexKey, list)
    if db[nameKey] == nil or db[nameKey] == "" then
        local entry = db[indexKey] and list[db[indexKey]] or list[1]
        if entry then db[nameKey] = entry.name end
    end
    db[indexKey] = nil
end

-- Saved names from before the media files were renamed: same name ignoring case
-- and separators (e.g. "anime wow" -> "Anime Wow") -> set to the new name
local function Squash(s) return (s:lower():gsub("[^%w]", "")) end

local function MigrateRenamedName(db, nameKey, list)
    local name = db[nameKey]
    if type(name) ~= "string" or name == "" then return end
    for _, entry in ipairs(list) do
        if entry.name == name then return end
    end
    local squashed = Squash(name)
    for _, entry in ipairs(list) do
        if Squash(entry.name) == squashed then db[nameKey] = entry.name return end
    end
end

function ns.InitDB()
    if type(DeathSoundDB) ~= "table" then DeathSoundDB = {} end
    local db = DeathSoundDB
    -- overlayWidth/overlayHeight were always equal; must run before the defaults fill overlaySize
    if db.overlaySize == nil and type(db.overlayWidth) == "number" then db.overlaySize = db.overlayWidth end
    db.overlayWidth, db.overlayHeight = nil, nil
    for k, v in pairs(ns.defaults) do
        if db[k] == nil then db[k] = v end
    end
    MigrateIndexToName(db, "soundName",             "soundIndex",             ns.SoundList)
    MigrateIndexToName(db, "overlayImageName",      "overlayImageIndex",      ns.ImageList)
    MigrateIndexToName(db, "partyOverlayImageName", "partyOverlayImageIndex", ns.ImageList)
    MigrateRenamedName(db, "soundName",             ns.SoundList)
    MigrateRenamedName(db, "overlayImageName",      ns.ImageList)
    MigrateRenamedName(db, "partyOverlayImageName", ns.ImageList)
end
