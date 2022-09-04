local Addon, SAO = ...

function SpellActivationOverlayOptionsPanel_Init(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.Text:SetText("Spell Alert opacity");
    _G[opacitySlider:GetName().."Low"]:SetText(OFF);
    opacitySlider:SetMinMaxValues(0, 1);
    opacitySlider:SetValueStep(0.05);
    opacitySlider:SetValue(SpellActivationOverlayDB.alert.opacity);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox.Text:SetText("Glowing Buttons");
    glowingButtonCheckbox:SetChecked(SpellActivationOverlayDB.glow.enabled);
end

function SpellActivationOverlayOptionsPanel_OnLoad(self)
    self.name = Addon;

    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;

    self.okay = function(self)
        SpellActivationOverlayDB.alert.opacity = opacitySlider:GetValue();

        SpellActivationOverlayDB.glow.enabled = glowingButtonCheckbox:GetChecked();

        -- TODO also apply values in the SAO/GAB engine
    end

    self.cancel = function(self)
        opacitySlider:SetValue(SpellActivationOverlayDB.alert.opacity);

        glowingButtonCheckbox:SetChecked(SpellActivationOverlayDB.glow.enabled);
    end

    InterfaceOptions_AddCategory(self);
end
