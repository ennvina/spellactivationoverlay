local AddonName, SAO = ...

local fire_blast = { 2136, 2137, 2138, 8412, 8413, 10197, 10199, 27078, 27079, 42872, 42873 }
local fireball = { 133, 143, 145, 3140, 8400, 8401, 8402, 10148, 10149, 10150, 10151, 25306, 27070, 38692, 42832, 42833 }
local living_bomb = { 44457, 55359, 55360 }
local scorch = { 2948, 8444, 8445, 8446, 10205, 10206, 10207, 27073, 27074, 42858, 42859 }

local function registerAuras(self)
    -- self:RegisterAura("hot_streak_half", 0, 48107, 449490, "Left + Right (Flipped)", 0.5, 255, 255, 255); -- 48107 doesn't exist in Wrath Classic
    self:RegisterAura("hot_streak_full", 0, 48108, 449490, "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["MAGE"] = {
    ["Register"] = registerAuras,
}
