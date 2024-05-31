local AddonName, SAO = ...
local Module = "aura"

-- Promote aura with variables easier total access
local function promoteAura(aura)
    aura.name = aura[1];
    aura.stacks = aura[2];
    aura.spellID = aura[3];
    if aura[4] then
        aura.overlay = {
            spellID = aura[3],
            texture = aura[4],
            position = aura[5],
            scale = aura[6],
            color = { aura[7], aura[8], aura[9] },
            autoPulse = aura[10],
            combatOnly = aura[13],
        }
    end
    if aura[11] then
        aura.buttons = aura[11];
    end
    aura.combatOnly = aura[13];
end

-- Register a new aura
-- If texture is nil, no Spell Activation Overlay (SAO) is triggered; subsequent params are ignored until glowIDs
-- If texture is a function, it will be evaluated at runtime when the SAO is triggered
-- If glowIDs is nil or empty, no Glowing Action Button (GAB) is triggered
-- All SAO arguments (between spellID and b, included) mimic Retail's SPELL_ACTIVATION_OVERLAY_SHOW event arguments
function SAO.RegisterAura(self, name, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, glowIDs, combatOnly)
    if (type(texture) == 'string') then
        texture = self.TexName[texture];
    end
    local aura = { name, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, glowIDs, nil, combatOnly }
    promoteAura(aura);

    if (type(texture) == 'string') then
        self:MarkTexture(texture);
    end

    -- Register the glow IDs
    -- The same glow ID may be registered by different auras, but it's okay
    self:RegisterGlowIDs(glowIDs);

    -- Register aura in the spell list, sorted by spell ID and by stack count
    -- Visuals are displayed is shown if the player currently has the aura with the required stack count
    SAO.BucketManager:addAura(aura);
end
