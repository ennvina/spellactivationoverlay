local AddonName, SAO = ...

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID

local OverpowerHandler = {
    initialized = false,
    -- Variables
    targetGuid = nil,
    vanishTime = nil,
    glowing = false,
    -- Constants; spellName and fakeSpellID are computed during init
    maxDuration = 5,
    tolerance = 0.2,
    spellName = nil,
    spellID = 7384,
    fakeSpellID = nil,
}

OverpowerHandler.init = function(self, name)
    self.spellName = name;
    self.fakeSpellID = self.spellID + 1000000;
    self.initialized = true;
end

OverpowerHandler.glow = function(self)
    SAO:AddGlow(self.fakeSpellID, { self.spellName });
    self.glowing = true;
end

OverpowerHandler.unglow = function(self)
    SAO:RemoveGlow(self.fakeSpellID);
    self.glowing = false;
end

OverpowerHandler.dodge = function(self, guid)
    self.targetGuid = guid;
    self.vanishTime = GetTime() + self.maxDuration - self.tolerance;
    C_Timer.After(self.maxDuration, function()
        self:timeout();
    end)

    if UnitGUID("target") == guid then
        self:glow();
    end
end

OverpowerHandler.overpower = function(self)
    self.targetGuid = nil;
    -- Always unglow, even if not needed. Better unglow too much than not enough.
    self:unglow();
end

OverpowerHandler.timeout = function(self)
    if self.targetGuid and GetTime() > self.vanishTime then
        self.targetGuid = nil;
        self:unglow();
    end
end

OverpowerHandler.retarget = function(self, ...)
    if not self.targetGuid then return end

    if self.glowing and UnitGUID("target") ~= self.targetGuid then
        self:unglow();
    elseif not self.glowing and UnitGUID("target") == self.targetGuid then
        self:glow();
    end
end

local function customLogin(self, ...)
    local overpowerName = GetSpellInfo(OverpowerHandler.spellID);
    if (overpowerName) then
        OverpowerHandler:init(overpowerName);
    end
end

local function customCLEU(self, ...)
    if not OverpowerHandler.initialized then return end

    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo(); -- For all events

    if sourceGUID ~= UnitGUID("player") then return end

    if event == "SWING_MISSED" and select(12, CombatLogGetCurrentEventInfo()) == "DODGE"
    or event == "SPELL_MISSED" and select(15, CombatLogGetCurrentEventInfo()) == "DODGE" then
        OverpowerHandler:dodge(destGUID);
    elseif event == "SPELL_CAST_SUCCESS" and select(13, CombatLogGetCurrentEventInfo()) == OverpowerHandler.spellName then
        OverpowerHandler:overpower();
    end
end

local function retarget(self, ...)
    OverpowerHandler:retarget(...);
end

local function registerClass(self)
    local tasteforBlood = 60503; -- Unused as of now, might be used in the future.
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
    local overpower = 7384;
    local execute = 5308;
    local revenge = 6572;
    local victoryRush = 34428;
    local slam = 1464;
    local shieldSlam = 23922;

    local bloodsurgeBuff = 46916;
    local bloodsurgeTalent = 46913;

    local suddenDeathBuff = 52437;
    local suddenDeathTalent = 29723;

    local swordAndBoardBuff = 50227;
    local swordAndBoardTalent = 46951;

    local battleStance = GetSpellInfo(2457);
    local defensiveStance = GetSpellInfo(71);
    local berserkerStance = GetSpellInfo(2458);

    self:AddOverlayOption(suddenDeathTalent, suddenDeathBuff);
    self:AddOverlayOption(bloodsurgeTalent, bloodsurgeBuff);
    self:AddOverlayOption(swordAndBoardTalent, swordAndBoardBuff);

    self:AddGlowingOption(nil, overpower, overpower, nil, string.format("%s = %s", DEFAULT, string.format(RACE_CLASS_ONLY, battleStance)));
    self:AddGlowingOption(nil, OverpowerHandler.fakeSpellID, overpower, nil, string.format("%s, %s, %s", battleStance, defensiveStance, berserkerStance));
    self:AddGlowingOption(nil, revenge, revenge, nil, string.format("%s = %s", DEFAULT, string.format(RACE_CLASS_ONLY, defensiveStance)));
    --self:AddGlowingOption(nil, ---, revenge, nil, string.format("%s, %s, %s", battleStance, defensiveStance, berserkerStance));
    self:AddGlowingOption(nil, execute, execute, nil, string.format("%s = %s", DEFAULT, string.format("%s, %s", battleStance, berserkerStance)));
    --self:AddGlowingOption(nil, ---, execute, nil, string.format("%s, %s, %s", battleStance, defensiveStance, berserkerStance));
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
}
