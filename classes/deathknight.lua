local AddonName, SAO = ...

local function registerClass(self)
    self:RegisterAura("rime", 0, 59052, "rime", "Top", 1, 255, 255, 255, true);
    self:RegisterAura("killing_machine", 0, 51124, "killing_machine", "Left + Right (Flipped)", 1, 255, 255, 255, true);
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerClass,
}
