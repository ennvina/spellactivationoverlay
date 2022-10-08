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
function SAO.ActivateOverlay(self, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay)
    if (texture) then
        if (discardedByOverlayOption(self, spellID, stacks)) then
            return;
        end
        if (type(forcePulsePlay) == 'table') then -- Hack to avoid glowIDs to be treated as forcePulsePlay
            forcePulsePlay = false;
        end
        self.ActiveOverlays[spellID] = stacks;
        self.ShowAllOverlays(self.Frame, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay);
    end
end

-- Remove an overlay
function SAO.DeactivateOverlay(self, spellID)
    self.ActiveOverlays[spellID] = nil;
    self.HideOverlays(self.Frame, spellID);
end
