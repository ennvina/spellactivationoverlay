local AddonName, SAO = ...

-- Get icon and label of an item
function SAO.GetItemText(self, itemID)
    local name,_,_,_,_,_,_,_,_,icon = GetItemInfo(itemID);
    if name then
        return "|T"..icon..":0|t "..name;
    end
end

function SAO.AddItemOverlayOption(self, spellID, itemID, projectID)
    if WOW_PROJECT_ID == projectID then
        local itemText = self:GetItemText(itemID);
        self:AddOverlayOption(spellID, spellID, 0, itemText);
    end
end

