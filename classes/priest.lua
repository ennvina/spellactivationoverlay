local AddonName, SAO = ...

local function registerClass(self)
    if not self.IsEra() then -- TBC/Wrath/Cata
        local smite = GetSpellInfo(585);
        local flashHeal = GetSpellInfo(2061);

        local serendipityBuff1 = 63731;
        local serendipityBuff2 = 63735;
        local serendipityBuff3 = 63734;
        local ghAndPoh = { (GetSpellInfo(2060)), (GetSpellInfo(596)) };

        -- Add option links during registerClass(), not during loadOptions() which would be loaded only when the options panel is opened
        -- Add option links before RegisterAura() calls, so that options they are used by initial triggers, if any
        if self.IsWrath() then
            self:AddOverlayLink(serendipityBuff3, serendipityBuff1);
            self:AddOverlayLink(serendipityBuff3, serendipityBuff2);
            self:AddGlowingLink(serendipityBuff3, serendipityBuff1);
            self:AddGlowingLink(serendipityBuff3, serendipityBuff2);
        end

        -- Surge of Light
        local surgeOfLightBuff = self.IsCata() and 88688 or 33151;
        if self.IsTBC() then
            self:RegisterAura("surge_of_light", 0, surgeOfLightBuff, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite });
        elseif self.IsWrath() then
            self:RegisterAura("surge_of_light", 0, surgeOfLightBuff, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite, flashHeal });
        elseif self.IsCata() then
            self:RegisterAura("surge_of_light", 0, surgeOfLightBuff, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flashHeal });
        end

        if self.IsWrath() then
            for talentPoints=1,3 do
                local auraName = ({ "serendipity_low", "serendipity_medium", "serendipity_high" })[talentPoints];
                local auraBuff = ({ serendipityBuff1, serendipityBuff2, serendipityBuff3 })[talentPoints];
                for nbStacks=1,3 do
                    local scale = 0.4 + 0.2 * nbStacks; -- 60%, 80%, 100%
                    local pulse = nbStacks == 3;
                    local glowIDs = nbStacks == 3 and ghAndPoh or nil;
                    self:RegisterAura(auraName, nbStacks, auraBuff, "serendipity", "Top", scale, 255, 255, 255, pulse, glowIDs);
                end
            end
        end

        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_priest", 60514); -- 60514 = Priest buff

    elseif self.IsSoD() then
        local smite = GetSpellInfo(585);
        local flashHeal = GetSpellInfo(2061);

        -- Surge of Light
        self:RegisterAura("surge_of_light_sod", 0, 431666, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite, flashHeal });

        local serendipityBuff = 413247;
        local lesserHeal = 2050;
        local heal = 2054;
        local greaterHeal = 2060;
        local prayerOfHealing = 596;
        local serendipityImprovedSpells = { (GetSpellInfo(lesserHeal)), (GetSpellInfo(heal)), (GetSpellInfo(greaterHeal)), (GetSpellInfo(prayerOfHealing)) };
        for nbStacks=1,3 do
            local scale = 0.4 + 0.2 * nbStacks; -- 60%, 80%, 100%
            local pulse = nbStacks == 3;
            local glowIDs = nbStacks == 3 and serendipityImprovedSpells or nil;
            self:RegisterAura("serendipity_sod", nbStacks, serendipityBuff, "serendipity", "Top", scale, 255, 255, 255, pulse, glowIDs);
        end

        -- Mind Spike
        local mindSpikeBuff = 431655;
        local mindBlast = 8092;
        local mindSpikeImprovedSpells = { (GetSpellInfo(mindBlast)) };
        for nbStacks=1,3 do
            local scale = 0.4 + 0.2 * nbStacks; -- 60%, 80%, 100%
            local pulse = nbStacks == 3;
            local glowIDs = nbStacks == 3 and mindSpikeImprovedSpells or nil;
            self:RegisterAura("mind_spike_sod", nbStacks, mindSpikeBuff, "frozen_fingers", "Left + Right (Flipped)", scale, 160, 60, 220, pulse, glowIDs);
        end
    end
end

local function loadOptions(self)
    local smite = 585;
    local flashHeal = 2061;
    local lesserHeal = 2050;
    local heal = 2054;
    local greaterHeal = 2060;
    local prayerOfHealing = 596;
    local mindBlast = 8092;

    local surgeOfLightBuff = self.IsCata() and 88688 or 33151;
    local surgeOfLightTalent = self.IsCata() and 88687 or 33150;
    local surgeOfLightSoDBuff = 431666;
    local surgeOfLightSoDRune = 431664;

    local mindSpikeSoDBuff = 431655;
    local mindSpikeSoDRune = 431662;

    local serendipityBuff3 = 63734;
    local serendipityTalent = 63730;
    local serendipitySoDBuff = 413247;

    local oneOrTwoStacks = self:NbStacks(1, 2);
    local threeStacks = self:NbStacks(3);

    if not self.IsEra() then
        self:AddOverlayOption(surgeOfLightTalent, surgeOfLightBuff);
        if self.IsWrath() then
            self:AddOverlayOption(serendipityTalent, serendipityBuff3, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
            self:AddOverlayOption(serendipityTalent, serendipityBuff3, 3); -- setup 3 stacks
        end
        self:AddSoulPreserverOverlayOption(60514); -- 60514 = Priest buff

        if self.IsTBC() or self.IsWrath() then
            self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, smite);
        end
        if self.IsWrath() or self.IsCata() then
            self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, flashHeal); -- Note to Effect morph: must useName, because of spell 101062
        end
        if self.IsWrath() then
            self:AddGlowingOption(serendipityTalent, serendipityBuff3, greaterHeal, threeStacks);
            self:AddGlowingOption(serendipityTalent, serendipityBuff3, prayerOfHealing, threeStacks);
        end
    elseif self.IsSoD() then
        self:AddOverlayOption(surgeOfLightSoDRune, surgeOfLightSoDBuff);
        self:AddOverlayOption(serendipitySoDBuff, serendipitySoDBuff, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddOverlayOption(serendipitySoDBuff, serendipitySoDBuff, 3); -- setup 3 stacks
        self:AddOverlayOption(mindSpikeSoDRune, mindSpikeSoDBuff, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddOverlayOption(mindSpikeSoDRune, mindSpikeSoDBuff, 3); -- setup 3 stacks

        self:AddGlowingOption(surgeOfLightSoDRune, surgeOfLightSoDBuff, smite);
        self:AddGlowingOption(surgeOfLightSoDRune, surgeOfLightSoDBuff, flashHeal);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, lesserHeal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, heal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, greaterHeal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, prayerOfHealing, threeStacks);
        self:AddGlowingOption(mindSpikeSoDRune, mindSpikeSoDBuff, mindBlast, threeStacks);
    end
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
