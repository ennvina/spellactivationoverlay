local AddonName, SAO = ...
local Module = "actionusable"

-- Optimize frequent calls
local GetSpellCooldown = GetSpellCooldown
local GetSpellPowerCost = GetSpellPowerCost
local IsUsableSpell = IsUsableSpell

-- Action usable or not
local HASH_ACTION_USABLE_NO   = 0x10
local HASH_ACTION_USABLE_YES  = 0x20
local HASH_ACTION_USABLE_MASK = 0x30

-- List of timers trying to retry manual checks of action usable
local ActionRetryTimers = {}

SAO.Variable:register({
    order = 2,
    core = "ActionUsable",

    trigger = {
        flag = SAO.TRIGGER_ACTION_USABLE,
        name = "action",
    },

    hash = {
        mask = HASH_ACTION_USABLE_MASK,
        key = "action",

        setterFunc = function(self, usable)
            if type(usable) ~= 'boolean' then
                SAO:Warn(Module, "Invalid Action Usable flag "..tostring(usable));
            else
                local maskedHash = usable and HASH_ACTION_USABLE_YES or HASH_ACTION_USABLE_NO;
                self:setMaskedHash(maskedHash, HASH_ACTION_USABLE_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_ACTION_USABLE_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_ACTION_USABLE_YES;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local actionUsable = hash:getActionUsable();
            return actionUsable and "usable" or "not_usable";
        end,
        fromValue = function(hash, value)
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
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getActionUsable() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            local spellID = bucket.actionSpellID;

            if not SAO:IsSpellLearned(spellID) then
                -- Spell not learned
                bucket:setActionUsable(false);
                return;
            end

            local start, duration, enabled, modRate = GetSpellCooldown(spellID);
            if type(start) ~= "number" then
                -- Spell not available
                bucket:setActionUsable(false);
                return;
            end

            local isActionUsable, notEnoughPower = IsUsableSpell(spellID);

            local gcdDuration = SAO:GetGCD();
            local isGCD = duration <= gcdDuration;
            local isActionOnCD = start > 0 and not isGCD;

            -- Non-mana spells and abilities should always be considered usable, regardless of player's current resources
            local costsMana = false;
            for _, spellCost in ipairs(GetSpellPowerCost(spellID) or {}) do
                if spellCost.name == "MANA" then
                    costsMana = true;
                    break;
                end
            end

            -- Evaluate whether or not the action is actually usable
            local usable = not isActionOnCD and (isActionUsable or (notEnoughPower and not costsMana));

            if isActionUsable and isActionOnCD then
                -- Action could be usable, but CD prevents us to: try again in a few seconds
                local endTime = start+duration;

                if (not ActionRetryTimers[spellID] or ActionRetryTimers[spellID].endTime ~= endTime) then
                    if (ActionRetryTimers[spellID]) then
                        ActionRetryTimers[spellID]:Cancel();
                    end

                    local remainingTime = endTime-GetTime();
                    local delta = 0.05; -- Add a small delay to account for lags and whatnot
                    local retryFunc = function()
                        bucket.trigger:manualCheck(SAO.TRIGGER_ACTION_USABLE);
                    end;
                    ActionRetryTimers[spellID] = C_Timer.NewTimer(remainingTime+delta, retryFunc);
                    ActionRetryTimers[spellID].endTime = endTime;
                end
            end

            bucket:setActionUsable(usable);
        end,
    },

    event = {
        isRequired = true,
        names = { "PLAYER_ENTERING_WORLD", "SPELL_UPDATE_USABLE" },
        PLAYER_ENTERING_WORLD = function()
            C_Timer.NewTimer(1, function()
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_ACTION_USABLE);
            end);
        end,
        SPELL_UPDATE_USABLE = function()
            SAO:CheckManuallyAllBuckets(SAO.TRIGGER_ACTION_USABLE);
        end,
    },

    condition = {
        noeVar = "action",
        hreVar = "actionUsable",
        noeDefault = true,
        description = "action usable flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "action",
        hreTrigger = "actionUsable",
        dependency = {
            name = "action",
            expectedType = "number",
            default = function(effect) return effect.spellID end,
            prepareBucket = function(bucket, value)
                bucket.actionSpellID = value;
                if not GetSpellInfo(value) then
                    SAO:Warn(Module, bucket.description.." requires action usable with spell "..value..", but the spell does not exist");
                end
            end,
        },
        classes = {
            force = "counter",
            ignore = nil,
        },
    },
});
