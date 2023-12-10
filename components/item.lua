local AddonName, SAO = ...

-- Get icon and label of an item
function SAO.GetItemText(self, itemID)
    local name,_,_,_,_,_,_,_,_,icon = GetItemInfo(itemID);
    if name then
        return "|T"..icon..":0|t "..name;
    end
end

function SAO.AddItemOverlayOption(self, spellID, itemID)
    local itemText = self:GetItemText(itemID);
    self:AddOverlayOption(spellID, spellID, 0, itemText);
end

function SAO.RegisterAuraSoulPreserver(self, label, spellID)
    if self.IsWrath() then
        self:RegisterAura(label, 0, spellID, "genericarc_05", "Left + Right (Flipped)", 1.5, 192, 192, 192, false);
    end
end

function SAO.AddSoulPreserverOverlayOption(self, spellID)
    if self.IsWrath() then
        -- Spell is specific to each class, item is the same for everyone
        self:AddItemOverlayOption(spellID, 37111);
    end
end
