# SpellActivationOverlay 2.7.4
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.7.4
## Classes
### :hunter:  Hunter
New Spell Alert
- Kill Command (The Burning Crusade)

New Glowing Button
- Kill Command (The Burning Crusade)
## Bug Fixes
### Options Panel
Opening the options panel is delayed after leaving combat (Mists of Pandaria).

_Developer's Note: This delay is annoying but it became mandatory with Siege of Orgrimmar patch for Mists of Pandaria Classic. Not delaying would cause an error when opening the options panel while in combat. Based on how Blizzard updates their game client over time, this is probably just the beginning. Expect other flavors to be affected by the same issue in the long run._
### :paladin:  Paladin
Exorcism now triggers if the target is Demon or Undead (Classic Era, The Burning Crusade).
Previously, Exorcism triggered for all targets, even if the target was neither Demon nor Undead.
### Glowing Buttons
A workaround has been implemented to fix an in-game glowing buttons issue (Mists of Pandaria).

The issue may affect players who match both following conditions
- playing the Siege of Orgrimmar patch for Mists of Pandaria
- binding spells and abilities inside macros

Although the issue comes for Blizzard's game client, the addon can help.
Once Blizzard fixes their stuff, these options shall be removed.

The following glowing buttons have been added temporarily
- :dk:  Death Knight
  - Howling Blast, during Rime
  - Icy Touch, during Rime
  - Frost Strike, during Killing Machine
  - Obliterate, during Killing Machine
  - Blood Boil, during Crimson Scourge
  - Dark Transformation
  - Death Coil, during Sudden Doom
  - Rune Tap, during Will of the Necropolis
- :druid:  Druid
  - Starsurge, during Shooting Stars
  - Moonfire, during Lunar Eclipse
  - Starfire, during Lunar Eclipse
  - Wrath, during Solar Eclipse
  - Maul, during Tooth and Claw
  - Healing Touch, during Dream of Cenarius (Bear)
  - Rebirth, during Dream of Cenarius (Bear)
- :hunter:  Hunter
  - Focus Fire, while at 5 stacks
  - Aimed Shot, while Master Marksman is at 5 stacks
  - Explosive Shot, during Lock and Load
  - Arcane Shot, during Thrill of the Hunt
  - Multi Shot, during Thrill of the Hunt
- :mage~1:  Mage
  - Ice Lance, during Fingers of Frost
  - Deep Freeze, during Fingers of Frost
  - Frostfire Bolt, during Brain Freeze
- :paladin:  Paladin
  - Hammer of Wrath
  - Holy Light, during Infusion of Light
  - Divine Light, during Infusion of Light
  - Holy Radiance, during Infusion of Light
  - Holy Shock, during Daybreak
  - Avenger's Shield, during Grand Crusader
  - Exorcism, during The Art of War
- :priest:  Priest
  - Mind Spike, during Surge of Darkness
  - Mind Blast, while Glyph of Mind Spike is at 2 stacks
- :shaman:  Shaman
  - Lava Burst, during Lava Surge
- :warlock:  Warlock
  - Soul Fire, during Molten Core
  - Incinerate, during Backlash
- :warrior:  Warrior
  - Overpower
  - Execute
  - Revenge
  - Raging Blow, while Enraged
  - Wild Strike, during Bloodsurge
  - Shield Slam, during Sword and Board
  - Heroic Strike, during Ultimatum
  - Cleave, during Ultimatum
## Known Limitations
It is possible that the above fixes do not work exactly as the game client. These fixes already required a ton of work, doing better would be even worse. Again, this is a band-aid to help Blizzard, please don't shoot the medic, thank you :innocent:
## Contributors
Shout-out to our amazing contributors
- Sofpokito for reporting Warrior issues and testing fixes
- laynerz for reporting Mage issues with extensive screenshots
- 떡반죽 for reporting Death Knight, Warrior, Paladin, Monk and Druid issues
- Moosi_13 for reporting Priest, Warrior and Paladin issues
- YoungChreezy for reporting Hunter issues

Thanks!

As always, the latest release is available on [CurseForge](https://www.curseforge.com/wow/addons/spellactivationoverlay) / [GitHub](https://github.com/ennvina/spellactivationoverlay/releases/latest) / [Discord](https://discord.com/channels/1013194771969355858/1379111832207228938)