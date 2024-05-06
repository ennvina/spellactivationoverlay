local AddonName, SAO = ...

-- Optimize frequent calls
local GetTalentTabInfo = GetTalentTabInfo
local UnitCanAttack = UnitCanAttack
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

local incinerate = 29722;
local shadowBolt = 686;
local soulFire = 6353;

local moltenCoreBuff = { 47383, 71162, 71165 };
local decimationBuff = { 63165, 63167 };

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

local function useNightfall(self)
    self:CreateEffect(
        "nightfall",
        SAO.ALL_PROJECTS,
        17941, -- Shadow Trance (buff)
        "aura",
        {
            talent = 18094, -- Nightfall (talent)
            overlay = { texture = "nightfall", position = "Left + Right (Flipped)" },
            button = shadowBolt,
        }
    );
end

local function registerMoltenCore(self, rank)
    local moltenCoreName = { "molten_core_low", "molten_core_medium", "molten_core_high" };
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

local function useMoltenCore(self)
    if self.IsWrath() or self.IsCata() then
        self:AddOverlayLink(moltenCoreBuff[3], moltenCoreBuff[1]);
        self:AddOverlayLink(moltenCoreBuff[3], moltenCoreBuff[2]);
        self:AddGlowingLink(moltenCoreBuff[3], moltenCoreBuff[1]);
        self:AddGlowingLink(moltenCoreBuff[3], moltenCoreBuff[2]);

        registerMoltenCore(self, 1); -- 1/3 talent point
        registerMoltenCore(self, 2); -- 2/3 talent points
        registerMoltenCore(self, 3); -- 3/3 talent points
    end
end

local function registerDecimation(self, rank)
    local decimationName = { "decimation_low", "decimation_high" };

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

local function useDecimation(self)
    if self.IsWrath() or self.IsCata() then
        self:AddOverlayLink(decimationBuff[2], decimationBuff[1]);
        self:AddGlowingLink(decimationBuff[2], decimationBuff[1]);

        registerDecimation(self, 1); -- 1/2 talent point
        registerDecimation(self, 2); -- 2/2 talent points
    end
end

local function useBacklash(self)
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
end

local function useEmpoweredImp(self)
    self:CreateEffect(
        "empowered_imp",
        SAO.WRATH + SAO.CATA,
        47283, -- Empowered Imp (buff)
        "aura",
        {
            talent = 47220, -- Empowered Imp (talent)
            overlay = { texture = "imp_empowerment", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.CATA] = soulFire,
            }
        }
    );
end

local function registerClass(self)
    -- Affliction
    useNightfall(self); -- a.k.a. Shadow Trance

    -- Demonology
    useMoltenCore(self);
    useDecimation(self);

    -- Destruction
    useBacklash(self);
    useEmpoweredImp(self);
end

local function loadOptions(self)
    local drainSoul = 1120;

    if DrainSoulHandler.initialized then
        self:AddGlowingOption(nil, DrainSoulHandler.optionID, drainSoul, nil, string.format(string.format(HEALTH_COST_PCT, "<%s%"), 25), DrainSoulHandler.variants);
    end
end

SAO.Class["WARLOCK"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["PLAYER_LOGIN"] = customLogin,
    ["PLAYER_TARGET_CHANGED"] = retarget,
    ["UNIT_HEALTH"] = unitHealth,
}
