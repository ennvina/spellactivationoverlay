@here I am hyped to announce the beta release of SpellActivationOverlay v1.1.0!

Due to high demand, there is an 'official beta' release for those of you eager to play Season of Discovery as soon as possible. Enjoy :)

## General

This release focuses on supporting runes introduced in Season of Discovery.

Supported runes are listed here https://github.com/ennvina/spellactivationoverlay/issues?q=is%3Aissue+label%3Asod

Many runes haven't been tested thoroughly, please keep in mind this is a **beta** version of the addon. Make sure to report issues and suggestions over Discord, GitHub, or CurseForge. Thank you for your patience and understanding :)

## Classes

### :druid:  Druid

New Spell Alert:
- Fury of Stormrage

New Glowing Button:
- Healing Touch, during Fury of Stormrage

### :hunter:  Hunter

New Spell Alerts:
- Flanking Strike
- Cobra Strikes

New Glowing Button:
- Flanking Strike, when the action is usable

### :mage~1:  Mage

New Spell Alert:
- Fingers of Frost
- Arcane Blast, different effect with different stacks

New Glowing Buttons:
- Ice Lance, during Fingers of Frost
- Ice Lance, when the enemy target is Frozen
- Arcane Missiles\*, during Arcane Blast
- Arcane Explosion\*, during Arcane Blast

\* Arcane Blast buff indicates that it can reset from healing spells, although no healing spell seems to reset it yet. Should you discover a rune that resets it, please share it with us, thank you :mage:

Updated Spell Alert:
- Clearcasting size is scaled back to 150%, to avoid overlap now that Classic Era has other spell alerts at the left/right location

### :priest:  Priest

New Spell Alert:
- Serendipity

New Glowing Buttons:
- Lesser Heal, during Serendipity
- Heal, during Serendipity
- Greater Heal, during Serendipity
- Prayer of Healing, during Serendipity

### :shaman:  Shaman

New Spell Alert:
- Molten Blast

New Glowing Button:
- Molten Blast, when the action is usable

### :warrior:  Warrior

New Spell Alert:
- Raging Blow

New Glowing Buttons:
- Raging Blow, when the action is usable
- Victory Rush, when the action is usable

## Bug Fixes

### Glowing Buttons

In rare circumstances, glowing buttons would never glow. Reloading the UI would always fix the issue, until next log out.






@here I am pleased to announce the newest release of SpellActivationOverlay, version 1.1.1

This release follows v1.1.0 which was only released as beta. Please refer to 1.1.0 release notes in case you haven't read them.

## General

This release focuses again on Season of Discovery.

Make sure to head over the Discord server or the GitHub page to suggest new runes or send feedback about supported ones. Thank you! :pray:

## Classes

### :hunter:  Hunter

The Spell Alert of Flanking Strike is no longer always displayed upon login.

_Developer's Note: This is most likely an issue from the game client, a fix has been deployed on the addon side until the game is fixed._

### :mage~1:  Mage

New Spell Alert:
- Arcane Blast, different effect with different stacks

New Glowing Buttons:
- Arcane Missiles\*, during Arcane Blast
- Arcane Explosion\*, during Arcane Blast

\* Arcane Blast buff indicates that it can reset from healing spells, although no healing spell seems to reset it yet. Should you discover a rune that resets it, please share it with us, thank you :mage:

Updated Spell Alert:
- Clearcasting size is scaled back to 150%, similar to Wrath Classic, to avoid overlap with spell alerts that were recently added

### :shaman:  Shaman

The Spell Alert of Molten Blast is no longer always displayed upon login.

_Developer's Note: This is most likely an issue from the game client, a fix has been deployed on the addon side until the game is fixed._

## Known Limitations

### Options Panel

On Classic Era, options for Spell Alerts and Glowing Buttons of Season of Discovery are displayed on all realms, including non-seasonal realms.

As always, the latest release is available:
- on CurseForge 👉  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub 👉  https://github.com/ennvina/spellactivationoverlay/releases/latest






@here I am pleased to announce the newest release of SpellActivationOverlay, version 1.1.2

## General

This release focuses again on Season of Discovery.

Make sure to head over the Discord server or the GitHub page to suggest new runes or send feedback about supported ones. Thank you! :pray:

## Classes

### :hunter:  Hunter

The Spell Alert and Glowing Button of Flanking Strike should be triggered correctly.

### :mage~1:  Mage

Arcane Blast Spell Alert and its associated Glowing Buttons — Arcane Missiles and Arcane Explosion — should be triggered correctly.

### :rogue:  Rogue

Rogues finally got some love!

Riposte effects may now be displayed when the ability is on cooldown. This is especially useful for rogue tanks who parry very often: you can now know when the ability is usable soon™

The option is disabled by default and may be enabled from the options window. Beware! There are two options: one for the Riposte Spell Alert, and one for the Riposte Glowing Button. Make sure to enable both if you need both.

### :shaman:  Shaman

The Spell Alert and Glowing Button of Molten Blast should be triggered correctly.

### :warrior:  Warrior

The Spell Alert and Glowing Button of Raging Blow should be triggered correctly.

The Glowing Button of Victory Rush should be triggered correctly.

## Bug fixes

### Options Panel

On Classic Era, options for Spell Alerts and Glowing Buttons of Season of Discovery are no longer displayed on non-seasonal realms.

As always, the latest release is available:
- on CurseForge 👉  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub 👉  https://github.com/ennvina/spellactivationoverlay/releases/latest





@here I am not so pleased to announce the newest release of SpellActivationOverlay, version 1.1.3

This release fixes an issue introduced in version 1.1.2, related to stackable auras. Sowwy  :person_bowing:

## Classes

### :hunter:  Hunter

Cobra Strikes (Season of Discovery) and Lock and Load (Wrath Classic) Spell Alerts would sometimes not be seen, and their Glowing Buttons would not glow in the process.

### :mage~1:  Mage

Arcane Blast (Season of Discovery) and Fingers of Frost (Wrath Classic, Season of Discovery) Spell Alerts would sometimes not be seen, and their Glowing Buttons would not glow in the process.

### :priest:  Priest

The Serendipity Spell Alert would sometimes not be seen, and its Glowing Buttons would not glow in the process.

### :shaman:  Shaman

The Maelstrom Weapon (Wrath Classic) Spell Alert would sometimes not be seen, and its Glowing Buttons would not glow in the process.

### :warlock:  Warlock

The Molten Core (Wrath Classic) Spell Alert would sometimes not be seen.

### :warrior:  Warrior

The Bloodsurge (Wrath Classic) and Sudden Death (Wrath Classic) Spell Alerts would sometimes not be seen, and their Glowing Buttons would not glow in the process, usually at 2 stacks, due to tier 10 set bonus.

As always, the latest release is available:
- on CurseForge 👉  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub 👉  https://github.com/ennvina/spellactivationoverlay/releases/latest