local AddonName, SAO = ...
local Module = "talent"

-- Optimize frequent calls
local GetSpecialization = C_SpecializationInfo and C_SpecializationInfo.GetSpecialization

-- Has spent point in the talent tree
local HASH_TALENT_NO   = 0x40
local HASH_TALENT_YES  = 0x80
local HASH_TALENT_MASK = 0xC0

SAO.Variable:register({
    order = 3,
    core = "Talented",

    trigger = {
        flag = SAO.TRIGGER_TALENT,
        name = "talent",
    },

    hash = {
        mask = HASH_TALENT_MASK,
        key = "talent",

        setterFunc = function(self, usable)
            if type(usable) ~= 'boolean' then
                SAO:Warn(Module, "Invalid Talented flag "..tostring(usable));
            else
                local maskedHash = usable and HASH_TALENT_YES or HASH_TALENT_NO;
                self:setMaskedHash(maskedHash, HASH_TALENT_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_TALENT_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_TALENT_YES;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local talented = hash:getTalented();
            return talented and "yes" or "no";
        end,
        fromValue = function(hash, value)
            if value == "yes" then
                hash:setTalented(true);
                return true;
            elseif value == "no" then
                hash:setTalented(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getTalented() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            if bucket.talentTabIndex then
                local tab, index = bucket.talentTabIndex[1], bucket.talentTabIndex[2];
                local rank = SAO:GetNbTalentPoints(tab, index);
                bucket:setTalented(rank > 0);
            elseif bucket.talentTierColumn then
                local tier, column = bucket.talentTierColumn[1], bucket.talentTierColumn[2];
                local rank = SAO:GetNbTalentPoints(tier, column);
                bucket:setTalented(rank > 0);
            elseif bucket.talentSpec then
                local currentSpec = GetSpecialization();
                bucket:setTalented(currentSpec == bucket.talentSpec);
            elseif bucket.talentSpecs then
                -- When checking a list of specs, at least one spec must match
                local currentSpec = GetSpecialization();
                for spec in ipairs(bucket.talentSpecs) do
                    if spec == currentSpec then
                        bucket:setTalented(true);
                        return;
                    end
                end
                bucket:setTalented(false);
            elseif bucket.talentRuneID then
                local hasRune = C_Engraving.IsRuneEquipped(bucket.talentRuneID);
                bucket:setTalented(hasRune);
            else
                bucket:setTalented(false);
            end
        end,
    },

    event = {
        isRequired = true,
        names =
            (SAO.IsSoD() and { "PLAYER_TALENT_UPDATE", "RUNE_UPDATED", "PLAYER_EQUIPMENT_CHANGED" })
            or
            (SAO.IsMoP() and { "PLAYER_TALENT_UPDATE", "PLAYER_SPECIALIZATION_CHANGED" })
            or
            ({ "PLAYER_TALENT_UPDATE" })
        ,
        PLAYER_TALENT_UPDATE = function(...)
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentTabIndex or bucket.talentTierColumn then -- Refresh only talent-based buckets
                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT);
                end
            end
        end,
        PLAYER_SPECIALIZATION_CHANGED = function(...)
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentSpec or bucket.talentSpecs then -- Refresh only spec-based buckets
                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT);
                end
            end
        end,
        RUNE_UPDATED = function(rune) -- Cannot rely on rune contents, because we need to refresh even if rune is un-equipped
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentRuneID then -- Refresh only rune-based buckets
                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT);
                end
            end
        end,
        PLAYER_EQUIPMENT_CHANGED = function(equipmentSlot, hasCurrent)
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentRuneID then -- Refresh only rune-based buckets
                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT);
                end
            end
        end,
    },

    condition = {
        noeVar = "talent",
        hreVar = "requireTalent",
        noeDefault = true,
        description = "talent flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "talent",
        hreTrigger = "requireTalent",
        dependency = {
            name = "talent",
            expectedType = "number",
            default = function(effect) return effect.spellID end,
            prepareBucket = function(bucket, value)
                if value < 0 then
                    -- Negative values are focused on specializations instead of talents
                    if not SAO.IsMoP() or not C_SpecializationInfo or not C_SpecializationInfo.IsInitialized() then
                        SAO:Error(Module, bucket.description.." calls for specialization "..value.." but specializations are unavailable"); return;
                    end

                    local specs = SAO:GetSpecsFromTalent(value);
                    if not specs or #specs == 0 then
                        SAO:Error(Module, bucket.description.." requires specialization "..value..", but it cannot be mapped to an actual specialization"); return;
                    elseif #specs == 1 then
                        bucket.talentSpec = specs[1];
                    else
                        bucket.talentSpecs = specs;
                    end

                    return;
                end

                -- Positive values have to be a talent's spell ID
                local talentName = GetSpellInfo(value);
                local _, _, i, j = SAO:GetTalentByName(talentName);
                if type(i) == 'number' and type(j) == 'number' then
                    if SAO.IsMoP() then
                        -- Talent Tier-Column is an optional table { tier, column } telling the talent location in the player's talent table
                        local tier, column = i, j;
                        bucket.talentTierColumn = { tier, column };
                    else
                        -- Talent Tab-Index is an optional table { tab, index } telling the talent location in the player's talent tree
                        local tab, index = i, j;
                        bucket.talentTabIndex = { tab, index };
                    end
                    return;
                end

                -- For Season of Discovery, don't give up if the talent is not found, for it may be a rune
                if SAO.IsSoD() then
                    bucket.talentRuneID = SAO:GetRuneFromSpell(value);
                    if not bucket.talentRuneID then
                        -- May not be found immediately, because of slow initialization
                        -- Until we know of a guaranteed event that finalizes rune knowledge, our best bet is to retry over time
                        bucket.talentRuneNbRetries = 5;
                        bucket.talentRuneRetryTicker = C_Timer.NewTicker(
                            1,
                            function()
                                bucket.talentRuneNbRetries = bucket.talentRuneNbRetries - 1;
                                local runeID = SAO:GetRuneFromSpell(value);
                                if runeID then
                                    -- Found it, yay!
                                    bucket.talentRuneRetryTicker:Cancel();
                                    bucket.talentRuneID = runeID;
                                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT); -- Manual check because this code happens after prepareBucket returned
                                elseif bucket.talentRuneNbRetries == 0 then
                                    -- Not found after retrying several times, bummer.
                                    bucket.talentRuneRetryTicker:Cancel();
                                    SAO:Error(Module, bucket.description.." requires talent or rune "..value..(talentName and " ("..talentName..")" or "")..
                                                        ", but it cannot be found, neither in the talent tree nor in the rune set");
                                end
                            end
                        );
                    end
                    return;
                end

                SAO:Error(Module, bucket.description.." requires talent "..value..(talentName and " ("..talentName..")" or "")..", but it cannot be found in the talent tree");
            end,
        },
        classes = {
            force = nil,
            ignore = nil,
        },
    },
});
