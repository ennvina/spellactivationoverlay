local AddonName, SAO = ...

-- Apply all values from the database to the engine
function SAO.ApplyAllVariables(self)
    self:ApplySpellAlertOpacity();
    self:ApplySpellAlertGeometry();
    self:ApplySpellAlertTimer();
    self:ApplySpellAlertSound();
    self:ApplyGlowingButtonsToggle();
end

-- Apply spell alert opacity
function SAO.ApplySpellAlertOpacity(self)
    -- Change the main frame's visibility and opacity
    SpellActivationOverlayContainerFrame:SetShown(SpellActivationOverlayDB.alert.enabled);
    SpellActivationOverlayContainerFrame:SetAlpha(SpellActivationOverlayDB.alert.opacity);
end

-- Apply spell alert geometry i.e., scale and offset
function SAO.ApplySpellAlertGeometry(self)
    SpellActivationOverlayAddonFrame.scale = SpellActivationOverlayDB.alert.scale;
    SpellActivationOverlayAddonFrame.offset = SpellActivationOverlayDB.alert.offset;
    SpellActivationOverlay_OnChangeGeometry(SpellActivationOverlayAddonFrame);
end

-- Apply spell alert progressive timer effect
function SAO.ApplySpellAlertTimer(self)
    SpellActivationOverlayAddonFrame.useTimer = SpellActivationOverlayDB.alert.timer ~= 0;
    SpellActivationOverlay_OnChangeTimerVisibility(SpellActivationOverlayAddonFrame);
end

-- Apply spell alert sound effects toggle
function SAO.ApplySpellAlertSound(self)
    SpellActivationOverlayAddonFrame.useSound = SpellActivationOverlayDB.alert.sound ~= 0;
    SpellActivationOverlay_OnChangeSoundToggle(SpellActivationOverlayAddonFrame);
end

-- Apply glowing buttons on/off
function SAO.ApplyGlowingButtonsToggle(self)
    -- @todo Find a way to only refresh spell alert when checking spell alert, or glowing button when clicking glowing button
    self:ForEachBucket(function(bucket)
        bucket:reset(); -- Reset hash to force re-display if needed
        bucket.trigger:manualCheckAll();
    end);
end
