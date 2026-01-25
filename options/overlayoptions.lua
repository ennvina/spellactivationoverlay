local AddonName, SAO = ...
local Module = "option"

-- Add a checkbox for an overlay
-- talentID is the spell ID of the associated talent; can be negative for specs instead of talents
-- auraID is the spell ID that triggers the overlay; it must match a spell ID of an aura registered with RegisterAura
-- hash is the display hash expected for this option; use a numerical value as legacy option "stacks", including 0 for "any stacks"
-- talentSubText is a string describing the specificity of this option
-- variants optional variant object that tells which are sub-options and how to use them
-- testHash if defined, forces the hash value for the test function
-- testAuraID optional spell ID used to test the aura in lieu of auraID
-- @note Options must be linked asap, not during loadOptions() which would be loaded only when the options panel is opened
-- By linking options as soon as possible, before their respective RegisterAura() calls, options can be used by initial triggers, if any
function SAO.AddOverlayOption(self, talentID, auraID, hash, talentSubText, variants, testHash, testAuraID)
    local talentText = self:GetTalentText(talentID);
    if not talentText or (not self:IsFakeSpell(auraID) and not self:DoesSpellExist(auraID)) then
        if not talentText then
            SAO:Debug(Module, "Skipping overlay option of talentID "..tostring(talentID).." because the spell does not exist");
        end
        if not self:IsFakeSpell(auraID) and not self:DoesSpellExist(auraID) then
            SAO:Debug(Module, "Skipping overlay option of auraID "..tostring(auraID).." because the spell does not exist (and is not a fake spell)");
        end
        return;
    end

    local className = self.CurrentClass.Intrinsics[1];
    local classFile = self.CurrentClass.Intrinsics[2];

    local hashCalculator = SAO.Hash:new();
    if type(hash) == 'string' then
        hashCalculator:fromString(hash);
    elseif type(hash) == 'number' then
        hashCalculator:setAuraStacks(hash);
    else
        hashCalculator:setAuraStacks(0);
    end

    local applyTextFunc = function(self)
        local retryApplyText = nil;
        local enabled = self:IsEnabled();

        -- Class text
        local text = "";
        -- No longer display the class name for each overlay
        -- local classColor;
        -- if (enabled) then
        --     classColor = select(4,GetClassColor(classFile));
        -- else
        --     local dimmedClassColor = CreateColor(0.5*RAID_CLASS_COLORS[classFile].r, 0.5*RAID_CLASS_COLORS[classFile].g, 0.5*RAID_CLASS_COLORS[classFile].b);
        --     classColor = dimmedClassColor:GenerateHexColor();
        -- end
        -- text = WrapTextInColorCode(className, classColor);

        -- Talent text
        text = text.." "..talentText;
        local humanReadableHash = hashCalculator:toHumanReadableString();
        if humanReadableHash then
            text = text .. " ("..humanReadableHash..")";
        end
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

        -- Set final text to checkbox
        self.Text:SetText(text);

        if (enabled) then
            self.Text:SetTextColor(1, 1, 1);
        else
            self.Text:SetTextColor(0.5, 0.5, 0.5);
        end

        return retryApplyText;
    end

    local testFunc = function(start, cb, sb)
        local registeredSpellID;
        if testAuraID then
            registeredSpellID = testAuraID;
        else
            registeredSpellID = auraID;
        end
        local bucket = self:GetBucketBySpellID(registeredSpellID);
        if (not bucket) then
            SAO:Debug("preview", "Trying to preview overlay with spell ID "..tostring(registeredSpellID).." but it is not registered, ".."or its registration failed");
            return;
        end

        SpellActivationOverlayFrame_SetForceAlpha2(start);

        local fakeOffset = 42000000;
        local testHashCalculator = SAO.Hash:new();
        if type(testHash) == 'string' then
            testHashCalculator:fromString(testHash);
        elseif type(testHash) == 'number' then
            testHashCalculator:setAuraStacks(testHash);
        else
            testHashCalculator.hash = hashCalculator.hash;
        end
        local display = bucket[testHashCalculator.hash];
        if start then
            if not display then
                SAO:Debug("preview", "Trying to preview overlay with spell ID "..tostring(registeredSpellID).." with "..hashCalculator:toString().." but there is no aura with this hash");
                return;
            end

            local testHashData = { optionIndex = testHashCalculator:toOptionIndex() }

            local testTexture = type(variants) == 'table' and type(variants.textureTestFunc) == 'function' and variants.textureTestFunc(cb, sb) or nil;

            for _, o in ipairs(display.overlays) do
                local texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly = testTexture or o.texture, o.position, o.scale, o.r, o.g, o.b, o.autoPulse, o.autoPulse, nil, o.combatOnly;
                -- Note: texture is assigned to testTexture or o.texture, forcePulsePlay is assigned to o.autoPulse, endTime is assigned to nil
                self:ActivateOverlay(testHashData, fakeOffset+(testAuraID or auraID), texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly, { strata = "DIALOG", level = 10000 });
                fakeOffset = fakeOffset + 1000000; -- Add offset so that different nodes in the same bucket may share the same 'location' for testing purposes
            end
        else
            if not display then
                return;
            end

            for _, _ in ipairs(display.overlays or {42}) do -- list size is the only thing that matters, {42} is just a random thing to have a list with 1 element
                self:DeactivateOverlay(fakeOffset+(testAuraID or auraID));
                fakeOffset = fakeOffset + 1000000;
            end
        end
    end

    local optionIndex = hashCalculator:toOptionIndex();
    self:AddOption("alert", auraID, optionIndex, type(variants) == 'table' and variants.values, applyTextFunc, testFunc, { frame = SpellActivationOverlayOptionsPanelSpellAlertLabel, xOffset = 4, yOffset = -4 });
end

function SAO.AddOverlayLink(self, srcOption, dstOption)
    return self:AddOptionLink("alert", srcOption, dstOption);
end

function SAO.GetOverlayOptions(self, auraID)
    return self:GetOptions("alert", auraID);
end
