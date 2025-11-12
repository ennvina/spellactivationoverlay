local AddonName, SAO = ...
local Module = "events"

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID

-- Events starting with SPELL_AURA e.g., SPELL_AURA_APPLIED
-- This should be invoked only if the buff is done on the player i.e., UnitGUID("player") == destGUID
function SAO.SPELL_AURA(self, ...)
    local _, event, _, _, _, _, _, _, _, _, _, spellID, spellName = CombatLogGetCurrentEventInfo();

    --[[ Aura event chart

    For un-stackable auras:
    - "SPELL_AURA_APPLIED" = buff is being applied now
    - "SPELL_AURA_REMOVED" = buff is being removed now

    For stackable auras:
    - "SPELL_AURA_APPLIED" = first stack applied
    - "SPELL_AURA_APPLIED_DOSE" = second stack applied or beyond
    - "SPELL_AURA_REMOVED_DOSE" = removed a stack, but there is at least one stack left
    - "SPELL_AURA_REMOVED" = removed last remaining stack

    For any aura:
    - "SPELL_AURA_REFRESH" = buff is refreshed, usually the remaining time is reset to its max duration
    ]]
    local auraApplied = event:sub(0,18) == "SPELL_AURA_APPLIED"; -- includes "SPELL_AURA_APPLIED" and "SPELL_AURA_APPLIED_DOSE"
    local auraRemovedLast = event == "SPELL_AURA_REMOVED";
    local auraRemovedDose = event == "SPELL_AURA_REMOVED_DOSE";
    local auraRefresh = event == "SPELL_AURA_REFRESH";
    if not auraApplied and not auraRemovedLast and not auraRemovedDose and not auraRefresh then
        return; -- Not an event we're interested in
    end

    -- Use the game's aura from CLEU to find its corresponding aura item in SAO, if any
    local bucket;
    bucket, spellID = self:GetBucketBySpellIDOrSpellName(spellID, spellName);
    if not bucket then
        -- This spell is not tracked by SAO
        return;
    end
    if not bucket.trigger:reactsWith(SAO.TRIGGER_AURA) then
        -- This spell ignores aura-based triggers
        return;
    end

    -- Handle unique case first: aura refresh
    if (auraRefresh) then
        bucket:refresh();
        -- Can return now, because SPELL_AURA_REFRESH is used only to refresh timer
        return;
    end

    -- Now, we are in a situation where we either got a buff (SPELL_AURA_APPLIED*) or lost it (SPELL_AURA_REMOVED*)

    if (auraRemovedLast) then
        bucket:setAuraStacks(nil); -- nil means "not currently holding any stacks"
        -- Can return now, because SPELL_AURA_REMOVED resets everything
        return;
    end

    --[[ Now, we are in a situation where either:
        - we got a buff (SPELL_AURA_APPLIED*)
        - or we lost a stack but still have the buff (SPELL_AURA_REMOVED_DOSE)
        Either way, the player currently has the buff or debuff
    ]]

    local stacks = 0; -- Number of stacks of the aura, unless the aura is stack-agnostic (see below)
    if not bucket.stackAgnostic then
        -- To handle stackable auras, we must find the aura (ugh!) to get its number of stacks
        -- In an ideal world, we would use a stack count from the combat log which, unfortunately, is unavailable
        if event ~= "SPELL_AURA_REMOVED" then -- No need to find aura with complete removal: the buff is not there anymore
            stacks = self:GetPlayerAuraStacksBySpellID(spellID) or 0;
        end
        -- For the record, stacks will always be 0 for stack-agnostic auras, even if the aura actually has stacks
        -- This is an optimization that prevents the above call of GetPlayerAuraStacksBySpellID, which has a significant cost
    end

    --[[ Aura is enabled, either because:
        - it was added now (SPELL_AURA_APPLIED)
        - or was upgraded (SPELL_AURA_APPLIED_DOSE)
        - or was downgraded but still visible (SPELL_AURA_REMOVED_DOSE)
    ]]
    bucket:setAuraStacks(stacks);
end

-- The (in)famous CLEU event
function SAO.COMBAT_LOG_EVENT_UNFILTERED(self, ...)
    local _, event, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo();

    if ( (event:sub(0,11) == "SPELL_AURA_") and (destGUID == UnitGUID("player")) ) then
        self:SPELL_AURA(...);
    end
end

local arePendingEffectsRegistered = false;
function SAO.LOADING_SCREEN_DISABLED(self, ...)
    -- Register effects right after the loading screen ends
    -- Initially, this was called after PLAYER_LOGIN
    -- But in some situations, PLAYER_LOGIN is "too soon" to be able to use the game's glow engine
    if not arePendingEffectsRegistered then
        arePendingEffectsRegistered = true;
        self:RegisterPendingEffectsAfterPlayerLoggedIn();
    end

    -- Check manually if buckets are triggered immediately after their creation (see above code)
    -- Or after a loading screen in-between zones, because CLEU may not trigger everything during a loading screen
    -- If it is possible to create effects after this point, this kind of manual checks should be called there too
    self:CheckManuallyAllBuckets();
end

function SAO.PLAYER_REGEN_ENABLED(self, ...)
    local inCombat = false; -- Cannot rely on InCombatLockdown() at this point
    self:ForEachBucket(function(bucket) bucket:checkCombat(inCombat) end);
end

function SAO.PLAYER_REGEN_DISABLED(self, ...)
    local inCombat = true; -- Cannot rely on InCombatLockdown() at this point
    self:ForEachBucket(function(bucket) bucket:checkCombat(inCombat) end);
end

-- Specific spellbook update
function SAO.SPELLS_CHANGED(self, ...)
    for glowID, _ in pairs(self.RegisteredGlowSpellNames) do
        self:RefreshSpellIDsByName(glowID, true);
    end
end

-- Specific spell learned
function SAO.LEARNED_SPELL_IN_TAB(self, ...)
    local spellID, skillInfoIndex, isGuildPerkSpell = ...;
    self:LearnNewSpell(spellID);
end

local warnedSaoVsNecrosis = false;
function SAO.ADDON_LOADED(self, addOnName, containsBindings)
    if warnedSaoVsNecrosis then
        return;
    end

    local iamSAO = strlower(AddonName) == "spellactivationoverlay";
    local itisSAO = strlower(addOnName) == "spellactivationoverlay";

    local iamNecrosis = strlower(AddonName):sub(0,8) == "necrosis";
    local itisNecrosis = strlower(addOnName):sub(0,8) == "necrosis";

    if (iamSAO and (itisNecrosis or itisSAO and NecrosisConfig)) or
       (iamNecrosis and (itisSAO or itisNecrosis and _G["Spell".."ActivationOverlayDB"])) then
        local className, classFilename, classId = UnitClass("player");
        if classFilename == "WARLOCK" then
            self:Info("==", "You have installed Necrosis and Spell".."ActivationOverlay at the same time.")
            if iamSAO then
                self.Shutdown:EnableCategory("NECROSIS_INSTALLED");
                local shutdownCategory = self.Shutdown:GetCategory();
                if shutdownCategory.Name == "NECROSIS_INSTALLED" and shutdownCategory.DisableCondition.IsDisabled() then
                    self:Warn("==", "Spell".."ActivationOverlay will be disabled for this character to avoid double procs with Necrosis. "..
                        "You can go to Options > AddOns to change the preferred addon.");
                end
            elseif iamNecrosis then
                self.Shutdown:EnableCategory("SAO_INSTALLED");
                local shutdownCategory = self.Shutdown:GetCategory();
                if shutdownCategory.Name == "SAO_INSTALLED" and shutdownCategory.DisableCondition.IsDisabled() then
                    self:Warn("==", "Necrosis Spell Activations will be disabled for this character to avoid double procs with Spell".."ActivationOverlay. "..
                        "You can go to Options > AddOns to change the preferred addon. "..
                        "This concerns only \"Spell Activations\" of Necrosis; it has no effect on other features of Necrosis.");
                end
            end
        else
            self:Info("==", "You have installed Necrosis and SpellActivationOverlay at the same time.")
            self:Info("==", "Because you are playing "..className..", Necrosis is not necessary.");
        end
        warnedSaoVsNecrosis = true;
    end
end

-- List of events directly handled by SpellActivationOverlayFrame, as initially intended by Blizzard
-- Each event handler must have the signature: function(self, event, ...) where self is SpellActivationOverlayFrame
local DirectFrameEventHandlers = {}

if SAO.IsProject(SAO.CATA_AND_ONWARD) then
	--[[
		Dead code because these events do not exist in Classic Era, BC Classic, nor Wrath Classic
		Also, the "displaySpellActivationOverlays" console variable does not exist
		-- Update with upcoming Cataclysm --
		Must look into it for Cataclysm Classic, because these events should occur once again
		But we have added a few parameters since then - must add missing parameters if needed
		For now, we simply write debug information to try to confirm these events are emitted
	]]

	DirectFrameEventHandlers["SPELL_ACTIVATION_OVERLAY_SHOW"] = function(self, event, ...)
		local spellID, texture, positions, scale, r, g, b = ...;
		SAO:Debug(Module, "Received native SPELL_ACTIVATION_OVERLAY_SHOW with spell ID "..tostring(spellID)..", texture "..tostring(texture)..", positions '"..tostring(positions).."', scale "..tostring(scale)..", (r g b) = ("..tostring(r).." "..tostring(g).." "..tostring(b)..")");
		SAO:ReportUnknownEffect(Module, spellID, texture, positions, scale, r, g, b);
		-- if ( GetCVarBool("displaySpellActivationOverlays") ) then 
		-- 	SpellActivationOverlay_ShowAllOverlays(self, spellID, texture, positions, scale, r, g, b, true)
		-- end
	end

	DirectFrameEventHandlers["SPELL_ACTIVATION_OVERLAY_HIDE"] = function(self, event, ...)
		local spellID = ...;
		if spellID then
			SAO:Debug(Module, "Received native SPELL_ACTIVATION_OVERLAY_HIDE with spell ID "..tostring(spellID));
		end
		-- if spellID then
		-- 	SpellActivationOverlay_HideOverlays(self, spellID);
		-- else
		-- 	SpellActivationOverlay_HideAllOverlays(self);
		-- end
	end
end

DirectFrameEventHandlers["PLAYER_REGEN_DISABLED"] = function(self, event, ...)
	if not self.disableDimOutOfCombat and event == "PLAYER_REGEN_DISABLED" and self.inPseudoCombat ~= true then
		self.combatAnimOut:Stop();	--In case we're in the process of animating this out.
		self.combatAnimIn:Play();
		for _, overlay in ipairs(self.combatOnlyOverlays) do
			overlay.combat.animOut:Stop();
			SpellActivationOverlayFrame_PlayCombatAnimIn(overlay.combat.animIn);
		end
	end
end

DirectFrameEventHandlers["PLAYER_REGEN_ENABLED"] = function(self, event, ...)
	if not self.disableDimOutOfCombat and event == "PLAYER_REGEN_ENABLED" and self.inPseudoCombat ~= false then
		self.combatAnimIn:Stop();	--In case we're in the process of animating this out.
		self.combatAnimOut:Play();
		for _, overlay in ipairs(self.combatOnlyOverlays) do
			overlay.combat.animIn:Stop();
			SpellActivationOverlayFrame_PlayCombatAnimOut(overlay.combat.animOut);
		end
	end
end

SAO.CentralizedEventDispatcher = {}

function SAO:InitializeEventDispatcher()
    local isEventPair = function(event, handler)
        -- An event name is a string with all capital letters and underscores only
        return type(handler) == 'function' and type(event) == 'string' and event:match("^[A-Z_]+$") ~= nil;
    end

    -- func is a function with the signature: function(frame, self, event, ...)
    -- where frame is SpellActivationOverlayFrame, and self is SAO
    local addDispatcher = function(event, func)
        if not self.CentralizedEventDispatcher[event] then
            self.CentralizedEventDispatcher[event] = {};
        end
        tinsert(self.CentralizedEventDispatcher[event], func);
    end

    -- Events that were originally handled directly in SpellActivationOverlayFrame_OnEvent
    for event, handler in pairs(DirectFrameEventHandlers) do
        if isEventPair(event, handler) then
            local func = function(frame, self, event, ...)
                handler(frame, event, ...);
            end
            addDispatcher(event, func);
        end
    end

    -- Global events
    for event, handler in pairs(SAO) do
        if isEventPair(event, handler) then
            local func = function(frame, self, event, ...)
                handler(self, ...);
            end
            addDispatcher(event, func);
        end
    end

    -- Variable events
    for event, handlers in pairs(SAO.VariableEventProxy) do
        for _, var in ipairs(handlers) do
            local handler = var.event[event];
            if isEventPair(event, handler) then
                local func = function(frame, self, event, ...)
                    handler(...);
                end
                addDispatcher(event, func);
            end
        end
    end

    -- Class-specific events
    for event, handler in pairs(SAO.CurrentClass or {}) do
        if isEventPair(event, handler) then
            local func = function(frame, self, event, ...)
                handler(self, ...);
            end
            addDispatcher(event, func);
        end
    end
end
