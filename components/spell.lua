local AddonName, SAO = ...

-- Optimize frequent calls
local GetSpellCooldownLegacy = GetSpellCooldown
local GetSpellCooldownModern = C_Spell and C_Spell.GetSpellCooldown
local GetSpellInfoLegacy = GetSpellInfo
local GetSpellInfoModern = C_Spell and C_Spell.GetSpellInfo
local GetSpellPowerCost = C_Spell and C_Spell.GetSpellPowerCost or GetSpellPowerCost -- Unlike functions like GetSpellInfo, this one is identical between Legacy and Modern
local IsSpellKnownOrOverridesKnown = IsSpellKnownOrOverridesKnown

-- Deprecation workaround
-- https://www.townlong-yak.com/framexml/64133/Blizzard_DeprecatedSpellBook/Deprecated_SpellBook.lua#22
if C_SpellBook and C_SpellBook.IsSpellInBook then
    IsSpellKnownOrOverridesKnown = function(spellID)
        return C_SpellBook.IsSpellInBook(spellID, false, true);
    end
end

-- List of spell IDs sharing the same name
-- key = spell name, value = list of spell IDs
-- The list is a cache of calls to GetSpellIDsByName
-- The list will evolve automatically when the player learns new spells
SAO.SpellIDsByName = {}

-- Check if a spell exists for a given spell ID
-- Returns true if the spell exists, false otherwise
function SAO:DoesSpellExist(spellID)
    if GetSpellInfoModern then
        local spellInfo = GetSpellInfoModern(spellID);
        return spellInfo ~= nil;
    end

    local spellName = GetSpellInfoLegacy(spellID);
    return spellName ~= nil;
end

-- Get the spell name for a given spell ID
-- Returns the spell name, or defaultName if the spell does not exist
function SAO:GetSpellName(spellID, defaultName)
    if GetSpellInfoModern then
        local spellInfo = GetSpellInfoModern(spellID);
        return spellInfo and spellInfo.name or defaultName;
    end

    local spellName = GetSpellInfoLegacy(spellID);
    return spellName or defaultName;
end

-- Get the in-game string representing spell icon and name for a given spell ID
function SAO:GetSpellIconAndText(spellID)
    if GetSpellInfoModern then
        local spellInfo = GetSpellInfoModern(spellID);
        if spellInfo then
            local spellName, spellIcon = spellInfo.name, spellInfo.iconID;
            return "|T"..spellIcon..":0|t "..spellName;
        end
        return nil;
    end

    local spellName, _, spellIcon = GetSpellInfoLegacy(spellID);
    if spellName then
        return "|T"..spellIcon..":0|t "..spellName;
    end
    return nil;
end

-- Get the cooldown start time and duration for a given spell ID
function SAO:GetSpellCooldown(spellID)
    if GetSpellCooldownModern then
        local cooldownInfo = GetSpellCooldownModern(spellID);
        if cooldownInfo == nil then
            return nil, nil;
        end
        return cooldownInfo.startTime, cooldownInfo.duration;
    end

    local startTime, duration = GetSpellCooldownLegacy(spellID);
    return startTime, duration;
end

-- Get the power cost table for a given spell ID
function SAO:GetSpellPowerCost(spellID)
    return GetSpellPowerCost(spellID);
end

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
        for _, spellID in ipairs(homonyms) do
            -- Glowing Action Buttons (GABs)
            if (not self.RegisteredGlowSpellIDs[spellID]) then
                self.RegisteredGlowSpellIDs[spellID] = true;
                self:AwakeButtonsBySpellID(spellID);
            end
        end
    end
end

-- Update the spell cache when a new spell is learned
function SAO:LearnNewSpell(spellID)
    local name = self:GetSpellName(spellID);
    if not name then
        return;
    end

    local cached = self.SpellIDsByName[name];
    if not cached then
        -- Not interested in untracked spells
        return;
    end

    for _, id in ipairs(cached) do
        if id == spellID then
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
end

-- Spell ID tester that falls back on spell name testing if spell ID is zero
-- This function helps when the game client fails to give a spell ID
-- Ideally, this function should be pointless, but Classic Era has some issues
-- @param spellID spell ID from CLEU
-- @param spellName spell name from CLEU
-- @param referenceID spell ID of the spell we want to compare with CLEU
function SAO:IsSpellIdentical(spellID, spellName, referenceID)
    if spellID ~= 0 then
        return spellID == referenceID
    else
        return spellName == self:GetSpellName(referenceID)
    end
end

local canHaveMultipleRanks = SAO.IsProject(SAO.ALL_PROJECTS - SAO.CATA_AND_ONWARD);
-- Test if the player is capable of casting a specific spell
function SAO:IsSpellLearned(spellID)
    if IsSpellKnownOrOverridesKnown(spellID) then
        return true;
    end
    if canHaveMultipleRanks then
        local spellName = self:GetSpellName(spellID);
        for _, spellID in ipairs(self.SpellIDsByName[spellName] or {}) do
            if IsSpellKnownOrOverridesKnown(spellID) then
                return true;
            end
        end
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

    local duration, expirationTime = self:GetPlayerAuraDurationExpirationTimBySpellIdOrName(spellID);

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

    if (self.IsEra() or self.IsTBC() or self.IsWrath() or self.IsCata()) and spellID == 48107 then
        -- Mage's Heating Up does not exist in Era/TBC/Wrath/Cata
        return true
    end

    if spellID == 96215 then
        -- Hot Streak + Heating Up is made up
        return true
    end

    return false
end
