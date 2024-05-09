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

    if auras and (auraApplied or auraRemoved or auraRefresh) then
        local count = 0;
        if (not auras[0]) then
            -- If there is no aura with stacks == 0, this must mean that this aura is stackable
            -- To handle stackable auras, we must find the aura (ugh!) to get its number of stacks
            -- In an ideal world, we'd use the 'amount' which, unfortunately, is unreliable
            count = select(3, self:FindPlayerAuraByID(spellID));
        end

        local currentlyActiveOverlay = self:GetActiveOverlay(spellID);
        if (
            -- Aura not visible yet
            (not currentlyActiveOverlay)
        and
            -- Aura is there, either because it was added or upgraded or downgraded but still visible
            (auraApplied or (auraRemoved and count and count > 0))
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
            (currentlyActiveOverlay)
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
            -- Aura is already visible but its number of stack changed
            (currentlyActiveOverlay and currentlyActiveOverlay ~= count)
        and
            -- The new stack count allows it to be visible
            ((auraApplied or auraRemoved) and (count and count > 0))
        and
            -- The number of stacks is supported
            (auras[count])
        ) then
            -- Deactivate old aura and activate the new one
            self:Debug(Module, "Changing number of stacks from "..tostring(currentlyActiveOverlay).." to "..count.." for aura "..spellID.." "..(GetSpellInfo(spellID) or ""));
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
            -- Aura is already visible and its number of stacks changed
            (currentlyActiveOverlay and currentlyActiveOverlay ~= count)
        and
            ((auraApplied and count and count > 0) or auraRemoved)
            -- If condition end up here, it means the previous 'if' was false
            -- Which means either there is no stacks, or the number of stacks is not supported
        ) then
            -- Aura just disappeared or is not supported for this number of stacks
            self:Debug(Module, "Removing aura of "..spellID.." "..(GetSpellInfo(spellID) or ""));
            -- self:UnmarkAura(spellID); -- No need to unmark explicitly, because DeactivateOverlay does it automatically
            self:DeactivateOverlay(spellID);
            self:RemoveGlow(spellID);
        end
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
