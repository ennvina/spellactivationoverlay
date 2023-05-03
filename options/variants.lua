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
function SAO.CreateStringVariants(self, optionType, auraID, id, values)
    local getOption = function()
        if optionType == "glow" then
            return self:GetGlowingOptions(auraID)[id];
        else
            return self:GetOverlayOptions(auraID)[id];
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
function SAO.SpecVariantValue(self, specs)
    local text = "";
    local value = 0;

    if #specs == 1 then
        value = specs[1] or 666;
        text = string.format(RACE_CLASS_ONLY, select(1, GetTalentTabInfo(specs[1])));
    else
        for _, spec in ipairs(specs) do
            value = 10*value + spec;
            text = text..", "..select(1, GetTalentTabInfo(spec));
        end
        text = text:sub(3);
    end

    local width = ceil(#text*0.4);

    return {
        value = tostring(value),
        text = text,
        width = width,
    }
end
