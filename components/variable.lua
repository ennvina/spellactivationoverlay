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
    elseif type(expectedType) == 'string' then
        if not var[member] then
            error("Variable does not define a "..tostring(member));
        elseif type(var[member]) ~= expectedType then
            error("Variable defines member "..tostring(member).." of type '"..type(var[member]).."' instead of '"..expectedType.."'");
        end
    else -- type(expectedType) == 'table'
        for _, expType in ipairs(expectedType) do
            if type(var[member]) == expType then
                return;
            end
        end
        error("Variable defines member "..tostring(member).." of type '"..type(var[member]).."' instead of '"..strjoin("' or '", unpack(expectedType)).."'");
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

        check(var, "core", 'string'); -- "HolyPower", used for hasHolyPower, getHolyPower, setHolyPower, etc.

        check(var, "trigger", 'table');
        check(var.trigger, "flag", 'number'); -- TRIGGER_HOLY_POWER
        check(var.trigger, "name", 'string'); -- "holyPower"

        check(var, "hash", 'table');
        check(var.hash, "mask", 'number'); -- HASH_HOLY_POWER_MASK
        check(var.hash, "key", 'string'); -- "holy_power"
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
        check(var.hash, "toAnyFunc", { 'function', 'nil' }); -- nil means there is no 'toAnyX' method
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
        -- check(var.bucket, "impossibleValue", 'any'); -- can be anything, usually nil or -1
        --[[ function(bucket)
            if Enum and Enum.PowerType and Enum.PowerType.HolyPower then
                local holyPower = UnitPower("player", Enum.PowerType.HolyPower);
                bucket:setHolyPower(holyPower);
            else
                SAO:Debug(Module, "Cannot fetch Holy Power because this resource is unknown from Enum.PowerType");
            end
        end]]
        check(var.bucket, "fetchAndSet", 'function'); -- Added in TriggerManualChecks

        check(var, "event", 'table');
        check(var.event, "isRequired", { 'boolean', 'function' }); -- SAO.IsCata() and select(2, UnitClass("player")) == "PALADIN"
        check(var.event, "names", 'table'); -- { "UNIT_POWER_FREQUENT" }
        for _, eventName in ipairs(var.event.names or {}) do
            check(var.event, eventName, { 'function', 'nil' });
        end

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
        check(var.import, "depencency", { 'table', 'nil' });
        if type(var.import.dependency) == 'table' then
            check(var.import.dependency, "name", 'string'); -- "execValue"
            check(var.import.dependency, "expectedType", 'string'); -- "number"
            check(var.import.dependency, "default", { 'nil', var.import.dependency.expectedType, 'function' }); -- 25
            check(var.import.dependency, "prepareBucket", 'function'); -- function(bucket, value) bucket.execValue = value end
        end
        check(var.import, "classes", { 'table', 'nil' });
        if type(var.import.classes) == 'table' then
            check(var.import.classes, "force", { 'string', 'table', 'nil' });
            check(var.import.classes, "ignore", { 'string', 'table', 'nil' });
        end

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
        SAO.Hash["has"..var.core] = function(hash) return bit.band(hash.hash, var.hash.mask) ~= 0 end;
        SAO.Hash["set"..var.core] = var.hash.setterFunc;
        SAO.Hash["get"..var.core] = var.hash.getterFunc;
        if var.hash.toAnyFunc then
            SAO.Hash["toAny"..var.core] = var.hash.toAnyFunc;
        end

        -- Add the bucket setter directly to the bucket class declaration
        SAO.Bucket["set"..var.core] = function(bucket, value)
            if bucket.currentState["current"..var.core] == value then
                return;
            end
            bucket.currentState["current"..var.core] = value;
            bucket.trigger:inform(var.trigger.flag);
            bucket.hashCalculator["set"..var.core](bucket.hashCalculator, value, bucket);
            if bucket.trigger:isFullyInformed() then
                bucket:applyHash();
            end
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
            "set"..var.core, -- Setter method for Hash
            var.condition.description,
            var.condition.checker,
            var.condition.noeToHash
        );

        if type(var.event.isRequired) == 'function' and var.event.isRequired()
        or type(var.event.isRequired) == 'boolean' and var.event.isRequired then
            for _, eventName in ipairs(var.event.names or {}) do
                if var.event[eventName] then
                    if SAO.VariableEventProxy[eventName] then
                        tinsert(SAO.VariableEventProxy[eventName], var);
                    else
                        SAO.VariableEventProxy[eventName] = { var };
                    end
                end
            end
        end

        SAO.VariableImporter[var.trigger.flag] = function(effect, props, class)
            local ignoreClasses = var.import.classes and var.import.classes.ignore and var.import.classes.ignore;
            local forceClasses = var.import.classes and var.import.classes.force and var.import.classes.force;

            if type(ignoreClasses) == 'string' and ignoreClasses == class
            or type(ignoreClasses) == 'table' and tContains(ignoreClasses, class) then
                return;
            end

            local triggerName = var.import.noeTrigger;

            if type(forceClasses) == 'string' and forceClasses == class
            or type(forceClasses) == 'table' and tContains(forceClasses, class) then
                effect.triggers[triggerName] = true;
            elseif type(props) ~= 'table' then
                effect.triggers[triggerName] = false;
            else
                local propName = var.import.hreTrigger;
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

            local dependency = var.import.dependency;
            if dependency then
                local depName, depType, depDefault = dependency.name, dependency.expectedType, dependency.default;
                if type(props) == 'table' and type(props[depName]) == depType then
                    effect[depName] = props[depName];
                elseif type(props) == 'table' and type(props[depName]) == 'table' then
                    for project, talent in pairs(props[depName]) do
                        if SAO.IsProject(project) then
                            effect[depName] = talent;
                            break;
                        end
                    end
                elseif type(props) ~= 'table' or props[depName] == nil then
                    if type(depDefault) == 'function' then
                        effect[depName] = depDefault(effect);
                    else
                        effect[depName] = depDefault;
                    end
                end
                if effect[depName] == nil and depDefault ~= nil then
                    SAO:Debug(Module, "Missing dependency "..tostring(depName).." for effect "..tostring(effect.name));
                elseif type(effect[depName]) ~= depType and type(depDefault) == depType then
                    SAO:Debug(Module, "Wrong type for dependency "..tostring(depName).." of effect "..tostring(effect.name));
                end
            end
        end

        self.__index = nil;
        setmetatable(var, self);
        self.__index = self;

        SAO.Variables[var.trigger.flag] = var;
    end
}

SAO.VariableState = {
    new = function(self, parent) -- parent is the bucket attached to the new state
        local state = { parent = parent }

        self.__index = nil;
        setmetatable(state, self);
        self.__index = self;

        -- state:reset(); -- No need to reset now, trigger flags are probably not set yet
        return state;
    end,

    reset = function(self)
        for _, var in pairs(SAO.Variables) do
            if self.parent.trigger:reactsWith(var.trigger.flag) then
                self["current"..var.core] = var.bucket.impossibleValue;
            end
        end
    end,
}

SAO.VariableImporter = {
    importTrigger = function(self, flag, effect, props, class)
        if self[flag] then
            self[flag](effect, props, class);
        end
    end,
}

SAO.VariableEventProxy = {
    OnEvent = function(self, event, ...)
        for _, var in ipairs(self[event] or {}) do
            var.event[event](...);
        end
    end,
}
