local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("surge_of_light", 0, 33151, 450933, "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["PRIEST"] = {
    ["Register"] = registerAuras,
}
