# SpellActivationOverlay 2.3.0
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.3.0
## General
### Seasonal
This release bumps TOC file for Season of Discovery patch.
## Classes
### :mage~1:  Mage
Impact effect is now hidden when Fire Blast misses (Wrath, Cataclysm).

When Fire Blast misses, the spell goes on cooldown but the Impact buff is still active on the player. the Impact effect was still displayed simply because the buff was active. This invited the player to cast Fire Blast, which cannot be cast (due to cooldown), which caused confusion.
### :shaman:  Shaman
Maelstrom Weapon no longer empowers Chain Heal and Healing Wave since phase 4 (Season of Discovery).
## Bug Fixes
### :shaman:  Shaman
Molten Blast options should not longer be duplicated (Season of Discovery).
### Glowing Buttons
Lua errors caused by action buttons should no longer happen. If you still encounter issues on vehicles or mind controls, such as Nefarian or Magmaw, please report them.

As always, the latest release is available:
- on CurseForge :point_right:  https://www.curseforge.com/wow/addons/spellactivationoverlay
- on GitHub :point_right:  https://github.com/ennvina/spellactivationoverlay/releases/latest