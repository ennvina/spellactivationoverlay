local AddonName, SAO = ...
local Module = "glow"

-- Optimize frequent calls
--local ActionButton_HideOverlayGlow = ActionButton_HideOverlayGlow -- Native glow disabled to avoid taints
--local ActionButton_ShowOverlayGlow = ActionButton_ShowOverlayGlow -- Native glow disabled to avoid taints
local GetNumShapeshiftForms = GetNumShapeshiftForms
local GetSpellInfo = GetSpellInfo
local HasAction = HasAction

--[[
Each ActionButton will be granted an object .__sao which holds:
- .useExternalGlow, a boolean that tells if the glow is handled by an external library, not by 'us'
- .GetGlowID, a function that fetches the current spell ID bound to the button
- .EnableGlow, a function that starts the glow
- .DisableGlow, a function that stops the glow
- .oldGlowID (optional), the last known ID returned by .GetGlowID
- .startTimer (optional), the timer that starts a delayed call of .EnableGlow
]]

-- List of known ActionButton instances that currently match one of the spell IDs to track
-- This does not mean that buttons are glowing right now, but they could glow at any time
-- key = glowID (= spellID of action), value = list of ActionButton objects for this spell
-- (side note: the sublist of buttons is a table of key = button and a dummy value = true)
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
-- This helps fill or re-fill RegisteredGlowSpellIDs when e.g. a new spell rank is learned
SAO.RegisteredGlowSpellNames = {}

-- Register a glow ID
-- Each ID is either a numeric value (spellID) or a string (spellName)
function SAO.RegisterGlowID(self, glowID)
    if (type(glowID) == "number") then
        self.RegisteredGlowSpellIDs[glowID] = true;
        self:AwakeButtonsBySpellID(glowID);
    elseif (type(glowID) == "string") then
        if (not SAO.RegisteredGlowSpellNames[glowID]) then
            SAO.RegisteredGlowSpellNames[glowID] = true;
            local glowSpellIDs = self:GetSpellIDsByName(glowID);
            for _, glowSpellID in ipairs(glowSpellIDs) do
                self.RegisteredGlowSpellIDs[glowSpellID] = true;
                self:AwakeButtonsBySpellID(glowSpellID);
            end
        end
    end
end

-- Register a list of glow ID
-- Each ID is either a numeric value (spellID) or a string (spellName)
function SAO.RegisterGlowIDs(self, glowIDs)
    for _, glowID in ipairs(glowIDs or {}) do
        self:RegisterGlowID(glowID);
    end
end

--[[
    The GlowEngine object accepts requests to enable to disable glow for SAO
    It also tracks buttons glowing or not glowing from Native glows
    To avoid conflict between SAO and Native glows, SAO glow is only enabled when Native is not
    PS. This object is enabled for Cataclysm and later, because Native glow was introduced in Cataclysm
]]
local GlowEngine = SAO.IsProject(SAO.CATA_AND_ONWARD) and {
    SAOGlows = {}, -- Key/value pairs: key = glowID, value = { [frame1] = isGlowingByUs }, { [frame2] = isGlowingByUs }
    NativeGlows = {}, -- Key/value pairs: key = glowID, value = true

    FrameName = function(self, frame)
        return tostring(frame and frame.GetName and frame:GetName() or "");
    end,

    SpellInfo = function(self, glowID)
        return tostring(glowID).." ("..tostring(GetSpellInfo(glowID))..")";
    end,

    ParamName = function(self, frame, glowID)
        return self:FrameName(frame)..", "..self:SpellInfo(glowID);
    end,

    BeginGlowFinally = function(self, frame)
        if frame.__sao.startTimer == nil then -- If startTimer is not nil, then a EnableGlow is already planned
            frame.__sao.startTimer = C_Timer.NewTimer(
                SAO:IsResponsiveMode() and 0.01 or 0.028,
                function()
                    frame.__sao.EnableGlow();
                end
            );
        end
    end,

    EndGlowFinally = function(self, frame, onlyIfInternal)
        if frame.__sao.startTimer then
            frame.__sao.startTimer:Cancel();
            frame.__sao.startTimer = nil;
        end
        if onlyIfInternal then
            if not frame.__sao.useExternalGlow then
                -- Disable glow only if using an internal glow
                -- Using an external glow will most likely want to start glowing from the GLOW_SHOW event that brought us here
                -- So if we disabled the glow at this point, we would probably interfere with the external glowing engine
                frame.__sao.DisableGlow();
            end
        else
            frame.__sao.DisableGlow();
        end
    end,

    BeginSAOGlow = function(self, frame, glowID)
        SAO:Trace(Module, "BeginSAOGlow("..self:ParamName(frame, glowID)..")");

        -- First, look if this glow ID is already known
        local saoGlowForGlowID = self.SAOGlows[glowID];
        if saoGlowForGlowID then
            SAO:Debug(Module, "Re-glowing an already glowing button "..self:ParamName(frame, glowID));
            if saoGlowForGlowID[frame] == true then
                return; -- This action is already known
            end
        else
            -- Add the glow ID to the list of known SAO glows
            self.SAOGlows[glowID] = {};
            saoGlowForGlowID = self.SAOGlows[glowID];
        end

        -- Then activate the glow, if not in conflict
        local isStartingGlow;
        if self.NativeGlows[glowID] then
            -- Natively glowing, do not double-glow with SAO+Native
            SAO:Debug(Module, "BeginSAOGlow does not glow to prevent conflict with Native glow of "..self:ParamName(frame, glowID));
            isStartingGlow = false;
        else
            -- Not natively glowing, start SAO glow now!
            isStartingGlow = true;
            self:BeginGlowFinally(frame);
        end
        saoGlowForGlowID[frame] = isStartingGlow;
    end,

    EndSAOGlow = function(self, frame, glowID)
        SAO:Trace(Module, "EndSAOGlow("..self:ParamName(frame, glowID)..")");

        -- Basic security measure: un-glow first, then ask questions
        self:EndGlowFinally(frame);

        -- First, look if this glow ID is already known
        local saoGlowForGlowID = self.SAOGlows[glowID];
        if not saoGlowForGlowID then
            SAO:Debug(Module, "Trying to un-glow a non-tracked action "..self:SpellInfo(glowID));
            return;
        end
        if saoGlowForGlowID[frame] == nil then
            SAO:Debug(Module, "Trying to un-glow a tracked action but un-tracked button "..self:SpellInfo(glowID));
            return; -- This action is not in the list of SAO glowing buttons
        end

        saoGlowForGlowID[frame] = nil; -- Remove button from list of SAO glows

        local nbFrames = 0;
        for _, _ in pairs(saoGlowForGlowID) do nbFrames = nbFrames + 1; end
        if nbFrames == 0 then
            self.SAOGlows[glowID] = nil; -- Remove the action entirely after last button is removed
        end
    end,

    BeginNativeGlow = function(self, glowID)
        SAO:Trace(Module, "BeginNativeGlow("..self:SpellInfo(glowID)..")");

        if self.NativeGlows[glowID] then
            return; -- This action is already known
        end

        local saoGlowForGlowID = self.SAOGlows[glowID];
        if saoGlowForGlowID then
            for frame, isGlowingByUs in pairs(saoGlowForGlowID) do
                if isGlowingByUs then
                    -- Already glowing with SAO, disable SAO glow to prevent conflict
                    SAO:Debug(Module, "BeginNativeGlow un-glows SAO glowing button "..self:FrameName(frame, glowID));
                    self:EndGlowFinally(frame, true);
                    saoGlowForGlowID[frame] = false; -- Set frame as not glowing by 'us'
                end
            end
        end

        self.NativeGlows[glowID] = true;
    end,

    EndNativeGlow = function(self, glowID)
        SAO:Trace(Module, "EndNativeGlow("..self:SpellInfo(glowID)..")");

        if not self.NativeGlows[glowID] then
            return; -- This action is not in the list of Native glowing buttons
        end

        local saoGlowForGlowID = self.SAOGlows[glowID];
        if saoGlowForGlowID then
            -- SAO glow was disabled to prevent conflict, but now that Native glow goes away, start SAO glow!
            for frame, isGlowingByUs in pairs(saoGlowForGlowID) do
                if not isGlowingByUs then
                    SAO:Debug(Module, "EndNativeGlow allows to re-glow SAO glowing buttons "..self:FrameName(frame, glowID));
                    self:BeginGlowFinally(frame);
                    saoGlowForGlowID[frame] = true; -- Set frame as glowing by 'us'
                end
            end
        end

        self.NativeGlows[glowID] = nil; -- Remove button from list of Native glows
    end,
} or {
    BeginSAOGlow = function(self, frame, glowID)
        frame.__sao.EnableGlow();
    end,

    EndSAOGlow = function(self, frame, glowID)
        frame.__sao.DisableGlow();
    end,
}

if SAO.IsProject(SAO.CATA_AND_ONWARD) then
    local GlowEngineFrame = CreateFrame("Frame", "SpellActivationOverlayGlowEngineFrame");
    GlowEngineFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_SHOW");
    GlowEngineFrame:RegisterEvent("SPELL_ACTIVATION_OVERLAY_GLOW_HIDE");
    GlowEngineFrame:SetScript("OnEvent", function (self, event, spellID)
        if event == "SPELL_ACTIVATION_OVERLAY_GLOW_SHOW" then
            GlowEngine:BeginNativeGlow(spellID);
        elseif event == "SPELL_ACTIVATION_OVERLAY_GLOW_HIDE" then
            GlowEngine:EndNativeGlow(spellID);
        end
    end);
end

local function EnableGlow(frame, glowID, reason)
    if SAO.Shutdown:IsAddonDisabled() then
        return;
    end
    if frame:IsShown() then -- Invisible frames might cause issues; worse case scenario they will be visible soon and the player will have to wait for next proc
        SAO:Debug(Module, "Enabling Glow for button "..tostring(frame.GetName and frame:GetName() or "").." with glow id "..tostring(glowID).." due to "..reason);
        GlowEngine:BeginSAOGlow(frame, glowID);
    end
end

local function DisableGlow(frame, glowID, reason)
    SAO:Debug(Module, "Disabling Glow for button "..tostring(frame.GetName and frame:GetName() or "").." with glow id "..tostring(glowID).." due to "..reason);
    GlowEngine:EndSAOGlow(frame, glowID);
end

-- An action button has been updated
-- Check its old/new action and old/new spell ID, and put it in appropriate lists
-- If forceRefresh is true, refresh even if old spell ID and new spell ID are identical
-- Set forceRefresh if the spell ID of the button may switch from untracked to tracked (or vice versa) in light of recent events
function SAO.UpdateActionButton(self, button, forceRefresh)
    local oldGlowID = button.__sao.lastGlowID; -- Set by us, a few lines below
    local newGlowID = button.__sao.GetGlowID();
    button.__sao.lastGlowID = newGlowID; -- Write button.__sao.lastGlowID here, but use oldGlowID/newGlowID for the rest of the function

    if (oldGlowID == newGlowID and not forceRefresh) then
        -- Skip any processing if the glow ID hasn't changed
        return;
    end

    -- Register/unregister button as 'dormant' i.e., not tracked but could be tracked in the future
    if (oldGlowID and not self.RegisteredGlowSpellIDs[oldGlowID] and type(self.DormantActionButtons[oldGlowID]) == 'table') then
        if (self.DormantActionButtons[oldGlowID][button] == button) then
            self.DormantActionButtons[oldGlowID][button] = nil;
        end
    end
    if (newGlowID and not self.RegisteredGlowSpellIDs[newGlowID]) then
        if (type(self.DormantActionButtons[newGlowID]) == 'table') then
            if (self.DormantActionButtons[newGlowID][button] ~= button) then
                self.DormantActionButtons[newGlowID][button] = button;
            end
        else
            self.DormantActionButtons[newGlowID] = { [button] = button };
        end
    end

    if (not self.RegisteredGlowSpellIDs[oldGlowID] and not self.RegisteredGlowSpellIDs[newGlowID]) then
        -- Ignore action if it does not (nor did not) correspond to a tracked glowID
        return;
    end

    -- Untrack previous action button and track the new one
    if (oldGlowID and self.RegisteredGlowSpellIDs[oldGlowID] and type(self.ActionButtons[oldGlowID]) == 'table') then
        -- Detach action button from the former glow ID
        if (self.ActionButtons[oldGlowID][button] == button) then
            self.ActionButtons[oldGlowID][button] = nil;
        end
    end
    if (newGlowID and self.RegisteredGlowSpellIDs[newGlowID]) then
        if (type(self.ActionButtons[newGlowID]) == 'table') then
            -- Attach action button to the current glow ID
            if (self.ActionButtons[newGlowID][button] ~= button) then
                self.ActionButtons[newGlowID][button] = button;
            end
        else
            -- This glow ID has no Action Buttons yet: be the first
            self.ActionButtons[newGlowID] = { [button] = button };
        end
        -- Remove from the 'dormant' table, if it was dormant
        if (type(self.DormantActionButtons[newGlowID]) == 'table' and self.DormantActionButtons[newGlowID][button] == button) then
            self.DormantActionButtons[newGlowID][button] = nil;
        end
    end

    -- Glow or un-glow, if needed
    local wasGlowing = oldGlowID and (self.GlowingSpells[oldGlowID] ~= nil);
    local mustGlow = newGlowID and (self.GlowingSpells[newGlowID] ~= nil);

    if (not wasGlowing and mustGlow) then
        if (not SpellActivationOverlayDB or not SpellActivationOverlayDB.glow or SpellActivationOverlayDB.glow.enabled) then
            EnableGlow(button, newGlowID, "action button update (was "..tostring(oldGlowID)..")");
        end
    elseif (wasGlowing and not mustGlow) then
        DisableGlow(button, oldGlowID, "action button update (now "..tostring(newGlowID)..")");
    end
end

-- Grab all action button activity that allows us to know which button has which spell
local LBG = LibStub("LibButtonGlow-1.0", false);
local function HookActionButton_Update(button)
    if (button:GetParent() == OverrideActionBar) then
        -- Act on all buttons but the ones from OverrideActionBar

        if not button.saoAnalyzed then
            button.saoAnalyzed = true;
            -- Set the "statehidden" attribute upon init, to avoid game client issues with conflicting action slots
            local useOverrideActionBar = ((HasVehicleActionBar() and UnitVehicleSkin("player") and UnitVehicleSkin("player") ~= "")
                or (HasOverrideActionBar() and GetOverrideBarSkin() and GetOverrideBarSkin() ~= 0)); -- Test copied from ActionBarController.lua:99
            if not useOverrideActionBar then
                -- Set "statehidden" to true
                -- Don't worry, it should be reset to false next time the player enters a vehicle
                button:SetAttribute("statehidden", true);
            end
        end

        return;
    end

    if not button.__sao then
        button.__sao = { useExternalGlow = false };
        button.__sao.GetGlowID = function()
            if (button.action and HasAction(button.action)) then
                return SAO:GetSpellIDByActionSlot(button.action);
            end
        end
        button.__sao.EnableGlow = function()
            LBG.ShowOverlayGlow(button);
        end
        button.__sao.DisableGlow = function()
            LBG.HideOverlayGlow(button);
        end
    end
    SAO:UpdateActionButton(button);
end
hooksecurefunc("ActionButton_Update", HookActionButton_Update);

-- Grab buttons in the stance bar
local function HookStanceBar_UpdateState()
    local numForms = GetNumShapeshiftForms();
    for i=1, numForms do
        if i > NUM_STANCE_SLOTS then
            break;
        end
        local button = StanceBarFrame.StanceButtons[i];
        button.stanceForm = i;
        if not button.__sao then
            button.__sao = { useExternalGlow = false };
            button.__sao.GetGlowID = function()
                return select(4, GetShapeshiftFormInfo(button.stanceForm));
            end
            button.__sao.EnableGlow = function()
                LBG.ShowOverlayGlow(button);
            end
            button.__sao.DisableGlow = function()
                LBG.HideOverlayGlow(button);
            end
        end
        SAO:UpdateActionButton(button);
    end
end
hooksecurefunc("StanceBar_UpdateState", HookStanceBar_UpdateState);

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
            if (not SpellActivationOverlayDB or not SpellActivationOverlayDB.glow or SpellActivationOverlayDB.glow.enabled) then
                EnableGlow(frame, frame.__sao and frame.__sao.GetGlowID(), "direct activation");
            end
        end
    end
end

-- Find a glowing option in the options table
-- First try to find from optionIndex, otherwise fallback to legacy options
local function isGlowingOptionEnabled(glowingOptions, glowID, hashData)
    if not glowingOptions then
        return true; -- Enabled by default, in case there is not an option for it
    end

    local optionIndex = hashData and hashData.optionIndex;
    local legacyAllowed = hashData == nil or hashData.legacyGlowingOption;

    if type(glowID) == "number" then
        if optionIndex and type(glowingOptions[optionIndex]) == 'table' and type(glowingOptions[optionIndex][glowID]) == 'boolean' then
            return glowingOptions[optionIndex][glowID];
        elseif legacyAllowed and type(glowingOptions[glowID]) == "boolean" then
            return glowingOptions[glowID];
        end
    else
        local glowSpellName = (type(glowID) == "number") and GetSpellInfo(glowID) or glowID;

        if optionIndex and type(glowingOptions[optionIndex]) == 'table' then
            for optionSpellID, optionEnabled in pairs(glowingOptions[optionIndex]) do
                if (GetSpellInfo(optionSpellID) == glowSpellName) then
                    return optionEnabled;
                end
            end
        end

        if legacyAllowed then
            for optionSpellID, optionEnabled in pairs(glowingOptions) do
                if (type(optionSpellID) == 'number' and GetSpellInfo(optionSpellID) == glowSpellName) then
                    return optionEnabled;
                end
            end
        end
    end

    return true; -- Enabled by default, in case there is not an option for it
end

-- Add a glow effect for action buttons matching one of the given glow IDs
-- Each glow ID may be a spell identifier (number) or spell name (string)
function SAO.AddGlow(self, spellID, glowIDs, hashData)
    if (glowIDs == nil) then
        return;
    end

    local glowingOptions = self:GetGlowingOptions(spellID);

    for _, glowID in ipairs(glowIDs) do

        -- Find if the glow option is enabled
        local glowEnabled = isGlowingOptionEnabled(glowingOptions, glowID, hashData);

        -- Let it glow
        if (glowEnabled) then
            if (type(glowID) == "number") then
                -- glowID is a direct spell identifier
                self:AddGlowNumber(spellID, glowID);
            elseif (type(glowID) == "string") then
                -- glowID is a spell name: find spell identifiers and then parse them
                local glowSpellIDs = self:GetSpellIDsByName(glowID);
                for _, glowSpellID in ipairs(glowSpellIDs) do
                    self:AddGlowNumber(spellID, glowSpellID);
                end
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
                DisableGlow(frame, glowSpellID, "direct deactivation");
                if SAO:HasTrace(Module) then
                    local oldGlowID, newGlowID = glowSpellID, (frame.__sao and frame.__sao.GetGlowID());
                    local frameName = tostring(frame and frame.GetName and frame:GetName());
                    if oldGlowID ~= newGlowID then
                        SAO:Trace(Module, "RemoveGlow deactivates button "..frameName.." which had glowID "..tostring(oldGlowID).." but its glow ID is now "..tostring(newGlowID));
                    end
                end
            end
        end
    end
end

local warnedOutdatedLBG = false
local function warnOutdatedLBG()
    -- Warn players that their configuration has an issue with glowing buttons
    -- There is one case where this warning is misleading: if LibActionButton for ElvUI and for non-ElvUI are loaded at the same time
    -- But this should not happen in practice, because ElvUI usually replaces pretty much anything UI-related in the game
    if warnedOutdatedLBG then return end

    local text = "[|cffa2f3ff"..AddonName.."|r] One of your addons uses an old version of LibButtonGlow. "
               .."|cffff0000Please consider updating your addons|r. "
               .."Glowing buttons have been |cffff8040temporarily disabled|r to prevent issues. "
               .."(note: the Glowing Buttons option can still be enabled, but it will have no effect until the faulty addon is up-to-date)";
    print(text);

    warnedOutdatedLBG = true
end

-- Track PLAYER_LOGIN which happens immediately after all ADDON_LOADED events
-- Which means, at this point we know which addons are installed and loaded
local binder = CreateFrame("Frame", "SpellActivationOverlayLABBinder");
binder:RegisterEvent("PLAYER_LOGIN");
binder:SetScript("OnEvent", function()
    if (not LibStub) then
        -- LibStub is a must-have to load libraries required by this binder
        return
    end

    local LAB = LibStub("LibActionButton-1.0", true);
    local LAB_ElvUI = LibStub("LibActionButton-1.0-ElvUI", true);
    local LAB_GE = LibStub("LibActionButton-1.0-GE", true);
    local LBG, LBGversion = LibStub("LibButtonGlow-1.0", true);
    local LCG = LibStub("LibCustomGlow-1.0", true);

    local buttonUpdateFunc = function(libGlow, event, self)
        if (self._state_type ~= "action") then
            -- If button is not an "action", then GetSpellId is unusable
            -- This happens for instance with vehicle buttons
            -- They are probably not meant to glow, so it's simpler to just ignore them
            return;
        end
        if not self.__sao or self.__sao.useExternalGlow == false then
            if self.__sao then
                SAO:Debug(Module, "Replacing glowing button functions of "..tostring(self.GetName and self.GetName()).." with external lib");
                self.__sao.useExternalGlow = true;
            else
                self.__sao = { useExternalGlow = true };
            end
            self.__sao.GetGlowID = function()
                return self:GetSpellId();
            end
            self.__sao.EnableGlow = function()
                libGlow.ShowOverlayGlow(self);
            end
            self.__sao.DisableGlow = function()
                libGlow.HideOverlayGlow(self);
            end
        end
        SAO:UpdateActionButton(self);
    end

    local LBGButtonUpdateFunc = function(event, self)
        buttonUpdateFunc(LBG, event, self);
    end

    local LCGButtonUpdateFunc = function(event, self)
        buttonUpdateFunc(LCG, event, self);
    end

    local LAB_GEButtonUpdateFunc = function(event, self)
        buttonUpdateFunc(LAB_GE, event, self);
    end

    -- Support for LibActionButton used by e.g., Bartender
    if (LAB and LBG and LBGversion >= 8) then -- Prioritize LibButtonGlow, if available
        LAB:RegisterCallback("OnButtonUpdate", LBGButtonUpdateFunc);
    elseif (LAB and LCG) then -- Otherwise fall back to LibCustomGlow
        LAB:RegisterCallback("OnButtonUpdate", LCGButtonUpdateFunc);
    elseif (LAB and LBG) then
        warnOutdatedLBG();
    end

    -- Support for ElvUI's LibActionButton
    if (LAB_ElvUI) then
        -- For some time, ElvUI favored LibCustomGlow by default
        -- On ElvUI 13.01 and higher, LibButtonGlow is the official lib for ElvUI
        -- This is probably due to a bug of LibCustomGlow under ElvUI 13
        -- Although we're not sure if the bug existed in 13.00, we favor LBG for all 13.xx versions
        local hasElvUI13OrHigher, hasElvUI1381OrHigher = false, false
        if (ElvUI and ElvUI[1] and type(ElvUI[1].version) == 'number') then
            hasElvUI13OrHigher = ElvUI[1].version >= 13
            hasElvUI1381OrHigher = ElvUI[1].version >= 13.81
        end
        -- However, there is a bug with ProjectAzilroka which hasn't been updated since Ulduar patch
        -- So we switch back to the old priority if an old Azilroka is found
        local hasAzilroka186OrLower = false
        if (ProjectAzilroka and type(ProjectAzilroka.Version) == 'string') then
            local _, _, azilMajor, azilMinor = strfind(ProjectAzilroka.Version, "(%d+)%.(%d+)")
            azilMajor = tonumber(azilMajor)
            azilMinor = tonumber(azilMinor)
            if (type(azilMajor) == 'number' and type(azilMinor) == 'number') then
                hasAzilroka186OrLower = azilMajor < 1 or azilMajor == 1 and azilMinor <= 86
            end
        end
        if (hasElvUI13OrHigher and not hasElvUI1381OrHigher and not hasAzilroka186OrLower) then
            if (LBG and LBGversion >= 8) then
                LAB_ElvUI:RegisterCallback("OnButtonUpdate", LBGButtonUpdateFunc);
            elseif (LCG) then
                LAB_ElvUI:RegisterCallback("OnButtonUpdate", LCGButtonUpdateFunc);
            elseif (LBG) then
                warnOutdatedLBG();
            end
        else
            if (LCG) then -- Prioritize LibCustomGlow, if available
                LAB_ElvUI:RegisterCallback("OnButtonUpdate", LCGButtonUpdateFunc);
            elseif (LBG and LBGversion >= 8) then -- Otherwise fall back to LibButtonGlow
                LAB_ElvUI:RegisterCallback("OnButtonUpdate", LBGButtonUpdateFunc);
            elseif (LBG) then
                warnOutdatedLBG();
            end
        end
    end

    -- Support for AzeriteUI5's LibActionButton
    if (LAB_GE) then
        LAB_GE:RegisterCallback("OnButtonUpdate", LAB_GEButtonUpdateFunc)
    end

    binder:UnregisterEvent("PLAYER_LOGIN");
end);
