local AddonName, SAO = ...
local Module = "overlay"

-- Search in overlay options if the specified auraID should be discarded
-- By default, do *not* discard
-- This happens e.g., if there is no option for this auraID
-- @param hashName The standard, modern way of indexing overlays in options
-- @param hashAny For aura triggers, the 'aura_stacks=any' counterpart
-- @param fallbackIndex Legacy index, formerly 'stacks'
-- If fallbackIndex is set, it means the overlay's bucket is triggered exclusively by auras
local function discardedByOverlayOption(self, auraID, hashName, hashAny, fallbackIndex)
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
    if hashName and type(overlayOptions[hashName]) ~= 'nil' then
        return not overlayOptions[hashName];
    elseif hashAny and type(overlayOptions[hashAny]) ~= 'nil' then
        return not overlayOptions[hashAny];
    elseif fallbackIndex then
        if type(overlayOptions[fallbackIndex]) ~= 'nil' then
            return not overlayOptions[fallbackIndex];
        elseif fallbackIndex > 0 and type(overlayOptions[0]) ~= "nil" then
            return not overlayOptions[0];
        end
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
            if discardedByOverlayOption(self, spellID, nil, nil, stacks) then
                return;
            end
        elseif type(hashData) == 'table' and type(hashData.hashName) == 'string' then
            -- Modern code
            local hashName, hashAny, fallbackIndex = hashData.hashName, hashData.hashAny, hashData.fallbackIndex;
            if discardedByOverlayOption(self, spellID, hashName, hashAny, fallbackIndex) then
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
