local AddonName, SAO = ...

function SpellActivationOverlayOptionsPanel_Init(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.Text:SetText("Spell Alert opacity");
    _G[opacitySlider:GetName().."Low"]:SetText(OFF);
    opacitySlider:SetMinMaxValues(0, 1);
    opacitySlider:SetValueStep(0.05);

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider.Text:SetText("Spell Alert scale");
    _G[scaleSlider:GetName().."Low"]:SetText(SMALL);
    _G[scaleSlider:GetName().."High"]:SetText(LARGE);
    scaleSlider:SetMinMaxValues(0.5, 2);
    scaleSlider:SetValueStep(0.05);

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider.Text:SetText("Spell Alert offset");
    _G[offsetSlider:GetName().."Low"]:SetText(NEAR);
    _G[offsetSlider:GetName().."High"]:SetText(FAR);
    offsetSlider:SetMinMaxValues(-200, 400);
    offsetSlider:SetValueStep(20);

    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
    testButton:SetText("Toggle Test");
    testButton.fakeSpellID = 42;
    testButton.isTesting = false;
    testButton.StartTest = function(self)
        if (not self.isTesting) then
            self.isTesting = true;
            SAO:ActivateOverlay(0, self.fakeSpellID, SAO.TexName["imp_empowerment"], "Left + Right (Flipped)", 1, 255, 255, 255, false);
            SAO:ActivateOverlay(0, self.fakeSpellID, SAO.TexName["brain_freeze"], "Top", 1, 255, 255, 255, false);
        end
    end
    testButton.StopTest = function(self)
        if (self.isTesting) then
            self.isTesting = false;
            SAO:DeactivateOverlay(self.fakeSpellID);
        end
    end

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox.Text:SetText("Glowing Buttons");

    -- Hack to apply database variables to UI elements
    self.cancel();
end

-- User clicks OK to the options panel
local function okayFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    if (SpellActivationOverlayDB.alert.opacity ~= opacitySlider:GetValue()) then
        SpellActivationOverlayDB.alert.opacity = opacitySlider:GetValue();
        SAO.ApplySpellAlertOpacity();
    end

    local geometryChanged = false;

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    if (SpellActivationOverlayDB.alert.scale ~= scaleSlider:GetValue()) then
        SpellActivationOverlayDB.alert.scale = scaleSlider:GetValue();
        geometryChanged = true;
    end

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    if (SpellActivationOverlayDB.alert.offset ~= offsetSlider:GetValue()) then
        SpellActivationOverlayDB.alert.offset = offsetSlider:GetValue();
        geometryChanged = true;
    end

    if (geometryChanged) then
        SAO.ApplySpellAlertGeometry();
    end

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    if (SpellActivationOverlayDB.glow.enabled ~= glowingButtonCheckbox:GetChecked()) then
        SpellActivationOverlayDB.glow.enabled = glowingButtonCheckbox:GetChecked();
        SAO.ApplyGlowingButtonsToggle();
    end
    end

-- User clicked Cancel to the options panel
local function cancelFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
        opacitySlider:SetValue(SpellActivationOverlayDB.alert.opacity);

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider:SetValue(SpellActivationOverlayDB.alert.scale);

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider:SetValue(SpellActivationOverlayDB.alert.offset);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
        glowingButtonCheckbox:SetChecked(SpellActivationOverlayDB.glow.enabled);
    end

function SpellActivationOverlayOptionsPanel_OnLoad(self)
    self.name = AddonName;
    self.okay = okayFunc;
    self.cancel = cancelFunc;

    InterfaceOptions_AddCategory(self);

    SAO.OptionsPanel = self;
end
