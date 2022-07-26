## SpellActivationOverlay Changelog

#### v0.3.2-alpha (2022-07-27)

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
- Utility functions to work around auras; defined in a separated source file

#### v0.0.2-alpha (2022-07-23)

- Re-use WeakAuras "Blizzard Alert" category for listing textures
- Map texture IDs to a local texture name in the addon folder

#### v0.0.1-alpha (2022-07-23)

- Re-use Blizzard code from Retail's FrameXML source code
- Re-use Rime and Killing Machine textures from Retail
- Ignore displaySpellActivationOverlays cvariable, unavailable in Classic
