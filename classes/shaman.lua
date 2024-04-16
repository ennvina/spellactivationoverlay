local AddonName, SAO = ...

local function registerClass(self)

    if self.IsWrath() or self.IsTBC() then
        -- Elemental Focus has 2 charges on TBC and Wrath
        self:RegisterAura("elemental_focus_1", 1, 16246, "echo_of_the_elements", "Left", 1, 255, 255, 255, true);
        self:RegisterAura("elemental_focus_2", 2, 16246, "echo_of_the_elements", "Left + Right (Flipped)", 1, 255, 255, 255, true);
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

    local oneToFourStacks = string.format(CALENDAR_TOOLTIP_DATE_RANGE, "1", string.format(STACKS, 4));
    local fiveStacks = string.format(STACKS, 5);

    if self.IsEra() then
        -- Elemental Focus has 1 charge on Classic Era
        self:AddOverlayOption(elementalFocusTalent, elementalFocusBuff);
    else
        -- Elemental Focus has 2 charges on TBC and Wrath
        self:AddOverlayOption(elementalFocusTalent, elementalFocusBuff, 0, nil, nil, 2); -- setup any stacks, test with 2 stacks
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
    end
end

SAO.Class["SHAMAN"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
