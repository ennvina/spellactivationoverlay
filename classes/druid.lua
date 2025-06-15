local AddonName, SAO = ...

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetShapeshiftForm = GetShapeshiftForm
local GetSpellInfo = GetSpellInfo
local UnitGUID = UnitGUID

local omenSpellID = 16870;
local omenSpellIDFeral = 135700;
local lunarSpellID = SAO.IsSoD() and 408255 or 48518;
local solarSpellID = SAO.IsSoD() and 408250 or 48517;

local feralCache = false;
local clarityCache = false;
local lunarCache = false;
local solarCache = false;

local leftTexture = '';
local rightTexture = '';

local glowingWrath = false;
local glowingStarfire = false;
--local glowingStarsurge = false;

-- Assign fake spell IDs for left and right textures, and make sure they are different
-- If we used the 'real' spell IDs instead of fake IDs, we would see weird transitions
-- If spell IDs were identical, hiding the left or right SAO could also hide the other
-- (the latter is a limitation, some would say a feature, of Blizzard's original code)
local leftFakeSpellID  = 0x0D00001D;
local rightFakeSpellID = 0x0D00002D;

local cyclone = 33786;
local entanglingRoots = 339;
local healingTouch = 5185;
local hibernate = 2637;
local maul = 6807;
local moonfire = 8921;
local nourish = SAO.IsSoD() and 408247 or 50464;
local rebirth = 20484;
local regrowth = 8936;
local starfire = 2912;
local starsurge = 78674;
local wrath = 5176;

local omenOfClarityTalent = 16864;
-- local eclipseTalent = 48516;

local function useShootingStars()
    SAO:CreateEffect(
        "shooting_stars",
        SAO.CATA_AND_ONWARD,
        93400, -- Shooting Stars (buff)
        "aura",
        {
            talent = {
                [SAO.CATA] = 93398, -- Shooting Stars (talent)
                [SAO.MOP]  = 93399, -- Shooting Stars (passive)
            },
            overlay = { texture = "shooting_stars", position = "Top" },
            buttons = {
                [SAO.CATA] = starsurge,
                -- [SAO.MOP_AND_ONWARD] = starsurge, -- Button already glowing natively
            },
        }
    );
end

local function useEclipse()
    SAO:CreateEffect(
        "eclipse_lunar",
        SAO.MOP,
        lunarSpellID,
        "aura",
        {
            aka = 93431, -- Eclipse Visual (Lunar)
            overlay = { texture = "eclipse_moon", position = "Left" },
            -- buttons = { moonfire, starfire }, -- Buttons already glowing natively
        }
    );

    SAO:CreateEffect(
        "eclipse_solar",
        SAO.MOP,
        solarSpellID,
        "aura",
        {
            aka = 93430, -- Eclipse Visual (Solar)
            overlay = { texture = "eclipse_sun", position = "Right (Flipped)" },
            -- buttons = { wrath }, -- Button already glowing natively
        }
    );
end

local function useElunesWrathOfElune(name, spellID)
    SAO:CreateEffect(
        name,
        SAO.WRATH,
        spellID,
        "aura",
        {
            overlay = { texture = "shooting_stars", position = "Top" },
            button = starfire,
        }
    );
end

local function useOmenOfClarityForSpec(specIndex, suffix, spellID, texture, scale, level)
    SAO:CreateEffect(
        "omen_of_clarity_"..suffix,
        SAO.MOP,
        spellID,
        "aura",
        {
            talent = omenOfClarityTalent,
            overlay = { texture = texture, position = "Left + Right (Flipped)", level = level, scale = scale, option = { subText = SAO:GetSpecNameFunction(specIndex) } },
        }
    );
end

local function useOmenOfClarity()
    -- Feral Omen of Clarity is slightly smaller to avoid conflict with Dream of Cenarius, and higher level to make it more visible
    useOmenOfClarityForSpec(2, "feral", omenSpellIDFeral, "feral_omenofclarity", 0.9, 4);
    useOmenOfClarityForSpec(4, "resto", omenSpellID, "natures_grace", nil, nil);
end

local function useNaturesGrace()
    SAO:CreateEffect(
        "natures_grace",
        SAO.ERA + SAO.TBC + SAO.WRATH,
        16886, -- Nature's Grace (buff)
        "aura",
        {
            talent = (SAO.IsEra() or SAO.IsTBC()) and 16880 or 61346, -- Nature's Grace (Era and TBC talent) or Nature's Grace (Wrath talent)
            overlay = { texture = "serendipity", position = "Top", scale = 0.7 },
        }
    );
end

local function useFuryOfStormrage()
    local buff = SAO.IsSoD() and 414800 or 81093; -- Fury of Stormrage (buff)
    local talent = SAO.IsSoD() and 414799 or 17104; -- Fury of Stormrage (rune) or Fury of Stormrage (talent)
    SAO:CreateEffect(
        "fury_of_stormrage",
        SAO.SOD + SAO.CATA,
        buff,
        "aura",
        {
            talent = talent,
            overlay = { texture = "fury_of_stormrage", position = "Top" },
            buttons = {
                [SAO.SOD] = { healingTouch, nourish },
                [SAO.CATA] = starfire,
            },
        }
    );
end

local function useSwiftbloom()
    SAO:CreateEffect(
        "swiftbloom",
        SAO.SOD,
        1226035,  -- Swiftbloom (buff)
        "aura",
        {
            overlay = { texture = "fury_of_stormrage", position = "Top", scale = 0.7, color = { 255, 60, 255 } },
            buttons = {
                nourish,
                healingTouch,
                regrowth,
            },
        }
    );
end

local function usePredatoryStrikes()
    SAO:CreateEffect(
        "predatory_strikes",
        SAO.WRATH + SAO.CATA + SAO.MOP,
        69369, -- Predator's Swiftness / Predatory Swiftness (buff)
        "aura",
        {
            talent = {
                [SAO.WRATH + SAO.CATA] = 16972, -- Predatory Strikes (talent)
                [SAO.MOP] = 16974, -- Predatory Swiftness (passive)
            },
            overlay = { texture = "predatory_swiftness", position = "Top" },
            buttons = {
                [SAO.WRATH + SAO.CATA] = {
                    regrowth,
                    healingTouch,
                    nourish,
                    rebirth,
                    wrath,
                    entanglingRoots,
                    cyclone,
                    hibernate,
                },
                [SAO.MOP] = {
                    healingTouch,
                    rebirth,
                    entanglingRoots,
                    hibernate,
                },
            },
        }
    );
end

local function useToothAndClaw()
    SAO:CreateEffect(
        "tooth_and_claw",
        SAO.MOP,
        135286, -- Tooth and Claw (buff)
        "aura",
        {
            talent = 135288, -- Tooth and Claw (passive)
            overlay = { texture = "ultimatum", position = "Top" },
            -- button = maul, -- Button already glowing natively
        }
    );
end

local function useDreamOfCenarius()
    -- Guardian
    local guardianNameFunc = SAO:GetSpecNameFunction(3); -- 3 == Guardian
    SAO:CreateEffect(
        "dream_of_cenarius_bear",
        SAO.MOP,
        145162, -- Dream of Cenarius (Guardian buff)
        "aura",
        {
            talent = 108373, -- Dream of Cenarius (talent)
            overlay = { texture = "dark_tiger", position = "Left + Right (Flipped)", option = { subText = guardianNameFunc } },
            buttons = {
                default = { option = { talentSubText = guardianNameFunc } },
                -- [SAO.MOP] = { healingTouch, rebirth }, -- Buttons already glowing natively
            },
        }
    );

    -- Feral
    local feralNameFunc = SAO:GetSpecNameFunction(2); -- 2 == Feral
    local scale, color = 1.2, { 200, 200, 200 }; -- Overlay is slightly bigger to avoid conflict with Omen of Clarity, dimmer to compensate
    SAO:CreateEffect(
        "dream_of_cenarius_cat",
        SAO.MOP,
        145152, -- Dream of Cenarius (Feral buff)
        "aura",
        {
            talent = 108373, -- Dream of Cenarius (talent)
            overlays = {
                { stacks = 1, texture = "dark_tiger", position = "Left"                  , scale = scale, color = color, pulse = true , option = false },
                { stacks = 2, texture = "dark_tiger", position = "Left + Right (Flipped)", scale = scale, color = color, pulse = true , option = { subText = feralNameFunc, setupHash = SAO:HashNameFromStacks(0), testHash = SAO:HashNameFromStacks(2) } },
            },
            -- buttons = nil, -- Too many buttons to suggest
        }
    );
end

local function isFeral(self)
    local shapeshift = GetShapeshiftForm()
    return (shapeshift == 1) or (shapeshift == 3);
end

local function hasClarity(self)
    return self:HasPlayerAuraBySpellID(omenSpellID);
end

local function hasLunar(self)
    return self:HasPlayerAuraBySpellID(lunarSpellID);
end

local function hasSolar(self)
    return self:HasPlayerAuraBySpellID(solarSpellID);
end

local function updateOneSAO(self, position, fakeSpellID, realSpellID, texture, combatOnly)
    if (texture == "") then
        self:DeactivateOverlay(fakeSpellID);
    else
        local endTime = SAO:GetSpellEndTime(realSpellID);
        self:ActivateOverlay(0, fakeSpellID, self.TexName[texture], position, 1, 255, 255, 255, true, nil, endTime, combatOnly);
    end
end

local function updateLeftSAO(self, texture, realSpellID, combatOnly)
    if (leftTexture ~= texture) then
        leftTexture = texture;
        updateOneSAO(self, "Left", leftFakeSpellID, realSpellID, texture, combatOnly);
    end
end

local function updateRightSAO(self, texture, realSpellID, combatOnly)
    if (rightTexture ~= texture) then
        rightTexture = texture;
        updateOneSAO(self, "Right (Flipped)", rightFakeSpellID, realSpellID, texture, combatOnly);
    end
end

local function updateOneSAOTimer(self, leftFakeSpellID, realSpellID)
    local endTime = self:GetSpellEndTime(realSpellID);
    self:RefreshOverlayTimer(leftFakeSpellID, endTime);
end

local function updateLeftSAOTimer(self, realSpellID)
    updateOneSAOTimer(self, leftFakeSpellID, realSpellID);
end

local function updateRightSAOTimer(self, realSpellID)
    updateOneSAOTimer(self, rightFakeSpellID, realSpellID);
end

--[[
    Update Lest/Right SAO

    On Wrath, Lunar and Solar Eclipse are exclusive, and have priority over Omen.
    Possibilities ("X / Y" means "Left uses texture X and Right uses texture Y"):
    - Lunar   / nothing (Lunar proc, no Omen)
    - Lunar   / Omen    (Lunar proc, Omen proc)
    - nothing / Solar   (Solar proc, no Omen)
    - Omen    / Solar   (Solar proc, Omen proc)
    - Omen    / Omen    (Omen proc, no eclipse)
    - nothing / nothing (no proc)

    On Season of Discovery, Lunar and Solar Eclipse have charges, and have priority over Omen.
    Possibilities are the same as Wrath, plus these ones:
    - Lunar   / Solar   (Lunar proc, Solar proc, no Omen)
    - Lunar   / Solar   (Lunar proc, Solar proc, Omen proc)
    The problem is, we don't get to see the Omen proc in the last case.
    If this is unacceptable, please file an issue.
]]
local function updateSAOs(self)
    local omenTexture = feralCache and "feral_omenofclarity" or "natures_grace";
    local lunarTexture = "eclipse_moon";
    local solarTexture = "eclipse_sun";

    local omenOptions = self:GetOverlayOptions(omenSpellID);
    local lunarOptions = self:GetOverlayOptions(lunarSpellID);
    local solarOptions = self:GetOverlayOptions(solarSpellID);

    local mayActivateOmen = clarityCache and (not omenOptions or type(omenOptions[0]) == "nil" or omenOptions[0]);
    local mustActivateLunar = lunarCache and (not lunarOptions or type(lunarOptions[0]) == "nil" or lunarOptions[0]);
    local mustActivateSolar = solarCache and (not solarOptions or type(solarOptions[0]) == "nil" or solarOptions[0]);

    if self:IsSoD() then
        -- Season of Discovery
        local leftImage, rightImage = '', '';
        local leftSpell, rightSpell = nil, nil;
        local leftCOnly, rightCOnly = nil, nil;
        if (mayActivateOmen) then
            leftImage, rightImage = omenTexture, omenTexture;
            leftSpell, rightSpell = omenSpellID, omenSpellID;
        end
        if (mustActivateLunar) then
            leftImage = lunarTexture;
            leftSpell = lunarSpellID;
            leftCOnly = true;
        end
        if (mustActivateSolar) then
            rightImage = solarTexture;
            rightSpell = solarSpellID;
            rightCOnly = true;
        end
        updateLeftSAO (self, leftImage , leftSpell , leftCOnly);
        updateRightSAO(self, rightImage, rightSpell, rightCOnly);
    else
        -- Wrath of the Lich King / Cataclysm
        if (mustActivateLunar) then
            -- Lunar Eclipse
            updateLeftSAO (self, lunarTexture, lunarSpellID, true); -- Left is always Lunar Eclipse
            updateRightSAO(self, mayActivateOmen and omenTexture or '', mayActivateOmen and omenSpellID or nil); -- Right is either Omen or nothing
        elseif (mustActivateSolar) then
            -- Solar Eclipse
            updateLeftSAO (self, mayActivateOmen and omenTexture or '', mayActivateOmen and omenSpellID or nil); -- Left is either Omen or nothing
            updateRightSAO(self, solarTexture, solarSpellID, true); -- Right is always Solar Eclipse
        else
            -- No Eclipse: either both SAOs are Omen of Clarity, or both are nothing
            if (mayActivateOmen) then
                updateLeftSAO (self, omenTexture, omenSpellID);
                updateRightSAO(self, omenTexture, omenSpellID);
            else
                updateLeftSAO (self, '', nil);
                updateRightSAO(self, '', nil);
            end
        end
    end
end

local function updateSAOTimers(self)
    local omenOptions = self:GetOverlayOptions(omenSpellID);
    local lunarOptions = self:GetOverlayOptions(lunarSpellID);
    local solarOptions = self:GetOverlayOptions(solarSpellID);

    local mayActivateOmen = clarityCache and (not omenOptions or type(omenOptions[0]) == "nil" or omenOptions[0]);
    local mustActivateLunar = lunarCache and (not lunarOptions or type(lunarOptions[0]) == "nil" or lunarOptions[0]);
    local mustActivateSolar = solarCache and (not solarOptions or type(solarOptions[0]) == "nil" or solarOptions[0]);

    if self:IsSoD() then
        -- Season of Discovery
        local leftSpell, rightSpell = nil, nil;
        if (mayActivateOmen) then
            leftSpell, rightSpell = omenSpellID, omenSpellID;
        end
        if (mustActivateLunar) then
            leftSpell = lunarSpellID;
        end
        if (mustActivateSolar) then
            rightSpell = solarSpellID;
        end
        updateLeftSAOTimer (self, leftSpell );
        updateRightSAOTimer(self, rightSpell);
    else
        -- Wrath of the Lich King
        if (mustActivateLunar) then
            -- Lunar Eclipse
            updateLeftSAOTimer (self, lunarSpellID); -- Left is always Lunar Eclipse
            updateRightSAOTimer(self, mayActivateOmen and omenSpellID or nil); -- Right is either Omen or nothing
        elseif (mustActivateSolar) then
            -- Solar Eclipse
            updateLeftSAOTimer (self, mayActivateOmen and omenSpellID or nil); -- Left is either Omen or nothing
            updateRightSAOTimer(self, solarSpellID); -- Right is always Solar Eclipse
        else
            -- No Eclipse: either both SAOs are Omen of Clarity, or both are nothing
            if (mayActivateOmen) then
                updateLeftSAOTimer (self, omenSpellID);
                updateRightSAOTimer(self, omenSpellID);
            end
        end
    end
end

local function updateGABs(self)
    if (lunarCache ~= glowingStarfire) then
        local starfireSpellID = 2912;
        if (lunarCache) then
            self:AddGlow(starfireSpellID, { (GetSpellInfo(starfireSpellID)) });
            glowingStarfire = true;
        else
            self:RemoveGlow(starfireSpellID);
            glowingStarfire = false;
        end
    end

    if (solarCache ~= glowingWrath) then
        local wrathSpellID = 5176;
        if (solarCache) then
            self:AddGlow(wrathSpellID, { (GetSpellInfo(wrathSpellID)) });
            glowingWrath = true;
        else
            self:RemoveGlow(wrathSpellID);
            glowingWrath = false;
        end
    end

    -- if ((lunarCache or solarCache) ~= glowingStarsurge) then
    --     local starsurgeSpellID = 78674;
    --     if (lunarCache or solarCache) then
    --         self:AddGlow(starsurgeSpellID, { (GetSpellInfo(starsurgeSpellID)) });
    --         glowingStarsurge = true;
    --     else
    --         self:RemoveGlow(starsurgeSpellID);
    --         glowingStarsurge = false;
    --     end
    -- end
end

local function customLoad(self)
    feralCache = isFeral(self);
    clarityCache = hasClarity(self);
    lunarCache = hasLunar(self);
    solarCache = hasSolar(self);
    updateSAOs(self);
    updateGABs(self);
end

local function updateShapeshift(self)
    local newIsFeral = isFeral(self)
    if (feralCache ~= newIsFeral) then
        feralCache = newIsFeral;
        updateSAOs(self);
    end
end

local function customCLEU(self, ...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo() -- For all events

    -- Accept only certain events, and only when done by the player
    if (event ~= "SPELL_AURA_APPLIED" and event ~= "SPELL_AURA_REMOVED" and event ~= "SPELL_AURA_REFRESH") then return end
    if (sourceGUID ~= UnitGUID("player")) then return end

    local spellID, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo()) -- For SPELL_*

    if (event == "SPELL_AURA_APPLIED") then
        if self:IsSpellIdentical(spellID, spellName, omenSpellID) then
            clarityCache = true;
            updateSAOs(self);
        elseif self:IsSpellIdentical(spellID, spellName, lunarSpellID) then
            lunarCache = true;
            updateSAOs(self);
            updateGABs(self);
        elseif self:IsSpellIdentical(spellID, spellName, solarSpellID) then
            solarCache = true;
            updateSAOs(self);
            updateGABs(self);
        end
        return;
    elseif (event == "SPELL_AURA_REMOVED") then
        if self:IsSpellIdentical(spellID, spellName, omenSpellID) then
            clarityCache = false;
            updateSAOs(self);
        elseif self:IsSpellIdentical(spellID, spellName, lunarSpellID) then
            lunarCache = false;
            updateSAOs(self);
            updateGABs(self);
        elseif self:IsSpellIdentical(spellID, spellName, solarSpellID) then
            solarCache = false;
            updateSAOs(self);
            updateGABs(self);
        end
        return;
    elseif (event == "SPELL_AURA_REFRESH") then
        if self:IsSpellIdentical(spellID, spellName, omenSpellID)
        or self:IsSpellIdentical(spellID, spellName, lunarSpellID)
        or self:IsSpellIdentical(spellID, spellName, solarSpellID)
        then
            updateSAOTimers(self);
        end
        return;
    end
end

local function registerClass(self)
    useNaturesGrace();
    useShootingStars();
    useEclipse(); -- MoP+
    useFuryOfStormrage();
    useToothAndClaw();
    useDreamOfCenarius();
    usePredatoryStrikes(); -- a.k.a. Predatory Swiftness
    useOmenOfClarity(); -- MoP+
    useSwiftbloom();  -- SoD Scarlet Enclave Resto 2pc

    if not SAO.IsProject(SAO.MOP_AND_ONWARD) then -- Pre-MoP
        -- Track Eclipses with a custom CLEU function, so that eclipses can coexist with Omen of Clarity
        -- self:RegisterAura("eclipse_lunar", 0, lunarSpellID, "eclipse_moon", "Left", 1, 255, 255, 255, true);
        -- self:RegisterAura("eclipse_solar", 0, solarSpellID, "eclipse_sun", "Right (Flipped)", 1, 255, 255, 255, true);
        if self.IsProject(SAO.SOD + SAO.WRATH + SAO.CATA + SAO.MOP) then -- Must exclude Eclipses for expansions which have no Eclipses, because the fake spell IDs would be accepted
            self:RegisterAura("eclipse_lunar", 0, lunarSpellID+1000000, "eclipse_moon", "Left", 1, 255, 255, 255, true); -- Fake spell ID, for option testing
            self:RegisterAura("eclipse_solar", 0, solarSpellID+1000000, "eclipse_sun", "Right (Flipped)", 1, 255, 255, 255, true); -- Fake spell ID, for option testing
        end

        -- Track Omen of Clarity with a custom CLEU function, to be able to switch between feral and non-feral texture
        -- self:RegisterAura("omen_of_clarity", 0, 16870, "natures_grace", "Left + Right (Flipped)", 1, 255, 255, 255, true);
        self:RegisterAura("omen_of_clarity", 0, 16870+1000000, "natures_grace", "Left + Right (Flipped)", 1, 255, 255, 255, true); -- Fake spell ID, for option testing

        -- Register glow IDs for glowing buttons, namely Starfire, Wrath and Starsurge
        self:RegisterGlowIDs({ (GetSpellInfo(starfire)), (GetSpellInfo(wrath)) });
        -- if self.IsCata() then
        --     local starsurge = GetSpellInfo(78674);
        --     self:RegisterGlowIDs({ starsurge });
        -- end

        -- Balance 4p set bonuses
        useElunesWrathOfElune("wrath_of_elune", 46833); -- PvP season 5-6-7-8
        useElunesWrathOfElune("elunes_wrath", 64823); -- PvE tier 8

        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_druid", 60512); -- 60512 = Druid buff

        -- Mark textures that aren't marked automatically
        local omenTextureFeral = "feral_omenofclarity";
        local omenTextureResto = "natures_grace";
        local lunarTexture = "eclipse_moon";
        local solarTexture = "eclipse_sun";
        self:MarkTexture(omenTextureFeral);
        self:MarkTexture(omenTextureResto);
        if not self.IsEra() then
            self:MarkTexture(lunarTexture);
            self:MarkTexture(solarTexture);
        end
    end
end

local function loadOptions(self)
    if not SAO.IsProject(SAO.MOP_AND_ONWARD) then -- Pre-MoP
        -- Cheat with fake talents, to tell explicitly which type of eclipse is involved
        -- Otherwise the player would always see a generic "Eclipse" text
        local lunarEclipseTalent = lunarSpellID; -- Not really a talent
        local solarEclipseTalent = solarSpellID; -- Not really a talent

        self:AddOverlayOption(lunarEclipseTalent, lunarSpellID, 0, nil, nil, nil, lunarSpellID+1000000); -- Spell ID not used by ActivateOverlay like typical overlays
        self:AddOverlayOption(solarEclipseTalent, solarSpellID, 0, nil, nil, nil, solarSpellID+1000000); -- Spell ID not used by ActivateOverlay like typical overlays
        self:AddOverlayOption(omenOfClarityTalent, omenSpellID, 0, nil, nil, nil,  omenSpellID+1000000); -- Spell ID not used by ActivateOverlay like typical overlays
        self:AddSoulPreserverOverlayOption(60512); -- 60512 = Druid buff

        self:AddGlowingOption(lunarEclipseTalent, starfire, starfire);
        self:AddGlowingOption(solarEclipseTalent, wrath, wrath);
    end
end

SAO.Class["DRUID"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["UPDATE_SHAPESHIFT_FORM"] = updateShapeshift,
    ["PLAYER_ENTERING_WORLD"] = customLoad,
}
