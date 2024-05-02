local AddonName, SAO = ...

local aimedShot = 19434;
local arcaneShot = 3044;
local chimeraShot = 53209;
local counterattack = 19306;
local explosiveShot = 53301;
local killShot = 53351;
local mongooseBite = 1495;

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
        SAO.ALL_PROJECTS,
        counterattack,
        "counter"
    );
end

local function useMongooseBite()
    SAO:CreateEffect(
        "mongoose_bite",
        SAO.ERA + SAO.TBC,
        mongooseBite,
        "counter"
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

local function useFlankingStrike()
    if SAO.IsSoD() then
        local flankingStrike = 415320;
        SAO:RegisterAura("flanking_strike", 0, flankingStrike, "tooth_and_claw", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flankingStrike }, true);
        SAO:RegisterCounter("flanking_strike");
    end
end

local function useCobraStrikes()
    local cobraStrikes = 425714;
    SAO:CreateEffect(
        "cobra_strikes",
        SAO.SOD,
        cobraStrikes,
        "aura",
        {
            overlays = {
                { stacks = 1, texture = "monk_serpent", position = "Left", scale = 0.7, option = false },
                { stacks = 2, texture = "monk_serpent", position = "Left + Right (Flipped)", scale = 0.7, option = { setupStacks = 0, testStacks = 2 } },
            },
        }
    );
end

local function useLockAndLoad()
    local lockAndLoadBuff = SAO.IsSoD() and 415414 or 56453;
    local lockAndLoadTalent = SAO.IsSoD() and 415413 or 56342;
    SAO:CreateEffect(
        "lock_and_load",
        SAO.SOD + SAO.WRATH + SAO.CATA,
        lockAndLoadBuff,
        "aura",
        {
            talent = lockAndLoadTalent,
            overlays = {
                [SAO.SOD] = { texture = "lock_and_load", position = "Top" },
                [SAO.WRATH+SAO.CATA] = {
                    { stacks = 1, texture = "lock_and_load", position = "Top", option = false },
                    { stacks = 2, texture = "lock_and_load", position = "Top", option = { setupStacks = 0, testStacks = 2 } },
                },
            },
            buttons = {
                [SAO.SOD] = nil, -- Don't glow buttons for Season of Discovery, there would be too many to suggest
                [SAO.WRATH] = { arcaneShot, explosiveShot },
                [SAO.CATA] = explosiveShot,
            },
        }
    );
end

local function registerClass(self)

    -- Kill Shot, Execute-like ability for targets at 20% hp or less
    useKillShot();

    -- Counterattack, registered as both aura and counter, but only used as counter
    useCounterattack();

    -- Mongoose Bite, before Wrath because there is no longer a proc since Wrath
    useMongooseBite();

    -- Improved Steady Shot, formerly Master Marksman
    useImprovedSteadyShot();

    -- Flanking Strike (Season of Discovery)
    useFlankingStrike();

    -- Cobra Strikes (Season of Discovery)
    useCobraStrikes();

    -- Lock and Load: display something on top if there is at least one charge
    useLockAndLoad();

    -- Sniper Training, 5 stacks only (Season of Discovery)
    -- SAO:RegisterAura("sniper_training", 5, 415401, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(aimedShot)) }, true);
end

local function loadOptions(self)
    local flankingStrike = 415320;
    -- local sniperTrainingBuff = 415401;
    -- local sniperTrainingRune = 415399;

    if self.IsSoD() then
        self:AddOverlayOption(flankingStrike, flankingStrike);
    end

    if self.IsSoD() then
        self:AddGlowingOption(nil, flankingStrike, flankingStrike);
        -- self:AddGlowingOption(sniperTrainingRune, sniperTrainingBuff, aimedShot, self:NbStacks(5));
    end
end

SAO.Class["HUNTER"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
