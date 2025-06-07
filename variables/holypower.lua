local AddonName, SAO = ...
local Module = "holypower"

-- Optimize frequent calls
local UnitPower = UnitPower
local EnumHolyPower = Enum and Enum.PowerType and Enum.PowerType.HolyPower

local HolyPowerPowerTypeToken = "HOLY_POWER"

-- Holy Power, starting at Cataclysm
-- hash = HASH_HOLY_POWER_0 * (1 + holy_power)
local HASH_HOLY_POWER_0    = 0x100
local HASH_HOLY_POWER_1    = 0x200
local HASH_HOLY_POWER_2    = 0x300
local HASH_HOLY_POWER_3    = 0x400
local HASH_HOLY_POWER_4    = 0x500
local HASH_HOLY_POWER_5    = 0x600
local HASH_HOLY_POWER_MASK = 0x700

-- The Holy Power variable was designed for Paladins of Cataclysm
-- Over time, the game has had its share of new resources for other classes
-- Instead of creating a new variable every time, each class-specific resource can have a variable using this file
-- If the term 'Holy Power' becomes too confusing, the variable can be renamed e.g. 'Class Power'

local playerClass = select(2, UnitClass("player"));
local isPlayerClassValid = playerClass == "PALADIN";

local requiredProject = SAO.CATA_AND_ONWARD;

local minimumLevel = PALADINPOWERBAR_SHOW_LEVEL or 9;

local FormatHolyPower = function(holyPower)
    return string.format(HOLY_POWER_COST, holyPower);
end

-- maxHolyPower is the only constant that does not adapt to class
-- Adapting to class could invalidate class-agnostic stuff, such as option indexes
local maxHolyPower = SAO.IsCata() and 3 or 5; -- 3 for Cata, 5 for MoP+
local maxShadowOrbs = 3;
local maxValue = math.max(maxHolyPower, maxShadowOrbs);

-- Readjust constants if playing a class other than paladin (except maxHolyPower, see above)
-- This is a bit clunky but way more efficient than handling multi-class tables, and less error-prone
if playerClass == "PRIEST" then
    EnumHolyPower = Enum and Enum.PowerType and Enum.PowerType.ShadowOrbs;
    HolyPowerPowerTypeToken = "SHADOW_ORBS";
    isPlayerClassValid = true;
    requiredProject = SAO.MOP + SAO.WOD;
    minimumLevel = SHADOW_ORBS_SHOW_LEVEL or 10;
    FormatHolyPower = function(holyPower)
        if holyPower == 3 then
            return SHADOW_ORBS_COST; -- "All Shadow Orbs"
        end
        return string.format("%s %s", holyPower, SHADOW_ORBS);
    end
end

local canUseHolyPower = false;
if SAO.IsProject(requiredProject) and isPlayerClassValid then
    if UnitLevel("player") >= minimumLevel then
        canUseHolyPower = true;
    else
        local levelTracker = CreateFrame("Frame", "SpellActivationOverlayHolyPowerLevelTracker");
        levelTracker:RegisterEvent("PLAYER_LEVEL_UP");
        levelTracker:SetScript("OnEvent", function (self, event, level)
            if level >= minimumLevel then
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
            elseif holyPower > maxValue then
                SAO:Debug(Module, "Holy Power overflow ("..holyPower..") truncated to "..maxValue);
                self:setMaskedHash(HASH_HOLY_POWER_0 + maxValue, HASH_HOLY_POWER_MASK);
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
            return FormatHolyPower(holyPower);
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
                    local holyPower = UnitPower("player", EnumHolyPower);
                    bucket:setHolyPower(holyPower);
                end
            else
                local classAddendum = playerClass == "PALADIN" and "" or ("(or equivalent resource for "..tostring(playerClass)..") ")
                SAO:Debug(Module, "Cannot fetch Holy Power "..classAddendum.."because such resource is unknown from Enum.PowerType");
            end
        end,
    },

    event = {
        isRequired = SAO.IsProject(requiredProject) and isPlayerClassValid,
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
        checker = function(value) return type(value) == 'number' and value >= 0 and value <= maxValue end,
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
