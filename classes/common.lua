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
function SAO.FindPlayerAuraByID(id)
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

function SAO.UNIT_AURA(self, ...)
    -- Not used anymore
    --[[
    for name, aura in pairs(self.RegisteredAurasByName) do
        local spellID = aura[3];
        local auraFound = SAO.FindPlayerAuraByID(spellID);
        if (not SAO.ActiveOverlays[spellID] and auraFound) then
            -- Aura just appeared
            SAO.ActiveOverlays[spellID] = true;
            self.ShowAllOverlays(self.Frame, select(3,unpack(aura)));
        elseif (SAO.ActiveOverlays[spellID] and not auraFound) then
            -- Aura just disappeared
            SAO.ActiveOverlays[spellID] = nil;
            self.HideOverlays(self.Frame, spellID);
        end
    end
    ]]
end

function SAO.COMBAT_LOG_EVENT_UNFILTERED(self, ...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo();
    if (event ~= "SPELL_AURA_APPLIED" and event ~= "SPELL_AURA_REMOVED") then return end
    if (destGUID ~= UnitGUID("player")) then return end

    local spellID, spellName, spellSchool, auraType, amount = select(12, CombatLogGetCurrentEventInfo());
    local auras = self.RegisteredAurasBySpellID[spellID];
    if auras then
        local currentlyActiveOverlay = SAO.ActiveOverlays[spellID];
        if (
            -- Aura is there
            event == "SPELL_AURA_APPLIED"
        and
            -- Aura just appeared or the number of stacks just changed
            (not currentlyActiveOverlay or currentlyActiveOverlay  ~= amount)
        and
            -- The number of stacks is supported
            (auras[amount or 0])
        ) then
            SAO.ActiveOverlays[spellID] = amount or 0;
            self.ShowAllOverlays(self.Frame, select(3,unpack(auras[amount or 0])));
        elseif (currentlyActiveOverlay) then
            -- Aura just disappeared or is not supported for this number of stacks
            SAO.ActiveOverlays[spellID] = nil;
            self.HideOverlays(self.Frame, spellID);
        end
        -- print(timestamp, event, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags, spellID, spellName, spellSchool, auraType, amount);
    end
end

-- Event receiver
function SAO.OnEvent(self, event, ...)
    if self[event] then
        self[event](self, ...)
    end
end
