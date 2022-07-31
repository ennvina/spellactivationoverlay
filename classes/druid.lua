local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("omen_of_clarity", 0, 16870, "natures_grace", "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["DRUID"] = {
    ["Register"] = registerAuras,
}
