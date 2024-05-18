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

-- Holy Power
-- hash = HASH_HOLY_POWER_0 * (1 + holy_power)
local HASH_HOLY_POWER_0    = 0x0200
local HASH_HOLY_POWER_1    = 0x0400
local HASH_HOLY_POWER_2    = 0x0600
local HASH_HOLY_POWER_3    = 0x0800
local HASH_HOLY_POWER_MASK = 0x0E00

SAO.Hash = {
    new = function(self, initialHash)
        local hash = { hash = initialHash or 0 }
        self.__index = nil;
        setmetatable(hash, self);
        self.__index = self;
        return hash;
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

    hasAuraStacks = function(self)
        return bit.band(self.hash, HASH_AURA_MASK) ~= 0;
    end,

    setAuraStacks = function(self, stacks, stackAgnostic)
        if stacks == nil then
            self:setMaskedHash(HASH_AURA_ABSENT, HASH_AURA_MASK);
        elseif type(stacks) ~= 'number' or stacks < 0 then
            SAO:Warn(Module, "Invalid stack count "..tostring(stacks));
        elseif stackAgnostic then
            self:setMaskedHash(HASH_AURA_ANY, HASH_AURA_MASK);
        elseif stacks > 99 then
            SAO:Debug(Module, "Stack overflow ("..stacks..") truncated to 99");
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

    hasActionUsable = function(self)
        return bit.band(self.hash, HASH_ACTION_USABLE_MASK) ~= 0;
    end,

    setActionUsable = function(self, usable)
        if type(usable) ~= 'boolean' then
            SAO:Warn(Module, "Invalid Action Usable flag "..tostring(usable));
        else
            local maskedHash = usable and HASH_ACTION_USABLE_YES or HASH_ACTION_USABLE_NO;
            self:setMaskedHash(maskedHash, HASH_ACTION_USABLE_MASK);
        end
    end,

    isActionUsable = function(self)
        local maskedHash = self:getMaskedHash(HASH_ACTION_USABLE_MASK);
        if maskedHash == nil then return nil; end

        return maskedHash == HASH_ACTION_USABLE_YES;
    end,

    hasHolyPower = function(self)
        return bit.band(self.hash, HASH_HOLY_POWER_MASK) ~= 0;
    end,

    setHolyPower = function(self, holyPower)
        if type(holyPower) ~= 'number' or holyPower < 0 then
            SAO:Warn(Module, "Invalid Holy Power "..tostring(holyPower));
        elseif holyPower > 3 then
            SAO:Debug(Module, "Holy Power overflow ("..holyPower..") truncated to 3");
            self:setMaskedHash(HASH_HOLY_POWER_3, HASH_HOLY_POWER_MASK);
        else
            self:setMaskedHash(HASH_HOLY_POWER_0 * (1 + holyPower), HASH_HOLY_POWER_MASK);
        end
    end,

    getHolyPower = function(self)
        local maskedHash = self:getMaskedHash(HASH_HOLY_POWER_MASK);
        if maskedHash == nil then return nil; end

        return (maskedHash / HASH_HOLY_POWER_0) - 1;
    end,
}
