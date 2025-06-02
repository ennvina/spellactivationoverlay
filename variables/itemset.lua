local AddonName, SAO = ...
local Module = "itemset"

-- Does the player wears enough items in the item set
local HASH_ITEM_SET_EQUIPPED     = 0x20000
local HASH_ITEM_SET_NOT_EQUIPPED = 0x40000
local HASH_ITEM_SET_MASK         = 0x60000

SAO.Variable:register({
    order = 8,
    core = "ItemSetEquipped",

    trigger = {
        flag = SAO.TRIGGER_ITEM_SET,
        name = "itemset",
    },

    hash = {
        mask = HASH_ITEM_SET_MASK,
        key = "item_set",

        setterFunc = function(self, itemSetEquipped)
            if type(itemSetEquipped) ~= 'boolean' then
                SAO:Warn(Module, "Invalid ItemSet flag "..tostring(itemSetEquipped));
            else
                local maskedHash = itemSetEquipped and HASH_ITEM_SET_EQUIPPED or HASH_ITEM_SET_NOT_EQUIPPED;
                self:setMaskedHash(maskedHash, HASH_ITEM_SET_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_ITEM_SET_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_ITEM_SET_EQUIPPED;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local itemSetEquipped = hash:getItemSetEquipped();
            return itemSetEquipped and "equipped" or "not_equipped";
        end,
        fromValue = function(hash, value)
            if value == "equipped" then
                hash:setItemSetEquipped(true);
                return true;
            elseif value == "not_equipped" then
                hash:setItemSetEquipped(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getItemSetEquipped() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            local nbTierItems = SAO:GetNbItemsEquipped(bucket.itemSet.items);
            bucket:setItemSetEquipped(nbTierItems >= bucket.itemSet.minimum);
        end,
    },

    event = {
        isRequired = true,
        names = { "PLAYER_EQUIPMENT_CHANGED" },
        PLAYER_EQUIPMENT_CHANGED = function(...)
            SAO:CheckManuallyAllBuckets(SAO.TRIGGER_ITEM_SET);
        end,
    },

    condition = {
        noeVar = "itemset",
        hreVar = "itemSetEquipped",
        noeDefault = true,
        description = "item set equipped flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "itemset",
        hreTrigger = "useItemSet",
        dependency = {
            name = "itemSet",
            expectedType = "table",
            default = function(effect) return nil end, -- Make the 'itemSet' property mandatory
            prepareBucket = function(bucket, value)
                bucket.itemSet = value;
            end,
        },
        classes = {
            force = nil,
            ignore = nil,
        },
    },
});
