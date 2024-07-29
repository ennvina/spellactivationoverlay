local AddonName, SAO = ...
local Module = "talent"

-- Optimize frequent calls
local GetTalentInfo = GetTalentInfo

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
                local rank = select(5, GetTalentInfo(tab, index));
                bucket:setTalented(rank > 0);
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
        names = SAO.IsSoD() and { "PLAYER_TALENT_UPDATE", "RUNE_UPDATED", "PLAYER_EQUIPMENT_CHANGED" } or { "PLAYER_TALENT_UPDATE" },
        PLAYER_TALENT_UPDATE = function(...)
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentTabIndex then -- Keep only talent-based buckets
                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT);
                end
            end
        end,
        RUNE_UPDATED = function(rune) -- Cannot rely on rune contents, because we need to refresh even if rune is un-equipped
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentRuneID then -- Keep only rune-based buckets
                    bucket.trigger:manualCheck(SAO.TRIGGER_TALENT);
                end
            end
        end,
        PLAYER_EQUIPMENT_CHANGED = function(equipmentSlot, hasCurrent)
            local buckets = SAO:GetBucketsByTrigger(SAO.TRIGGER_TALENT);
            for _, bucket in ipairs(buckets or {}) do
                if bucket.talentRuneID then -- Keep only rune-based buckets
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
                local talentName = GetSpellInfo(value);
                local _, _, tab, index = SAO:GetTalentByName(talentName);
                if type(tab) == 'number' and type(index) == 'number' then
                    -- Talent Tab-Index is an option object { tab, index } telling the talent location in the player's tree
                    bucket.talentTabIndex = { tab, index };
                else
                    if SAO.IsSoD() then -- For Season of Discovery, don't give up if the talent is not found, for it may be a rune
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
                    else
                        SAO:Error(Module, bucket.description.." requires talent "..value..(talentName and " ("..talentName..")" or "")..", but it cannot be found in the talent tree");
                    end
                end
            end,
        },
        classes = {
            force = nil,
            ignore = nil,
        },
    },
});
