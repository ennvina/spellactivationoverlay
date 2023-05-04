local AddonName, SAO = ...

-- Optimize frequent calls
local GetTalentTabInfo = GetTalentTabInfo
local UnitCanAttack = UnitCanAttack
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

--[[
    DrainSoulHandler evaluates when the Drain Soul button should glow
    because the target has 25% health or less. Only in Wrath Classic.

    The following conditions must be met:
    - the current target can be attacked
    - the current target has 25% or less than 25% health

    This stops if either:
    - the target cannot be attacked
    - the target is healed over 25% health
]]
local DrainSoulHandler = {

    initialized = false,

    -- Methods

    checkOption = function(option)
        if option == "spec:1/2/3" then
            -- Always glow if 'all specs' option is chosen
            return true;
        elseif option == "spec:1" then
            -- If 'affliction only' option is chosen, check if Affliction is the majority spec
            local afflictionPoints = select(3, GetTalentTabInfo(1));
            local demonologyPoints = select(3, GetTalentTabInfo(2));
            local destructionPoints = select(3, GetTalentTabInfo(3));
            return afflictionPoints > demonologyPoints and afflictionPoints > destructionPoints;
        end
        return false;
    end,

    init = function(self, id, name)
        SAO.GlowInterface:bind(self);
        self:initVars(id, name, false, nil, {
            SAO:SpecVariantValue({ 1 }),
            SAO:SpecVariantValue({ 1, 2, 3 }),
        }, self.checkOption);
        self.initialized = true;
    end,

    checkTargetHealth = function(self)
        local canExecute = false;

        if UnitCanAttack("player", "target") then
            local hp = UnitHealth("target");
            local hpMax = UnitHealthMax("target");
            canExecute = hp > 0 and hp/hpMax <= 0.25;
        end

        if canExecute and not self.glowing then
            self:glow();
        elseif not canExecute and self.glowing then
            self:unglow();
        end
    end,
}

local function customLogin(self, ...)
    if WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC then
        -- Drain Soul is empowered on low health enemies only in Wrath Classic
        local spellID = 1120;
        local spellName = GetSpellInfo(spellID);
        if (spellName) then
            -- Must register glowing buttons manually, because Drain Soul is not registered by an aura/counter/etc.
            self:RegisterGlowIDs({ spellName });
            local allSpellIDs = self:GetSpellIDsByName(spellName);
            for _, oneSpellID in ipairs(allSpellIDs) do
                self:AwakeButtonsBySpellID(oneSpellID);
            end
            -- Initialize handler
            DrainSoulHandler:init(spellID, spellName);
        end
    end
end

local function retarget(self, ...)
    if DrainSoulHandler.initialized then
        DrainSoulHandler:checkTargetHealth();
    end
end

local function unitHealth(self, unitID)
    if DrainSoulHandler.initialized and unitID == "target" then
        DrainSoulHandler:checkTargetHealth();
    end
end

local function registerMolenCore(self, baseName, spellID, glowIDs)
    self:RegisterAura(baseName.."_1", 1, spellID, "molten_core", "Left", 1, 255, 255, 255, true, glowIDs);
    self:RegisterAura(baseName.."_2", 2, spellID, "molten_core", "Left + Right (Flipped)", 1, 255, 255, 255, true, glowIDs);
    self:RegisterAura(baseName.."_3", 3, spellID, "molten_core", "Left + Right (Flipped)", 1, 255, 255, 255, true, glowIDs); -- Same as 2 charges
end

local function registerClass(self)
    local shadowBolt = GetSpellInfo(686);
    local incinerate = GetSpellInfo(29722);
    local soulFire = GetSpellInfo(6353);
    local incinerateAndSoulFire = { incinerate, soulFire };

    local moltenCoreBuff1 = 47383;
    local moltenCoreBuff2 = 71162;
    local moltenCoreBuff3 = 71165;

    local decimationBuff1 = 63165;
    local decimationBuff2 = 63167;

    -- Add option links during registerClass(), not because loadOptions() which would be loaded only when the options panel is opened
    -- Add option links before RegisterAura() calls, so that options they are used by initial triggers, if any
    self:AddOverlayLink(moltenCoreBuff3, moltenCoreBuff1);
    self:AddOverlayLink(moltenCoreBuff3, moltenCoreBuff2);
    self:AddOverlayLink(decimationBuff2, decimationBuff1);
    self:AddGlowingLink(moltenCoreBuff3, moltenCoreBuff1);
    self:AddGlowingLink(moltenCoreBuff3, moltenCoreBuff2);
    self:AddGlowingLink(decimationBuff2, decimationBuff1);

    -- Backlash
    self:RegisterAura("backlash", 0, 34936, "backlash", "Top", 1, 255, 255, 255, true, { shadowBolt, incinerate });

    -- Empowered Imp
    self:RegisterAura("empowered_imp", 0, 47283, "imp_empowerment", "Left + Right (Flipped)", 1, 255, 255, 255, true);

    -- Molten Core
    registerMolenCore(self, "molten_core_low", moltenCoreBuff1, incinerateAndSoulFire); -- 1/3 talent point
    registerMolenCore(self, "molten_core_medium", moltenCoreBuff2, incinerateAndSoulFire); -- 2/3 talent points
    registerMolenCore(self, "molten_core_high", moltenCoreBuff3, incinerateAndSoulFire); -- 3/3 talent points

    -- Decimation
    self:RegisterAura("decimation_low", 0, decimationBuff1, "impact", "Top", 0.8, 255, 255, 255, true, { soulFire }); -- 1/2 talent point
    self:RegisterAura("decimation_high", 0, decimationBuff2, "impact", "Top", 0.8, 255, 255, 255, true, { soulFire }); -- 2/2 talent point

    -- Nightfall / Shadow Trance
    self:RegisterAura("nightfall", 0, 17941, "nightfall", "Left + Right (Flipped)", 1, 255, 255, 255, true, { shadowBolt });
end

local function loadOptions(self)
    local shadowBolt = 686;
    local incinerate = 29722;
    local soulFire = 6353;
    local drainSoul = 1120;

    local nightfallBuff = 17941;
    local nightfallTalent = 18094;

    local backlashBuff = 34936;
    local backlashTalent = 34935;

    local empoweredImpBuff = 47283;
    local empoweredImpTalent = 47220;

    local moltenCoreBuff3 = 71165;
    local moltenCoreTalent = 47245;

    local decimationBuff2 = 63167;
    local decimationTalent = 63156;

--    local akaShadowTrance = GetSpellInfo(nightfallBuff);

    self:AddOverlayOption(nightfallTalent, nightfallBuff --[[, 0, akaShadowTrance]]);
    self:AddOverlayOption(backlashTalent, backlashBuff);
    self:AddOverlayOption(moltenCoreTalent, moltenCoreBuff3, 0, nil, nil, 3); -- setup any stacks, test with 3 stacks
    self:AddOverlayOption(decimationTalent, decimationBuff2);
    self:AddOverlayOption(empoweredImpTalent, empoweredImpBuff);

    if DrainSoulHandler.initialized then
        self:AddGlowingOption(nil, DrainSoulHandler.optionID, drainSoul, nil, string.format(string.format(HEALTH_COST_PCT, "<%s%"), 25), DrainSoulHandler.variants);
    end
    self:AddGlowingOption(nightfallTalent, nightfallBuff, shadowBolt --[[, akaShadowTrance]]);
    self:AddGlowingOption(backlashTalent, backlashBuff, shadowBolt);
    self:AddGlowingOption(backlashTalent, backlashBuff, incinerate);
    self:AddGlowingOption(moltenCoreTalent, moltenCoreBuff3, incinerate);
    self:AddGlowingOption(moltenCoreTalent, moltenCoreBuff3, soulFire);
    self:AddGlowingOption(decimationTalent, decimationBuff2, soulFire);
    -- self:AddGlowingOption(empoweredImpTalent, empoweredImpBuff, ...); -- Maybe add spell options for Empowered Imp
end

SAO.Class["WARLOCK"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["PLAYER_LOGIN"] = customLogin,
    ["PLAYER_TARGET_CHANGED"] = retarget,
    ["UNIT_HEALTH"] = unitHealth,
}
