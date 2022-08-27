local AddonName, SAO = ...

-- List of known ActionButton instances that currently match one of the spell IDs to track
-- This does not mean that buttons are glowing right now, but they could glow at any time
-- key = glowID (= spellID of action), value = list of ActionButton objects for this spell
-- (side note: the sublist of buttons is a map of key = action slot and value = button)
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
    if (self:GetParent() == OverrideActionBar) then
        -- Act on all buttons but the ones from OverrideActionBar, whatever that is
        return
    end

    local oldAction = self.lastAction; -- Set by us, a few lines below
    local oldGlowID = nil;
    if (oldAction) then
        oldGlowID = SAO.GlowIDByActionSlot[oldAction];
    end
    local newAction = self.action; -- Set by the game, inside Blizzard's ActionButton.lua
    local newGlowID = nil;
    if HasAction(self.action) then
        newGlowID = SAO:GetSpellIDByActionSlot(self.action);
    end
    self.lastAction = self.action; -- Write self.lastAction here, but use oldAction/newAction for the rest of the function

    if (oldGlowID == newGlowID) then
        -- Skip any processing if the glow ID hasn't changed

        -- Former code for potential button overwrites, but it should not happen again now that we exclude children of OverrideActionBar
        -- if (SAO.RegisteredGlowIDs[newGlowID] and type(SAO.ActionButtons[newGlowID]) == 'table' and SAO.ActionButtons[oldGlowID][oldAction] ~= self) then
        --     SAO.ActionButtons[oldGlowID][oldAction] = self;
        -- end
        return
    end

    if (not SAO.RegisteredGlowIDs[oldGlowID] and not SAO.RegisteredGlowIDs[newGlowID]) then
        -- Ignore action if it does not (nor did not) correspond to a tracked glowID
        return
    end

    -- Untrack previous action button and track the new one
    if (oldGlowID and SAO.RegisteredGlowIDs[oldGlowID] and type(SAO.ActionButtons[oldGlowID]) == 'table') then
        -- Detach action button from the former glow ID
        if (SAO.ActionButtons[oldGlowID][oldAction] == self) then
            SAO.ActionButtons[oldGlowID][oldAction] = nil;
        end
    end
    if (newGlowID and SAO.RegisteredGlowIDs[newGlowID]) then
        if (type(SAO.ActionButtons[newGlowID]) == 'table') then
            -- Attach action button to the current glow ID
            if (SAO.ActionButtons[newGlowID][newAction] ~= self) then
                SAO.ActionButtons[newGlowID][newAction] = self;
            end
        else
            -- This glow ID has no Action Buttons yet: be the first
            SAO.ActionButtons[newGlowID] = { [newAction] = self };
        end
    end
    SAO.GlowIDByActionSlot[newAction] = newGlowID;

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

-- Also look for specific events for bar swaps when e.g. entering/leaving stealth
-- Not sure if it is really necessary, but in theory it will do nothing at worst
function HookActionButton_OnEvent(self, event)
    if (event == "ACTIONBAR_PAGE_CHANGED" or event == "UPDATE_BONUS_ACTIONBAR") then
        HookActionButton_Update(self);
    end
end
hooksecurefunc("ActionButton_OnEvent", HookActionButton_OnEvent);

-- Add a glow effect for action buttons matching one of the given spell IDs
function SAO.AddGlow(self, spellID, glowIDs)
    if (glowIDs == nil) then
        return
    end

    for _, glowID in ipairs(glowIDs) do
        local actionButtons = self.ActionButtons[glowID];
        for _, frame in pairs(actionButtons or {}) do
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
            for _, frame in pairs(actionButtons or {}) do
                ActionButton_HideOverlayGlow(frame);
            end
            table.insert(usedGlowIDs, glowID);
        end
    end
    for _, glowID in ipairs(usedGlowIDs) do
        self.GlowingSpells[glowID] = nil;
    end
end
