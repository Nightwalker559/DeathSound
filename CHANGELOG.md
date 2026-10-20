# Changelog

All notable changes to DeathSound are documented here.

---

## 1.2.2

### Added
- **Addon icon** — DeathSound now has an icon in the AddOns list (`Media\icon.tga`, same style as the other addons)
- **New emotes and sound** — images `Pumpkin_Cry.png` (crying jack-o'-lantern) and `Snowman_Cry.png`, sound `Headless_Horseman_Beckon.ogg`

### Changed
- **Emote images are 128×128** — all images were scaled down from 256×256 to the largest size the overlay can show (smaller download, same look)

### Removed
- `Cat_Sad.png` (stretched in the square overlay); if it was your selected image the addon falls back to the first one in the list

---

## 1.2.1

### Changed
- **One list file** — `Data\SoundList.lua` and `Data\ImageList.lua` are merged into `Data\MediaLists.lua` (sounds and images in one place, one line in the TOC); `UpdateLists.bat` writes this file. Run it again if you added your own sounds or images, the old two files are no longer loaded and can be deleted
- `UpdateLists.bat` always writes both lists: an empty or missing `Media\Sounds` / `Media\Images` folder now gives an empty list instead of leaving a stale one behind
- **Uniform file names** — all sounds and images now follow one scheme: words capitalized and joined by underscores (`Anime_Wow.ogg`, `Cat_Cry.png`); the list names shown in the dropdowns follow ("Anime Wow", "Cat Cry"). Your saved sound and image selections are carried over automatically

## 1.2.0

### Fixed
- **Empty size / offset field reset the value to the default** — leaving the overlay size or party offset box empty (Enter or focus loss) set it back to 64 px / 4 px; it now keeps the current value
- **Release Spirit anchor used the wrong popup** — the overlay was anchored to `StaticPopup1`, which is not the death dialog when another popup is already open; it now looks up the `DEATH` popup itself and falls back to the saved position if there is none
- **Party emote on the wrong frame with ElvUI** — ElvUI party frames were matched by index, so showing yourself in the party shifted every emote by one slot; frames are now matched by their unit like the default frames
- **Party emote image changed for everyone** — a second party member dying re-rolled the random image of emotes that were already visible, and every health update of a dead member re-rolled it again; the image is now picked once per death and only for that slot
- **Drag tooltip never showed** — the tooltip sat on a child frame with mouse disabled; it is now on the overlay itself (visible in edit mode)
- **Edit mode closed by revive** — reviving hid the overlay while it was unlocked for positioning
- **Unlock/Lock button label stale** — dying ends the edit mode; the button label is now refreshed when the Emote tab is shown
- Unknown slash arguments (`/ds foo`) now print the command list instead of opening the options
- **Party emote test needed a real group** — the test only looked for frames of party1-4, so it reported "No party frames visible" with ElvUI showing the group solo or in Edit Mode; it now uses whatever party frames are visible
- **Party emote random** — with Random every party member gets their own image (never the last pick and none that is already shown), and the test shows one random image per visible frame; the dropdown is dimmed while Random is on

### Changed
- **Shared namespace instead of globals** — `DeathSoundLocale`, `DEATHSOUND_SOUND_LIST`, `DEATHSOUND_IMAGE_LIST`, `DeathSound_OptionsPanel` and the `DeathSound_Build*Section` functions moved into the addon namespace; `UpdateLists.bat` writes `ns.SoundList` / `ns.ImageList` (run it again if you have your own generated lists)
- **Initialisation in one place** — defaults and the old index-to-name migrations are merged and run once; the overlay frames now exist before the options panel is built (no load-order caveat)
- **Performance** — `UNIT_HEALTH` is registered only for `party1`-`party4` instead of every unit; roster/zone events are coalesced into a single next-frame update
- Duplicate code replaced by helpers (checkbox, button, number box, radio dropdown, tooltip, random pick without retry loop, overlay placement, party emote placement); ElvUI skin takes its widgets from a registry instead of a hand-kept name list (removes entries for non-existing widgets)
- Checkboxes use `UICheckButtonTemplate` instead of the deprecated `InterfaceOptionsCheckButtonTemplate`
- ElvUI skin delay uses `RunNextFrame`
- **Folder structure** — files moved into `Core\`, `Data\`, `Locales\`, `UI\` and `Media\Sounds` / `Media\Images` like the other addons; `UpdateLists.bat` reads and writes the new locations
- **Options redesign** — flat tabs with an underline for the active one, sections with headings, a preview of the selected image next to the settings (Emote and Group tab), explanatory hints instead of silent dimming, the Sound ID moved to its own section, the version shown next to the title
- **File hints per tab** — the always-visible path block is replaced by a footer in the Sound, Emote and Group tabs ("Your own images: Media\Images, then run UpdateLists.bat and /reload")
- **Emote test button** — no longer shows the overlay on screen for 6 seconds; with Random every click shows a new image in the preview (disabled without Random)
- Subtitle and TOC notes mention the party emote
- **Locales** — `Locales\Locale.lua` merged into `enUS.lua` (two files: enUS, deDE)

### Removed
- Redundant `OnHide` save of the Sound ID (the box already saves on every change), unused frame names and dead `UnitIsUnit(partyN, "player")` checks

---

## 1.1.8

### Fixed
- **Party emote shown inside raid instances** — a small group (e.g. two players) in a raid instance stays a regular party, so `IsInRaid()` returned false and the party overlay still appeared; the overlay is now also suppressed whenever `IsInInstance()` reports instance type `raid`, and re-evaluated on `PLAYER_ENTERING_WORLD`

---

## 1.1.7

### Fixed
- **Taint on `UIDROPDOWNMENU_MENU_LEVEL`** — the options dropdowns now use the modern menu API instead of the legacy `UIDropDownMenu_*` functions
- Dropdown click overlays removed; ElvUI skin updated for the new dropdowns

### Changed
- Toc updated
---

## 1.1.6

### Fixed
- **Party emote triggered by raid deaths** — `party1`-`party4` unit tokens remain valid while in a raid (pointing to your own subgroup), so a subgroup member's death in a raid incorrectly triggered the party overlay; `UpdatePartyOverlay` now also checks `IsInRaid()` and hides the overlay while in a raid

---

## 1.1.5

### Fixed
- **Party emote shown for offline members** — `UpdatePartyOverlay` did not check `UnitIsConnected`; a disconnected party member's stale health data could register as dead/ghost, triggering the emote overlay incorrectly

---

## 1.1.4

### Changed
- **TOC interface bumped to support 12.1** — added `120100` (Midnight Patch 12.1 "Curse of Ula'tek") alongside `120007` (12.0.7 "Revelations"); no API changes required for this addon
- **Restart requirement corrected** — adding new sound/image files and running `UpdateLists.bat` only requires `/reload`, not a full game restart; README and `UpdateLists.bat` messaging updated accordingly

---

## 1.1.3

### Changed
- TOC updated

---

## 1.1.2

### Fixed
- **Emote test button tooltip wrong duration** — `OPT_TEST_EMOTE_TOOLTIP` stated "3 seconds" in both EN and DE; corrected to "6 seconds" to match the actual timer
- **ElvUI overlay button frame level** — all four dropdown overlay buttons in `ElvUI_Skin.lua` used `dd.Button:GetFrameLevel() + 1` after `S:HandleDropDownBox()`; replaced with `dd:GetFrameLevel() + 2` for consistency with the 1.1.1 fix and to guard against `.Button` being nil after ElvUI skinning

### Changed
- **TOC interface bumped to 120007** — Midnight Patch 12.0.7 (Revelations), released June 16, 2026; no API changes in 12.0.7 affect this addon

---

## 1.1.1

### Fixed
- **Dropdown overlay button fragility** — all four dropdown overlay buttons previously used `dd.Button:GetFrameLevel()` to set their frame level; replaced with `dd:GetFrameLevel() + 2` which does not depend on a `.Button` child existing in the template
- **Anchor dropdown tooltip never shown** — `OnEnter`/`OnLeave` was set on the `anchorDD` frame itself, but the overlay button sitting on top intercepted all mouse events; moved tooltip scripts to `anchorDDOverlay` so the tooltip correctly appears on hover

### Changed
- `DeathSound_BuildPartySection` — entire function body re-indented to 4 spaces for consistency with `DeathSound_BuildOverlaySection`
- Removed stale cached `list` reference from `buildOptionsPanel` and `DeathSound_BuildOverlaySection` — both functions previously captured `DEATHSOUND_SOUND_LIST` / `DEATHSOUND_IMAGE_LIST` at build time; all dropdown initializers already read the list fresh on each open
- Removed empty `-- ---- Info-Texte ----` comment at end of `DeathSound_BuildPartySection`

---

## 1.1.0

### Added
- New emote images added to the Images folder
- New sound added to the Sounds folder

### Fixed
- **Selection resets when adding new files** — sound and emote selections are now stored by **name** instead of index; adding new files to `Sounds\` or `Images\` no longer shifts the saved selection to a different entry; automatic migration from old `soundIndex` / `overlayImageIndex` / `partyOverlayImageIndex` runs on first load
- **`px (quadratisch)` hardcoded** — replaced with locale key `OPT_OVERLAY_SIZE_UNIT`; now correctly shown as "px (square)" in English and "px (quadratisch)" in German

### Changed
- `DEFAULTS` and `OVERLAY_DEFAULTS` tables sorted alphabetically — SavedVariables file (`DeathSoundDB`) is now written in consistent alphabetical key order

---

## 1.0.9

### New
- **Party Member Emote** — new dedicated **Group** tab in the options panel with:
  - Enable toggle — independent from the main DeathSound toggle
  - Image dropdown — picks from the same image list as the death overlay
  - Test button — previews the emote on all visible party frames for 6 seconds; prints a chat message if no party is active
  - Random checkbox — shows a different image on each party member death, never repeating the same one twice in a row
  - Anchor dropdown — Left / Right / Top / Bottom (default: Left)
  - Offset input field — configurable px distance between emote and party frame (0–64 px, default: 4 px)
  - Supports Default UI (`PartyMemberFrame1–4`, `CompactPartyFrameMember1–5`) and ElvUI (`ElvUF_PartyGroup1UnitButton1–4`)
  - Image size adapts automatically to party frame dimensions; Top/Bottom capped at 96 px
  - Overlay stays visible until the player is resurrected
  - ElvUI skin support for all new UI elements
  - New locale keys in EN and DE

### Added
- New emote images added to the Images folder
- `OPT_OVERLAY_UNLOCK_TIP` locale key added to both EN and DE — was missing, tooltip showed raw key name `[OPT_OVERLAY_UNLOCK_TIP]` instead of text

### Fixed
- **`enUS.lua` syntax error** — `OPT_OVERLAY_SIZE` and `OPT_OVERLAY_UNLOCK` were on the same line without a separator, causing a Lua parse error that prevented the addon from loading for all non-deDE clients
- **Image dropdown stale reference** — `UIDropDownMenu_Initialize` and `RefreshImageDropdown` in the Emote tab now read `DEATHSOUND_IMAGE_LIST` fresh on each open instead of using a cached reference (same fix previously applied to the Sound tab in 1.0.8)
- **Variable shadowing in test emote button** — inner `local list` inside the `OnClick` closure shadowed the outer `list` captured at build time; renamed to `currentList` for consistency and correctness
- **Overlay not hiding on resurrection when unlocked** — `PLAYER_ALIVE` / `PLAYER_UNGHOST` now always hides the overlay unless a test preview timer is currently running; previously the overlay stayed visible in edit mode after being revived
- **`UIRadioButtonTemplate` crash** — `.Text` child no longer exists in WoW Midnight; replaced with manually created `FontString` per button
- **Party frame detection** — `GetPartyFrame` now correctly handles all three UI variants: ElvUI (`ElvUF_PartyGroup1UnitButton1–4`), Midnight Default (`CompactPartyFrameMember1–5`), and older Default UI (`PartyFrame.MemberFrame1–4`); player's own frame is filtered in all cases via `f.unit` and `UnitIsUnit`

### Changed
- `UpdateSoundList.bat` and `UpdateImageList.bat` merged into a single **`UpdateLists.bat`** — scans both `Sounds\` and `Images\` in one run, reports per-folder counts and a combined error summary
- All locale references to the old bat filenames updated (`UpdateSoundList.bat` / `UpdateImageList.bat` → `UpdateLists.bat`)
- README German section updated to match English: `.png` added as recommended format, correct max size (`128×128` px), corrected step descriptions, bat filename updated
- Party Member Emote moved from Emote tab into its own dedicated **Group** tab — anchor selection changed from 4 radio buttons to a compact dropdown, offset input placed inline next to it
- Options panel now has three tabs: **Sound**, **Emote**, **Group**
- Combined info text (Sounds path, Emotes path, UpdateLists hint) moved above the tab buttons directly below the main enable checkbox — removed from Sound tab and Group tab individually
- Sound tab section headers ("Custom Sound File", "WoW Sound ID") removed — checkboxes are self-explanatory without separate labels
- Locale files cleaned up — removed all unused keys, restructured with section comments (Sound Tab / Emote Tab / Group Tab / Messages)

---

## 1.0.8

### Added
- New emote images added to the Images folder
- Random Emote mode: shows a random image from the list on each death, never repeating the same one twice in a row
- Random checkbox in the Emote tab next to the image dropdown (same pattern as Sound tab)
- **Test button** for emotes: previews the selected emote image for 6 seconds without dying — respects Random and Popup Anchor mode
- Clicking the test button while a preview is active restarts the 6 second timer
- **PNG support** for emote images — `.png` is now the recommended format (smaller files, alpha channel, universally compatible)
- `.tga` files continue to work as legacy format

### Fixed
- `testTimer` moved to module level — prevents handle loss if the panel were ever rebuilt
- `UIDropDownMenu_Initialize` in the Sound tab now reads `DEATHSOUND_SOUND_LIST` fresh on each open instead of using a stale cached reference

### Changed
- `UpdateRandomMode` extracted as a named function instead of duplicated inline code
- `UpdateImageList.bat` now scans for both `.png` and `.tga` files (PNG first)
- `ImageList.lua` and `Images/README.txt` updated to reflect PNG as primary format

---

## 1.0.7

### Added
- Options panel: two tabs — **Sound** and **Emote** — for a cleaner layout
- Emote tab: option to anchor the overlay to the left of the **Release Spirit** popup (automatically sized to match the popup height)
- When popup anchor is active, manual size/lock/reset controls are disabled automatically
- Active tab is highlighted in cyan, inactive tab in gray

### Fixed
- `HideOverlay` function had inverted lock condition and was never called — removed, replaced with direct `overlayFrame:Hide()`
- `AnchorToPopup` was recreated on every `ShowOverlay` call — extracted to module-level function
- `UpdatePopupMode` forward declaration removed — function now defined after all widgets it references
- `OVERLAY_DEFAULTS` were applied twice (in `ADDON_LOADED` and `BuildOverlaySection`) — kept only the necessary safety check in `BuildOverlaySection`
- Duplicate `resetBtn:SetScript` bug removed (was set twice with identical handlers)

### Changed
- Options panel split into **Sound** and **Emote** tabs
- Overlay size input is now a free-text EditBox (32–128 px, clamped on confirm) instead of fixed buttons
- `DeathSound_BuildOverlaySection` no longer takes an anchor frame argument — receives `imageFrame` directly

---

## 1.0.6

### Added
- **Death Overlay** — displays a custom `.tga` image on screen when your character dies
- `Images\` subfolder for overlay image files (recommended: 256×256 or 512×512 px, alpha channel supported)
- `ImageList.lua` manifest for registering images (same pattern as SoundList.lua)
- `UpdateImageList.bat` — scans `Images\` and writes `ImageList.lua` automatically
- Image dropdown in options panel to select the active overlay image
- Four fixed size buttons (32×32, 64×64, 96×96, 128×128) to set overlay size
- Lock / Unlock button — unlocks the overlay for drag-to-move in edit mode
- Reset Position button to re-center the overlay on screen
- Overlay position, size and lock state saved in `DeathSoundDB`
- Overlay respects the global enable toggle — hidden when DeathSound is disabled
- ElvUI skin support for all new overlay option elements
- Localization for all new overlay strings (EN/DE)

### Fixed
- German locale: inconsistent umlaut substitutions cleaned up throughout (ä, ö, ü now used correctly everywhere)
- Overlay section alignment in options panel — all elements now flush left with the rest of the panel

### Changed
- Overlay size is controlled exclusively via the four fixed size buttons — no freeform resizing

---

## 1.0.5

### Added
- New sound files added to the Sounds folder

### Fixed
- `buildOptionsPanel` was declared twice as a forward declaration — duplicate removed
- `UpdateModeUI` was called in `randomCB:OnClick` before it existed in scope — fixed via inner forward declaration inside `buildOptionsPanel`
- `StopCurrentSound` extracted as a dedicated function to avoid duplicated stop logic across all three play paths

### Changed
- `UpdateDropdownText` / `UpdateDropdownTextLocal` pattern replaced with `dropdownRef` — a module-level reference to the dropdown frame, used directly in `PlaySelectedSound` via `UIDropDownMenu_SetText`
- `UpdateModeUI` moved to after all widgets are defined, ensuring all upvalues are valid at call time

---

## 1.0.4

### Added
- Random sound mode: plays a random sound from the list on each death, never repeating the same sound twice in a row
- Random checkbox in the options panel next to the Test button

### Fixed
- Random mode checkbox did not correctly update all UI elements on toggle — now calls `UpdateModeUI()` consistently
- Dropdown text did not refresh after a random pick — now shows which sound was last played
- `UpdateModeUI` used a single ambiguous alpha variable for two different purposes — split into `fileDimmed` and `ddDimmed` for clarity

---

## 1.0.3

### Fixed
- `buildOptionsPanel` was incorrectly declared as a global function — now properly local via forward declaration
- Pressing Escape in the Sound ID EditBox restored the wrong value — snapshot is now saved on focus gained
- Dropdown overlay remained clickable when Custom File mode was disabled
- `OnHide` panel callback used an unnecessary global `_G` lookup — replaced with closure

### Changed
- `ddLabel`, `idLabel` and `idHint` are now correctly dimmed when switching modes

---

## 1.0.2

### Added
- WoW Sound ID mode: play any in-game sound by entering its ID from Wowhead
- New sound files added to the Sounds folder
- New locale keys for Sound ID section (EN/DE)

### Changed
- Test buttons no longer show ">>" prefix — cleaner look
- Options panel now has two sections: Custom File and WoW Sound ID
- Both modes are mutually exclusive and toggle each other off automatically

---

## 1.0.1

### Added
- New sound files added to the Sounds folder

### Changed
- All included sound files converted to `.ogg` format

---

## 1.0.0

### Added
- Initial release
- Plays a custom sound via the Master audio channel on character death
- In-game options panel (ESC → Options → AddOns → DeathSound)
- Sound dropdown selector with live test button
- `UpdateSoundList.bat` — auto-generates `SoundList.lua` from the Sounds folder
- ElvUI skin — automatically applied when ElvUI is active
- Debounce: sound plays exactly once per death regardless of how often the game fires the death event
- Slash commands: `/deathsound`, `/deathsound test`, `/deathsound on/off`, `/ds`
- Localization: English and German