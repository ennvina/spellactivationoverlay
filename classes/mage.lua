local AddonName, SAO = ...

local hotStreakSpellID = 48108;
local heatingUpSpellID = 48107; -- Does not exist in Wrath Classic

-- Because the Heating Up buff does not exist in Wrath of the Lich King
-- We try to guess when the mage should virtually get this buff
local HotStreakHandler = {}

-- Initialize constants
HotStreakHandler.init = function(self, spellName)
    local fire_blast = { 2136, 2137, 2138, 8412, 8413, 10197, 10199, 27078, 27079, 42872, 42873 }
    local fireball = { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306, 27070, 38692, 42832, 42833 }
    -- local living_bomb = { 44457, 55359, 55360 } this is the DOT effect, which we do NOT want
    local living_bomb = { 44461, 55361, 55362 }
    local scorch = { 2948, 8444, 8445, 8446, 10205, 10206, 10207, 27073, 27074, 42858, 42859 }

    self.spells = {}
    local function addSpellPack(spellPack)
        for _, spellID in pairs(spellPack) do
            self.spells[spellID] = true;
        end
    end
    addSpellPack(fire_blast);
    addSpellPack(fireball);
    addSpellPack(living_bomb);
    addSpellPack(scorch);

    -- There are 3 states possible: cold, heating_up and hot_streak
    -- The state always starts as cold
    self.state = 'cold';
    -- There is a known issue when the player disconnects with the virtual "Heating Up" buff, then reconnects
    -- Ideally, we'd keep track of the virtual buff, but it's really hard to do, and sometimes not even possible
    -- It's best not to over-design something to try to fix fringe cases, so we simply accept this limitation
end

HotStreakHandler.isSpellTracked = function(self, spellID)
    return self.spells[spellID];
end

local function registerAuras(self)
    local hotStreamSpellName = GetSpellInfo(hotStreakSpellID);
    if (hotStreamSpellName) then
        -- Check for Hot Streak Spell to know if we are in Warth Classic
        -- Currently, there is no such constant as WOW_PROJECT_WOTLK_CLASSIC or WOW_PROJECT_WRATH_CLASSIC, etc.

        self:RegisterAura("hot_streak_full", 0, hotStreakSpellID, 449490, "Left + Right (Flipped)", 1, 255, 255, 255);

        --self:RegisterAura("hot_streak_half", 0, heatingUpSpellID, 449490, "Left + Right (Flipped)", 0.5, 255, 255, 255);
        -- Heating Up (spellID == 48107) doesn't exist in Wrath Classic, so we can't use the above aura
        -- Instead, we track Fire Blast, Fireball, Living Bomb and Scorch non-periodic critical strikes
        HotStreakHandler:init(hotStreamSpellName);
    end
end

local function customCLEU(self, ...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo() -- For all events

    -- Special case: if player dies, we assume the "Heating Up" virtual buff is lost
    if (event == "UNIT_DIED" and destGUID == UnitGUID("player")) then
        if (HotStreakHandler.state == 'heating_up') then
            self:DeactivateOverlay(heatingUpSpellID);
        end
        HotStreakHandler.state = 'cold';

        return;
    end

    -- Accept only certain events, and only when done by the player
    if (event ~= "SPELL_DAMAGE" and event ~= "SPELL_AURA_APPLIED" and event ~= "SPELL_AURA_REMOVED") then return end
    if (sourceGUID ~= UnitGUID("player")) then return end

    local spellID, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo()) -- For SPELL_*

    -- If Hot Streak buff was acquired or lost, we have our immediate answer
    -- We assume there is no third charge i.e., if a crit occurs under Hot Streak buff, there is no hidden Heating Up
    if (event == "SPELL_AURA_APPLIED") then
        if (spellID == hotStreakSpellID) then
            self:DeactivateOverlay(heatingUpSpellID);
            HotStreakHandler.state = 'hot_streak';
        end
        return;
    elseif (event == "SPELL_AURA_REMOVED") then
        if (spellID == hotStreakSpellID) then
            HotStreakHandler.state = 'cold';
        end
        return;
    end

    -- The rest of the code is dedicated to try to catch the Heating Up buff, or if the buff is lost.

    -- Spell must be match a known spell ID that can proc Hot Streak
    if (not HotStreakHandler:isSpellTracked(spellID)) then return end

    local amount, overkill, school, resisted, blocked, absorbed, critical, glancing, crushing, isOffHand = select(15, CombatLogGetCurrentEventInfo()); -- For SPELL_DAMAGE*

    if (HotStreakHandler.state == 'cold') then
        if (critical) then
            -- A crit while cold => Heating Up!
            HotStreakHandler.state = 'heating_up';
            self:ActivateOverlay(0, heatingUpSpellID, self.TexName[449490], "Left + Right (Flipped)", 0.5, 255, 255, 255);
        end
    elseif (HotStreakHandler.state == 'heating_up') then
        if (not critical) then
            -- No crit while Heating Up => cooling down
            HotStreakHandler.state = 'cold';
            self:DeactivateOverlay(heatingUpSpellID);
        -- else
            -- We could put the state to 'hot_streak' here, but the truth is, we don't know for sure if it's accurate
            -- Either way, if the Hot Streak buff is deserved, we'll know soon enough with a "SPELL_AURA_APPLIED"
        end
    elseif (HotStreakHandler.state == 'hot_streak') then
        -- No matter if we crit or not, when we are in a Hot Streak, we stay that way until "SPELL_AURA_REMOVED" comes
    else
        print("Unkown HotStreakHandler state");
    end
end

SAO.Class["MAGE"] = {
    ["Register"] = registerAuras,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
}
