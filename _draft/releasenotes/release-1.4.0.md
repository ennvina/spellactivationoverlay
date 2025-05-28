@here I am very pleased to announce the newest release of SpellActivationOverlay, version 1.4.0

This is another big release, this time focusing on stability for all classes, especially for Cataclysm. The goal is be at least on par with Wrath of the Lich King. Make sure to send feedback, thank you :slight_smile:

Shout-out to @amanthuul and @espionn for their contribution to the code. Thanks!  :person_bowing:
## General
A new system has been introduced to design effects more easily. Cataclysm is in desperate need of new effects, and such system helps a great deal.
### Spell Alerts
The sound is no longer played for minor spell alerts, such as Mage's Heating Up or Shaman's Maelstrom Weapon before the fifth stack.
### Options
Classes with no Spell Alerts or no Glowing Buttons, or both, now have a "None" text in their options panel.

## Classes
### :dk:  Death Knight
Removed Glowing Button:
- Rune Strike (Cataclysm)

The Rune Strike ability should still glow in Frost and Unholy Presence, but due to the game client.
### :druid:  Druid
New Spell Alert:
- Fury of Stormrage (Cataclysm)

Removed Spell Alert:
- Nature's Grace (Cataclysm)

New Glowing Button:
- Starfire, during Fury of Stormrage (Cataclysm)
### :hunter:  Hunter
New Spell Alert:
- Master Marksman (Cataclysm)

Removed Spell Alert:
- Improved Steady Shot (Cataclysm)

New Glowing Button:
- Aimed Shot!, during Master Marksman (Cataclysm)
:point_down:



## Classes
### :mage~1:  Mage
Removed sound effect for minor Spell Alerts:
- Clearcasting
- Frozen debuff
- Heating Up (Season of Discovery, Wrath, Cataclysm)
- Arcane Blast at 1-3 stacks (Season of Discovery)
### :paladin:  Paladin
Removed sound effect for minor Spell Alert:
- The Art of War with only 1 talent point (Wrath)
### :priest:  Priest
New Spell Alert:
- Serendipity (Cataclysm)

New Glowing Buttons:
- Greater Heal, during Serendipity (Cataclysm)
- Prayer of Healing, during Serendipity (Cataclysm)

Removed sound effect for minor Spell Alerts:
- Serendipity at 1-2 stacks (Season of Discovery, TBC, Wrath)
- Mind Spike at 1-2 stacks (Season of Discovery)
### :rogue:  Rogue
Removed Spell Alert:
- Riposte (Cataclysm)
:point_down:



## Classes
### :shaman:  Shaman
New Spell Alerts:
- Fulmination, with 6-9 Lightning Shield stacks (Cataclysm)
- Maelstrom Weapon (Cataclysm)
- Tidal Waves (Cataclysm)

Updated Spell Alert:
- Elemental Focus spell alert uses a more discreet texture (Cataclysm)

New Glowing Buttons:
- Lava Burst, with Lava Surge talent (Cataclysm)
- Earth Shock, with 6-9 Lightning Shield stacks (Cataclysm)
- Chain Heal, during Maelstrom Weapon (Cataclysm)
- Chain Lightning, during Maelstrom Weapon (Cataclysm)
- Greater Healing Wave, during Maelstrom Weapon (Cataclysm)
- Healing Rain, during Maelstrom Weapon (Cataclysm)
- Healing Surge, during Maelstrom Weapon (Cataclysm)
- Healing Wave, during Maelstrom Weapon (Cataclysm)
- Hex, during Maelstrom Weapon (Cataclysm)
- Lightning Bolt, during Maelstrom Weapon (Cataclysm)
- Healing Surge, during Tidal Waves (Cataclysm)
- Healing Wave, during Tidal Waves (Cataclysm)
- Greater Healing Wave, during Tidal Waves (Cataclysm)

Removed sound effect for minor Spell Alerts:
- Shaman's Elemental Focus
- Shaman's Maelstrom Weapon at 1-4 stacks (Season of Discovery, Wrath)
- Shaman's Rolling Thunder at 7-9 Lightning Shield stacks (Season of Discovery)
### :warlock:  Warlock
New Glowing Buttons:
- Drain Soul, when the enemy has low HP (Cataclysm)
- Chaos Bolt, during Backdraft (Cataclysm)
- Incinerate, during Backdraft (Cataclysm)
- Shadow Bolt, during Backdraft (Cataclysm)
- Soul Fire, during Empowered Imp (Cataclysm)
### :warrior:  Bladestorm
New Spell Alert:
- Bladestorm (Wrath, Cataclysm)
:point_down:



## Bug Fixes
Spell Alerts could sometimes fail to start pulsing when being previewed in the options panel.

Texture orientation for the Spell Alert displayed on Top during Toggle Test was incorrect (Cataclysm).
### :hunter:  Hunter
Arcane Shot no longer glows during Lock and Load (Cataclysm).
### :mage~1:  Mage
Pyroblast! (with an exclamation mark) is no longer counted for triggering Heating Up (Cataclysm). Pyroblast (with no exclamation mark) is still counted.

Texture orientation for Fringers of Frost, Frozen debuff and Brain Freeze were incorrect (Cataclysm).
### :warlock:  Warlock
Specializations in Drain Soul option were displaying numbers instead of names (Cataclysm).

Soul Fire no longer glows during Molten Core (Cataclysm).

## Known Issues
Some classes have so many options that they may end up outside the options panel.

Spell Alerts with distinct visuals for distinct stack counts may display a visual timer timer shorter than intended. The issue was already there, please do not blame this release, thank you :slight_smile:

Spell Alert texture for Bladestorm may have the wrong orientation if the player changes gender / body type at the barber shop, or if the player has a temporary race change with spell and items such as Orb of Deception.


As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest
