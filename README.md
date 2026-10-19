# DeathSound — Sound & Emote

Plays a sound and shows an emote image when your character dies, and optionally an emote next to the unit frame of a dead party member.

## Installation
Copy the `DeathSound` folder to `World of Warcraft\_retail_\Interface\AddOns\`.

## Adding Your Own Sounds
1. Put `.ogg` or `.mp3` files into `DeathSound\Media\Sounds\`.
2. Rename `UpdateLists.bat.txt` (addon folder) to `UpdateLists.bat` and run it. It rewrites `Data\SoundList.lua`.
3. `/reload`, then pick the sound in the options.

## Adding Your Own Emote Images
1. Put `.png` (recommended) or `.tga` files, up to `128×128` px, into `DeathSound\Media\Images\`.
2. Run `UpdateLists.bat`. It rewrites `Data\ImageList.lua`.
3. `/reload`, then use the **Emote** tab:
   - Enable **Show image overlay on death** and pick an image, or enable **Random**
   - **Anchor to Release Spirit popup** places the image next to the death dialog
   - **Unlock (Edit Mode)** lets you drag the overlay; size is 32–128 px

## Group Emote
The **Group** tab shows an emote next to the unit frame of a dead party member (default UI, raid-style party frames and ElvUI). Choose the image, the side of the frame (left, right, top, bottom) and the offset (0–64 px). **Test** previews it for 6 seconds. It is never shown in raid groups or raid instances.

## Commands
| Command | Action |
|---|---|
| `/deathsound` or `/ds` | Open the options |
| `/ds test` | Play the current sound |
| `/ds on` / `/ds off` | Enable / disable the addon |

## Compatibility
World of Warcraft: Midnight 12.1 and 12.1.5 (Interface 120100, 120105). ElvUI is skinned automatically.

Author: Nightwalker559
