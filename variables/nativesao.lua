local AddonName, SAO = ...
local Module = "nativesao"

-- Native SpellActivationOverlay event is shown or hidden
local HASH_NATIVE_SAO_SHOW = 0x2000
local HASH_NATIVE_SAO_HIDE = 0x4000
local HASH_NATIVE_SAO_MASK = 0x6000

SAO.Variable:register({
    order = 6,
    core = "NativeSAO",

    trigger = {
        flag = SAO.TRIGGER_NATIVE_SAO,
        name = "sao",
    },

    hash = {
        mask = HASH_NATIVE_SAO_MASK,
        key = "sao",

        setterFunc = function(self, shown)
            if type(shown) ~= 'boolean' then
                SAO:Warn(Module, "Invalid Native SAO flag "..tostring(shown));
            else
                local maskedHash = shown and HASH_NATIVE_SAO_SHOW or HASH_NATIVE_SAO_HIDE;
                self:setMaskedHash(maskedHash, HASH_NATIVE_SAO_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_NATIVE_SAO_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_NATIVE_SAO_SHOW;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local nativeSAO = hash:getNativeSAO();
            return nativeSAO and "show" or "hide";
        end,
        fromValue = function(hash, value)
            if value == "show" then
                hash:setNativeSAO(true);
                return true;
            elseif value == "hide" then
                hash:setNativeSAO(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getNativeSAO() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            -- Exceptionnally, this variable cannot be checked manually
            if bucket.currentState["currentNativeSAO"] == nil then
                -- Simply init to false, if not initialized yet
                bucket:setNativeSAO(false);
            end
        end,
    },

    event = {
        isRequired = SAO.IsProject(SAO.CATA_AND_ONWARD),
        names = { "SPELL_ACTIVATION_OVERLAY_SHOW", "SPELL_ACTIVATION_OVERLAY_HIDE" },
        SPELL_ACTIVATION_OVERLAY_SHOW = function(spellID, overlayFileDataID, locationName, scale, r, g, b)
            local bucket = spellID ~= nil and SAO:GetBucketBySpellID(spellID);
            if bucket and bucket.trigger:reactsWith(SAO.TRIGGER_NATIVE_SAO) then
                bucket:setNativeSAO(true);
            end
        end,
        SPELL_ACTIVATION_OVERLAY_HIDE = function(spellID)
            local bucket = spellID ~= nil and SAO:GetBucketBySpellID(spellID);
            if bucket and bucket.trigger:reactsWith(SAO.TRIGGER_NATIVE_SAO) then
                bucket:setNativeSAO(false);
            end
        end,
    },

    condition = {
        noeVar = "sao",
        hreVar = "useNativeSAO",
        noeDefault = true,
        description = "native SAO flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "sao",
        hreTrigger = "useNativeSAO",
        dependency = nil, -- Depends on spellID, which is always set
        classes = {
            force = "native",
            ignore = nil,
        },
    },
});
