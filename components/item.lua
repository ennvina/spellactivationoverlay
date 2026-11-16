local AddonName, SAO = ...

-- Optimize frequent calls
local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo

-- Get icon and label of an item
function SAO.GetItemText(self, itemID)
    local name,_,_,_,_,_,_,_,_,icon = GetItemInfo(itemID);
    if name then
        return "|T"..icon..":0|t "..name;
    end
end

local function registerHealingTrance(self, label, spellID, itemID)
    local itemTextFunc = function()
        local itemText = self:GetItemText(itemID);
        if itemText then
            -- If item is cached, return text immediately
            return itemText;
        else
            -- If item is not cached, request load and return a function to retry later
            -- In practice, the game will retrieve it instantly, but we still need to wait for the load callback
            local item = Item:CreateFromItemID(itemID);
            return function(callback)
                item:ContinueOnItemLoad(callback);
            end
        end
    end;

    self:CreateEffect(
        label,
        SAO.ALL_PROJECTS, -- Not really all projects, it was filtered before reaching this point
        spellID,
        "aura",
        {
            overlay = {
                texture = "genericarc_04",
                position = "Left + Right (Flipped)", outer = 0.2, scale = 1.2,
                color = { 255, 192, 255 },
                pulse = false,
                option = { subText = itemTextFunc },
            },
        }
    );
end

function SAO.RegisterAuraEyeOfGruul(self, label, spellID)
    if self.IsTBC() then
        registerHealingTrance(self, label, spellID, 28823);
    end
end

function SAO.RegisterAuraSoulPreserver(self, label, spellID)
    if self.IsWrath() then
        registerHealingTrance(self, label, spellID, 37111);
    end
end
