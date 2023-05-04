local AddonName, SAO = ...

-- Create a texture variant object
function SAO.CreateTextureVariants(self, auraID, stacks, values)
    local textureFunc = function()
        return self.TexName[self:GetOverlayOptions(auraID)[stacks]];
    end

    local transformer = function(cb, sb, texture, positions, scale, r, g, b, autoPulse, glowIDs)
        if (cb:GetChecked()) then
            -- Checkbox is checked, preview will work well
            return texture, positions, scale, r, g, b, autoPulse, glowIDs;
        else
            -- Checkbox is not checked, must force texture otherwise preview will not display anything
            local sbText = sb and UIDropDownMenu_GetText(sb);
            for _, obj in ipairs(values) do
                if (obj.text == sbText or obj.text == sbText:gsub(":127:127:127|t",":255:255:255|t")) then
                    texture = self.TexName[obj.value];
                    break
                end
            end
            return texture, positions, scale, r, g, b, autoPulse, glowIDs;
        end
    end

    local variants = {
        variantType = 'texture',
        textureFunc = textureFunc,
        transformer = transformer,
        values = values,
    }

    return variants;
end

-- Utility function to create value for texture variants
function SAO.TextureVariantValue(self, texture, horizontal, suffix)
    local text;
    if (horizontal) then
        text = "|T"..self.TexName[texture]..":16:32:0:0:256:128:16:240:16:112:255:255:255|t";
    else
        text = "|T"..self.TexName[texture]..":16:16:0:0:128:256:16:112:80:176:255:255:255|t";
    end
    if (suffix) then
        text = (text or "").." "..suffix;
    end

    local width = horizontal and 6 or 3;
    if (suffix) then
        width = width+1+#suffix;
    end

    return {
        value = texture,
        text = text or texture,
        width = width,
    }
end

-- Create a string variant object
function SAO.CreateStringVariants(self, optionType, optionID, optionSubID, values)
    local getOption = function()
        if optionType == "glow" then
            return self:GetGlowingOptions(optionID)[optionSubID];
        else
            return self:GetOverlayOptions(optionID)[optionSubID];
        end
    end

    local variants = {
        variantType = 'string',
        getOption = getOption,
        values = values,
    }

    return variants;
end

-- Utility function to create value for string variants
function SAO.StringVariantValue(self, items, valuePrefix, getTextFunc)
    local text = "";
    local value = "";

    if #items == 1 then
        value = tostring(items[1]);
        text = string.format(RACE_CLASS_ONLY, getTextFunc(items[1]));
    elseif #items > 1 then
        for _, item in ipairs(items) do
            value = value == "" and tostring(item) or value.."/"..tostring(item);
            text = text..", "..getTextFunc(item);
        end
        text = text:sub(3);
    end

    local width = ceil(#text*0.4);

    return {
        value = valuePrefix..value,
        text = text,
        width = width,
    }
end

-- Utility function to create value for string variants for specializations
function SAO.SpecVariantValue(self, specs)
    return self:StringVariantValue(specs, "spec:",
    function(spec)
        return select(1, GetTalentTabInfo(spec));
    end);
end

-- Utility function to create value for string variants for spells
function SAO.SpellVariantValue(self, spellIDs)
    return self:StringVariantValue(spellIDs, "spell:",
    function(spellID)
        return select(1, GetSpellInfo(spellID));
    end);
end

-- Mapping between class stance and their respective spells
-- It works well for all classes except maybe Druid, which has dynamic stances
-- Fortunately, druids currently do not need to deal with StanceVariantValue
local ClassStance = {
    ["DRUID"] = {
        5487,  -- Bear Form, could also be Dire Bear Form is 9634
        1066,  -- Aquatic Form
        768,   -- Cat Form
        783,   -- Travel Form
        24858, -- Moonkin Form
    },
    ["ROGUE"] = {
        1784, -- Stealth
    },
    ["PALADIN"] = {
        465,   -- Devotion Aura (rank 1)
        7294,  -- Retribution Aura (rank 1)
        19746, -- Concentration Aura
        19876, -- Shadow Resistance Aura (rank 1)
        19888, -- Frost Resistance Aura (rank 1)
        19891, -- Fire Resistance Aura (rank 1)
        32223, -- Crusader Aura
    },
    ["PRIEST"] = {
        15473, -- Shadowform
    },
    ["WARRIOR"] = {
        2457, -- Battle Stance
        71,   -- Defensive Stance
        2458, -- Berserker Stance
    },
}

-- Utility function to create value for string variants for stances
function SAO.StanceVariantValue(self, stances)
    local classFile = self.CurrentClass and self.CurrentClass.Intrinsics[2] or select(2, UnitClass("player"));

    return self:StringVariantValue(stances, "stance:",
    function(stance)
        if ClassStance[classFile] and ClassStance[classFile][stance] then
            return select(1, GetSpellInfo(ClassStance[classFile][stance]));
        end
        return UNKNOWN;
    end);
end
