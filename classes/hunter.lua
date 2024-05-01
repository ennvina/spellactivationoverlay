local AddonName, SAO = ...

local function registerClass(self)
    local aimedShot = 19434;
    local arcaneShot = 3044;
    local killShot  = 53351;
    local chimeraShot = 53209;
    local explosiveShot = 53301;
    local counterattack = 19306;

    local issGlowNames = { (GetSpellInfo(aimedShot)), (GetSpellInfo(arcaneShot)), (GetSpellInfo(chimeraShot)) };
    local lalGlowNames = { (GetSpellInfo(arcaneShot)), (GetSpellInfo(explosiveShot)) };

    if self.IsWrath() or self.IsCata() then
        -- Improved Steady Shot, formerly Master Marksman
        self:RegisterAura("improved_steady_shot", 0, 53220, "master_marksman", "Top", 1, 255, 255, 255, true, issGlowNames);

        -- Lock and Load: display something on top if there is at least one charge
        self:RegisterAura("lock_and_load_1", 1, 56453, "lock_and_load", "Top", 1, 255, 255, 255, true, lalGlowNames);
        self:RegisterAura("lock_and_load_2", 2, 56453, "lock_and_load", "Top", 1, 255, 255, 255, true, lalGlowNames);

        -- Kill Shot, Execute-like ability for targets at 20% hp or less
        self:RegisterAura("kill_shot", 0, killShot, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(killShot)) });
        self:RegisterCounter("kill_shot");
    end

    -- Counterattack, registered as both aura and counter, but only used as counter
    self:RegisterAura("counterattack", 0, counterattack, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(counterattack)) });
    self:RegisterCounter("counterattack"); -- Must match name from above call

    if self.IsEra() or self.IsTBC() then
        -- Mongoose Bite, before Wrath because there is no longer a proc since Wrath
        local mongooseBite = 1495;
        self:RegisterAura("mongoose_bite", 0, mongooseBite, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(mongooseBite)) });
        self:RegisterCounter("mongoose_bite");
    end

    if self.IsSoD() then
        -- Flanking Strike (Season of Discovery)
        local flankingStrike = 415320;
        self:RegisterAura("flanking_strike", 0, flankingStrike, "tooth_and_claw", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flankingStrike }, true);
        self:RegisterCounter("flanking_strike");

        -- Cobra Strikes (Season of Discovery)
        local cobraStrikes = 425714;
        self:RegisterAura("cobra_strikes_1", 1, cobraStrikes, "monk_serpent", "Left", 0.7, 255, 255, 255, true);
        self:RegisterAura("cobra_strikes_2", 2, cobraStrikes, "monk_serpent", "Left + Right (Flipped)", 0.7, 255, 255, 255, true);

        -- Lock and Load (Season of Discovery)
        -- Unlike Wrath, we do not suggest to glow buttons, because there are too many (all 'shots')
        self:RegisterAura("lock_and_load", 0, 415414, "lock_and_load", "Top", 1, 255, 255, 255, true);

        -- Sniper Training, 5 stacks only (Season of Discovery)
        -- self:RegisterAura("sniper_training", 5, 415401, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(aimedShot)) }, true);
    end
end

local function loadOptions(self)
    local mongooseBite = 1495;
    local killShot = 53351;
    local counterattack = 19306;
    local aimedShot = 19434;
    local arcaneShot = 3044;
    local chimeraShot = 53209;
    local explosiveShot = 53301;

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
