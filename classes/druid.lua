local AddonName, SAO = ...

-- Optimize frequent calls
local CombatLogGetCurrentEventInfo = CombatLogGetCurrentEventInfo
local GetShapeshiftForm = GetShapeshiftForm
local GetSpellInfo = GetSpellInfo
local UnitGUID = UnitGUID

local omenSpellID = 16870;
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

local naturesGraceVariants; -- Lazy init in lazyCreateNaturesGraceVariants()

local function isFeral(self)
    local shapeshift = GetShapeshiftForm()
    return (shapeshift == 1) or (shapeshift == 3);
end

local function hasClarity(self)
    return self:FindPlayerAuraByID(omenSpellID) ~= nil;
end

local function hasLunar(self)
    return self:FindPlayerAuraByID(lunarSpellID) ~= nil;
end

local function hasSolar(self)
    return self:FindPlayerAuraByID(solarSpellID) ~= nil;
end

local function updateOneSAO(self, position, fakeSpellID, realSpellID, texture)
    if (texture == "") then
        self:DeactivateOverlay(fakeSpellID);
    else
        local endTime = SAO:GetSpellEndTime(realSpellID);
        self:ActivateOverlay(0, fakeSpellID, self.TexName[texture], position, 1, 255, 255, 255, true, nil, endTime);
    end
end

local function updateLeftSAO(self, texture, realSpellID)
    if (leftTexture ~= texture) then
        leftTexture = texture;
        updateOneSAO(self, "Left", leftFakeSpellID, realSpellID, texture);
    end
end

local function updateRightSAO(self, texture, realSpellID)
    if (rightTexture ~= texture) then
        rightTexture = texture;
        updateOneSAO(self, "Right (Flipped)", rightFakeSpellID, realSpellID, texture);
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
        if (mayActivateOmen) then
            leftImage, rightImage = omenTexture, omenTexture;
            leftSpell, rightSpell = omenSpellID, omenSpellID;
        end
        if (mustActivateLunar) then
            leftImage = lunarTexture;
            leftSpell = lunarSpellID;
        end
        if (mustActivateSolar) then
            rightImage = solarTexture;
            rightSpell = solarSpellID;
        end
        updateLeftSAO (self, leftImage , leftSpell );
        updateRightSAO(self, rightImage, rightSpell);
    else
        -- Wrath of the Lich King
        if (mustActivateLunar) then
            -- Lunar Eclipse
            updateLeftSAO (self, lunarTexture, lunarSpellID); -- Left is always Lunar Eclipse
            updateRightSAO(self, mayActivateOmen and omenTexture or '', mayActivateOmen and omenSpellID or nil); -- Right is either Omen or nothing
        elseif (mustActivateSolar) then
            -- Solar Eclipse
            updateLeftSAO (self, mayActivateOmen and omenTexture or '', mayActivateOmen and omenSpellID or nil); -- Left is either Omen or nothing
            updateRightSAO(self, solarTexture, solarSpellID); -- Right is always Solar Eclipse
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

local function lazyCreateNaturesGraceVariants(self)
    if (naturesGraceVariants) then
        return;
    end

    local spellID = 16886;

    local textureVariant1 = "serendipity";
    local textureVariant2 = "fury_of_stormrage";

    if not SAO.IsEra() or GetSpellInfo(spellID) then
        self:MarkTexture(textureVariant1);
        self:MarkTexture(textureVariant2);
    end

    naturesGraceVariants = self:CreateTextureVariants(spellID, 0, {
        self:TextureVariantValue(textureVariant1, true),
        self:TextureVariantValue(textureVariant2, true),
    });
end

local function registerClass(self)
    -- Track Eclipses with a custom CLEU function, so that eclipses can coexist with Omen of Clarity
    -- self:RegisterAura("eclipse_lunar", 0, lunarSpellID, "eclipse_moon", "Left", 1, 255, 255, 255, true);
    -- self:RegisterAura("eclipse_solar", 0, solarSpellID, "eclipse_sun", "Right (Flipped)", 1, 255, 255, 255, true);
    if self.IsSoD() or self.IsWrath() or self.IsCata() then -- Must exclude Eclipses for expansions which have no Eclipses, because the fake spell IDs would be accepted
        self:RegisterAura("eclipse_lunar", 0, lunarSpellID+1000000, "eclipse_moon", "Left", 1, 255, 255, 255, true); -- Fake spell ID, for option testing
        self:RegisterAura("eclipse_solar", 0, solarSpellID+1000000, "eclipse_sun", "Right (Flipped)", 1, 255, 255, 255, true); -- Fake spell ID, for option testing
    end

    -- Track Omen of Clarity with a custom CLEU function, to be able to switch between feral and non-feral texture
    -- self:RegisterAura("omen_of_clarity", 0, 16870, "natures_grace", "Left + Right (Flipped)", 1, 255, 255, 255, true);
    self:RegisterAura("omen_of_clarity", 0, 16870+1000000, "natures_grace", "Left + Right (Flipped)", 1, 255, 255, 255, true); -- Fake spell ID, for option testing

    -- Register glow IDs for glowing buttons, namely Starfire, Wrath and Starsurge
    local starfire = GetSpellInfo(2912);
    local wrath = GetSpellInfo(5176);
    self:RegisterGlowIDs({ starfire, wrath });
    -- if self.IsCata() then
    --     local starsurge = GetSpellInfo(78674);
    --     self:RegisterGlowIDs({ starsurge });
    -- end

    -- Predatory Strikes, inspired by Predatory Swiftness
    local regrowth = GetSpellInfo(8936);
    local healingTouch = GetSpellInfo(5185);
    local nourish = GetSpellInfo(50464);
    local rebirth = GetSpellInfo(20484);
    -- local wrath = GetSpellInfo(5176);
    local entanglingRoots = GetSpellInfo(339);
    local cyclone = GetSpellInfo(33786);
    local hibernate = GetSpellInfo(2637);
    local predatoryStrikesSpells = {
        regrowth,
        healingTouch,
        nourish,
        rebirth,
        wrath,
        entanglingRoots,
        cyclone,
        hibernate,
    }
    self:RegisterAura("predatory_strikes", 0, 69369, "predatory_swiftness", "Top", 1, 255, 255, 255, true, predatoryStrikesSpells);

    -- Nature's Grace
    if self.IsEra() then
        -- Texture of Nature's Grace is always "serendipity" to avoid confusion with SoD's Fury of Stormrage which, obvisouly, uses "fury_of_stormrage"
        -- This limitation is necessary for Season of Discovery only, but because SoD and non-SoD Era share the same config file, we have to dumb down
        self:RegisterAura("natures_grace", 0, 16886, "serendipity", "Top", 1, 255, 255, 255, true);
    else
        -- Let the player select between "serendipity" and "fury_of_stormrage"
        lazyCreateNaturesGraceVariants(self);
        self:RegisterAura("natures_grace", 0, 16886, naturesGraceVariants.textureFunc, "Top", 1, 255, 255, 255, true);
    end

    -- Balance 4p set bonuses
    self:RegisterAura("wrath_of_elune", 0, 46833, "shooting_stars", "Top", 1, 255, 255, 255, true, { starfire }); -- PvP season 5-6-7-8
    self:RegisterAura("elunes_wrath", 0, 64823, "shooting_stars", "Top", 1, 255, 255, 255, true, { starfire }); -- PvE tier 8

    -- Fury of Stormrage (Season of Discovery)
    if self.IsSoD() then
        local furyOfStormrage = 414800;
        self:RegisterAura("fury_of_stormrage", 0, furyOfStormrage, "fury_of_stormrage", "Top", 1, 255, 255, 255, true, { healingTouch });
    end

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

local function loadOptions(self)
    local starfire = 2912;
    local wrath = 5176;

    -- Predatory Strikes candidates
    local regrowth = 8936;
    local healingTouch = 5185;
    local nourish = 50464;
    local rebirth = 20484;
    -- local wrath = 5176;
    local entanglingRoots = 339;
    local cyclone = 33786;
    local hibernate = 2637;

    local omenOfClarityTalent = 16864;
--    local eclipseTalent = 48516;
    -- Cheat with fake talents, to tell explicitly which type of eclipse is involved
    -- Otherwise the player would always see a generic "Eclipse" text
    local lunarEclipseTalent = lunarSpellID; -- Not really a talent
    local solarEclipseTalent = solarSpellID; -- Not really a talent

    local wrathOfEluneBuff = 46833;
    local elunesWrathBuff = 64823;
    local wrathOfEluneTalent = wrathOfEluneBuff; -- Not really a talent
    local elunesWrathTalent = elunesWrathBuff; -- Not really a talent

    local furyOfStormrageBuff = 414800;
    local furyOfStormrageTalent = furyOfStormrageBuff; -- Not really a talent

    local predatoryStrikesTalent = 16972;
    local predatoryStrikesBuff = 69369;

    local naturesGraceEraTalent = 16880;
    local naturesGraceWrathTalent = 61346;
    local naturesGraceBuff = 16886;

    self:AddOverlayOption(omenOfClarityTalent, omenSpellID, 0, nil, nil, nil,  omenSpellID+1000000); -- Spell ID not used by ActivateOverlay like typical overlays
    self:AddOverlayOption(lunarEclipseTalent, lunarSpellID, 0, nil, nil, nil, lunarSpellID+1000000); -- Spell ID not used by ActivateOverlay like typical overlays
    self:AddOverlayOption(solarEclipseTalent, solarSpellID, 0, nil, nil, nil, solarSpellID+1000000); -- Spell ID not used by ActivateOverlay like typical overlays
    self:AddOverlayOption(wrathOfEluneTalent, wrathOfEluneBuff);
    self:AddOverlayOption(elunesWrathTalent, elunesWrathBuff);
    if self.IsSoD() then
        self:AddOverlayOption(furyOfStormrageTalent, furyOfStormrageBuff);
    end
    if self.IsEra() then
        self:AddOverlayOption(naturesGraceEraTalent, naturesGraceBuff);
    elseif self.IsTBC() then
        lazyCreateNaturesGraceVariants(self);
        self:AddOverlayOption(naturesGraceEraTalent, naturesGraceBuff, 0, nil, naturesGraceVariants); -- Same talent as Era
    else
        lazyCreateNaturesGraceVariants(self);
        self:AddOverlayOption(naturesGraceWrathTalent, naturesGraceBuff, 0, nil, naturesGraceVariants);
    end
    self:AddOverlayOption(predatoryStrikesTalent, predatoryStrikesBuff);
    self:AddSoulPreserverOverlayOption(60512); -- 60512 = Druid buff

    self:AddGlowingOption(lunarEclipseTalent, starfire, starfire);
    self:AddGlowingOption(solarEclipseTalent, wrath, wrath);
    self:AddGlowingOption(wrathOfEluneTalent, wrathOfEluneBuff, starfire);
    self:AddGlowingOption(elunesWrathTalent, elunesWrathBuff, starfire);
    if self.IsSoD() then
        self:AddGlowingOption(furyOfStormrageTalent, furyOfStormrageBuff, healingTouch);
    end
    if not self.IsEra() then -- Must exclude this option specifically for Classic Era, because the talent exists in Era but it has no proc
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, regrowth);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, healingTouch);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, nourish);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, rebirth);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, wrath);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, entanglingRoots);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, cyclone);
        self:AddGlowingOption(predatoryStrikesTalent, predatoryStrikesBuff, hibernate);
    end
end

SAO.Class["DRUID"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["UPDATE_SHAPESHIFT_FORM"] = updateShapeshift,
    ["PLAYER_ENTERING_WORLD"] = customLoad,
}
