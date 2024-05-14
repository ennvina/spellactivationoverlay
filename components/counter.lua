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
-- key = spellName / spellID, value = { nodeName, talent, combatOnly }
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
-- @param nodeName name of the registered node
-- @param talent talent object { tab, index } to check when counter triggers; may be nil
function SAO:RegisterCounter(nodeName, talent)
    local bucket = self:GetBucketByName(nodeName);
    if not bucket then
        self:Error(Module, "Cannot find a bucket for counter "..tostring(nodeName));
        return;
    elseif not bucket[0] then
        self:Error(Module, "Cannot find a stackless bucket for counter "..tostring(nodeName));
        return;
    elseif #bucket[0] ~= 1 then
        self:Error(Module, "Non-unique bucket for counter "..tostring(nodeName));
        return;
    end

    local node = bucket[0][1];

    local combatOnly = node.combatOnly;

    local counter = { nodeName, talent, combatOnly };

    local glowIDs = node.buttons;
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
-- @param nodeName name of the registered node
-- @param newStatus new status, either 'off', 'hard' or 'soft'
function SAO.SetCounterStatus(self, spellID, nodeName, newStatus)
    local oldStatus = 'off';
    if self.ActivatedCounters[spellID] then
        oldStatus = self.ActivatedCounters[spellID].status;
    end

    if oldStatus == newStatus then
        return;
    end

    local bucket = self:GetBucketByName(nodeName);
    local node = bucket[0][1]; -- We know it has stacks == 0, which has exactly one item in it, thanks to RegisterCounter checks
    if not node then
        -- Unknown node. Should never happen.
        self:Error(Module, "Counter uses unknown nodeName "..tostring(nodeName));
        return;
    end
    local nodeSpellID = node.spellID;

    local statusChanged = false;
    if oldStatus == 'off' and newStatus == 'hard' then
        node.overlays:show();
        self:AddGlow(nodeSpellID, {spellID});
        self.ActivatedCounters[spellID] = { status=newStatus };
        statusChanged = true;
    elseif oldStatus == 'hard' and newStatus == 'off' then
        node.overlays:hide();
        self:RemoveGlow(nodeSpellID);
        self.ActivatedCounters[spellID] = nil;
        statusChanged = true;
    elseif oldStatus == 'off' and newStatus == 'soft' then
        node:show();
        self:AddGlow(nodeSpellID, {spellID});
        local TimetoLingerGlowForSoft = 7.5; -- Buttons glows temporarily for 7.5 secs
        -- The time is longer from Off to Soft than from Hard to Soft, because starting
        -- a spell alert out-of-combat combat incurs a 5-second highlight before fading out
        local timer = C_Timer.NewTimer(
            TimetoLingerGlowForSoft,
            function() self:RemoveGlow(nodeSpellID) end
        );
        self.ActivatedCounters[spellID] = { status=newStatus, softTimer=timer };
        statusChanged = true;
    elseif oldStatus == 'soft' and newStatus == 'off' then
        local timer = self.ActivatedCounters[spellID].softTimer;
        timer:Cancel();
        node.overlays:hide();
        self:RemoveGlow(nodeSpellID);
        self.ActivatedCounters[spellID] = nil;
        statusChanged = true;
    elseif oldStatus == 'soft' and newStatus == 'hard' then
        local timer = self.ActivatedCounters[spellID].softTimer;
        timer:Cancel();
        -- node:show(); -- No need to activate, it is already active, even if hidden
        self:AddGlow(nodeSpellID, {spellID}); -- Re-glow in case the glow was removed after soft timer ended
        self.ActivatedCounters[spellID] = { status=newStatus };
        statusChanged = true;
    elseif oldStatus == 'hard' and newStatus == 'soft' then
        -- node:show(); -- No need to activate, it is already active
        -- self:AddGlow(nodeSpellID, {spellID}); -- No need to glow, it is already glowing
        local TimetoLingerGlowForSoft = 2.5; -- Buttons glows temporarily for 2.5 secs
        local timer = C_Timer.NewTimer(
            TimetoLingerGlowForSoft,
            function() self:RemoveGlow(nodeSpellID) end
        );
        self.ActivatedCounters[spellID] = { status=newStatus, softTimer=timer };
        statusChanged = true;
    end
    if statusChanged then -- Do not compare (oldStatus ~= newStatus) because it does not tell if something was done
        SAO:Debug(Module, "Status of counter "..tostring(spellID).." changed from '"..oldStatus.."' to '"..newStatus.."'");
    end
end

-- Check if an action counter became either activated or deactivated
function SAO.CheckCounterAction(self, spellID, nodeName, talent, combatOnly)
    SAO:TraceThrottled(spellID, Module, "CheckCounterAction "..tostring(spellID).." "..tostring(nodeName).." "..tostring(talent).." "..tostring(combatOnly));

    if (talent) then
        local rank = select(5, GetTalentInfo(talent[1], talent[2]));
        if (not (rank > 0)) then
            -- 0 points spent in the required Talent
            self:SetCounterStatus(spellID, nodeName, 'off');
            return;
        end
    end

    if (not self:IsSpellLearned(spellID)) then
        -- Spell not learned
        self:SetCounterStatus(spellID, nodeName, 'off');
        return;
    end

    local start, duration, enabled, modRate = GetSpellCooldown(spellID);
    if (type(start) ~= "number") then
        -- Spell not available
        self:SetCounterStatus(spellID, nodeName, 'off');
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
    self:SetCounterStatus(spellID, nodeName, status);

    if (isCounterUsable and start > 0) then
        -- Counter could be usable, but CD prevents us to: try again in a few seconds
        local endTime = start+duration;

        if (not self.CounterRetryTimers[spellID] or self.CounterRetryTimers[spellID].endTime ~= endTime) then
            if (self.CounterRetryTimers[spellID]) then
                self.CounterRetryTimers[spellID]:Cancel();
            end

            local remainingTime = endTime-GetTime();
            local delta = 0.05; -- Add a small delay to account for lags and whatnot
            local retryFunc = function() self:CheckCounterAction(spellID, nodeName, talent, combatOnly); end;
            self.CounterRetryTimers[spellID] = C_Timer.NewTimer(remainingTime+delta, retryFunc);
            self.CounterRetryTimers[spellID].endTime = endTime;
        end
    end
end

function SAO.CheckAllCounterActions(self, checkCombatOnly)
    SAO:TraceThrottled(checkCombatOnly, Module, "CheckAllCounterActions "..tostring(checkCombatOnly));
    for spellID, counter in pairs(self.ActivableCountersBySpellID) do
        if not checkCombatOnly or counter[3] then
            self:CheckCounterAction(spellID, counter[1], counter[2], counter[3]);
        end
    end
end
