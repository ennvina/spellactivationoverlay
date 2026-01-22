local AddonName, SAO = ...
local Module = "option"

-- Add a checkbox for a glowing button
-- talentID is the spell ID of the associated talent; can be nil, meaning the button does not glow depending on a talent; can be negative for specs instead of talents
-- spellID is the spell ID of the buff or action that triggers the button; if the button is a counter, spellID should match glowID
-- glowID is the spell ID of the button(s) that will glow
-- talentSubText is a string describing the specificity of this option, appended to talent text
-- spellSubText is a string describing the specificity of this option, appended to spell text
-- variants optional variant object that tells which are sub-options and how to use them
-- hash optional hash, used to describe what the display is expected to depend on
-- alwaysHideTalentText if true, the option will be hidden even when the talent does not match the glowID
-- @note Options must be linked asap, not during loadOptions() which would be loaded only when the options panel is opened
-- By linking options as soon as possible, before their respective RegisterAura() calls, options can be used by initial triggers, if any
function SAO.AddGlowingOption(self, talentID, spellID, glowID, talentSubText, spellSubText, variants, hash, alwaysHideTalentText) -- @todo use hash and testHash like overlay options
    local talentText = talentID and self:GetTalentText(talentID);
    if (talentID and not talentText) or (not self:IsFakeSpell(glowID) and not self:DoesSpellExist(glowID)) then
        if talentID and not talentText then
            SAO:Debug(Module, "Skipping glowing option of talentID "..tostring(talentID).." because the spell does not exist");
        end
        if not self:IsFakeSpell(glowID) and not self:DoesSpellExist(glowID) then
            SAO:Debug(Module, "Skipping glowing option of glowID "..tostring(glowID).." because the spell does not exist (and is not a fake spell)");
        end
        return;
    end

    local className = self.CurrentClass.Intrinsics[1];
    local classFile = self.CurrentClass.Intrinsics[2];

    local applyTextFunc = function(self)
        local retryApplyText = nil;
        local enabled = self:IsEnabled();

        -- Class text
        local text = "";
        -- No longer display the class name for each glowing button
        -- local classColor;
        -- if (enabled) then
        --     classColor = select(4,GetClassColor(classFile));
        -- else
        --     local dimmedClassColor = CreateColor(0.5*RAID_CLASS_COLORS[classFile].r, 0.5*RAID_CLASS_COLORS[classFile].g, 0.5*RAID_CLASS_COLORS[classFile].b);
        --     classColor = dimmedClassColor:GenerateHexColor();
        -- end
        -- text = WrapTextInColorCode(className, classColor);

        -- Talent text
        if talentID and talentID ~= glowID and not alwaysHideTalentText then
            text = text.." "..talentText;
            if type(talentSubText) == 'function' then
                local evalTalentSubText = talentSubText();
                if type(evalTalentSubText) == 'string' then
                    text = text.." ("..evalTalentSubText..")";
                else
                    retryApplyText = evalTalentSubText;
                end
            elseif type(talentSubText) == 'string' then
                text = text.." ("..talentSubText..")";
            end
            text = text.." +";
        elseif talentID and talentID == glowID and talentSubText and not alwaysHideTalentText then
            SAO:Debug(Module, "Glowing option of glowID "..tostring(glowID).." has talent sub-text '"..talentSubText.."' but the text will be discarded because talentID matches glowID");
        end

        -- Spell text
        local spellIconAndText = SAO:GetSpellIconAndText(glowID);
        text = text.." "..spellIconAndText;
        if spellSubText then
            text = text.." ("..spellSubText..")";
        end

        -- Hash text
        if type(hash) == 'string' then
            local hashCalculator = SAO.Hash:new();
            hashCalculator:fromString(hash);
            local humanReadableHash = hashCalculator:toHumanReadableString();
            if humanReadableHash then
                text = text .. " ("..humanReadableHash..")";
            end
        end

        -- Set final text to checkbox
        self.Text:SetText(text);

        if (enabled) then
            self.Text:SetTextColor(1, 1, 1);
        else
            self.Text:SetTextColor(0.5, 0.5, 0.5);
        end

        return retryApplyText;
    end

    local testFunc = function(start)
        local fakeOffset = 42000000;
        if (start) then
            self:AddGlow(fakeOffset+spellID, { SAO:GetSpellName(glowID) });
        else
            self:RemoveGlow(fakeOffset+spellID);
        end
    end

    self:AddOption("glow", spellID, glowID, type(variants) == 'table' and variants.values, applyTextFunc, testFunc, { frame = SpellActivationOverlayOptionsPanelGlowingButtons, xOffset = 16, yOffset = 2 });
end

function SAO.AddGlowingLink(self, srcOption, dstOption)
    return self:AddOptionLink("glow", srcOption, dstOption);
end

function SAO.GetGlowingOptions(self, spellID)
    return self:GetOptions("glow", spellID);
end
