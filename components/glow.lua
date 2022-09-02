local AddonName, SAO = ...

-- List of known ActionButton instances that currently match one of the spell IDs to track
-- This does not mean that buttons are glowing right now, but they could glow at any time
-- key = glowID (= spellID of action), value = list of ActionButton objects for this spell
-- (side note: the sublist of buttons is a map of key = action slot and value = button)
-- The list will change each time an action button changes, which may happen very often
-- For example, any macro with [mod:shift] updates the list every time Shift is pressed
SAO.ActionButtons = {}

-- Action buttons that are not tracked but could be tracked in the future
-- This re-track may happen if e.g. a new spell is learned or during delayed loading
SAO.DormantActionButtons = {}

-- List of spell IDs that should be currently glowing
-- key = glowID (= spellID of action), value = spellID of aura which triggered it recently
-- The list will change each time an overlay is triggered with a glowing effect
SAO.GlowingSpells = {}

-- List of spell IDs that should be tracked to glow action buttons
-- The spell ID may differ from the spell ID for the corresponding aura
-- key = glowID (= spell ID/name of the glowing spell), value = true
-- The lists should be setup at start, based on the player class
SAO.RegisteredGlowSpellIDs = {}

-- List of spell names that should be tracked to glow action buttons
-- This helps to fill RegisteredGlowSpellIDs e.g., when a spell is learned
SAO.RegisteredGlowSpellNames = {}

-- Register a list of glow ID
-- Each ID is either a numeric value (spellID) or a string (spellName)
function SAO.RegisterGlowIDs(self, glowIDs)
    for _, glowID in ipairs(glowIDs or {}) do
        if (type(glowID) == "number") then
            self.RegisteredGlowSpellIDs[glowID] = true;
        elseif (type(glowID) == "string") then
            if (not SAO.RegisteredGlowSpellNames[glowID]) then
                SAO.RegisteredGlowSpellNames[glowID] = true;
                local glowSpellIDs = self:GetSpellIDsByName(glowID);
                for _, glowSpellID in ipairs(glowSpellIDs) do
                    self.RegisteredGlowSpellIDs[glowSpellID] = true;
                end
            end
        end
    end
end

-- An action button has been updated
-- Check its old/new action and old/new spell ID, and put it in appropriate lists
-- If forceRefresh is true, refresh even if old spell ID and new spell ID are identical
-- Set forceRefresh if the spell ID of the button may switch from untracked to tracked (or vice versa) in light of recent events
function SAO.UpdateActionButton(self, button, forceRefresh)
    local oldAction = button.lastAction; -- Set by us, a few lines below
    local oldGlowID = button.lastGlowID; -- Set by us, a few lines below
    local newAction = button.action; -- Set by the game, inside Blizzard's ActionButton.lua
    local newGlowID = nil;
    if HasAction(button.action) then
        newGlowID = self:GetSpellIDByActionSlot(button.action);
    end
    button.lastAction = newAction; -- Write button.lastAction here, but use oldAction/newAction for the rest of the function
    button.lastGlowID = newGlowID; -- Write button.lastGlowID here, but use oldGlowID/newGlowID for the rest of the function

    if (oldGlowID == newGlowID and not forceRefresh) then
        -- Skip any processing if the glow ID hasn't changed
        return;
    end

    -- Register/unregister button as 'dormant' i.e., not tracked but could be tracked in the future
    if (oldGlowID and not self.RegisteredGlowSpellIDs[oldGlowID] and type(self.DormantActionButtons[oldGlowID]) == 'table') then
        if (self.DormantActionButtons[oldGlowID][oldAction] == button) then
            self.DormantActionButtons[oldGlowID][oldAction] = nil;
        end
    end
    if (newGlowID and not self.RegisteredGlowSpellIDs[newGlowID]) then
        if (type(self.DormantActionButtons[newGlowID]) == 'table') then
            if (self.DormantActionButtons[newGlowID][newAction] ~= button) then
                self.DormantActionButtons[newGlowID][newAction] = button;
            end
        else
            self.DormantActionButtons[newGlowID] = { [newAction] = button };
        end
    end

    if (not self.RegisteredGlowSpellIDs[oldGlowID] and not self.RegisteredGlowSpellIDs[newGlowID]) then
        -- Ignore action if it does not (nor did not) correspond to a tracked glowID
        return;
    end

    -- Untrack previous action button and track the new one
    if (oldGlowID and self.RegisteredGlowSpellIDs[oldGlowID] and type(self.ActionButtons[oldGlowID]) == 'table') then
        -- Detach action button from the former glow ID
        if (self.ActionButtons[oldGlowID][oldAction] == button) then
            self.ActionButtons[oldGlowID][oldAction] = nil;
        end
    end
    if (newGlowID and self.RegisteredGlowSpellIDs[newGlowID]) then
        if (type(self.ActionButtons[newGlowID]) == 'table') then
            -- Attach action button to the current glow ID
            if (self.ActionButtons[newGlowID][newAction] ~= button) then
                self.ActionButtons[newGlowID][newAction] = button;
            end
        else
            -- This glow ID has no Action Buttons yet: be the first
            self.ActionButtons[newGlowID] = { [newAction] = button };
        end
        -- Remove from the 'dormant' table, if it was dormant
        if (type(self.DormantActionButtons[newGlowID]) == 'table' and self.DormantActionButtons[newGlowID][newAction] == button) then
            self.DormantActionButtons[newGlowID][newAction] = nil;
        end
    end

    -- Glow or un-glow, if needed
    local wasGlowing = oldGlowID and (self.GlowingSpells[oldGlowID] ~= nil);
    local mustGlow = newGlowID and (self.GlowingSpells[newGlowID] ~= nil);

    if (not wasGlowing and mustGlow) then
        ActionButton_ShowOverlayGlow(button);
    elseif (wasGlowing and not mustGlow) then
        ActionButton_HideOverlayGlow(button);
    end
end

-- Grab all action button activity that allows us to know which button has which spell
function HookActionButton_Update(self)
    if (self:GetParent() == OverrideActionBar) then
        -- Act on all buttons but the ones from OverrideActionBar, whatever that is
        return;
    end

    SAO:UpdateActionButton(self);
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

-- Awake dormant buttons associated to a spellID
function SAO.AwakeButtonsBySpellID(self, spellID)
    local dormantButtons = {};
    for _, button in pairs(self.DormantActionButtons[spellID] or {}) do
        table.insert(dormantButtons, button);
    end
    for _, button in ipairs(dormantButtons) do
        self:UpdateActionButton(button, true);
    end
end

-- Add a glow effect for action buttons matching the given glow ID
-- @param glowID spell identifier of the glow; must be a number
function SAO.AddGlowNumber(self, spellID, glowID)
    local actionButtons = self.ActionButtons[glowID];
    if (self.GlowingSpells[glowID]) then
        self.GlowingSpells[glowID][spellID] = true;
    else
        self.GlowingSpells[glowID] = { [spellID] = true };
        for _, frame in pairs(actionButtons or {}) do
            ActionButton_ShowOverlayGlow(frame);
        end
    end
end

-- Add a glow effect for action buttons matching one of the given glow IDs
-- Each glow ID may be a spell identifier (number) or spell name (string)
function SAO.AddGlow(self, spellID, glowIDs)
    if (glowIDs == nil) then
        return;
    end

    for _, glowID in ipairs(glowIDs) do
        if (type(glowID) == "number") then
            -- glowID is a direct spell identifier
            self:AddGlowNumber(spellID, glowID);
        elseif (type(glowID) == "string") then
            -- glowID is a spell name: find spell identifiers first, then parse them
            local glowSpellIDs = self:GetSpellIDsByName(glowID);
            for _, glowSpellID in ipairs(glowSpellIDs) do
                self:AddGlowNumber(spellID, glowSpellID);
            end
        end
    end
end

-- Remove the glow effect for action buttons matching any of the given spell IDs
function SAO.RemoveGlow(self, spellID)
    local consumedGlowSpellIDs = {};

    -- First, gather each glowSpellID attached to spellID
    for glowSpellID, triggerSpellIDs in pairs(self.GlowingSpells) do
        if (triggerSpellIDs[spellID]) then
            -- spellID is attached to this glowSpellID
            -- Gather how many triggers are attached to the same glowSpellID (spellID included)
            local count = 0;
            for _, _  in pairs(triggerSpellIDs) do
                count = count+1;
            end
            consumedGlowSpellIDs[glowSpellID] = count;
        end
    end

    -- Then detach the spellID <-> glowSpellID link
    -- And remove the glow if and only if the trigger was the last one asking to glow
    for glowSpellID, count in pairs(consumedGlowSpellIDs) do
        if (count > 1) then
            -- Only detach
            self.GlowingSpells[glowSpellID][spellID] = nil;
        else
            -- Detach and un-glow
            self.GlowingSpells[glowSpellID] = nil;
            local actionButtons = self.ActionButtons[glowSpellID];
            for _, frame in pairs(actionButtons or {}) do
                ActionButton_HideOverlayGlow(frame);
            end
        end
    end
end
