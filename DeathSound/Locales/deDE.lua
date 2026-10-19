-- DeathSound - Locales\deDE.lua
-- Deutsch

if GetLocale() ~= "deDE" then return end

local _, ns = ...
local L = ns.L

L["ADDON_TITLE"]          = "DeathSound"
L["ADDON_SUBTITLE"]       = "Spielt einen Sound und zeigt ein Emote, wenn du stirbst, und ein Emote, wenn ein Gruppenmitglied stirbt."
L["TAB_SOUND"]            = "Sound"
L["TAB_IMAGE"]            = "Emote"
L["TAB_GROUP"]            = "Gruppe"

L["OPT_ENABLE"]           = "DeathSound aktivieren"
L["OPT_ENABLE_TOOLTIP"]   = "Addon ein- oder ausschalten."

L["DD_NO_SOUNDS"]         = "|cffff6600Keine Sounds in MediaLists.lua eingetragen|r"
L["DD_NO_IMAGES"]         = "|cffff6600Keine Bilder in MediaLists.lua eingetragen|r"

-- Abschnitte und Hinweise
L["SECTION_SOUND_FILE"]   = "Sounddatei"
L["SECTION_SOUND_ID"]     = "WoW-Sound-ID"
L["SECTION_IMAGE"]        = "Bild"
L["SECTION_POSITION"]     = "Position und Größe"
L["SECTION_PREVIEW"]      = "Vorschau"
L["SECTION_PARTY"]        = "Gruppen-Emote"
L["SECTION_PARTY_POSITION"] = "Position"
L["HINT_POPUP_MODE"]      = "Größe und Position folgen dem Popup."
L["HINT_FILES_SOUND"]     = "Eigene Sounds (.ogg, .mp3): |cffffffffMedia\\Sounds|r, danach |cffffffffUpdateLists.bat|r ausführen und |cffffffff/reload|r."
L["HINT_FILES_IMAGE"]     = "Eigene Bilder (.png, .tga): |cffffffffMedia\\Images|r, danach |cffffffffUpdateLists.bat|r ausführen und |cffffffff/reload|r."

-- Sound Tab
L["OPT_USE_FILE"]         = "Eigene Sounddatei verwenden"
L["OPT_TEST_BUTTON"]      = "Testen"
L["OPT_TEST_TOOLTIP"]     = "Den gewählten Sound jetzt abspielen."
L["OPT_RANDOM"]           = "Zufällig"
L["OPT_RANDOM_TOOLTIP"]   = "Bei jedem Tod einen zufälligen Sound aus der Liste abspielen."
L["OPT_USE_ID"]           = "WoW Sound-ID verwenden"
L["OPT_ID_LABEL"]         = "Sound-ID (von Wowhead):"

-- Emote Tab
L["OPT_OVERLAY_ENABLE"]         = "Bild-Overlay beim Tod anzeigen"
L["OPT_OVERLAY_ENABLE_TOOLTIP"] = "Zeigt ein eigenes Bild wenn dein Charakter stirbt."
L["OPT_TEST_EMOTE_TOOLTIP"]     = "Zeigt ein weiteres zufälliges Bild in der Vorschau. Nur mit Zufall verfügbar."
L["OPT_RANDOM_EMOTE_TOOLTIP"]   = "Bei jedem Tod ein zufälliges Emote-Bild aus der Liste anzeigen."
L["OPT_OVERLAY_SIZE"]           = "Größe:"
L["OPT_OVERLAY_SIZE_UNIT"]      = "px (quadratisch, 32 - 128)"
L["OPT_OVERLAY_UNLOCK"]         = "Entsperren (Bearbeiten)"
L["OPT_OVERLAY_UNLOCK_TIP"]     = "Entsperrt das Overlay damit du es an eine neue Position ziehen kannst."
L["OPT_OVERLAY_LOCK"]           = "Position sperren"
L["OPT_OVERLAY_LOCK_TIP"]       = "Sperrt das Overlay an seiner aktuellen Position."
L["OPT_OVERLAY_ANCHOR_POPUP"]     = "An 'Geist freilassen'-Popup ankern"
L["OPT_OVERLAY_ANCHOR_POPUP_TIP"] = "Positioniert das Bild links neben dem Todes-Dialog wenn du stirbst."
L["OPT_OVERLAY_RESET"]          = "Position zurücksetzen"
L["OPT_OVERLAY_RESET_TIP"]      = "Verschiebt das Overlay zurück in die Bildschirmmitte."
L["OVERLAY_DRAG_TIP"]           = "Linksklick und ziehen zum Verschieben"

-- Group Tab
L["OPT_PARTY_ENABLE"]           = "Emote bei Tod eines Gruppenmitglieds anzeigen"
L["OPT_PARTY_ENABLE_TOOLTIP"]   = "Zeigt ein Emote-Bild neben dem Frame eines Gruppenmitglieds wenn es stirbt."
L["OPT_PARTY_TEST_TOOLTIP"]     = "Zeigt das Gruppen-Emote für 6 Sekunden auf allen sichtbaren Party-Frames."
L["OPT_PARTY_RANDOM_TOOLTIP"]   = "Jedes Gruppenmitglied bekommt beim Tod ein eigenes zufälliges Bild."
L["OPT_PARTY_ANCHOR"]           = "Anker-Position:"
L["OPT_PARTY_ANCHOR_LEFT"]      = "Links"
L["OPT_PARTY_ANCHOR_RIGHT"]     = "Rechts"
L["OPT_PARTY_ANCHOR_TOP"]       = "Oben"
L["OPT_PARTY_ANCHOR_BOTTOM"]    = "Unten"
L["OPT_PARTY_ANCHOR_TIP"]       = "Auf welcher Seite des Party-Frames das Emote erscheinen soll."
L["OPT_PARTY_OFFSET"]           = "Abstand:"
L["MSG_NO_PARTY"]               = "Keine Gruppenfenster sichtbar. Tritt einer Gruppe bei oder zeige die Gruppenfenster an (Bearbeitungsmodus oder ElvUI)."

-- Messages
L["MSG_ENABLED"]          = "Aktiviert."
L["MSG_DISABLED"]         = "Deaktiviert."
L["MSG_NO_SOUNDS"]        = "Keine Sounds in MediaLists.lua eingetragen!"
L["MSG_FILE_ERROR"]       = "Sound konnte nicht abgespielt werden: "
L["MSG_FILE_HINT"]        = "Datei vorhanden? Nach dem Hinzufügen /reload ausführen!"
L["MSG_INVALID_ID"]       = "Ungültige Sound-ID! Bitte eine Zahl größer als 0 eingeben."
L["MSG_ID_ERROR"]         = "Sound-ID konnte nicht abgespielt werden: "
L["MSG_HELP"]             = "Befehle:"
L["MSG_HELP_OPEN"]        = "  /deathsound        - Optionen öffnen"
L["MSG_HELP_TEST"]        = "  /deathsound test   - Sound testen"
L["MSG_HELP_ON"]          = "  /deathsound on     - Aktivieren"
L["MSG_HELP_OFF"]         = "  /deathsound off    - Deaktivieren"
