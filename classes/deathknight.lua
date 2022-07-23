local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("rime", 0, 59052, 450930, "Top", 1, 255, 255, 255);
    self:RegisterAura("killing_machine", 0, 51124, 458740, "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerAuras,
}
