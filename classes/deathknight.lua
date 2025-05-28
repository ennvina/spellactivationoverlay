local AddonName, SAO = ...

local DK_SPEC_BLOOD = -1;
local DK_SPEC_FROST = -2;
local DK_SPEC_UNHOLY = -4;

local bloodBoil = 48721;
local boneShield = 49222;
local darkTransformation = 63560;
local deathCoil = 47541;
local deathStrike = 49998;
local frostStrike = 49143;
local howlingBlast = 49184;
local icyTouch = 45477;
local obliterate = 49020;
local runeStrike = 56815;
local runeTap = 48982;

local function useRuneStrike()
    SAO:CreateEffect(
        "rune_strike",
        SAO.WRATH,
        runeStrike, -- Rune Strike (ability)
        "counter",
        { useName = false }
    );
end

local function useBoneShield()
    local boneShieldTalent = SAO.IsMoP() and DK_SPEC_BLOOD or boneShield;

    SAO:CreateEffect(
        "bone_shield",
        SAO.CATA + SAO.MOP,
        boneShield,
        "aura",
        {
            talent = boneShieldTalent,
            requireTalent = true,
            actionUsable = true,
            combatOnly = true,
            button = { stacks = -1, spellID = boneShield },
        }
    );
end

local function useRime()
    local rimeTalent = SAO.IsMoP() and 59057 or 49188;

    SAO:CreateEffect(
        "rime",
        SAO.WRATH + SAO.CATA + SAO.MOP,
        59052, -- Freezing Fog (buff)
        "aura",
        {
            talent = rimeTalent,
            overlay = { texture = "rime", position = "Top" },
            buttons = {
                [SAO.WRATH] = howlingBlast,
                [SAO.CATA] = { howlingBlast, icyTouch },
                -- [SAO.MOP] = { howlingBlast, icyTouch }, -- Buttons already glowing natively
            },
        }
    );
end

local function useKillingMachine()
    local killinsMachineTalent = SAO.IsMoP() and 51128 or 51123;

    SAO:CreateEffect(
        "killing_machine",
        SAO.WRATH + SAO.CATA + SAO.MOP,
        51124, -- Killing Machine (buff)
        "aura",
        {
            talent = killinsMachineTalent,
            overlay = { texture = "killing_machine", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.WRATH] = { icyTouch, frostStrike, howlingBlast },
                [SAO.CATA] = { frostStrike, obliterate },
                -- [SAO.MOP] = { frostStrike, obliterate }, -- Buttons already glowing natively
            },
        }
    );
end

local function useCrimsonScourge()
    local crimsonScourgeTalent = SAO.IsMoP() and 81136 or 81135;

    SAO:CreateEffect(
        "crimson_scourge",
        SAO.CATA + SAO.MOP,
        81141, -- Crimson Scourge (buff)
        "aura",
        {
            talent = crimsonScourgeTalent,
            overlay = { texture = "blood_boil", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.CATA] = bloodBoil,
                -- [SAO.MOP] = bloodBoil, -- Button already glowing natively
            },
        }
    );
end

local function useDarkTransformation()
    SAO:CreateEffect(
        "dark_transformation",
        SAO.CATA + SAO.MOP,
        93426, -- Dark Transformation proc for Native SHOW event
        "native",
        {
            overlay = { texture = "dark_transformation", position = "Top" },
            buttons = {
                [SAO.CATA] = darkTransformation,
                -- [SAO.MOP] = darkTransformation, -- Button already glowing natively
            }
        }
    );
end

local function useSuddenDoom()
    local suddenDoomTalent = SAO.IsMoP() and 49530 or 81340;

    SAO:CreateEffect(
        "sudden_doom",
        SAO.CATA + SAO.MOP,
        81340, -- Sudden Doom (buff)
        "aura",
        {
            talent = suddenDoomTalent,
            overlay = { texture = "sudden_doom", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.CATA] = deathCoil,
                -- [SAO.MOP] = deathCoil, -- Button already glowing natively
            },
        }
    );
end

local function useWotn()
    local wotnTalent = SAO.IsMoP() and 81164 or 52284;

    SAO:CreateEffect(
        "wotn",
        SAO.CATA + SAO.MOP,
        96171, -- Will of the Necropolis (buff)
        "aura",
        {
            talent = wotnTalent,
            overlay = { texture = "necropolis", position = "Top" },
            buttons = {
                [SAO.CATA] = runeTap,
                -- [SAO.MOP] = runeTap, -- Button already glowing natively
            },
        }
    );
end

local function useDarkSuccor()
    SAO:CreateEffect(
        "dark_succor",
        SAO.MOP,
        101568, -- Dark Succor (buff)
        "aura",
        {
            button = deathStrike,
        }
    );
end

local function registerClass(self)
    -- Counters
    useRuneStrike();

    -- Blood
    useBoneShield();
    useWotn();
    useCrimsonScourge();

    -- Frost
    useRime();
    useKillingMachine();

    -- Unholy
    useDarkTransformation();
    useSuddenDoom();

    -- Glyphs
    useDarkSuccor();
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerClass,
}
