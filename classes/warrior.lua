local AddonName, SAO = ...

local function registerClass(self)
    self:RegisterAura("bloodsurge", 0, 46916, "blood_surge", "Top", 1, 255, 255, 255, true);
    self:RegisterAura("sudden_death", 0, 52437, "sudden_death", "Left + Right (Flipped)", 1, 255, 255, 255, true);
    self:RegisterAura("sword_and_board", 0, 50227, "sword_and_board", "Left + Right (Flipped)", 1, 255, 255, 255, true, { GetSpellInfo(23922) });
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerClass,
}
