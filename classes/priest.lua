local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("surge_of_light", 0, 33151, 450933, "Left + Right (Flipped)", 1, 255, 255, 255);

    -- Serendipity with 1 talent point out of 3
--    self:RegisterAura("serendipity_low_1", 1, 63731, 469752, "Top", 0.25, 255, 255, 255);
--    self:RegisterAura("serendipity_low_2", 2, 63731, 469752, "Top", 0.5, 255, 255, 255);
    self:RegisterAura("serendipity_low_3", 3, 63731, 469752, "Top", 1, 255, 255, 255);

    -- Serendipity with 2 talent points out of 3
--    self:RegisterAura("serendipity_medium_1", 1, 63735, 469752, "Top", 0.25, 255, 255, 255);
--    self:RegisterAura("serendipity_medium_2", 2, 63735, 469752, "Top", 0.5, 255, 255, 255);
    self:RegisterAura("serendipity_medium_3", 3, 63735, 469752, "Top", 1, 255, 255, 255);

    -- Serendipity with 3 talent points out of 3
--    self:RegisterAura("serendipity_high_1", 1, 63734, 469752, "Top", 0.25, 255, 255, 255);
--    self:RegisterAura("serendipity_high_2", 2, 63734, 469752, "Top", 0.5, 255, 255, 255);
    self:RegisterAura("serendipity_high_3", 3, 63734, 469752, "Top", 1, 255, 255, 255);
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerAuras,
}
