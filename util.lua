local AddonName, SAO = ...

-- Utility aura function, one of the many that Blizzard could've done better years ago...
function SAO.FindPlayerAuraByID(self, id)
    local i = 1
    local name, icon, count, dispelType, duration, expirationTime,
        source, isStealable, nameplateShowPersonal, spellId,
        canApplyAura, isBossDebuff, castByPlayer = UnitBuff("player", i);
    while name do
        if (spellId == id) then
            return name, icon, count, dispelType, duration, expirationTime,
                source, isStealable, nameplateShowPersonal, spellId,
                canApplyAura, isBossDebuff, castByPlayer;
        end
        i = i+1
        name, icon, count, dispelType, duration, expirationTime,
            source, isStealable, nameplateShowPersonal, spellId,
            canApplyAura, isBossDebuff, castByPlayer = UnitBuff("player", i);
    end
end

--[[
    Utility function to know how many talent points the player has spent on a specific talent

    If the talent is found, returns:
    - the number of points spent for this talent
    - the total number of points possible for this talent
    - the tabulation in which the talent was found
    - the index in which the talent was found
    Tabulation and index can be re-used in GetTalentInfo to avoid re-parsing all talents

    Returns nil if no talent is found with this name e.g., in the wrong expansion
]]
function SAO.GetTalentByName(self, talentName)
    for tab = 1, GetNumTalentTabs() do
        for index = 1, GetNumTalents(tab) do
            local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(tab, index);
            if (name == talentName) then
                return rank, maxRank, tab, index;
            end
        end
    end
end

-- Utility function to get the spell ID associated to an action
function SAO.GetSpellIDByActionSlot(self, actionSlot)
    local actionType, id, subType = GetActionInfo(actionSlot);
    if (actionType == "spell") then
        return id;
    elseif (actionType == "macro") then
        return GetMacroSpell(id);
    end
end
