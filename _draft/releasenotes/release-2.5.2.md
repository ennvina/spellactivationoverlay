# SpellActivationOverlay 2.5.2
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.5.2
## General
### Options
The 'Toggle Test' feature now previews spell alerts on top of the options panel.

Moving the mouse cursor over each spell alert in the options panel now previews them on top of the options panel.
## Classes
### :druid:  Druid
New Spell Alerts
- Dream of Cenarius, in Guardian specialization (Mists of Pandaria)
- Dream of Cenarius, in Feral specialization (Mists of Pandaria)

Updated Spell Alert
- Omen of Clarity in Feral specialization has been slightly scaled down to avoid conflict with Dream of Cenarius (Mists of Pandaria)

The scale factor of Omen of Clarity in Restoration specialization is left unchanged.
### :hunter:  Hunter
The Hunter class is now fully supported for Mists of Pandaria!

New Spell Alerts
- Master Marksman (Mists of Pandaria)
- Lock and Load (Mists of Pandaria)
- Thrill of the Hunt (Mists of Pandaria)

Updated Spell Alert
- Lock and Load is slightly dimmer at 1 stack, to indicate that there the next Shot will consume the last stack (Wrath, Cataclysm)
## Bug Fixes
### :hunter:  Hunter
Lock and Load no longer plays a sound when dropping from 2 stacks to 1 stack, because there is no new 'proc' (Wrath, Cataclysm).

_Developer's Note: Sounds should indicate something new and hardly controllable by the player has happened, to tell them "Now would be a good time to cast this ability that you maybe wouldn't have cast otherwise". When the player consumes a charge on purpose, there is no point in triggering the sound. At best, it's a distraction (pun intended). At worst, it is misleading players that stacks were refreshed, which they were not._
## Known Limitations
## Miscellaneous
The addon is now capable of overlapping spell alerts with a predictable order.
## Contributors
Shout-out to our amazing contributors
- Bison, for sending feedback about Feral druids
Thanks!

As always, the latest release is available on [CurseForge](https://www.curseforge.com/wow/addons/spellactivationoverlay) / [GitHub](https://github.com/ennvina/spellactivationoverlay/releases/latest) / [Discord](https://discord.com/channels/1013194771969355858/1379111832207228938)