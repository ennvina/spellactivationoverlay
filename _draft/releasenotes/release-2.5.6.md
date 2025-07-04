# SpellActivationOverlay 2.5.6
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.5.6

This release fixes a couple of minor issues for Mists of Pandaria, and a major issue for Classic Era that popped up out of nowhere.
## General
## Classes
### :paladin:  Paladin
New Spell Alert
- The Art of War (Mists of Pandaria)
## Bug Fixes
### :druid:  Druid
Druids no longer get error from loading Eclipse Moon and Eclipse Sun textures at start (Mists of Pandaria).
### :hunter:  Hunter
The following abilities would not always glow
- Counterattack (Era, TBC, Wrath)
- Kill Shot (Wrath)
- Mongoose Bite (Era, TBC)

This issue happened only if all the following conditions were met at the same time
- The ability is Rank 2 or higher
- The Hunter has reloaded their interface after learning Rank 2
- The "Show all spell ranks" option is disabled in the Spellbook
### :paladin:  Paladin
The following spells would not always glow
- Exorcism (Era, TBC, Wrath)
- Hammer of Wrath (Era, TBC, Wrath)
- Holy Shock (Era, TBC, Wrath)

This issue happened only if all the following conditions were met at the same time
- The spell is Rank 2 or higher
- The Paladin has reloaded their interface after learning Rank 2
- The "Show all spell ranks" option is disabled in the Spellbook
### :warrior:  Warrior
The following abilities would not always glow
- Warrior's Execute (Era, TBC, Wrath)
- Warrior's Overpower (Era, TBC)
- Warrior's Revenge (Era, TBC, Wrath)

This issue happened only if all the following conditions were met at the same time
- The ability is Rank 2 or higher
- The Warrior has reloaded their interface after learning Rank 2
- The respective options are setup to the exclusive stance(s) the ability can be cast in

As an example of the latter condition, Overpower could fail to glow if its option was set to "Battle Stance only" and would correctly glow if the option was set to "All stances".
## Known Limitations
## Miscellaneous
## Contributors
Shout-out to our amazing contributors
- jokke and mistik911 for reporting the Warrior's Overpower issue
- Adal4 for reporting the Paladin's The Art of War issue
- Amanthuul and kakukembo for reporting the Druid's Eclipse issue
Thanks!

As always, the latest release is available on [CurseForge](https://www.curseforge.com/wow/addons/spellactivationoverlay) / [GitHub](https://github.com/ennvina/spellactivationoverlay/releases/latest) / [Discord](https://discord.com/channels/1013194771969355858/1379111832207228938)