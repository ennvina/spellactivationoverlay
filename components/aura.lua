local AddonName, SAO = ...
local Module = "aura"

--[[
    Lists of auras that must be tracked
    These lists should be setup at start, based on the player class

    The name should be unique
    For stackable buffs, the stack count should be appended e.g., maelstrom_weapon_4

    Spell IDs may not be unique, especially for stackable buffs
    Because of that, RegisteredAuraBucketsBySpellID is a multimap instead of a map
]]
SAO.RegisteredAuraBucketsByName = {}
SAO.RegisteredAuraBucketsBySpellID = {}

--[[
    List of markers for each aura activated excplicitly by an aura event, usually from CLEU.
    Key = spellID, Value = number of stacks, or nil if marker is reset

    This list looks redundant with SAO.ActiveOverlays, but there are significant differences:
    - ActiveOverlays tracks absolutely every overlay, while AuraMarkers is focused on "aura from CLEU"
    - ActiveOverlays is limited to effects that have an overlay, while AuraMarkers tracks effects with or without overlays
]]
SAO.AuraMarkers = {}

-- Basic Aura object, promoted with show/hide functions and easy access to variables
local Aura = {

    bind = function(self, obj)
        self.__index = nil;
        setmetatable(obj, self);
        self.__index = self;

        obj.name = obj[1];
        obj.stacks = obj[2];
        obj.spellID = obj[3];
        if obj[4] then
            obj.overlays = {
                stacks = obj[2],
                spellID = obj[3],
                texture = obj[4],
                position = obj[5],
                scale = obj[6],
                r = obj[7], g = obj[8], b = obj[9],
                autoPulse = obj[10],
                combatOnly = obj[13],
                show = function(self)
                    SAO:ActivateOverlay(self.stacks, self.spellID, self.texture, self.position, self.scale, self.r, self.g, self.b, self.autoPulse, nil, nil, self.combatOnly);
                end,
                hide = function(self)
                    SAO:DeactivateOverlay(self.spellID);
                end,
            }
        else
            obj.overlays = {
                show = function() end,
                hide = function() end,
            }
        end
        if obj[11] then
            obj.buttons = obj[11];
            obj.buttons.spellID = obj[3];
            obj.buttons.show = function(self)
                SAO:AddGlow(self.spellID, self);
            end
            obj.buttons.hide = function(self)
                SAO:RemoveGlow(self.spellID);
            end
        else
            obj.buttons =  {
                show = function() end,
                hide = function() end,
            }
        end
        obj.combatOnly = obj[13];
    end,

    show = function(self)
        self.overlays:show();
        self.buttons:show();
    end,

    hide = function(self)
        SAO:Warn(Module, "Removing an individual aura but there's no reason to, for spell "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        self.overlays:hide();
        self.buttons:hide();
    end,
}

-- List of Aura objects
AuraArray = {
    create = function(self, spellID, stacks)
        local obj = {};
        self.__index = nil;
        setmetatable(obj, self);
        self.__index = self;

        obj.spellID = spellID;
        obj.stacks = stacks;
        obj.hasOverlay = false;
        obj.hasButton = false;

        return obj;
    end,

    add = function(self, aura)
        table.insert(self, aura);
        self.hasOverlay = self.hasOverlay or aura.overlays ~= nil;
        self.hasButton = self.hasButton or aura.buttons ~= nil;
    end,

    show = function(self)
        if not self.hasOverlay and not self.hasButton then
            SAO:Warn(Module, "Showing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or "").." but there are no displays attached to it");
            return;
        end
        SAO:Debug(Module, "Showing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        SAO:MarkAura(self.spellID, self.stacks);
        for _, aura in ipairs(self) do
            aura:show();
        end
    end,

    hide = function(self)
        SAO:Debug(Module, "Removing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        SAO:UnmarkAura(self.spellID);
        if self.hasOverlay then
            SAO:DeactivateOverlay(self.spellID);
        end
        if self.hasButton then
            SAO:RemoveGlow(self.spellID);
        end
    end,
}

-- List of aura arrays, indexed by stack count
local AuraBucket = {
    create = function(self)
        local obj = {};
        self.__index = nil;
        setmetatable(obj, self);
        self.__index = self;
        return obj;
    end,

    addAura = function(self, aura)
        if not self[aura.stacks] then
            self[aura.stacks] = AuraArray:create(aura.spellID, aura.stacks);
        end
        self[aura.stacks]:add(aura);
    end,
}

local AuraBucketManager = {
    addAura = function(self, spellID, aura)
        local auraBucket = self:getOrCreateBucket(spellID);
        auraBucket:addAura(aura);

        SAO.RegisteredAuraBucketsByName[aura.name] = auraBucket;
    end,

    getOrCreateBucket = function(self, spellID)
        local bucket = SAO.RegisteredAuraBucketsBySpellID[spellID];

        if not bucket then
            bucket = AuraBucket:create();
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

-- Register a new aura
-- If texture is nil, no Spell Activation Overlay (SAO) is triggered; subsequent params are ignored until glowIDs
-- If texture is a function, it will be evaluated at runtime when the SAO is triggered
-- If glowIDs is nil or empty, no Glowing Action Button (GAB) is triggered
-- All SAO arguments (between spellID and b, included) mimic Retail's SPELL_ACTIVATION_OVERLAY_SHOW event arguments
function SAO.RegisterAura(self, name, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, glowIDs, combatOnly)
    if (type(texture) == 'string') then
        texture = self.TexName[texture];
    end
    local aura = { name, stacks, spellID, texture, positions, scale, r, g, b, autoPulse, glowIDs, nil, combatOnly }
    Aura:bind(aura);

    if (type(texture) == 'string') then
        self:MarkTexture(texture);
    end

    -- Register aura in the spell list, sorted by spell ID and by stack count
    AuraBucketManager:addAura(spellID, aura);

    -- Register the glow IDs
    -- The same glow ID may be registered by different auras, but it's okay
    self:RegisterGlowIDs(glowIDs);

    -- Apply aura immediately, if found
    local exists, _, count = self:FindPlayerAuraByID(spellID);
    if (exists and (stacks == 0 or stacks == count)) then
        aura:show();
    end
end

function SAO:MarkAura(spellID, count)
    if type(count) ~= 'number' then
        self:Debug(Module, "Marking aura of "..tostring(spellID).." with invalid count "..tostring(count));
    end
    if type(self.AuraMarkers[spellID]) == 'number' then
        self:Debug(Module, "Marking aura of "..tostring(spellID).." with count "..tostring(count).." but it already has a count of "..self.AuraMarkers[spellID]);
    end
    self.AuraMarkers[spellID] = count;
end

function SAO:UnmarkAura(spellID)
    self.AuraMarkers[spellID] = nil;
end

function SAO:GetAuraMarker(spellID)
    return self.AuraMarkers[spellID];
end

-- Change count of already displayed aura
function SAO:ChangeAuraCount(spellID, oldCount, newCount, auras)
    self:Debug(Module, "Changing number of stacks from "..tostring(oldCount).." to "..newCount.." for aura "..spellID.." "..(GetSpellInfo(spellID) or ""));
    self:DeactivateOverlay(spellID);
    self:RemoveGlow(spellID);
    self:MarkAura(spellID, newCount); -- Call MarkAura after DeactivateOverlay, because DeactivateOverlay may reset its aura marker
    for _, aura in ipairs(auras) do
        local texture, positions, scale, r, g, b, autoPulse, _, _, combatOnly = select(4,unpack(aura));
        local forcePulsePlay = autoPulse;
        self:ActivateOverlay(newCount, spellID, texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, nil, combatOnly);
        aura.buttons:show();
    end
end

-- Reactivate aura timer
function SAO:RefreshAura(spellID)
    self:Debug(Module, "Refreshing aura of "..spellID.." "..(GetSpellInfo(spellID) or ""));
    self:RefreshOverlayTimer(spellID);
end
