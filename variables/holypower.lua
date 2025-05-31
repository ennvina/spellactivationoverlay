local AddonName, SAO = ...
local Module = "holypower"

-- Optimize frequent calls
local UnitPower = UnitPower
local EnumHolyPower = Enum and Enum.PowerType and Enum.PowerType.HolyPower

local HolyPowerPowerTypeToken = "HOLY_POWER"

-- Holy Power, Cataclysm only
-- hash = HASH_HOLY_POWER_0 * (1 + holy_power)
local HASH_HOLY_POWER_0    = 0x100
local HASH_HOLY_POWER_1    = 0x200
local HASH_HOLY_POWER_2    = 0x300
local HASH_HOLY_POWER_3    = 0x400
local HASH_HOLY_POWER_MASK = 0x700

local canUseHolyPower = false;
if SAO.IsCata() and select(2, UnitClass("player")) == "PALADIN" then
    local PALADINPOWERBAR_SHOW_LEVEL = PALADINPOWERBAR_SHOW_LEVEL or 9;
    if UnitLevel("player") >= PALADINPOWERBAR_SHOW_LEVEL then
        canUseHolyPower = true;
    else
        local levelTracker = CreateFrame("Frame", "SpellActivationOverlayHolyPowerLevelTracker");
        levelTracker:RegisterEvent("PLAYER_LEVEL_UP");
        levelTracker:SetScript("OnEvent", function (self, event, level)
            if level >= PALADINPOWERBAR_SHOW_LEVEL then
                canUseHolyPower = true;
                levelTracker:UnregisterEvent("PLAYER_LEVEL_UP");
                levelTracker = nil;
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_HOLY_POWER);
            end
        end);
    end
end

SAO.Variable:register({
    order = 4,
    core = "HolyPower",

    trigger = {
        flag = SAO.TRIGGER_HOLY_POWER,
        name = "holyPower",
    },

    hash = {
        mask = HASH_HOLY_POWER_MASK,
        key = "holy_power",

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
        toAnyFunc = nil,

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
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            if EnumHolyPower then
                if canUseHolyPower then
                    local holyPower = UnitPower("player", Enum.PowerType.HolyPower);
                    bucket:setHolyPower(holyPower);
                end
            else
                SAO:Debug(Module, "Cannot fetch Holy Power because this resource is unknown from Enum.PowerType");
            end
        end,
    },

    event = {
        isRequired = SAO.IsProject(SAO.CATA_AND_ONWARD) and select(2, UnitClass("player")) == "PALADIN",
        names = { "UNIT_POWER_UPDATE", "UNIT_POWER_FREQUENT" },
        UNIT_POWER_UPDATE = function(unitTarget, powerType)
            if unitTarget == "player" and powerType == HolyPowerPowerTypeToken then
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_HOLY_POWER);
            end
        end,
        UNIT_POWER_FREQUENT = function(unitTarget, powerType)
            if unitTarget == "player" and powerType == HolyPowerPowerTypeToken and SAO:IsResponsiveMode() then
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_HOLY_POWER);
            end
        end,
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
        classes = {
            force = nil,
            ignore = nil,
        },
    },
});
