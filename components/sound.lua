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
    - Incidentally, if no item enables the sound for a spell ID, it will not be played
]]
SAO.AuraSoundLibrary = {
    enableItem = function(self, item)
        SAO:Trace(Module, "Enabling aura sound for item "..tostring(item.id).." with spellID "..tostring(item.spellID))
        local spellID = item.spellID
        if not self[spellID] then
            self[spellID] = {
                itemIDs = {},
                auraSoundID = nil, -- Non-nil indicates a sound is currently playing
            }
        end

        if not tContains(self[spellID].itemIDs, item.id) then
            table.insert(self[spellID].itemIDs, item.id)
        end
        if not self[spellID].auraSoundID then
            local trigger = Enum.UnitAuraSoundTrigger.Added -- @todo Maybe consider Enum.UnitAuraSoundTrigger.ApplicationsIncreased
            local sound = {
                unitToken = item.unit,
                spellID = item.spellID,
                soundFileName = mustUseLocalSound and localSound or nil,
                soundFileID = not mustUseLocalSound and gameSound or nil,
            }
            local auraSoundID = C_UnitAuras.AddAuraSound(trigger, sound)
            SAO:Debug(Module, "Enabling sound for spell ID", spellID)

            self[spellID].auraSoundID = auraSoundID
        end
    end,

    disableItem = function(self, item)
        SAO:Trace(Module, "Disabling aura sound for item "..tostring(item.id).." with spellID "..tostring(item.spellID))
        local spellID = item.spellID
        if self[spellID] then
            for i, id in ipairs(self[spellID].itemIDs) do
                if id == item.id then
                    table.remove(self[spellID].itemIDs, i)
                    break
                end
            end
            if #self[spellID].itemIDs == 0 and self[spellID].auraSoundID then
                C_UnitAuras.RemoveAuraSound(self[spellID].auraSoundID)
                SAO:Debug(Module, "Disabling sound for spell ID", spellID)

                self[spellID].auraSoundID = nil
            end
        end
    end,
}
