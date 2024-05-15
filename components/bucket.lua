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
SAO.AuraBucket = {
    create = function(self, spellID)
        local obj = {
            -- Spell ID is the main identifier to activate/deactivate visuals
            spellID = spellID,

            -- Count-agnostic means the bucket does not care about its number of stacks
            countAgnostic = true,
        };

        self.__index = nil;
        setmetatable(obj, self);
        self.__index = self;

        return obj;
    end,

    getOrCreateDisplay = function(self, stacks)
        if not self[stacks] then
            self[stacks] = SAO.Display:new(self.spellID, stacks);
            if stacks ~= 0 then
                -- Having at least one non-zero display is enough to know the bucket cares about number of stacks
                self.countAgnostic = false;
            end
        end
        return self[stacks];
    end,

    show = function(self, stacks, options)
        if self[0] then
            self[0]:show(options);
        end
        if stacks ~= 0 then
            self[stacks]:show(options);
        end
    end,

    hide = function(self, stacks)
        if self[0] then
            self[0]:hide();
        end
        if stacks ~= 0 then
            self[stacks]:hide();
        end
    end,

    refresh = function(self, stacks)
        if self[0] then
            self[0]:refresh();
        end
        if stacks ~= 0 then
            self[stacks]:refresh();
        end
    end,

    changeStacks = function(self, oldStacks, newStacks)
        local spellID = self.spellID;
        SAO:Debug(Module, "Changing number of stacks from "..tostring(oldStacks).." to "..newStacks.." for bucket "..spellID.." "..(GetSpellInfo(spellID) or ""));
        if oldStacks == newStacks then
            SAO:Warn(Module, "Changing number of stacks with same number");
            return;
        elseif oldStacks == 0 then
            SAO:Warn(Module, "Changing number of stacks from 0 to "..tostring(newStacks));
        elseif newStacks == 0 then
            SAO:Warn(Module, "Changing number of stacks from "..tostring(oldStacks).." to 0");
        end

        self[oldStacks]:hide();
        self[newStacks]:show({ mimicPulse = true });
    end,
}

SAO.BucketManager = {
    addAura = function(self, aura)
        local bucket = self:getOrCreateBucket(aura.spellID);
        SAO.RegisteredBucketsByName[aura.name] = bucket; -- May overwrite, but will overwrite with itself

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

        -- Display aura immediately, if found
        local count = SAO:GetPlayerAuraCountBySpellID(aura.spellID);
        if count ~= nil and (aura.stacks == 0 or aura.stacks == count) then
            -- @todo must MarkDisplay in the process. Might require something more complex (because other auras with same spellID may be triggered at start)
            display:show();
        end
    end,

    getOrCreateBucket = function(self, spellID)
        local bucket = SAO.RegisteredBucketsBySpellID[spellID];

        if not bucket then
            bucket = SAO.AuraBucket:create(spellID);
            SAO.RegisteredBucketsBySpellID[spellID] = bucket;

            -- Cannot guarantee we can track spell ID on Classic Era, but can always track spell name
            if SAO.IsEra() and not SAO:IsFakeSpell(spellID) then
                local spellName = GetSpellInfo(spellID);
                if spellName then
                    SAO.RegisteredBucketsBySpellID[spellName] = bucket; -- Share pointer
                else
                    SAO:Debug(Module, "Registering aura with unknown spell "..tostring(spellID));
                end
            end
        end

        return bucket;
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
