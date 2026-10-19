local AddonName, SAO = ...

-- Apply all values from the database to the engine
function SAO.ApplyAllVariables(self)
    self:ApplySpellAlertOpacity(true); -- true to force-apply the enabled state
    self:ApplySpellAlertGeometry();
    self:ApplySpellAlertTimer();
    self:ApplySpellAlertSound();
    self:ApplyGlowingButtonsToggle();
end

-- Apply spell alert opacity
function SAO.ApplySpellAlertOpacity(self, enableChanged)
    -- Change the main frame's visibility and opacity
    SpellActivationOverlayContainerFrame:SetShown(SpellActivationOverlayDB.alert.enabled);
    SpellActivationOverlayContainerFrame:SetAlpha(SpellActivationOverlayDB.alert.opacity);
    if enableChanged then
        SAO:ForEachBucket(function(bucket) bucket:checkOption() end);
    end
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
    local useSound = SpellActivationOverlayDB.alert.sound ~= 0;
    SpellActivationOverlayAddonFrame.useSound = useSound;
    SpellActivationOverlay_OnChangeSoundToggle(SpellActivationOverlayAddonFrame);
    SAO.AuraSoundLibrary:setGlobalEnabled(useSound);
end

-- Apply glowing buttons on/off
function SAO.ApplyGlowingButtonsToggle(self)
    -- @todo Find a way to only refresh spell alert when checking spell alert, or glowing button when clicking glowing button
    self:ForEachBucket(function(bucket)
        bucket:reset(); -- Reset hash to force re-display if needed
        bucket.trigger:manualCheckAll();
        bucket:checkOption();
    end);
end
