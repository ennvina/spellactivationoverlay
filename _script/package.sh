#!/bin/bash
CWD=$(cd -P "$(dirname "$0")" && pwd)

bye() {
    echo "$1" >&2
    stat=($(</proc/$$/stat))
    [ ${stat[3]} -eq 1 ] && read # Pause if called in separate window
    exit 1
}

cd "$CWD"/.. || bye "Cannot go to parent directory"

# Retrieve version and check consistency
VERSION_TOC_VERSION=$(grep -i '^##[[:space:]]*version:' ./SpellActivationOverlay.toc | grep -o '[0-9].*')
VERSION_TOC_TITLE=$(grep -i '^##[[:space:]]*title:' ./SpellActivationOverlay.toc | grep -o '|c........[0-9].*|r' | grep -o '[0-9]*\.[^|]*')
VERSION_CHANGELOG=$(grep -m1 -o '^#### v[^[:space:]]*' ./changelog.md | grep -o '[0-9].*')
if [ -z "$VERSION_TOC_VERSION" ] || [[ "$VERSION_TOC_VERSION" =~ \n ]] \
|| [ -z "$VERSION_TOC_TITLE" ] || [[ "$VERSION_TOC_TITLE" =~ \n ]]
then
    bye "Cannot retrieve version from TOC file"
fi
if [ -z "$VERSION_CHANGELOG" ] || [[ "$VERSION_CHANGELOG" =~ \n ]]
then
    bye "Cannot retrieve version from ChangeLog file"
fi
if [ "$VERSION_TOC_VERSION" != "$VERSION_TOC_TITLE" ] || [ "$VERSION_TOC_VERSION" != "$VERSION_CHANGELOG" ]
then
    bye "Versions do not match: $VERSION_TOC_VERSION (toc, version) vs. $VERSION_TOC_TITLE (toc, title) vs. $VERSION_CHANGELOG (changelog)"
fi

# Release wrath version
rm -rf ./_release/wrath || bye "Cannot clean wrath directory"
mkdir -p ./_release/wrath/SpellActivationOverlay || bye "Cannot create wrath directory"
cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options textures ./_release/wrath/SpellActivationOverlay/ || bye "Cannot copy wrath files"
cd ./_release/wrath || bye "Cannot cd to wrath directory"
echo -n "Zipping wrath directory... "
"$CWD"/zip -9 -r -q SpellActivationOverlay-"$VERSION_TOC_VERSION"-wrath.zip SpellActivationOverlay || bye "Cannot zip wrath directory"
echo
explorer . # || bye "Cannot open explorer to wrath directory"

cd "$CWD"/.. || bye "Cannot go to parent directory"

# Release vanilla version
rm -rf ./_release/vanilla || bye "Cannot clean vanilla directory"
mkdir -p ./_release/vanilla/SpellActivationOverlay || bye "Cannot create vanilla directory"
cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options textures ./_release/vanilla/SpellActivationOverlay/ || bye "Cannot copy vanilla files"
cd ./_release/vanilla || bye "Cannot cd to vanilla directory"
echo -n "Cleaning up vanilla directory... "
# Change Interface version; to know the version of a specific game client, enter: /dump select(4, GetBuildInfo())
VANILLA_BUILD_VERSION=11403
sed -i s/'^## Interface:.*'/"## Interface: $VANILLA_BUILD_VERSION"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update version of TOC file"
# Remove everything related to DK
sed -i '/deathknight/d' SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove deathknight from TOC file"
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
"$CWD"/zip -9 -r -q SpellActivationOverlay-"$VERSION_TOC_VERSION"-vanilla.zip SpellActivationOverlay || bye "Cannot zip vanilla directory"
echo
explorer . # || bye "Cannot open explorer to vanilla directory"
