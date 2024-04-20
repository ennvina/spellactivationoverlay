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
echo -n "Cleaning up wrath directory... "
# Remove unused textures to reduce the archive size.
# The list below, TEXTURES_NOT_FOR_WRATH, is a list of textures added exclusively for Season of Discovery.
TEXTURES_NOT_FOR_WRATH=(tooth_and_claw
monk_serpent
raging_blow
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination)
for texname in ${TEXTURES_NOT_FOR_WRATH[@]}
do
    rm -f SpellActivationOverlay/textures/"$texname".* || bye "Cannot cleanup textures from wrath installation"
done
echo
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
VANILLA_BUILD_VERSION=11502
sed -i s/'^## Interface:.*'/"## Interface: $VANILLA_BUILD_VERSION"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update version of TOC file"
# Remove everything related to DK
sed -i '/deathknight/d' SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove deathknight from TOC file"
rm -f SpellActivationOverlay/classes/deathknight.lua || bye "Cannot remove deathknight class file"
# Remove unused textures to reduce the archive size.
# The list below, TEXTURES_NOT_FOR_VANILLA, is based on the contents of
# SpellActivationOverlayDB.debug.unmarked after calling the global
# function SAO_DB_ComputeUnmarkedTextures() on each and every class
# on characters logged in with the Classic Era game client.
# Because these textures are not 'marked', we don't need them.
TEXTURES_NOT_FOR_VANILLA=(master_marksman
molten_core
art_of_war
lock_and_load
sudden_death
shooting_stars
daybreak
backlash
predatory_swiftness
sword_and_board
killing_machine
rime)
for texname in ${TEXTURES_NOT_FOR_VANILLA[@]}
do
    rm -f SpellActivationOverlay/textures/"$texname".* || bye "Cannot cleanup textures from vanilla installation"
done
echo
echo -n "Zipping vanilla directory... "
"$CWD"/zip -9 -r -q SpellActivationOverlay-"$VERSION_TOC_VERSION"-vanilla.zip SpellActivationOverlay || bye "Cannot zip vanilla directory"
echo
explorer . # || bye "Cannot open explorer to vanilla directory"

cd "$CWD"/.. || bye "Cannot go to parent directory"

# Release cata version
rm -rf ./_release/cata || bye "Cannot clean cata directory"
mkdir -p ./_release/cata/SpellActivationOverlay || bye "Cannot create cata directory"
cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options textures ./_release/cata/SpellActivationOverlay/ || bye "Cannot copy cata files"
cd ./_release/cata || bye "Cannot cd to cata directory"
echo -n "Cleaning up cata directory... "
# Change Interface version; to know the version of a specific game client, enter: /dump select(4, GetBuildInfo())
CATA_BUILD_VERSION=40400
sed -i s/'^## Interface:.*'/"## Interface: $CATA_BUILD_VERSION"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update version of TOC file"
# Remove unused textures to reduce the archive size.
# The list below, TEXTURES_NOT_FOR_CATA, is a list of textures added exclusively for Season of Discovery.
TEXTURES_NOT_FOR_CATA=(tooth_and_claw
monk_serpent
raging_blow
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination)
for texname in ${TEXTURES_NOT_FOR_CATA[@]}
do
    rm -f SpellActivationOverlay/textures/"$texname".* || bye "Cannot cleanup textures from wrath installation"
done
echo
echo -n "Zipping cata directory... "
"$CWD"/zip -9 -r -q SpellActivationOverlay-"$VERSION_TOC_VERSION"-cata.zip SpellActivationOverlay || bye "Cannot zip cata directory"
echo
explorer . # || bye "Cannot open explorer to cata directory"
