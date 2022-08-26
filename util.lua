local AddonName, SAO = ...

-- Utility function to get the spell ID associated to an action
function SAO.GetSpellIDByActionSlot(self, actionSlot)
    local actionType, id, subType = GetActionInfo(actionSlot);
    if (actionType == "spell") then
        return id;
    elseif (actionType == "macro") then
        return GetMacroSpell(id);
    end
end
