local AddonName, SAO = ...

local function registerAuras(self)
    -- Elemental Focus
    self:RegisterAura("elemental_focus_1", 1, 16246, "echo_of_the_elements", "Left", 1, 255, 255, 255, true);
    self:RegisterAura("elemental_focus_2", 2, 16246, "echo_of_the_elements", "Left + Right (Flipped)", 1, 255, 255, 255, true);

    -- Maelstrom Weapon
    self:RegisterAura("maelstrom_weapoon_1", 1, 53817, 1028136, "Top", 1, 255, 255, 255, false);
    self:RegisterAura("maelstrom_weapoon_2", 2, 53817, 1028137, "Top", 1, 255, 255, 255, false);
    self:RegisterAura("maelstrom_weapoon_3", 3, 53817, 1028138, "Top", 1, 255, 255, 255, false);
    self:RegisterAura("maelstrom_weapoon_4", 4, 53817, 1028139, "Top", 1, 255, 255, 255, false);
    self:RegisterAura("maelstrom_weapoon_5", 5, 53817, 450927, "Top", 1, 255, 255, 255, true);
end

SAO.Class["SHAMAN"] = {
    ["Register"] = registerAuras,
}
