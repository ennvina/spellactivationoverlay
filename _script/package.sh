#!/bin/bash
CWD=$(cd -P "$(dirname "$0")" && pwd)

bye() {
    echo "$1" >&2;
    exit 1
}

cd "$CWD"/.. || bye "Cannot go to parent directory"

VERSION=$(grep -i '^##[[:space:]]*version:' ./SpellActivationOverlay.toc | grep -o '[0-9].*')
([ -z "$VERSION" ] || [[ "$VERSION" =~ \n ]]) && bye "Cannot retrieve version from TOC file"

# Release wrath version
rm -rf ./_release/wrath || bye "Cannot clean wrath directory"
mkdir -p ./_release/wrath/SpellActivationOverlay || bye "Cannot create wrath directory"
cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options textures ./_release/wrath/SpellActivationOverlay/ || bye "Cannot copy wrath files"
cd ./_release/wrath || bye "Cannot cd to wrath directory"
echo -n "Zipping wrath directory... "
"$CWD"/zip -9 -r -q SpellActivationOverlay-"$VERSION"-wrath.zip SpellActivationOverlay || bye "Cannot zip wrath directory"
echo
explorer . # || bye "Cannot open explorer to wrath directory"

cd "$CWD"/.. || bye "Cannot go to parent directory"

# Release vanilla version
rm -rf ./_release/vanilla || bye "Cannot clean vanilla directory"
mkdir -p ./_release/vanilla/SpellActivationOverlay || bye "Cannot create vanilla directory"
cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options textures ./_release/vanilla/SpellActivationOverlay/ || bye "Cannot copy vanilla files"
cd ./_release/vanilla || bye "Cannot cd to vanilla directory"
echo -n "Cleaning up vanilla directory... "
# Remove everything related to DK
sed -i '/deathknight/d' SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot cleanup vanilla TOC file"
rm -f SpellActivationOverlay/classes/deathknight.lua || bye "Cannot remove deathknight class file"
# Remove unused textures to reduce the archive size.
# The list below, WRATH_ONLY_TEXTURES, is based on the contents of
# SpellActivationOverlayDB.debug.unmarked after calling the global
# function SAO_DB_ComputeUnmarkedTextures() on each and every class
# on characters logged in with the Classic Era game client.
# Because these textures are not 'marked', we don't need them.
WRATH_ONLY_TEXTURES=(master_marksman
molten_core
imp_empowerment
art_of_war
lock_and_load
blood_surge
brain_freeze
frozen_fingers
maelstrom_weapon_2
sudden_death
shooting_stars
maelstrom_weapon
high_tide
daybreak
eclipse_moon
maelstrom_weapon_4
backlash
predatory_swiftness
sword_and_board
impact
arcane_missiles
hot_streak
killing_machine
maelstrom_weapon_3
rime
surge_of_light
eclipse_sun
maelstrom_weapon_1)
for texname in ${WRATH_ONLY_TEXTURES[@]}
do
    rm -f SpellActivationOverlay/textures/"$texname".* || bye "Cannot cleanup textures from vanilla installation"
done
echo
echo -n "Zipping vanilla directory... "
"$CWD"/zip -9 -r -q SpellActivationOverlay-"$VERSION"-vanilla.zip SpellActivationOverlay || bye "Cannot zip vanilla directory"
echo
explorer . # || bye "Cannot open explorer to vanilla directory"
