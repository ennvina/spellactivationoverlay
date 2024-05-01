local AddonName, SAO = ...

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetTalentInfo = GetTalentInfo
local UnitGUID = UnitGUID

-- Detect Rolling Thunder stacks
local RollingThunderHandler = {
    -- Constants
    lightningShield = {324, 325, 905, 945, 8134, 10431, 10432},
    fakeSpellID = 324+1000000, -- For option testing

    -- Constants that will be initialized at init()
    lightningShieldSpellIDs = {},
    earthShockSpells = {},
    -- Variables
    initialized = false,
    glowtimer,

    -- Methods
    init = function(self)
        -- Fetch spell name of Earth Shock
        -- Instead, we could hardcode the list of spell IDs of all ranks, but the spell name is fine
        table.insert(self.earthShockSpells, (GetSpellInfo(8042)));

        -- Keep spell ID of Lightning Shield ranks only for ranks known at the current expansion
        for _, id in pairs(self.lightningShield) do
            local name = GetSpellInfo(id);
            if name then
                self.lightningShieldSpellIDs[id] = true;
            end
        end
        self:addSpellIDCandidates(self.lightningShield);

        self.initialized = true;
    end,

    addSpellIDCandidates = function(self, ids)
    end,

    cleu = function(self)
        local _, event, _, _, _, _, _, destGUID, _, _, _, _, _, _, _, stacks = CombatLogGetCurrentEventInfo()

        -- Event must relate to the player
        if (not destGUID) or (destGUID ~= UnitGUID("player")) then return end

        -- Event must be about spell auras
        if (event:sub(0,11) ~= "SPELL_AURA_") then return end

        local spellID, spellName = select(12, CombatLogGetCurrentEventInfo());
        if SAO:IsCata() then
            if (self.lightningShieldSpellIDs[spellID]) then
                if (event == "SPELL_AURA_APPLIED_DOSE") then
                    -- Deactivating old overlays and activating new one when Lightning Shield stack is gained
                    if stacks >= 6 then
                        self:deactivate();
                        self:activate(stacks);
                    end
                elseif (event == "SPELL_AURA_REMOVED_DOSE") then
                    -- Deactivating old overlays and activating new one when Lightning Shield stack is lost
                    if stacks >= 6 then
                        self:deactivate();
                        self:activate(stacks);
                    else
                        self:deactivate();
                    end
                end
            end
            else
                if (self.lightningShieldSpellIDs[spellID]) then
                    if (event == "SPELL_AURA_APPLIED_DOSE") then
                        -- Deactivating old overlays and activating new one when Lightning Shield stack is gained
                        if stacks >= 7 then
                            self:deactivate();
                            self:activate(stacks);
                        end
                    elseif (event == "SPELL_AURA_REMOVED_DOSE") then
                        -- Deactivating old overlays and activating new one when Lightning Shield stack is lost
                        if stacks >= 7 then
                            self:deactivate();
                            self:activate(stacks);
                        else
                            self:deactivate();
                    end
                end
            end
        end
    end,

    activate = function(self, lightningShieldStacks)
        -- SAO
        local staticShockEquipped = C_Engraving and C_Engraving.IsRuneEquipped(49679);
        if staticShockEquipped then
            return;
        end
        local saoOption = SAO:GetOverlayOptions(324);
        local hasSAO = not saoOption or type(saoOption[lightningShieldStacks]) == "nil" or saoOption[lightningShieldStacks];
        if (hasSAO) then
            local scale = 0.5 + 0.1 * (lightningShieldStacks - 6);
            if SAO:IsCata() then local scale = 0.5 + 0.1 * (lightningShieldStacks - 5); end
            local pulse = lightningShieldStacks == 9 or nil;
            SAO:ActivateOverlay(lightningShieldStacks, 324, SAO.TexName["fulmination"], "Top", scale, 255, 255, 255, pulse, pulse);
        end

        -- GABs
        local gabOption = SAO:GetGlowingOptions(324);
        local hasESGAB = not gabOption or type(gabOption[324]) == "nil" or gabOption[324];
        if (hasESGAB and (hasSAO or lightningShieldStacks == 9)) then
            SAO:AddGlow(324, self.earthShockSpells); -- First arg is option ID, second arg is spell ID list
        end
    end,

    deactivate = function(self)
        -- SAO
        SAO:DeactivateOverlay(324);

        -- GAB
        SAO:RemoveGlow(324);
    end,
}

-- Must deactivate Rolling Thunder if the rune is lost on wrists
-- Must activate Rolling Thunder after logging or changing runes, if the rune is present on wrists and if there are 7 or more charges or Lightning Shield
-- This function does not re-activate the effect if already activated
local function checkRollingThunderRuneAndLightningSieldStacks(self, ...)
    if not RollingThunderHandler.initialized then
        return;
    end

    local RollingThunderEquipped = (C_Engraving and SAO:IsSpellLearned(432056)) or SAO:GetTalentByName((GetSpellInfo(88766)));
    if not RollingThunderEquipped then
        RollingThunderHandler:deactivate();
    else
        -- C_UnitAuras is currently available for Classic Era and Cataclysm only
        -- Fortunately, RollingThunderHandler is used only on Season of Discovery and Cataclysm
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", GetSpellInfo(324));
        if SAO:IsCata() then
            if aura and aura.applications > 5 and not SAO:GetActiveOverlay(324) then
                RollingThunderHandler:activate(aura.applications);
            end
        else
            if aura and aura.applications > 6 and not SAO:GetActiveOverlay(324) then
                RollingThunderHandler:activate(aura.applications);
            end
        end
    end
end

local function rollingThunderCombatCheck(combat)
    local TimetoLingerGlow = 2.5; -- Buttons glows temporarily for 2.5 secs
    if not combat then RollingThunderHandler.glowtimer = C_Timer.NewTimer(
        TimetoLingerGlow,
        function() RollingThunderHandler:deactivate(); end
    )
    end
    if combat then
        if RollingThunderHandler.glowtimer then
            RollingThunderHandler.glowtimer:Cancel();
            end
        checkRollingThunderRuneAndLightningSieldStacks();
    end
end

local function deactivateRollingThunderGlow(self, ...)
    rollingThunderCombatCheck(false);
end

local function activateRollingThunderGlow(self, ...)
    rollingThunderCombatCheck(true);
end

local function customCLEU(self, ...)
    if RollingThunderHandler.initialized then
        RollingThunderHandler:cleu();
    end
end

local function registerClass(self)

    if self.IsWrath() or self.IsTBC() then
        -- Elemental Focus has 2 charges on TBC and Wrath
        self:RegisterAura("elemental_focus_1", 1, 16246, "echo_of_the_elements", "Left", 1, 255, 255, 255, true);
        self:RegisterAura("elemental_focus_2", 2, 16246, "echo_of_the_elements", "Left + Right (Flipped)", 1, 255, 255, 255, true);
    end
    
    if self.IsCata() then
        local lavaBurstCata = 51505;
        self:RegisterAura("lava_surge", 0, lavaBurstCata, "imp_empowerment", "Left + Right (Flipped)", 1, 255, 255, 255, true, {lavaBurstCata}, true);
        self:RegisterCounter("lava_surge");
        if (not RollingThunderHandler.initialized) then
            RollingThunderHandler:init();
        end
        for lightningShieldStacks=6,9 do
            local auraName = "fulmination_"..lightningShieldStacks;
            local scale = 0.5 + 0.1 * (lightningShieldStacks - 5); -- 60%, 70%, 80%
            local pulse = lightningShieldStacks == 9;
            self:RegisterAura(auraName, lightningShieldStacks, RollingThunderHandler.fakeSpellID, "fulmination", "Top", scale, 255, 255, 255, pulse, RollingThunderHandler.earthShockSpells);
        end
        -- Maelstrom Weapon
        local lightningBolt = 403;
        local chainLightning = 421;
        local healingSurge = 8004;
        local healingWave = 331;
        local chainHeal = 1064;
        local greaterHealingWave = 77472;
        local healingRain = 73920;
        local hex = 51514;
        local maelstromSpells = {
            GetSpellInfo(lightningBolt),
            GetSpellInfo(chainLightning),
            GetSpellInfo(healingSurge),
            GetSpellInfo(greaterHealingWave),
            GetSpellInfo(healingWave),
            GetSpellInfo(chainHeal),
            GetSpellInfo(healingRain),
            GetSpellInfo(hex),
        }
        self:RegisterAura("maelstrom_weapon_1", 1, 53817, "maelstrom_weapon_1", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_2", 2, 53817, "maelstrom_weapon_2", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_3", 3, 53817, "maelstrom_weapon_3", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_4", 4, 53817, "maelstrom_weapon_4", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_5", 5, 53817, "maelstrom_weapon", "Top", 1, 255, 255, 255, true, maelstromSpells);

        -- Tidal Waves
        local tidalSpells = {
            GetSpellInfo(greaterHealingWave),
            GetSpellInfo(healingWave),
            GetSpellInfo(healingSurge),
        }
        self:RegisterAura("tidal_waves_1", 1, 53390, "high_tide", "Left (CCW)", 0.8, 255, 255, 255, true, tidalSpells);
        self:RegisterAura("tidal_waves_2", 2, 53390, "high_tide", "Left (CCW)", 0.8, 255, 255, 255, true, tidalSpells);
        self:RegisterAura("tidal_waves_2", 2, 53390, "high_tide", "Right (CW)", 0.8, 255, 255, 255, true); -- no need to re-glow tidalSpells for right texture
    end


    if self.IsWrath() then
        -- Maelstrom Weapon
        local lightningBolt = 403;
        local chainLightning = 421;
        local lesserHealingWave = 8004;
        local healingWave = 331;
        local chainHeal = 1064;
        local hex = 51514;
        local maelstromSpells = {
            GetSpellInfo(lightningBolt),
            GetSpellInfo(chainLightning),
            GetSpellInfo(lesserHealingWave),
            GetSpellInfo(healingWave),
            GetSpellInfo(chainHeal),
            GetSpellInfo(hex),
        }
        self:RegisterAura("maelstrom_weapon_1", 1, 53817, "maelstrom_weapon_1", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_2", 2, 53817, "maelstrom_weapon_2", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_3", 3, 53817, "maelstrom_weapon_3", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_4", 4, 53817, "maelstrom_weapon_4", "Top", 1, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_5", 5, 53817, "maelstrom_weapon", "Top", 1, 255, 255, 255, true, maelstromSpells);

        -- Tidal Waves
        local tidalSpells = {
            GetSpellInfo(lesserHealingWave),
            GetSpellInfo(healingWave),
        }
        self:RegisterAura("tidal_waves_1", 1, 53390, "high_tide", "Left (CCW)", 0.8, 255, 255, 255, true, tidalSpells);
        self:RegisterAura("tidal_waves_2", 2, 53390, "high_tide", "Left (CCW)", 0.8, 255, 255, 255, true, tidalSpells);
        self:RegisterAura("tidal_waves_2", 2, 53390, "high_tide", "Right (CW)", 0.8, 255, 255, 255, true); -- no need to re-glow tidalSpells for right texture

        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_shaman", 60515); -- 60515 = Shaman buff
    end

    if self.IsEra() and not self.IsSoD() then
        -- On non-SoD Era, Elemental Focus is simply displayed Left and Right
        self:RegisterAura("elemental_focus", 0, 16246, "echo_of_the_elements", "Left + Right (Flipped)", 1, 255, 255, 255, true);
    end

    if self.IsSoD() then

        -- Initializing Rolling Thunder handler, only for Season of Discovery
        if (not RollingThunderHandler.initialized) then
            RollingThunderHandler:init();
        end

        local moltenBlastSoD = 425339;
        self:RegisterAura("molten_blast", 0, moltenBlastSoD, "impact", "Top", 0.8, 255, 255, 255, true, { moltenBlastSoD }, true);
        self:RegisterCounter("molten_blast");

        -- Maelstrom Weapon & Power Surge
        local maelstromSoDBuff = 408505;
        local lightningBolt = 403;
        local chainLightning = 421;
        local lesserHealingWave = 8004;
        local healingWave = 331;
        local chainHeal = 1064;
        local lavaBurstSoD = 408490;
        local powerSurgeSoDBuff = 415105;
        local maelstromSpells = {
            GetSpellInfo(lightningBolt),
            GetSpellInfo(chainLightning),
            GetSpellInfo(lesserHealingWave),
            GetSpellInfo(healingWave),
            GetSpellInfo(chainHeal),
            GetSpellInfo(lavaBurstSoD),
        }
        local powerSurgeSpells = {
            GetSpellInfo(chainLightning),
            GetSpellInfo(chainHeal),
            GetSpellInfo(lavaBurstSoD),
        }
        self:RegisterAura("maelstrom_weapon_sod_1", 1, maelstromSoDBuff, "maelstrom_weapon_1", "Top", 0.8, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_sod_2", 2, maelstromSoDBuff, "maelstrom_weapon_2", "Top", 0.8, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_sod_3", 3, maelstromSoDBuff, "maelstrom_weapon_3", "Top", 0.8, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_sod_4", 4, maelstromSoDBuff, "maelstrom_weapon_4", "Top", 0.8, 255, 255, 255, false);
        self:RegisterAura("maelstrom_weapon_sod_5", 5, maelstromSoDBuff, "maelstrom_weapon", "Top", 0.8, 255, 255, 255, true, maelstromSpells);

        -- If Power Surge is enabled but not Elemental Focus, display Power Surge Left and Right
        -- If Elemental Focus is enabled but not Power Surge, display Elemental Focus Left and Right
        -- If both are enabled, show only left part of Power Surge and right part of Elemental Focus
        -- PS. 'enabled' means the option is enabled and the talent/rune is equipped
        local elementalFocusBuff = 16246;
        local elementalFocusTalent = 16164;
        local _, _, efTalentTab, efTalentIndex = SAO:GetTalentByName(GetSpellInfo(elementalFocusTalent));
        local powerSurgeSoDRune = 48829;

        local powerSurgeRightTextureFunc = function()
            local hasElementalFocusOption = SpellActivationOverlayDB.classes["SHAMAN"]["alert"][elementalFocusBuff][0];
            local canProcElementalFocus = efTalentTab and efTalentIndex and select(5, GetTalentInfo(efTalentTab, efTalentIndex)) > 0;
            if hasElementalFocusOption and canProcElementalFocus then
                return;
            end
            return self.TexName["imp_empowerment"];
        end

        local elementalFocusLeftTextureFunc = function()
            local hasPowerSurgeOption = SpellActivationOverlayDB.classes["SHAMAN"]["alert"][powerSurgeSoDBuff][0];
            local canProcPowerSurge = C_Engraving and C_Engraving.IsRuneEquipped(powerSurgeSoDRune);
            if hasPowerSurgeOption and canProcPowerSurge then
                return;
            end
            return self.TexName["echo_of_the_elements"];
        end

        self:RegisterAura("power_surge_sod", 0, powerSurgeSoDBuff, "imp_empowerment", "Left", 1, 255, 255, 255, true, powerSurgeSpells);
        self:RegisterAura("power_surge_sod", 0, powerSurgeSoDBuff, powerSurgeRightTextureFunc, "Right (Flipped)", 1, 255, 255, 255, true, powerSurgeSpells);
        self:RegisterAura("elemental_focus", 0, elementalFocusBuff, elementalFocusLeftTextureFunc, "Left", 1, 255, 255, 255, true);
        self:RegisterAura("elemental_focus", 0, elementalFocusBuff, "echo_of_the_elements", "Right (Flipped)", 1, 255, 255, 255, true);
        for lightningShieldStacks=7,9 do
            local auraName = "rolling_thunder_"..lightningShieldStacks;
            local scale = 0.5 + 0.1 * (lightningShieldStacks - 6); -- 60%, 70%, 80%
            local pulse = lightningShieldStacks == 9;
            self:RegisterAura(auraName, lightningShieldStacks, RollingThunderHandler.fakeSpellID, "fulmination", "Top", scale, 255, 255, 255, pulse, RollingThunderHandler.earthShockSpells);
        end
        -- Tidal Waves SoD
        local tidalSpells = {
            GetSpellInfo(lesserHealingWave),
            GetSpellInfo(healingWave),
        }
        self:RegisterAura("tidal_waves_1_sod", 1, 432041, "high_tide", "Left (CCW)", 0.8, 255, 255, 255, true, tidalSpells);
        self:RegisterAura("tidal_waves_2_sod", 2, 432041, "high_tide", "Left (CCW)", 0.8, 255, 255, 255, true, tidalSpells);
        self:RegisterAura("tidal_waves_2_sod", 2, 432041, "high_tide", "Right (CW)", 0.8, 255, 255, 255, true); -- no need to re-glow tidalSpells for right texture
    end
end

local function loadOptions(self)
    local lightningBolt = 403;
    local chainLightning = 421;
    local lesserHealingWave = 8004;
    local healingWave = 331;
    local chainHeal = 1064;
    local hex = 51514;

    local maelstromWeaponBuff = 53817;
    local maelstromWeaponTalent = 51528;

    local elementalFocusBuff = 16246;
    local elementalFocusTalent = 16164;

    local tidalWavesBuff = 53390;
    local tidalWavesTalent = 51562;

    -- Season of Discovery
    local moltenBlastSoD = 425339;
    local maelstromSoDBuff = 408505;
    local maelstromSoD = 408498;
    local lavaBurstSoD = 408490;
    local powerSurgeSoDBuff = 415105;
    local powerSurgeSoD = 415100;
    local lightningShield = 324;
    local rollingThunderSoD = 432056;
    local earthShock = 8042;
    local tidalWavesSoDBuff = 432041;
    local tidalWavesSoDTalent = 432233;

    --Cataclysm
    local lavaBurstCata = 51505;
    local lavaSurgeTalentCata = 77756;
    local fulminationTalentCata = 88766;
    local greaterHealingWave = 77472;
    local healingSurge = 8004;
    local healingRain = 73920;

    local oneToFourStacks = self:NbStacks(1, 4);
    local fiveStacks = self:NbStacks(5);
    local sevenToNineStacks = self:NbStacks(7, 9);
    local sixToNineStacks = self:NbStacks(6, 9);

    if self.IsEra() then
        -- Elemental Focus has 1 charge on Classic Era
        self:AddOverlayOption(elementalFocusTalent, elementalFocusBuff);
    elseif self.IsWrath() then
        -- Elemental Focus has 2 charges on TBC and Wrath
        self:AddOverlayOption(elementalFocusTalent, elementalFocusBuff, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
    end

    if self.IsCata() then
        self:AddOverlayOption(lavaBurstCata, lavaBurstCata);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, 6, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, 7, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, 8, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, 9, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(maelstromWeaponTalent, maelstromWeaponBuff, 0, oneToFourStacks, nil, 4); -- setup any stacks, test with 4 stacks
        self:AddOverlayOption(maelstromWeaponTalent, maelstromWeaponBuff, 5); -- setup 5 stacks
        self:AddOverlayOption(tidalWavesTalent, tidalWavesBuff, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
    end 
    if self.IsWrath() then
        self:AddOverlayOption(maelstromWeaponTalent, maelstromWeaponBuff, 0, oneToFourStacks, nil, 4); -- setup any stacks, test with 4 stacks
        self:AddOverlayOption(maelstromWeaponTalent, maelstromWeaponBuff, 5); -- setup 5 stacks
        self:AddOverlayOption(tidalWavesTalent, tidalWavesBuff, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddSoulPreserverOverlayOption(60515); -- 60515 = Shaman buff
    elseif self.IsSoD() then
        self:AddOverlayOption(powerSurgeSoD, powerSurgeSoDBuff);
        self:AddOverlayOption(moltenBlastSoD, moltenBlastSoD);
        self:AddOverlayOption(maelstromSoD, maelstromSoDBuff, 0, oneToFourStacks, nil, 4); -- setup any stacks, test with 4 stacks
        self:AddOverlayOption(maelstromSoD, maelstromSoDBuff, 5); -- setup 5 stacks
        self:AddOverlayOption(rollingThunderSoD, lightningShield, 7, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(rollingThunderSoD, lightningShield, 8, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(rollingThunderSoD, lightningShield, 9, nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(tidalWavesSoDTalent, tidalWavesSoDBuff, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
    end

    if self.IsCata() then
        self:AddGlowingOption(lavaSurgeTalentCata, lavaBurstCata, lavaBurstCata);
        self:AddGlowingOption(fulminationTalentCata, lightningShield, earthShock, sixToNineStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, lightningBolt, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, chainLightning, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, healingSurge, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, greaterHealingWave, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, healingWave, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, chainHeal, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, healingRain, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, hex, fiveStacks);
        self:AddGlowingOption(tidalWavesTalent, tidalWavesBuff, greaterHealingWave);
        self:AddGlowingOption(tidalWavesTalent, tidalWavesBuff, healingWave);
        self:AddGlowingOption(tidalWavesTalent, tidalWavesBuff, healingSurge);
    end 
    if self.IsWrath() then
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, lightningBolt, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, chainLightning, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, lesserHealingWave, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, healingWave, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, chainHeal, fiveStacks);
        self:AddGlowingOption(maelstromWeaponTalent, maelstromWeaponBuff, hex, fiveStacks);
        self:AddGlowingOption(tidalWavesTalent, tidalWavesBuff, lesserHealingWave);
        self:AddGlowingOption(tidalWavesTalent, tidalWavesBuff, healingWave);
    elseif self.IsSoD() then
        self:AddGlowingOption(nil, moltenBlastSoD, moltenBlastSoD);
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, chainLightning);
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, chainHeal);
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, lavaBurstSoD);
        self:AddGlowingOption(maelstromSoD, maelstromSoDBuff, lightningBolt, fiveStacks);
        self:AddGlowingOption(maelstromSoD, maelstromSoDBuff, chainLightning, fiveStacks);
        self:AddGlowingOption(maelstromSoD, maelstromSoDBuff, lesserHealingWave, fiveStacks);
        self:AddGlowingOption(maelstromSoD, maelstromSoDBuff, healingWave, fiveStacks);
        self:AddGlowingOption(maelstromSoD, maelstromSoDBuff, chainHeal, fiveStacks);
        self:AddGlowingOption(maelstromSoD, maelstromSoDBuff, lavaBurstSoD, fiveStacks);
        self:AddGlowingOption(rollingThunderSoD, lightningShield, earthShock, sevenToNineStacks);
        self:AddGlowingOption(tidalWavesSoDTalent, tidalWavesSoDBuff, lesserHealingWave);
        self:AddGlowingOption(tidalWavesSoDTalent, tidalWavesSoDBuff, healingWave);
    end
end

SAO.Class["SHAMAN"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["SPELLS_CHANGED"] = checkRollingThunderRuneAndLightningSieldStacks,
    ["PLAYER_REGEN_ENABLED"] = deactivateRollingThunderGlow,
    ["PLAYER_REGEN_DISABLED"] = activateRollingThunderGlow,
    ["PLAYER_LOGIN"] = deactivateRollingThunderGlow,
}
