local AddonName, SAO = ...
local Module = "holypower"

-- Optimize frequent calls
local UnitPower = UnitPower
local EnumHolyPower = Enum and Enum.PowerType and Enum.PowerType.HolyPower

-- Holy Power, Cataclysm only
-- hash = HASH_HOLY_POWER_0 * (1 + holy_power)
local HASH_HOLY_POWER_0    = 0x100
local HASH_HOLY_POWER_1    = 0x200
local HASH_HOLY_POWER_2    = 0x300
local HASH_HOLY_POWER_3    = 0x400
local HASH_HOLY_POWER_MASK = 0x700

SAO.Variable:register({
    order = 4,

    trigger = {
        flag = SAO.TRIGGER_HOLY_POWER,
        name = "holyPower",
    },

    hash = {
        mask = HASH_HOLY_POWER_MASK,
        key = "holy_power",
        core = "HolyPower",
        setterFunc = function(self, holyPower)
            if type(holyPower) ~= 'number' or holyPower < 0 then
                SAO:Warn(Module, "Invalid Holy Power "..tostring(holyPower));
            elseif holyPower > 3 then
                SAO:Debug(Module, "Holy Power overflow ("..holyPower..") truncated to 3");
                self:setMaskedHash(HASH_HOLY_POWER_3, HASH_HOLY_POWER_MASK);
            else
                self:setMaskedHash(HASH_HOLY_POWER_0 * (1 + holyPower), HASH_HOLY_POWER_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_HOLY_POWER_MASK);
            if maskedHash == nil then return nil; end

            return (maskedHash / HASH_HOLY_POWER_0) - 1;
        end,

        toValue = function(hash)
            local holyPower = hash:getHolyPower();
            return tostring(holyPower);
        end,
        fromValue = function(hash, value)
            if tostring(tonumber(value)) == value then
                hash:setHolyPower(tonumber(value));
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            local holyPower = hash:getHolyPower();
            return string.format(HOLY_POWER_COST, holyPower);
        end,
        optionIndexer = function(hash)
            return hash:getHolyPower();
        end,
    },

    bucket = {
        member = "currentHolyPower",
        impossibleValue = nil,
        setter = "setHolyPower",
        fetchAndSet = function(bucket)
            if EnumHolyPower then
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower);
                bucket:setHolyPower(holyPower);
            else
                SAO:Debug(Module, "Cannot fetch Holy Power because this resource is unknown from Enum.PowerType");
            end
        end,
    },

    event = {
        names = { "UNIT_POWER_FREQUENT" },
        isRequired = function() return SAO.IsCata() and select(2, UnitClass("player")) == "PALADIN" end,
    },

    condition = {
        noeVar = "holyPower",
        hreVar = "holyPower",
        noeDefault = 0,
        description = "Holy Power value",
        checker = function(value) return type(value) == 'number' and value >= 0 and value <= 3 end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "holyPower",
        hreTrigger = "useHolyPower",
        dependency = nil, -- No additional dependency value
    },
});
