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
            else
                bucket:setTalented(false);
            end
        end,
    },

    event = {
        isRequired = true,
        names = { "PLAYER_TALENT_UPDATE" },
        PLAYER_TALENT_UPDATE = function(...)
            SAO:CheckManuallyAllBuckets(SAO.TRIGGER_TALENT);
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
                    SAO:Error(Module, bucket.description.." requires talent "..value..(talentName and " ("..talentName..")" or "")..", but it cannot be found in the talent tree");
                end
            end,
        },
        classes = {
            force = nil,
            ignore = nil,
        },
    },
});
