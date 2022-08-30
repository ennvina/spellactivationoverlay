local AddonName, SAO = ...

local function registerClass(self)
    local flashOfLight = GetSpellInfo(19750);
    local exorcism = GetSpellInfo(879);
    local holyLight = GetSpellInfo(635);

    -- Art of War
    self:RegisterAura("art_of_war", 0, 59578, "art_of_war", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flashOfLight, exorcism });

    -- Infusion of Light, 1/2 talent points
    self:RegisterAura("infusion_of_light_low", 0, 53672, "daybreak", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flashOfLight, holyLight });

    -- Infusion of Light, 2/2 talent points
    self:RegisterAura("infusion_of_light_high", 0, 54149, "daybreak", "Left + Right (Flipped)", 1, 255, 255, 255, true, { flashOfLight, holyLight });
end

SAO.Class["PALADIN"] = {
    ["Register"] = registerClass,
}
