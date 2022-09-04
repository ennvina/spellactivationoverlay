local AddonName, SAO = ...

-- Apply all values from the database to the engine
function SAO.ApplyAllVariables(self)
    self:ApplySpellAlertOpacity();
    self:ApplyGlowingButtonsToggle();
end

-- Apply spell alert opacity
function SAO.ApplySpellAlertOpacity(self)
    -- Change the main frame's opacity and adjust in-combat and out-of-combat animation transparency
    SpellActivationOverlayContainerFrame:SetAlpha(SpellActivationOverlayDB.alert.opacity);
end

-- Apply glowing buttons on/off
function SAO.ApplyGlowingButtonsToggle(self)
    -- Don't do anything
    -- Buttons will stop glowing by themselves, and will never light up again

    -- A better function would be to stop glowing / start glowing now
    -- But this would be more complex to code, and the benefit is minimal
end
