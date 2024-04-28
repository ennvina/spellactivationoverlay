local AddonName, SAO = ...
local Module = "effect"

--[[
    List of registered effect objects.
    Each object can have / must have these members:

{
    name = "my_effect", -- Mandatory
    project = SAO.WRATH + SAO.CATA, -- Mandatory
    spellID = 12345; -- Mandatory; usually a buff to track, for counters this is the counter ability
    talent = 49188; -- Talent or rune or nil (for counters)

    counter = false, -- Default is false
    combatOnly = false, -- Default is false

    overlays = {{
        texture = "genericarc_05", -- Mandatory
        location = "Top", -- Mandatory
        scale = 1, -- Default is 1
        color = {255, 255, 255}, -- Default is {255, 255, 255}
        pulse = true, -- Default is true
        option = true, -- Default is true
    }}, -- Although rare, multiple overlays are possible

    buttons = {{
        project = SAO.WRATH, -- Default is project from effect
        spellID = 1111, -- Default is spellID from effect
        useName = true, -- Default is false
        option = true, -- Default is true
    }, { -- Multiple buttons if needed
        project = SAO.CATA,
        spellID = 2222,
        useName = true,
        option = true,
    }},
}

]]
local allEffects = {}


local function checkEffect(effect)
    if type(effect) ~= 'table' then
        SAO:Error(Module, "Registering invalid effect "..tostring(effect));
        return false;
    end
    if type(effect.name) ~= 'string' or effect.name == '' then
        SAO:Error(Module, "Registering effect with invalid name "..tostring(effect.name));
        return false;
    end
    if type(effect.project) ~= 'number' or bit.band(effect.project, SAO.ALL_PROJECTS) == 0 then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid project flags "..tostring(effect.project));
        return false;
    end
    if type(effect.spellID) ~= 'number' or effect.spellID <= 0 then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid spellID "..tostring(effect.spellID));
        return false;
    end
    if effect.talent and type(effect.talent) ~= 'number' then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid talent "..tostring(effect.talent));
        return false;
    end
    if effect.counter ~= true and type(effect.overlays) ~= "table" then
        SAO:Error(Module, "Registering effect "..effect.name.." with no overlays and not as counter");
        return false;
    end
    if effect.counter == true and (type(effect.buttons) ~= "table" or #effect.buttons == 0) then
        SAO:Error(Module, "Registering effect "..effect.name.." with no buttons despite being a counter");
        return false;
    end
    if effect.overlays and type(effect.overlays) ~= 'table' then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid overlay list");
        return false;
    end
    if effect.buttons and type(effect.buttons) ~= 'table' then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid button list");
        return false;
    end

    for i, overlay in ipairs(effect.overlays or {}) do
        if overlay.project and type(overlay.project) ~= 'number' then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid project flags "..tostring(overlay.project));
            return false;
        end
        if overlay.spellID and type(overlay.spellID) ~= 'number' then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid spellID "..tostring(overlay.spellID));
            return false;
        end
        if type(overlay.texture) ~= 'string' then -- @todo check the texture even exists
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid texture name "..tostring(overlay.texture));
            return false;
        end
        if type(overlay.location) ~= 'string' then -- @todo check the location is one of the allowed values
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid location "..tostring(overlay.location));
            return false;
        end
        if overlay.scale and (type(overlay.scale) ~= 'number' or overlay.scale <= 0) then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid scale factor "..tostring(overlay.scale));
            return false;
        end
        if overlay.color and (type(overlay.color) ~= 'table' or type(overlay.color[1]) ~= 'number' or type(overlay.color[2]) ~= 'number' or type(overlay.color[3]) ~= 'number') then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid color");
            return false;
        end
    end

    for i, button in ipairs(effect.buttons or {}) do
        if button.project and type(button.project) ~= 'number' then
            SAO:Error(Module, "Registering effect "..effect.name.." for button "..i.." with invalid project flags "..tostring(button.project));
            return false;
        end
        if button.spellID and type(button.spellID) ~= 'number' then
            SAO:Error(Module, "Registering effect "..effect.name.." for button "..i.." with invalid spellID "..tostring(button.spellID));
            return false;
        end
    end

    return true;
end

function SAO:RegisterEffect(effect)
    if not checkEffect(effect) then
        return;
    end

    if not self.IsProject(effect.project) then
        return;
    end

    local glowIDs = nil
    if type(effect.buttons) == 'table' then
        glowIDs = {}
        for i, button in ipairs(effect.buttons) do
            if not button.project or self.IsProject(button.project) then
                local spellID = button.spellID or effect.spellID;
                if button.useName == true then
                    local spellName = GetSpellInfo(spellID);
                    if not spellName then
                        SAO:Error(Module, "Registering effect "..effect.name.." for button "..i.." with unknown spellID "..tostring(spellID));
                        return false;
                    end
                    table.insert(glowIDs, spellName);
                else
                    table.insert(glowIDs, spellID);
                end
            end
        end
    end

    for _, overlay in ipairs(effect.overlays or {}) do
        if not overlay.project or self.IsProject(overlay.project) then
            local name = effect.name;
            local stacks = overlay.stacks or 0;
            local spellID = overlay.spellID or effect.spellID;
            local texture = overlay.texture;
            local location = overlay.location;
            local scale = overlay.scale or 1;
            local r, g, b = 255, 255, 255
            if overlay.color then r, g, b = overlay.color[1], overlay.color[2], overlay.color[3] end
            local autoPulse = overlay.pulse ~= false;
            local combatOnly = overlay.combatOnly == true or effect.combatOnly == true;
            self:RegisterAura(name, stacks, spellID, texture, location, scale, r, g, b, autoPulse, glowIDs, combatOnly);
            glowIDs = nil; -- Immediately clear the glow ID list to avoid re-registering the same list on next overlay
        end
    end

    if not effect.overlays and effect.counter == true then
        self:RegisterAura(effect.name, 0, effect.spellID, nil, "", 0, 0, 0, 0, false, glowIDs);
    end

    if effect.counter == true then
        self:RegisterCounter(effect.name);
    end

    table.insert(allEffects, effect);
end

function SAO:AddEffectOptions()
    for _, effect in ipairs(allEffects) do
        local talent = effect.talent;

        for _, overlay in ipairs(effect.overlays or {}) do
            if overlay.option ~= false and (not overlay.project or self.IsProject(overlay.project)) then
                local buff = overlay.spellID or effect.spellID;
                self:AddOverlayOption(talent, buff);
            end
        end

        for _, button in ipairs(effect.buttons or {}) do
            if button.option ~= false and (not button.project or self.IsProject(button.project)) then
                local buff = effect.spellID;
                local spellID = button.spellID or effect.spellID;
                self:AddGlowingOption(talent, buff, spellID);
            end
        end
    end
end
