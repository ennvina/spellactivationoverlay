#!/bin/bash
CWD=$(cd -P "$(dirname "$0")" && pwd)

# Exit with specific message. Pause the window if running in a separate window.
# $1 = message to display before exiting
bye() {
    echo "$1" >&2
    stat=($(</proc/$$/stat))
    [ ${stat[3]} -eq 1 ] && read # Pause if called in separate window
    exit 1
}

# Utility function to cd back to base directory and exit if error.
cdup() {
    cd "$CWD"/.. || bye "Cannot go to parent directory"
}

# Create a project directory and copy all addon files to it.
# Remove existing project directory, if any.
# Current directory (cd) ends up in the new directory.
# $1 = flavor
# $2 = build version, fetched from /dump select(4, GetBuildInfo())
mkproject() {
    local flavor=$1
    local build_version=$2

    echo
    echo "==== ${flavor^^} ===="
    echo -n "Creating $flavor project..."
    rm -rf ./_release/$flavor || bye "Cannot clean wrath directory"
    mkdir -p ./_release/$flavor/SpellActivationOverlay || bye "Cannot create $flavor directory"
    cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options sounds textures ./_release/$flavor/SpellActivationOverlay/ || bye "Cannot copy $flavor files"
    cd ./_release/$flavor || bye "Cannot cd to $flavor directory"
    sed -i s/'^## Interface:.*'/"## Interface: $build_version"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update version of $flavor TOC file"
    echo
}

# Remove unused textures to reduce archive size.
# The list passed as parameter is based on the contents of the array
# SpellActivationOverlayDB.debug.unmarked after calling the global
# function SAO_DB_ComputeUnmarkedTextures() on each and every class
# on characters logged in with the game client of the target flavor.
# Because these textures are not 'marked', we don't need them.
# $@ = array of textures
prunetex() {
    echo -n "Cleaning up textures..."
    for texname in "$@"
    do
        rm -f SpellActivationOverlay/textures/"$texname".* || bye "Cannot cleanup textures from installation"
    done
    echo
}

# Remove unused sounds to reduce archive size.
# $@ = array of sounds
prunesound() {
    echo -n "Cleaning up sounds..."
    for soundname in "$@"
    do
        rm -f SpellActivationOverlay/sounds/"$soundname".* || bye "Cannot cleanup sounds from installation"
    done
    if ! ls -1 SpellActivationOverlay/sounds | grep -q .
    then
        rmdir SpellActivationOverlay/sounds || bye "Cannot remove empty 'sounds' directory"
    fi
    echo
}

# Remove everything related to specific classes to reduce archive size.
# $@ = array of classes
pruneclass() {
    echo -n "Cleaning up classes..."
    for classname in "$@"
    do
        sed -i "/$classname/d" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove $classname from TOC filer"
        rm -f SpellActivationOverlay/classes/$classname.lua || bye "Cannot remove $classname class file"
    done
    echo
}

# Gather all files of the current folder to a single zip.
# $1 = flavor
# $2 = addon version
# $3 = alpha/beta/etc. (optional)
zipproject() {
    local flavor=$1
    local version=$2

    echo -n "Zipping $flavor directory..."
    local filename=SpellActivationOverlay-"$version"${3:+-}$3-${flavor}.zip
    "$CWD"/zip -9 -r -q "$filename" SpellActivationOverlay || bye "Cannot zip $flavor directory"
    echo
    explorer . # || bye "Cannot open explorer to $flavor directory"
}

# Retrieve version and check consistency
cdup
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
WRATH_BUILD_VERSION=30403
mkproject wrath $WRATH_BUILD_VERSION

TEXTURES_NOT_FOR_WRATH=(
tooth_and_claw
monk_serpent
raging_blow
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination)
prunetex "${TEXTURES_NOT_FOR_WRATH[@]}"

zipproject wrath "$VERSION_TOC_VERSION"

cdup

# Release vanilla version
VANILLA_BUILD_VERSION=11502
mkproject vanilla $VANILLA_BUILD_VERSION

CLASSES_NOT_FOR_VANILLA=(deathknight)
pruneclass "${CLASSES_NOT_FOR_VANILLA[@]}"

TEXTURES_NOT_FOR_VANILLA=(
master_marksman
molten_core
art_of_war
sudden_death
shooting_stars
daybreak
backlash
predatory_swiftness
sword_and_board
killing_machine
rime)
prunetex "${TEXTURES_NOT_FOR_VANILLA[@]}"

zipproject vanilla "$VERSION_TOC_VERSION"

cdup

# Release cata version
CATA_BUILD_VERSION=40400
mkproject cata $CATA_BUILD_VERSION

TEXTURES_NOT_FOR_CATA=(
tooth_and_claw
monk_serpent
raging_blow
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination)
prunetex "${TEXTURES_NOT_FOR_CATA[@]}"

SOUNDS_NOT_FOR_CATA=(UI_PowerAura_Generic)
prunesound "${SOUNDS_NOT_FOR_CATA[@]}"

zipproject cata "$VERSION_TOC_VERSION" alpha

cdup
