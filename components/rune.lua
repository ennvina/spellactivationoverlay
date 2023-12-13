local AddonName, SAO = ...

-- Optimize frequent calls
local GetSpellInfo = GetSpellInfo

-- Map between spell ID and rune ID
local runeMapping = { initialized = false }; -- Use arbitraty spell ID 'initialized' to know if table was init
local function addRuneMapping(rune)
    local runeID = rune.skillLineAbilityID;
    for _, spellID in pairs(rune.learnedAbilitySpellIDs) do
        if runeMapping[spellID] ~= runeID then
            SAO:Debug("rune - Spell "..(GetSpellInfo(spellID) or "x").." ("..spellID..") is learned by rune "..runeID);
            runeMapping[spellID] = runeID;
        end
    end
end

local function initRuneMapping()
    local categories = C_Engraving and C_Engraving.GetRuneCategories(false, true) or {};
    local foundRune = false;
    for _, cat in pairs(categories) do
        local runes = C_Engraving.GetRunesForCategory(cat, true) or {};
        for _, rune in pairs(runes) do
            addRuneMapping(rune);
            foundRune = true;
        end
    end
    runeMapping.initialized = foundRune;
end

function SAO.GetRuneFromSpell(self, spellID)
    -- Lazy init
    if not runeMapping.initialized then
        initRuneMapping();
    end

    return runeMapping[spellID];
end

function SAO.IsRuneSpellLearned(self, spellID)
    local runeID = self:GetRuneFromSpell(spellID);
    if runeID then
        return C_Engraving.IsRuneEquipped(runeID);
    end
end

-- Track rune updates
if SAO.IsSoD() then
    RuneUpdateTracker = CreateFrame("FRAME");
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
end
