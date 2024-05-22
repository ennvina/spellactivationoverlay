local AddonName, SAO = ...
local Module = "variable"

-- Variable definition map
-- key = trigger flag, value = variable object
SAO.Variables = {}

local function error(msg)
    if SAO.Error then
        SAO:Error(Module, msg);
    else
        print(WrapTextInColor("**SAO** -"..Module.."- "..msg, RED_FONT_COLOR));
    end
end

local function check(var, member, expectedType)
    if type(var) ~= 'table' then
        return;
    elseif not var[member] then
        error("Variable does not define a "..tostring(member));
    elseif type(var[member]) ~= expectedType then
        error("Variable defines member "..tostring(member).." of type '"..type(var[member]).."' instead of '"..expectedType.."'");
    end
end

local function getName(var)
    -- For debugging purposes, exact name does not really matter as long as we can identify which variable goes wrong
    return type(var) == 'table' and type(var.hash) == 'table' and tostring(var.hash.key) or "<unknown variable>";
end

SAO.Variable = {
    register = function(self, var)
        check(var, "order", 'number'); -- Unique number
        -- This order must be stable over patches, because it is used to index saved variables
        -- Only the order must be stable: if x < y in patch A, then x must be < y in patch B
        -- However, an eventual new z can be anywhere, even between x and y, as long as the new order is also stable

        check(var, "trigger", 'table');
        check(var.trigger, "flag", 'number'); -- TRIGGER_HOLY_POWER
        check(var.trigger, "name", 'string'); -- "holyPower"

        check(var, "hash", 'table');
        check(var.hash, "mask", 'number'); -- HASH_HOLY_POWER_MASK
        check(var.hash, "key", 'string'); -- "holy_power"
        check(var.hash, "core", 'string'); -- "HolyPower", used for hasHolyPower, getHolyPower, setHolyPower
        --[[ function(self, holyPower, bucket)
            if type(holyPower) ~= 'number' or holyPower < 0 then
                SAO:Warn(Module, "Invalid Holy Power "..tostring(holyPower));
            elseif holyPower > 3 then
                SAO:Debug(Module, "Holy Power overflow ("..holyPower..") truncated to 3");
                setMaskedHash(self, HASH_HOLY_POWER_3, HASH_HOLY_POWER_MASK);
            else
                setMaskedHash(self, HASH_HOLY_POWER_0 * (1 + holyPower), HASH_HOLY_POWER_MASK);
            end
        end]]
        check(var.hash, "setterFunc", 'function');
        --[[ function(self)
            local maskedHash = getMaskedHash(self, HASH_HOLY_POWER_MASK);
            if maskedHash == nil then return nil; end
            return (maskedHash / HASH_HOLY_POWER_0) - 1;
        end]]
        check(var.hash, "getterFunc", 'function');
        -- function(hash) return tostring(hash:getHolyPower()) end
        check(var.hash, "toValue", 'function');
        --[[ function(hash, value)
            if tostring(tonumber(value)) == value then
                hash:setHolyPower(tonumber(value));
                return true;
            else
                return nil; -- Not good
            end
        end]]
        check(var.hash, "fromValue", 'function');
        -- function(hash) return string.format(HOLY_POWER_COST, hash:getHolyPower()) end
        check(var.hash, "getHumanReadableKeyValue", 'function');
        -- function(hash) return hash:getHolyPower() end
        check(var.hash, "optionIndexer", 'function');

        check(var, "bucket", 'table');
        check(var.bucket, "member", 'string'); -- "currentHolyPower"
        -- check(var.bucket, "impossibleValue", 'any'); -- can be anything, usually nil or -1
        check(var.bucket, "setter", 'string'); -- "setHolyPower"
        --[[ function(bucket)
            if Enum and Enum.PowerType and Enum.PowerType.HolyPower then
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower);
                bucket:setHolyPower(holyPower);
            else
                SAO:Debug(Module, "Cannot fetch Holy Power because this resource is unknown from Enum.PowerType");
            end
        end]]
        check(var.bucket, "fetchAndSet", 'function'); -- Formerly in TriggerManualChecks

        check(var, "event", 'table');
        check(var.event, "names", 'table'); -- { "UNIT_POWER_FREQUENT" }
        -- function() return SAO.IsCata() and select(2, UnitClass("player")) == "PALADIN" end
        check(var.event, "isRequired", 'function');

        check(var, "condition", 'table');
        check(var.condition, "noeVar", 'string'); -- "holyPower"
        check(var.condition, "hreVar", 'string'); -- "holyPower"
        -- check(var.condition, "noeDefault", 'any'); -- can be anything, usually 0
        check(var.condition, "description", 'string'); -- "Holy Power value"
        -- function(value) return type(value) == 'number' and value >= 0 and value <= 3 end
        check(var.condition, "checker", 'function');
        -- function(value) return value end
        check(var.condition, "noeToHash", 'function');

        check(var, "import", 'table');
        check(var.import, "noeTrigger", 'string'); -- "holyPower"
        check(var.import, "hreTrigger", 'string'); -- "useHolyPower"

        -- Uniqueness tests
        for _, var2 in pairs(SAO.Variables) do
            if var.order == var2.order then
                error("Variables "..getName(var).." and "..getName(var2).." share the same order "..var.order);
            end
            if bit.band(var.trigger.flag, var2.trigger.flag) ~= 0 then
                local x1 = string.format('0x%X', var.trigger.flag);
                local x2 = string.format('0x%X', var2.trigger.flag);
                error("Variables "..getName(var).." and "..getName(var2).." overlap their trigger flag "..x1.." vs. "..x2);
            end
            if bit.band(var.hash.mask, var2.hash.mask) ~= 0 then
                local x1 = string.format('0x%X', var.hash.mask);
                local x2 = string.format('0x%X', var2.hash.mask);
                error("Variables "..getName(var).." and "..getName(var2).." overlap their hash mask "..x1.." vs. "..x2);
            end
        end

        SAO.TriggerNames[var.trigger.flag] = var.trigger.name;
        SAO.TriggerFlags[var.trigger.name] = var.trigger.flag;
        SAO.RegisteredBucketsByTrigger[var.trigger.flag] = {};

        SAO.TriggerManualChecks[var.trigger.flag] = var.bucket.fetchAndSet;

        -- Add the hash setter and getter directly to the Hash class definition
        SAO.Hash["has"..var.hash.core] = function(hash) return bit.band(hash.hash, var.hash.mask) ~= 0 end;
        SAO.Hash["set"..var.hash.core] = var.hash.setterFunc;
        SAO.Hash["get"..var.hash.core] = var.hash.getterFunc;

        -- Add the bucket setter directly to the bucket class declaration
        SAO.Bucket[var.bucket.setter] = function(bucket, value)
            if bucket[var.bucket.member] == value then
                return;
            end
            bucket.currentState[var.bucket.member] = value;
            bucket.trigger:inform(var.trigger.flag);
            bucket.hashCalculator["set"..var.hash.core](bucket.hashCalculator, value, bucket);
            bucket:applyHash();
        end

        SAO.HashStringifier:register(
            var.order,
            var.hash.mask,
            var.hash.key,
            var.hash.toValue,
            var.hash.fromValue,
            var.hash.getHumanReadableKeyValue,
            var.hash.optionIndexer
        );

        SAO.ConditionBuilder:register(
            var.condition.noeVar, -- Name used by NOE
            var.condition.hreVar, -- Name used by HRE
            var.condition.noeDefault, -- Default (NOE only)
            "set"..var.hash.core, -- Setter method for Hash, comes from var.hash insted of var.condition
            var.condition.description,
            var.condition.checker,
            var.condition.noeToHash
        );

        SAO.VariableImporter[var.trigger.flag] = function(effect, props)
            local triggerName, propName = var.import.noeTrigger, var.import.hreTrigger;

            if type(props) ~= 'table' then
                effect.triggers[triggerName] = false;
                return;
            end

            if type(props[propName]) == 'boolean' then
                effect.triggers[triggerName] = props[propName];
            elseif type(props[propName]) == 'table' then
                for project, prop in pairs(props[propName]) do
                    if SAO.IsProject(project) then
                        effect.triggers[triggerName] = prop;
                        break;
                    end
                end
            else
                effect.triggers[triggerName] = false;
            end
        end

        self.__index = nil;
        setmetatable(var, self);
        self.__index = nil;

        SAO.Variables[var.trigger.flag] = var;
    end
}

SAO.VariableState = {
    new = function(self)
        local state = {}

        self.__index = nil;
        setmetatable(state, self);
        self.__index = self;

        state:reset();
        return state;
    end,

    reset = function(self)
        for _, var in pairs(SAO.Variables) do
            self[var.bucket.member] = var.bucket.impossibleValue;
        end
    end,
}

SAO.VariableImporter = {
    importTrigger = function(self, flag, effect, props)
        if self[flag] then
            self[flag](effect, props);
        end
    end,
}
