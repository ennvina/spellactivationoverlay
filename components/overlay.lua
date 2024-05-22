local AddonName, SAO = ...
local Module = "overlay"

-- Search in overlay options if the specified auraID should be discarded
-- By default, do *not* discard
-- This happens e.g., if there is no option for this auraID
-- @param optionIndex Main indexing of overlay in options
-- @param optionAnyStacks For aura triggers, the 'aura_stacks=any' counterpart
local function discardedByOverlayOption(self, auraID, optionIndex, optionAnyStacks)
    if (not SpellActivationOverlayDB) then
        return false; -- By default, do not discard
    end

    if (SpellActivationOverlayDB.alert and not SpellActivationOverlayDB.alert.enabled) then
        return true;
    end

    local overlayOptions = self:GetOverlayOptions(auraID);

    if (not overlayOptions) then
        return false; -- By default, do not discard
    end

    -- Look for option in the exact hash
    if optionIndex and type(overlayOptions[optionIndex]) ~= 'nil' then
        return not overlayOptions[optionIndex];
    elseif optionAnyStacks and type(overlayOptions[optionAnyStacks]) ~= 'nil' then
        return not overlayOptions[optionAnyStacks];
    end

    return false; -- By default, do not discard
end

-- Add or refresh an overlay
function SAO.ActivateOverlay(self, hashData, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly)
    if (texture) then
        -- Discard the overlay if options are not favorable
        if type(hashData) == 'number' then
            -- Legacy code
            local stacks = hashData;
            local fallbackAny = stacks > 0 and 0 or nil;
            if discardedByOverlayOption(self, spellID, stacks, fallbackAny) then
                return;
            end
        elseif type(hashData) == 'table' then
            -- Modern code
            local optionIndex, optionAnyStacks = hashData.optionIndex, hashData.optionAnyStacks;
            if discardedByOverlayOption(self, spellID, optionIndex, optionAnyStacks) then
                return;
            end
        else
            SAO:Warn(Module, "Unknown overlay hash-data type '"..type(hashData).."'");
        end

        -- Hack to avoid glowIDs to be treated as forcePulsePlay
        if (type(forcePulsePlay) == 'table') then
            forcePulsePlay = false;
        end

        -- Fetch texture from functor if needed
        if (type(texture) == 'function') then
            texture = texture(self);
        end

        -- Find when the effect ends, if it will end
        endTime = self:GetSpellEndTime(spellID, endTime);

        -- Actually show the overlay(s)
        self.ShowAllOverlays(self.Frame, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly);
    end
end

-- Remove an overlay
function SAO.DeactivateOverlay(self, spellID)
    self.HideOverlays(self.Frame, spellID);
end

-- Refresh the duration of an overlay
function SAO.RefreshOverlayTimer(self, spellID, endTime)
    endTime = self:GetSpellEndTime(spellID, endTime);
    if (endTime) then
        self.SetOverlayTimer(self.Frame, spellID, endTime);
    end
end
