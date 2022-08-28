local AddonName, SAO = ...

local function registerClass(self)
    -- Art of War
    self:RegisterAura("art_of_war", 0, 59578, "art_of_war", "Left + Right (Flipped)", 1, 255, 255, 255, true, { GetSpellInfo(19750), GetSpellInfo(879) });

    -- Infusion of Light, 1/2 talent points
    self:RegisterAura("infusion_of_light_low", 0, 53672, "daybreak", "Left + Right (Flipped)", 1, 255, 255, 255, true, { GetSpellInfo(19750), GetSpellInfo(635) });

    -- Infusion of Light, 2/2 talent points
    self:RegisterAura("infusion_of_light_high", 0, 54149, "daybreak", "Left + Right (Flipped)", 1, 255, 255, 255, true, { GetSpellInfo(19750), GetSpellInfo(635) });
end

SAO.Class["PALADIN"] = {
    ["Register"] = registerClass,
}
