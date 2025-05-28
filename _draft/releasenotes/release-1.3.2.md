@here I am pleased to announce the newest release of SpellActivationOverlay, version 1.3.2

This release focuses on supporting runes for Season of Discovery and starts adding new things on Cataclysm. I've been working around the clock (the patch note below speaks for itself) but I still have a ton of work to do. Expect more changes coming soon™. Stay tuned!

## General
Texture files have been removed from the addon package when they are already included in Cataclysm game files. As such, the archive is now significantly smaller for Cataclysm than other flavors, despite using more textures than ever before.

## Classes
### :dk:  Death Knight
The Death Knight class experiments the upcoming rework for Cataclysm. Ideally, you shouldn't see any difference for Wrath Classic. Existing Death Knight effects were fixed for Cataclysm. Make sure to report issues you would encounter, thank you :)

New Spell Alerts:
- Crimson Scourge (Cataclysm)
- Sudden Doom (Cataclysm)
- Will of the Necropolis (Cataclysm)

New Glowing Buttons:
- Blood Boil, during Crimson Scourge (Cataclysm)
- Death Coil, during Sudden Doom (Cataclysm)
- Icy Touch, during Rime (Cataclysm)
- Obliterate, during Killing Machine (Cataclysm)
- Rune Tap, during Will of the Necropolis (Cataclysm)
### :druid:  Druid
New Spell Alerts:
- Lunar Eclipse and Solar Eclipse (Cataclysm)
- Shooting Stars (Cataclysm)

Updated Spell Alert:
- Nature's Grace (TBC, Wrath, Cataclysm) now has a fixed texture
- Nature's Grace has been scaled to 70% (down from 100%)

New Glowing Buttons:
- Starfire, during Lunar Eclipse (Cataclysm)
- Wrath, during Solar Eclipse (Cataclysm)
- Starsurge, during Shooting Stars (Cataclysm)
### :hunter:  Hunter
New Spell Alert:
- Lock and Load (Season of Discovery)

Unlike Wrath, there are no glowing buttons for Lock and Load, which empowers all shots on Season of Discovery. Adding options for each of them would break the options panel, not to mention it would be a mess to setup for players. Until we find a more suitable solution, Hunters will have to rely on the spell alert to know when to unleash Lock and Load.
### :paladin:  Paladin
Updated Spell Alert:
- Infusion of Light texture and position have changed since Wrath

New Glowing Buttons:
- Holy Shock, as combat-only counter
- Flash of Light, during Infusion of Light (Cataclysm)
- Holy Light, during Infusion of Light (Cataclysm)
- Divine Light, during Infusion of Light (Cataclysm)
- Holy Radiance, during Infusion of Light (Cataclysm)
- Exorcism, during The Art of War (Cataclysm)
### :warrior:  Warrior
New Spell Alerts:
- Bloodsurge (Cataclysm)
- Sudden Death (Cataclysm)
- Sword and Board (Cataclysm)
- Sword and Board (Season of Discovery)

Updated Spell Alert:
- Bloodsurge texture has changed since Wrath

New Glowing Buttons:
- Slam, during Bloodsurge (Cataclysm)
- Colossus Smash, during Sudden Death (Cataclysm)
- Shield Slam, during Sword and Board (Cataclysm)
- Shield Slam, during Sword and Board (Season of Discovery)
- Overpower, during Taste for Blood (Season of Discovery)

As in Wrath, there is no dedicated Taste for Blood option in Season of Discovery. Taste for Blood shares its option with Overpower.

## Bug Fixes
### :dk:  Death Knight
Killing Machine (Cataclysm) no longer glows Icy Touch and Howling Blast.
### :druid:  Druid
When logging in or reloading UI while under the effect of Lunar or Solar Eclipse, the spell alert was shown then hidden immediately.
### :mage~1:  Mage
Death Knight's Hungering Cold (Wrath, Cataclysm) is now tagged as Frozen debuff.
### :warrior:  Warrior
Blood Surge (Season of Discovery) did not trigger correctly.

Bloodsurge (Wrath) and Sudden Death (Wrath) spell alerts did not preview when hovering the mouse over their respective option in the options panel.


As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest
