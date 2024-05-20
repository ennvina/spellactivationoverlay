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
local HASH_AURA_MAX    = HASH_AURA_ZERO + 99 -- Allow no more than 99 stacks
local HASH_AURA_MASK   = 0x7F

-- Action usable or not
local HASH_ACTION_USABLE_NO   = 0x080
local HASH_ACTION_USABLE_YES  = 0x100
local HASH_ACTION_USABLE_MASK = 0x180

-- Has spent point in the talent tree
local HASH_TALENT_NO   = 0x200
local HASH_TALENT_YES  = 0x400
local HASH_TALENT_MASK = 0x600

-- Holy Power
-- hash = HASH_HOLY_POWER_0 * (1 + holy_power)
local HASH_HOLY_POWER_0    = 0x0800
local HASH_HOLY_POWER_1    = 0x1000
local HASH_HOLY_POWER_2    = 0x1800
local HASH_HOLY_POWER_3    = 0x2000
local HASH_HOLY_POWER_MASK = 0x3800

-- Check that masks are not overlapping with one another
-- This order must be stable over patches, because it is used to index saved variables
-- Only the order must be stable: if x < y in patch A, then x must be < y in patch B
-- However, a new z can be anywhere, even between x and y, as long as the new order is stable
local masks = {
    HASH_AURA_MASK,
    HASH_ACTION_USABLE_MASK,
    HASH_TALENT_MASK,
    HASH_HOLY_POWER_MASK
}
for i1, mask1 in ipairs(masks) do
    for i2, mask2 in ipairs(masks) do
        if i2 > i1 and bit.band(mask1, mask2) ~= 0 then
            local x1 = string.format('0x%X', mask1);
            local x2 = string.format('0x%X', mask2);
            print(WrapTextInColor("**SAO** -"..Module.."- Overlapping hash mask "..x1.." vs. "..x2, RED_FONT_COLOR));
        end
    end
end

local HashStringifierList = {}
local HashStringifierMap = {}

local HashStringifier = {
    register = function(self, mask, key, toValue, fromValue, getHumanReadableKeyValue, optionIndexer)
        local converter = {
            mask = mask,
            key = key,

            toValue = toValue,
            fromValue = fromValue,
            getHumanReadableKeyValue = getHumanReadableKeyValue,
            optionIndexer = optionIndexer,
        }

        self.__index = nil;
        setmetatable(converter, self);
        self.__index = self;

        tinsert(HashStringifierList, converter);
        HashStringifierMap[converter.key] = converter;
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

HashStringifier:register(
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
        else
            return nil; -- Should be obvious if aura is 'missing' or 'any'
        end
    end,
    function(hash) -- optionIndexer
        return hash:getAuraStacks() or -1; -- returns n if n > 0, otherwise (if n == nil) returns -1
    end
);

HashStringifier:register(
    HASH_ACTION_USABLE_MASK,
    "action", -- key
    function(hash) -- toValue()
        local actionUsable = hash:isActionUsable();
        return actionUsable and "usable" or "not_usable";
    end,
    function(hash, value) -- fromValue()
        if value == "usable" then
            hash:setActionUsable(true);
            return true;
        elseif value == "not_usable" then
            hash:setActionUsable(false);
            return true;
        else
            return nil; -- Not good
        end
    end,
    function(hash) -- getHumanReadableKeyValue
        return nil; -- Should be obvious
    end,
    function(hash) -- optionIndexer
        return hash:isActionUsable() and 0 or -1;
    end
);

HashStringifier:register(
    HASH_TALENT_MASK,
    "talent", -- key
    function(hash) -- toValue()
        local talented = hash:isTalented();
        return talented and "yes" or "no";
    end,
    function(hash, value) -- fromValue()
        if value == "yes" then
            hash:setTalented(true);
            return true;
        elseif value == "no" then
            hash:setTalented(false);
            return true;
        else
            return nil; -- Not good
        end
    end,
    function(hash) -- getHumanReadableKeyValue
        return nil; -- Should be obvious
    end,
    function(hash) -- optionIndexer
        return hash:isTalented() and 0 or -1;
    end
);

HashStringifier:register(
    HASH_HOLY_POWER_MASK,
    "holy_power", -- key
    function(hash) -- toValue()
        local holyPower = hash:getHolyPower();
        return tostring(holyPower);
    end,
    function(hash, value) -- fromValue()
        if tostring(tonumber(value)) == value then
            hash:setHolyPower(tonumber(value));
            return true;
        else
            return nil; -- Not good
        end
    end,
    function(hash) -- getHumanReadableKeyValue
        local holyPower = hash:getHolyPower();
        return string.format(HOLY_POWER_COST, holyPower);
    end,
    function(hash) -- optionIndexer
        return hash:getHolyPower();
    end
);


-- Private methods

local function setMaskedHash(self, maskedHash, mask)
    self.hash = bit.band(self.hash, bit.bnot(mask)) + maskedHash;
end

local function getMaskedHash(self, mask)
    local maskedHash = bit.band(self.hash, mask);
    if maskedHash == 0 then
        SAO:Debug(Module, "Cannot convert hash ("..tostring(self.hash)..") with mask "..tostring(mask));
        return nil; -- Potential issue: for aura stacks, may be mistaken with 'aura absent'
    end
    return maskedHash;
end

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

    -- Aura Stacks

    hasAuraStacks = function(self)
        return bit.band(self.hash, HASH_AURA_MASK) ~= 0;
    end,

    setAuraStacks = function(self, stacks, stackAgnostic)
        if stacks == nil then
            setMaskedHash(self, HASH_AURA_ABSENT, HASH_AURA_MASK);
        elseif type(stacks) ~= 'number' or stacks < 0 then
            SAO:Warn(Module, "Invalid stack count "..tostring(stacks));
        elseif stackAgnostic then
            setMaskedHash(self, HASH_AURA_ANY, HASH_AURA_MASK);
        elseif stacks > 99 then
            SAO:Debug(Module, "Stack overflow ("..stacks..") truncated to 99");
            setMaskedHash(self, HASH_AURA_MAX, HASH_AURA_MASK);
        else
            setMaskedHash(self, HASH_AURA_ZERO + stacks, HASH_AURA_MASK);
        end
    end,

    getAuraStacks = function(self)
        local maskedHash = getMaskedHash(self, HASH_AURA_MASK);
        if maskedHash == nil then return nil; end

        if maskedHash == HASH_AURA_ABSENT then
            return nil;
        end
        return maskedHash - HASH_AURA_ZERO;
    end,

    toAnyAuraStacks = function(self)
        return bit.band(self.hash, bit.bnot(HASH_AURA_MASK)) + HASH_AURA_ANY;
    end,

    basedOnlyOnAuraStacks = function(self) -- Used for legacy code
        return self:hasAuraStacks() and bit.bor(self.hash, HASH_AURA_MASK) == HASH_AURA_MASK;
    end,

    -- Action Usable

    hasActionUsable = function(self)
        return bit.band(self.hash, HASH_ACTION_USABLE_MASK) ~= 0;
    end,

    setActionUsable = function(self, usable)
        if type(usable) ~= 'boolean' then
            SAO:Warn(Module, "Invalid Action Usable flag "..tostring(usable));
        else
            local maskedHash = usable and HASH_ACTION_USABLE_YES or HASH_ACTION_USABLE_NO;
            setMaskedHash(self, maskedHash, HASH_ACTION_USABLE_MASK);
        end
    end,

    isActionUsable = function(self)
        local maskedHash = getMaskedHash(self, HASH_ACTION_USABLE_MASK);
        if maskedHash == nil then return nil; end

        return maskedHash == HASH_ACTION_USABLE_YES;
    end,

    basedOnlyOnActionUsable = function(self) -- Used for legacy code
        return self:hasActionUsable() and bit.bor(self.hash, HASH_ACTION_USABLE_MASK) == HASH_ACTION_USABLE_MASK;
    end,

    -- Talented

    hasTalented = function(self)
        return bit.band(self.hash, HASH_TALENT_MASK) ~= 0;
    end,

    setTalented = function(self, usable)
        if type(usable) ~= 'boolean' then
            SAO:Warn(Module, "Invalid Talented flag "..tostring(usable));
        else
            local maskedHash = usable and HASH_TALENT_YES or HASH_TALENT_NO;
            setMaskedHash(self, maskedHash, HASH_TALENT_MASK);
        end
    end,

    isTalented = function(self)
        local maskedHash = getMaskedHash(self, HASH_TALENT_MASK);
        if maskedHash == nil then return nil; end

        return maskedHash == HASH_TALENT_YES;
    end,

    -- Holy Power

    hasHolyPower = function(self)
        return bit.band(self.hash, HASH_HOLY_POWER_MASK) ~= 0;
    end,

    setHolyPower = function(self, holyPower)
        if type(holyPower) ~= 'number' or holyPower < 0 then
            SAO:Warn(Module, "Invalid Holy Power "..tostring(holyPower));
        elseif holyPower > 3 then
            SAO:Debug(Module, "Holy Power overflow ("..holyPower..") truncated to 3");
            setMaskedHash(self, HASH_HOLY_POWER_3, HASH_HOLY_POWER_MASK);
        else
            setMaskedHash(self, HASH_HOLY_POWER_0 * (1 + holyPower), HASH_HOLY_POWER_MASK);
        end
    end,

    getHolyPower = function(self)
        local maskedHash = getMaskedHash(self, HASH_HOLY_POWER_MASK);
        if maskedHash == nil then return nil; end

        return (maskedHash / HASH_HOLY_POWER_0) - 1;
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
