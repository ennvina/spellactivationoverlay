# SpellActivationOverlay 2.5.1
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.5.1
## General
## Classes
### :druid:  Druid
The Druid class is now fully supported for Mists of Pandaria!

Druid options have been re-ordered to be more intuitive.

New Spell Alerts
- Lunar Eclipse and Solar Eclipse (Mists of Pandaria)
- Shooting Stars (Mists of Pandaria)
- Tooth and Claw (Mists of Pandaria)
- Predatory Swiftness (Mists of Pandaria)
- Omen of Clarity, for Feral and Restoration (Mists of Pandaria)

New Glowing Button
- Entangling Roots, during Predatory Swiftness (Mists of Pandaria)
- Healing Touch, during Predatory Swiftness (Mists of Pandaria)
- Hibernate, during Predatory Swiftness (Mists of Pandaria)
- Rebirth, during Predatory Swiftness (Mists of Pandaria)
### :mage~1:  Mage
The Mage class is now fully supported for Mists of Pandaria!

Mage options have been re-ordered to be more intuitive.

New Spell Alerts
- Arcane Missiles (Mists of Pandaria)
- Heating Up (Mists of Pandaria)
- Hot Streak (Mists of Pandaria)
- Brain Freeze (Mists of Pandaria)
- Fingers of Frost (Mists of Pandaria)

New Glowing Buttons
- Arcane Missiles, during Arcane Missiles (Mists of Pandaria)
- Inferno Blast\*, during Heating Up (Mists of Pandaria)
- Pyroblast, during Hot Streak (Mists of Pandaria)
- Frostfire Bolt, during Brain Freeze (Mists of Pandaria)
- Deep Freeze, during Fingers of Frost (Mists of Pandaria)
- Ice Lance, during Fingers of Frost (Mists of Pandaria)

\* Inferno Blast does not glow by default, in case Mages prefer to keep the Inferno Blast cooldown to spread damage over time effects.
### :priest:  Priest
New Glowing Button
- Devouring Plague, at 3 Shadow Orbs (Mists of Pandaria)

Although the game client already glows the button of Devouring Plague at 3 Shadow Orbs, it has some flaws:
- It only lets the button glow for up to 30 seconds, probably to avoid buttons constantly glowing while AFK
- Devouring Plague does not glow when the Priest got the 3rd shadow orb from the new functionality that grants an orb every 6 seconds out of combat

The addon solves both issues by setting Devouring Plague as _combat-only_.
## Bug Fixes
## Known Limitations
### :priest:  Priest
Because the game client glows Devouring Plague for 30 seconds, the button will keep glowing even when the Priest leaves combat, up until 30 seconds after getting/refreshing the 3rd orb (or up until Devouring Plague is cast, obviously).
## Miscellaneous
## Contributors
Shout-out to our amazing contributors
- Siegester03, for helping a great deal with the Mage class
Thanks!

As always, the latest release is available on [CurseForge](https://www.curseforge.com/wow/addons/spellactivationoverlay) / [GitHub](https://github.com/ennvina/spellactivationoverlay/releases/latest) / [Discord](https://discord.com/channels/1013194771969355858/1379111832207228938)