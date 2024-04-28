local AddonName, SAO = ...
local Module = "counter"

-- Optimize frequent calls
local GetSpellCooldown = GetSpellCooldown
local GetSpellPowerCost = GetSpellPowerCost
local GetTalentInfo = GetTalentInfo
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local IsUsableSpell = IsUsableSpell

--[[
    A counter's activity can be in one of these statuses:
    - Off
    - Hard = active, no questions asked
    - Soft = active internally, but visually softened (e.g. can be hidden temporarily to remove visual clutter)
]]

-- List of spell names or IDs of actions that can trigger as 'counter'
-- key = spellName / spellID, value = { auraID, talent }
SAO.ActivableCountersByName = {};
SAO.ActivableCountersBySpellID = {};

-- List of spell IDs currently activated
-- key = spellID, value = { status, softTimer }
-- status = 'hard' | 'soft'
-- softTimer = timer object if status == 'soft'
SAO.ActivatedCounters = {};

-- List of timer objects for checking cooldown of activated counters
-- key = spellID, value = timer object
SAO.CounterRetryTimers = {};

-- Track an action that becomes usable by itself, without knowing it with an aura
-- If the action is triggered by an aura, it will already activate during buff
-- The spellID is taken from the aura's table
-- @param auraID name of the aura registered to SAO.RegisterAura
-- @param talent talent object { tab, index } to check when counter triggers; may be nil
function SAO.RegisterCounter(self, auraID, talent)
    local aura = self.RegisteredAurasByName[auraID];
    if (not aura) then
        return;
    end

    local combatOnly = select(13,unpack(aura));

    local counter = { auraID, talent, combatOnly };

    local glowIDs = select(11,unpack(aura));
    for _, glowID in ipairs(glowIDs or {}) do
        if (type(glowID) == "number") then
            self.ActivableCountersBySpellID[glowID] = counter;
        elseif (type(glowID) == "string") then
            self.ActivableCountersByName[glowID] = counter;
            local glowSpellIDs = self:GetSpellIDsByName(glowID);
            for _, glowSpellID in ipairs(glowSpellIDs) do
                self.ActivableCountersBySpellID[glowSpellID] = counter;
            end
        end
    end
end

-- Set the counter status of a spell. Do nothing if the status has not changed.
-- @param spellID spell ID of the counter to update
-- @param auraID spell ID of the registered aura
-- @param newStatus new status, either 'off', 'hard' or 'soft'
function SAO.SetCounterStatus(self, spellID, auraID, newStatus)
    local oldStatus = 'off';
    if self.ActivatedCounters[spellID] then
        oldStatus = self.ActivatedCounters[spellID].status;
    end

    if oldStatus == newStatus then
        return;
    end

    local aura = self.RegisteredAurasByName[auraID];
    if not aura then
        -- Unknown aura. Should never happen.
        self:Debug(Module, "Counter uses unknown auraID "..tostring(auraID));
        return;
    end
    local auraSpellID = aura[3];

    local statusChanged = false;
    if oldStatus == 'off' and newStatus == 'hard' then
        self:ActivateOverlay(select(2, unpack(aura)));
        self:AddGlow(auraSpellID, {spellID});
        self.ActivatedCounters[spellID] = { status=newStatus };
        statusChanged = true;
    elseif oldStatus == 'hard' and newStatus == 'off' then
        self:DeactivateOverlay(auraSpellID);
        self:RemoveGlow(auraSpellID);
        self.ActivatedCounters[spellID] = nil;
        statusChanged = true;
    elseif oldStatus == 'off' and newStatus == 'soft' then
        self:ActivateOverlay(select(2, unpack(aura)));
        self:AddGlow(auraSpellID, {spellID});
        local TimetoLingerGlowForSoft = 7.5; -- Buttons glows temporarily for 7.5 secs
        -- The time is longer from Off to Soft than from Hard to Soft, because starting
        -- a spell alert out-of-combat combat incurs a 5-second highlight before fading out
        local timer = C_Timer.NewTimer(
            TimetoLingerGlowForSoft,
            function() self:RemoveGlow(auraSpellID) end
        );
        self.ActivatedCounters[spellID] = { status=newStatus, softTimer=timer };
        statusChanged = true;
    elseif oldStatus == 'soft' and newStatus == 'off' then
        local timer = self.ActivatedCounters[spellID].softTimer;
        timer:Cancel();
        self:DeactivateOverlay(auraSpellID);
        self:RemoveGlow(auraSpellID);
        self.ActivatedCounters[spellID] = nil;
        statusChanged = true;
    elseif oldStatus == 'soft' and newStatus == 'hard' then
        local timer = self.ActivatedCounters[spellID].softTimer;
        timer:Cancel();
        -- self:ActivateOverlay(select(2, unpack(aura))); -- No need to activate, it is already active, even if hidden
        self:AddGlow(auraSpellID, {spellID}); -- Re-glow in case the glow was removed after soft timer ended
        self.ActivatedCounters[spellID] = { status=newStatus };
        statusChanged = true;
    elseif oldStatus == 'hard' and newStatus == 'soft' then
        -- self:ActivateOverlay(select(2, unpack(aura))); -- No need to activate, it is already active
        -- self:AddGlow(auraSpellID, {spellID}); -- No need to glow, it is already glowing
        local TimetoLingerGlowForSoft = 2.5; -- Buttons glows temporarily for 2.5 secs
        local timer = C_Timer.NewTimer(
            TimetoLingerGlowForSoft,
            function() self:RemoveGlow(auraSpellID) end
        );
        self.ActivatedCounters[spellID] = { status=newStatus, softTimer=timer };
        statusChanged = true;
    end
    if statusChanged then -- Do not compare (oldStatus ~= newStatus) because it does not tell if something was done
        SAO:Debug(Module, "Status of counter "..tostring(spellID).." changed from '"..oldStatus.."' to '"..newStatus.."'");
    end
end

-- Check if an action counter became either activated or deactivated
function SAO.CheckCounterAction(self, spellID, auraID, talent, combatOnly)
    SAO:TraceThrottled(spellID, Module, "CheckCounterAction "..tostring(spellID).." "..tostring(auraID).." "..tostring(talent).." "..tostring(combatOnly));

    if (talent) then
        local rank = select(5, GetTalentInfo(talent[1], talent[2]));
        if (not (rank > 0)) then
            -- 0 points spent in the required Talent
            self:SetCounterStatus(spellID, auraID, 'off');
            return;
        end
    end

    if (not self:IsSpellLearned(spellID)) then
        -- Spell not learned
        self:SetCounterStatus(spellID, auraID, 'off');
        return;
    end

    local start, duration, enabled, modRate = GetSpellCooldown(spellID);
    if (type(start) ~= "number") then
        -- Spell not available
        self:SetCounterStatus(spellID, auraID, 'off');
        return;
    end

    local isCounterUsable, notEnoughPower = IsUsableSpell(spellID);

    local gcdDuration = self:GetGCD();
    local isGCD = duration <= gcdDuration;
    local isCounterOnCD = start > 0 and not isGCD;

    -- Non-mana spells should always glow, regardless of player's current resources.
    local costsMana = false
    for _, spellCost in ipairs(GetSpellPowerCost(spellID) or {}) do
        if spellCost.name == "MANA" then
            costsMana = true;
            break;
        end
    end

    -- Evaluate what is the current status of the counter
    local status = 'off';
    if not isCounterOnCD and (isCounterUsable or (notEnoughPower and not costsMana)) then
        if InCombatLockdown() or not combatOnly then
            status = 'hard';
        else
            status = 'soft';
        end
    end

    -- Set the new status and enable/disable spell alerts and glowing buttons accordingly
    self:SetCounterStatus(spellID, auraID, status);

    if (isCounterUsable and start > 0) then
        -- Counter could be usable, but CD prevents us to: try again in a few seconds
        local endTime = start+duration;

        if (not self.CounterRetryTimers[spellID] or self.CounterRetryTimers[spellID].endTime ~= endTime) then
            if (self.CounterRetryTimers[spellID]) then
                self.CounterRetryTimers[spellID]:Cancel();
            end

            local remainingTime = endTime-GetTime();
            local delta = 0.05; -- Add a small delay to account for lags and whatnot
            local retryFunc = function() self:CheckCounterAction(spellID, auraID, talent, combatOnly); end;
            self.CounterRetryTimers[spellID] = C_Timer.NewTimer(remainingTime+delta, retryFunc);
            self.CounterRetryTimers[spellID].endTime = endTime;
        end
    end
end

function SAO.CheckAllCounterActions(self, checkCombatOnly)
    SAO:TraceThrottled(checkCombatOnly, Module, "CheckAllCounterActions "..tostring(checkCombatOnly));
    for spellID, counter in pairs(self.ActivableCountersBySpellID) do
        if not checkCombatOnly or counter[3] then
            self:CheckCounterAction(spellID, unpack(counter));
        end
    end
end
