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
    cp -R changelog.md LICENSE SpellActivationOverlay.* classes components options sounds textures variables ./_release/$flavor/SpellActivationOverlay/ || bye "Cannot copy $flavor files"
    cd ./_release/$flavor || bye "Cannot cd to $flavor directory"
    sed -i s/'^## Interface:.*'/"## Interface: $build_version"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update version of $flavor TOC file"
    echo
}

# Remove copyright of given expansions because the addon does not embed texture for these expansions
# Expansion anmes are case sensitive, and must match one of the copyrights includes in TOC file
# $1+ = expansions
prunecopyright() {
    for expansion in "$@"
    do
        grep -q "${expansion}" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot find copyright of expansion ${expansion} in TOC file"
        sed -i "/${expansion}/,+2d" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove copyright of expansion ${expansion} from TOC file"
    done
}

# Remove unused variables to reduce archive size.
# $@ = array of variables
prunevar() {
    echo -n "Cleaning up variables..."
    for varname in "$@"
    do
        sed -i "/$varname/d" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove $varname from TOC file"
        rm -f SpellActivationOverlay/variables/"$varname".* || bye "Cannot cleanup variables from installation"
    done
    echo
}

# Find texture names which file data ID is lesser or equal to a specific threshold
# Such textures are supposed to be already embedded in the game files
# $1 = threshold up until textures are supposed to be embedded, and can be pruned
# $2+ = IDs to avoid even if they are below the threshold
texbelow() {
    local threshold=$1
    shift
    awk '/^local mapping/{flag=1;next;next} /^}/{flag=0} flag' SpellActivationOverlay/textures/texname.lua |
        tr " \t" "_" | tr -d "'" |
        awk -F'"' "1${*/#/ \&\& \$2!=}" |
        awk -F'"' "{ if (\$2 <= $threshold) print \$4 }" |
        while read name
        do
            [ -e "SpellActivationOverlay/textures/${name,,}.blp" ] && printf '%s\n' "${name,,}"
        done
}

# Remove unused textures to reduce archive size.
# The list passed as parameter is based on the contents of the array
# SpellActivationOverlayDB.dev.unmarked after calling the global
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
        sed -i "/$classname/d" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove $classname from TOC file"
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
VERSION_TOC_TITLE=$(grep -i '^##[[:space:]]*title:' ./SpellActivationOverlay.toc | grep -o '|c........[0-9].*|r' | grep -o '[0-9]\.[^|]*')
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

VARIABLES_NOT_FOR_WRATH=(holypower nativesao)
prunevar "${VARIABLES_NOT_FOR_WRATH[@]}"

TEXTURES_NOT_FOR_WRATH=(
tooth_and_claw
monk_serpent
raging_blow
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination
sudden_doom)
prunetex "${TEXTURES_NOT_FOR_WRATH[@]}"

zipproject wrath "$VERSION_TOC_VERSION"

cdup

# Release vanilla version
VANILLA_BUILD_VERSION=11502
mkproject vanilla $VANILLA_BUILD_VERSION

VARIABLES_NOT_FOR_VANILLA=(holypower nativesao)
prunevar "${VARIABLES_NOT_FOR_VANILLA[@]}"

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
killing_machine
rime
sudden_doom)
prunetex "${TEXTURES_NOT_FOR_VANILLA[@]}"

zipproject vanilla "$VERSION_TOC_VERSION"

cdup

# Release cata version
CATA_BUILD_VERSION=40400
mkproject cata $CATA_BUILD_VERSION

prunecopyright Cataclysm

TEXTURES_NOT_FOR_CATA=(
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination
monk_serpent
raging_blow
tooth_and_claw
$(texbelow 511469 450914 450915)
)
prunetex "${TEXTURES_NOT_FOR_CATA[@]}"

SOUNDS_NOT_FOR_CATA=(UI_PowerAura_Generic)
prunesound "${SOUNDS_NOT_FOR_CATA[@]}"

zipproject cata "$VERSION_TOC_VERSION"

cdup
