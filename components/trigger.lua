local AddonName, SAO = ...
local Module = "trigger"

-- List of trigger flags, as bit field
SAO.TRIGGER_AURA          = 0x01
SAO.TRIGGER_ACTION_USABLE = 0x02
SAO.TRIGGER_TALENT        = 0x04
SAO.TRIGGER_HOLY_POWER    = 0x08
SAO.TRIGGER_EXECUTE       = 0x10
SAO.TRIGGER_NATIVE_SAO    = 0x20
SAO.TRIGGER_STANCE        = 0x40
SAO.TRIGGER_ITEM_SET      = 0x80

-- Trigger names for variables and conditions
SAO.TriggerNames = {} -- Will be filled by Variable

-- Transpose index for fast lookup in both directions
SAO.TriggerFlags = {} -- Will be filled by Variable

-- Functions to check manually if a trigger should be triggered
SAO.TriggerManualChecks = {} -- Will be filled by Variable

-- List of lists of buckets requiring each type of trigger
SAO.RegisteredBucketsByTrigger = {} -- Will be filled by Variable

function SAO:GetBucketsByTrigger(flag)
    local buckets = SAO.RegisteredBucketsByTrigger[flag];
    if not buckets then
        SAO:Error(Module, "Cannot get buckets for trigger "..tostring(flag));
    end
    return buckets;
end

SAO.Trigger = {
    new = function(self, parent) -- parent is the bucket attached to the new trigger
        local trigger = {
            parent = parent,

            required = 0, -- Bit field of required triggers to get information before pretending to activate the trigger
            informed = 0, -- Bit field of currently known informations required by the trigger
        }

        self.__index = nil;
        setmetatable(trigger, self);
        self.__index = self;

        return trigger;
    end,

    require = function(self, flag)
        local name = SAO.TriggerNames[flag];
        if not name then
            SAO:Error(Module, "Unknown trigger "..tostring(flag));
            return;
        end
        if bit.band(self.required, flag) == 0 then
            tinsert(SAO.RegisteredBucketsByTrigger[flag], self.parent);
        else
            SAO:Warn(Module, "Requiring several times the same trigger "..tostring(name).." for "..self.parent.description);
        end

        self.required = bit.bor(self.required, flag);
    end,

    reactsWith = function(self, flag)
        return bit.band(self.required, flag) ~= 0;
    end,

    isFullyInformed = function(self)
        return self.required ~= 0 and self.informed == self.required;
    end,

    inform = function(self, flag)
        local name = tostring(SAO.TriggerNames[flag] or flag);
        if bit.bor(self.required, flag) ~= self.required then
            SAO:Error(Module, "Informing unsupported trigger "..name.." for "..self.parent.description);
            return;
        end
        if bit.band(self.informed, flag) == flag then
            return;
        end
        SAO:Trace(Module, "Informing trigger "..name.." for "..self.parent.description);

        self.informed = bit.bor(self.informed, flag);
    end,

    uninform = function(self, flag) -- @todo remove code maybe, probably dead code. Who needs to un-inform?
        local name = tostring(SAO.TriggerNames[flag] or flag);
        if bit.band(self.required, flag) ~= self.required then
            return;
        end
        if bit.band(self.informed, flag) == 0 then
            SAO:Debug(Module, "De-informing unactive trigger "..name.." for "..self.parent.description);
            return;
        end
        SAO:Trace(Module, "De-informing trigger "..name.." for "..self.parent.description);

        self.informed = bit.band(self.informed, bit.bnot(flag));
    end,

    manualCheck = function(self, flags)
        if bit.band(self.required, flags) == 0 then
            SAO:Warn(Module, "Checking manually a trigger "..tostring(flags).." which does not meet requirements of  "..self.parent.description);
            return;
        end

        if bit.bor(self.required, flags) ~= self.required then
            SAO:Warn(Module, "Checking manually a trigger "..tostring(flags).." which is not completely wanted by "..self.parent.description);
        end

        -- Reset informed flags to avoid premature show/hide when parsing all trigger functions
        for flag, name in pairs(SAO.TriggerNames) do
            if bit.band(flag, flags) ~= 0 then
                self.informed = bit.band(self.informed, bit.bnot(flag));
            end
        end

        for flag, name in pairs(SAO.TriggerNames) do
            if bit.band(flag, flags) ~= 0 and self:reactsWith(flag) then
                SAO.TriggerManualChecks[flag](self.parent);
                -- Must inform explicitly
                -- Usually, the manual check would change state of the bucket, which will re-inform the trigger has triggered
                -- But if the state does not change, the bucket may ignore the change, and thus not re-inform the trigger
                self.informed = bit.bor(self.informed, flag);
            end
        end

        -- Apply hash, in case it wasn't applied because of lazy evaluations during bucket setters (setAuraStacks, etc.)
        self.parent:applyHash();
    end,

    manualCheckAll = function(self)
        if self.required == 0 then
            SAO:Debug(Module, "Checking manually all triggers which require nothing for "..self.parent.description);
            return;
        end

        self.informed = 0; -- Reset informed flags to avoid premature show/hide when parsing all trigger functions

        for flag, name in pairs(SAO.TriggerNames) do
            if self:reactsWith(flag) then
                SAO.TriggerManualChecks[flag](self.parent);
                -- Must inform explicitly
                -- Usually, the manual check would change state of the bucket, which will re-inform the trigger has triggered
                -- But if the state does not change, the bucket may ignore the change, and thus not re-inform the trigger
                self.informed = bit.bor(self.informed, flag);
            end
        end

        -- Apply hash, in case it wasn't applied because of lazy evaluations during bucket setters (setAuraStacks, etc.)
        self.parent:applyHash();
    end,
}
