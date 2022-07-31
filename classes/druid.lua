local AddonName, SAO = ...

local omenSpellID = 16870;

local feralCache = false;
local clarityCache = false;

local function isFeral(self)
    local shapeshift = GetShapeshiftForm()
    return (shapeshift == 1) or (shapeshift == 3);
end

local function hasClarity(self)
    return self:FindPlayerAuraByID(omenSpellID) ~= nil;
end

local function activateOmen(self)
    local texture = feralCache and "feral_omenofclarity" or "natures_grace";
    self:ActivateOverlay(0, omenSpellID, self.TexName[texture], "Left + Right (Flipped)", 1, 255, 255, 255);
end

local function deactivateOmen(self)
    self:DeactivateOverlay(omenSpellID);
end

local function customLoad(self)
    feralCache = isFeral(self);
    clarityCache = hasClarity(self);
    if (clarityCache) then
        activateOmen(self);
    end
end

local function updateShapeshift(self)
    local newIsFeral = isFeral(self)
    if (feralCache ~= newIsFeral) then
        feralCache = newIsFeral;
        if (clarityCache) then
            activateOmen(self); -- Will update the texture
        end
    end
end

local function customCLEU(self, ...)
    local timestamp, event, _, sourceGUID, sourceName, sourceFlags, sourceRaidFlags, destGUID, destName, destFlags, destRaidFlags = CombatLogGetCurrentEventInfo() -- For all events

    -- Accept only certain events, and only when done by the player
    if (event ~= "SPELL_AURA_APPLIED" and event ~= "SPELL_AURA_REMOVED") then return end
    if (sourceGUID ~= UnitGUID("player")) then return end

    local spellID, spellName, spellSchool = select(12, CombatLogGetCurrentEventInfo()) -- For SPELL_*

    if (event == "SPELL_AURA_APPLIED") then
        if (spellID == omenSpellID) then
            clarityCache = true;
            activateOmen(self);
        end
        return;
    elseif (event == "SPELL_AURA_REMOVED") then
        if (spellID == omenSpellID) then
            clarityCache = false;
            deactivateOmen(self);
        end
        return;
    end
end

local function registerAuras(self)
    -- Track Omen of Clarity with a custom CLEU function, to be able to switch between feral and non-feral texture
    -- self:RegisterAura("omen_of_clarity", 0, 16870, "natures_grace", "Left + Right (Flipped)", 1, 255, 255, 255);
end

SAO.Class["DRUID"] = {
    ["Register"] = registerAuras,
    ["COMBAT_LOG_EVENT_UNFILTERED"] = customCLEU,
    ["UPDATE_SHAPESHIFT_FORM"] = updateShapeshift,
    ["PLAYER_ENTERING_WORLD"] = customLoad,
}
