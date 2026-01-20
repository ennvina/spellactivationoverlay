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

# Remove stuff dedicated to developers to optimize archive size and speed up the addon
prunedev() {
    echo -n "Removing developer-specific code..."

    # Remove dev variables
    FILES_TO_REMOVE=(variables/_template.lua)
    for filetoremove in "${FILES_TO_REMOVE[@]}"
    do
        rm -f SpellActivationOverlay/"$filetoremove" || bye "Cannot remove file $filetoremove"
    done

    # Remove developer-specific calls in code
    echo -ne " \033[s" # Save cursor position
    PATHS_WITH_DEV_CODE=(SpellActivationOverlay/SpellActivationOverlay.lua SpellActivationOverlay/components/)
    NB_PATHS_WITH_DEV_CODE=$(find "${PATHS_WITH_DEV_CODE[@]}" -type f -name '*.lua' -printf . | wc -c)
    NB_FILES_PROCESSED=0
    echo -n "[1/2] 0/${NB_PATHS_WITH_DEV_CODE}"
    find "${PATHS_WITH_DEV_CODE[@]}" -type f -name '*.lua' -print0 |
        while read -r -d '' filename
        do
            # Remove SAO:Trace calls
            if grep -q 'SAO:Trace' "$filename"
            then
                sed -i '/SAO:Trace/d' "$filename" || bye "Cannot remove trace code from $filename"
            fi

            # Remove DEV_ONLY blocks
            if grep -q 'BEGIN_DEV_ONLY' "$filename"
            then
                sed -i '/BEGIN_DEV_ONLY/,/END_DEV_ONLY/d' "$filename" || bye "Cannot remove developer-specific code block from $filename"
            fi
            if grep -q 'DEV_ONLY' "$filename"
            then
                sed -i '/DEV_ONLY/d' "$filename" || bye "Cannot remove developer-specific code from $filename"
            fi

            echo -ne "\033[u[1/2] $((++NB_FILES_PROCESSED))/${NB_PATHS_WITH_DEV_CODE}"
        done

    # Pseudo-minify by removing things like comments and blank lines
    # Must be done after removing DEV_ONLY blocks to avoid removing comments that would contain DEV_ONLY markers
    NB_PATHS_TO_MINIFY=$(find "SpellActivationOverlay/" -type f -name '*.lua' -printf . | wc -c)
    NB_FILES_PROCESSED=0
    echo -ne "\033[u"; printf "%$((8 + 2 * ${#NB_PATHS_WITH_DEV_CODE}))s" ""; echo -ne "\033[u" # Erase former progress line
    echo -n "0/${NB_PATHS_TO_MINIFY}"
    find "SpellActivationOverlay/" -type f -name '*.lua' -print0 |
        while read -r -d '' filename
        do
            # Remove comment-only blocks
            sed -i '/^[[:space:]]*--\[\[/,/[[:space:]]*\]\]/d' "$filename" || bye "Cannot remove comment blocks from $filename"

            # Remove comment-only lines and blank lines
            COMMENT_ONLY_LINE='^[[:space:]]*--.*$'
            BLANK_LINE='^[[:space:]]*$'
            sed -i "/$COMMENT_ONLY_LINE/d;/$BLANK_LINE/d" "$filename" || bye "Cannot remove comments and blank lines from $filename"

            # Remove end-of-line comments, except in strings; assumes no multi-line strings and no -- in single-quote strings
            # Also remove leading spaces, trailing spaces, and trailing semicolons
            EOL_COMMENT='[[:space:]]*--[^"]*$'
            LEADING_SPACES='^[[:space:]]*'
            TRAILING_SPACES='[[:space:]]*$'
            TRAILING_SEMICOLON=';[[:space:]]*$'
            sed -i "s/$EOL_COMMENT//;s/$LEADING_SPACES//;s/$TRAILING_SPACES//;s/$TRAILING_SEMICOLON//" "$filename" || bye "Cannot remove syntactic sugar from $filename"

            echo -ne "\033[u[2/2] $((++NB_FILES_PROCESSED))/${NB_PATHS_TO_MINIFY}"
        done

    echo
}

# Creae the base project directory, that will be copied for each flavor
mkbaseproject() {
    echo -n "Creating base project..."
    rm -rf ./_release/base || bye "Cannot clean base directory"
    mkdir -p ./_release/base/SpellActivationOverlay || bye "Cannot create base directory"
    cp -R changelog.md LICENSE SpellActivationOverlay.* classes components libs options sounds textures variables ./_release/base/SpellActivationOverlay/ || bye "Cannot copy base files"
    echo

    # Always prune dev by default
    cd ./_release/base || bye "Cannot cd to base directory"
    prunedev
    cdup
}

# Create a project directory and copy all addon files to it.
# Remove existing project directory, if any.
# Current directory (cd) ends up in the new directory.
# $1 = flavor
# $2 = build version, fetched from /dump select(4, GetBuildInfo())
# $3 = flavor color (RGB hex code without leading #)
# $4 = flavor icon
# $5 = flavor icon margin
# $6 = (unused) flavor full name
# $7 = flag to unset the prefix icon in the title
mkproject() {
    local flavor=$1
    local build_version=$2
    local flavor_color='ff'"$3"
    local flavor_icon_margin=${5:-16}
    local flavor_icon_coord_min=$flavor_icon_margin
    local flavor_icon_coord_max=$((512 - $flavor_icon_margin))
    local flavor_icon='|TInterface\/Icons\/'"$4:16:16:0:0:512:512:$flavor_icon_coord_min:$flavor_icon_coord_max:$flavor_icon_coord_min:$flavor_icon_coord_max|t"
    local flavor_fullname=$6
    local flavor_noprefixicon=$7

    echo
    echo "==== ${flavor^^} ===="
    echo -n "Creating $flavor project..."
    rm -rf ./_release/"$flavor" || bye "Cannot clean $flavor directory"
    mkdir -p ./_release/"$flavor"/SpellActivationOverlay || bye "Cannot create $flavor directory"
    cp -R ./_release/base/SpellActivationOverlay ./_release/"$flavor"/ || bye "Cannot copy base files to $flavor"
    cd ./_release/"$flavor" || bye "Cannot cd to $flavor directory"
    sed -i s/'^## Interface:.*'/"## Interface: $build_version"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update version of $flavor TOC file"
    sed -i s%'^\(##[[:space:]]*Title:.*|c\)\(........\)\([0-9][^|]*\)|r |T[^|]*|t'%'\1'"$flavor_color"'\3|r '"$flavor_icon"% SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update title of $flavor TOC file"
    sed -i s/'^## X-SAO-Build:.*'/"## X-SAO-Build: $flavor"/ SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot update X-SAO-Build of $flavor TOC file"
    if [ -n "$flavor_noprefixicon" ]
    then
        sed -i 's/|T[^|]*Spell_Frost_Stun[^|]*|t[[:space:]]*//' SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove prefix icon from title of $flavor TOC file"
    fi
    echo
}

# Remove copyright of given expansions because the addon does not embed texture for these expansions
# Expansion anmes are case sensitive, and must match one of the copyrights includes in TOC file
# $1+ = expansions
prunecopyright() {
    for expansion in "$@"
    do
        grep -q "World of Warcraft.*${expansion}" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot find copyright of expansion ${expansion} in TOC file"
        sed -i "/World of Warcraft.*${expansion}/,+2d" SpellActivationOverlay/SpellActivationOverlay.toc || bye "Cannot remove copyright of expansion ${expansion} from TOC file"
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
        rm -f SpellActivationOverlay/classes/"$classname".lua || bye "Cannot remove $classname class file"
    done
    echo
}

# Remove trailing \r characters
# $@ = array of file wildcards
dos2unix() {
    echo -n "Converting files from DOS to Unix..."
    for wildcard in "$@"
    do
        find . -type f -name "$wildcard" -print0 | xargs -0 sed -i 's/\r$//' || bye "Cannot convert from DOS to Unix"
    done
    echo
}

# Replace code contents
# Replacement is done with sed; strings must not contain characters messing around with sed
# $1 = text to replace
# $2 = replacement text
# $3+ = file wildcards
replacecode() {
    local before=$1
    local after=$2
    shift 2
    echo -n "Replacing source code from $before to $after..."
    for wildcard in "$@"
    do
        find . -type f -name "$wildcard" -print0 | xargs -0 sed -i "s~$before~$after~g" || bye "Cannot replace source code"
    done
    echo
}

# Transform a TOC file into XML file that includes scripts and UIs
# The TOC file is deleted in the process
# $1 = TOC file input
# $2 = XML file output
toc2xml() {
    local tocfile=SpellActivationOverlay/"$1"
    local xmlfile=SpellActivationOverlay/"$2"
    echo -n "Transforming TOC file into XML include file"
    cat > "$xmlfile" <<EOF
<Ui xmlns="http://www.blizzard.com/wow/ui/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.blizzard.com/wow/ui/ ..\FrameXML\UI.xsd">
EOF
    local nlines=0
    sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' "$tocfile" |
        grep -Eo '^[[:alnum:]\./\\-]*.(lua|xml)$' |
        tr '\\' / |
        while read f
        do
            if [[ "$f" =~ \.lua$ ]]
            then
                printf '\t<Script file="%s"/>\n' "$f" || bye "Cannot write XML file"
            else
                printf '\t<Include file="%s"/>\n' "$f" || bye "Cannot write XML file"
            fi
            ((++nlines))
        done >> "$xmlfile"
    [ $(wc -l "$xmlfile" | grep -Eo '^[0-9]+') -gt 0 ] || bye "No lines written to XML file"
cat >> "$xmlfile" <<EOF
</Ui>
EOF
    rm "$tocfile" || bye "Cannot remove former TOC file"
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
    "$CWD"/zip.exe -9 -r -q "$filename" SpellActivationOverlay || bye "Cannot zip $flavor directory"
    echo
    explorer.exe . # || bye "Cannot open explorer to $flavor directory"
}

# Retrieve version and check consistency
cdup
VERSION_TOC_VERSION=$(grep -i '^##[[:space:]]*version:' ./SpellActivationOverlay.toc | grep -o '[0-9].*[^[:space:]]')
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
release_wrath() {
WRATH_BUILD_VERSION=30403
mkproject wrath $WRATH_BUILD_VERSION 40abff achievement_boss_lichking 64 "Wrath of the Lich King"

VARIABLES_NOT_FOR_WRATH=(holypower nativesao)
prunevar "${VARIABLES_NOT_FOR_WRATH[@]}"

CLASSES_NOT_FOR_WRATH=(monk)
pruneclass "${CLASSES_NOT_FOR_WRATH[@]}"

TEXTURES_NOT_FOR_WRATH=(
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination
fury_of_stormrage_yellow
maelstrom_weapon_6
maelstrom_weapon_7
maelstrom_weapon_8
maelstrom_weapon_9
maelstrom_weapon_10
monk_serpent
raging_blow
shadow_word_insanity
sudden_doom
thrill_of_the_hunt_1
thrill_of_the_hunt_2
thrill_of_the_hunt_3
tooth_and_claw
white_tiger
rkm128)
prunetex "${TEXTURES_NOT_FOR_WRATH[@]}"

zipproject wrath "$VERSION_TOC_VERSION"

cdup
}

# Release TBC version
release_tbc() {
TBC_BUILD_VERSION=20505
mkproject tbc $TBC_BUILD_VERSION 2da203 achievement_dungeon_outland_dungeonmaster 64 "The Burning Crusade" true

VARIABLES_NOT_FOR_TBC=(holypower nativesao)
prunevar "${VARIABLES_NOT_FOR_TBC[@]}"

CLASSES_NOT_FOR_TBC=(deathknight monk)
pruneclass "${CLASSES_NOT_FOR_TBC[@]}"

TEXTURES_NOT_FOR_TBC=(
arcane_missiles
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
art_of_war
blood_surge
daybreak
fulmination
fury_of_stormrage
high_tide
impact
killing_machine
lock_and_load
maelstrom_weapon
maelstrom_weapon_1
maelstrom_weapon_2
maelstrom_weapon_3
maelstrom_weapon_4
maelstrom_weapon_6
maelstrom_weapon_7
maelstrom_weapon_8
maelstrom_weapon_9
maelstrom_weapon_10
master_marksman
molten_core
monk_serpent
predatory_swiftness
raging_blow
rime
shooting_stars
sudden_death
sudden_doom
sword_and_board
tooth_and_claw
white_tiger
rkm128)
prunetex "${TEXTURES_NOT_FOR_TBC[@]}"

zipproject tbc "$VERSION_TOC_VERSION"

cdup
}

# Release vanilla version
release_vanilla() {
VANILLA_BUILD_VERSION=11508
mkproject vanilla $VANILLA_BUILD_VERSION ffffff inv_misc_food_31 32 "Classic Era and Season of Discovery"

VARIABLES_NOT_FOR_VANILLA=(holypower nativesao)
prunevar "${VARIABLES_NOT_FOR_VANILLA[@]}"

CLASSES_NOT_FOR_VANILLA=(deathknight monk)
pruneclass "${CLASSES_NOT_FOR_VANILLA[@]}"

TEXTURES_NOT_FOR_VANILLA=(
art_of_war
backlash
daybreak
fury_of_stormrage_yellow
master_marksman
molten_core
killing_machine
predatory_swiftness
rime
shadow_word_insanity
shooting_stars
sudden_doom
thrill_of_the_hunt_1
thrill_of_the_hunt_2
thrill_of_the_hunt_3
rkm128)
prunetex "${TEXTURES_NOT_FOR_VANILLA[@]}"

zipproject vanilla "$VERSION_TOC_VERSION"

cdup
}

# Release cata version
release_cata() {
CATA_BUILD_VERSION=40402
mkproject cata $CATA_BUILD_VERSION db550d achievment_boss_madnessofdeathwing 64 "Cataclysm"

prunecopyright Cataclysm

CLASSES_NOT_FOR_CATA=(monk)
pruneclass "${CLASSES_NOT_FOR_CATA[@]}"

TEXTURES_NOT_FOR_CATA=(
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
fulmination
fury_of_stormrage_yellow
maelstrom_weapon_6
maelstrom_weapon_7
maelstrom_weapon_8
maelstrom_weapon_9
maelstrom_weapon_10
monk_serpent
raging_blow
thrill_of_the_hunt_1
thrill_of_the_hunt_2
thrill_of_the_hunt_3
tooth_and_claw
white_tiger
$(texbelow 511469 450914 450915)
rkm128)
prunetex "${TEXTURES_NOT_FOR_CATA[@]}"

SOUNDS_NOT_FOR_CATA=(UI_PowerAura_Generic)
prunesound "${SOUNDS_NOT_FOR_CATA[@]}"

zipproject cata "$VERSION_TOC_VERSION"

cdup
}

# Release mop version
release_mop() {
MOP_BUILD_VERSION=50503
mkproject mop $MOP_BUILD_VERSION 00ff96 achievement_character_pandaren_female 64 "Mists of Pandaria"

prunecopyright Cataclysm Pandaria

TEXTURES_NOT_FOR_MOP=(
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
echo_of_the_elements
maelstrom_weapon_6
maelstrom_weapon_7
maelstrom_weapon_8
maelstrom_weapon_9
maelstrom_weapon_10
raging_blow
$(texbelow 898423 450914 450915)
)
prunetex "${TEXTURES_NOT_FOR_MOP[@]}"

SOUNDS_NOT_FOR_MOP=(UI_PowerAura_Generic)
prunesound "${SOUNDS_NOT_FOR_MOP[@]}"

zipproject mop "$VERSION_TOC_VERSION"

cdup
}

# Release Necrosis version
release_necrosis() {
NECROSIS_BUILD_VERSION=40402 # Version does not matter, toc will not be used
mkproject necrosis $NECROSIS_BUILD_VERSION 8787ed spell_shadow_abominationexplosion 64 "Necrosis"

CLASSES_NOT_FOR_NECROSIS=(
deathknight
druid
hunter
mage
monk
paladin
priest
rogue
shaman
warrior)
pruneclass "${CLASSES_NOT_FOR_NECROSIS[@]}"

TEXTURES_NOT_FOR_NECROSIS=(
arcane_missiles
arcane_missiles_1
arcane_missiles_2
arcane_missiles_3
art_of_war
bandits_guile
blood_surge
brain_freeze
daybreak
echo_of_the_elements
eclipse_moon
eclipse_sun
feral_omenofclarity
frozen_fingers
fulmination
fury_of_stormrage
fury_of_stormrage_yellow
genericarc_02
genericarc_05
high_tide
hot_streak
impact
killing_machine
lock_and_load
maelstrom_weapon
maelstrom_weapon_1
maelstrom_weapon_2
maelstrom_weapon_3
maelstrom_weapon_4
maelstrom_weapon_6
maelstrom_weapon_7
maelstrom_weapon_8
maelstrom_weapon_9
maelstrom_weapon_10
master_marksman
monk_serpent
natures_grace
natures_grace
predatory_swiftness
raging_blow
rime
serendipity
shooting_stars
sudden_death
sudden_doom
surge_of_light
sword_and_board
thrill_of_the_hunt_1
thrill_of_the_hunt_2
thrill_of_the_hunt_3
tooth_and_claw
white_tiger
rkm128)
prunetex "${TEXTURES_NOT_FOR_NECROSIS[@]}"

dos2unix "*.lua" "*.xml"

toc2xml SpellActivationOverlay.toc SpellActivations.xml

# Add License at the beginning of main file
echo -n "Injecting License..."
{
    printf '%s\n' '--[[' > SpellActivationOverlay/NecrosisSpellActivation.lua &&
    cat SpellActivationOverlay/LICENSE >> SpellActivationOverlay/NecrosisSpellActivation.lua &&
    printf '\n%s\n' 'Credits to Blizzard Entertainment for writing original code of Spell Activation Overlay' >> SpellActivationOverlay/NecrosisSpellActivation.lua &&
    printf '%s\n' '--]]' >> SpellActivationOverlay/NecrosisSpellActivation.lua &&
    cat SpellActivationOverlay/SpellActivationOverlay.lua >> SpellActivationOverlay/NecrosisSpellActivation.lua &&
    rm SpellActivationOverlay/SpellActivationOverlay.lua SpellActivationOverlay/LICENSE
} || bye "Cannot craft main Lua file"
echo

mv SpellActivationOverlay/SpellActivationOverlay.xml SpellActivationOverlay/NecrosisSpellActivation.xml || bye "Cannot rename files"
rm SpellActivationOverlay/changelog.md || bye "Cannot remove unused files"

# Saved Variables
replacecode SpellActivationOverlayDB NecrosisConfig "*.lua" "*.xml"
# UI Elements
# replacecode DISPLAY_LABEL "Spell OVERLAY" "InterfaceOptionsPanels.xml"
# Global variable and widget names
replacecode 'SpellActivationOverlay\.lua' 'NecrosisSpellActivation\.lua' "*.xml"
replacecode 'SpellActivationOverlay\.xml' 'NecrosisSpellActivation\.xml' "*.xml"
replacecode SpellActivationOverlay NecrosisSpellActivationOverlay "*.lua" "*.xml"
# File locations; must be replaced after global rename of SpellActivationOverlay
replacecode 'Add[oO]ns/NecrosisSpellActivationOverlay' 'AddOns/Necrosis/SpellActivations' "*.lua" "*.xml"
replacecode 'Add[oO]ns\\\\NecrosisSpellActivationOverlay' 'AddOns\\\\Necrosis\\\\SpellActivations' "*.lua" "*.xml"
# # File locations
# replacecode 'Add[oO]ns/SpellActivationOverlay' 'AddOns/Necrosis/SpellActivations' "*.lua" "*.xml"
# replacecode 'Add[oO]ns\\\\SpellActivationOverlay' 'AddOns\\\\Necrosis\\\\SpellActivations' "*.lua" "*.xml"

zipproject necrosis "$VERSION_TOC_VERSION"

cdup
}

# Release universal version
release_universal() {
UNIVERSAL_BUILD_VERSION=50500 # Same as latest Classic version, currently Mists of Pandaria Classic
mkproject universal $UNIVERSAL_BUILD_VERSION c845fa spell_arcane_portalstormwind 32 "Universal"

echo -n "Generatic TOC files for each flavor..."
PROJECTS=(
"vanilla Vanilla"
# "tbc TBC"
"wrath Wrath"
"cata Cata"
"mop Mists"
)
addon_name=SpellActivationOverlay
for project in "${PROJECTS[@]}"; do
    read flavor suffix <<< "$project"
    build_version=$(grep -i '^##[[:space:]]*interface:' "../${flavor}/${addon_name}/${addon_name}.toc" | grep -o '[0-9].*[^[:space:]]')
    [ -z "$build_version" ] && bye "Cannot read Interface version from '$flavor'"
    cp "./${addon_name}/${addon_name}.toc" "./${addon_name}/${addon_name}_${suffix}.toc" || bye "Cannot generate TOC file for '$flavor'"
    sed -i s/'^## Interface:.*'/"## Interface: $build_version"/ "./${addon_name}/${addon_name}_${suffix}.toc" || bye "Cannot update version of $flavor TOC file"
done
echo

zipproject universal "$VERSION_TOC_VERSION"

cdup
}

mkbaseproject
release_vanilla
release_tbc
release_wrath
release_cata
release_mop
release_universal
release_necrosis
