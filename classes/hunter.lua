local AddonName, SAO = ...

local aimedShot = 19434;
local arcaneShot = 3044;
local chimeraShot = 53209;
local counterattack = 19306;
local explosiveShot = 53301;
local killShot = 53351;
local mongooseBite = 1495;

local function useKillShot()
    if SAO.IsWrath() or SAO.IsCata() then
        SAO:RegisterAura("kill_shot", 0, killShot, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(killShot)) });
        SAO:RegisterCounter("kill_shot");
    end
end

local function useCounterattack()
    SAO:RegisterAura("counterattack", 0, counterattack, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(counterattack)) });
    SAO:RegisterCounter("counterattack"); -- Must match name from above call
end

local function useMongooseBite()
    if SAO.IsEra() or SAO.IsTBC() then
        -- Mongoose Bite, before Wrath because there is no longer a proc since Wrath
        local mongooseBite = 1495;
        SAO:RegisterAura("mongoose_bite", 0, mongooseBite, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(mongooseBite)) });
        SAO:RegisterCounter("mongoose_bite");
    end
end

local function useImprovedSteadyShot()
    local issGlowNames = { (GetSpellInfo(aimedShot)), (GetSpellInfo(arcaneShot)), (GetSpellInfo(chimeraShot)) };
    if SAO.IsWrath() or SAO.IsCata() then
        -- Improved Steady Shot, formerly Master Marksman
        SAO:RegisterAura("improved_steady_shot", 0, 53220, "master_marksman", "Top", 1, 255, 255, 255, true, issGlowNames);
    end
end

local function useFlankingStrike()
    if SAO.IsSoD() then
        local flankingStrike = 415320;
        SAO:RegisterAura("flanking_strike", 0, flankingStrike, "tooth_and_claw", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flankingStrike }, true);
        SAO:RegisterCounter("flanking_strike");
    end
end

local function useCobraStrikes()
    if SAO.IsSoD() then
        local cobraStrikes = 425714;
        SAO:RegisterAura("cobra_strikes_1", 1, cobraStrikes, "monk_serpent", "Left", 0.7, 255, 255, 255, true);
        SAO:RegisterAura("cobra_strikes_2", 2, cobraStrikes, "monk_serpent", "Left + Right (Flipped)", 0.7, 255, 255, 255, true);
    end
end

local function useLockAndLoad()
    local lalGlowNames = { (GetSpellInfo(arcaneShot)), (GetSpellInfo(explosiveShot)) };
    if SAO.IsWrath() or SAO.IsCata() then
        SAO:RegisterAura("lock_and_load_1", 1, 56453, "lock_and_load", "Top", 1, 255, 255, 255, true, lalGlowNames);
        SAO:RegisterAura("lock_and_load_2", 2, 56453, "lock_and_load", "Top", 1, 255, 255, 255, true, lalGlowNames);
    end
    if SAO.IsSoD() then
        -- Unlike Wrath, we do not suggest to glow buttons, because there are too many (all 'shots')
        SAO:RegisterAura("lock_and_load", 0, 415414, "lock_and_load", "Top", 1, 255, 255, 255, true);
    end
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
    local improvedSteadyShotBuff = 53220;
    local improvedSteadyShotTalent = 53221;

    local lockAndLoadBuff = 56453;
    local lockAndLoadTalent = 56342;
    local lockAndLoadBuffSoD = 415414;
    local lockAndLoadTalentSoD = 415413;

    local flankingStrike = 415320;
    local cobraStrikes = 425714;
    -- local sniperTrainingBuff = 415401;
    -- local sniperTrainingRune = 415399;

    if self.IsWrath() or self.IsCata() then
        self:AddOverlayOption(improvedSteadyShotTalent, improvedSteadyShotBuff);
        self:AddOverlayOption(lockAndLoadTalent, lockAndLoadBuff, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
    end
    if self.IsSoD() then
        self:AddOverlayOption(flankingStrike, flankingStrike);
        self:AddOverlayOption(cobraStrikes, cobraStrikes, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddOverlayOption(lockAndLoadTalentSoD, lockAndLoadBuffSoD);
    end

    if self.IsWrath() or self.IsCata() then
        self:AddGlowingOption(nil, killShot, killShot);
    end
    self:AddGlowingOption(nil, counterattack, counterattack);
    if self.IsEra() or self.IsTBC() then
        self:AddGlowingOption(nil, mongooseBite, mongooseBite);
    end
    if self.IsSoD() then
        self:AddGlowingOption(nil, flankingStrike, flankingStrike);
        -- self:AddGlowingOption(sniperTrainingRune, sniperTrainingBuff, aimedShot, self:NbStacks(5));
    end
    if self.IsWrath() or self.IsCata() then
        self:AddGlowingOption(improvedSteadyShotTalent, improvedSteadyShotBuff, aimedShot);
        self:AddGlowingOption(improvedSteadyShotTalent, improvedSteadyShotBuff, arcaneShot);
        self:AddGlowingOption(improvedSteadyShotTalent, improvedSteadyShotBuff, chimeraShot);
        self:AddGlowingOption(lockAndLoadTalent, lockAndLoadBuff, arcaneShot);
        self:AddGlowingOption(lockAndLoadTalent, lockAndLoadBuff, explosiveShot);
    end
end

SAO.Class["HUNTER"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
