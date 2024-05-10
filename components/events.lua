local AddonName, SAO = ...
local Module = "events"

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetSpellInfo = GetSpellInfo
local UnitGUID = UnitGUID

-- Events starting with SPELL_AURA e.g., SPELL_AURA_APPLIED
-- This should be invoked only if the buff is done on the player i.e., UnitGUID("player") == destGUID
function SAO.SPELL_AURA(self, ...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo();
    local spellID, spellName, spellSchool, auraType, amount = select(12, CombatLogGetCurrentEventInfo());
    local auraApplied = event:sub(0,18) == "SPELL_AURA_APPLIED";
    local auraRemoved = event:sub(0,18) == "SPELL_AURA_REMOVED";
    local auraRefresh = event:sub(0,18) == "SPELL_AURA_REFRESH";
    if not auraApplied and not auraRemoved and not auraRefresh then
        return; -- Not an event we're interested in
    end

    local auras;
    if not self.IsEra() then
        auras = self.RegisteredAurasBySpellID[spellID];
    else
        -- Due to Classic Era limitation, aura is registered by its spell name
        auras = self.RegisteredAurasBySpellID[spellName];
        if (auras) then
            -- Must fetch spellID from aura, because spellID from CLEU is most likely 0 at this point
            -- We can fetch any aura from auras because all auras store the same spellID
            for _, auraStacks in pairs(auras) do
                spellID = auraStacks[1][3]; -- [1] for first aura in auraStacks, [3] because spellID is the third item
                break;
            end
        end
    end

    if not auras then
        -- Not tracking this spell
        return;
    end

    local auraAppliedFirst = event == "SPELL_AURA_APPLIED";      -- For stackable auras: first stack applied; for unstackable auras: buff applied
    local auraAppliedDose  = event == "SPELL_AURA_APPLIED_DOSE"; -- For stackable auras: second stack applied or beyond; for unstackable auras: N/A
    local auraRemovedLast  = event == "SPELL_AURA_REMOVED";      -- For stackable auras: removed last remaining stack; for unstackable auras: buff removed
    local auraRemovedDose  = event == "SPELL_AURA_REMOVED_DOSE"; -- For stackable auras: removed a stack, but there is at least one stack left; for unstackable auras: N/A

    local count = 0;
    if not auras[0] then
        -- If there is no aura with stacks == 0, this must mean that this aura is stackable
        -- To handle stackable auras, we must find the aura (ugh!) to get its number of stacks
        -- In an ideal world, we'd use a stack count from the combat log which, unfortunately, is unavailable
        count = select(3, self:FindPlayerAuraByID(spellID)) or 0;
        -- Please note, the opposite is not necessarily true:
        -- if an aura is defined with stacks == 0, it does not guarantee that the aura is not stackable
        -- it means that the aura is count-agnostic, meaning we don't care how many count it has
        -- in other words, the only thing that matters is whether or not the buff is found, independently of its number of stacks
    end

    --[[ Check if the spell is currently displayed, and if yes, with which count
    Returned count will always be zero if tracking a count-agnostic aura (because the above if/then/else statement will be skipped)
    Possible values:
    - 1 or more, if the aura is displayed and it is a stackable aura, in which case the value indicates the number of stacks
    - 0, if the aura is displayed and either the aura is not stackable or the effect is count-agnostic
    - nil, if the aura is not displayed
    ]]
    local displayedCount = self:GetAuraMarker(spellID);
    local isDisplayed = displayedCount ~= nil;
    if (
        -- Aura not visible yet
        (not isDisplayed)
    and
        --[[ Aura is enabled, either because:
        - it was added (auraAppliedFirst)
        - or was upgraded (auraAppliedDose)
        - or was downgraded but still visible (auraRemovedDose)
        ]]
        (auraApplied or auraRemovedDose)
    and
        -- The number of stacks is supported
        (auras[count])
    ) then
        -- Activate aura
        self:Debug(Module, "Activating aura of "..spellID.." "..(GetSpellInfo(spellID) or ""));
        for _, aura in ipairs(auras[count]) do
            self:MarkAura(spellID, count);
            self:ActivateOverlay(count, select(3,unpack(aura)));
            self:AddGlow(spellID, select(11,unpack(aura)));
        end
    elseif (
        -- Aura is already visible
        (isDisplayed)
    and
        -- Aura is re-applied
        (auraRefresh)
    and
        -- The number of stacks is supported
        (auras[count])
    ) then
        -- Reactivate aura timer
        self:Debug(Module, "Refreshing aura of "..spellID.." "..(GetSpellInfo(spellID) or ""));
        self:RefreshOverlayTimer(spellID);
    elseif (
        -- Aura is already visible
        (isDisplayed)
    and
        --[[ Its number of stacks changed
        Note: if the aura is count-agnostic, this test will always return false, which suits us
        When an aura is count-agnostic, we don't care when an aura goes from count A to count B because, by definition, the exact count does not matter
        ]]
        (displayedCount ~= count)
    and
        -- The new stack count allows it to be visible
        (auraApplied or auraRemovedDose)
    and
        -- The number of stacks is supported
        (auras[count])
    ) then
        -- Deactivate old aura and activate the new one
        self:Debug(Module, "Changing number of stacks from "..tostring(displayedCount).." to "..count.." for aura "..spellID.." "..(GetSpellInfo(spellID) or ""));
        self:DeactivateOverlay(spellID);
        self:RemoveGlow(spellID);
        self:MarkAura(spellID, count); -- Call MarkAura after DeactivateOverlay, because DeactivateOverlay may reset its aura marker
        for _, aura in ipairs(auras[count]) do
            local texture, positions, scale, r, g, b, autoPulse, _, combatOnly = select(4,unpack(aura));
            local forcePulsePlay = autoPulse;
            self:ActivateOverlay(count, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, nil, combatOnly);
            self:AddGlow(spellID, select(11,unpack(aura)));
        end
    elseif (
        -- Aura is already visible
        (isDisplayed)
    and
        --[[ The aura should not be visible, either because:
        - the aura is completely removed (auraRemovedLast)
        - or the aura has changed stacks to an unsupported stack count
        Note: a count-agnostic aura will have its count == 0, in which case the 'stack change test' will always return false, which suits us
        A count-agnostic aura only cares whether the buff is active or not, the exact count does not matter
        Because of this, it doesn't make any sense to e.g. "remove the aura because the new number of stacks is unsupported"
        If you wonder when it is possible to deactivate an aura-agnostic effect, the answer is simple: when it is completely removed (auraRemovedLast)
        ]]
        (auraRemovedLast or ((auraAppliedDose or auraRemovedDose) and displayedCount ~= count and not auras[count]))
    ) then
        -- Aura just disappeared or is not supported for this number of stacks
        self:Debug(Module, "Removing aura of "..spellID.." "..(GetSpellInfo(spellID) or ""));
        -- self:UnmarkAura(spellID); -- No need to unmark explicitly, because DeactivateOverlay does it automatically
        self:DeactivateOverlay(spellID);
        self:RemoveGlow(spellID);
    end
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

    -- Check if auras are still there after a loading screen
    -- This circumvents a limitation of the CLEU which may not trigger during a loading screen
    for spellID, stacks in pairs(self.ActiveOverlays) do
        if not self:IsFakeSpell(spellID) and not self:FindPlayerAuraByID(spellID) then
            self:DeactivateOverlay(spellID);
            self:RemoveGlow(spellID);
        end
    end
end

function SAO.PLAYER_ENTERING_WORLD(self, ...)
    C_Timer.NewTimer(1, function() self:CheckAllCounterActions() end);
end

function SAO.SPELL_UPDATE_USABLE(self, ...)
    self:CheckAllCounterActions();
end

function SAO.PLAYER_REGEN_ENABLED(self, ...)
    self:CheckAllCounterActions(true);
end

function SAO.PLAYER_REGEN_DISABLED(self, ...)
    self:CheckAllCounterActions(true);
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

-- Event receiver
function SAO.OnEvent(self, event, ...)
    if self[event] then
        self[event](self, ...);
    end
    self:InvokeClassEvent(event, ...)
end
