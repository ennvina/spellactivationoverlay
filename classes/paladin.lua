local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("art_of_war", 0, 59578, 450913, "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["PALADIN"] = {
    ["Register"] = registerAuras,
}
