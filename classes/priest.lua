local AddonName, SAO = ...

local function registerClass(self)
    local smite = GetSpellInfo(585);
    local flashHeal = GetSpellInfo(2061);

    local serendipityBuff1 = 63731;
    local serendipityBuff2 = 63735;
    local serendipityBuff3 = 63734;
    local ghAndPoh = { (GetSpellInfo(2060)), (GetSpellInfo(596)) }

    -- Add option links during registerClass(), not because loadOptions() which would be loaded only when the options panel is opened
    -- Add option links before RegisterAura() calls, so that options they are used by initial triggers, if any
    self:AddGlowingLink(serendipityBuff3, serendipityBuff1);
    self:AddGlowingLink(serendipityBuff3, serendipityBuff2);

    -- Surge of Light
    self:RegisterAura("surge_of_light", 0, 33151, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite, flashHeal });

    -- Serendipity with 1 talent point out of 3
    self:RegisterAura("serendipity_low", 3, serendipityBuff1, "serendipity", "Top", 1, 255, 255, 255, true, ghAndPoh);

    -- Serendipity with 2 talent points out of 3
    self:RegisterAura("serendipity_medium", 3, serendipityBuff2, "serendipity", "Top", 1, 255, 255, 255, true, ghAndPoh);

    -- Serendipity with 3 talent points out of 3
    self:RegisterAura("serendipity_high", 3, serendipityBuff3, "serendipity", "Top", 1, 255, 255, 255, true, ghAndPoh);
end

local function loadOptions(self)
    local smite = 585;
    local flashHeal = 2061;
    local greaterHeal = 2060;
    local prayerOfHealing = 596;

    local surgeOfLightBuff = 33151;
    local surgeOfLightTalent = 33150;

    local serendipityBuff3 = 63734;
    local serendipityTalent = 63730;

    local threeStacks = string.format(STACKS, 3);

    self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, smite);
    self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, flashHeal);
    self:AddGlowingOption(serendipityTalent, serendipityBuff3, greaterHeal, threeStacks);
    self:AddGlowingOption(serendipityTalent, serendipityBuff3, prayerOfHealing, threeStacks);
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
