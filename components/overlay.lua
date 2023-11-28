local AddonName, SAO = ...

-- List of currently active overlays
-- key = spellID, value = aura config
-- This list will change each time an overlay is triggered or un-triggered
SAO.ActiveOverlays = {}

-- Check if overlay is active
function SAO.GetActiveOverlay(self, spellID)
    return self.ActiveOverlays[spellID] ~= nil;
end

-- Search in overlay options if the specified auraID should be discarded
-- By default, do *not* discard
-- This happens e.g., if there is no option for this auraID
local function discardedByOverlayOption(self, auraID, stacks)
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

    -- Look for option in the exact stack count
    if (type(overlayOptions[stacks]) ~= "nil") then
        return not overlayOptions[stacks];
    end

    -- Look for a default option as if stacks == 0
    if (stacks and stacks > 0 and type(overlayOptions[0]) ~= "nil") then
        return not overlayOptions[0];
    end

    return false; -- By default, do not discard
end

-- Add or refresh an overlay
function SAO.ActivateOverlay(self, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime)
    if (texture) then
        -- Tell the overlay is active, even though the overlay may be discarded below
        -- This "active state" tells the aura is in place, which is used by e.g. the glowing button system
        self.ActiveOverlays[spellID] = stacks;

        -- Discard the overlay if options are not favorable
        if (discardedByOverlayOption(self, spellID, stacks)) then
            return;
        end

        -- Hack to avoid glowIDs to be treated as forcePulsePlay
        if (type(forcePulsePlay) == 'table') then
            forcePulsePlay = false;
        end

        -- Fetch texture from functor if needed
        if (type(texture) == 'function') then
            texture = texture(self);
        end

        -- Find whe the effect ends, if it will end
        if (type(endTime) ~= 'number') then
            -- @todo do not fetch endTime if option is disabled, because this fetch may have a significant CPU cost
            if type(spellID) == 'string' then
                -- spellID is a spell name
                endTime = select(6, self:FindPlayerAuraByName(spellID));
            elseif type(spellID) == 'number' and spellID < 1000000 then -- spell IDs over 1000000 are fake ones
                -- spellID is a spell ID number
                endTime = select(6, self:FindPlayerAuraByID(spellID));
            end
        end

        -- Actually show the overlay(s)
        self.ShowAllOverlays(self.Frame, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime);
    end
end

-- Remove an overlay
function SAO.DeactivateOverlay(self, spellID)
    self.ActiveOverlays[spellID] = nil;
    self.HideOverlays(self.Frame, spellID);
end
