local AddonName, SAO = ...

local function registerAuras(self)
    self:RegisterAura("bloodsurge", 0, 46916, 449487, "Top", 1, 255, 255, 255);
end

SAO.Class["WARRIOR"] = {
    ["Register"] = registerAuras,
}
