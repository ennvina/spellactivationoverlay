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
    scaleSlider:SetMinMaxValues(0.25, 2.5);
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
    glowingButtonCheckbox.ApplyValueToEngine = function(self, checked)
        SpellActivationOverlayDB.glow.enabled = checked;
        for _, checkbox in ipairs(SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes) do
            -- Additional glowing checkboxes are enabled/disabled depending on the main glowing checkbox
            checkbox:ApplyParentEnabling();
        end
        SAO:ApplyGlowingButtonsToggle();
    end

    local classOptions = SpellActivationOverlayDB.classes and SAO.CurrentClass and SpellActivationOverlayDB.classes[SAO.CurrentClass.Intrinsics[2]];
    if (classOptions) then
        SpellActivationOverlayOptionsPanel.classOptions = { initialValue = CopyTable(classOptions) };
    else
        SpellActivationOverlayOptionsPanel.classOptions = { initialValue = {} };
    end
end

-- User clicks OK to the options panel
local function okayFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.initialValue = opacitySlider:GetValue();

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider.initialValue = scaleSlider:GetValue();

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider.initialValue = offsetSlider:GetValue();

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox.initialValue = glowingButtonCheckbox:GetChecked();

    local classOptions = SpellActivationOverlayDB.classes and SAO.CurrentClass and SpellActivationOverlayDB.classes[SAO.CurrentClass.Intrinsics[2]];
    if (classOptions) then
        SpellActivationOverlayOptionsPanel.classOptions.initialValue = CopyTable(classOptions);
    end
end

-- User clicked Cancel to the options panel
local function cancelFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    local classOptions = SpellActivationOverlayOptionsPanel.classOptions;

    self:applyAll(
        opacitySlider.initialValue,
        scaleSlider.initialValue,
        offsetSlider.initialValue,
        glowingButtonCheckbox.initialValue,
        classOptions.initialValue
    );
end

-- User reset settings to default values
local function defaultFunc(self)
    local defaultClassOptions = SAO.defaults.classes and SAO.CurrentClass and SAO.defaults.classes[SAO.CurrentClass.Intrinsics[2]];
    self:applyAll(
        1, -- opacity
        1, -- scale
        0, -- offset
        true, -- glow
        defaultClassOptions -- class options
    );
end

local function applyAllFunc(self, opacityValue, scaleValue, offsetValue, isGlowEnabled, classOptions)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider:SetValue(opacityValue);
    if (SpellActivationOverlayDB.alert.opacity ~= opacityValue) then
        SpellActivationOverlayDB.alert.opacity = opacityValue;
        SpellActivationOverlayDB.alert.enabled = opacityValue > 0;
        SAO:ApplySpellAlertOpacity();
    end

    local geometryChanged = false;

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider:SetValue(scaleValue);
    if (SpellActivationOverlayDB.alert.scale ~= scaleValue) then
        SpellActivationOverlayDB.alert.scale = scaleValue;
        geometryChanged = true;
    end

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider:SetValue(offsetValue);
    if (SpellActivationOverlayDB.alert.offset ~= offsetValue) then
        SpellActivationOverlayDB.alert.offset = offsetValue;
        geometryChanged = true;
    end

    if (geometryChanged) then
        SAO:ApplySpellAlertGeometry();
    end

    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
    -- Enable/disable the test button with alert.enabled, which was set/reset a few lines above, alongside opacity
    testButton:SetEnabled(SpellActivationOverlayDB.alert.enabled);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox:SetChecked(isGlowEnabled);
    if (SpellActivationOverlayDB.glow.enabled ~= isGlowEnabled) then
        SpellActivationOverlayDB.glow.enabled = isGlowEnabled;
        SAO:ApplyGlowingButtonsToggle();
    end

    if (SpellActivationOverlayDB.classes and SAO.CurrentClass and SpellActivationOverlayDB.classes[SAO.CurrentClass.Intrinsics[2]] and classOptions) then
        SpellActivationOverlayDB.classes[SAO.CurrentClass.Intrinsics[2]] = CopyTable(classOptions);
        for _, checkbox in ipairs(SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes) do
            checkbox:ApplyValue();
        end
    end
end

function SpellActivationOverlayOptionsPanel_OnLoad(self)
    self.name = AddonName;
    self.okay = okayFunc;
    self.cancel = cancelFunc;
    self.default = defaultFunc;
    self.applyAll = applyAllFunc; -- not a callback used by Blizzard's InterfaceOptions_AddCategory, but used by us

    InterfaceOptions_AddCategory(self);

    SAO.OptionsPanel = self;
end

function SpellActivationOverlayOptionsPanel_OnShow(self)
    if (SAO.CurrentClass) then
        if (SAO.CurrentClass.LoadOptions) then
            SAO.CurrentClass.LoadOptions(SAO);
            SAO.CurrentClass.LoadOptions = nil; -- Reset callback so that it is not called again on next show
        end
    end
end

local function createOptionForGlow(classFile, spellID, glowID)
    local default = true;
    if (SAO.defaults.classes[classFile] and SAO.defaults.classes[classFile].glow and SAO.defaults.classes[classFile].glow[spellID]) then
        default = SAO.defaults.classes[classFile].glow[spellID][glowID];
    end
    if (not SpellActivationOverlayDB.classes) then
        SpellActivationOverlayDB.classes = { [classFile] = { glow = { [spellID] = { [glowID] = default } } } };
    elseif (not SpellActivationOverlayDB.classes[classFile]) then
        SpellActivationOverlayDB.classes[classFile] = { glow = { [spellID] = { [glowID] = default } } };
    elseif (not SpellActivationOverlayDB.classes[classFile].glow) then
        SpellActivationOverlayDB.classes[classFile].glow = { [spellID] = { [glowID] = default } };
    elseif (not SpellActivationOverlayDB.classes[classFile].glow[spellID]) then
        SpellActivationOverlayDB.classes[classFile].glow[spellID] = { [glowID] = default };
    elseif (type (SpellActivationOverlayDB.classes[classFile].glow[spellID][glowID]) == "nil") then
        SpellActivationOverlayDB.classes[classFile].glow[spellID][glowID] = default;
    end
end

function SAO.AddGlowingOption(self, subText, spellID, glowID)
    local className = self.CurrentClass.Intrinsics[1];
    local classFile = self.CurrentClass.Intrinsics[2];
    local cb = CreateFrame("CheckButton", nil, SpellActivationOverlayOptionsPanel, "InterfaceOptionsCheckButtonTemplate");

    cb.ApplyText = function(_, classColor)
        local text = WrapTextInColorCode(className, classColor);
        text = text.." "..GetSpellInfo(glowID);
        if (type(subText) == "number") then
            -- if subText is a number, this is a spellID, probably ID of the corresponding talent
            text = text.." ("..GetSpellInfo(subText)..")";
        elseif (type(subText) == "string") then
            -- if subText is a string, the caller wants to control what's inside the subtext
            text = text.." ("..subText..")";
        end
        cb.Text:SetText(text);
    end

    cb.ApplyParentEnabling = function()
        -- Enable/disable the checkbox if the parent (i.e. main "Glowing Buttons" checkbox) is checked or not
        if (SpellActivationOverlayDB.glow.enabled) then
            cb:SetEnabled(true);
            cb:ApplyText(select(4,GetClassColor(classFile)));
            cb.Text:SetTextColor(1, 1, 1);
        else
            cb:SetEnabled(false);
            local dimmedClassColor = CreateColor(0.5*RAID_CLASS_COLORS[classFile].r, 0.5*RAID_CLASS_COLORS[classFile].g, 0.5*RAID_CLASS_COLORS[classFile].b);
            cb:ApplyText(dimmedClassColor:GenerateHexColor());
            cb.Text:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    cb.ApplyValue = function()
        cb:SetChecked(SpellActivationOverlayDB.classes[classFile].glow[spellID][glowID]);
    end

    -- Init
    createOptionForGlow(classFile, spellID, glowID);
    cb:ApplyParentEnabling();
    cb:ApplyValue();

    cb:SetScript("PostClick", function()
        local checked = cb:GetChecked();
        SpellActivationOverlayDB.classes[classFile].glow[spellID][glowID] = checked;
    end);

    cb:SetSize(20, 20);

    if (type(SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes) == "nil") then
        -- The first additional glowing checkbox is anchored to the main "Glowing Buttons" checkbox
        cb:SetPoint("TOPLEFT", SpellActivationOverlayOptionsPanelGlowingButtons, "BOTTOMLEFT", 16, 2);
        SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes = { cb };
    else
        -- Each subsequent glowing checkbox is anchored to the previous one
        local lastCheckBox = SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes[#SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes];
        cb:SetPoint("TOPLEFT", lastCheckBox, "BOTTOMLEFT", 0, 0);
        table.insert(SpellActivationOverlayOptionsPanel.additionalGlowingCheckboxes, cb);
    end

    return cb;
end

SLASH_SAO1 = "/sao"
SLASH_SAO2 = "/spellactivationoverlay"

SlashCmdList.SAO = function(msg, editBox)
	-- https://github.com/Stanzilla/WoWUIBugs/issues/89
	InterfaceOptionsFrame_OpenToCategory(SAO.OptionsPanel);
	InterfaceOptionsFrame_OpenToCategory(SAO.OptionsPanel);
end
