local AddonName, SAO = ...

local function registerClass(self)
    self:RegisterAura("bloodsurge", 0, 46916, "blood_surge", "Top", 1, 255, 255, 255, true, { GetSpellInfo(1464) });
    self:RegisterAura("sudden_death", 0, 52437, "sudden_death", "Left + Right (Flipped)", 1, 255, 255, 255, true, { GetSpellInfo(5308) });
    self:RegisterAura("sword_and_board", 0, 50227, "sword_and_board", "Left + Right (Flipped)", 1, 255, 255, 255, true, { GetSpellInfo(23922) });

    local overpower = 7384;
    self:RegisterAura("overpower", 0, overpower, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(overpower)) });
    self:RegisterCounter("overpower"); -- Must match name from above call

    local revenge = 6572;
    self:RegisterAura("revenge", 0, revenge, nil, "", 0, 0, 0, 0, false, { (GetSpellInfo(revenge)) });
    self:RegisterCounter("revenge"); -- Must match name from above call
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerClass,
}
