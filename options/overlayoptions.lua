local AddonName, SAO = ...

local Module = "option"

-- Add a checkbox for an overlay
-- talentID is the spell ID of the associated talent
-- auraID is the spell ID that triggers the overlay; it must match a spell ID of an aura registered with RegisterAura
-- count is the number of stacks expected for this option; use 0 if aura has no stacks or for "any stacks"
-- talentSubText is a string describing the specificity of this option
-- variants optional variant object that tells which are sub-options and how to use them
-- testStacks if defined, forces the number of stacks for the test function
-- testAuraID optional spell ID used to test the aura in lieu of auraID
-- @note Options must be linked asap, not during loadOptions() which would be loaded only when the options panel is opened
-- By linking options as soon as possible, before their respective RegisterAura() calls, options can be used by initial triggers, if any
function SAO.AddOverlayOption(self, talentID, auraID, count, talentSubText, variants, testStacks, testAuraID)
    if not GetSpellInfo(talentID) or (not self:IsFakeSpell(auraID) and not GetSpellInfo(auraID)) then
        if not GetSpellInfo(talentID) then
            self:Debug(Module, "Skipping overlay option of talentID "..tostring(talentID).." because the spell does not exist");
        end
        if not self:IsFakeSpell(auraID) and not GetSpellInfo(auraID) then
            self:Debug(Module, "Skipping overlay option of auraID "..tostring(auraID).." because the spell does not exist (and is not a fake spell)");
        end
        return;
    end

    local className = self.CurrentClass.Intrinsics[1];
    local classFile = self.CurrentClass.Intrinsics[2];

    local applyTextFunc = function(self)
        local enabled = self:IsEnabled();

        -- Class text
        local classColor;
        if (enabled) then
            classColor = select(4,GetClassColor(classFile));
        else
            local dimmedClassColor = CreateColor(0.5*RAID_CLASS_COLORS[classFile].r, 0.5*RAID_CLASS_COLORS[classFile].g, 0.5*RAID_CLASS_COLORS[classFile].b);
            classColor = dimmedClassColor:GenerateHexColor();
        end
        local text = WrapTextInColorCode(className, classColor);

        -- Talent text
        local spellName, _, spellIcon = GetSpellInfo(talentID);
        text = text.." |T"..spellIcon..":0|t "..spellName;
        if (count and count > 0) then
            text = text .. " ("..SAO:NbStacks(count)..")";
        end
        if (talentSubText) then
            text = text.." ("..talentSubText..")";
        end

        -- Set final text to checkbox
        self.Text:SetText(text);

        if (enabled) then
            self.Text:SetTextColor(1, 1, 1);
        else
            self.Text:SetTextColor(0.5, 0.5, 0.5);
        end
    end

    local testFunc = function(start, cb, sb)
        local registeredSpellID;
        if testAuraID then
            registeredSpellID = testAuraID;
        elseif self.IsEra() and not self:IsFakeSpell(auraID) then
            registeredSpellID = GetSpellInfo(auraID); -- Cannot track spell ID on Classic Era, but can track spell name
        else
            registeredSpellID = auraID;
        end
        local bucket = self:GetBucketBySpellID(registeredSpellID);
        if (not bucket) then
            SAO:Debug("preview", "Trying to preview overlay with spell ID "..tostring(registeredSpellID).." but it is not registered, or its registration failed");
            return;
        end

        SpellActivationOverlayFrame_SetForceAlpha2(start);

        local fakeOffset = 42000000;
        local stacks = testStacks or count or 0;
        local hash = SAO.Hash:new()
        hash:setAuraStacks(stacks); -- @todo use correct hash
        local display = bucket[hash.hash];
        if (start) then
            if (not display) then
                SAO:Debug("preview", "Trying to preview overlay with spell ID "..tostring(registeredSpellID).." with "..tostring(stacks).." stacks but there is no aura with this number of stacks");
                return;
            end

            local testTexture = type(variants) == 'table' and type(variants.textureTestFunc) == 'function' and variants.textureTestFunc(cb, sb) or nil;
            for _, o in ipairs(display.overlays) do
                local texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly = testTexture or o.texture, o.position, o.scale, o.r, o.g, o.b, o.autoPulse, o.autoPulse, nil, o.combatOnly;
                -- Note: texture is assigned to testTexture or o.texture, forcePulsePlay is assigned to o.autoPulse, endTime is assigned to nil
                self:ActivateOverlay(stacks, fakeOffset+(testAuraID or auraID), texture, positions, scale, r, g, b, autoPulse, forcePulsePlay, endTime, combatOnly);
                fakeOffset = fakeOffset + 1000000; -- Add offset so that different nodes in the same bucket may share the same 'location' for testing purposes
            end
        else
            for _, _ in ipairs(display.overlays or {42}) do -- list size is the only thing that matters, {42} is just a random thing to have a list with 1 element
                self:DeactivateOverlay(fakeOffset+(testAuraID or auraID));
                fakeOffset = fakeOffset + 1000000;
            end
        end
    end

    self:AddOption("alert", auraID, count or 0, type(variants) == 'table' and variants.values, applyTextFunc, testFunc, { frame = SpellActivationOverlayOptionsPanelSpellAlertLabel, xOffset = 4, yOffset = -4 });
end

function SAO.AddOverlayLink(self, srcOption, dstOption)
    return self:AddOptionLink("alert", srcOption, dstOption);
end

function SAO.GetOverlayOptions(self, auraID)
    return self:GetOptions("alert", auraID);
end
