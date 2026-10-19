-- DeathSound - Locale\enUS.lua
-- English (default fallback)

local _, ns = ...
local L = ns.L

L["ADDON_TITLE"]          = "DeathSound"
L["ADDON_SUBTITLE"]       = "Plays a sound and shows an emote when your character dies."
L["TAB_SOUND"]            = "Sound"
L["TAB_IMAGE"]            = "Emote"
L["TAB_GROUP"]            = "Group"

L["OPT_ENABLE"]           = "Enable DeathSound"
L["OPT_ENABLE_TOOLTIP"]   = "Toggle the addon on or off."
L["OPT_INFO_PATH"]        = "Sounds:"
L["OPT_INFO_PATH_VALUE"]  = "Interface\\AddOns\\DeathSound\\Media\\Sounds\\"
L["OPT_INFO_PATH_IMG"]    = "Emotes:"
L["OPT_INFO_PATH_VALUE_IMG"]  = "Interface\\AddOns\\DeathSound\\Media\\Images\\"
L["OPT_INFO_REGISTER_COMBINED"] = "Then run |cffffffff UpdateLists.bat |cff888888, then |cffffffff /reload |cff888888is enough. Supported: .ogg, .mp3 (sound) — .png, .tga (emote)."

L["DD_NO_SOUNDS"]         = "|cffff6600No sounds registered in SoundList.lua|r"
L["DD_NO_IMAGES"]         = "|cffff6600No images registered in ImageList.lua|r"

-- Sound Tab
L["OPT_USE_FILE"]         = "Use custom sound file"
L["OPT_SELECT_SOUND"]     = "Select Sound:"
L["OPT_TEST_BUTTON"]      = "Test"
L["OPT_TEST_TOOLTIP"]     = "Play the selected sound right now."
L["OPT_RANDOM"]           = "Random"
L["OPT_RANDOM_TOOLTIP"]   = "Play a random sound from the list on each death."
L["OPT_USE_ID"]           = "Use WoW Sound ID"
L["OPT_ID_LABEL"]         = "Sound ID (from Wowhead):"

-- Emote Tab
L["OPT_OVERLAY_ENABLE"]         = "Show image overlay on death"
L["OPT_OVERLAY_ENABLE_TOOLTIP"] = "Displays a custom image when your character dies."
L["OPT_SELECT_IMAGE"]           = "Select Image:"
L["OPT_TEST_EMOTE_TOOLTIP"]     = "Preview the selected emote image for 6 seconds."
L["OPT_RANDOM_EMOTE_TOOLTIP"]   = "Show a random emote image from the list on each death."
L["OPT_OVERLAY_SIZE"]           = "Size:"
L["OPT_OVERLAY_SIZE_UNIT"]      = "px (square)"
L["OPT_OVERLAY_UNLOCK"]         = "Unlock (Edit Mode)"
L["OPT_OVERLAY_UNLOCK_TIP"]     = "Unlocks the overlay so you can drag it to a new position."
L["OPT_OVERLAY_LOCK"]           = "Lock Position"
L["OPT_OVERLAY_LOCK_TIP"]       = "Locks the overlay in its current position."
L["OPT_OVERLAY_ANCHOR_POPUP"]     = "Anchor to Release Spirit popup"
L["OPT_OVERLAY_ANCHOR_POPUP_TIP"] = "Positions the image to the left of the Release Spirit dialog when you die."
L["OPT_OVERLAY_RESET"]          = "Reset Position"
L["OPT_OVERLAY_RESET_TIP"]      = "Moves the overlay back to the center of the screen."
L["OVERLAY_DRAG_TIP"]           = "Left-click and drag to move"

-- Group Tab
L["OPT_PARTY_ENABLE"]           = "Show emote on party member death"
L["OPT_PARTY_ENABLE_TOOLTIP"]   = "Displays an emote image next to the frame of any party member who dies."
L["OPT_PARTY_SELECT_IMAGE"]     = "Party emote image:"
L["OPT_PARTY_TEST_TOOLTIP"]     = "Preview the party emote on all visible party frames for 6 seconds."
L["OPT_PARTY_RANDOM_TOOLTIP"]   = "Show a random emote image on each party member death."
L["OPT_PARTY_ANCHOR"]           = "Anchor position:"
L["OPT_PARTY_ANCHOR_LEFT"]      = "Left"
L["OPT_PARTY_ANCHOR_RIGHT"]     = "Right"
L["OPT_PARTY_ANCHOR_TOP"]       = "Top"
L["OPT_PARTY_ANCHOR_BOTTOM"]    = "Bottom"
L["OPT_PARTY_ANCHOR_TIP"]       = "Choose which side of the party frame the emote appears on."
L["OPT_PARTY_OFFSET"]           = "Offset:"
L["MSG_NO_PARTY"]               = "No party frames visible — join a group first."

-- Messages
L["MSG_ENABLED"]          = "Enabled."
L["MSG_DISABLED"]         = "Disabled."
L["MSG_NO_SOUNDS"]        = "No sounds found in SoundList.lua!"
L["MSG_FILE_ERROR"]       = "Could not play sound: "
L["MSG_FILE_HINT"]        = "File missing? Run /reload after adding new files!"
L["MSG_INVALID_ID"]       = "Invalid Sound ID! Please enter a number greater than 0."
L["MSG_ID_ERROR"]         = "Could not play Sound ID: "
L["MSG_HELP"]             = "Commands:"
L["MSG_HELP_OPEN"]        = "  /deathsound        - Open options"
L["MSG_HELP_TEST"]        = "  /deathsound test   - Test current sound"
L["MSG_HELP_ON"]          = "  /deathsound on     - Enable"
L["MSG_HELP_OFF"]         = "  /deathsound off    - Disable"
