local AddonName, SAO = ...

function SpellActivationOverlayOptionsPanel_Init(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.Text:SetText("Spell Alert opacity");
    _G[opacitySlider:GetName().."Low"]:SetText(OFF);
    opacitySlider:SetMinMaxValues(0, 1);
    opacitySlider:SetValueStep(0.05);
    opacitySlider.initialValue = SpellActivationOverlayDB.alert.opacity;
    opacitySlider:SetValue(opacitySlider.initialValue);
    opacitySlider.ApplyValueToEngine = function(self, value)
        SpellActivationOverlayDB.alert.opacity = value;
        SpellActivationOverlayDB.alert.enabled = value > 0;
        SAO:ApplySpellAlertOpacity();
    end

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider.Text:SetText("Spell Alert scale");
    _G[scaleSlider:GetName().."Low"]:SetText(SMALL);
    _G[scaleSlider:GetName().."High"]:SetText(LARGE);
    scaleSlider:SetMinMaxValues(0.5, 2);
    scaleSlider:SetValueStep(0.05);
    scaleSlider.initialValue = SpellActivationOverlayDB.alert.scale;
    scaleSlider:SetValue(scaleSlider.initialValue);
    scaleSlider.ApplyValueToEngine = function(self, value)
        SpellActivationOverlayDB.alert.scale = value;
        SAO:ApplySpellAlertGeometry();
    end

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider.Text:SetText("Spell Alert offset");
    _G[offsetSlider:GetName().."Low"]:SetText(NEAR);
    _G[offsetSlider:GetName().."High"]:SetText(FAR);
    offsetSlider:SetMinMaxValues(-200, 400);
    offsetSlider:SetValueStep(20);
    offsetSlider.initialValue = SpellActivationOverlayDB.alert.offset;
    offsetSlider:SetValue(offsetSlider.initialValue);
    offsetSlider.ApplyValueToEngine = function(self, value)
        SpellActivationOverlayDB.alert.offset = value;
        SAO:ApplySpellAlertGeometry();
    end

    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
    testButton:SetText("Toggle Test");
    testButton.fakeSpellID = 42;
    testButton.isTesting = false;
    testButton.StartTest = function(self)
        if (not self.isTesting) then
            self.isTesting = true;
            SAO:ActivateOverlay(0, self.fakeSpellID, SAO.TexName["imp_empowerment"], "Left + Right (Flipped)", 1, 255, 255, 255, false);
            SAO:ActivateOverlay(0, self.fakeSpellID, SAO.TexName["brain_freeze"], "Top", 1, 255, 255, 255, false);
            -- Hack the frame to force full opacity even when out of combat
            SpellActivationOverlayFrame.disableDimOutOfCombat = true;
            SpellActivationOverlayFrame:SetAlpha(1);
        end
    end
    testButton.StopTest = function(self)
        if (self.isTesting) then
            self.isTesting = false;
            SAO:DeactivateOverlay(self.fakeSpellID);
            -- Undo hack
            SpellActivationOverlayFrame.disableDimOutOfCombat = nil;
            if (not InCombatLockdown()) then
                SpellActivationOverlayFrame.combatAnimOut:Play();
            end
        end
    end
    testButton:SetEnabled(SpellActivationOverlayDB.alert.enabled);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox.Text:SetText("Glowing Buttons");
    glowingButtonCheckbox.initialValue = SpellActivationOverlayDB.glow.enabled;
    glowingButtonCheckbox:SetChecked(glowingButtonCheckbox.initialValue);
end

-- User clicks OK to the options panel
local function okayFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.initialValue = opacitySlider:GetValue();
    -- SAO:ApplySpellAlertOpacity(); -- Not necessary because this option is interactive

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider.initialValue = scaleSlider:GetValue();
    -- SAO:ApplySpellAlertGeometry(); -- Not necessary because this option is interactive

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider.initialValue = offsetSlider:GetValue();
    -- SAO:ApplySpellAlertGeometry(); -- Not necessary because this option is interactive

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox.initialValue = glowingButtonCheckbox:GetChecked();
    SAO:ApplyGlowingButtonsToggle();
end

-- User clicked Cancel to the options panel
local function cancelFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider:SetValue(opacitySlider.initialValue);
    if (SpellActivationOverlayDB.alert.opacity ~= opacitySlider.initialValue) then
        SpellActivationOverlayDB.alert.opacity = opacitySlider.initialValue;
        SpellActivationOverlayDB.alert.enabled = opacitySlider.initialValue > 0;
        SAO:ApplySpellAlertOpacity();
    end

    local geometryChanged = false;

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider:SetValue(scaleSlider.initialValue);
    if (SpellActivationOverlayDB.alert.scale ~= scaleSlider.initialValue) then
        SpellActivationOverlayDB.alert.scale = scaleSlider.initialValue;
        geometryChanged = true;
    end

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider:SetValue(offsetSlider.initialValue);
    if (SpellActivationOverlayDB.alert.offset ~= offsetSlider.initialValue) then
        SpellActivationOverlayDB.alert.offset = offsetSlider.initialValue;
        geometryChanged = true;
    end

    if (geometryChanged) then
        SAO:ApplySpellAlertGeometry();
    end

    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
    -- Enable/disable the test button with alert.enabled, which was set/reset a few lines above, alongside opacity
    testButton:SetEnabled(SpellActivationOverlayDB.alert.enabled);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox:SetChecked(glowingButtonCheckbox.initialValue);
    -- Not necessary because this option is non-interactive
    --if (SpellActivationOverlayDB.glow.enabled ~= glowingButtonCheckbox.initialValue) then
    --    SpellActivationOverlayDB.glow.enabled = glowingButtonCheckbox.initialValue;
    --    SAO:ApplyGlowingButtonsToggle();
    --end
    end

function SpellActivationOverlayOptionsPanel_OnLoad(self)
    self.name = AddonName;
    self.okay = okayFunc;
    self.cancel = cancelFunc;

    InterfaceOptions_AddCategory(self);

    SAO.OptionsPanel = self;
end
