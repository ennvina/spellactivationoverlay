local AddonName, SAO = ...

-- Optimize frequent calls
local GetTime = GetTime
local PlaySound = PlaySound
local PlaySoundFile = PlaySoundFile
local StopSound = StopSound

-- Remember last time the Spell Alert sound was played
-- This is used to prevent the same sound to be played several times at the same time
-- For example, "Left + Right" will display a "Left" aura and "Right" aura, but we only want o single sound effect
local timeOfLastPlayedAlert = nil

-- Play a Spell Alert sound effect
-- Return the sound handle ID, or nil if sound will not play e.g., muted channel
function SAO.PlaySpellAlertSound(self)
    if GetTime() == timeOfLastPlayedAlert then
        return;
    end

    local willPlay, soundHandle;

    if SAO.IsProject(SAO.ERA + SAO.TBC + SAO.WRATH) then
        willPlay, soundHandle = PlaySoundFile("Interface\\Addons\\SpellActivationOverlay\\sounds\\UI_PowerAura_Generic.ogg");
    else
        -- SOUNDKIT.UI_POWER_AURA_GENERIC was introduced in Cataclysm
        willPlay, soundHandle = PlaySound(SOUNDKIT.UI_POWER_AURA_GENERIC);
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
