# SpellActivationOverlay 2.1.1

@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.1.1

## Classes
### :dk:  Death Knight
New Spell Alert:
- Dark Transformation, when the ghoul can be transformed (Cataclysm)

New Glowing Button:
- Dark Transformation, when the ghoul can be transformed (Cataclysm)

Please note, if the ghoul has 5 stacks of Shadow Infusion and the death knight does not cast Dark Transformation immediately and decides to mount up and start flying, when the death knight lands and dismounts, the ghoul still has 5 stacks of Shadow Infusion but Dark Transformation is not usable. This is *not* an issue caused by the addon. This is an issue from the game itself. However, casting Death Coil quickly (i.e., before Shadow Infusion expires) will refresh the fifth stack of Shadow Infusion and will make Dark Transformation usable, without needing to build up five stacks again.

## Bug Fixes
### :mage~1:  Mage
Arcane Missiles timer should now refresh correctly (Cataclysm).

This issue is most likely a bug from the game client. Until Blizzard fixes it, the addon exceptionally implements a local fix.
### :paladin:  Paladin
Effects based on Holy Power are no longer displayed before level 9, because there are no Holy Power spenders yet (Cataclysm).

## Known Limitations
### :dk:  Death Knight
If Shadow Infusion expires from the ghoul during a loading screen, Dark Transformation may be displayed for a couple of seconds after loading screen ends, even though the ability is not usable (Cataclysm).

As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest
