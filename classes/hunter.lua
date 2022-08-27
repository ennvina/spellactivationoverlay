local AddonName, SAO = ...

local function registerClass(self)
    -- Improved Steady Shot, formerly Master Marksman
    self:RegisterAura("improved_steady_shot", 0, 53220, "master_marksman", "Top", 1, 255, 255, 255, true);

    -- Lock and Load, option 1: display something on top if there is at least one charge
    -- Advantage: easier to see
    -- Disadvantages: doesn't show the number of charges, may conflict with Improved Steady Shot
    self:RegisterAura("lock_and_load_1", 1, 56453, "lock_and_load", "Top", 1, 255, 255, 255, true);
    self:RegisterAura("lock_and_load_2", 2, 56453, "lock_and_load", "Top", 1, 255, 255, 255, true);

    -- Lock and Load, option 2: display the first charge on top-left and second charge on top-right
    -- Advantages: displays two charges, doesn't conflict with Improved Steady Shot
    -- Disadvantage: weird place to put them (smaller, away from the center)
    -- self:RegisterAura("lock_and_load", 1, 56453, "lock_and_load", "TopLeft", 1, 255, 255, 255, true);
    -- self:RegisterAura("lock_and_load_2left", 2, 56453, "lock_and_load", "TopLeft", 1, 255, 255, 255, true);
    -- self:RegisterAura("lock_and_load_2right", 2, 56453, "lock_and_load", "TopRight", 1, 255, 255, 255, true);
end

SAO.Class["HUNTER"] = {
    ["Register"] = registerClass,
}
