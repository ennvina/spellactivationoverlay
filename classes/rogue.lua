local AddonName, SAO = ...
local Module = "rogue"

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetTime = GetTime
local UnitGUID = UnitGUID

--[[
    RiposteHandler guesses when Riposte is available,
    even while the ability is on cooldown

    The following conditions must be met:
    - the player parried recently

    This stops if either:
    - Riposte has been cast
    - more than 5 seconds have elapsed since last parry
]]
local RiposteHandler = {

    initialized = false,

    -- Methods

    init = function(self, id, name)
        SAO.GlowInterface:bind(self);
        local variantValues = {
            SAO:CooldownVariantValue({ "off" }),
            SAO:CooldownVariantValue({ "off", "on" }),
        }
        self:initVars(id, name, true, 5, variantValues, function (option)
            return option == "cd:off/on";
        end);
        self.alertVariants = SAO:CreateStringVariants("alert", self.optionID, 0, variantValues);
        self.alerting = false;
        self.lastRiposteTime = nil;
        self.initialized = true;
    end,

    parried = function(self)
        if self.lastRiposteTime and GetTime() < self.lastRiposteTime + 1 then
            -- When the player parries too quickly after last Riposte cast, Riposte cannot be cast
            -- More exactly, the ability will look like it will be usable, but it will fade before cooldown allows to re-cast it
            -- This is due to the fact that Riposte is available for 5 secs after a parry, but the cooldown is 6 secs
            -- So, there is a 1-second window where a parry event would trigger a misleading Riposte effect
            -- If we displayed the effect, the player would believe Riposte is available either now or soon, whereas in practice it's never available
            -- We simply ignore parry events in this 1-second window, hence the (GetTime() < self.lastRiposteTime + 1) test
            SAO:Debug(Module, "Ignoring a parry event because it occurred less than 1 second after last Riposte cast");
            return;
        end
        self:glow();
        self:alert();
    end,

    riposte = function(self)
        self.lastRiposteTime = GetTime();
        -- Always unglow, even if not needed. Better unglow too much than not enough.
        self:unglow();
        self:unalert();
    end,

    cleu = function(self, ...)
        local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = ...; -- For all events

        local myGuid = UnitGUID("player");

        if sourceGUID == myGuid then
            if event == "SPELL_CAST_SUCCESS" and select(13, ...) == self.spellName then
                self:riposte();
            end
        end

        if destGUID == myGuid and (event == "SWING_MISSED" or event == "SPELL_MISSED") then
            local missType;
            if event == "SWING_MISSED" then
                missType = select(12, ...);
            elseif event == "SPELL_MISSED" then
                missType = select(15, ...);
            end
            if missType == "PARRY" then
                self:parried();
            end
        end
    end,

    alert = function(self)
        if self.optionTestFunc(self.alertVariants.getOption()) then
            if not self.alerting then
                local aura = SAO.RegisteredAurasByName["riposte"];
                if aura then
                    -- It might conflict with 'default' counter effect
                    -- But tests showed no significant issues so far
                    SAO:ActivateOverlay(select(2, unpack(aura)));
                end
                self.alerting = true;
            end

            -- Start alert timer, very similar to glow timer
            -- There might exist a timer for glow already, and we could benefit from it by implementing onTimeout()
            -- But because alert option and glow option are independent, the glow timer may not be running right now
            local tolerance = 0.2;
            self.alertVanishTime = GetTime() + self.maxDuration - tolerance;
            C_Timer.After(self.maxDuration, function()
                if self.alertVanishTime and GetTime() > self.alertVanishTime then
                    self:unalert();
                end
            end);
        end
    end,

    unalert = function(self)
        if self.alerting then
            self.alerting = false;
            local aura = SAO.RegisteredAurasByName["riposte"];
            if aura then
                local auraSpellID = aura[3];
                SAO:DeactivateOverlay(auraSpellID);
            end

            -- Tell the timer that there is no need to remove alert after timeout, because alert is already removed
            self.alertVanishTime = nil;
        end
    end,
}

local function customLogin(self, ...)
    -- Initialization on PLAYER_LOGIN event because the talent tree may not be available before

    local riposteSpellID = 14251;
    local riposteSpellName = GetSpellInfo(riposteSpellID);

    if (riposteSpellName) then
        RiposteHandler:init(riposteSpellID, riposteSpellName);

        local _, _, tab, index = self:GetTalentByName(riposteSpellName);
        local talent;
        if (type(tab) == "number" and type(index) == "number") then
            talent = { tab, index };
        end

        self:RegisterCounter("riposte", talent); -- 1st arguement must match 1st argument passed to RegisterAura
    end
end

local function customCLEU(self, ...)
    if RiposteHandler.initialized then
        RiposteHandler:cleu(CombatLogGetCurrentEventInfo());
    end
end

local function registerClass(self)
    -- Register Riposte as both an aura and a counter
    -- Rogue does not really have a 'Riposte' aura, but it will be used by RegisterCounter in customLogin()

    -- The aura must be registered as soon as possible, because it registers the glowID before parsing action buttons
    -- The counter must be registered as late as possible, because it requires the talent tree, which is not available now
    local riposteSpellID = 14251;
    self:RegisterAura("riposte", 0, riposteSpellID, "bandits_guile", "Top (CW)", 1, 255, 255, 255, true, { riposteSpellID });
end

local function loadOptions(self)
    if RiposteHandler.initialized then
        self:AddOverlayOption(RiposteHandler.spellID, RiposteHandler.spellID, 0, nil, RiposteHandler.alertVariants);
        self:AddGlowingOption(nil, RiposteHandler.optionID, RiposteHandler.spellID, nil, nil, RiposteHandler.variants);
    end
end

SAO.Class["ROGUE"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["PLAYER_LOGIN"] = customLogin,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
}
