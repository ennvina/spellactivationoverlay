local AddonName, SAO = ...

local DK_SPEC_BLOOD = SAO.TALENT.SPEC_1;
local DK_SPEC_FROST = SAO.TALENT.SPEC_2;
local DK_SPEC_UNHOLY = SAO.TALENT.SPEC_3;

local DK_STANCE_BLOOD = 48263;
local DK_STANCE_FROST = 48266;
local DK_STANCE_UNHOLY = 48265;

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
    SAO:CreateEffect(
        "bone_shield",
        SAO.CATA + SAO.MOP,
        boneShield, -- Bone Shield (buff/ability; in this case, tracked as buff)
        "aura",
        {
            requireTalent = true,
            talent = {
                [SAO.CATA] = boneShield, -- Blood talent
                [SAO.MOP] = DK_SPEC_BLOOD, -- Blood spec
            },

            actionUsable = true,
            combatOnly = true,
            button = { stacks = -1, spellID = boneShield },
        }
    );
end

local function useRime()
    SAO:CreateEffect(
        "rime",
        SAO.WRATH + SAO.CATA + SAO.MOP,
        59052, -- Freezing Fog (buff)
        "aura",
        {
            talent = {
                [SAO.WRATH + SAO.CATA] = 49188, -- Frost talent
                [SAO.MOP] = 59057, -- Passive ability from Frost spec
            },
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
    SAO:CreateEffect(
        "killing_machine",
        SAO.WRATH + SAO.CATA + SAO.MOP,
        51124, -- Killing Machine (buff)
        "aura",
        {
            talent = {
                [SAO.WRATH + SAO.CATA] = 51123, -- Frost talent
                [SAO.MOP] = 51128, -- Passive ability from Frost spec
            },
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
    SAO:CreateEffect(
        "crimson_scourge",
        SAO.CATA + SAO.MOP,
        81141, -- Crimson Scourge (buff)
        "aura",
        {
            talent = {
                [SAO.CATA] = 81135, -- Blood Talent
                [SAO.MOP] = 81136, -- Passive ability from Blood spec
            },
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
    SAO:CreateEffect(
        "sudden_doom",
        SAO.CATA + SAO.MOP,
        81340, -- Sudden Doom (buff)
        "aura",
        {
            talent = {
                [SAO.CATA] = 81340, -- Unholy talent
                [SAO.MOP] = 49530, -- Passive ability from Unholy spec
            },
            overlay = { texture = "sudden_doom", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.CATA] = deathCoil,
                -- [SAO.MOP] = deathCoil, -- Button already glowing natively
            },
        }
    );
end

local function useWotn()
    SAO:CreateEffect(
        "wotn",
        SAO.CATA + SAO.MOP,
        96171, -- Will of the Necropolis (buff)
        "aura",
        {
            talent = {
                [SAO.CATA] = 52284, -- Blood talent
                [SAO.MOP] = 81164, -- Passive ability from Unholy spec
            },
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
            useStance = true,
            stances = { DK_STANCE_FROST, DK_STANCE_UNHOLY },

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
