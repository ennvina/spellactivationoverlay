local AddonName, SAO = ...

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitCanAttack = UnitCanAttack
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

local function easyAs123(option)
    return option == "stance:1/2/3";
end

--[[
    OverpowerHandler guesses when Overpower is available,
    even without being in Battle Stance

    The following conditions must be met:
    - an enemy dodged recently
    - that enemy is the current target

    This stops if either:
    - Overpower has been cast
    - the current target is not the enemy who dodged
    - more than 5 seconds have elapsed since last dodge

    The Overpower button will glow/unglow successively when
    switching the target back and forth the enemy who dodged.
    This prevents players from switching to Battle Stance
    and then wondering "why am I unable to cast Overpower?"

    If multiple enemies have dodged recently, Overpower
    can only be cast on the last enemy who dodged.
    This matches behavior on current Wrath phase (Ulduar).
    May need testing for Classic Era and other Wrath phases.
]]
local OverpowerHandler = {

    initialized = false,

    -- Variables

    targetGuid = nil,

    -- Methods

    init = function(self, id, name)
        SAO.GlowInterface:bind(self);
        self:initVars(id, name, true, 5, {
            SAO:StanceVariantValue({ 1 }),
            SAO:StanceVariantValue({ 1, 2, 3 }),
        }, easyAs123);
        self.initialized = true;
    end,

    dodge = function(self, guid)
        self.targetGuid = guid;

        if UnitGUID("target") == guid then
            self:glow();
        end
    end,

    overpower = function(self)
        self.targetGuid = nil;
        -- Always unglow, even if not needed. Better unglow too much than not enough.
        self:unglow();
    end,

    retarget = function(self, ...)
        if not self.targetGuid then return end

        if self.glowing and UnitGUID("target") ~= self.targetGuid then
            self:unglow();
        elseif not self.glowing and UnitGUID("target") == self.targetGuid then
            self:glow();
        end
    end,

    cleu = function(self, ...)
        local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...; -- For all events

        if sourceGUID ~= UnitGUID("player") then return end

        if event == "SWING_MISSED" and select(12, ...) == "DODGE"
        or event == "SPELL_MISSED" and select(15, ...) == "DODGE" then
            self:dodge(destGUID);
        elseif event == "SPELL_CAST_SUCCESS" and select(13, ...) == self.spellName then
            self:overpower();
        end
    end,
}

--[[
    RevengeHandler guesses when Revenge is available,
    even without being in Defensive Stance

    The following conditions must be met:
    - the player dodged, parried or blocked recently

    This stops if either:
    - Revenge has been cast
    - more than 5 seconds have elapsed since last dodge/parry/block
]]
local RevengeHandler = {

    initialized = false,

    -- Methods

    init = function(self, id, name)
        SAO.GlowInterface:bind(self);
        self:initVars(id, name, true, 5, {
            SAO:StanceVariantValue({ 2 }),
            SAO:StanceVariantValue({ 1, 2, 3 }),
        }, easyAs123);
        self.initialized = true;
    end,

    dpb = function(self) -- 'DPB' means Dodge, Parry, or Block
        self:glow();
    end,

    revenge = function(self)
        -- Always unglow, even if not needed. Better unglow too much than not enough.
        self:unglow();
    end,

    cleu = function(self, ...)
        local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...; -- For all events

        local myGuid = UnitGUID("player");

        if sourceGUID == myGuid then
            if event == "SPELL_CAST_SUCCESS" and select(13, ...) == self.spellName then
                self:revenge();
            end
        end

        if destGUID == myGuid then

            if event:sub(0,6) == "SPELL_" then
                local spellID = select(12, ...);
                if spellID == 42463 or spellID == 53739 then
                    return; -- Seal of Vengeance and Seal of Corruption do not trigger Revenge, probably because of PvP balancing issues
                end
            end

            if event == "SWING_MISSED" or event == "SPELL_MISSED" then
                -- Check for full dodge/parry/block
                local missType;
                if event == "SWING_MISSED" then
                    missType = select(12, ...);
                elseif event == "SPELL_MISSED" then
                    missType = select(15, ...);
                end
                if missType == "DODGE" or missType == "PARRY" or missType == "BLOCK" then
                    self:dpb();
                end
            elseif event == "SWING_DAMAGE" or event == "SPELL_DAMAGE" then
                -- Check for partial block
                local blocked;
                if event == "SWING_DAMAGE" then
                    blocked = select(16, ...);
                elseif event == "SPELL_DAMAGE" then
                    blocked = select(19, ...);
                end
                if blocked then
                    self:dpb();
                end
            end

        end
    end,
}

--[[
    ExecuteHandler guesses when Execute is available,
    even without being in Battle or Berserker Stance

    The following conditions must be met:
    - the current target can be attacked
    - the current target has less than 20% health

    This stops if either:
    - the target cannot be attacked
    - the target is healed at or over 20% health
]]
local ExecuteHandler = {

    initialized = false,

    -- Methods

    init = function(self, id, name)
        SAO.GlowInterface:bind(self);
        self:initVars(id, name, true, nil, {
            SAO:StanceVariantValue({ 1, 3 }),
            SAO:StanceVariantValue({ 1, 2, 3 }),
        }, easyAs123);
        self.initialized = true;
    end,

    checkTargetHealth = function(self)
        local canExecute = false;

        if UnitCanAttack("player", "target") then
            local hp = UnitHealth("target");
            local hpMax = UnitHealthMax("target");
            canExecute = hp > 0 and hp/hpMax < 0.2;
        end

        if canExecute and not self.glowing then
            self:glow();
        elseif not canExecute and self.glowing then
            self:unglow();
        end
    end,

    retarget = function(self, ...)
        self:checkTargetHealth();
    end,

    healthChanged = function(self, unitID)
        if unitID == "target" then
            self:checkTargetHealth();
        end
    end
}

local function customLogin(self, ...)
    local overpower = 7384;
    local overpowerName = GetSpellInfo(overpower);
    if (overpowerName) then
        OverpowerHandler:init(overpower, overpowerName);
    end

    local revenge = 6572;
    local revengeName = GetSpellInfo(revenge);
    if (revengeName) then
        RevengeHandler:init(revenge, revengeName);
    end

    local execute = 5308;
    local executeName = GetSpellInfo(execute);
    if (executeName) then
        ExecuteHandler:init(execute, executeName);
    end
end

local function customCLEU(self, ...)
    if OverpowerHandler.initialized then
        OverpowerHandler:cleu(CombatLogGetCurrentEventInfo());
    end

    if RevengeHandler.initialized then
        RevengeHandler:cleu(CombatLogGetCurrentEventInfo());
    end
end

local function retarget(self, ...)
    if OverpowerHandler.initialized then
        OverpowerHandler:retarget(...);
    end

    if ExecuteHandler.initialized then
        ExecuteHandler:retarget(...);
    end
end

local function unitHealth(self, ...)
    if ExecuteHandler.initialized then
        ExecuteHandler:healthChanged(...);
    end
end

local function registerClass(self)
    -- local tasteforBlood = 60503; -- Unused as of now, might be used in the future.
    local overpower = 7384;
    local execute = 5308;
    local revenge = 6572;
    local victoryRush = 34428;
    local slam = 1464;
    local shieldSlam = 23922;

    self:RegisterAura("bloodsurge", 0, 46916, "blood_surge", "Top", 1, 255, 255, 255, true, { (GetSpellInfo(slam)) });
    self:RegisterAura("sudden_death", 0, 52437, "sudden_death", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(execute)) });
    self:RegisterAura("sword_and_board", 0, 50227, "sword_and_board", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(shieldSlam)) });

    -- Overpower
    self:RegisterAura("overpower", 0, overpower, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(overpower)) });
    self:RegisterCounter("overpower"); -- Must match name from above call

    -- Execute
    self:RegisterAura("execute", 0, execute, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(execute)) });
    self:RegisterCounter("execute"); -- Must match name from above call

    -- Revenge
    self:RegisterAura("revenge", 0, revenge, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(revenge)) });
    self:RegisterCounter("revenge"); -- Must match name from above call

    -- Victory Rush
    self:RegisterAura("victory_rush", 0, victoryRush, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(victoryRush)) });
    self:RegisterCounter("victory_rush"); -- Must match name from above call
end

local function loadOptions(self)
    -- local overpower = 7384;
    local execute = 5308;
    -- local revenge = 6572;
    local victoryRush = 34428;
    local slam = 1464;
    local shieldSlam = 23922;

    local bloodsurgeBuff = 46916;
    local bloodsurgeTalent = 46913;

    local suddenDeathBuff = 52437;
    local suddenDeathTalent = 29723;

    local swordAndBoardBuff = 50227;
    local swordAndBoardTalent = 46951;


    self:AddOverlayOption(suddenDeathTalent, suddenDeathBuff);
    self:AddOverlayOption(bloodsurgeTalent, bloodsurgeBuff);
    self:AddOverlayOption(swordAndBoardTalent, swordAndBoardBuff);

    if OverpowerHandler.initialized then
        self:AddGlowingOption(nil, OverpowerHandler.optionID, OverpowerHandler.spellID, nil, nil, OverpowerHandler.variants);
    end
    if RevengeHandler.initialized then
        self:AddGlowingOption(nil, RevengeHandler.optionID, RevengeHandler.spellID, nil, nil, RevengeHandler.variants);
    end
    if ExecuteHandler.initialized then
        self:AddGlowingOption(nil, ExecuteHandler.optionID, ExecuteHandler.spellID, nil, nil, ExecuteHandler.variants);
    end
    self:AddGlowingOption(nil, victoryRush, victoryRush);
    self:AddGlowingOption(suddenDeathTalent, suddenDeathBuff, execute);
    self:AddGlowingOption(bloodsurgeTalent, bloodsurgeBuff, slam);
    self:AddGlowingOption(swordAndBoardTalent, swordAndBoardBuff, shieldSlam);
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["PLAYER_LOGIN"] = customLogin,
    ["PLAYER_TARGET_CHANGED"] = retarget,
    ["UNIT_HEALTH"] = unitHealth,
}
