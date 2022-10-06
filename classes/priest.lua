local AddonName, SAO = ...

local function registerClass(self)
    local smite = GetSpellInfo(585);
    local flashHeal = GetSpellInfo(2061);
    self:RegisterAura("surge_of_light", 0, 33151, "surge_of_light", "Left + Right (Flipped)", 1, 255, 255, 255, true, { smite, flashHeal });

    local serendipityBuff1 = 63731;
    local serendipityBuff2 = 63735;
    local serendipityBuff3 = 63734;
    local ghAndPoh = { (GetSpellInfo(2060)), (GetSpellInfo(596)) }

    -- Serendipity with 1 talent point out of 3
--    self:RegisterAura("serendipity_low_1", 1, serendipityBuff1, "serendipity", "Top", 0.25, 255, 255, 255, true, ghAndPoh);
--    self:RegisterAura("serendipity_low_2", 2, serendipityBuff1, "serendipity", "Top", 0.5, 255, 255, 255, true, ghAndPoh);
    self:RegisterAura("serendipity_low_3", 3, serendipityBuff1, "serendipity", "Top", 1, 255, 255, 255, true, ghAndPoh);

    -- Serendipity with 2 talent points out of 3
--    self:RegisterAura("serendipity_medium_1", 1, serendipityBuff2, "serendipity", "Top", 0.25, 255, 255, 255, true, ghAndPoh);
--    self:RegisterAura("serendipity_medium_2", 2, serendipityBuff2, "serendipity", "Top", 0.5, 255, 255, 255, true, ghAndPoh);
    self:RegisterAura("serendipity_medium_3", 3, serendipityBuff2, "serendipity", "Top", 1, 255, 255, 255, true, ghAndPoh);

    -- Serendipity with 3 talent points out of 3
--    self:RegisterAura("serendipity_high_1", 1, serendipityBuff3, "serendipity", "Top", 0.25, 255, 255, 255, true, ghAndPoh);
--    self:RegisterAura("serendipity_high_2", 2, serendipityBuff3, "serendipity", "Top", 0.5, 255, 255, 255, true, ghAndPoh);
    self:RegisterAura("serendipity_high_3", 3, serendipityBuff3, "serendipity", "Top", 1, 255, 255, 255, true, ghAndPoh);

    -- Add option links during registerClass(), not because loadOptions() which would be loaded only when the options panel is opened
    self:AddGlowingLink(serendipityBuff3, serendipityBuff1);
    self:AddGlowingLink(serendipityBuff3, serendipityBuff2);
end

local function loadOptions(self)
-- Smite (Surge of Light), Flash Heal (Surge of Light), Greater Heal (3 stacks of Serendipity), Prayer of Healing (3 stacks of Serendipity)
    local smite = 585;
    local flashHeal = 2061;
    local greaterHeal = 2060;
    local prayerOfHealing = 596;

    local surgeOfLightBuff = 33151;
    local surgeOfLightTalent = 33150;

--    local serendipityBuff1 = 63731;
--    local serendipityBuff2 = 63735;
    local serendipityBuff3 = 63734;
    local serendipityTalent = 63730;

    self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, smite);
    self:AddGlowingOption(surgeOfLightTalent, surgeOfLightBuff, flashHeal);
    self:AddGlowingOption(serendipityTalent, serendipityBuff3, greaterHeal);
    self:AddGlowingOption(serendipityTalent, serendipityBuff3, prayerOfHealing);
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
