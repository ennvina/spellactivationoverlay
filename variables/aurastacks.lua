local AddonName, SAO = ...
local Module = "aurastacks"

-- Global variables
SAO.AURASTACKS = {
    LEGACY = C_UnitAuras == nil,
    MODERN = C_UnitAuras ~= nil,
};
--[[BEGIN_DEV_ONLY]]
if false then -- Invert for testing purposes
    SAO.AURASTACKS.LEGACY = true;
    SAO.AURASTACKS.MODERN = false;
end
assert(SAO.AURASTACKS.LEGACY ~= SAO.AURASTACKS.MODERN); -- Exactly one of these modes must be active
--[[END_DEV_ONLY]]

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

-- map between aura instance ID and bucket (Modern mode only)
local bucketsByAuraInstanceID = {};

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
                -- assert(aurastacks == 0);
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
                bucket.auraInstanceID = auraInstanceID;
                if auraInstanceID ~= nil then
                    bucketsByAuraInstanceID[auraInstanceID] = bucket;
                end
            end
        end,
    },

    event = {
        isRequired = true,
        names = SAO.AURASTACKS.MODERN and { "UNIT_AURA" } or { "COMBAT_LOG_EVENT_UNFILTERED" },

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
            if not UnitIsUnit(unitTarget, "player") then
                return;
            end

            -- Special case, should happen once per login or per loading screen at best
            if updateInfo.isFullUpdate then
                SAO:Info(Module, "Full aura update detected, rechecking all buckets");
                SAO:CheckManuallyAllBuckets(SAO.TRIGGER_AURA);
                return;
            end

            for _, auraInstanceID in ipairs(updateInfo.updatedAuraInstanceIDs or {}) do
                local bucket = bucketsByAuraInstanceID[auraInstanceID];
                if bucket then
                    SAO:Trace(Module, "Updating bucket "..tostring(bucket.bucketName).." due to update of aura instance ID "..tostring(auraInstanceID));
                    local aura = C_UnitAuras.GetAuraDataByAuraInstanceID(unitTarget, auraInstanceID);
                    assert(type(aura) == 'table' and aura.auraInstanceID == auraInstanceID);
                    if bucket.lastKnownAuraStacks ~= aura.applications then
                        SAO:Trace(Module, "Bucket "..tostring(bucket.bucketName).." aura stacks changed from "..tostring(bucket.lastKnownAuraStacks).." to "..tostring(aura.applications));
                        bucket:setAuraStacks(bucket.stackAgnostic and 0 or aura.applications);
                        bucket.lastKnownAuraStacks = aura.applications;
                    else
                        SAO:Trace(Module, "Bucket "..tostring(bucket.bucketName).." aura stacks remain unchanged at "..tostring(bucket.lastKnownAuraStacks));
                        bucket:refresh();
                    end
                end
            end

            for _, auraInstanceID in ipairs(updateInfo.removedAuraInstanceIDs or {}) do
                local bucket = bucketsByAuraInstanceID[auraInstanceID];
                if bucket then
                    SAO:Trace(Module, "Updating bucket "..tostring(bucket.bucketName).." due to removal of aura instance ID "..tostring(auraInstanceID));
                    bucket:setAuraStacks(nil);
                    bucket.lastKnownAuraStacks = nil;
                    bucketsByAuraInstanceID[auraInstanceID] = nil;
                end
            end

            for _, aura in ipairs(updateInfo.addedAuras or {}) do
                local bucket = SAO:GetBucketBySpellID(aura.spellId);
                if bucket then
                    if bucketsByAuraInstanceID[aura.auraInstanceID] then --[[BEGIN_DEV_ONLY]]
                        SAO:Warn(Module,
                            "Associating the (supposedly) newfound aura instance ID "..tostring(aura.auraInstanceID)
                            .." to bucket "..bucket.description
                            ..", ".."but this aura instance ID is already associated with bucket "..bucketsByAuraInstanceID[aura.auraInstanceID].description
                        );
                    end --[[END_DEV_ONLY]]
                    local auraInstanceID = aura.auraInstanceID;
                    SAO:Trace(Module, "Updating bucket "..tostring(bucket.bucketName).." due to addition of aura instance ID "..tostring(auraInstanceID));
                    bucket:setAuraStacks(bucket.stackAgnostic and 0 or aura.applications);
                    bucket.lastKnownAuraStacks = aura.applications;
                    bucket.auraInstanceID = auraInstanceID;
                    bucketsByAuraInstanceID[auraInstanceID] = bucket;
                end
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
        dependency = nil, -- Actually, aura stacks depend on 'spellID', but this property is mandatory and automatically imported
        classes = {
            force = "aura",
            ignore = nil,
        },
    },
});
