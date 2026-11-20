# DeathSound — Sound & Emote

Plays a sound and shows an emote image when your character dies, and optionally an emote next to the unit frame of a dead party member.

For World of Warcraft Retail.

**Author:** Nightwalker559 · **License:** MIT with AI restriction

---

## Features

- **Sound tab:** plays a sound from the list (or a random one on each death), or a WoW sound ID from Wowhead. **Test** plays it right away.
- **Emote tab:** shows an image on death, a fixed one or **Random**. **Anchor to Release Spirit popup** places it next to the death dialog; **Unlock (Edit Mode)** lets you drag it (size 32-128 px).
- **Group tab:** an emote next to the unit frame of a dead party member (default UI, raid-style party frames and ElvUI). Choose the image or **Random** (each member gets their own), the side of the frame and the offset (0-64 px). **Test** previews it for 6 seconds. It is never shown in raid groups or raid instances.

## Adding your own media

1. Put `.ogg` or `.mp3` files into `DeathSound\Media\Sounds\`, and `.png` (recommended) or `.tga` images up to `128×128` px into `DeathSound\Media\Images\`.
2. Rename `UpdateLists.bat.txt` (addon folder) to `UpdateLists.bat` and run it. It rewrites `Data\MediaLists.lua` for sounds and images.
3. `/reload`, then pick them in the options.

## Commands

| Command | Action |
| --- | --- |
| `/deathsound`, `/ds` | Open the options |
| `/ds test` | Play the current sound |
| `/ds on`, `/ds off` | Enable or disable the addon |

---

See the [changelog](https://github.com/Nightwalker559/DeathSound/blob/main/CHANGELOG.md) for the version history.

## Feedback

Found a bug or have an idea? [Open an issue on GitHub](https://github.com/Nightwalker559/DeathSound/issues).

## License

MIT with AI restriction (no use for AI or machine learning), see [LICENSE.md](https://github.com/Nightwalker559/DeathSound/blob/main/LICENSE.md).
