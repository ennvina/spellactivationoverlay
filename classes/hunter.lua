local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("improved_steady_shot", 0, 53220, "master_marksman", "Top", 1, 255, 255, 255);
end

SAO.Class["HUNTER"] = {
    ["Register"] = registerAuras,
}
