local AddonName, SAO = ...
local Module = "bucket"

--[[
    Bucket of Displays and Triggers

    A 'bucket' is a container that stores maps of display objects
    Buckets are maps which key is a number of stacks, and value is a display
]]

--[[
    Lists of auras and effects that must be tracked
    These lists should be setup at start, based on the player class
]]
SAO.RegisteredBucketsByName = {}
SAO.RegisteredBucketsBySpellID = {}

-- List of aura arrays, indexed by stack count
-- A stack count of zero means "for everyone"
-- A stack count of non-zero means "for a specific number of stacks"
SAO.Bucket = {
    create = function(self, name, spellID)
        local bucket = {
            name = name, -- Name should be unique amongst buckets

            -- Spell ID is the main identifier to activate/deactivate visuals
            spellID = spellID,

            -- Stack-agnostic means the bucket does not care about its number of stacks
            stackAgnostic = true, -- @todo revisit code which used countAgnostic
            currentStacks = 0, -- currentStacks is 0 for everyone, except buckets triggered by auras
            displayedStacks = nil,

            -- Constant for more efficient debugging
            description = "bucket "..spellID.." "..(GetSpellInfo(spellID) or ""),
        };
        bucket.trigger = SAO.Trigger:new(bucket);

        self.__index = nil;
        setmetatable(bucket, self);
        self.__index = self;

        return bucket;
    end,

    getOrCreateDisplay = function(self, stacks)
        if not self[stacks] then
            self[stacks] = SAO.Display:new(self, stacks);
            if stacks ~= 0 then
                -- Having at least one non-zero display is enough to know the bucket cares about number of stacks
                self.stackAgnostic = false;
            end
        end
        return self[stacks];
    end,

    show = function(self, options) -- @todo change existing code which called show(stacks) to now show()
        if not self.trigger:isFullyActivated() then
            SAO:Warn(Module, "Showing display of un-triggered "..self.description);
        end

        if self[0] then
            self[0]:show(options);
        end
        if self.currentStacks ~= 0 and self[self.currentStacks] then
            self[self.currentStacks]:show(options);
        end
    end,

    hide = function(self) -- @todo change existing code which called hide(stacks) to now hide()
        if self.displayedStacks then
            self[self.displayedStacks]:hide(); -- Due to how hiding works, hiding any display will hide all displays in the bucket
        end
    end,

    refresh = function(self) -- @todo change existing code which called refresh(stacks) to now refresh()
        if not self.displayedStacks then
            -- Nothing to refresh if nothing is displayed
            return;
        end

        if self[0] then
            self[0]:refresh();
        end
        if self.displayedStacks ~= 0 then
            self[self.displayedStacks]:refresh();
        end
    end,

    setStacks = function(self, stacks)
        -- Store stack counts for easier access, and to backup state known when entering the method
        local oldStacks, newStacks, displayedStacks = self.currentStacks, stacks, self.displayedStacks;
        if oldStacks == newStacks then
            return;
        end

        self.currentStacks = stacks;

        if self.trigger:isFullyActivated() then
            SAO:Debug(Module, "Changing number of stacks from "..tostring(oldStacks).." to "..newStacks.." for "..self.description);

            if displayedStacks == oldStacks and displayedStacks ~= nil then
                self[oldStacks]:hide();
                if self[newStacks] then
                    self[newStacks]:show({ mimicPulse = true });
                end
            elseif displayedStacks ~= newStacks and self[newStacks] then
                self[newStacks]:show();
            end
        end
    end,
}

SAO.BucketManager = {
    addAura = function(self, aura)
        local bucket, created = self:getOrCreateBucket(aura.name, aura.spellID);

        if created and not SAO:IsFakeSpell(aura.spellID) then
            bucket.trigger:add(SAO.TRIGGER_AURA, { bucket = bucket });
        end

        local display = bucket:getOrCreateDisplay(aura.stacks);
        if aura.overlay then
            display:addOverlay(aura.overlay);
        end
        for _, button in ipairs(aura.buttons or {}) do
            display:addButton(button);
        end
        if type(aura.combatOnly) == 'boolean' then
            display:setCombatOnly(aura.combatOnly);
        end
    end,

    getOrCreateBucket = function(self, name, spellID)
        local bucket = SAO.RegisteredBucketsBySpellID[spellID];
        local created = false;

        if not bucket then
            bucket = SAO.Bucket:create(name, spellID);
            SAO.RegisteredBucketsBySpellID[spellID] = bucket;
            SAO.RegisteredBucketsByName[name] = bucket;

            -- Cannot guarantee we can track spell ID on Classic Era, but can always track spell name
            if SAO.IsEra() and not SAO:IsFakeSpell(spellID) then
                local spellName = GetSpellInfo(spellID);
                if spellName then
                    SAO.RegisteredBucketsBySpellID[spellName] = bucket; -- Share pointer
                else
                    SAO:Debug(Module, "Registering aura with unknown spell "..tostring(spellID));
                end
            end

            created = true;
        end

        return bucket, created;
    end
}

function SAO:GetBucketByName(name)
    return self.RegisteredBucketsByName[name];
end

function SAO:GetBucketBySpellID(spellID)
    return SAO.RegisteredBucketsBySpellID[spellID];
end

function SAO:GetBucketBySpellIDOrSpellName(spellID, fallbackSpellName)
    if not SAO.IsEra() or (type(spellID) == 'number' and spellID ~= 0) then
        return SAO.RegisteredBucketsBySpellID[spellID], spellID;
    else
        -- Due to Classic Era limitation, aura is registered by its spell name
        local bucket = SAO.RegisteredBucketsBySpellID[fallbackSpellName];
        if bucket then
            -- Must fetch spellID from aura, because spellID from CLEU is most likely 0 at this point
            -- We can fetch any aura from auras because all auras store the same spellID
            for stack, effects in pairs(bucket) do
                spellID = effects[1].spellID; -- [1] for first effect in effects, .spellID to get its spell ID
                break;
            end
        end
        return bucket, spellID;
    end
end

function SpellActivationOverlay_DumpBuckets()
    local nbBuckets = 0;
    for _, _ in pairs(SAO.RegisteredBucketsBySpellID) do
        nbBuckets = nbBuckets + 1;
    end
    SAO:Info(Module, "Listing buckets ("..nbBuckets.." item"..(nbBuckets == 1 and "" or "s")..")");

    for spellID, bucket in pairs(SAO.RegisteredBucketsBySpellID) do
        local str = bucket.name.." "..
            "nbStacks == "..tostring(bucket.currentStacks)..", "..
            "dispStacks == "..tostring(bucket.displayedStacks)..", "..
            "triggerReq == "..tostring(bucket.trigger.required)..", "..
            "triggerNow == "..tostring(bucket.trigger.activated);
        SAO:Info(Module, str);
    end
end
