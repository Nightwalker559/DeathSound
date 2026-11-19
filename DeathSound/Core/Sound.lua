-- DeathSound - Sound.lua
-- Plays the selected sound file or WoW sound ID (ns.PlaySelectedSound, ns.PlayGameSound).
-- ns.soundDropdown is set by the options panel; Random refreshes its menu.

local _, ns = ...
local L      = ns.L
local PREFIX = ns.PREFIX

local SOUND_PATH = "Interface\\AddOns\\DeathSound\\Media\\Sounds\\"

local currentSoundHandle = nil

local function StopCurrentSound()
    if currentSoundHandle then
        StopSound(currentSoundHandle)
        currentSoundHandle = nil
    end
end

function ns.PlayGameSound(rawID)
    local id = tonumber(rawID)
    if not id or id <= 0 then
        print(PREFIX .. L("MSG_INVALID_ID"))
        return
    end
    StopCurrentSound()
    local ok, handle = PlaySound(id, "Master")
    if ok then
        currentSoundHandle = handle
    else
        print(PREFIX .. L("MSG_ID_ERROR") .. id)
    end
end

function ns.PlaySelectedSound(force)
    local db = DeathSoundDB
    if not force and not db.enabled then return end

    if db.useGameSound then
        ns.PlayGameSound(db.gameSoundID)
        return
    end

    local list = ns.SoundList
    if #list == 0 then
        print(PREFIX .. L("MSG_NO_SOUNDS"))
        return
    end

    local entry
    if db.randomSound and #list > 1 then
        entry = list[ns.PickRandomIndex(#list, ns.ResolveIndex(list, db.soundName))]
        db.soundName = entry.name
        if ns.soundDropdown then ns.soundDropdown:GenerateMenu() end
    else
        entry = ns.ResolveEntry(list, db.soundName)
    end

    StopCurrentSound()
    local path = SOUND_PATH .. entry.file
    local ok, handle = PlaySoundFile(path, "Master")
    if ok then
        currentSoundHandle = handle
    else
        print(PREFIX .. L("MSG_FILE_ERROR") .. path)
        print(PREFIX .. L("MSG_FILE_HINT"))
    end
end
