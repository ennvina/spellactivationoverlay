local AddonName, SAO = ...

-- List of known ActionButton instances that currently match one of the spell IDs to track
-- This does not mean that buttons are glowing right now, but they could glow at any time
-- key = glowID (= spellID of action), value = list of ActionButton objects for this spell
-- The list will change each time an action button changes, which may happen very often
-- For example, any macro with [mod:shift] updates the list every time Shift is pressed
SAO.ActionButtons = {}

-- List of the last known glow ID for each action slot that was tracked
SAO.GlowIDByActionSlot = {}

-- List of spell IDs that should be currently glowing
-- key = glowID (= spellID of action), value = spellID of aura which triggered it recently
-- The list will change each time an overlay is triggered with a glowing effect
SAO.GlowingSpells = {}

-- Grab all action button activity that allows us to know which button has which spell
function HookActionButton_Update(self)
    local oldGlowID = SAO.GlowIDByActionSlot[self.action];
    local newGlowID = nil;
    if HasAction(self.action) then
        newGlowID = SAO:GetSpellIDByActionSlot(self.action);
    end
    if (oldGlowID == newGlowID) then
        -- Skip any processing if the glow ID hasn't changed
        return
    end
    if (not SAO.RegisteredGlowIDs[oldGlowID] and not SAO.RegisteredGlowIDs[newGlowID]) then
        -- Ignore action if it does not (nor did not) correspond to a tracked glowID
        return
    end

    -- Untrack previous action button and track the new one
    if (oldGlowID and SAO.RegisteredGlowIDs[oldGlowID] and type(SAO.ActionButtons[oldGlowID]) == 'table') then
        -- Detach action button from the former glow ID
        local foundIndex = nil;
        for i, frame in ipairs(SAO.ActionButtons[oldGlowID]) do
            if (frame == self) then
                foundIndex = i;
            end
        end
        if (foundIndex) then -- Should always pass, in theory
            table.remove(SAO.ActionButtons[oldGlowID], foundIndex);
        end
    end
    if (newGlowID and SAO.RegisteredGlowIDs[newGlowID]) then
        if (type(SAO.ActionButtons[newGlowID]) == 'table') then
            -- Attach action button to the current glow ID
            local foundIndex = nil;
            for i, frame in ipairs(SAO.ActionButtons[newGlowID]) do
                if (frame == self) then
                    foundIndex = i;
                end
            end
            if (not foundIndex) then -- Should always pass, in theory
                table.insert(SAO.ActionButtons[newGlowID], self);
            end
        else
            -- This glow ID has no Action Buttons yet: be the first
            SAO.ActionButtons[newGlowID] = { self };
        end
    end
    SAO.GlowIDByActionSlot[self.action] = newGlowID;

    -- Glow or un-glow, if needed
    local wasGlowing = oldGlowID and (SAO.GlowingSpells[oldGlowID] ~= nil)
    local mustGlow = newGlowID and (SAO.GlowingSpells[newGlowID] ~= nil)

    if (not wasGlowing and mustGlow) then
        ActionButton_ShowOverlayGlow(self);
    elseif (wasGlowing and not mustGlow) then
        ActionButton_HideOverlayGlow(self);
    end
end
hooksecurefunc("ActionButton_Update", HookActionButton_Update);

-- Add a glow effect for action buttons matching one of the given spell IDs
function SAO.AddGlow(self, spellID, glowIDs)
    if (glowIDs == nil) then
        return
    end

    for _, glowID in ipairs(glowIDs) do
        local actionButtons = self.ActionButtons[glowID];
        for _, frame in ipairs(actionButtons or {}) do
            ActionButton_ShowOverlayGlow(frame);
        end
        self.GlowingSpells[glowID] = spellID;
    end
end

-- Remove the glow effect for action buttons matching any of the given spell IDs
function SAO.RemoveGlow(self, spellID)
    local usedGlowIDs = {}
    for glowID, auraID in pairs(self.GlowingSpells) do
        if (auraID == spellID) then
            local actionButtons = self.ActionButtons[glowID];
            for _, frame in ipairs(actionButtons or {}) do
                ActionButton_HideOverlayGlow(frame);
            end
            table.insert(usedGlowIDs, glowID);
        end
    end
    for _, glowID in ipairs(usedGlowIDs) do
        self.GlowingSpells[glowID] = nil;
    end
end
