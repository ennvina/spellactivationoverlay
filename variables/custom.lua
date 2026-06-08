local AddonName, SAO = ...
local Module = "custom"

-- Optimize frequent calls

-- Does the current custom variable match one of the expected values
local HASH_CUSTOM_ACTIVATED   = 0x40000000
local HASH_CUSTOM_DEACTIVATED = 0x80000000
local HASH_CUSTOM_MASK        = 0xC0000000

SAO.Variable:register({
    order = 99,
    core = "Custom",

    trigger = {
        flag = SAO.TRIGGER_CUSTOM,
        name = "custom",
    },

    hash = {
        mask = HASH_CUSTOM_MASK,
        key = "custom_activated",

        setterFunc = function(self, customActivated)
            if type(customActivated) ~= 'boolean' then
                SAO:Warn(Module, "Invalid CustomActivated flag "..tostring(customActivated));
            else
                local maskedHash = customActivated and HASH_CUSTOM_ACTIVATED or HASH_CUSTOM_DEACTIVATED;
                self:setMaskedHash(maskedHash, HASH_CUSTOM_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_CUSTOM_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_CUSTOM_ACTIVATED;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local customActivated = hash:getCustom();
            return customActivated and "yes" or "no";
        end,
        fromValue = function(hash, value)
            if value == "yes" then
                hash:setCustom(true);
                return true;
            elseif value == "no" then
                hash:setCustom(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getCustom() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            if  not bucket
             or not bucket.custom
             or type(bucket.custom.isActivated) ~= 'function'
             or type(bucket.custom.state) ~= 'table'
             then
                bucket:setCustom(nil);
                return;
            end

            local isActivated = bucket.custom.isActivated(bucket, bucket.custom.state);
            if isActivated == nil then
                bucket:setCustom(nil);
            else
                bucket:setCustom(isActivated);
            end
        end,
    },

    event = {
        isRequired = false,
        names = {},
    },

    condition = {
        noeVar = "custom",
        hreVar = "customActivated",
        noeDefault = true,
        description = "custom activation flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "custom",
        hreTrigger = "useCustom",

        dependency = {
            name = "custom",
            expectedType = "table",
            default = function(effect) return nil end, -- Make the 'custom' property mandatory
            prepareBucket = function(bucket, value)
                if type(value) == 'table' and value.isActivated and value.events then
                    local frame = CreateFrame("Frame");
                    local custom = {
                        isActivated = value.isActivated,
                        events = value.events,
                        frame = frame,
                        state = {},
                    };

                    for eventName, eventFunc in pairs(custom.events) do
                        frame:RegisterEvent(eventName);
                    end

                    frame:SetScript("OnEvent", function(self, event, ...)
                        local eventFunc = custom.events[event];
                        if type(eventFunc) == 'function' then --[[DEV_ONLY]]
                            eventFunc(bucket, custom.state, ...);
                        else --[[BEGIN_DEV_ONLY]]
                            SAO:Error(Module, "Invalid event function for event "..tostring(event).." in custom variable");
                        end --[[END_DEV_ONLY]]
                    end);

                    bucket.custom = custom;
                else
                    SAO:Warn(Module, "Invalid custom dependency value "..tostring(value));
                end
            end,
        },

        classes = {
            force = "custom",
            ignore = nil,
        },
    },
});
