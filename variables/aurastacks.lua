local AddonName, SAO = ...
local Module = "aurastacks"

-- Aura stacks
--  if stacks >= 0 then
--      if stackAgnostic then
--          hash = HASH_AURA_ANY
--      else 
--          hash = HASH_AURA_ZERO + stacks
--  else
--      hash = HASH_AURA_ABSENT
local HASH_AURA_ABSENT = 1
local HASH_AURA_ANY    = 2
local HASH_AURA_ZERO   = HASH_AURA_ANY
local HASH_AURA_MAX    = HASH_AURA_ZERO + 10 -- Allow no more than 10 stacks
local HASH_AURA_MASK   = 0xF

SAO.Variable:register({
    order = 1,
    core = "AuraStacks",

    trigger = {
        flag = SAO.TRIGGER_AURA,
        name = "aura",
    },

    hash = {
        mask = HASH_AURA_MASK,
        key = "aura_stacks",

        setterFunc = function(self, stacks, bucket)
            if stacks == nil then
                self:setMaskedHash(HASH_AURA_ABSENT, HASH_AURA_MASK);
            elseif type(stacks) ~= 'number' or stacks < 0 then
                SAO:Warn(Module, "Invalid stack count "..tostring(stacks));
            elseif bucket and bucket.stackAgnostic then
                self:setMaskedHash(HASH_AURA_ANY, HASH_AURA_MASK);
            elseif stacks > 10 then
                SAO:Debug(Module, "Stack overflow ("..stacks..") truncated to 10");
                self:setMaskedHash(HASH_AURA_MAX, HASH_AURA_MASK);
            else
                self:setMaskedHash(HASH_AURA_ZERO + stacks, HASH_AURA_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_AURA_MASK);
            if maskedHash == nil then return nil; end

            if maskedHash == HASH_AURA_ABSENT then
                return nil;
            end
            return maskedHash - HASH_AURA_ZERO;
        end,
        toAnyFunc = function(self)
            return bit.band(self.hash, bit.bnot(HASH_AURA_MASK)) + HASH_AURA_ANY;
        end,

        toValue = function(hash)
            local auraStacks = hash:getAuraStacks();
            return (auraStacks == nil) and "missing" or (auraStacks == 0 and "any" or tostring(auraStacks));
        end,
        fromValue = function(hash, value)
            if value == "missing" then
                hash:setAuraStacks(nil);
                return true;
            elseif value == "any" then
                hash:setAuraStacks(0);
                return true;
            elseif tostring(tonumber(value)) == value then
                hash:setAuraStacks(tonumber(value));
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            local auraStacks = hash:getAuraStacks();
            if auraStacks and auraStacks > 0 then
                return SAO:NbStacks(auraStacks);
            elseif auraStacks == nil then
                return ACTION_SPELL_AURA_REMOVED_DEBUFF;
            else
                return nil; -- Should be obvious if aura is 'any'
            end
        end,
        optionIndexer = function(hash)
            return hash:getAuraStacks() or -1; -- returns n if n >= 0, otherwise (if n == nil) returns -1
        end,
    },

    bucket = {
        impossibleValue = -1,
        fetchAndSet = function(bucket)
            local auraStacks = SAO:GetPlayerAuraStacksBySpellID(bucket.spellID);
            if auraStacks ~= nil then
                if bucket.stackAgnostic then
                    bucket:setAuraStacks(0);
                else
                    bucket:setAuraStacks(auraStacks);
                end
            else
                bucket:setAuraStacks(nil);
            end
        end,
    },

    event = {
        isRequired = true,
        names = { "COMBAT_LOG_EVENT_UNFILTERED" },
        -- COMBAT_LOG_EVENT_UNFILTERED = function(...) -- Special case: handled by events.lua
    },

    condition = {
        noeVar = "aura",
        hreVar = "stacks",
        noeDefault = 0,
        description = "number of stacks",
        checker = function(value) return type(value) == 'number' and value >= -1 and value <= 10 end,
        noeToHash = function(value) return value >= 0 and value or nil end, -- return n if n >= 0, otherwise (if n == -1) return nil
    },

    import = {
        noeTrigger = "aura",
        hreTrigger = "requireAura",
        dependency = nil, -- Actually, aura stacks depend on 'spellID', but this property is mandatory and automatically imported
        classes = {
            force = "aura",
            ignore = nil,
        },
    },
});
