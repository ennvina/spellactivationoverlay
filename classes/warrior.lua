local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("bloodsurge", 0, 46916, 449487, "Top", 1, 255, 255, 255, true);
    self:RegisterAura("sudden_death", 0, 52437, 449493, "Left + Right (Flipped)", 1, 255, 255, 255, true);
    self:RegisterAura("sword_and_board", 0, 50227, 449494, "Left + Right (Flipped)", 1, 255, 255, 255, true);
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerAuras,
}
