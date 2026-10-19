local AddonName, SAO = ...
local Module = "sound"

-- Optimize frequent calls
local GetTime = GetTime
local PlaySound = PlaySound
local PlaySoundFile = PlaySoundFile
local StopSound = StopSound

-- Remember last time the Spell Alert sound was played
-- This is used to prevent the same sound to be played several times at the same time
-- For example, "Left + Right" will display a "Left" aura and "Right" aura, but we only want o single sound effect
local timeOfLastPlayedAlert = nil

local mustUseLocalSound = SAO.IsProject(
    SAO.ERA + SAO.TBC + SAO.WRATH + -- Flavors where SOUNDKIT.UI_POWER_AURA_GENERIC is absent
    SAO.FOREVER + SAO.RETAIL -- Flavors where SOUNDKIT.UI_POWER_AURA_GENERIC exists but the sound is inaudible
)

local localSound = "Interface\\AddOns\\SpellActivationOverlay\\sounds\\UI_PowerAura_Generic.ogg"
local gameSound = SOUNDKIT.UI_POWER_AURA_GENERIC


-- Play a Spell Alert sound effect
-- Return the sound handle ID, or nil if sound will not play e.g., muted channel
function SAO.PlaySpellAlertSound(self)
    if GetTime() == timeOfLastPlayedAlert then
        return;
    end

    local willPlay, soundHandle;

    if mustUseLocalSound then
        willPlay, soundHandle = PlaySoundFile(localSound);
    else
        -- SOUNDKIT.UI_POWER_AURA_GENERIC was introduced in Cataclysm
        willPlay, soundHandle = PlaySound(gameSound);
    end

    if willPlay then
        timeOfLastPlayedAlert = GetTime();
        return soundHandle;
    end
end

-- Stop playing a Spell Alert sound effect
-- @param handle Sound handle returned by PlaySpellAlertSound()
-- @param fadeoutTime (optional) fade out duration in milliseconds
function SAO.StopSpellAlertSound(self, handle, fadeoutTime)
    if handle then
        StopSound(handle, fadeoutTime);
    end
end

--[[
    AuraSoundLibrary stores the list of sounds currently active for an AuraContainerItem, sorted by spellID
    Due to how the game's AuraSound API works, it is impossible to target a specific number of applications
    Therefore, the rules aren this:
    - If at least one item enables the sound for a specific spell ID, the sound will be played
    - Conversely, if no item enables the sound for a spell ID, it will not be played
    - Also, the globalEnabled flag controls whether any aura sounds can be played at all
]]
SAO.AuraSoundLibrary = {
    globalEnabled = true, -- Whether the global sound is enabled

    enableItem = function(self, item)
        SAO:Trace(Module, "Enabling aura sound for item "..tostring(item.id).." with spellID "..tostring(item.spellID))
        local spellID = item.spellID
        if not self[spellID] then
            self[spellID] = {
                items = {},
                auraSoundIDs = nil, -- Non-nil indicates a sound is currently playing
            }
        end

        if self[spellID].items[item.id] then
            SAO:Warn(Module, "Enabling aura sound for item "..tostring(item.id).." with spellID "..tostring(item.spellID).." which is already enabled") --[[DEV_ONLY]]
        end
        self[spellID].items[item.id] = item;

        if not self[spellID].auraSoundIDs and self.globalEnabled then
            local auraSoundID1, auraSoundID2 = self:_internalAddSound(spellID, item.unit)
            SAO:Debug(Module, "Enabling sound for spell ID", spellID)

            self[spellID].auraSoundIDs = { auraSoundID1, auraSoundID2 }
        end
    end,

    disableItem = function(self, item)
        SAO:Trace(Module, "Disabling aura sound for item "..tostring(item.id).." with spellID "..tostring(item.spellID))
        local spellID = item.spellID
        if self[spellID] then
            if not self[spellID].items[item.id] then
                SAO:Warn(Module, "Disabling aura sound for item "..tostring(item.id).." with spellID "..tostring(item.spellID).." which is not enabled") --[[DEV_ONLY]]
            end
            self[spellID].items[item.id] = nil

            if next(self[spellID].items) == nil and self[spellID].auraSoundIDs then
                self:_internalRemoveSound(unpack(self[spellID].auraSoundIDs))
                SAO:Debug(Module, "Disabling sound for spell ID", spellID)

                self[spellID].auraSoundIDs = nil
            end
        end
    end,

    setGlobalEnabled = function(self, enabled)
        if self.globalEnabled == enabled then
            return
        end
        self.globalEnabled = enabled

        for spellID, soundData in pairs(self) do
            if type(spellID) == 'number' then -- Assumes that all numeric keys are spell IDs
                if soundData.auraSoundIDs and not enabled then
                    -- There was a sound and global sound is being disabled
                    self:_internalRemoveSound(unpack(soundData.auraSoundIDs))
                    SAO:Debug(Module, "Global sound disable is disabling sound of spell ID", spellID)

                    soundData.auraSoundIDs = nil
                elseif not soundData.auraSoundIDs and enabled then
                    -- There was no sound and global sound is being enabled
                    local firstItemID, firstItem = next(soundData.items)
                    if firstItem ~= nil then
                        local unit = firstItem.unit -- Use arbitrarily the unit of the first item; all items should share the same unit token
                        local auraSoundID1, auraSoundID2 = self:_internalAddSound(spellID, unit)
                        SAO:Debug(Module, "Global sound enable is enabling sound of spell ID", spellID)

                        soundData.auraSoundIDs = { auraSoundID1, auraSoundID2 }
                    end
                end
            end
        end
    end,

    _internalAddSound = function(self, spellID, unit)
        local trigger1 = Enum.UnitAuraSoundTrigger.Added
        local trigger2 = Enum.UnitAuraSoundTrigger.ApplicationsIncreased

        local sound = {
            unitToken = unit,
            spellID = spellID,
            soundFileName = mustUseLocalSound and localSound or nil,
            soundFileID = not mustUseLocalSound and gameSound or nil,
        }

        local auraSoundID1 = C_UnitAuras.AddAuraSound(trigger1, sound)
        local auraSoundID2 = C_UnitAuras.AddAuraSound(trigger2, sound)

        return auraSoundID1, auraSoundID2
    end,

    _internalRemoveSound = function(self, auraSoundID1, auraSoundID2)
        assertsafe(auraSoundID1)
        assertsafe(auraSoundID2)
        C_UnitAuras.RemoveAuraSound(auraSoundID1)
        C_UnitAuras.RemoveAuraSound(auraSoundID2)
    end,
}
