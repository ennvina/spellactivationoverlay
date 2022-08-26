local AddonName, SAO = ...

local riposteSpellID = 14251;

local isRiposteActivated = false;

local retryTimer = nil;

local function customSpellUpdate(self, ...)
    local start, duration, enabled, modRate = GetSpellCooldown(riposteSpellID);
    if (type(start) ~= "number") then
        -- Spell not available
        return
    end

    local isRiposteUsable = IsUsableSpell(riposteSpellID);
    local riposteMustBeActivated = isRiposteUsable and start == 0;

    if (not isRiposteActivated and riposteMustBeActivated) then
        -- Riposte triggered but not shown yet: just do it!
        isRiposteActivated = true;
        self:ActivateOverlay(0, riposteSpellID, self.TexName["bandits_guile"], "Top (CW)", 1, 255, 255, 255, true);
        self:AddGlow(riposteSpellID, {riposteSpellID}); -- Same spell ID, because there is no 'aura'
    elseif (isRiposteActivated and not riposteMustBeActivated) then
        -- Riposte not triggered but still shown: hide it
        isRiposteActivated = false;
        self:DeactivateOverlay(riposteSpellID);
        self:RemoveGlow(riposteSpellID);
    end
    
    if (isRiposteUsable and start > 0) then
        -- Riposte could be usable, but CD prevents us to: try again in a few seconds
        local endTime = start+duration;

        if (not retryTimer or retryTimer.endTime ~= endTime) then
            if (retryTimer) then
                retryTimer:Cancel();
            end

            local remainingTime = endTime-GetTime();
            local delta = 0.05; -- Add a small delay to account for lags and whatnot
            local retryFunc = function(...) customSpellUpdate(self, ...); end;
            retryTimer = C_Timer.NewTimer(remainingTime+delta, retryFunc);
            retryTimer.endTime = endTime;
        end
    end
end

local function registerClass(self)
    -- Register Riposte's spell ID
    SAO.RegisteredGlowIDs[riposteSpellID] = true;
end

SAO.Class["ROGUE"] = {
    ["Register"] = registerClass,
    ["SPELL_UPDATE_USABLE"] = customSpellUpdate,
}
