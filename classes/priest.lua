local AddonName, SAO = ...

local flashHeal = 2061;
local flashHealNoMana = 101062;
local innerFire = 588;
local mindBlast = 8092;
local shadowform = 15473;
local smite = 585;
local swDeath = 32379;
local bindingHeal = 401937;

local function useInnerFire()
    SAO:CreateEffect(
        "inner_fire",
        SAO.WRATH + SAO.CATA,
        innerFire,
        "aura",
        {
            combatOnly = true,
            button = { stacks = -1 },
        }
    );
end

local function useSurgeOfLight()
    SAO:CreateEffect(
        "surge_of_light",
        SAO.SOD + SAO.TBC + SAO.WRATH + SAO.CATA,
        {
            [SAO.SOD] = 431666,
            [SAO.TBC+SAO.WRATH] = 33151,
            [SAO.CATA] = 88688,
        },
        "aura",
        {
            talent = {
                [SAO.SOD] = 431664,
                [SAO.TBC+SAO.WRATH] = 33150,
                [SAO.CATA] = 88687,
            },
            overlay = { texture = "surge_of_light", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.SOD] = { smite, flashHeal, bindingHeal },
                [SAO.TBC] = smite,
                [SAO.WRATH] = { smite, flashHeal },
                [SAO.CATA] = flashHealNoMana,
            },
        }
    );
end

local function useShadowform()
    SAO:CreateEffect(
        "shadowform",
        SAO.ALL_PROJECTS,
        shadowform,
        "aura",
        {
            requireTalent = true,
            combatOnly = true,
            button = { stacks = -1 },
        }
    );
end

local function useShadowWordDeath()
    SAO:CreateEffect(
        "sw_death",
        SAO.CATA,
        swDeath,
        "counter",
        {
            useExecute = true,
            execThreshold = 25,
            buttonOption = { spellSubText = SAO:ExecuteBelow(25) },
        }
    );
end

local function useMindMelt()
--  local mindMeltBuff1 = 81292; -- Not used, only the second buff is interesting
    local mindMeltBuff2 = 87160;
    local mindMeltTalent = 14910;

    SAO:CreateEffect(
        "mind_melt",
        SAO.CATA,
        mindMeltBuff2,
        "aura",
        {
            talent = mindMeltTalent,
            button = mindBlast,
        }
    );
end

local function registerClass(self)
    if not self.IsEra() then -- TBC/Wrath/Cata
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
        elseif self.IsCata() then
            self:AddOverlayLink(serendipityBuff2, serendipityBuff1);
            self:AddGlowingLink(serendipityBuff2, serendipityBuff1);
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
        elseif self.IsCata() then
            for talentPoints=1,2 do
                local auraName = ({ "serendipity_low", "serendipity_high" })[talentPoints];
                local auraBuff = ({ serendipityBuff1, serendipityBuff2 })[talentPoints];
                for nbStacks=1,2 do
                    local scale = 0.7 + 0.3 * nbStacks; -- 70%, 100%
                    local pulse = nbStacks == 2;
                    local glowIDs = nbStacks == 2 and ghAndPoh or nil;
                    self:RegisterAura(auraName, nbStacks, auraBuff, "serendipity", "Top", scale, 255, 255, 255, pulse, glowIDs);
                end
            end
        end

        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_priest", 60514); -- 60514 = Priest buff

    elseif self.IsSoD() then
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
-- Disabled because it must to track the target debuff, not the player buff, which requires new development
--         local mindSpikeBuff = 431655;
--         local mindSpikeImprovedSpells = { (GetSpellInfo(mindBlast)) };
--         for nbStacks=1,3 do
--             local scale = 0.4 + 0.2 * nbStacks; -- 60%, 80%, 100%
--             local pulse = nbStacks == 3;
--             local glowIDs = nbStacks == 3 and mindSpikeImprovedSpells or nil;
--             self:RegisterAura("mind_spike_sod", nbStacks, mindSpikeBuff, "frozen_fingers", "Left + Right (Flipped)", scale, 160, 60, 220, pulse, glowIDs);
--         end
    end

    -- Discipline
    useInnerFire();

    -- Holy
    useSurgeOfLight();

    -- Shadow
    useShadowWordDeath();
    useShadowform();
    useMindMelt();
end

local function loadOptions(self)
    local lesserHeal = 2050;
    local heal = 2054;
    local greaterHeal = 2060;
    local prayerOfHealing = 596;

    local mindSpikeSoDBuff = 431655;
    local mindSpikeSoDRune = 431662;

    local serendipityBuff2 = 63735;
    local serendipityBuff3 = 63734;
    local serendipityTalent = 63730;
    local serendipitySoDBuff = 413247;

    local oneOrTwoStacks = self:NbStacks(1, 2);
    local twoStacks = self:NbStacks(2);
    local threeStacks = self:NbStacks(3);

    if not self.IsEra() then
        if self.IsWrath() then
            self:AddOverlayOption(serendipityTalent, serendipityBuff3, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
            self:AddOverlayOption(serendipityTalent, serendipityBuff3, self:HashNameFromStacks(3)); -- setup 3 stacks
        elseif self.IsCata() then
            self:AddOverlayOption(serendipityTalent, serendipityBuff2, self:HashNameFromStacks(1));
            self:AddOverlayOption(serendipityTalent, serendipityBuff2, self:HashNameFromStacks(2));
        end
        self:AddSoulPreserverOverlayOption(60514); -- 60514 = Priest buff

        if self.IsWrath() then
            self:AddGlowingOption(serendipityTalent, serendipityBuff3, greaterHeal, threeStacks);
            self:AddGlowingOption(serendipityTalent, serendipityBuff3, prayerOfHealing, threeStacks);
        elseif self.IsCata() then
            self:AddGlowingOption(serendipityTalent, serendipityBuff2, greaterHeal, twoStacks);
            self:AddGlowingOption(serendipityTalent, serendipityBuff2, prayerOfHealing, twoStacks);
        end
    elseif self.IsSoD() then
        self:AddOverlayOption(serendipitySoDBuff, serendipitySoDBuff, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
        self:AddOverlayOption(serendipitySoDBuff, serendipitySoDBuff, self:HashNameFromStacks(3)); -- setup 3 stacks
--         self:AddOverlayOption(mindSpikeSoDRune, mindSpikeSoDBuff, 0, oneOrTwoStacks, nil, 2); -- setup any stacks, test with 2 stacks
--         self:AddOverlayOption(mindSpikeSoDRune, mindSpikeSoDBuff, self:HashNameFromStacks(3)); -- setup 3 stacks

        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, lesserHeal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, heal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, greaterHeal, threeStacks);
        self:AddGlowingOption(serendipitySoDBuff, serendipitySoDBuff, prayerOfHealing, threeStacks);
--         self:AddGlowingOption(mindSpikeSoDRune, mindSpikeSoDBuff, mindBlast, threeStacks);
    end
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
