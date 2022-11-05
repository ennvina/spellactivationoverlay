local AddonName, SAO = ...

-- Create an empty texture variant object
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
                if (obj.text == sbText) then
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

-- Utility function to create value for variants
function SAO.TextureVariantValue(self, texture, horizontal, suffix)
    local text;
    if (horizontal) then
        text = "|T"..self.TexName[texture]..":0:2|t";
    else
        text = "|T"..self.TexName[texture]..":0:0:0:0:128:256:0:128:64:192|t";
    end
    if (suffix) then
        text = (text or "").." "..suffix;
    end

    local width = horizontal and 2 or 1;
    if (suffix) then
        width = width+1+#suffix;
    end

    return {
        value = texture,
        text = text or texture,
        width = width,
    }
end
