local AddonName, SAO = ...

local function createOptionFor(classFile, optionType, auraID, id)
    local default = true;
    if (SAO.defaults.classes[classFile] and SAO.defaults.classes[classFile][optionType] and SAO.defaults.classes[classFile][optionType][auraID]) then
        default = SAO.defaults.classes[classFile][optionType][auraID][id];
    end
    if (not SpellActivationOverlayDB.classes) then
        SpellActivationOverlayDB.classes = { [classFile] = { [optionType] = { [auraID] = { [id] = default } } } };
    elseif (not SpellActivationOverlayDB.classes[classFile]) then
        SpellActivationOverlayDB.classes[classFile] = { [optionType] = { [auraID] = { [id] = default } } };
    elseif (not SpellActivationOverlayDB.classes[classFile][optionType]) then
        SpellActivationOverlayDB.classes[classFile][optionType] = { [auraID] = { [id] = default } };
    elseif (not SpellActivationOverlayDB.classes[classFile][optionType][auraID]) then
        SpellActivationOverlayDB.classes[classFile][optionType][auraID] = { [id] = default };
    elseif (type (SpellActivationOverlayDB.classes[classFile][optionType][auraID][id]) == "nil") then
        SpellActivationOverlayDB.classes[classFile][optionType][auraID][id] = default;
    end
end

function SAO.AddOption(self, optionType, auraID, id, applyTextFunc, firstAnchor)
    local classFile = self.CurrentClass.Intrinsics[2];
    local cb = CreateFrame("CheckButton", nil, SpellActivationOverlayOptionsPanel, "InterfaceOptionsCheckButtonTemplate");

    cb.ApplyText = applyTextFunc;

    cb.ApplyParentEnabling = function()
        -- Enable/disable the checkbox if the parent (i.e. main "Glowing Buttons" checkbox) is checked or not
        if (SpellActivationOverlayDB[optionType].enabled) then
            cb:SetEnabled(true);
            cb:ApplyText();
        else
            cb:SetEnabled(false);
            cb:ApplyText();
        end
    end

    cb.ApplyValue = function()
        cb:SetChecked(SpellActivationOverlayDB.classes[classFile][optionType][auraID][id]);
    end

    -- Init
    createOptionFor(classFile, optionType, auraID, id);
    cb:ApplyParentEnabling();
    cb:ApplyValue();

    cb:SetScript("PostClick", function()
        local checked = cb:GetChecked();
        SpellActivationOverlayDB.classes[classFile][optionType][auraID][id] = checked;
    end);

    cb:SetSize(20, 20);

    if (type(SpellActivationOverlayOptionsPanel.additionalCheckboxes[optionType]) == "nil") then
        -- The first additional glowing checkbox is anchored an initial widget
        cb:SetPoint("TOPLEFT", firstAnchor, "BOTTOMLEFT", 16, 2);
        SpellActivationOverlayOptionsPanel.additionalCheckboxes[optionType] = { cb };
    else
        -- Each subsequent glowing checkbox is anchored to the previous one
        local lastCheckBox = SpellActivationOverlayOptionsPanel.additionalCheckboxes[optionType][#SpellActivationOverlayOptionsPanel.additionalCheckboxes[optionType]];
        cb:SetPoint("TOPLEFT", lastCheckBox, "BOTTOMLEFT", 0, 0);
        table.insert(SpellActivationOverlayOptionsPanel.additionalCheckboxes[optionType], cb);
    end

    return cb;
end
