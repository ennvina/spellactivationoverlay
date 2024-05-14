local AddonName, SAO = ...
local Module = "bucket"

--[[
    Aura Bucket and Effect Bucket

    A 'bucket' is a container that stores maps of lists of items
    Buckets are maps which key is a number of stacks, and value is a list

    Each list is a Lua indexed table, called 'array'
    Arrays store nodes of their respective kind

    Their respective counterparts have the same interface:
    - aura buckets and effect buckets have the same interface
    - aura arrays and effect arrays have the same interface
    - aura nodes and effect nodes have the same interface
]]

--[[
    Lists of auras and effects that must be tracked
    These lists should be setup at start, based on the player class
]]
SAO.RegisteredAuraBucketsByName = {}
SAO.RegisteredAuraBucketsBySpellID = {}

-- List of aura arrays, indexed by stack count
SAO.AuraBucket = {
    create = function(self)
        local obj = {};
        self.__index = nil;
        setmetatable(obj, self);
        self.__index = self;
        return obj;
    end,

    addNode = function(self, aura)
        if not self[aura.stacks] then
            self[aura.stacks] = SAO.AuraArray:create(aura.spellID, aura.stacks);
        end
        if not self.spellID then
            self.spellID = aura.spellID;
        elseif self.spellID ~= aura.spellID then
            SAO:Warn(Module, "Aura Bucket is getting distinct spell IDs "..tostring(self.spellID).." vs. "..tostring(aura.spellID));
        end
        self[aura.stacks]:add(aura);
    end,

    show = function(self, stacks)
        self[stacks]:show();
    end,

    hide = function(self, stacks)
        self[stacks]:hide();
    end,

    refresh = function(self, stacks)
        self[stacks]:refresh();
    end,

    changeStacks = function(self, oldStacks, newStacks)
        -- Change count of already displayed aura
        local spellID = self.spellID;
        SAO:Debug(Module, "Changing number of stacks from "..tostring(oldStacks).." to "..newStacks.." for aura "..spellID.." "..(GetSpellInfo(spellID) or ""));

        self[oldStacks]:hide();

        -- self[newStacks]:show(); -- Cannot simply show, because we may need to force pulse play
        SAO:MarkAura(spellID, newStacks);
        for _, aura in ipairs(self[newStacks]) do
            local o = aura.overlays;
            local texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly = o.texture, o.position, o.scale, o.r, o.g, o.b, o.autoPulse, o.autoPulse, nil, o.combatOnly;
            -- Note: forcePulsePlay is assigned to o.autoPulse, endTime is assigned to nil
            SAO:ActivateOverlay(newStacks, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly);
            aura.buttons:show();
        end
    end,
}

SAO.AuraBucketManager = {
    addNode = function(self, aura)
        local auraBucket = self:getOrCreateBucket(aura.spellID);
        auraBucket:addNode(aura);
        SAO.RegisteredAuraBucketsByName[aura.name] = auraBucket; -- May overwrite, but will overwrite with itself

        -- Display aura immediately, if found
        local exists, _, count = SAO:FindPlayerAuraByID(aura.spellID);
        if (exists and (aura.stacks == 0 or aura.stacks == count)) then
            aura:show();
        end
    end,

    getOrCreateBucket = function(self, spellID)
        local bucket = SAO.RegisteredAuraBucketsBySpellID[spellID];

        if not bucket then
            bucket = SAO.AuraBucket:create();
            SAO.RegisteredAuraBucketsBySpellID[spellID] = bucket;

            -- Cannot guarantee we can track spell ID on Classic Era, but can always track spell name
            if SAO.IsEra() and not SAO:IsFakeSpell(spellID) then
                local registeredSpellID = GetSpellInfo(spellID);
                if registeredSpellID then
                    SAO.RegisteredAuraBucketsBySpellID[registeredSpellID] = bucket; -- Share pointer
                else
                    SAO:Debug(Module, "Registering aura with unknown spell "..tostring(spellID));
                end
            end
        end

        return bucket;
    end
}

function SAO:GetBucketByName(name)
    return self.RegisteredAuraBucketsByName[name];
end

function SAO:GetBucketBySpellID(spellID)
    return SAO.RegisteredAuraBucketsBySpellID[spellID];
end

function SAO:GetBucketBySpellIDOrSpellName(spellID, fallbackSpellName)
    if not SAO.IsEra() or (type(spellID) == 'number' and spellID ~= 0) then
        return SAO.RegisteredAuraBucketsBySpellID[spellID], spellID;
    else
        -- Due to Classic Era limitation, aura is registered by its spell name
        local bucket = SAO.RegisteredAuraBucketsBySpellID[fallbackSpellName];
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
