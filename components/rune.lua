local AddonName, SAO = ...
local Module = "rune"

-- Optimize frequent calls
local GetSpellInfo = GetSpellInfo
local InCombatLockdown = InCombatLockdown

-- Map between spell ID and rune ID
local runeMapping = { initialized = false }; -- Use arbitraty spell ID 'initialized' to know if table was init
local function addRuneMapping(rune)
    local runeID = rune.skillLineAbilityID;
    for _, spellID in pairs(rune.learnedAbilitySpellIDs) do
        if runeMapping[spellID] ~= runeID then
            SAO:Debug(Module, "Spell "..(GetSpellInfo(spellID) or "x").." ("..spellID..") is learned by rune "..runeID);
            runeMapping[spellID] = runeID;
        end
    end
end

local function initRuneMapping()
    local categories = C_Engraving and C_Engraving.GetRuneCategories(false, false) or {};
    local foundRune = false;
    for _, cat in pairs(categories) do
        local runes = C_Engraving.GetRunesForCategory(cat, false) or {};
        for _, rune in pairs(runes) do
            addRuneMapping(rune);
            foundRune = true;
        end
    end
    SAO:Trace(Module, "initRuneMapping foundRune == "..tostring(foundRune));
    runeMapping.initialized = foundRune;
end

function SAO.GetRuneFromSpell(self, spellID)
    -- Lazy init
    if not runeMapping.initialized then
        C_Engraving.RefreshRunesList()
        initRuneMapping();
    end

    return runeMapping[spellID];
end

-- Track rune updates
if SAO.IsSoD() then
    -- Check rune updates when the RUNE_UPDATED event is triggered
    local RuneUpdateTracker = CreateFrame("FRAME");
    RuneUpdateTracker:RegisterEvent("RUNE_UPDATED");
    RuneUpdateTracker:SetScript("OnEvent", function(self, event, rune)
        if runeMapping.initialized and rune then
            addRuneMapping(rune);
        else
            -- Either rune mapping is not initialized (then init it)
            -- or there is no rune (then re-init all, to refresh list)
            initRuneMapping();
        end
    end);

    -- Check rune updates every 10 secs, up until a rune is found
    -- Runes are not checked while in combat to avoid lags (and Lua errors) while fighting
    -- Because of that, this technique does not check runes if the player fights too often
    -- Hopefully, the player should find time windows of not fighting for 10 secs in a row
    C_Timer.NewTicker(10, function(self)
        if runeMapping.initialized then
            -- Rune found outside of this timer: this timer has no use anymore
            self:Cancel();
            SAO:Debug(Module, "Stopping regular checks because at least one rune was found from another check");
        elseif InCombatLockdown() then
            SAO:Debug(Module, "Cannot perform regular checks because you are in combat");
        else
            -- Try again
            SAO:Debug(Module, "Performing a regular check");
            C_Engraving.RefreshRunesList()
            initRuneMapping();
            if runeMapping.initialized then
                -- Rune found: yay! No need for this timer anymore
                self:Cancel();
                SAO:Debug(Module, "Found at least one rune, stopping regular checks now");
            else
                SAO:Debug(Module, "No rune was found during regular check");
            end
        end
    end);
end
