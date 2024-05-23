local AddonName, SAO = ...
local Module = "hash"

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
local HASH_AURA_MAX    = HASH_AURA_ZERO + 9 -- Allow no more than 9 stacks
local HASH_AURA_MASK   = 0xF

local HashStringifierList = {}
local HashStringifierMap = {}

SAO.HashStringifier = {
    register = function(self, order, mask, key, toValue, fromValue, getHumanReadableKeyValue, optionIndexer)
        local stringifier = {
            order = order,
            mask = mask,
            key = key,

            toValue = toValue,
            fromValue = fromValue,
            getHumanReadableKeyValue = getHumanReadableKeyValue,
            optionIndexer = optionIndexer,
        }

        self.__index = nil;
        setmetatable(stringifier, self);
        self.__index = self;

        tinsert(HashStringifierList, stringifier);
        table.sort(HashStringifierList, function(s1, s2) return s1.order < s2.order end);
        HashStringifierMap[stringifier.key] = stringifier;
    end,

    -- Returns the key/value string, or nil if the flag is not set with the stringifier mask
    toKeyValue = function(self, hash)
        if bit.band(hash.hash, self.mask) == 0 then
            return nil;
        end
        local value = self.toValue(hash);
        return self.key..'='..value;
    end,

    -- Returns true if the value was set, false is something went wrong
    fromKeyValue = function(self, hash, key, value)
        if key ~= self.key then
            SAO:Error(Module, "Wrong stringifier called to convert key/value "..tostring(key).."="..tostring(value));
            return false;
        end
        return self.fromValue(hash, value) ~= nil;
    end,

    -- Returns a string telling what the hash does
    -- Returns nil if either the flag is not set, or the text is irrelevant / obvious
    toHumanReadableString = function(self, hash)
        if bit.band(hash.hash, self.mask) == 0 then
            return nil;
        end
        return self.getHumanReadableKeyValue(hash);
    end,

    -- Returns a trivial index for options, if there is one
    -- Returns either 0 if trivial, or nonzero if non trivial
    getOptionIndex = function(self, hash)
        if bit.band(hash.hash, self.mask) == 0 then
            return 0;
        end
        return self.optionIndexer(hash);
    end,
}

SAO.HashStringifier:register(
    1,
    HASH_AURA_MASK,
    "aura_stacks", -- key
    function(hash) -- toValue()
        local auraStacks = hash:getAuraStacks();
        return (auraStacks == nil) and "missing" or (auraStacks == 0 and "any" or tostring(auraStacks));
    end,
    function(hash, value) -- fromValue()
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
    function(hash) -- getHumanReadableKeyValue
        local auraStacks = hash:getAuraStacks();
        if auraStacks and auraStacks > 0 then
            return SAO:NbStacks(auraStacks);
        elseif auraStacks == nil then
            return ACTION_SPELL_AURA_REMOVED_DEBUFF;
        else
            return nil; -- Should be obvious if aura is 'any'
        end
    end,
    function(hash) -- optionIndexer
        return hash:getAuraStacks() or -1; -- returns n if n > 0, otherwise (if n == nil) returns -1
    end
);


SAO.Hash = {
    new = function(self, initialHash)
        local hash = { hash = initialHash or 0 }
        self.__index = nil;
        setmetatable(hash, self);
        self.__index = self;
        return hash;
    end,

    reset = function(self)
        self.hash = 0;
    end,

    setMaskedHash = function(self, maskedHash, mask)
        self.hash = bit.band(self.hash, bit.bnot(mask)) + maskedHash;
    end,

    getMaskedHash = function(self, mask)
        local maskedHash = bit.band(self.hash, mask);
        if maskedHash == 0 then
            SAO:Debug(Module, "Cannot convert hash ("..tostring(self.hash)..") with mask "..tostring(mask));
            return nil; -- Potential issue: for aura stacks, may be mistaken with 'aura absent'
        end
        return maskedHash;
    end,

    -- Aura Stacks

    hasAuraStacks = function(self)
        return bit.band(self.hash, HASH_AURA_MASK) ~= 0;
    end,

    setAuraStacks = function(self, stacks, bucket)
        if stacks == nil then
            self:setMaskedHash(HASH_AURA_ABSENT, HASH_AURA_MASK);
        elseif type(stacks) ~= 'number' or stacks < 0 then
            SAO:Warn(Module, "Invalid stack count "..tostring(stacks));
        elseif bucket and bucket.stackAgnostic then
            self:setMaskedHash(HASH_AURA_ANY, HASH_AURA_MASK);
        elseif stacks > 9 then
            SAO:Debug(Module, "Stack overflow ("..stacks..") truncated to 9");
            self:setMaskedHash(HASH_AURA_MAX, HASH_AURA_MASK);
        else
            self:setMaskedHash(HASH_AURA_ZERO + stacks, HASH_AURA_MASK);
        end
    end,

    getAuraStacks = function(self)
        local maskedHash = self:getMaskedHash(HASH_AURA_MASK);
        if maskedHash == nil then return nil; end

        if maskedHash == HASH_AURA_ABSENT then
            return nil;
        end
        return maskedHash - HASH_AURA_ZERO;
    end,

    toAnyAuraStacks = function(self)
        return bit.band(self.hash, bit.bnot(HASH_AURA_MASK)) + HASH_AURA_ANY;
    end,

    -- String Conversion functions

    toString = function(self)
        local result = "";

        for _, stringifier in ipairs(HashStringifierList) do
            local keyValue = stringifier:toKeyValue(self);
            if keyValue then
                if result == "" then
                    result = keyValue;
                else
                    result = result..";"..keyValue;
                end
            end
        end

        return result;
    end,

    fromString = function(self, str)
        --[[ Use a temporary new hash in order to:
            - start from a clean slate
            - rollback automatically, if there is a problem
            Once everything is okay, the temp hash will be set to the current hash
        ]]
        local hash = SAO.Hash:new();
        for keyValue in str:gmatch("([^;]+)") do
            local first, last = strfind(keyValue, '=');
            if not first or not last then
                SAO:Error(Module, "Wrong hash key/value "..tostring(keyValue));
                return;
            end
            local key, value = keyValue:sub(1, first-1), keyValue:sub(last+1);

            local stringifier = HashStringifierMap[key];
            if not stringifier then
                SAO:Error(Module, "Unknown hash key "..tostring(key).." in key/value "..tostring(keyValue));
                return;
            end

            if not stringifier:fromKeyValue(hash, key, value) then
                -- SAO:Error(Module, ...); -- Not message to write here, errors should be written in fromKeyValue call
                return;
            end
        end

        -- Everything's alright: use computed hash
        self.hash = hash.hash;
    end,

    toHumanReadableString = function(self)
        local answers = {};

        for _, stringifier in ipairs(HashStringifierList) do
            local answer = stringifier:toHumanReadableString(self);
            if answer then
                tinsert(answers, answer);
            end
        end

        if #answers > 0 then
            return strjoin(", ", unpack(answers));
        else
            return nil;
        end
    end,

    -- Tries to translate the hash as an obvious index number
    -- If not possible, the string from toString() is returned
    toOptionIndex = function(self)
        local prevIndex = 0;

        for _, stringifier in ipairs(HashStringifierList) do
            local index = stringifier:getOptionIndex(self);
            if index ~= 0 then
                if prevIndex ~= 0 then
                    -- Multiple non-trivial indexes: no luck
                    return self:toString();
                end
                prevIndex = index;
            end
        end

        return prevIndex;
    end,
}
