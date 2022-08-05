## SpellActivationOverlay Changelog

#### v0.4.2-beta (2022-08-xx)

- Alpha is reduced by 50% when out of combat

#### v0.4.1-beta (2022-08-05)

- New SAO: Paladin's Infusion of Light
- Textures should keep pulsing after gaining/losing stacks
- Mage's Heating Up does not pulse anymore
- Shamans's Maelstrom Weapon does not pulse at stacks 1-4

#### v0.4.0-beta (2022-07-31)

- Because all classes are supported, the addon now enters its Beta phase!
- New classes: Druid, Hunter, Rogue
- New SAO: Druid's Lunar Eclipse
- New SAO: Druid's Solar Eclipse
- New SAO: Druid's Omen of Clarity
- New SAO: Hunter's Improved Steady Shot
- New SAO: Hunter's Lock and Load
- New SAO: Mage's Impact
- New SAO: Shaman's Elemental Focus
- The Rogue class, although supported, currently doesn't have any SAO

#### v0.3.4-alpha (2022-07-31)

- New class: Warlock
- New SAO: Warlock's Backlash
- New SAO: Warlock's Empowered Imp
- New SAO: Warlock's Molten Core
- New SAO: Warlock's Nightfall, a.k.a. Shadow Trance

#### v0.3.3-alpha (2022-07-29)

- New classes: Shaman, Warrior
- New SAO: Priest's Serendipity
- New SAO: Shaman's Maelstrom Weapon
- New SAO: Warrior's Bloodsurge
- New SAO: Warrior's Sudden Death
- New SAO: Warrior's Sword and Board

#### v0.3.2-alpha (2022-07-27)

- New classes: Priest, Paladin
- New SAO: Priest's Surge of Light
- New SAO: Paladin's Art of War

#### v0.3.1-alpha (2022-07-26)

- New SAO: Mage's Missile Barrage
- New SAO: Mage's Brain Freeze

#### v0.3.0-alpha (2022-07-25)

- New SAO: Mage's Fingers of Frost
- Major changes to how stackable auras, such as Fingers of Frost, are handled
- Due to a game limitation, stackable auras rely a bit less on combat logs
- Talent checks could fail during login
- This addon no longer stores data to the game client local storage

#### v0.2.0-alpha (2022-07-24)

- Major changes to how custom code can be implemented, on a per-class basis
- Mage's Heating Up is now fully functional
- Mage's Heating Up now triggers only for mages who picked Hot Streak talent

#### v0.1.2-alpha (2022-07-24)

- New SAO: Mage's Heating Up, barely functional because Wrath has no such buff
- Factorized code in common.lua

#### v0.1.1-alpha (2022-07-24)

- New class: Mage
- New SAO: Mage's Hot Streak

#### v0.1.0-alpha (2020-07-24)

- SpellActivationOverlay is now public!
- Addon hosted on Curse https://www.curseforge.com/wow/addons/spellactivationoverlay
- Source code is available on GitHub https://github.com/ennvina/spellactivationoverlay
- This release mostly focuses on cleaning up some files before sharing them

#### v0.0.5-alpha (2022-07-24)

- Track combat event log instead of unit auras
- Support for stackable effects, although no stackable example is written yet

#### v0.0.4-alpha (2022-07-23)

- Utility functions are now centralized in common.lua
- First working Spell Activation Overlays (SAOs): DK's Rime and Killing Machine

#### v0.0.3-alpha (2022-07-23)

- Custom code for initializing new frame members
- Extra caution to ensure Blizzard original code changes as little as possible
- Utility functions to work around auras; defined in a separate source file

#### v0.0.2-alpha (2022-07-23)

- Re-use WeakAuras "Blizzard Alert" category for listing textures
- Map texture IDs to a local texture name in the addon folder

#### v0.0.1-alpha (2022-07-23)

- Re-use Blizzard code from Retail's FrameXML source code
- Re-use Rime and Killing Machine textures from Retail
- Ignore displaySpellActivationOverlays cvariable, unavailable in Classic
