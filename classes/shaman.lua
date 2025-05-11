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
    glowtimer = nil,

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
        local stackThreshold = SAO:IsCata() and 6 or 7; -- 6 or more for Cata, 7 or more for SoD
        if (self.lightningShieldSpellIDs[spellID]) then
            if (event == "SPELL_AURA_APPLIED_DOSE") or (event == "SPELL_AURA_REMOVED_DOSE") then
            -- Deactivating old overlays and activating new one when Lightning Shield stack is gained or lost
                self:deactivate();
                if stacks >= stackThreshold then
                    self:activate(stacks);
                end
            end
            if (event == "SPELL_AURA_REMOVED") then
                self:deactivate();
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
            local scale = 0.5 + 0.1 * (lightningShieldStacks - 6); -- 50%, 60%, 70%, 80% for Cataclysm or 60%, 70%, 80% for Season of Discovery
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

    local RollingThunderEquipped = (C_Engraving and SAO:IsSpellLearned(432056));
    if not (RollingThunderEquipped or SAO:IsCata()) then
        RollingThunderHandler:deactivate();
    else
        -- C_UnitAuras is currently available for Classic Era and Cataclysm only
        -- Fortunately, RollingThunderHandler is used only on Season of Discovery and Cataclysm
        local aura = C_UnitAuras.GetAuraDataBySpellName("player", GetSpellInfo(324));
        local stackThreshold = SAO:IsCata() and 6 or 7; -- 6 or more for Cata, 7 or more for SoD
        if aura and aura.applications >= stackThreshold and not SAO:GetBucketBySpellID(RollingThunderHandler.fakeSpellID):isDisplayed() then
            RollingThunderHandler:activate(aura.applications);
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
            RollingThunderHandler.glowtimer = nil;
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

-- Check if Maelstrom Weapon effect should pulse at 5 stacks
-- This question only applies to 5 stacks, because the answer is obvious for other stacks
-- At 5 stacks, we want to pulse if the shaman is capped at 5 stacks, and not pulse if capped at 10
local function mustPulseMSW5(self, ...)
    -- Count the number of items currently equipped from Enhancement's T4 set (Season of Discovery)
    local t4Items = { 240131, 240135, 240128, 240136, 240134, 240129, 240137, 240130 }
    local nbT4Items = 0;
    for _, item in ipairs(t4Items) do
        if C_Item.IsEquippedItem(item) then
            nbT4Items = nbT4Items + 1;
        end
    end

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
        SAO.TBC + SAO.WRATH + SAO.CATA,
        16246, -- Clearcasting (buff)
        "aura",
        {
            talent = 16164, -- Elemental Focus (talent)
            overlays = {
                [SAO.TBC+SAO.WRATH] = {
                    { stacks = 1, texture = "echo_of_the_elements", position = "Left", scale = 1, pulse = false, option = false },
                    { stacks = 2, texture = "echo_of_the_elements", position = "Left + Right (Flipped)", scale = 1, pulse = false, option = { setupHash = hash0Stacks, testHash = hash2Stacks } },
                },
                [SAO.CATA] = {
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

    -- Tidal Waves
    local greaterHealingWave = 77472;
    local healingSurge = 8004;
    local healingWave = 331;
    local lesserHealingWave = 8004; -- Renamed Healing Surge in Cataclysm; keep the former name to make the effect easier to design
    local tidalWavesBuff = self.IsSoD() and 432041 or 53390;
    local tidalWavesTalent = self.IsSoD() and 432233 or 51562;
    self:CreateEffect(
        "tidal_waves",
        SAO.SOD + SAO.WRATH + SAO.CATA,
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
                [SAO.CATA] = { greaterHealingWave, healingWave, healingSurge },
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
    local maelstromWeaponBuff = self.IsSoD() and 408505 or 53817;
    local maelstromWeaponTalent = self.IsSoD() and 408498 or 51528;
    local maelstromWeaponScale = self.IsSoD() and 0.8 or 1;
    self:CreateEffect(
        "maelstrom_weapon",
        SAO.SOD + SAO.WRATH + SAO.CATA,
        maelstromWeaponBuff,
        "aura",
        {
            talent = maelstromWeaponTalent,
            overlays = {
                { stacks = 1, texture = "maelstrom_weapon_1", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                { stacks = 2, texture = "maelstrom_weapon_2", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                { stacks = 3, texture = "maelstrom_weapon_3", position = "Top", scale = maelstromWeaponScale, pulse = false, option = false },
                { stacks = 4, texture = "maelstrom_weapon_4", position = "Top", scale = maelstromWeaponScale, pulse = false, option = { setupHash = hash0Stacks, testHash = hash4Stacks, subText = self:NbStacks(1,4) } },
                [SAO.WRATH+SAO.CATA] = {
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
                [SAO.SOD] =   { lightningBolt, chainLightning, lesserHealingWave,                                                               lavaBurstSoD },
                [SAO.WRATH] = { lightningBolt, chainLightning, lesserHealingWave,                     healingWave, chainHeal,              hex },
                [SAO.CATA] =  { lightningBolt, chainLightning, healingSurge,      greaterHealingWave, healingWave, chainHeal, healingRain, hex },
            },
            handlers = {
                -- Force refresh on a regular basis, because the game client does not send the correct SPELL_AURA_REFRESH events
                [SAO.SOD] = { onRepeat = function(bucket) bucket:refresh(); end },
            },
        }
    );

    if self.IsCata() then
        -- Initializing Rolling Thunder handler for Fulmination in Cataclysm
        if (not RollingThunderHandler.initialized) then
            RollingThunderHandler:init();
        end
        for lightningShieldStacks=6,9 do
            local auraName = "fulmination_"..lightningShieldStacks;
            local scale = 0.5 + 0.1 * (lightningShieldStacks - 6); -- 50%, 60%, 70%, 80% for Cataclysm
            local pulse = lightningShieldStacks == 9;
            self:RegisterAura(auraName, lightningShieldStacks, RollingThunderHandler.fakeSpellID, "fulmination", "Top", scale, 255, 255, 255, pulse, RollingThunderHandler.earthShockSpells);
        end
    end

    if self.IsWrath() then
        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_shaman", 60515); -- 60515 = Shaman buff
    end

    if self.IsEra() and not self.IsSoD() then
        -- On non-SoD Era, Elemental Focus is simply displayed Left and Right
        self:RegisterAura("elemental_focus", 0, 16246, "echo_of_the_elements", "Left + Right (Flipped)", 1, 255, 255, 255, false);
    end

    if self.IsSoD() then

        -- Initializing Rolling Thunder handler for Season of Discovery
        if (not RollingThunderHandler.initialized) then
            RollingThunderHandler:init();
        end

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
        self:RegisterAura("elemental_focus", 0, elementalFocusBuff, elementalFocusLeftTextureFunc, "Left", 1, 255, 255, 255, false);
        self:RegisterAura("elemental_focus", 0, elementalFocusBuff, "echo_of_the_elements", "Right (Flipped)", 1, 255, 255, 255, false);
        for lightningShieldStacks=7,9 do
            local auraName = "rolling_thunder_"..lightningShieldStacks;
            local scale = 0.5 + 0.1 * (lightningShieldStacks - 6); -- 60%, 70%, 80% for Season of Discovery
            local pulse = lightningShieldStacks == 9;
            self:RegisterAura(auraName, lightningShieldStacks, RollingThunderHandler.fakeSpellID, "fulmination", "Top", scale, 255, 255, 255, pulse, RollingThunderHandler.earthShockSpells);
        end
        SAO:CreateEffect(
            "power_surge_sod_heal",
            SAO.SOD,
            powerSurgeSoDHealBuff,
            "aura",
            {
                talent = powerSurgeSoDHealBuff,
                buttons = { chainHeal },
            }
        );
    end
end

local function loadOptions(self)
    local chainLightning = 421;
    local chainHeal = 1064;

    local elementalFocusBuff = 16246;
    local elementalFocusTalent = 16164;

    -- Season of Discovery
    local lavaBurstSoD = 408490;
    local powerSurgeSoDBuff = 415105;
    local powerSurgeSoD = 415100;
    local lightningShield = 324;
    local rollingThunderSoD = 432056;
    local earthShock = 8042;

    --Cataclysm
    local fulminationTalentCata = 88766;

    local sevenToNineStacks = self:NbStacks(7, 9);
    local sixToNineStacks = self:NbStacks(6, 9);

    if self.IsEra() then
        -- Elemental Focus has 1 charge on Classic Era
        self:AddOverlayOption(elementalFocusTalent, elementalFocusBuff);
    end

    if self.IsCata() then
        self:AddOverlayOption(fulminationTalentCata, lightningShield, self:HashNameFromStacks(6), nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, self:HashNameFromStacks(7), nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, self:HashNameFromStacks(8), nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(fulminationTalentCata, lightningShield, self:HashNameFromStacks(9), nil, nil, nil, RollingThunderHandler.fakeSpellID);
    end
    if self.IsWrath() then
        self:AddSoulPreserverOverlayOption(60515); -- 60515 = Shaman buff
    elseif self.IsSoD() then
        self:AddOverlayOption(powerSurgeSoD, powerSurgeSoDBuff);
        self:AddOverlayOption(rollingThunderSoD, lightningShield, self:HashNameFromStacks(7), nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(rollingThunderSoD, lightningShield, self:HashNameFromStacks(8), nil, nil, nil, RollingThunderHandler.fakeSpellID);
        self:AddOverlayOption(rollingThunderSoD, lightningShield, self:HashNameFromStacks(9), nil, nil, nil, RollingThunderHandler.fakeSpellID);
    end

    if self.IsCata() then
        self:AddGlowingOption(fulminationTalentCata, lightningShield, earthShock, sixToNineStacks);
    elseif self.IsSoD() then
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, chainLightning);
        self:AddGlowingOption(powerSurgeSoD, powerSurgeSoDBuff, lavaBurstSoD);
        self:AddGlowingOption(rollingThunderSoD, lightningShield, earthShock, sevenToNineStacks);
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
