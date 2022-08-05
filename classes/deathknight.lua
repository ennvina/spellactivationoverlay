local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("rime", 0, 59052, 450930, "Top", 1, 255, 255, 255, true);
    self:RegisterAura("killing_machine", 0, 51124, 458740, "Left + Right (Flipped)", 1, 255, 255, 255, true);
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerAuras,
}
