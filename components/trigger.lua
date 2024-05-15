local AddonName, SAO = ...
local Module = "trigger"

-- List of trigger flags, as bit field
-- Start high enough to be able to index trigger flag to a list, and avoid confusion with stack counts
SAO.TRIGGER_AURA     = 1
SAO.TRIGGER_COUNTER  = 2
SAO.TRIGGER_RESOURCE = 4

local TriggerNames = {
    [SAO.TRIGGER_AURA    ] = "aura",
    [SAO.TRIGGER_COUNTER ] = "counter",
    [SAO.TRIGGER_RESOURCE] = "resource",
}

local TriggerManualChecks = {
    [SAO.TRIGGER_AURA] = function(props)
        local auraStacks = SAO:GetPlayerAuraStacksBySpellID(props.bucket.spellID);
        if auraStacks ~= nil then
            if props.bucket.stackAgnostic then
                return 0;
            else
                return auraStacks;
            end
        else
            return nil;
        end
    end,
    [SAO.TRIGGER_COUNTER] = function(props)
        return false; -- @todo
    end,
    [SAO.TRIGGER_RESOURCE] = function(props)
        return false; -- @todo
    end,
}

SAO.Trigger = {
    new = function(self, parent) -- parent is the bucket attached to the new trigger
        local trigger = {
            parent = parent,

            required = 0, -- Bit field of required triggers to activate before 'showing' the bucket
            activated = 0, -- Bit field of currently activated triggers
            props = {},
        }

        self.__index = nil;
        setmetatable(trigger, self);
        self.__index = self;

        return trigger;
    end,

    add = function(self, flag, props)
        local name = TriggerNames[flag];
        if not name then
            SAO:Error(Module, "Unknown trigger "..tostring(flag));
            return;
        end
        if bit.band(self.required, flag) ~= 0 then
            SAO:Warn(Module, "Registering several times the same trigger "..tostring(name).." for "..self.parent.description);
        end

        self.required = bit.bor(self.required, flag);
        self.props[flag] = props;
        -- Special case for auras: the initial stack count becomes nil
        -- We cannot leave initial count to 0, because 0 has a special meaning for aura-based buckets
        if bit.band(flag, SAO.TRIGGER_AURA) ~= 0 then
            self.parent.currentStacks = nil;
        end
    end,

    reactsWith = function(self, flag)
        return bit.band(self.required, flag) ~= 0;
    end,

    isActivated = function(self, flag)
        return bit.band(self.activated, flag) ~= 0;
    end,

    isFullyActivated = function(self)
        return self.required ~= 0 and self.activated == self.required;
    end,

    activate = function(self, flag)
        local name = tostring(TriggerNames[flag] or flag);
        if bit.band(self.required, flag) ~= self.required then
            SAO:Error(Module, "Activating unsupported trigger "..name.." for "..self.parent.description);
            return;
        end
        if bit.band(self.activated, flag) == flag then
            SAO:Debug(Module, "Re-activating already activated trigger "..name.." for "..self.parent.description);
            return;
        end
        SAO:Debug(Module, "Activating trigger "..name.." for "..self.parent.description);

        self.activated = bit.bor(self.activated, flag);
        if self.activated == self.required then
            self.parent:show();
        end
    end,

    deactivate = function(self, flag)
        local name = tostring(TriggerNames[flag] or flag);
        if bit.band(self.required, flag) ~= self.required then
            SAO:Error(Module, "De-activating unsupported trigger "..name.." for "..self.parent.description);
            return;
        end
        if bit.band(self.activated, flag) == 0 then
            SAO:Debug(Module, "De-activating unactive trigger "..name.." for "..self.parent.description);
            return;
        end
        SAO:Debug(Module, "De-activating trigger "..name.." for "..self.parent.description);

        if self.activated == self.required then
            self.parent:hide();
        end
        self.activated = bit.band(self.activated, bit.bnot(flag));
    end,

    manualCheck = function(self)
        if self.required == 0 then
            SAO:Debug(Module, "Checking manually a trigger which requires nothing for "..self.parent.description);
            return;
        end

        local checked = 0;
        local stacks = 0;
        for _, flag in ipairs({ SAO.TRIGGER_AURA, SAO.TRIGGER_COUNTER, SAO.TRIGGER_RESOURCE }) do
            if self:reactsWith(flag) then
                local result = TriggerManualChecks[flag](self.props[flag]);
                if result then
                    checked = checked + flag;
                end
                if flag == SAO.TRIGGER_AURA then
                    stacks = result;
                end
            end
        end

        if self.activated == checked and self.parent.currentStacks == stacks then
            -- Did not change: nothing to do
            return;
        elseif self.required == self.activated then
            -- Was fully activated
            SAO:Debug(Module, "De-activating the formerly fully activated "..self.parent.description);
            self.parent:hide();
            self.parent:setStacks(stacks);
            self.activated = checked;
        elseif self.required == checked then
            -- Now fully activated
            SAO:Debug(Module, "Activating the newly fully activated "..self.parent.description);
            self.activated = checked;
            self.parent:setStacks(stacks);
            self.parent:show();
        else
            -- Simply overwrite with new knowledge
            self.activated = checked;
            self.parent:setStacks(stacks);
        end
    end,
}
