# SpellActivationOverlay 2.5.4
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.5.4
## General
### Options Panel
The class name is displayed at one place in the options panel, instead of each time for each spell alert and each glowing button.
## Classes
### :mage~1:  Mage
Removed Glowing Buttons
- Ice Lance\*, during Fingers of Frost (Mists of Pandaria)
- Deep Freeze\*, during Fingers of Frost (Mists of Pandaria)

\* These buttons are already glowing by the game client. Please note, it only concerns Fingers of Frost. Ice Lance and Deep Freeze will continue to glow for the Freeze debuff, because the game client does not glow Ice Lance nor Deep Freeze in this case.
### :priest:  Priest
New Spell Alert
- Serendipity\* (Mists of Pandaria)

\* The Serendipity texture used is Cataclysm is now used for the Divine Insight effect, which matches the reference client of Mists of Pandaria. Another texture has been selected for the Serendipity effect in Mists of Pandaria.

New Glowing Button
- Holy Word: Chastise\*\* (Mists of Pandaria)

\*\* This button is disabled by default. Its intended use is for damage Priests who want to cast HW:Chastise on cooldown and don't know when the cooldown is reset thanks to Chakra: Chastise.
### :warlock:  Warlock
New Spell Alerts
- Eye of Kilrogg
- Nightfall\* (Mists of Pandaria)
- Soulburn (Mists of Pandaria)
- Molten Core\*\* (Mists of Pandaria)
- Demonic Rebirth (Mists of Pandaria)
- Backlash\*\* (Mists of Pandaria)

\* Nightfall no longer grants a free instant Shadow Bolt. Therefore, there is no Glowing Button for Nightfall in Mists of Pandaria.

\*\* Switches to the green version of Molten Core if the Warlock has switched to Fel-infused spells.

New Glowing Buttons
- Drain Soul, when the target has 20% health of less (Mists of Pandaria)
- Incinerate\*\*\*, during Backdraft (Mists of Pandaria)
- Chaos Bolt\*\*\*, during Backdraft (Mists of Pandaria)

\*\*\* As in Cataclysm, the option is disabled by default to remove clutter. Because the effect is guaranteed after Conflagrate is cast, there is no real surprise that makes it worth telling players 'hey, you just got lucky and have a proc', hence the incentive of glowing this button is much more limited than e.g. glowing Incinerate during Backlash.
### :warrior:  Warrior
The Warrior class is now fully supported for Mists of Pandaria!

New Spell Alerts
- Victory Rush (Mists of Pandaria)
- Taste for Blood (Mists of Pandaria)
- Sudden Death (Mists of Pandaria)
- Bloodsurge (Mists of Pandaria)
- Sword and Board (Mists of Pandaria)
- Ultimatum (Mists of Pandaria)

New Glowing Buttons
- Overpower\*, during Taste for Blood (Mists of Pandaria)
- Victory Rush\*, during Victorious (Mists of Pandaria)
- Impending Victory, during Victorious (Mists of Pandaria)

\* Overpower and Victory Rush were already supported, but as a _counter_. Now they are based on buffs instead. They also have spell alerts now. If these overlays are popular enough, they might end up in other flavors as well.

Removed Glowing Buttons\*\*
- Execute (Mists of Pandaria)
- Revenge (Mists of Pandaria)

\*\* These buttons already glow natively in Mists of Pandaria
## Bug Fixes
### :mage~1:  Mage
The Freeze effect would always glow Ice Lance and Deep Freeze (Mists of Pandaria). Options for their respective buttons have been added.
### :shaman:  Shaman
Animations of Fulmination (Cataclysm, Mists of Pandaria) and Rolling Thunder (Season of Discovery) are now on par with other animations.

Shamans should no longer get invited to report unsupported effect Maelstrom (Mists of Pandaria).
### :warrior:  Warrior
Warriors should no longer get invited to report the following unsupported effects (Mists of Pandaria):
- Sudden Death
- Bloodsurge
- Sword and Board
- Ultimatum
## Known Limitations
## Miscellaneous
Overlays are never displayed after 60 seconds of leaving combat, up from 30 seconds.

_Developer's Note: The 30-second limit was introduced a while ago as a security against infinite overlays, especially Mage's Heating Up which had no duration in Wrath of the Lich King. Since then, the new combat-only feature has been introduced to mitigate these situations, and should be favored over the 30-second limit. A maximum duration is still kept 'just in case', but it is set to a longer time to allow out-of-combat effects that last for more than 30 seconds, such as Warlock's Eye of Kilrogg._
## Contributors
Shout-out to our amazing contributors
- Amanthuul for helping once again with Shaman, this class wouldn't be the same without you :person_bowing:
- TeamRemix for sending lots of feedback and test new effects for Priest
- Jumpsuitpally for sending feedback about Mage
- Optimizer2347 for reporting an unsupported effect
Thanks!

As always, the latest release is available on [CurseForge](https://www.curseforge.com/wow/addons/spellactivationoverlay) / [GitHub](https://github.com/ennvina/spellactivationoverlay/releases/latest) / [Discord](https://discord.com/channels/1013194771969355858/1379111832207228938)