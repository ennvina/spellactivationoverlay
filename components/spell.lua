local AddonName, SAO = ...

-- Optimize frequent calls
local GetSpellInfo = GetSpellInfo
local IsPlayerSpell = IsPlayerSpell

-- List of spell IDs sharing the same name
-- key = spell name, value = list of spell IDs
-- The list is a cache of calls to GetSpellIDsByName
-- The list will evolve automatically when the player learns new spells
SAO.SpellIDsByName = {}

-- Returns the list of spell IDs for a given name
-- Returns an empty list {} if the spell is not found in the spellbook
function SAO.GetSpellIDsByName(self, name)
    local cached = self.SpellIDsByName[name];
    if (cached) then
        return cached;
    end

    self:RefreshSpellIDsByName(name);
    return self.SpellIDsByName[name];
end

-- Force refresh the list of spell IDs for a given name by looking at the spellbook
-- The cache is updated in the process
-- If awaken is true, spellIDs are also added to RegisteredGlowSpellIDs
function SAO.RefreshSpellIDsByName(self, name, awaken)
    local homonyms = self:GetHomonymSpellIDs(name);
    self.SpellIDsByName[name] = homonyms;

    -- Awake dormant buttons associated to these spellIDs
    if (awaken) then
        local counter = self.ActivableCountersByName[name];

        for _, spellID in ipairs(homonyms) do
            -- Glowing Action Buttons (GABs)
            if (not self.RegisteredGlowSpellIDs[spellID]) then
                self.RegisteredGlowSpellIDs[spellID] = true;
                self:AwakeButtonsBySpellID(spellID);
            end

            -- Counters
            if (counter and not self.ActivableCountersBySpellID[spellID]) then
                self.ActivableCountersBySpellID[spellID] = counter;
                self:CheckCounterAction(spellID, unpack(counter));
            end
        end
    end
end

-- Update the spell cache when a new spell is learned
function SAO.LearnNewSpell(self, spellID)
    local name = GetSpellInfo(spellID);
    if (not name) then
        return;
    end

    local cached = self.SpellIDsByName[name];
    if (not cached) then
        -- Not interested in untracked spells
        return;
    end

    for _, id in ipairs(cached) do
        if (id == spellID) then
            -- Spell ID already cached
            return
        end
    end

    -- At this point, the spell ID is not cached yet, just do it!
    table.insert(self.SpellIDsByName[name], spellID);

    -- Also update RegisteredGlowSpellIDs if the name the tracked
    if (self.RegisteredGlowSpellNames[name]) then
        self.RegisteredGlowSpellIDs[spellID] = true;

        -- Awaken dormant buttons associated to this spellID
        self:AwakeButtonsBySpellID(spellID);
    end

    -- Also update ActivableCountersBySpellID if the name the tracked
    local counter = self.ActivableCountersByName[name];
    if (counter and not self.ActivableCountersBySpellID[spellID]) then
        self.ActivableCountersBySpellID[spellID] = counter;

        -- Try to see if action is usable now
        self:CheckCounterAction(spellID, unpack(counter));
    end
end

-- Spell ID tester that falls back on spell name testing if spell ID is zero
-- This function helps when the game client fails to give a spell ID
-- Ideally, this function should be pointless, but Classic Era has some issues
function SAO.IsSpellIdentical(self, spellID, spellName, referenceID)
    if spellID ~= 0 then
        return spellID == referenceID
    else
        return spellName == GetSpellInfo(referenceID)
    end
end

-- Test if the player is capable of casting a specific spell
-- For most game projects, it checks the IsPlayerSpell function
-- For Season of Discovery, it adds a specific check related to runes
function SAO.IsSpellLearned(self, spellID)
    if IsPlayerSpell(spellID) then
        return true;
    end
    if spellID >= 400000 and self.IsSoD() and self:IsRuneSpellLearned(spellID) then
        return true;
    end
    return false;
end

-- Get the time when the effect ends, or nil if it either does not end or we do not know when it will end
-- Returns either a table {startTime, endTime} or a single number endTime
function SAO.GetSpellEndTime(self, spellID, suggestedEndTime)
    if type(suggestedEndTime) == 'number'
    or type(suggestedEndTime) == 'table' and type(suggestedEndTime.endTime) == 'number' then
        return suggestedEndTime;
    end

    if (not self.Frame.useTimer) then
        return -- Return nil if there is no timer effect, to save CPU
    end

    local duration, expirationTime

    if type(spellID) == 'string' then
        -- spellID is a spell name
        _, _, _, _, duration, expirationTime = self:FindPlayerAuraByName(spellID);
    elseif type(spellID) == 'number' and spellID < 1000000 then -- spell IDs over 1000000 are fake ones
        -- spellID is a spell ID number
        _, _, _, _, duration, expirationTime = self:FindPlayerAuraByID(spellID);
    end

    if type(duration) == 'number' and type(expirationTime) == 'number' then
        local startTime, endTime = expirationTime-duration, expirationTime;
        return { startTime=startTime, endTime=endTime }
    elseif type(expirationTime) == 'number' then
        return expirationTime;
    end
end

-- Determine if the spell belongs is made up for internal purposes
function SAO.IsFakeSpell(self, spellID)
    if spellID >= 1000000 then
        -- Spell IDs over 1M are impossible for now
        return true
    end

    if (self.IsEra() or self.IsTBC() or self.IsWrath()) and spellID == 48107 then
        -- Mage's Heating Up does not exist in Era/TBC/Wrath
        return true
    end

    if spellID == 96215 then
        -- Hot Streak + Heating Up is made up
        return true
    end

    return false
end
