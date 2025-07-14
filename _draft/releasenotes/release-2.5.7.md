# SpellActivationOverlay 2.5.7
@here I am pleased to announce the newest release of SpellActivationOverlay, version 2.5.7
## General
### Options Panel
Players who opted out to disable the game's spell alerts can choose to ask the question again (Mists of Pandaria). If you would close the dialog box by mistake and would like to answer the question
- open the Options Panel, either by going to Options > AddOns > SpellActivationOverlay, or by typing `/sao`
- check the combo box named "Detect conflicts with the game's spell alerts"
## Classes
### :monk:  Monk
New Spell Alert
- Vital Mists (Mists of Pandaria)

Updated Spell Alerts
- Blackout Kick is now only displayed right (Mists of Pandaria)
- Tiger Palm is now green-ish and displayed left (Mists of Pandaria)
### :paladin:  Paladin
Updated Spell Alerts
- Infusion of Light now uses Daybreak visuals (Mists of Pandaria)
- Daybreak now uses Sun-like visuals (Mists of Pandaria)

Infusion of Light now matches the reference client. The Daybreak effect needed other visuals to avoid confusion with Infusion of Light.

_Developer's Note: Historically, the game has been inconsistent between texture names and effects, and Paladin is one of the most affected classes by this issue. Let's hope these new visuals will not cause too much confusion among our dearest purple plate wearers._

Removed Glowing Buttons
- Hammer of Wrath (Mists of Pandaria)
- Holy Shock, during Daybreak (Mists of Pandaria)
- Divine Light, during Infusion of Light (Mists of Pandaria)
- Holy Light, during Infusion of Light (Mists of Pandaria)
- Holy Radiance, during Infusion of Light (Mists of Pandaria)
- Avenger's Shield, during Grand Crusader (Mists of Pandaria)

_Developer's Note: These buttons are already glowing by the game client. When players unchecked such buttons in the addon's options panel, it was confusing because the buttons were still glowing even though the player asked explicitly not to. Since the addon cannot prevent the game client from glowing buttons, the wise choice is to simply remove these buttons from the addon._
### :rogue:  Rogue
New Glowing Button
- Dispatch, when the target has less than 35% health (Mists of Pandaria)
### :shaman:  Shaman
New Glowing Button
- Lava Burst, as combat-only counter (Mists of Pandaria)
## Bug Fixes
Text from the lower-right box of the Options Panel could display characters incorrectly, usually as small rectangles. This affected the so-called _non-ASCII characters_, such as:
- letters with accents or other diacritics: á, ê, ñ, ç...
- non-Latin characters: д, й, 일, 文...

Unknown effect detection could sometimes display reports for effects that were actually known (Mists of Pandaria).

In very rare cases, glowing a button could trigger a Lua error. The cause is not known for sure, but the Lua error should no longer happen, and a more explicit warning will be reported instead. As always, make sure to report errors and warning so we can investigate. Thank you :)
## Miscellaneous
All checkboxes are now translated at the bottom of the Options Panel.
## Contributors
Shout-out to our amazing contributors
- Jumpsuitpally for sending feedback about Paladin and Monk
- Krablord for sending feedback about Rogue and Shaman
- Bruni for reporting an issue that triggered false positive unknown effects
- omeletteman91 for reporting an unsupported effect

Thanks!

As always, the latest release is available on [CurseForge](https://www.curseforge.com/wow/addons/spellactivationoverlay) / [GitHub](https://github.com/ennvina/spellactivationoverlay/releases/latest) / [Discord](https://discord.com/channels/1013194771969355858/1379111832207228938)