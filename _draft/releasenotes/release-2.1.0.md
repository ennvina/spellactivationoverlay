# SpellActivationOverlay 2.1

@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.1

This is another big release, improving the major overhaul of the effect system in 2.0. This is the last step for the perilous journey of reworking the addon. Thanks again for your continued support  :heart:
## General
### Options
A new option "responsive mode" is available in the options panel. In some cases, it detects procs slightly sooner. In most situations, it makes no difference. Hence, the option is disabled by default.
## Classes
### :dk:  Death Knight
Bone Shield is now combat-only, meaning it will glow only for a few seconds after leaving combat (Cataclysm).
### :druid:  Druid
Eclipses are now combat-only, meaning the effect will fade out after leaving combat for a few seconds (Season of Discovery, Wrath, Cataclysm).
### :paladin:  Paladin
Updated Spell Alerts:
- Updated texture of Infusion of Light to match the reference client of Cataclysm (Cataclysm)
- Updated texture and increased size of Charges of Holy Power (Cataclysm)
- Charges of Holy Power is no longer combat-only (Cataclysm)
- Daybreak is displayed only when Holy Shock is usable (Cataclysm)\*

\* Exceptionally, this does not match the reference client, on purpose. It felt weird to see Daybreak proc, try to cast Holy Shock in response to the proc, but the target is not getting healed, and then realize Holy Shock is on cooldown. Hence, the decision to display the effect only when Holy Shock is usable.

New Glowing Buttons:
- Judgement of Light, Judgement of Wisdom and Judgement of Justice, with talent Judgements of the Pure, when the buff is missing (Wrath)
- Judgement, with talent Judgements of the Pure, when the buff is missing (Cataclysm)
:point_down:



## Classes
### :priest:  Priest
New Glowing Buttons:
- Inner Fire, when the buff is missing (Wrath, Cataclysm)\*
- Shadowform, when the Shadow priest is not assuming the one and only shadowform
- Shadow Word: Death, when the target has less than 25% of its total health (Cataclysm)

\* Inner Fire existed before Wrath, but it has become all the more important when the spell power component was added in Wrath.
### :rogue:  Rogue
New Glowing Button:
- Backstab, with Murderous Intent talent, when the target has less than 35% of its total health (Cataclysm)
### :warlock:  Warlock
New Spell Alert:
- Fel Spark, from tier 11 set bonus (Cataclysm)

New Glowing Buttons:
- Fel Flame, during Fel Spark, from tier 11 set bonus (Cataclysm)
- Shadowburn, when the spell is usable (Cataclysm)\*

\* Shadowburn existed before Cataclysm, but it has become interesting to spam it on cooldown when the soul sard cost was removed in Cataclysm.
:point_down:



## Bug Fixes
Effects gained or lost during a loading screen are correctly updated.
### :druid:  Druid
Soul Preserver overlay is now slightly dimmer, as intended (Wrath).
### :mage~1:  Mage
Clearcasting overlay is now slightly dimmer, as intended.

Finger of Frost overlay is now slightly dimmer, as intended (Cataclysm).

Missile Barrage overlay is now blue-ish, as intended (Season of Discovery).
### :paladin:  Paladin
Soul Preserver overlay is now slightly dimmer, as intended (Wrath).
### :priest:  Priest
Mind Spike overlay is now purple-ish, as intended (Season of Discovery).

Soul Preserver overlay is now slightly dimmer, as intended (Wrath).
### :shaman:  Shaman
Soul Preserver overlay is now slightly dimmer, as intended (Wrath).
## Known Issues
### :druid:  Druid
Buttons that started glowing during Eclipse do not fade out after leaving combat (Cataclysm).


As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest
