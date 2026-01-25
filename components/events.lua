local AddonName, SAO = ...
local Module = "events"

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local UnitGUID = UnitGUID

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

-- LEARNED_SPELL_IN_SKILL_LINE from patch 11.0.0, arrived in TBC Classic Anniversary
function SAO.LEARNED_SPELL_IN_SKILL_LINE(self, ...)
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
            self:Info("==", "Because you are playing "..className..", ".."Necrosis is not necessary.");
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
		SAO:Debug(Module, "Received native SPELL_ACTIVATION_OVERLAY_SHOW with spell ID "..tostring(spellID)..", ".."texture "..tostring(texture)..", ".."positions '"..tostring(positions).."', ".."scale "..tostring(scale)..", ".."(r g b) = ("..tostring(r).." "..tostring(g).." "..tostring(b)..")");
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
