local AddonName, SAO = ...


-- Check if Maelstrom Weapon effect should pulse at 5 stacks
-- This question only applies to 5 stacks, because the answer is obvious for other stacks
-- At 5 stacks, we want to pulse if the shaman is capped at 5 stacks, and not pulse if capped at 10
local function mustPulseMSW5()
    -- Count the number of items currently equipped from Enhancement's T4 set (Season of Discovery)
    local t4Items = { 240131, 240135, 240128, 240136, 240134, 240129, 240137, 240130 }
    local nbT4Items = SAO:GetNbItemsEquipped(t4Items);

    if nbT4Items < 6 then
        -- If the shaman does not have the T4 6pc, s/he is capped at 5 stacks
        -- In which case, the Maelstrom Weapon should pulse at 5 stacks
        return true;
    else
        -- If the shaman has at least 6 pieces of Enhancement's T4, Maelstrom Weapon is capped at 10 stacks
        -- In this case, Maelstrom Weapon should *not* pulse at 5 stacks
        return false;
    end
end

local function registerClass(self)
    local hash0Stacks = self:HashNameFromStacks(0);
    local hash2Stacks = self:HashNameFromStacks(2);
    local hash4Stacks = self:HashNameFromStacks(4);
    local hash6Stacks = self:HashNameFromStacks(6);
    local hash9Stacks = self:HashNameFromStacks(9);

    -- Elemental Focus has 2 charges on TBC, Wrath and Cataclysm
    -- TBC/Wrath use echo_of_the_elements texture, with scale of 100%
    -- Cataclysm uses cleaner texture, with scale of 150%
    self:CreateEffect(
        "elemental_focus",
        SAO.TBC_AND_ONWARD,
        16246, -- Clearcasting (buff)
        "aura",
        {
            talent = 16164, -- Elemental Focus (talent)
            overlays = {
                [SAO.TBC+SAO.WRATH] = {
                    { stacks = 1, texture = "echo_of_the_elements", position = "Left", scale = 1, pulse = false, option = false },
                    { stacks = 2, texture = "echo_of_the_elements", position = "Left + Right (Flipped)", scale = 1, pulse = false, option = { setupHash = hash0Stacks, testHash = hash2Stacks } },
                },
                [SAO.CATA_AND_ONWARD] = {
                    { stacks = 1, texture = "genericarc_05", position = "Left", scale = 1.5, pulse = false, option = false },
                    { stacks = 2, texture = "genericarc_05", position = "Left + Right (Flipped)", scale = 1.5, pulse = false, option = { setupHash = hash0Stacks, testHash = hash2Stacks } },
                }
            },
        }
    );

    -- Lava Surge (Cataclysm)
    local lavaBurstCata = 51505;
    self:CreateEffect(
        "lava_surge",
        SAO.CATA,
        lavaBurstCata,
        "counter",
        {
            talent = 77756, -- Lava Surge (talent)
            requireTalent = true,
            combatOnly = true,
            overlay = { texture = "imp_empowerment", position = "Left + Right (Flipped)" },
        }
    );

    -- Lava Surge (Mists of Pandaria)
    local lavaSurgeMop = 77762;
    self:CreateEffect(
        "lava_surge",
        SAO.MOP,
        lavaSurgeMop,
        "aura",
        {
            talent = 77756, -- Lava Surge (passive)
            combatOnly = true,
            overlay = { texture = "imp_empowerment", position = "Left + Right (Flipped)" },
        }
    );

    -- Tidal Waves
    local greaterHealingWave = 77472;
    local healingSurge = 8004;
    local healingWave = 331;
    local lesserHealingWave = 8004; -- Renamed Healing Surge in Cataclysm; keep the former name to make the effect easier to design
    local tidalWavesBuff = self.IsSoD() and 432041 or 53390;
    local tidalWavesTalent = self.IsSoD() and 432233 or 51564;
    self:CreateEffect(
        "tidal_waves",
        SAO.SOD + SAO.WRATH_AND_ONWARD,
        tidalWavesBuff,
        "aura",
        {
            talent = tidalWavesTalent,
            overlays = {
                { stacks = 1, texture = "high_tide", position = "Left (CCW)", scale = 0.8, option = false },
                { stacks = 2, texture = "high_tide", position = "Left (CCW)", scale = 0.8, option = false },
                { stacks = 2, texture = "high_tide", position = "Right (CW)", scale = 0.8, option = { setupHash = hash0Stacks, testHash = hash2Stacks } },
            },
            buttons = {
                [SAO.SOD+SAO.WRATH] = { lesserHealingWave, healingWave },
                [SAO.CATA_AND_ONWARD] = { greaterHealingWave, healingWave, healingSurge },
            },
        }
    );

    -- Maelstrom Weapon
    local lightningBolt = 403;
    local chainLightning = 421;
    local chainHeal = 1064;
    local healingRain = 73920;
    local hex = 51514;
    local lavaBurstSoD = 408490;
    local elementalBlast = 117014;
    local maelstromWeaponBuff = self.IsSoD() and 408505 or 53817;
    local maelstromWeaponTalent = self.IsSoD() and 408498 or 51530;
    local maelstromWeaponScale = self.IsSoD() and 0.8 or 1;
    self:CreateEffect(
        "maelstrom_weapon",
        SAO.SOD + SAO.WRATH_AND_ONWARD,
        maelstromWeaponBuff,
        "aura",
        {
            aka = {
                [SAO.MOP] = 60349, -- Maelstrom
            },
            talent = maelstromWeaponTalent,
            overlays = {
                { stacks = 1, texture = "maelstrom_weapon_1", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                { stacks = 2, texture = "maelstrom_weapon_2", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                { stacks = 3, texture = "maelstrom_weapon_3", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                { stacks = 4, texture = "maelstrom_weapon_4", position = "Top", scale = maelstromWeaponScale, pulse = false, option = { setupHash = hash0Stacks, testHash = hash4Stacks, subText = self:NbStacks(1,4) } },
                [SAO.WRATH_AND_ONWARD] = {
                    { stacks = 5, texture = "maelstrom_weapon"  , position = "Top", scale = maelstromWeaponScale, pulse = true , option = true },
                },
                [SAO.SOD] = {
                    { stacks = 5, texture = "maelstrom_weapon"  , position = "Top", scale = maelstromWeaponScale, pulse = mustPulseMSW5, option = true },
                    { stacks = 6, texture = "maelstrom_weapon_6", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                    { stacks = 7, texture = "maelstrom_weapon_7", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                    { stacks = 8, texture = "maelstrom_weapon_8", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                    { stacks = 9, texture = "maelstrom_weapon_9", position = "Top", scale = maelstromWeaponScale, pulse = false, option = { setupHash = hash6Stacks, testHash = hash9Stacks, subText = self:NbStacks(6,9) } },
                    { stacks = 10, texture = "maelstrom_weapon_10" , position = "Top", scale = maelstromWeaponScale, pulse = true , option = true },
                },
            },
            buttons = {
                default = { stacks = 5 },
                [SAO.SOD]   = { lightningBolt, chainLightning, lesserHealingWave,                                                               lavaBurstSoD },
                [SAO.WRATH] = { lightningBolt, chainLightning, lesserHealingWave,                     healingWave, chainHeal,              hex },
                [SAO.CATA]  = { lightningBolt, chainLightning, healingSurge,      greaterHealingWave, healingWave, chainHeal, healingRain, hex },
                [SAO.MOP]   = { lightningBolt, chainLightning, healingSurge,      greaterHealingWave, healingWave, chainHeal, healingRain, hex,               elementalBlast },
            },
            handlers = {
                -- Force refresh on a regular basis, because the game client does not send the correct SPELL_AURA_REFRESH events
                [SAO.SOD] = { onRepeat = function(bucket) bucket:refresh(); end },
            },
        }
    );

    -- Set up variables for Fulmination (Cataclysm and onward) and Rolling Thunder (Season of Discovery)
    local earthShock = 8042;
    local lithtningShield = self.IsSoD() and {324, 325, 905, 945, 8134, 10431, 10432} or 324;  -- Lightning Shield (buff, all 7 variants for Season of Discovery, one variant otherwise)
    
    -- Fulmination (Cataclysm and onward)
    SAO:CreateEffect(
        "fulmination",
        SAO.CATA_AND_ONWARD,
        lithtningShield,
        "aura",
        {
            aka = 95774, -- Fulmination! (buff)
            talent = 88767, -- Fulmination (passive)
            combatOnly = true,
            overlays = {
                default = { texture = "fulmination", position = "Top" },
                [SAO.CATA] = {
                    { scale=0.5, stacks = 6, pulse = false, },
                    { scale=0.6, stacks = 7, pulse = false, },
                    { scale=0.7, stacks = 8, pulse = false, },
                    { scale=0.8, stacks = 9, pulse = true,  },
                },
                [SAO.MOP] = {
                    { scale=0.8, stacks = 7, },
                },
            },
            buttons = {
                default = { spellID = earthShock },
                [SAO.CATA] = { stacks = 9 },
                [SAO.MOP] =  { stacks = 7 }, 
            },
        }
    );

    -- Rolling Thunder (Season of Discovery)
    SAO:CreateLinkedEffects(
        "rolling_thunder",
        SAO.SOD,
        lithtningShield,
        "aura",
        {
            talent =  432056, -- Rolling Thunder rune
            combatOnly = true,
            overlays = {
                default = { texture = "fulmination", position = "Top" },
                { scale=0.6, stacks = 7, pulse = false, },
                { scale=0.7, stacks = 8, pulse = false, },
                { scale=0.8, stacks = 9, pulse = true,  },
            },
            buttons = {{ spellID = earthShock, stacks = 9 },},
            handlers = {{
                onAboutToApplyHash = function(hashCalculator)
                    local RollingThunderEquipped = (C_Engraving and SAO:IsSpellLearned(432056)); -- Checking if Rolling Thunder rune is equipped
                    if not RollingThunderEquipped then
                        hashCalculator:setAuraStacks(0);
                    end
                end,
            },},
        }
    );

    if self.IsWrath() then
        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_shaman", 60515); -- 60515 = Shaman buff
    end

    if self.IsEra() and not self.IsSoD() then
        -- On non-SoD Era, Elemental Focus is simply displayed Left and Right
        self:RegisterAura("elemental_focus", 0, 16246, "echo_of_the_elements", "Left + Right (Flipped)", 1, 255, 255, 255, false);
    end

    if self.IsSoD() then

        local moltenBlastSoD = 425339;
        self:CreateEffect(
            "molten_blast",
            SAO.SOD,
            moltenBlastSoD,
            "counter",
            {
                combatOnly = true,
                overlay = { texture = "impact", position = "Top", scale = 0.8 },
            }
        );

        -- Power Surge
        local powerSurgeSoDBuff = 415105;
        local powerSurgeSoDHealBuff = 468526;
        local powerSurgeSpells = {
            (GetSpellInfo(chainLightning)),
            (GetSpellInfo(lavaBurstSoD)),
        }

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
            local canProcElementalFocus = efTalentTab and efTalentIndex and self:GetNbTalentPoints(efTalentTab, efTalentIndex) > 0;
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
        self:RegisterAura("elemental_focus", 0, elementalFocusBuff, elementalFocusLeftTextureFunc, "Left", 1, 255, 255, 255, false);
        self:RegisterAura("elemental_focus", 0, elementalFocusBuff, "echo_of_the_elements", "Right (Flipped)", 1, 255, 255, 255, false);

        SAO:CreateEffect(
            "power_surge_sod_heal",
            SAO.SOD,
            powerSurgeSoDHealBuff,
            "aura",
            {
                talent = powerSurgeSoDHealBuff,
                button = { spellID = chainHeal, option = { talentSubText = HEALER } },
            }
        );
    end
end

local function loadOptions(self)
    local chainLightning = 421;

    local elementalFocusBuff = 16246;
    local elementalFocusTalent = 16164;

    -- Season of Discovery
    local lavaBurstSoD = 408490;
    local powerSurgeSoDBuff = 415105;
    local powerSurgeSoD = 415100;

    if self.IsEra() then
        -- Elemental Focus has 1 charge on Classic Era
        self:AddOverlayOption(elementalFocusTalent, elementalFocusBuff);
    end

    if self.IsWrath() then
        self:AddSoulPreserverOverlayOption(60515); -- 60515 = Shaman buff
    elseif self.IsSoD() then
        self:AddOverlayOption(powerSurgeSoD, powerSurgeSoDBuff, nil, DAMAGER);
    end

    if self.IsSoD() then
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, chainLightning, DAMAGER);
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, lavaBurstSoD, DAMAGER);
    end
end

SAO.Class["SHAMAN"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
