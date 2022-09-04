local AddonName, SAO = ...

function SpellActivationOverlayOptionsPanel_Init(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.Text:SetText("Spell Alert opacity");
    _G[opacitySlider:GetName().."Low"]:SetText(OFF);
    opacitySlider:SetMinMaxValues(0, 1);
    opacitySlider:SetValueStep(0.05);

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
