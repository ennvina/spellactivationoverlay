local AddonName, SAO = ...

local function registerMolenCore(self, baseName, spellID)
    self:RegisterAura(baseName.."_1", 1, spellID, "molten_core", "Left", 1, 255, 255, 255, true);
    self:RegisterAura(baseName.."_2", 2, spellID, "molten_core", "Left + Right (Flipped)", 1, 255, 255, 255, true);
    self:RegisterAura(baseName.."_3", 3, spellID, "molten_core", "Left + Right (Flipped)", 1, 255, 255, 255, true);
    self:RegisterAura(baseName.."_3_top", 3, spellID, "lock_and_load", "Top", 1, 255, 255, 255, true);
--    self:RegisterAura(baseName.."_3_top", 3, spellID, "impact", "Top", 1, 255, 255, 255, true);
end

local function registerAuras(self)
    -- Backlash
    self:RegisterAura("backlash", 0, 34936, "backlash", "Top", 1, 255, 255, 255, true);

    -- Empowered Imp
    self:RegisterAura("empowered_imp", 0, 47283, "imp_empowerment", "Left + Right (Flipped)", 1, 255, 255, 255, true);

    -- Molten Core
    registerMolenCore(self, "molten_core_low", 47383); -- 1/3 talent point
    registerMolenCore(self, "molten_core_medium", 71162); -- 2/3 talent points
    registerMolenCore(self, "molten_core_high", 71165); -- 3/3 talent points

    -- Nightfall / Shadow Trance
    self:RegisterAura("nightfall", 0, 17941, "nightfall", "Left + Right (Flipped)", 1, 255, 255, 255, true);
end

SAO.Class["WARLOCK"] = {
    ["Register"] = registerAuras,
}
