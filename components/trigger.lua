local AddonName, SAO = ...
local Module = "trigger"

-- Optimize frequent calls
local GetTalentInfo = GetTalentInfo

-- List of trigger flags, as bit field
-- Start high enough to be able to index trigger flag to a list, and avoid confusion with stack counts
SAO.TRIGGER_AURA          = 0x1
SAO.TRIGGER_ACTION_USABLE = 0x2
SAO.TRIGGER_TALENT        = 0x4
SAO.TRIGGER_HOLY_POWER    = 0x8

local TriggerNames = {
    [SAO.TRIGGER_AURA         ] = "aura",
    [SAO.TRIGGER_ACTION_USABLE] = "counter",
    [SAO.TRIGGER_TALENT       ] = "talent",
    [SAO.TRIGGER_HOLY_POWER   ] = "resource",
}

-- List of lists of buckets requiring each type of trigger
SAO.RegisteredBucketsByTrigger = {};
for flag, _ in pairs(TriggerNames) do
    SAO.RegisteredBucketsByTrigger[flag] = {}
end

function SAO:GetBucketsByTrigger(flag)
    local buckets = SAO.RegisteredBucketsByTrigger[flag];
    if not buckets then
        SAO:Error(Module, "Cannot get buckets for trigger "..tostring(flag));
    end
    return buckets;
end

local TriggerManualChecks = {
    [SAO.TRIGGER_AURA] = function(bucket)
        local auraStacks = SAO:GetPlayerAuraStacksBySpellID(bucket.spellID);
        if auraStacks ~= nil then
            if bucket.stackAgnostic then
                bucket:setStacks(0);
            else
                bucket:setStacks(auraStacks);
            end
        else
            bucket:setStacks(nil);
        end
    end,
    [SAO.TRIGGER_ACTION_USABLE] = function(bucket)
        return false; -- @todo
    end,
    [SAO.TRIGGER_TALENT] = function(bucket)
        if bucket.talentTabIndex then
            local tab, index = bucket.talentTabIndex[1], bucket.talentTabIndex[2];
            local rank = select(5, GetTalentInfo(tab, index));
            bucket:setTalented(rank > 0);
        else
            bucket:setTalented(false);
        end
    end,
    [SAO.TRIGGER_HOLY_POWER] = function(bucket)
        return false; -- @todo
    end,
}

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
        local name = TriggerNames[flag];
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
        local name = tostring(TriggerNames[flag] or flag);
        if bit.bor(self.required, flag) ~= self.required then
            SAO:Error(Module, "Informing unsupported trigger "..name.." for "..self.parent.description);
            return;
        end
        if bit.band(self.informed, flag) == flag then
            return;
        end
        SAO:Debug(Module, "Informing trigger "..name.." for "..self.parent.description);

        self.informed = bit.bor(self.informed, flag);
    end,

    uninform = function(self, flag) -- @todo remove code maybe, probably dead code. Who needs to un-inform?
        local name = tostring(TriggerNames[flag] or flag);
        if bit.band(self.required, flag) ~= self.required then
            return;
        end
        if bit.band(self.informed, flag) == 0 then
            SAO:Debug(Module, "De-informing unactive trigger "..name.." for "..self.parent.description);
            return;
        end
        SAO:Debug(Module, "De-informing trigger "..name.." for "..self.parent.description);

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
        for flag, name in pairs(TriggerNames) do
            if bit.band(flag, flags) then
                self.informed = bit.band(self.informed, bit.bnot(flag));
            end
        end

        for flag, name in pairs(TriggerNames) do
            if bit.band(flag, flags) ~= 0 and self:reactsWith(flag) then
                TriggerManualChecks[flag](self.parent);
            end
        end
    end,

    manualCheckAll = function(self)
        if self.required == 0 then
            SAO:Debug(Module, "Checking manually all triggers which require nothing for "..self.parent.description);
            return;
        end

        self.informed = 0; -- Reset informed flags to avoid premature show/hide when parsing all trigger functions

        for flag, name in pairs(TriggerNames) do
            if self:reactsWith(flag) then
                TriggerManualChecks[flag](self.parent);
            end
        end
    end,
}
