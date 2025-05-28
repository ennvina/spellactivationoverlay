# SpellActivationOverlay 2.2.0
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.2.0

This release is focused on compatibility and fixing bugs.
## General
### :warlock:  Necrosis
Recently, Necrosis has started to include SpellActivationOverlay. There were issues when both SpellActivationOverlay and Necrosis were installed
- Players who have not installed Necrosis are unaffected
- Players who log in with a class other than Warlock are unaffected

**If you are using SpellActivationOverlay and Necrosis at the same time on your Warlock, please update both addons to fix these issues.**
### Options Panel
A special mode "Disabled" has been introduced, blocking the options panel. On top of blocking the options panel, effects can no longer trigger. Players can opt in to disable SpellActivationOverlay when Necrosis is loaded. This option is available only for Warlocks who have installed both SpellActivationOverlay and Necrosis.
## Bug Fixes
### Glowing Buttons
Lua errors caused by action buttons are less likely to happen
- Errors caused by `OverrideActionBarButton` should no longer happen
- Errors caused by other action buttons should happen less often
- Either way, players with an action bar management addon (such as Bartender, ElvUI, Dominos, etc.) should no longer have errors when buttons are glowing

As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest