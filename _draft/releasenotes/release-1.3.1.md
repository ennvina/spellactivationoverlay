@here I am pleased to announce the newest release of SpellActivationOverlay, version 1.3.1

This release adds a sound option for spell alerts, supports new runes in Season of Discovery, and scratches the surface of Cataclysm.

Shout-out to @amanthuul and @steijner for their contribution to the code. Thanks!  :person_bowing:
## General
### Cataclysm
This is the first release that tackles Cataclysm. The addon is still in alpha for this new _flavor_. Feedback is appreciated. Thank you :з
### Spell Alerts
Original Cataclysm played a sound when an alert was displayed. This addon plays the same sound. An option has been added, enabled for Cataclysm, disabled otherwise. Change it from the options panel, by entering /sao

## Classes
### :mage~1:  Mage
New Glowing Buttons:
- Deep Freeze (Season of Discovery), during Fingers of Frost or when the target is Frozen

For mage effects supported in Cataclysm, please read next post.
### :paladin:  Paladin
New Glowing Button:
- Divine Storm, as combat-only counter
### :priest:  Priest
New Spell Alert:
- Mind Spike (Season of Discovery)

New Glowing Button:
- Mind Blast, during Mind Spike (Season of Discovery) at 3 stacks
### :shaman:  Shaman
New Spell Alerts:
- Rolling Thunder (Season of Discovery) at 7-9 Lightning Shield stacks
- Tidal Waves (Season of Discovery)

New Glowing Buttons:
- Earth Shock (Season of Discovery) at 7-9 Lightning Shield stacks
- Healing Wave and Lesser Healing Wave, during Tidal Waves (Season of Discovery)

## Bug Fixes
### Counters
Counter-based Spell Alerts could incorrectly stay visible if the counter ability was lost e.g., after resetting talents. Glowing buttons were _not_ affected and already stopped glowing, as intended.

As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest




@here I am pleased to announce the newest release of SpellActivationOverlay, version 1.3.1

This release follows up the recently added combat-only system, supports new runes in Season of Discovery, adds a sound option for spell alerts, and scratches the surface of Cataclysm.

Shout-out to @Amanthuul and @steijner for their contribution to the code. Thanks!  :person_bowing:

## General
### Cataclysm
This is the first release that tackles Cataclysm. There is much to be done, so the addon is still in alpha for this new _flavor_. As usual, feedback is appreciated. Thank you :з
### Spell Alerts
The SpellActivationOverlay functionality from Cataclysm always played a sound when an alert was displayed. This addon plays the exact same sound.

An new option has been added to control it, enabled by default for Cataclysm, and disabled otherwise. It can be changed from the options panel, available by entering /sao

## Classes
### :mage~1:  Mage
New Glowing Buttons:
- Deep Freeze (Season of Discovery), during Fingers of Frost
- Deep Freeze (Season of Discovery), when the target is Frozen

All mage effects below are related to Cataclysm.

New Spell Alerts:
- Arcane Missiles!
- Arcane Potency, as combat-only effect
   - the effect is disabled by default because it does not really change the rotation, and to reduce visual clutter
   - there is a known issue where the 1-stack visual effect does not fade out quickly after leaving combat
   - (it still fades out after 30 seconds like every spell alert)

Updated Spell Alerts:
- Heating Up and Hot Streak
   - tests during Beta indicate that it is no longer possible to bank a Heating Up stack when Hot Streak is active
   - due to how talents were reworked, the Heating Up effect is displayed only if the mage has Improved Hot Streak
- Impact
   - while the visual effect is similar to Wrath Classic, please note Impact has been reworked

Unchanged Spell Alerts:
- Brain Freeze
- Clearcasting
- Fingers of Frost
- Frozen debuff

Removed Spell Alerts:
- ~~Missile Barrage~~
- ~~Heating Up + Hot Streak at the same time~~
- ~~Firestarter~~

New Glowing Buttons:
- Arcane Missiles, during Arcane Missiles!
- Pyroblast!, during Hot Streak
   - when Hot Streak procs, there is a new spell called Pyroblast! (with an exclamation mark)

Unchanged Glowing Buttons:
- Fireball and Frostfire bolt, during Brain Freeze
- Deep Freeze, during Fingers of Frost
- Deep Freeze, while the target is Frozen
- Fire Blast, during Impact

Removed Glowing Button:
- ~~Flamestrike, during Firestarter~~
### :paladin:  Paladin
New Glowing Button:
- Divine Storm, as combat-only counter
### :priest:  Priest
New Spell Alert:
- Mind Spike (Season of Discovery)

New Glowing Button:
- Mind Blast, during Mind Spike (Season of Discovery) at 3 stacks
### :shaman:  Shaman
New Spell Alerts:
- Rolling Thunder (Season of Discovery), with 7-9 Lightning Shield stacks
- Tidal Waves (Season of Discovery)

New Glowing Buttons:
- Earth Shock (Season of Discovery), with 7-9 Lightning Shield stacks
- Healing Wave and Lesser Healing Wave, during Tidal Waves (Season of Discovery)

## Bug Fixes
### Counters
Counter-based Spell Alerts could incorrectly stay visible if the counter ability was lost e.g., after resetting talents. Glowing buttons were _not_ affected and already stopped glowing, as intended.

As always, the latest release is available:
- on CurseForge 👉  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub 👉  https://github.com/ennvina/spellactivationoverlay/releases/latest






@here I am pleased to announce the newest release of SpellActivationOverlay, version 1.3.0

This release introduces a new system: combat-only abilities. The release also engages in new Season of Discovery content.
## General
### Seasonal
This release bumps TOC file for the new Season of Discovery content.
### Counters
Abilities in the _counters_ category can be classified as 'combat-only'. Their alerts and glowing buttons will fade out after a few seconds after leaving combat.

This setting is targeted at abilities which basically have an infinite duration. They were especially annoying when commuting or going AFK.

Please note, if an ability becomes available when out of combat, the alert or glowing button will activate for a few seconds. This helps players who want to engage combat when their favorite spell or ability is ready.
## Classes
### :hunter:  Hunter
Flanking Strike (Season of Discovery) is now classified as combat-only.
### :mage~1:  Mage
Heating Up is now classified as combat-only.
### :paladin:  Paladin
New Glowing Button:
- Exorcism, as combat-only counter
### :priest:  Priest
New Spell Alert:
- Surge of Light (Season of Discovery)

New Glowing Buttons:
- Flash Heal, during Surge of Light (Season of Discovery)
- Smite, during Surge of Light (Season of Discovery)
### :shaman:  Shaman
Molten Blast (Season of Discovery) is now classified as combat-only.
## Bug Fixes
### Counters
Counters were incorrectly flagged as unavailable during the Global Cooldown (Classic Era only).
### :druid:  Druid
Visual timers of Lunar Eclipse and Solar Eclipse (Season of Discovery) should now refresh their duration correctly when gaining a stack.

As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest