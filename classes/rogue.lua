local AddonName, SAO = ...

local riposteSpellID = 14251;

local isRiposteActive = false;

local function customSpellUpdate(self, ...)
    local isRiposteUsable = IsUsableSpell(riposteSpellID);

    if (not isRiposteActive and isRiposteUsable) then
        isRiposteActive = true;
        self:ActivateOverlay(0, riposteSpellID, self.TexName["rime"], "Top", 1, 255, 255, 255, true);
        self:AddGlow(riposteSpellID, {riposteSpellID}); -- Same spell ID, because there is no 'aura'
    elseif (isRiposteActive and not isRiposteUsable) then
        isRiposteActive = false;
        self:DeactivateOverlay(riposteSpellID);
        self:RemoveGlow(riposteSpellID);
    end
end

local function registerClass(self)
    -- Register Riposte's spell ID
    SAO.RegisteredGlowIDs[riposteSpellID] = true;
end

SAO.Class["ROGUE"] = {
    ["Register"] = registerClass,
    ["SPELL_UPDATE_USABLE"] = customSpellUpdate,
}
