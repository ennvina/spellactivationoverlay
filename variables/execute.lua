local AddonName, SAO = ...
local Module = "execute"

-- Optimize frequent calls
local UnitCanAttack = UnitCanAttack
local UnitExists = UnitExists
local UnitHealth = UnitHealth
local UnitHealthMax = UnitHealthMax

-- Can execute the current enemy target
--  if player has a target and if player can attack target then
--      if target < threshold then
--          hash = HASH_EXECUTE_HP_BELOW
--      else
--          hash = HASH_EXECUTE_HP_ABOVE
--      end
--  else
--      hash = HASH_EXECUTE_NO_ENEMY_TARGET
--  end
local HASH_EXECUTE_NO_ENEMY_TARGET = 0x0800
local HASH_EXECUTE_HP_BELOW        = 0x1000
local HASH_EXECUTE_HP_ABOVE        = 0x1800
local HASH_EXECUTE_MASK            = 0x1800

SAO.Variable:register({
    order = 5,
    core = "Execute",

    trigger = {
        flag = SAO.TRIGGER_EXECUTE,
        name = "execute",
    },

    hash = {
        mask = HASH_EXECUTE_MASK,
        key = "exec",

        setterFunc = function(self, executable)
            if type(executable) ~= 'boolean' and executable ~= nil then
                SAO:Warn(Module, "Invalid Executable value "..tostring(executable));
            else
                local maskedHash;
                if executable == true then
                    maskedHash = HASH_EXECUTE_HP_BELOW;
                elseif executable == false then
                    maskedHash = HASH_EXECUTE_HP_ABOVE;
                else
                    maskedHash = HASH_EXECUTE_NO_ENEMY_TARGET;
                end
                self:setMaskedHash(maskedHash, HASH_EXECUTE_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_EXECUTE_MASK);
            if maskedHash == nil then return nil; end -- May be mistaken with 'no enemy target'

            if maskedHash == HASH_EXECUTE_HP_BELOW then
                return true;
            elseif maskedHash == HASH_EXECUTE_HP_ABOVE then
                return false;
            else -- maskedHash == HASH_EXECUTE_NO_ENEMY_TARGET
                return nil;
            end
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local execute = hash:getExecute();
            if type(execute) == 'boolean' then
                return execute and "yes" or "no";
            else
                return "no_enemy_target";
            end
        end,
        fromValue = function(hash, value)
            if value == "yes" then
                hash:setExecute(true);
                return true;
            elseif value == "no" then
                hash:setExecute(false);
                return true;
            elseif value == "no_enemy_target" then
                hash:setExecute(nil);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Cannot tell exaclty, because it depends on a threshold known by bucket only
        end,
        optionIndexer = function(hash)
            local execute = hash:getExecute();
            if execute == true then
                return 0;
            elseif execute == false then
                return 1;
            else
                return -1;
            end
        end,
    },

    bucket = {
        impossibleValue = -1,
        fetchAndSet = function(bucket)
            if UnitCanAttack("player", "target") then
                local hp = UnitHealth("target");
                local hpMax = UnitHealthMax("target");
                if hp == 0 then
                    bucket:setExecute(nil);
                else
                    local canExecute = hp/hpMax < (bucket.execThreshold or 0.2);
                    bucket:setExecute(canExecute);
                end
            else
                bucket:setExecute(nil);
            end
        end,
    },

    event = {
        isRequired = true,
        names = { "PLAYER_TARGET_CHANGED", "UNIT_HEALTH", "UNIT_HEALTH_FREQUENT" },
        PLAYER_TARGET_CHANGED = function()
            if not UnitExists("target") or not UnitCanAttack("player", "target") then
                local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_EXECUTE);
                for _, bucket in ipairs(buckets or {}) do
                    bucket:setExecute(nil);
                end
            else
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_EXECUTE);
            end
        end,
        UNIT_HEALTH = function(unitID)
            if unitID == "target" then
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_EXECUTE);
            end
        end,
        UNIT_HEALTH_FREQUENT = function(unitID)
            if unitID == "target" and SAO:IsResponsiveMode() then
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_EXECUTE);
            end
        end
    },

    condition = {
        noeVar = "execute",
        hreVar = "exec",
        noeDefault = 0,
        description = "execute flag",
        checker = function(value) return type(value) == 'number' and value >= -1 and value <= 1 end,
        noeToHash = function(value)
            if value == 0 then
                return true;
            elseif value == 1 then
                return false;
            else
                return nil;
            end
        end,
    },

    import = {
        noeTrigger = "execute",
        hreTrigger = "useExecute",
        dependency = {
            name = "execThreshold",
            expectedType = "number",
            default = 0.2,
            prepareBucket = function(bucket, value)
                if value > 1 then -- Assume threshold greater than 1 are percentages
                    bucket.execThreshold = value / 100;
                else
                    bucket.execThreshold = value;
                end
            end,
        },
        classes = {
            force = "execute",
            ignore = nil,
        },
    },
});
