local AddonName, SAO = ...

-- Optimize frequent calls
local GetTalentTabInfo = GetTalentTabInfo
local UnitCanAttack = UnitCanAttack
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

local incinerate = 29722;
local shadowBolt = 686;
local soulFire = 6353;

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
            local selector = SAO.IsCata() and 5 or 3;
            local afflictionPoints = select(selector, GetTalentTabInfo(1));
            local demonologyPoints = select(selector, GetTalentTabInfo(2));
            local destructionPoints = select(selector, GetTalentTabInfo(3));
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
    if self.IsWrath() or self.IsCata() then
        -- Drain Soul is empowered on low health enemies only in Wrath Classic and Cataclysm Classic
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

local function registerMoltenCore(self, rank)
    local moltenCoreName = { "molten_core_low", "molten_core_medium", "molten_core_high" };
    local moltenCoreBuff = { 47383, 71162, 71165 };
    local overlayOption = (rank == 3) and { setupStacks = 0, testStacks = 3 };
    local buttonOption = rank == 3;

    self:CreateEffect(
        moltenCoreName[rank],
        SAO.WRATH + SAO.CATA,
        moltenCoreBuff[rank], -- Molten Core (buff) rank 1, 2 or 3
        "aura",
        {
            talent = 47245, -- Molten Core (talent)
            overlays = {
                { stacks = 1, texture = "molten_core", position = "Left", option = false },
                { stacks = 2, texture = "molten_core", position = "Left + Right (Flipped)", option = false },
                { stacks = 3, texture = "molten_core", position = "Left + Right (Flipped)", option = overlayOption }, -- Same visuals as 2 charges
            },
            buttons = {
                default = { option = buttonOption },
                [SAO.WRATH] = { incinerate, soulFire },
                [SAO.CATA] = { incinerate },
            },
        }
    );
end

local function registerDecimation(self, rank)
    local decimationName = { "decimation_low", "decimation_high" };
    local decimationBuff = { 63165, 63167 };

    self:CreateEffect(
        decimationName[rank],
        SAO.WRATH + SAO.CATA,
        decimationBuff[rank], -- Decimation (buff) rank 1 or 2
        "aura",
        {
            talent = 63156, -- Decimation (talent)
            overlay = { texture = "impact", position = "Top", scale = 0.8, option = (rank == 2) },
            button = { spellID = soulFire, option = (rank == 2) },
        }
    );
end

local function registerClass(self)

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
    self:CreateEffect(
        "backlash",
        SAO.TBC + SAO.WRATH + SAO.CATA,
        34936, -- Backlash (buff)
        "aura",
        {
            talent = 34935, -- Backlash (talent)
            overlay = { texture = "backlash", position = "Top" },
            buttons = { shadowBolt, incinerate },
        }
    );

    -- Empowered Imp
    self:RegisterAura("empowered_imp", 0, 47283, "imp_empowerment", "Left + Right (Flipped)", 1, 255, 255, 255, true);

    -- Molten Core
    if self.IsWrath() or self.IsCata() then
        registerMoltenCore(self, 1); -- 1/3 talent point
        registerMoltenCore(self, 2); -- 2/3 talent points
        registerMoltenCore(self, 3); -- 3/3 talent points
    end

    -- Decimation
    if self.IsWrath() or self.IsCata() then
        registerDecimation(self, 1); -- 1/2 talent point
        registerDecimation(self, 2); -- 2/2 talent points
    end

    -- Nightfall / Shadow Trance
    self:RegisterAura("nightfall", 0, 17941, "nightfall", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(shadowBolt)) });
end

local function loadOptions(self)
    local drainSoul = 1120;

    local nightfallBuff = 17941;
    local nightfallTalent = 18094;

    local empoweredImpBuff = 47283;
    local empoweredImpTalent = 47220;

--    local akaShadowTrance = GetSpellInfo(nightfallBuff);

    self:AddOverlayOption(nightfallTalent, nightfallBuff --[[, 0, akaShadowTrance]]);
    self:AddOverlayOption(empoweredImpTalent, empoweredImpBuff);

    if DrainSoulHandler.initialized then
        self:AddGlowingOption(nil, DrainSoulHandler.optionID, drainSoul, nil, string.format(string.format(HEALTH_COST_PCT, "<%s%"), 25), DrainSoulHandler.variants);
    end
    self:AddGlowingOption(nightfallTalent, nightfallBuff, shadowBolt --[[, akaShadowTrance]]);
    -- self:AddGlowingOption(empoweredImpTalent, empoweredImpBuff, ...); -- Maybe add spell options for Empowered Imp
end

SAO.Class["WARLOCK"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["PLAYER_LOGIN"] = customLogin,
    ["PLAYER_TARGET_CHANGED"] = retarget,
    ["UNIT_HEALTH"] = unitHealth,
}
