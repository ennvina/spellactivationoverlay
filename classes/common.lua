local AddonName, SAO = ...

-- List of classes
-- Each class defines its own stuff in their <classname>.lua
SAO.Class = {}

--[[
    Lists of auras that must be tracked
    These lists should be setup at start, based on the player class

    The name should be unique
    For stackable buffs, the stack count should be appended e.g., maelstrom_weapon_4

    Spell IDs may not be unique, especially for stackable buffs
    Because of that, RegisteredAurasBySpellID is a multimap instead of a map
]]
SAO.RegisteredAurasByName = {}
SAO.RegisteredAurasBySpellID = {}

-- List of currently active overlays
-- This list will change each time an overlay is triggered or un-triggered
SAO.ActiveOverlays = {}

-- Utility function to register a new aura
-- Arguments simply need to copy Retail's SPELL_ACTIVATION_OVERLAY_SHOW event arguments
function SAO.RegisterAura(self, name, stacks, spellID, texture, positions, scale, r, g, b)
    local aura = { name, stacks, spellID, self.TexName[texture], positions, scale, r, g, b }
    self.RegisteredAurasByName[name] = aura;
    if self.RegisteredAurasBySpellID[spellID] then
        self.RegisteredAurasBySpellID[spellID][stacks] = aura;
    else
        self.RegisteredAurasBySpellID[spellID] = { [stacks] = aura }
    end
end

-- Utility aura function, one of the many that Blizzard could've done better years ago...
function SAO.FindPlayerAuraByID(self, id)
    local i = 1
    local name, icon, count, dispelType, duration, expirationTime,
        source, isStealable, nameplateShowPersonal, spellId,
        canApplyAura, isBossDebuff, castByPlayer = UnitBuff("player", i);
    while name do
        if (spellId == id) then
            return name, icon, count, dispelType, duration, expirationTime,
                source, isStealable, nameplateShowPersonal, spellId,
                canApplyAura, isBossDebuff, castByPlayer;
        end
        i = i+1
        name, icon, count, dispelType, duration, expirationTime,
            source, isStealable, nameplateShowPersonal, spellId,
            canApplyAura, isBossDebuff, castByPlayer = UnitBuff("player", i);
    end
end

--[[
    Utility function to know how many talent points the player has spent on a specific talent

    If the talent is found, returns:
    - the number of points spent for this talent
    - the total number of points possible for this talent
    - the tabulation in which the talent was found
    - the index in which the talent was found
    Tabulation and index can be re-used in GetTalentInfo to avoid re-parsing all talents

    Returns nil if no talent is found with this name e.g., in the wrong expansion
]]
function SAO.GetTalentByName(self, talentName)
    for tab = 1, GetNumTalentTabs() do
        for index = 1, GetNumTalents(tab) do
            local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(tab, index);
            if (name == talentName) then
                return rank, maxRank, tab, index;
            end
        end
    end
end

-- Add or refresh an overlay
function SAO.ActivateOverlay(self, stacks, spellID, texture, positions, scale, r, g, b)
    self.ActiveOverlays[spellID] = stacks;
    self.ShowAllOverlays(self.Frame, spellID, texture, positions, scale, r, g, b);
end

-- Remove an overlay
function SAO.DeactivateOverlay(self, spellID)
    self.ActiveOverlays[spellID] = nil;
    self.HideOverlays(self.Frame, spellID);
end

-- Event UNIT_AURA
-- Former code, removed for performance reasons
-- Source code kept, in case there exists a buff overlay that can't be tracked by CLEU
function SAO.UNIT_AURA(self, ...)
    -- Not used anymore
    --[[
    for name, aura in pairs(self.RegisteredAurasByName) do
        local spellID = aura[3];
        local auraFound = SAO.FindPlayerAuraByID(spellID);
        if (not SAO.ActiveOverlays[spellID] and auraFound) then
            -- Aura just appeared
            self:ActivateOverlay(0, select(3,unpack(aura)));
        elseif (SAO.ActiveOverlays[spellID] and not auraFound) then
            -- Aura just disappeared
            self:DeactivateOverlay(spellID);
        end
    end
    ]]
end

-- Events starting with SPELL_AURA e.g., SPELL_AURA_APPLIED
-- This should be invoked only if the buff is done on the player i.e., UnitGUID("player") == destGUID
function SAO.SPELL_AURA(self, ...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo();
    local spellID, spellName, spellSchool, auraType, amount = select(12, CombatLogGetCurrentEventInfo());
    local auraApplied = event:sub(0,18) == "SPELL_AURA_APPLIED";
    local auraRemoved = event:sub(0,18) == "SPELL_AURA_REMOVED";

    local auras = self.RegisteredAurasBySpellID[spellID];
    if auras and (auraApplied or auraRemoved) then
        local currentlyActiveOverlay = self.ActiveOverlays[spellID];
        local nbStacks = amount or 0;
        if (
            -- Aura is there
            auraApplied
        and
            -- Aura just appeared or the number of stacks just changed
            (not currentlyActiveOverlay or currentlyActiveOverlay  ~= amount)
        and
            -- The number of stacks is supported
            (auras[nbStacks])
        ) then
            self:ActivateOverlay(nbStacks, select(3,unpack(auras[nbStacks])));
        elseif (currentlyActiveOverlay) then
            -- Aura just disappeared or is not supported for this number of stacks
            self:DeactivateOverlay(spellID);
        end
        -- print(timestamp, event, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType, amount);
    end
end

-- The (in)famous CLEU event
function SAO.COMBAT_LOG_EVENT_UNFILTERED(self, ...)
    local _, event, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo();

    if ( (event:sub(0,11) == "SPELL_AURA_") and (destGUID == UnitGUID("player")) ) then
        self:SPELL_AURA(...);
    end
end

-- Event receiver
function SAO.OnEvent(self, event, ...)
    if self[event] then
        self[event](self, ...);
    end
    if (self.CurrentClass and self.CurrentClass[event]) then
        self.CurrentClass[event](self, ...);
    end
end
