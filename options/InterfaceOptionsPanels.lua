local AddonName, SAO = ...
local iamNecrosis = strlower(AddonName):sub(0,8) == "necrosis"

-- Optimize frequent calls
local GetAddOnMetadata = C_AddOns and C_AddOns.GetAddOnMetadata or GetAddOnMetadata

function SpellActivationOverlayOptionsPanel_Init(self)
    local shutdownCategory = SAO.Shutdown:GetCategory();
    if shutdownCategory then
        -- Apply shutdown settings before enything else, in case init fails precisely because of why the addon was shut down
        if shutdownCategory.Reason then
            local globalOffReason = SpellActivationOverlayOptionsPanel.globalOff.reason;
            globalOffReason:SetText("("..shutdownCategory.Reason..")");
        end

        if shutdownCategory.Button then
            local globalOffButton = SpellActivationOverlayOptionsPanel.globalOff.button;
            globalOffButton:SetText(shutdownCategory.Button.Text);
            local estimatedWidth = (2+strlenutf8(shutdownCategory.Button.Text))*8;
            globalOffButton:SetWidth(estimatedWidth);
            if estimatedWidth > 48 then
                globalOffButton:SetHeight(globalOffButton:GetHeight()+ceil((estimatedWidth-32)/16));
            end
            globalOffButton:SetScript("OnClick", shutdownCategory.Button.OnClick);
            globalOffButton:Show();
        end

        if shutdownCategory.DisableCondition then
            local disableCondition = SAO.Shutdown:GetCategory().DisableCondition;
            local disableConditionButton = SpellActivationOverlayOptionsPanelDisableConditionButton;
            disableConditionButton.Text:SetText(disableCondition.Text);
            disableConditionButton.OnValueChanged = function(self, checked)
                if checked then
                    disableCondition.OnValueChanged(self, true);
                    SpellActivationOverlayOptionsPanel.globalOff:Show();
                    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
                    if testButton.isTesting then
                        testButton:StopTest();
                    end
                else
                    disableCondition.OnValueChanged(self, false);
                    SpellActivationOverlayOptionsPanel.globalOff:Hide();
                end
            end
            disableConditionButton:SetChecked(SAO.Shutdown:IsAddonDisabled());
            disableConditionButton:OnValueChanged(disableConditionButton:GetChecked());
            if disableCondition.ShowIf == nil or disableCondition.ShowIf() then
                disableConditionButton:Show();
            end
        else
            -- Without disable condition, disabling is absolute
            SpellActivationOverlayOptionsPanel.globalOff:Show();
        end
    end

    local buildInfoLabel = SpellActivationOverlayOptionsPanelBuildInfo;
    local xSaoBuild = GetAddOnMetadata(AddonName, "X-SAO-Build");
    if type(xSaoBuild) == 'string' and #xSaoBuild > 0 then -- X-SAO-Build is defined only for the original SAO addon, not for other builds such as Necrosis
        local titleText = GetAddOnMetadata(AddonName, "Title");
        if xSaoBuild == "universal" then
            -- Universal build is compatible with everything
            local universalText = SAO:gradientText(
                SAO:universalBuild(),
                {
                    {r=0.1, g=1, b=0.3}, -- green (start)
                    {r=1, g=1, b=0.5},   -- yellow
                    {r=0.9, g=0.1, b=0}, -- red
                    {r=0.7, g=0, b=0.8}, -- purple
                    {r=0, g=0.3, b=1},   -- blue (end)
                }
            );
            buildInfoLabel:SetText(titleText.."\n"..universalText);
        elseif xSaoBuild == "dev" then
            -- Developer build is compatible with everything
            local buildForDevs = SAO:gradientText(
                "Build for Developers", -- Do not translate, assume all developers understand English
                {
                    {r=0, g=0.3, b=1}, -- blue (start)
                    {r=1, g=1, b=1},   -- white
                    {r=0, g=0.3, b=1}, -- blue (end)
                }
            );
            buildInfoLabel:SetText(titleText.."\n"..buildForDevs);
        else
            -- Optimized build, must check compatibility
            local addonBuild = SAO.GetFullProjectName(xSaoBuild);
            local expectedBuild = SAO.GetFullProjectName(SAO.GetExpectedBuildID());
            if addonBuild ~= expectedBuild then
                titleText = WrapTextInColorCode(titleText, "ffff0000");
                addonBuild = WrapTextInColorCode(addonBuild, "ffff0000");
                expectedBuild = WrapTextInColorCode(expectedBuild, "ffff0000");
                buildInfoLabel:SetFontObject(GameFontNormalLarge);
                SAO:Info("", SAO:compatibilityWarning(addonBuild, expectedBuild));
            end

            local optimizedForText;
            if xSaoBuild == "vanilla" then
                if addonBuild == expectedBuild then
                    optimizedForText = SAO:optimizedFor(BNET_FRIEND_TOOLTIP_WOW_CLASSIC);
                else
                    optimizedForText = SAO:optimizedFor(WrapTextInColorCode(BNET_FRIEND_TOOLTIP_WOW_CLASSIC, "ffff0000"));
                end
            else
                optimizedForText = SAO:optimizedFor(string.format(BNET_FRIEND_ZONE_WOW_CLASSIC, addonBuild));
            end

            buildInfoLabel:SetText(titleText.."\n"..optimizedForText);
        end
    end

    local classInfoLabel = SpellActivationOverlayOptionsPanelClassInfo;
    if SAO.CurrentClass then
        local className, classFile, classId = SAO.CurrentClass.Intrinsics[1], SAO.CurrentClass.Intrinsics[2], SAO.CurrentClass.Intrinsics[3];
        local gradientColors;
        if classFile == "PRIEST" then
            -- Special case for Priest, use a different gradient
            -- Because their class color is white, it is not possible to make it brighter
            gradientColors = {
                {r=0.8, g=0.8, b=0.8}, -- gray (start)
                RAID_CLASS_COLORS[classFile], -- Priest white
                {r=0.9, g=0.9, b=0.9}, -- gray (middle)
                {r=0.7, g=0.7, b=0.7}, -- gray (end)
            };
        else
            -- Gradient for all classes but Priest
            local function mixColors(color1, color2, t)
                return {
                    r = color1.r * (1 - t) + color2.r * t,
                    g = color1.g * (1 - t) + color2.g * t,
                    b = color1.b * (1 - t) + color2.b * t,
                };
            end
            local classColor = RAID_CLASS_COLORS[classFile];
            gradientColors = {
                classColor,
                mixColors(classColor, {r=1, g=1, b=1}, 0.25), -- Moderately lighter
                classColor,
                mixColors(classColor, {r=0, g=0, b=0}, 0.15), -- Slightly darker
            };
        end
        local classIcons = {
            ["DEATHKNIGHT"] = "Interface/Icons/Spell_Deathknight_ClassIcon",
            ["DRUID"] = "Interface/Icons/ClassIcon_Druid",
            ["HUNTER"] = "Interface/Icons/ClassIcon_Hunter",
            ["MAGE"] = "Interface/Icons/ClassIcon_Mage",
            ["MONK"] = "Interface/Icons/ClassIcon_Monk",
            ["PALADIN"] = "Interface/Icons/ClassIcon_Paladin",
            ["PRIEST"] = "Interface/Icons/ClassIcon_Priest",
            ["ROGUE"] = "Interface/Icons/ClassIcon_Rogue",
            ["SHAMAN"] = "Interface/Icons/ClassIcon_Shaman",
            ["WARLOCK"] = "Interface/Icons/ClassIcon_Warlock",
            ["WARRIOR"] = "Interface/Icons/ClassIcon_Warrior",
        };
        local classIcon = classIcons[classFile] or "Interface/Icons/INV_Misc_QuestionMark";
        local classText = SAO:gradientText(className, gradientColors);
        classInfoLabel:SetText(string.format("|T%s:16:16:0:0:512:512:32:480:32:480|t %s", classIcon, classText));
    else
        -- If CurrentClass is nil, it means the class is not supported
        -- We could get the class from UnitClass("player"), but that's not the point of this label
        -- This label is supposed to reflect what was loaded for the current class
        -- If the class is not supported, it does not make much sense to tell "here is what we've got for this class"
        classInfoLabel:SetText("");
    end

    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.Text:SetText(SPELL_ALERT_OPACITY);
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
    scaleSlider.Text:SetText("Spell Alert Scale");
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
    offsetSlider.Text:SetText("Spell Alert Offset");
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

    local timerSlider = SpellActivationOverlayOptionsPanelSpellAlertTimerSlider;
    timerSlider.Text:SetText("Spell Alert Progressive Timer");
    _G[timerSlider:GetName().."Low"]:SetText(DISABLE);
    _G[timerSlider:GetName().."High"]:SetText(ENABLE);
    timerSlider:SetMinMaxValues(0, 1);
    timerSlider:SetValueStep(1);
    timerSlider.initialValue = SpellActivationOverlayDB.alert.timer;
    timerSlider:SetValue(timerSlider.initialValue);
    timerSlider.ApplyValueToEngine = function(self, value)
        SpellActivationOverlayDB.alert.timer = value;
        SAO:ApplySpellAlertTimer();
    end

    local soundSlider = SpellActivationOverlayOptionsPanelSpellAlertSoundSlider;
    soundSlider.Text:SetText("Spell Alert Sound Effect");
    _G[soundSlider:GetName().."Low"]:SetText(DISABLE);
    _G[soundSlider:GetName().."High"]:SetText(ENABLE);
    soundSlider:SetMinMaxValues(0, 1);
    soundSlider:SetValueStep(1);
    soundSlider.initialValue = SpellActivationOverlayDB.alert.sound;
    soundSlider:SetValue(soundSlider.initialValue);
    soundSlider.ApplyValueToEngine = function(self, value)
        SpellActivationOverlayDB.alert.sound = value;
        SAO:ApplySpellAlertSound();
    end

    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
    testButton:SetText("Toggle Test");
    testButton.fakeSpellID = 42;
    testButton.isTesting = false;
    local testTextureLeftRight = SAO.IsEra() and "echo_of_the_elements" or "imp_empowerment";
    local testTextureTop = SAO.IsEra() and "fury_of_stormrage" or "brain_freeze";
    local testPositionTop = SAO.IsCata() and "Top (CW)" or "Top";
    testButton.StartTest = function(self)
        if (not self.isTesting) then
            self.isTesting = true;
            -- Test with strata = "DIALOG" to see above the options panel itself
            -- Test with level = 9999, slightly below the cap of 10000, to let overlay previews have priority about the Toggle Test feature
            SAO:ActivateOverlay(0, self.fakeSpellID, SAO.TexName[testTextureLeftRight], "Left + Right (Flipped)", 1, 255, 255, 255, false, nil, GetTime()+5, false, { strata = "DIALOG", level = 9999 });
            SAO:ActivateOverlay(0, self.fakeSpellID, SAO.TexName[testTextureTop]      , testPositionTop         , 1, 255, 255, 255, false, nil, GetTime()+5, false, { strata = "DIALOG", level = 9999 });
            self.testTimerTicker = C_Timer.NewTicker(4.9, -- Ticker must be slightly shorter than overlay duration, to refresh it before losing it
            function()
                SAO:RefreshOverlayTimer(self.fakeSpellID, GetTime()+5);
            end);
            -- Hack the frame to force full opacity even when out of combat
            SpellActivationOverlayFrame_SetForceAlpha1(true);
        end
    end
    testButton.StopTest = function(self)
        if (self.isTesting) then
            self.isTesting = false;
            self.testTimerTicker:Cancel();
            SAO:DeactivateOverlay(self.fakeSpellID);
            -- Undo hack
            SpellActivationOverlayFrame_SetForceAlpha1(false);
        end
    end
    testButton:SetEnabled(SpellActivationOverlayDB.alert.enabled);
    -- Manually mark textures used for testing
    SAO:MarkTexture(testTextureLeftRight);
    SAO:MarkTexture(testTextureTop);

    local debugButton = SpellActivationOverlayOptionsPanelSpellAlertDebugButton;
    debugButton.Text:SetText("Write Debug to Chatbox");
    debugButton:SetChecked(SpellActivationOverlayDB.debug == true);

    local reportButton = SpellActivationOverlayOptionsPanelSpellAlertReportButton;
    if SAO:CanReport() then
        reportButton.Text:SetText("Report unsupported effects to Chatbox");
        reportButton:SetChecked(SpellActivationOverlayDB.report ~= false); -- Default to true
    else
        reportButton:Hide();
    end

    local responsiveButton = SpellActivationOverlayOptionsPanelSpellAlertResponsiveButton;
    responsiveButton.Text:SetText(SAO:responsiveMode());
    responsiveButton:SetChecked(SpellActivationOverlayDB.responsiveMode == true);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox.Text:SetText("Glowing Buttons");
    glowingButtonCheckbox.initialValue = SpellActivationOverlayDB.glow.enabled;
    glowingButtonCheckbox:SetChecked(glowingButtonCheckbox.initialValue);
    glowingButtonCheckbox.ApplyValueToEngine = function(self, checked)
        SpellActivationOverlayDB.glow.enabled = checked;
        for _, checkbox in ipairs(SpellActivationOverlayOptionsPanel.additionalCheckboxes.glow or {}) do
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

    SpellActivationOverlayOptionsPanel.additionalCheckboxes = {};
end

-- User clicks OK to the options panel
local function okayFunc(self)
    local opacitySlider = SpellActivationOverlayOptionsPanelSpellAlertOpacitySlider;
    opacitySlider.initialValue = opacitySlider:GetValue();

    local scaleSlider = SpellActivationOverlayOptionsPanelSpellAlertScaleSlider;
    scaleSlider.initialValue = scaleSlider:GetValue();

    local offsetSlider = SpellActivationOverlayOptionsPanelSpellAlertOffsetSlider;
    offsetSlider.initialValue = offsetSlider:GetValue();

    local timerSlider = SpellActivationOverlayOptionsPanelSpellAlertTimerSlider;
    timerSlider.initialValue = timerSlider:GetValue();

    local soundSlider = SpellActivationOverlayOptionsPanelSpellAlertSoundSlider;
    soundSlider.initialValue = soundSlider:GetValue();

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
    local timerSlider = SpellActivationOverlayOptionsPanelSpellAlertTimerSlider;
    local soundSlider = SpellActivationOverlayOptionsPanelSpellAlertSoundSlider;
    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    local classOptions = SpellActivationOverlayOptionsPanel.classOptions;

    self:applyAll(
        opacitySlider.initialValue,
        scaleSlider.initialValue,
        offsetSlider.initialValue,
        timerSlider.initialValue,
        soundSlider.initialValue,
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
        1, -- timer
        SAO.IsCata() and 1 or 0, -- sound
        true, -- glow
        defaultClassOptions -- class options
    );
end

local function applyAllFunc(self, opacityValue, scaleValue, offsetValue, timerValue, soundValue, isGlowEnabled, classOptions)
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

    local timerSlider = SpellActivationOverlayOptionsPanelSpellAlertTimerSlider;
    timerSlider:SetValue(timerValue);
    if (SpellActivationOverlayDB.alert.timer ~= timerValue) then
        SpellActivationOverlayDB.alert.timer = timerValue;
        SAO:ApplySpellAlertTimer();
    end

    local soundSlider = SpellActivationOverlayOptionsPanelSpellAlertSoundSlider;
    soundSlider:SetValue(soundValue);
    if (SpellActivationOverlayDB.alert.sound ~= soundValue) then
        SpellActivationOverlayDB.alert.sound = soundValue;
        SAO:ApplySpellAlertSound();
    end

    local testButton = SpellActivationOverlayOptionsPanelSpellAlertTestButton;
    -- Enable/disable the test button with alert.enabled, which was set/reset a few lines above, alongside opacity
    testButton:SetEnabled(SpellActivationOverlayDB.alert.enabled);

    local glowingButtonCheckbox = SpellActivationOverlayOptionsPanelGlowingButtons;
    glowingButtonCheckbox:SetChecked(isGlowEnabled);
    if (SpellActivationOverlayDB.glow.enabled ~= isGlowEnabled) then
        SpellActivationOverlayDB.glow.enabled = isGlowEnabled;
        glowingButtonCheckbox:ApplyValueToEngine(isGlowEnabled);
    end

    if (SpellActivationOverlayDB.classes and SAO.CurrentClass and SpellActivationOverlayDB.classes[SAO.CurrentClass.Intrinsics[2]] and classOptions) then
        SpellActivationOverlayDB.classes[SAO.CurrentClass.Intrinsics[2]] = CopyTable(classOptions);
        for _, checkbox in ipairs(SpellActivationOverlayOptionsPanel.additionalCheckboxes.alert or {}) do
            checkbox:ApplyValue();
        end
        for _, checkbox in ipairs(SpellActivationOverlayOptionsPanel.additionalCheckboxes.glow or {}) do
            checkbox:ApplyValue();
        end
    end
end

local InterfaceOptions_AddCategory = InterfaceOptions_AddCategory
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory

if Settings and Settings.RegisterCanvasLayoutCategory then
    --[[ Deprecated. 
    See Blizzard_ImplementationReadme.lua for recommended setup.
    ]]
    InterfaceOptions_AddCategory = function(frame, addOn, position)
        -- cancel is no longer a default option. May add menu extension for this.
        frame.OnCommit = frame.okay;
        frame.OnDefault = frame.default;
        frame.OnRefresh = frame.refresh;

        if frame.parent then
            local category = Settings.GetCategory(frame.parent);
            local subcategory, layout = Settings.RegisterCanvasLayoutSubcategory(category, frame, frame.name, frame.name);
            subcategory.ID = frame.name;
            return subcategory, category;
        else
            local category, layout = Settings.RegisterCanvasLayoutCategory(frame, frame.name, frame.name);
            category.ID = frame.name;
            Settings.RegisterAddOnCategory(category);
            return category;
        end
    end

    -- Deprecated. Use Settings.OpenToCategory().
    InterfaceOptionsFrame_OpenToCategory = function(categoryIDOrFrame)
        if type(categoryIDOrFrame) == "table" then
            local categoryID = categoryIDOrFrame.name;
            return Settings.OpenToCategory(categoryID);
        else
            return Settings.OpenToCategory(categoryIDOrFrame);
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

local optionsLoaded = false; -- Make sure we do not load the options panel twice
function SpellActivationOverlayOptionsPanel_OnShow(self)
    if optionsLoaded then
        return;
    end

    if SAO.CurrentClass and type(SAO.CurrentClass.LoadOptions) == 'function' then
        SAO.CurrentClass.LoadOptions(SAO);
    end

    SAO:AddEffectOptions();

    for _, optionType in ipairs({ "alert", "glow" }) do
        if (type(SpellActivationOverlayOptionsPanel.additionalCheckboxes[optionType]) == "nil") then
            local className = SAO.CurrentClass and SAO.CurrentClass.Intrinsics[1] or select(1, UnitClass("player"));
            local classFile = SAO.CurrentClass and SAO.CurrentClass.Intrinsics[2] or select(2, UnitClass("player"));
            local dimFactor = 0.7;
            local dimmedTextColor = CreateColor(dimFactor, dimFactor, dimFactor);
            local dimmedClassColor = CreateColor(dimFactor*RAID_CLASS_COLORS[classFile].r, dimFactor*RAID_CLASS_COLORS[classFile].g, dimFactor*RAID_CLASS_COLORS[classFile].b);
            local text = WrapTextInColor(string.format("%s (%s)", NONE, WrapTextInColor(className, dimmedClassColor)), dimmedTextColor);
            SpellActivationOverlayOptionsPanel[optionType.."None"]:SetText(text);
        end
    end

    optionsLoaded = true;
end

if not iamNecrosis then
    SLASH_SAO1 = "/sao"
    SLASH_SAO2 = "/spellactivationoverlay"
    SlashCmdList.SAO = function(msg, editBox)
        -- https://github.com/Stanzilla/WoWUIBugs/issues/89
        InterfaceOptionsFrame_OpenToCategory(SAO.OptionsPanel);
        InterfaceOptionsFrame_OpenToCategory(SAO.OptionsPanel);
    end
end
