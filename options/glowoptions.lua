local AddonName, SAO = ...

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

function SAO.AddGlowingOption(self, talentID, spellID, glowID, talentSubText, spellSubText)
    local className = self.CurrentClass.Intrinsics[1];
    local classFile = self.CurrentClass.Intrinsics[2];
    local cb = CreateFrame("CheckButton", nil, SpellActivationOverlayOptionsPanel, "InterfaceOptionsCheckButtonTemplate");

    cb.ApplyText = function(_, classColor)
        -- Class text
        local text = WrapTextInColorCode(className, classColor);

        -- Talent text
        local spellName, spellIcon;
        if (talentID) then
            spellName, _, spellIcon = GetSpellInfo(talentID);
            text = text.." |T"..spellIcon..":0|t "..spellName.." +"
            if (talentSubText) then
                text = text.." ("..talentSubText..")";
            end
        end

        -- Spell text
        spellName, _, spellIcon = GetSpellInfo(glowID);
        text = text.." |T"..spellIcon..":0|t "..spellName;
        if (spellSubText) then
            text = text.." ("..spellSubText..")";
        end

        -- Set final text to checkbox
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

function SAO.AddGlowingLink(self, srcOption, dstOption)
    if (not self.GlowingOptionLinks) then
        self.GlowingOptionLinks = { [dstOption] = srcOption };
    else
        self.GlowingOptionLinks[dstOption] = srcOption;
    end
end
