local AddonName, SAO = ...
local Module = "warrior"

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetShapeshiftForm = GetShapeshiftForm
local UnitCanAttack = UnitCanAttack
local UnitGUID = UnitGUID
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

local cleave = 845;
local colossusSmash = 86346;
local execute = 5308;
local heroicStrike = 78;
local overpower = 7384;
local ragingBlowSoD = 402911;
local revenge = 6572;
local shieldSlam = 23922;
local slam = 1464;
local victoryRush = SAO.IsSoD() and 402927 or 34428;

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
            self:unglow(true);
        elseif not self.glowing and UnitGUID("target") == self.targetGuid then
            self:glow(true);
        end
    end,

    onTimeout = function(self)
        self.targetGuid = nil;
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
    OPTFBHandler guesses when Overpower is available,
    specifically for Taste for Blood

    This must be a different handler than OverpowerHandler.
    Because Taste for Blood does not have a target requirement,
    the glow/unglow reasons are quite different, and trying
    to combine them into a single handler would be a mess.

    The following condition must be met:
    - the player gains the Taste for Blood effect

    This stops if:
    - the player loses the Taste for Blood effect

    The player may lose the effect because Overpower was cast,
    or because the effect faded after its full duration

    If the Taste for Blood effect is refreshed before Overpower
    was cast, it will not re-glow the button
]]
local OPTFBHandler = {

    initialized = false,

    -- Variables

    buffID = nil,
    hasBuff = nil,

    -- Methods

    init = function(self, id, name, buffID)
        SAO.GlowInterface:bind(self);
        self:initVars(id, name, 2, nil, {
            -- Must be the same variant values as OverpowerHandler
            -- Because OPTFBHandler and OverpowerHandler share the same optionID
            SAO:StanceVariantValue({ 1 }),
            SAO:StanceVariantValue({ 1, 2, 3 }),
        }, function(option)
            -- Unlike other warrior handlers, this handler may be active with "stance:1"
            return option == "stance:1/2/3" or GetShapeshiftForm() == 1
        end);

        self.buffID = buffID;
        self.hasBuff = SAO:HasPlayerAuraBySpellID(self.buffID);
        if self.hasBuff then
            self:glow();
        end

        self.initialized = true;
    end,

    cleu = function(self, ...)
        local _, event, _, _, _, _, _, destGUID = ...;
        if destGUID ~= UnitGUID("player") then return end
        if (event:sub(0,11) ~= "SPELL_AURA_") then return end
        local spellID, spellName = select(12, CombatLogGetCurrentEventInfo());

        if event == "SPELL_AURA_APPLIED" and SAO:IsSpellIdentical(spellID, spellName, self.buffID) then
            if not self.hasBuff then
                self.hasBuff = true;
                self:glow();
            end
        elseif event == "SPELL_AURA_REMOVED" and SAO:IsSpellIdentical(spellID, spellName, self.buffID) then
            -- Always unglow, even if not needed. Better unglow too much than not enough.
            self.hasBuff = false;
            self:unglow();
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
    if SAO.IsMoP() then
        -- No handlers for Mists of Pandaria: all abilities are available in all stances
        return;
    end

    local overpowerName = GetSpellInfo(overpower);
    if overpowerName then
        -- Overpower is used for OverpowerHandler, detecting when the target dodges
        OverpowerHandler:init(overpower, overpowerName);

        -- Overpower is also used for OPTFBHandler, looking for Taste for Blood buff
        if self.IsSoD() then
            local tasteForBloodBuff = 426969;
            OPTFBHandler:init(overpower, overpowerName, tasteForBloodBuff);
        elseif self.IsWrath() or self.IsCata() then
            local tasteForBloodBuffSoD = 60503;
            OPTFBHandler:init(overpower, overpowerName, tasteForBloodBuffSoD);
        end
    end

    local revengeName = GetSpellInfo(revenge);
    if revengeName then
        RevengeHandler:init(revenge, revengeName);
    end

    local executeName = GetSpellInfo(execute);
    if executeName then
        ExecuteHandler:init(execute, executeName);
    end
end

local function customCLEU(self, ...)
    if OverpowerHandler.initialized then
        OverpowerHandler:cleu(CombatLogGetCurrentEventInfo());
    end

    if OPTFBHandler.initialized then
        OPTFBHandler:cleu(CombatLogGetCurrentEventInfo());
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

local function unitHealth(self, unitID)
    if ExecuteHandler.initialized then
        ExecuteHandler:healthChanged(unitID);
    end
end

local function unitHealthFrequent(self, unitID)
    if self:IsResponsiveMode() then
        unitHealth(self, unitID);
    end
end


local function useOverpower()
    SAO:CreateEffect(
        "overpower",
        SAO.ALL_PROJECTS,
        overpower,
        "counter",
        {   -- Lazy evaluation for variants, because they are created later on
            buttonOption = not SAO.IsMoP() and { variants = function() return OverpowerHandler.variants end } or nil,
        }
    );
end

local function useExecute()
    SAO:CreateEffect(
        "execute",
        SAO.ALL_PROJECTS,
        execute,
        "counter",
        {   -- Lazy evaluation for variants, because they are created later on
            buttonOption = not SAO.IsMoP() and { variants = function() return ExecuteHandler.variants end } or nil,
        }
    );
end

local function useRevenge()
    SAO:CreateEffect(
        "revenge",
        SAO.ALL_PROJECTS,
        revenge,
        "counter",
        {   -- Lazy evaluation for variants, because they are created later on
            buttonOption = not SAO.IsMoP() and { variants = function() return RevengeHandler.variants end } or nil,
        }
    );
end

local function useVictoryRush()
    SAO:CreateEffect(
        "victory_rush",
        SAO.ALL_PROJECTS - SAO.ERA, -- includes SAO.SOD, then SAO.TBC and later
        victoryRush,
        "counter"
    );
end

local function useRagingBlow()
    -- Has a spell alert, unlike other Warrior 'counters'
    SAO:CreateEffect(
        "raging_blow",
        SAO.SOD,
        ragingBlowSoD,
        "counter",
        {
            overlay = { texture = "raging_blow", position = "Left + Right (Flipped)" },
        }
    );
end

local function useSuddenDeath()
    local suddenDeathBuff = SAO.IsSoD() and 440114 or 52437;
    local suddenDeathTalent = SAO.IsSoD() and 440113 or 29723;

    SAO:CreateEffect(
        "sudden_death",
        SAO.SOD + SAO.WRATH + SAO.CATA,
        suddenDeathBuff,
        "aura",
        {
            talent = suddenDeathTalent,
            overlay = { texture = "sudden_death", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.SOD] = execute,
                [SAO.WRATH] = execute,
                [SAO.CATA] = colossusSmash,
            },
        }
    );
end

local function useBladestorm()
    local bladestorm = 46924;

    -- Bladestorm texture orientation depends on race and gender
    -- Known limitation: orientation may be incorrect if the player changes race or gender
    -- It can be solved in theory, but it would probably require writing unhealthy code
    local race = select(3, UnitRace("player"));
    local gender = UnitSex("player");
    local ccw = { "Left (vFlipped)", "Right (Flipped)" };
    local cw  = { "Left", "Right (180)" };
    -- Table of positions
    -- Each row has the following structure:
    -- [race] = { unknown, male, female }
    local positions = {
        [1]  = { nil, ccw, ccw }, -- Human
        [2]  = { nil, ccw, ccw }, -- Orc
        [3]  = { nil, ccw, ccw }, -- Dwarf
        [4]  = { nil, ccw, ccw }, -- Night Elf
        [5]  = { nil, ccw, ccw }, -- Undead
        [6]  = { nil, ccw, ccw }, -- Tauren
        [7]  = { nil, ccw, ccw }, -- Gnome
        [8]  = { nil, ccw, cw  }, -- Troll
        [9]  = { nil, cw , cw  }, -- Goblin
        [10] = { nil, ccw, cw  }, -- Blood Elf
        [11] = { nil, ccw, ccw }, -- Draenei
        [22] = { nil, ccw, ccw }, -- Worgen
    };
    if not positions[race] then
        SAO:Error(Module, "Unknown race "..tostring((UnitRace("player"))));
        race = 2; -- Orc
    end
    if not positions[race][gender] then
        SAO:Error(Module, "Unknown gender "..tostring(gender));
        gender = 2; -- Male
    end

    SAO:CreateEffect(
        "bladestorm",
        SAO.WRATH + SAO.CATA,
        bladestorm, -- Bladestorm (ability)
        "aura",
        {
            overlays = {
                default = { texture = "bandits_guile", scale = 1.25, color = { 200, 200, 200 } },
                { position = positions[race][gender][1], option = false },
                { position = positions[race][gender][2], option = true },
            },
        }
    );
end

local function useBattleTrance()
    local battleTranceBuff = 12964;
    local battleTranceTalent = 12322;
    SAO:CreateEffect(
        "battle_trance",
        SAO.CATA,
        battleTranceBuff,
        "aura",
        {
            talent = battleTranceTalent,
            buttons = { heroicStrike, cleave },
        }
    );
end

local function useBloodsurge()
    -- Quick note: the ability is spelled "Bloodsurge" in Wrath+ and "Blood Surge" in Season of Discovery
    local bloodsurgeBuff = SAO.IsSoD() and 413399 or 46916;
    local bloodsurgeTalent = SAO.IsSoD() and 413380 or 46913;

    SAO:CreateEffect(
        "bloodsurge",
        SAO.SOD + SAO.WRATH + SAO.CATA,
        bloodsurgeBuff,
        "aura",
        {
            overlays = {
                [SAO.SOD+SAO.WRATH] = { texture = "blood_surge", position = "Top" },
                [SAO.CATA] = { texture = "blood_surge", position = "Left + Right (Flipped)" }, -- Left/Right because texture orientation has changed
            },
            button = slam,
        }
    );
end

local function useSwordAndBoard()
    local swordAndBoardBuff = SAO.IsSoD() and 426979 or 50227;
    local swordAndBoardTalent = SAO.IsSoD() and 426978 or 46951;

    SAO:CreateEffect(
        "sword_and_board",
        SAO.SOD + SAO.WRATH + SAO.CATA,
        swordAndBoardBuff,
        "aura",
        {
            talent = swordAndBoardTalent,
            overlay = { texture = "sword_and_board", position = "Left + Right (Flipped)" },
            button = shieldSlam,
        }
    );
end

local function useIncite()
    local inciteBuff = 86627;
    local inciteTalent = 50685; -- Rank 1

    SAO:CreateEffect(
        "incite",
        SAO.CATA,
        inciteBuff,
        "aura",
        {
            talent = inciteTalent,
            button = heroicStrike,
        }
    );
end

local function useRegicide()
    local regicideBuff = 1231436;

    SAO:CreateEffect(
        "regicide_warrior",
        SAO.SOD,
        regicideBuff,
        "aura",
        {
            overlay = { texture = "sudden_death", position = "Left + Right (Flipped)" },
            button = execute,
        }
    );
end

local function registerClass(self)
    -- Counters
    useOverpower();
    useExecute();
    useRevenge();
    useVictoryRush();
    useRagingBlow();

    -- Arms
    useSuddenDeath();
    useBladestorm();

    -- Fury
    useBattleTrance();
    useBloodsurge();

    -- Protection
    useSwordAndBoard();
    useIncite();

    -- Items
    useRegicide();
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerClass,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["PLAYER_LOGIN"] = customLogin,
    ["PLAYER_TARGET_CHANGED"] = retarget,
    ["UNIT_HEALTH"] = unitHealth,
    ["UNIT_HEALTH_FREQUENT"] = unitHealthFrequent,
}
