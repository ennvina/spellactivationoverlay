local AddonName, SAO = ...

local function customLogin(self, ...)
    -- Must initialize class on PLAYER_LOGIN instead of registerClass
    -- Because we need the talent tree, which is not always available right off the bat

    -- Register Riposte as both an aura and a counter
    -- Rogue does not really have a 'Riposte' aura, but it will be used by RegisterCounter
    local riposteSpellID = 14251;
    local riposteSpellName = GetSpellInfo(riposteSpellID);
    local _, _, tab, index = self:GetTalentByName(riposteSpellName);
    local talent = type(tab) == "number" and type(index) == "number" and { tab, index };
    self:RegisterAura("riposte", 0, riposteSpellID, "bandits_guile", "Top (CW)", 1, 255, 255, 255, true, { riposteSpellID });
    self:RegisterCounter("riposte", talent); -- Must match name from above call
end

local function registerClass(self)
    -- Nothing to do, because everything is done in customLogin()
end

SAO.Class["ROGUE"] = {
    ["Register"] = registerClass,
    ["PLAYER_LOGIN"] = customLogin,
}
