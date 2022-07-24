local AddonName, SAO = ...

local function registerAuras(self)
    -- self:RegisterAura("hot_streak_half", 0, 48107, 449490, "Left + Right (Flipped)", 0.5, 255, 255, 255); -- 48107 doesn't exist in Wrath Classic
    self:RegisterAura("hot_streak_full", 0, 48108, 449490, "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["MAGE"] = {
    ["Register"] = registerAuras,
}
