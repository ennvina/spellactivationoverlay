## SpellActivationOverlay Changelog

#### v0.9.2 (2022-06-21)

- Bump in TOC file for Trial of the Grand Crusader patch
- The options window is compatible with the new settings UI

#### v0.9.1 (2022-05-28)

- Mage's Clearcasting is now enabled by default on Classic Era
- Mage's Clearcasting has been scaled to 100% (down from 150%) on Classic Era
- New GAB: Warlock's Drain Soul when the enemy has low HP
- The Drain Soul option is available for Wrath Classic only
- Warrior's Overpower has an option to be detected in any stance
- Warrior's Revenge has an option to be detected in any stance
- Warrior's Execute has an option to be detected in any stance

Please enter /sao to enable or disable these options

#### v0.9.0 (2022-05-01)

- Support for Classic Era, although many WotLK spells and talents are missing
- Mage's Heating Up effect is now hidden when the talent is lost e.g., respec
- Fixed an issue where paladin and warrior buttons would sometimes not glow
- The addon should now use a bit less CPU than before

#### v0.8.4 (2022-04-28)

- New SAO: Druid's Wrath of Elune (4p set bonus of PvP season 5-6-7-8)
- New SAO: Druid's Elune's Wrath (4p set bonus of tier 8)
- New SAO: Mage's Heating Up and Hot Streak at the same time
- New GAB: Druid's Starfire button glows during Wrath of Elune
- New GAB: Druid's Starfire button glows during Elune's Wrath

Enter /sao to enable or disable these options

#### v0.8.3 (2022-01-29)

- Glowing buttons work again with ProjectAzilroka, after Ulduar patch
- Mage's Heating Up works again with ProjectAzilroka, after Ulduar patch
- Other features may also work back to normal for ProjectAzilroka users
- These fixes also apply to addons embedding an outdated LibButtonGlow
- If there is no fallback solution, glowing buttons are temporarily disabled

#### v0.8.2 (2022-01-18)

- Bump in TOC file for Ulduar patch

#### v0.8.1 (2022-11-13)

- The default glowing button library is now LibButtonGlow for ElvUI 13

#### v0.8.0 (2022-11-08)

- SAOs and GABs can be previewed by moving the cursor over their options
- SAOs may have variants when e.g. there is no obvious texture to use
- New SAO: Druid's Nature's Grace, optional
- New SAO: Mage's Arcane Concentration (a.k.a. Clearcasting), optional
- New SAO: Shaman's Tidal Waves, optional
- New GAB: Shaman's Lesser Healing Wave button may glow during Tidal Waves
- New GAB: Shaman's Healing Wave button may glow during Tidal Waves

#### v0.7.0 (2022-10-09)

- Spell Alerts may now be enabled or disabled individually
- Glowing buttons may now be enabled or disabled individually
- Options panel is opened by entering /sao or /spellactivationoverlay

#### v0.6.5 (2022-10-05)

- Entering a vehicle should no longer cause a Lua error
- Spending 1 point out of 2 in Art of War now has a SAO and GABs

#### v0.6.4 (2022-09-29)

- Spell Alerts fade out after being out of combat for 30 seconds
- Spell Alerts triggering out-of-combat are not dimmed for 5 seconds
- SAOs and GABs should disappear if their triggers fade during a loading screen
- Lua errors of 'ipairs' should no longer occur after a loading screen
- Pulse animations should no longer start earlier thn expected

#### v0.6.3 (2022-09-20)

- New SAO: Warlock's Decimation
- New GAB: Warlock's Soul Fire button glows during Decimation
- Changed SAO: Warlock's Molten Core SAO no longer displays the 3rd charge
- Rogue's Riposte SAO should no longer trigger without the talent

#### v0.6.2 (2022-09-13)

Shout-out to MartGon once again for his contribution to the code. Thanks!

- Glowing buttons no longer "un-glow" during the Global Cooldown (GCD)
- Glowing buttons no longer "un-glow" due to the lack of rage, energy, or RP
- New SAO: Druid's Predatory Strikes, based on Predatory Swiftness from Retail
- New SAO: Mage's Firestarter, which uses texture of Impact
- New GAB: Mage's Flamestrike button glows during Firestarter
- Changed SAO: Mage's Impact uses texture of Lock and Load instead of Impact

#### v0.6.1 (2022-09-06)

Shout-out to MartGon and xHashii for their contribution to the code. Thanks!

- Buttons should glow correctly when using Bartender, ElvUI or Dominos
- New GAB: Hunter's Kill Shot button glows when the target has low HP
- New GAB: Paladin's Hammer of Wrath button glows when the target has low HP
- New GAB: Warrior's Execute button glows when the target has low HP
- New GAB: Warrior's Victory Rush button glows after killing an enemy
- Riposte should display its SAO as intended
- Reload UI should no longer cause a Lua error because of options
- Glowing Buttons checkbox should now apply the option correctly

#### v0.6.0 (2022-09-04)

- After extensive testing, SpellActivationOverlay now leaves its Beta phase!
- Options Panel, available from Interface > AddOns > SpellActivationOverlay
- Options for Spell Alerts: opacity, scale factor, offset
- Options for Glowing Buttons: on/off
- A "Toggle Test" button displays fake Spell Alerts for testing interactively

#### v0.5.0-beta (2022-08-31)

SpellActivationOverlay now has a Discord server!
Make sure to check it out at https://discord.gg/xJmGfGcd4M

Support for Glowing Action Buttons (GABs), making some actions glow, namely:
- Death Knight's Rune Strike button glows after parrying or dodging an attack
- Death Knight's Howling Blast button glows during Rime
- DK's Icy Touch/Frost Strike/Howling Blast buttons glow during Killing Machine
- Druid's Wrath button glows during Solar Eclipse
- Druid's Starfire button glows during Lunar Eclipse
- Hunter's Counterattack button glows after parrying an attack, unless on CD
- Hunter's Aimed/Arcane/Chimera Shot buttons glow during Improved Steady Shot
- Hunter's Arcane/Explosive Shot buttons glow during Lock and Load
- Mage's Arcane Missiles button glows during Missile Barrage
- Mage's Pyroblast button glows during Hot Streak
- Mage's Fire Blast button glows during Impact
- Mage's Fireball and Frostfire Bolt buttons glow during Brain Freeze
- Paladin's Flash of Light and Holy Light buttons glow during Infusion of Light
- Paladin's Flash of Light and Exorcism buttons glow during The Art of War
- Priest's Smite and Flash Heal buttons glow during Surge of Light
- Priest's Greater Heal and Prayer of Healing glow at 3 stacks of Serendipity
- Rogue's Riposte button glows after parrying an attack, unless on cooldown
- Warlock's Shadow Bolt button glows during Nightfall, a.k.a. Shadow Trance
- Warlock's Shadow Bolt and Incinerate buttons glow during Backlash
- Warlock's Incinerate and Soul Fire buttons glow during Molten Core
- Warrior's Overpower button glows after the enemy dodges, if in Battle Stance
- Warrior's Revenge button glows after parry/dodge/block in Defensive Stance
- Warrior's Execute button glows during Sudden Death
- Warrior's Slam button glows during Bloodsurge
- Warrior's Shield Slam button glows during Sword and Board

- New SAO: Rogue's Riposte
- SAOs should now always show up on ReloadUI

#### v0.4.2-beta (2022-08-05)

- Mage's Heating Up is no longer lost on death
- Alpha is reduced by 50% when out of combat
- SAOs are shown uplon login if player already has the corresponding buffs
- Currently, this includes all SAOs but Heating Up, which is not a buff

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
