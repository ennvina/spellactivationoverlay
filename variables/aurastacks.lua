local AddonName, SAO = ...
local Module = "aurastacks"

-- Optimize frequent calls
local canaccessvalue = canaccessvalue
local InCombatLockdown = InCombatLockdown

-- Global variables
SAO.AURASTACKS = {
    LEGACY = C_UnitAuras == nil,
    MODERN = C_UnitAuras ~= nil,
};
assertsafe(SAO.AURASTACKS.LEGACY ~= SAO.AURASTACKS.MODERN); -- Exactly one of these modes must be active
SAO:Info(Module, "You are currently using the Modern AuraStacks mode. Enjoy!"); --[[DEV_ONLY]]

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
local HASH_AURA_MAX    = HASH_AURA_ZERO + 10 -- Allow no more than 10 stacks
local HASH_AURA_MASK   = 0xF

-- Map between aura instance ID and bucket (Modern mode only)
local bucketsByAuraInstanceID = {};

-- Shared variable to optimize manual bucket attempts
local secretBuckets = {};
local secretlessBuckets = {};

SAO.Variable:register({
    order = 1,
    core = "AuraStacks",

    trigger = {
        flag = SAO.TRIGGER_AURA,
        name = "aura",
    },

    hash = {
        mask = HASH_AURA_MASK,
        key = "aura_stacks",

        setterFunc = function(self, stacks, bucket)
            if stacks == nil then
                self:setMaskedHash(HASH_AURA_ABSENT, HASH_AURA_MASK);
            elseif type(stacks) ~= 'number' or stacks < 0 then
                SAO:Warn(Module, "Invalid stack count "..tostring(stacks));
            elseif bucket and bucket.stackAgnostic then
                self:setMaskedHash(HASH_AURA_ANY, HASH_AURA_MASK);
            elseif stacks > 10 then
                SAO:Debug(Module, "Stack overflow ("..stacks..") truncated to 10");
                self:setMaskedHash(HASH_AURA_MAX, HASH_AURA_MASK);
            else
                self:setMaskedHash(HASH_AURA_ZERO + stacks, HASH_AURA_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_AURA_MASK);
            if maskedHash == nil then return nil; end

            if maskedHash == HASH_AURA_ABSENT then
                return nil;
            end
            return maskedHash - HASH_AURA_ZERO;
        end,
        toAnyFunc = function(self)
            return bit.band(self.hash, bit.bnot(HASH_AURA_MASK)) + HASH_AURA_ANY;
        end,

        toValue = function(hash)
            local auraStacks = hash:getAuraStacks();
            return (auraStacks == nil) and "missing" or (auraStacks == 0 and "any" or tostring(auraStacks));
        end,
        fromValue = function(hash, value)
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
        getHumanReadableKeyValue = function(hash)
            local auraStacks = hash:getAuraStacks();
            if auraStacks and auraStacks > 0 then
                -- Aura aims a specific number of stacks
                return SAO:NbStacks(auraStacks);
            elseif auraStacks == nil then
                -- Aura is expected to be missing
                return ACTION_SPELL_AURA_REMOVED_DEBUFF;
            else
                -- assertsafe(aurastacks == 0);
                -- Aura is expected to be present, but we don't care how many stacks it has, a.k.a. it has 'any' stacks
                return nil; -- Should be obvious if aura is 'any'
            end
        end,
        optionIndexer = function(hash)
            return hash:getAuraStacks() or -1; -- returns n if n >= 0, otherwise (if n == nil) returns -1
        end,
    },

    bucket = {
        impossibleValue = -1,
        fetchAndSet = function(bucket)
            if bucket.auraHasSecretRestrictions and InCombatLockdown() then
                -- Cannot fetch aura stacks reliably due to secret restrictions while in combat
                return;
            end

            local auraStacks, auraInstanceID = SAO:GetPlayerAuraStacksBySpellID(bucket.spellID);
            if auraStacks ~= nil then
                if bucket.stackAgnostic then
                    bucket:setAuraStacks(0);
                else
                    bucket:setAuraStacks(auraStacks);
                end
            else
                bucket:setAuraStacks(nil);
            end

            if SAO.AURASTACKS.MODERN then -- Additional handling to optimize Modern mode
                bucket.lastKnownAuraStacks = auraStacks; -- Store raw value, because bucket:getAuraStacks() is unreliable if stackAgnostic is set
                if bucket.auraInstanceID ~= auraInstanceID then
                    if bucket.auraInstanceID ~= nil then
                        if not bucket.auraHasSecretRestrictions then --[[BEGIN_DEV_ONLY]]
                            SAO:Warn(Module, "Removing outdated aura instance ID mapping for", bucket.auraInstanceID, "of bucket", bucket.name);
                        end --[[END_DEV_ONLY]]
                        bucketsByAuraInstanceID[bucket.auraInstanceID] = nil;
                    end
                    bucket.auraInstanceID = auraInstanceID;
                    if auraInstanceID ~= nil then
                        bucketsByAuraInstanceID[auraInstanceID] = bucket;
                    end
                end
            end
        end,
    },

    event = {
        isRequired = true,
        names = SAO.AURASTACKS.MODERN and { "UNIT_AURA", "PLAYER_REGEN_ENABLED" } or { "COMBAT_LOG_EVENT_UNFILTERED" },

        -- Legacy aura handling via CLEU
        COMBAT_LOG_EVENT_UNFILTERED = SAO.AURASTACKS.LEGACY and function(...)
            local _, event, _, _, _, _, _, destGUID = CombatLogGetCurrentEventInfo();

            if ( (event:sub(0,11) == "SPELL_AURA_") and (destGUID == UnitGUID("player")) ) then
                -- Events starting with SPELL_AURA e.g., SPELL_AURA_APPLIED
                -- This should be invoked only if the buff is done on the player i.e., UnitGUID("player") == destGUID
                local spellID, spellName = select(12, CombatLogGetCurrentEventInfo());

                --[[ Aura event chart

                For un-stackable auras:
                - "SPELL_AURA_APPLIED" = buff is being applied now
                - "SPELL_AURA_REMOVED" = buff is being removed now

                For stackable auras:
                - "SPELL_AURA_APPLIED" = first stack applied
                - "SPELL_AURA_APPLIED_DOSE" = second stack applied or beyond
                - "SPELL_AURA_REMOVED_DOSE" = removed a stack, but there is at least one stack left
                - "SPELL_AURA_REMOVED" = removed last remaining stack

                For any aura:
                - "SPELL_AURA_REFRESH" = buff is refreshed, usually the remaining time is reset to its max duration
                ]]
                local auraApplied = event:sub(0,18) == "SPELL_AURA_APPLIED"; -- includes "SPELL_AURA_APPLIED" and "SPELL_AURA_APPLIED_DOSE"
                local auraRemovedLast = event == "SPELL_AURA_REMOVED";
                local auraRemovedDose = event == "SPELL_AURA_REMOVED_DOSE";
                local auraRefresh = event == "SPELL_AURA_REFRESH";
                if not auraApplied and not auraRemovedLast and not auraRemovedDose and not auraRefresh then
                    return; -- Not an event we're interested in
                end

                -- Use the game's aura from CLEU to find its corresponding aura item in SAO, if any
                local bucket;
                bucket, spellID = SAO:GetBucketBySpellIDOrSpellName(spellID, spellName);
                if not bucket then
                    -- This spell is not tracked by SAO
                    return;
                end
                if not bucket.trigger:reactsWith(SAO.TRIGGER_AURA) then
                    -- This spell ignores aura-based triggers
                    return;
                end

                -- Handle unique case first: aura refresh
                if (auraRefresh) then
                    bucket:refresh();
                    -- Can return now, because SPELL_AURA_REFRESH is used only to refresh timer
                    return;
                end

                -- Now, we are in a situation where we either got a buff (SPELL_AURA_APPLIED*) or lost it (SPELL_AURA_REMOVED*)

                if (auraRemovedLast) then
                    bucket:setAuraStacks(nil); -- nil means "not currently holding any stacks"
                    -- Can return now, because SPELL_AURA_REMOVED resets everything
                    return;
                end

                --[[ Now, we are in a situation where either:
                    - we got a buff (SPELL_AURA_APPLIED*)
                    - or we lost a stack but still have the buff (SPELL_AURA_REMOVED_DOSE)
                    Either way, the player currently has the buff or debuff
                ]]

                local stacks = 0; -- Number of stacks of the aura, unless the aura is stack-agnostic (see below)
                if not bucket.stackAgnostic then
                    -- To handle stackable auras, we must find the aura (ugh!) to get its number of stacks
                    -- In an ideal world, we would use a stack count from the combat log which, unfortunately, is unavailable
                    if event ~= "SPELL_AURA_REMOVED" then -- No need to find aura with complete removal: the buff is not there anymore
                        stacks = SAO:GetPlayerAuraStacksBySpellID(spellID) or 0;
                    end
                    -- For the record, stacks will always be 0 for stack-agnostic auras, even if the aura actually has stacks
                    -- This is an optimization that prevents the above call of GetPlayerAuraStacksBySpellID, which has a significant cost
                end

                --[[ Aura is enabled, either because:
                    - it was added now (SPELL_AURA_APPLIED)
                    - or was upgraded (SPELL_AURA_APPLIED_DOSE)
                    - or was downgraded but still visible (SPELL_AURA_REMOVED_DOSE)
                ]]
                bucket:setAuraStacks(stacks);
            end
        end or nil,

        -- Modern aura handling via UNIT_AURA
        UNIT_AURA = SAO.AURASTACKS.MODERN and function(unitTarget, updateInfo)
            if unitTarget ~= "player" and (not canaccessvalue(UnitIsUnit(unitTarget, "player")) or not UnitIsUnit(unitTarget, "player")) then
                return;
            end

            if not canaccessvalue(updateInfo.isFullUpdate) or
               not canaccessvalue(updateInfo.updatedAuraInstanceIDs) or
               not canaccessvalue(updateInfo.removedAuraInstanceIDs) or
               not canaccessvalue(updateInfo.addedAuras)
            then
                -- Cannot fetch information from the updateInfo structure, but maybe there are non-secret auras that can be checked manually
                for _, bucket in ipairs(secretlessBuckets) do
                    SAO:Debug(Module, "Checking buckets manually for secretless aura", bucket.name);
                    bucket.trigger:manualCheck(SAO.TRIGGER_AURA);
                end
                if SAO.IsForever() or SAO.IsRetail() then
                    return; -- There's probably no reason to continue processing auras information after this point
                else
                    SAO:Warn(Module, "Dealing with secret aura information in a flavor which is not supposed to have them:", SAO.GetFlavorName());
                end
            end

            -- Special case, should happen once per login or per loading screen at best
            if canaccessvalue(updateInfo.isFullUpdate) and updateInfo.isFullUpdate then
                SAO:Debug(Module, "Full aura update detected, rechecking all buckets");
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_AURA);
                return;
            end

            local addedAuraInstanceIDsExpectedToBeRemoved = {}; --[[DEV_ONLY]]

            local addAura = function(auraInstanceID, aura, bucket)
                SAO:Trace(Module, "Associating aura instance ID "..tostring(auraInstanceID).." to bucket "..bucket.name);
                bucket:setAuraStacks(bucket.stackAgnostic and 0 or aura.applications);
                bucket.lastKnownAuraStacks = aura.applications;
                if bucket.auraInstanceID then
                    -- This situation is usually an issue, unless the aura instance ID is removed in the same update cycle, before leaving this function
                    --[[BEGIN_DEV_ONLY]]
                    addedAuraInstanceIDsExpectedToBeRemoved[bucket.auraInstanceID] = { name = bucket.name, newID = auraInstanceID };
                    SAO:Info(Module, "Aura instance ID "..tostring(bucket.auraInstanceID)..
                        " is being replaced by new aura instance ID "..tostring(auraInstanceID)..
                        " for bucket "..bucket.name);
                    --[[END_DEV_ONLY]]
                    bucketsByAuraInstanceID[bucket.auraInstanceID] = nil;
                    bucket:refresh();
                end
                bucket.auraInstanceID = auraInstanceID;
                bucketsByAuraInstanceID[auraInstanceID] = bucket;
            end

            local removeAura = function(auraInstanceID, bucket)
                SAO:Trace(Module, "Removing association of aura instance ID "..tostring(auraInstanceID).." from bucket "..bucket.name);
                bucket:setAuraStacks(nil);
                bucket.lastKnownAuraStacks = nil;
                bucket.auraInstanceID = nil;
                bucketsByAuraInstanceID[auraInstanceID] = nil;
            end

            local updateAura = function(auraInstanceID, aura, bucket)
                SAO:Trace(Module, "Updating aura instance ID "..tostring(auraInstanceID).." for bucket "..bucket.name);
                if bucket.lastKnownAuraStacks ~= aura.applications then
                    SAO:Trace(Module, "Bucket "..tostring(bucket.name).." aura stacks changed from "..tostring(bucket.lastKnownAuraStacks).." to "..tostring(aura.applications));
                    bucket:setAuraStacks(bucket.stackAgnostic and 0 or aura.applications);
                    bucket.lastKnownAuraStacks = aura.applications;
                else
                    SAO:Trace(Module, "Bucket "..tostring(bucket.name).." aura stacks remain unchanged at "..tostring(bucket.lastKnownAuraStacks));
                    bucket:refresh();
                end
            end

            -- Process aura data in the following order, as seen in the game client UI files (e.g. Interface\AddOns\Blizzard_PrivateAurasUI\Blizzard_PrivateAurasUI.lua)
            -- 1. added auras
            -- 2. updated auras*
            -- 3. removed auras
            -- *updated auras may incidentally indicate an aura removal as well

            for _, aura in ipairs(canaccessvalue(updateInfo.addedAuras) and updateInfo.addedAuras or {}) do
                local bucket = SAO:GetBucketBySpellID(aura.spellId);
                if bucket and bucket.trigger:reactsWith(SAO.TRIGGER_AURA) then
                    local auraInstanceID = aura.auraInstanceID;
                    if bucket.auraInstanceID == auraInstanceID then
                        -- This should not happen, but we have seen cases when an addedAuras is fired twice e.g., Fingers of Frost (SoD)
                        SAO:Warn(Module, "Added aura instance ID "..tostring(auraInstanceID).." for bucket "..bucket.name.." which already has the same aura instance ID, updating it instead"); --[[DEV_ONLY]]
                        updateAura(auraInstanceID, aura, bucket);
                    else
                        addAura(auraInstanceID, aura, bucket);
                    end
                end
            end

            for _, auraInstanceID in ipairs(canaccessvalue(updateInfo.updatedAuraInstanceIDs) and updateInfo.updatedAuraInstanceIDs or {}) do
                local bucket = bucketsByAuraInstanceID[auraInstanceID];
                if bucket then
                    SAO:Trace(Module, "Trying to update aura instance ID "..tostring(auraInstanceID).." for bucket "..bucket.name);
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID);
                    if not aura then
                        -- Known Issue: sometimes the game client tells the aura is updated, while in reality it has been removed
                        -- @todo Check if the game is sending an aura removal at the same time, and if so, ignore this update
                        removeAura(auraInstanceID, bucket);
                    else
                        updateAura(auraInstanceID, aura, bucket);
                    end
                end
            end

            for _, auraInstanceID in ipairs(canaccessvalue(updateInfo.removedAuraInstanceIDs) and updateInfo.removedAuraInstanceIDs or {}) do
                if addedAuraInstanceIDsExpectedToBeRemoved[auraInstanceID] then --[[BEGIN_DEV_ONLY]]
                    SAO:Info(Module, "Removed aura instance ID "..tostring(auraInstanceID)..
                        " which was expected to be removed because an aura for the same bucket was just added");
                    addedAuraInstanceIDsExpectedToBeRemoved[auraInstanceID] = nil;
                end --[[END_DEV_ONLY]]
                local bucket = bucketsByAuraInstanceID[auraInstanceID];
                if bucket then
                    removeAura(auraInstanceID, bucket);
                end
            end

            for auraInstanceID, replacementInfo in pairs(addedAuraInstanceIDsExpectedToBeRemoved) do --[[BEGIN_DEV_ONLY]]
                SAO:Error(Module, "Replacing bucket "..replacementInfo.name..
                    " which had aura instance ID "..tostring(auraInstanceID)..
                    " with aura instance ID "..tostring(replacementInfo.newID)..
                    " without removing the former aura instance ID");
            end --[[END_DEV_ONLY]]
        end or nil,

        PLAYER_REGEN_ENABLED = SAO.AURASTACKS.MODERN and function(self, event, ...)
            -- When leaving combat, auras may be queried individually
            for _, bucket in ipairs(secretBuckets) do
                SAO:Debug(Module, "Checking buckets manually for secret aura", bucket.name);
                bucket.trigger:manualCheck(SAO.TRIGGER_AURA);
            end
        end or nil,
    },

    condition = {
        noeVar = "aura",
        hreVar = "stacks",
        noeDefault = 0,
        description = "number of stacks",
        checker = function(value) return type(value) == 'number' and value >= -1 and value <= 10 end,
        noeToHash = function(value) return value >= 0 and value or nil end, -- return n if n >= 0, otherwise (if n == -1) return nil
    },

    import = {
        noeTrigger = "aura",
        hreTrigger = "requireAura",
        -- dependency = nil, -- Actually, aura stacks depend on 'spellID', but this property is mandatory and automatically imported
        dependency = (C_Secrets and C_Secrets.GetSpellAuraSecrecy) and {
            name = "spellID",
            expectedType = "number",
            default = function(effect) return effect.spellID end,
            prepareBucket = function(bucket, value)
                local secrecy = SAO:IsSpellSecret(value);
                if secrecy == 1 then
                    SAO:Debug(Module, bucket.description.." is based on spell "..value.." which has secret restrictions");
                elseif secrecy == 2 then
                    SAO:Debug(Module, bucket.description.." is based on spell "..value.." which is always secret");
                end
                local hasSecretRestrictions = type(secrecy) == 'number' and secrecy > 0;
                bucket.auraHasSecretRestrictions = hasSecretRestrictions;
                if hasSecretRestrictions then
                    table.insert(secretBuckets, bucket);
                else
                    table.insert(secretlessBuckets, bucket);
                end
            end,
        } or nil,
        classes = {
            force = "aura",
            ignore = nil,
        },
    },

    macro = {
        getCondition = nil,
    },
});
