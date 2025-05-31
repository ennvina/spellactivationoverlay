local AddonName, SAO = ...
local Module = "stance"

-- Optimize frequent calls
local GetShapeshiftForm = GetShapeshiftForm
local GetShapeshiftFormInfo = GetShapeshiftFormInfo

-- Does the current stance match one of the expected stances
local HASH_STANCE_NO   = 0x08000
local HASH_STANCE_YES  = 0x10000
local HASH_STANCE_MASK = 0x18000

SAO.Variable:register({
    order = 7,
    core = "MatchStance",

    trigger = {
        flag = SAO.TRIGGER_STANCE,
        name = "stance",
    },

    hash = {
        mask = HASH_STANCE_MASK,
        key = "match_stance",

        setterFunc = function(self, matchStance)
            if type(matchStance) ~= 'boolean' then
                SAO:Warn(Module, "Invalid MatchStance flag "..tostring(matchStance));
            else
                local maskedHash = matchStance and HASH_STANCE_YES or HASH_STANCE_NO;
                self:setMaskedHash(maskedHash, HASH_STANCE_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_STANCE_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_STANCE_YES;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local stance = hash:getMatchStance();
            return stance and "yes" or "no";
        end,
        fromValue = function(hash, value)
            if value == "yes" then
                hash:setMatchStance(true);
                return true;
            elseif value == "no" then
                hash:setMatchStance(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getMatchStance() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            local currentStanceIndex = GetShapeshiftForm();
            if currentStanceIndex == nil then
                bucket:setMatchStance(nil);
            elseif currentStanceIndex == 0 then
                bucket:setMatchStance(false);
            else
                local _, _, _, currentStanceSpellID = GetShapeshiftFormInfo(currentStanceIndex);
                if not currentStanceSpellID then
                    bucket:setMatchStance(nil);
                elseif bucket.stanceID then
                    bucket:setMatchStance(currentStanceSpellID == bucket.stanceID);
                elseif bucket.stanceIDs then
                    -- When checking a list of stances, at least one stance must match
                    for _, expectedStanceID in ipairs(bucket.stanceIDs) do
                        if currentStanceSpellID == expectedStanceID then
                            bucket:setMatchStance(true);
                            return;
                        end
                    end
                    bucket:setMatchStance(false);
                end
            end
        end,
    },

    event = {
        isRequired = true,
        names = { "UPDATE_SHAPESHIFT_FORM" },
        UPDATE_SHAPESHIFT_FORM = function(...)
            SAO:CheckManuallyAllBuckets(SAO.TRIGGER_STANCE);
        end,
    },

    condition = {
        noeVar = "stance",
        hreVar = "matchStance",
        noeDefault = true,
        description = "stance match flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "stance",
        hreTrigger = "useStance",
        dependency = {
            name = "stances",
            expectedType = "table",
            default = function(effect) return nil end, -- Make the 'stances' property mandatory
            prepareBucket = function(bucket, value)
                if #value == 1 then
                    bucket.stanceID = value[1];
                else
                    bucket.stanceIDs = value;
                end
            end,
        },
        classes = {
            force = nil,
            ignore = nil,
        },
    },
});
