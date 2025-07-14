local AddonName, SAO = ...

local aimedShot = 19434;
local aimedShotBang = 82928;
local arcaneShot = 3044;
local chimeraShot = 53209;
local concussiveShot = 5116;
local counterattack = 19306;
local distractingShot = 20736;
local explosiveShot = 53301;
local flankingStrike = 415320;
local killCommand = 34026;
local killShot = 53351;
local mongooseBite = 1495;
local multiShot = 2643;
local scatterShot = 19503;
local thrillOfTheHunt = 34498;
local tranquilizingShot = 19801;

local function useKillShot()
    SAO:CreateEffect(
        "kill_shot",
        SAO.WRATH + SAO.CATA,
        killShot,
        "counter"
    );
end

local function useCounterattack()
    SAO:CreateEffect(
        "counterattack",
        SAO.ALL_PROJECTS - SAO.MOP_AND_ONWARD,
        counterattack,
        "counter"
    );
end

local function useMongooseBite()
    SAO:CreateEffect(
        "mongoose_bite",
        SAO.ERA + SAO.TBC,
        mongooseBite,
        "counter",
        {
            useName = false,
            combatOnly = true,
            overlay = { texture = "bandits_guile", position = "Top (CW)", scale = 1.1 },
        }
    );
end

local function useKillingStreak()
    local killingStreakBuff1 = 94006;
    local killingStreakBuff2 = 94007;
    local killingStreakTalent = 82748;

    SAO:CreateLinkedEffects(
        "killing_streak",
        SAO.CATA,
        { killingStreakBuff1, killingStreakBuff2 },
        "aura",
        {
            talent = killingStreakTalent,
            button = killCommand,
        }
    );
end

local function useFocusFire()
    SAO:CreateEffect(
        "focus_fire",
        SAO.MOP,
        19615, -- Frenzy (buff)
        "aura",
        {
            aka = 88843, -- Focus Fire! (placeholder spell for the overlay)
            talent = 82692, -- Focus Fire (ability)
            overlay = { stacks = 5, texture = "focus_fire", position = "Left + Right (Flipped)" },
            -- button = focusFire, -- Button already glowing natively
        }
    );
end

local function useImprovedSteadyShot()
    local improvedSteadyShotBuff = 53220;
    local improvedSteadyShotTalent = 53221;
    SAO:CreateEffect(
        "improved_steady_shot",
        SAO.WRATH,
        improvedSteadyShotBuff,
        "aura",
        {
            talent = improvedSteadyShotTalent,
            overlay = { texture = "master_marksman", position = "Top" },
            buttons = { aimedShot, arcaneShot, chimeraShot },
        }
    );
end

local function useMasterMarksman()
    -- local masterMarksmanBuff1to4 = 82925;
    local masterMarksmanBuff5 = 82926;

    SAO:CreateEffect(
        "master_marksman",
        SAO.CATA_AND_ONWARD,
        masterMarksmanBuff5, -- Fire! (buff)
        "aura",
        {
            talent = {
                [SAO.CATA] = 34485, -- Master Marksman (talent)
                [SAO.MOP_AND_ONWARD] = 34487, -- Master Marksman (passive)
            },
            overlay = { texture = "master_marksman", position = "Top" },
            buttons = {
                [SAO.CATA] = aimedShotBang,
                -- [SAO.MOP] = aimedShot, -- Button already glowing natively
            }
        }
    );
end

local function useLockAndLoad()
    SAO:CreateEffect(
        "lock_and_load",
        SAO.SOD + SAO.WRATH_AND_ONWARD,
        {
            [SAO.SOD] = 415414,
            [SAO.WRATH_AND_ONWARD] = 56453,
        },
        "aura",
        {
            talent = {
                [SAO.SOD] = 415413, -- Lock and Load (rune)
                [SAO.WRATH + SAO.CATA] = 56342, -- Lock and Load (talent)
                [SAO.MOP_AND_ONWARD] = 56343, -- Lock and Load (passive)
            },
            overlays = {
                [SAO.SOD] = { texture = "lock_and_load", position = "Top" },
                [SAO.WRATH_AND_ONWARD] = { -- Stacks == 1 is slightly dimmer, to give information that 'only 1 stack remains'
                    { stacks = 1, texture = "lock_and_load", position = "Top", color = { 200, 200, 200 }, pulse = false, option = false },
                    { stacks = 2, texture = "lock_and_load", position = "Top", color = { 255, 255, 255 }, pulse = true,  option = { setupHash = SAO:HashNameFromStacks(0), testHash = SAO:HashNameFromStacks(2) } },
                },
            },
            buttons = {
                [SAO.SOD] = nil, -- Don't glow buttons for Season of Discovery, there would be too many to suggest
                [SAO.WRATH] = { arcaneShot, explosiveShot },
                [SAO.CATA] = explosiveShot,
                -- [SAO.MOP_AND_ONWARD] = explosiveShot, -- Button already glowing natively
            },
        }
    );
end

local function useThrillOfTheHunt()
    SAO:CreateEffect(
        "thrill_of_the_hunt",
        SAO.MOP,
        34720, -- Thrill of the Hunt (buff)
        "aura",
        {
            talent = 109306, -- Thrill of the Hunt (talent)
            overlays = {
                { stacks = 1, texture = "thrill_of_the_hunt_1", position = "Left + Right (Flipped)", pulse = false, option = false },
                { stacks = 2, texture = "thrill_of_the_hunt_2", position = "Left + Right (Flipped)", pulse = false, option = false },
                { stacks = 3, texture = "thrill_of_the_hunt_3", position = "Left + Right (Flipped)", pulse = true , option = { setupHash = SAO:HashNameFromStacks(0), testHash = SAO:HashNameFromStacks(3) } },
            },
            -- buttons = { arcaneShot, multiShot }, -- Buttons already glowing natively
        }
    );
end

local function useFlankingStrike()
    SAO:CreateEffect(
        "flanking_strike",
        SAO.SOD,
        flankingStrike,
        "counter",
        {
            useName = false,
            combatOnly = true,
            overlay = { texture = "tooth_and_claw", position = "Left + Right (Flipped)" },
        }
    );
end

local function useCobraStrikes()
    local cobraStrikesBuff = 425714;
    local cobraStrikesTalent = 425713;
    SAO:CreateEffect(
        "cobra_strikes",
        SAO.SOD,
        cobraStrikesBuff,
        "aura",
        {
            talent = cobraStrikesTalent,
            overlays = {
                { stacks = 1, texture = "monk_serpent", position = "Left", scale = 0.7, option = false },
                { stacks = 2, texture = "monk_serpent", position = "Left + Right (Flipped)", scale = 0.7, option = { setupHash = SAO:HashNameFromStacks(0), testHash = SAO:HashNameFromStacks(2) } },
            },
        }
    );
end

local function useSniperTraining()
    local sniperTrainingBuff = 415401;
    local sniperTrainingRune = 415399;
    SAO:CreateEffect(
        "sniper_training",
        SAO.SOD,
        sniperTrainingBuff,
        "aura",
        {
            talent = sniperTrainingRune,
            combatOnly = true,
            button = {
                stacks = 5,
                spellID = aimedShot,
                useName = false,
            },
        }
    );
end

local function useBurningAdrenaline()
    local burningAdrenalineBuff = 99060;

    SAO:CreateEffect(
        "burning_adrenaline",
        SAO.CATA,
        burningAdrenalineBuff,
        "aura",
        {
            overlay = { texture = "genericarc_05", position = "Left + Right (Flipped)" },
--[[
    Do not add buttons for Burning Adrenaline, because there are too many of them:
    - action bars would light up like a Xmas tree
    - it adds a lot of bloat to the options panel

    It would be slightly better if we could enable each shot per spec
    But it's currently not possible, and not planned either

    Also, as a tier set, this effect will be probably forgotten in a few months
    Not to mention, the effect may just disappear for Mists of Pandaria Classic
]]
            -- buttons = {
            --     aimedShot,
            --     aimedShotBang,
            --     arcaneShot,
            --     chimeraShot,
            --     concussiveShot,
            --     distractingShot,
            --     explosiveShot,
            --     killCommand,
            --     multiShot,
            --     scatterShot,
            --     thrillOfTheHunt,
            --     tranquilizingShot,
            -- },
        }
    )
end

local function registerClass(self)

    -- Kill Shot, Execute-like ability for targets at 20% hp or less
    useKillShot();

    -- Counterattack, registered as both aura and counter, but only used as counter
    useCounterattack();

    -- Mongoose Bite, before Wrath because there is no longer a proc since Wrath
    useMongooseBite();

    -- Beast Mastery
    useKillingStreak();
    useFocusFire();

    -- Marksmanship
    useImprovedSteadyShot(); -- Improved Steady Shot, formerly Master Marksman
    useMasterMarksman(); -- Master Marksman, from Cataclysm

    -- Survival
    useLockAndLoad();

    -- Talents
    useThrillOfTheHunt();

    -- Season of Discovery runes
    useFlankingStrike();
    useCobraStrikes();
    -- useSniperTraining();

    -- Tier Sets
    useBurningAdrenaline(); -- T12 4pc
end

SAO.Class["HUNTER"] = {
    ["Register"] = registerClass,
}
