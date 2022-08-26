local AddonName, SAO = ...

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

-- List of spell IDs that should be tracked to glow action buttons
-- The spell ID may differ from the spell ID for the corresponding aura
-- key = glowID (= spell ID of the glowing spell), value = true
-- The lists should be setup at start, based on the player class
SAO.RegisteredGlowIDs = {}

-- Register a new aura
-- All arguments before autoPulse simply need to copy Retail's SPELL_ACTIVATION_OVERLAY_SHOW event arguments
function SAO.RegisterAura(self, name, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, glowIDs)
    local aura = { name, stacks, spellID, self.TexName[texture], positions, scale, r, g, b, autoPulse, glowIDs }

    -- Register aura in the spell list, sorted by spell ID and by stack count
    self.RegisteredAurasByName[name] = aura;
    if self.RegisteredAurasBySpellID[spellID] then
        if self.RegisteredAurasBySpellID[spellID][stacks] then
            table.insert(self.RegisteredAurasBySpellID[spellID][stacks], aura)
        else
            self.RegisteredAurasBySpellID[spellID][stacks] = { aura };
        end
    else
        self.RegisteredAurasBySpellID[spellID] = { [stacks] = { aura } }
    end

    -- Register the glow IDs
    -- The same glow ID may be registered by different auras, but it's okay
    for _, glowID in ipairs(glowIDs or {}) do
        self.RegisteredGlowIDs[glowID] = true;
    end

    -- Apply aura immediately, if found
    local exists, _, count = select(3, self:FindPlayerAuraByID(spellID));
    if (exists and (stacks == 0 or stacks == count)) then
        self:ActivateOverlay(count, select(3,unpack(aura)));
        self:AddGlow(spellID, select(11,unpack(aura)));
    end
end