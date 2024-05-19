local AddonName, SAO = ...
local Module = "effect"

--[[
    List of registered effect objects.
    Each object can have / must have these members:

{
    name = "my_effect", -- Mandatory
    project = SAO.WRATH + SAO.CATA, -- Mandatory
    spellID = 12345, -- Mandatory; usually a buff to track, for counters this is the counter ability
    talent = 49188, -- Talent or rune or nil (for counters that don't rely on other talent)
    requireTalent = false, -- Default is false
    counter = false, -- Default is false
    combatOnly = false, -- Default is false
    minor = false, -- Default is false; tells the effect is minor, and should not have any option

    overlays = {{
        stacks = 0, -- Default is 0
        spellID = nil, -- Default is spellID from effect
        texture = "genericarc_05", -- Mandatory
        position = "Top", -- Mandatory
        scale = 1, -- Default is 1
        color = {255, 255, 255}, -- Default is {255, 255, 255}
        pulse = true, -- Default is true
        option = { -- Default is true
            setupStacks = 0, -- Default is number of stacks from overlay
            testStacks = 0, -- Default is nil, which defaults to setupStacks
            subText = "no stacks", -- Default is nil
            variants = nil, -- Default is nil
        },
    }}, -- Although rare, multiple overlays are possible

    buttons = {{
        project = SAO.WRATH, -- Default is project from effect
        spellID = 1111, -- Default is spellID from effect
        useName = true, -- Default is false from Era to Wrath, default is true starting from Cataclysm
        stacks = 0, -- Default is nil to apply to all overlays (if any); may target one of the stacks from overlays
        option = { -- Default is true
            talentSubText = "no stacks", -- Default is nil; if option is not set at all, try to guess a good stack count for SAO:NbStacks
            spellSubText = nil, -- Default is nil
            variants = nil, -- Default is nil
        },
    }, { -- Multiple buttons if needed
        project = SAO.CATA,
        spellID = 2222,
        useName = true,
    }},
}

]]
local allEffects = {}

-- List of effects waiting to be added to allEffects
-- Cannot add them immediately to allEffects because the game is in need of other initialization, such as talent tree
local pendingEffects = {}

-- Flag to know when the player has logged in, detected by PLAYER_LOGIN event
local hasPlayerLoggedIn = false;

local function doesUseName(useNameProp)
    if useNameProp == nil then
        return SAO.IsCata() == false;
    else
        return useNameProp == true;
    end
end

-- Copy option's value, deep-copy if option is a table
local function copyOption(option)
    if type(option) == 'table' then
        local optionCopy = {}; -- Copy table to avoid issues when re-using options between effects
        for k, v in pairs(option) do
            optionCopy[k] = v; -- Copy one depth level only
            -- optionCopy[k] = copyOption(v); -- Use this code for a full deep copy
        end
        return optionCopy;
    else
        return option;
    end
end

-- Merge option1 and option2, with priority to option2
local function mergeOption(option1, option2)
    if option2 == nil then -- nil means "unspecified"
        return copyOption(option1);
    end

    if option2 == false then -- false means "no options, please"
        return false;
    end

    if option2 == true then -- true means "I specify that yes I want an option, but not specifying which params exactly"
        if type(option1) == 'table' then
            return copyOption(option1);
        end
        return true;
    end

    -- At this point, option2 should be a table
    if type(option2) ~= 'table' then
        SAO:Error(Module, "Merging options with invalid values "..tostring(option1).." vs. "..tostring(option2));
        return copyOption(option2);
    end

    if type(option1) ~= 'table' then
        return copyOption(option2);
    end

    -- Merge both tables, with priority to option2
    local combined = {}
    for k, v in pairs(option1) do
        combined[k] = v; -- write option1 first
    end
    for k, v in pairs(option2) do
        combined[k] = v; -- option2 overwrites option1, if sharing same keys
    end
    return combined;
end

local function getValueOrDefault(value, default)
    if value ~= nil then
        return value;
    else
        return default;
    end
end

local function addOneOverlay(overlays, overlayConfig, project, default)
    if not default then
        default = {}
    end

    local stacks = overlayConfig.stacks or default.stacks;
    if type(stacks) ~= 'nil' and (type(stacks) ~= 'number' or stacks < 0) then
        SAO:Error(Module, "Adding Overlay with invalid number of stacks "..tostring(stacks));
    end

    local texture = overlayConfig.texture or default.texture;
    if type(texture) ~= 'string' then
        SAO:Error(Module, "Adding Overlay with invalid texture "..tostring(texture));
    end

    local position = overlayConfig.position or default.position;
    if type(position) ~= 'string' then
        SAO:Error(Module, "Adding Overlay with invalid position "..tostring(position));
    end

    local option = overlayConfig.option;
    if option == nil then option = default.option; end
    if option ~= nil and type(option) ~= 'boolean' and type(option) ~= 'table' then
        SAO:Error(Module, "Adding Overlay with invalid option "..tostring(option));
    end

    local color = overlayConfig.color or default.color;

    local overlay = {
        project = overlayConfig.project or project, -- Note: cannot have a 'default.project'
        stacks = stacks,
        texture = texture,
        position = position,
        scale = overlayConfig.scale or default.scale,
        color = color and { color[1], color[2], color[3] } or nil,
        pulse = getValueOrDefault(overlayConfig.pulse, default.pulse),
        option = mergeOption(default.option, overlayConfig.option),
    }

    if type(overlay.project) == 'number' and not SAO.IsProject(overlay.project) then
        return;
    end

    table.insert(overlays, overlay);
end

local function addOneButton(buttons, buttonConfig, project, default)
    if not default then
        default = {}
    end

    if type(buttonConfig) == 'table' then
        local spellID = buttonConfig.spellID or default.spellID;
        if spellID ~= nil and type(spellID) ~= 'number' then
            SAO:Error(Module, "Adding Button with invalid spellID "..tostring(spellID));
        end
        local option = buttonConfig.option;
        if option == nil then option = default.option; end
        if option ~= nil and type(option) ~= 'boolean' and type(option) ~= 'table' then
            SAO:Error(Module, "Adding Button with invalid option "..tostring(option));
        end
    end

    local button = {};

    if type(buttonConfig) == 'number' then
        button.project = project; -- Note: cannot have a 'default.project'
        button.spellID = buttonConfig;
        button.useName = default.useName;
        button.stacks = default.stacks;
        button.option = copyOption(default.option);
    elseif type(buttonConfig) == 'table' then
        button.project = buttonConfig.project or project; -- Note: cannot have a 'default.project'
        button.spellID = buttonConfig.spellID or default.spellID;
        button.useName = getValueOrDefault(buttonConfig.useName, default.useName);
        button.stacks = buttonConfig.stacks or default.stacks;
        button.option = mergeOption(default.option, buttonConfig.option);
    else
        SAO:Error(Module, "Adding Button with invalid value "..tostring(buttonConfig));
    end

    if type(button.project) == 'number' and not SAO.IsProject(button.project) then
        return;
    end

    table.insert(buttons, button);
end

local function importTalent(effect, props)
    if type(props.talent) == 'number' then
        effect.talent = props.talent;
    elseif type(props.talent) == 'table' then
        for project, talent in pairs(props.talent) do
            if SAO.IsProject(project) then
                effect.talent = talent;
                break;
            end
        end
    else
        effect.talent = effect.spellID;
    end

    if type(props.requireTalent) == 'boolean' then
        effect.requireTalent = props.requireTalent;
    elseif type(props.requireTalent) == 'table' then
        for project, requireTalent in pairs(props.requireTalent) do
            if SAO.IsProject(project) then
                effect.requireTalent = requireTalent;
                break;
            end
        end
    else
        effect.requireTalent = false;
    end
end

local function importOverlays(effect, props)
    effect.overlays = {}
    if props.overlay then
        addOneOverlay(effect.overlays, props.overlay);
    end
    local default = props.overlays and props.overlays.default or nil;
    for key, overlayConfig in pairs(props.overlays or {}) do
        if key ~= "default" then
            if type(key) == 'number' and key >= SAO.ERA then
                if type(overlayConfig) == 'table' and overlayConfig[1] then
                    for _, subOverlayConfig in ipairs(overlayConfig) do
                        addOneOverlay(effect.overlays, subOverlayConfig, key, overlayConfig.default or default);
                    end
                else
                    addOneOverlay(effect.overlays, overlayConfig, key, default);
                end
            else
                addOneOverlay(effect.overlays, overlayConfig, nil, default);
            end
        end
    end
end

local function importButtons(effect, props)
    effect.buttons = {}
    if props.button then
        addOneButton(effect.buttons, props.button);
    end
    local default = props.buttons and props.buttons.default or nil;
    for key, buttonConfig in pairs(props.buttons or {}) do
        if key ~= "default" then
            if type(key) == 'number' and key >= SAO.ERA then
                if type(buttonConfig) == 'table' and buttonConfig[1] then
                    for _, subButtonConfig in ipairs(buttonConfig) do
                        addOneButton(effect.buttons, subButtonConfig, key, buttonConfig.default or default);
                    end
                else
                    addOneButton(effect.buttons, buttonConfig, key, default);
                end
            else
                addOneButton(effect.buttons, buttonConfig, nil, default);
            end
        end
    end
end

local function createCounter(effect, props)
    effect.counter = true;

    if type(props) == 'table' then
        effect.combatOnly = props.combatOnly;
        effect.buttons = {{
            useName = doesUseName(props.useName),
        }}
    else
        effect.buttons = {{
            useName = doesUseName(),
        }}
    end

    return effect;
end

local function createAura(effect, props)
    if type(props) == 'table' then
        effect.combatOnly = props.combatOnly;
    else
        SAO:Error(Module, "Creating an aura for "..tostring(effect.name).." requires a 'props' table");
    end

    importTalent(effect, props);

    importOverlays(effect, props);

    importButtons(effect, props);

    return effect;
end

local function createCounterWithOverlay(effect, props)
    if type(props) ~= 'table' or (not props.overlay and not props.overlays) then
        SAO:Error(Module, "Creating a counter with overlay for "..tostring(effect.name).." requires a 'props' table that contains either 'overlay' or 'overlays' or both");
    end

    createCounter(effect, props);

    importTalent(effect, props);

    importOverlays(effect, props);

    return effect;
end

local function checkNativeEffect(effect)
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
    if effect.requireTalent ~= nil and type(effect.requireTalent) ~= 'boolean' then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid talent requirement flag "..tostring(effect.requireTalent));
        return false;
    end
    if effect.minor ~= nil and type(effect.minor) ~= 'boolean' then
        SAO:Error(Module, "Registering effect "..effect.name.." with invalid minor flag "..tostring(effect.minor));
        return nil;
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

    local hasStacksZero, hasStacksNonZero = false, false;
    for i, overlay in ipairs(effect.overlays or {}) do
        if overlay.project and type(overlay.project) ~= 'number' then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid project flags "..tostring(overlay.project));
            return false;
        end
        if overlay.spellID and type(overlay.spellID) ~= 'number' then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid spellID "..tostring(overlay.spellID));
            return false;
        end
        if type(overlay.stacks) ~= 'nil' and (type(overlay.stacks) ~= 'number' or overlay.stacks < 0) then
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid number of stacks "..tostring(overlay.stacks));
            return false;
        end
        local stacks = overlay.stacks or 0;
        if stacks == 0 then
            if hasStacksNonZero then
                SAO:Error(Module, "Registering effect "..effect.name.." with mixed stacks of zero and non-zero");
                return false;
            end
            hasStacksZero = true;
        else
            if hasStacksZero then
                SAO:Error(Module, "Registering effect "..effect.name.." with mixed stacks of zero and non-zero");
                return false;
            end
            hasStacksNonZero = true;
        end
        if type(overlay.texture) ~= 'string' then -- @todo check the texture even exists
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid texture name "..tostring(overlay.texture));
            return false;
        end
        if type(overlay.position) ~= 'string' then -- @todo check the position is one of the allowed values
            SAO:Error(Module, "Registering effect "..effect.name.." for overlay "..i.." with invalid position "..tostring(overlay.position));
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

    if effect.requireTalent and not effect.talent then
        SAO:Error(Module, "Registering effect "..effect.name.." with talent requirement, but no talent is pointed out in the talent tree");
        return false;
    end

    return true;
end

local function RegisterNativeEffectNow(self, effect)
    -- Buckets of glow IDs, sorted by their number of stacks
    -- Key = Nb of stacks, Value = List of glow IDs
    -- Stack index is guided by available overlays; if there are no overlays, index from button stacks instead
    -- A button that has not defined its stacks will be added to all buckets
    -- Please note, having no stacks defined is not the same as having stacks == 0
    local glowIDsByStack = {};
    if type(effect.buttons) == 'table' then
        -- First, identify the list of stacks claimed by overlays
        local hasExplicitStacks = false
        for _, overlay in ipairs(effect.overlays or {}) do
            local stacks = overlay.stacks or 0; -- Overlays with no stacks set is equivalent to explicitly having stacks == 0
            glowIDsByStack[stacks] = {};
            hasExplicitStacks = true;
        end
        -- If there are no overlays, look for buttons instead
        if not hasExplicitStacks then
            for _, button in ipairs(effect.buttons) do
                local stacks = button.stacks;
                if stacks then -- Unlike overlays, buttons with no stacks set are *not* equivalent to explicitly having stacks
                    glowIDsByStack[stacks] = {};
                    hasExplicitStacks = true;
                end
            end
            if not hasExplicitStacks then
                -- If there are no explicit stacks in buttons either, the implicit value is 0
                glowIDsByStack[0] = {};
            end
        end

        -- Then for each button, add them to their corresponding stack bucket
        for i, button in ipairs(effect.buttons) do
            if not button.project or self.IsProject(button.project) then
                local spellID = button.spellID or effect.spellID;
                local useName = doesUseName(button.useName);
                local spellToAdd;
                if useName then
                    local spellName = GetSpellInfo(spellID);
                    if not spellName then
                        SAO:Error(Module, "Registering effect "..effect.name.." for button "..i.." with unknown spellID "..tostring(spellID));
                        return false;
                    end
                    spellToAdd = spellName;
                else
                    spellToAdd = spellID;
                end

                local stacks = button.stacks;
                if stacks == 0 and not glowIDsByStack[0] then
                    -- Button with stacks explicitly set to 0, but with no overlays at stacks == 0, will go to every bucket
                    for _, glowBucket in pairs(glowIDsByStack) do
                        table.insert(glowBucket, spellToAdd);
                    end
                elseif stacks then
                    -- An explicit number of stacks will go directly to the target bucket
                    if not glowIDsByStack[stacks] then
                        SAO:Error(Module, "A button of "..tostring(effect.name).." has a 'stacks' number unbeknownst to overlays");
                    end
                    table.insert(glowIDsByStack[stacks], spellToAdd);
                else
                    -- A button without explicit number of stacks will go to every bucket
                    for _, glowBucket in pairs(glowIDsByStack) do
                        table.insert(glowBucket, spellToAdd);
                    end
                end
            end
        end
    end

    for _, overlay in ipairs(effect.overlays or {}) do
        if not overlay.project or self.IsProject(overlay.project) then
            local name = effect.name;
            local stacks = overlay.stacks or 0;
            if stacks > 0 then
                name = name.." "..stacks;
            end
            local spellID = overlay.spellID or effect.spellID;
            local texture = overlay.texture;
            local position = overlay.position;
            local scale = overlay.scale or 1;
            local r, g, b = 255, 255, 255
            if overlay.color then r, g, b = overlay.color[1], overlay.color[2], overlay.color[3] end
            local autoPulse = overlay.pulse ~= false;
            local combatOnly = overlay.combatOnly == true or effect.combatOnly == true;
            self:RegisterAura(name, stacks, spellID, texture, position, scale, r, g, b, autoPulse, glowIDsByStack[stacks], combatOnly);
            glowIDsByStack[stacks] = nil; -- Immediately clear the glow ID list to avoid re-registering the same list on next overlay with same number of stacks
        end
    end

    if not effect.overlays or #effect.overlays == 0 then
        -- If there are no overlays, assume each button expects to have a trigger for their number of stacks
        local combatOnly = effect.combatOnly == true;
        for stacks, glowBucket in pairs(glowIDsByStack) do
            self:RegisterAura(effect.name, stacks, effect.spellID, nil, "", 0, 0, 0, 0, false, glowBucket, combatOnly);
        end
        glowIDsByStack = {};
    end

    for stacks, glowBucket in pairs(glowIDsByStack) do
        SAO:Error(Module, "Effect "..tostring(effect.name).." has defined "..#glowBucket.." button(s) for stacks == "..tostring(stacks)..", but these buttons are unused");
    end

    if effect.talent and effect.requireTalent then
        local talentName = GetSpellInfo(effect.talent);
        local _, _, tab, index = self:GetTalentByName(talentName);
        if type(tab) == 'number' and type(index) == 'number' then
            local bucket = self:GetBucketByName(effect.name);
            bucket.talentTabIndex = { tab, index };
            bucket.trigger:require(SAO.TRIGGER_TALENT);
        elseif effect.requireTalent then
            self:Error(Module, "Effect "..tostring(effect.name).." requires talent "..effect.talent..(talentName and "("..talentName..")" or "")..", but it cannot be found in the talent tree");
        end
    end

    if effect.counter == true then
        self:RegisterCounter(effect.name);
    end

    table.insert(allEffects, effect);
end

function SAO:RegisterNativeEffect(effect)
    if not checkNativeEffect(effect) then
        return;
    end

    if not self.IsProject(effect.project) then
        return;
    end

    if hasPlayerLoggedIn then
        RegisterNativeEffectNow(self, effect);
    else
        table.insert(pendingEffects, effect);
    end
end

function SAO:RegisterPendingEffectsAfterPlayerLoggedIn()
    if hasPlayerLoggedIn then
        self:Debug(Module, "Received PLAYER_LOGIN twice in the same session");
    end
    hasPlayerLoggedIn = true;

    for _, effect in ipairs(pendingEffects) do
        RegisterNativeEffectNow(self, effect);
    end
    pendingEffects = {};
end

function SAO:AddEffectOptions()
    for _, effect in ipairs(allEffects) do
        local talent = effect.talent;
        local skipOptions = effect.minor == true;

        local uniqueOverlayStack = { latest = nil, unique = true };
        for _, overlay in ipairs((not skipOptions) and effect.overlays or {}) do
            if overlay.option ~= false and (not overlay.project or self.IsProject(overlay.project)) then
                local buff = overlay.spellID or effect.spellID;
                if type(overlay.option) == 'table' then
                    local setupStacks = type(overlay.option.setupStacks) == 'number' and overlay.option.setupStacks or overlay.stacks;
                    local testStacks = type(overlay.option.testStacks) == 'number' and overlay.option.testStacks or setupStacks;
                    local subText = overlay.option.subText;
                    local variants = overlay.option.variants;
                    self:AddOverlayOption(talent, buff, setupStacks, subText, variants, testStacks);
                else
                    local setupStacks = overlay.stacks;
                    self:AddOverlayOption(talent, buff, setupStacks);
                end

                -- Bonus: detect if all overlays are based on a unique stack count; it will help write sub-text for glowing option
                local stacks = overlay.stacks or 0;
                if uniqueOverlayStack.latest and uniqueOverlayStack.latest ~= stacks and uniqueOverlayStack.unique then
                    uniqueOverlayStack.unique = false;
                end
                uniqueOverlayStack.latest = stacks;
            end
        end

        for _, button in ipairs((not skipOptions) and effect.buttons or {}) do
            if button.option ~= false and (not button.project or self.IsProject(button.project)) then
                local buff = effect.spellID;
                local spellID = button.spellID or effect.spellID;
                if type(button.option) == 'table' then
                    local talentSubText = button.option.talentSubText;
                    local spellSubText = button.option.spellSubText;
                    local variants = button.option.variants;
                    self:AddGlowingOption(talent, buff, spellID, talentSubText, spellSubText, variants);
                else
                    local stacks = button.stacks or (uniqueOverlayStack.unique and uniqueOverlayStack.latest) or nil;
                    local talentSubText = stacks and stacks > 0 and self:NbStacks(stacks) or nil;
                    self:AddGlowingOption(talent, buff, spellID, talentSubText);
                end
            end
        end
    end
end

--[[
    Create an effect based on a specific class.
    @param name Effect name, must be unique
    @param project Project flags where the effect is used e.g. SAO.WRATH+SAO.CATA
    @param class Class name e.g., "counter"
    @param props (optional) Properties to initialize the effect
    @param register (optional) Register the effect automatically after creation; default is true
]]
function SAO:CreateEffect(name, project, spellID, class, props, register)
    if type(name) ~= 'string' or name == '' then
        self:Error(Module, "Creating effect with invalid name "..tostring(name));
        return nil;
    end
    if type(project) ~= 'number' or bit.band(project, SAO.ALL_PROJECTS) == 0 then
        self:Error(Module, "Creating effect "..name.." with invalid project flags "..tostring(project));
        return nil;
    end
    if (type(spellID) ~= 'number' and type(spellID) ~= 'table') or (type(spellID) == 'number' and spellID <= 0) then
        self:Error(Module, "Creating effect "..name.." with invalid spellID "..tostring(spellID));
        return nil;
    end
    if type(class) ~= 'string' then
        self:Error(Module, "Creating effect "..name.." with invalid class "..tostring(spellID));
        return nil;
    end
    if props and type(props) ~= 'table' then
        self:Error(Module, "Creating effect "..name.." with invalid props "..tostring(props));
        return nil;
    end
    if props and props.minor ~= nil and type(props.minor) ~= 'boolean' then
        self:Error(Module, "Creating effect "..name.." with invalid minor flag "..tostring(props.minor));
        return nil;
    end

    if not self.IsProject(project) then
        return;
    end

    if type(spellID) == 'table' then
        for spellProject, projectedSpellID in pairs(spellID) do
            if type(spellProject) ~= 'number' or spellProject < SAO.ERA or type(projectedSpellID) ~= 'number' or projectedSpellID <= 0 then
                self:Error(Module, "Creating effect "..name.." with invalid spellProject "..tostring(spellProject).." or spellID "..tostring(projectedSpellID).." or both");
                return nil;
            end
            if self.IsProject(spellProject) then
                spellID = projectedSpellID;
                break;
            end
        end
    end

    local effect = {
        name = name,
        project = project,
        spellID = spellID,
        minor = type(props) == 'table' and props.minor,
    }

    if strlower(class) == "counter" then
        createCounter(effect, props);
    elseif strlower(class) == "aura" then
        createAura(effect, props);
    elseif strlower(class) == "counter_with_overlay" then
        createCounterWithOverlay(effect, props);
    else
        self:Error(Module, "Creating effect "..name.." with unknown class "..tostring(class));
        return nil;
    end

    if register == nil or register == true then
        self:RegisterNativeEffect(effect);
    end

    return effect;
end

--[[
    Create multiple, linked effects.
    Parameters are almost identical to CreateEffect, the main difference is that there are multiple spellIDs instead of one.
    The last spellID is the 'master' while all others are linked to it.
    Options are set to false for all overlays/buttons, except the last one.
    The minor flag, if set, will be ignored because overriden to disable all options.
]]
function SAO:CreateLinkedEffects(name, project, spellIDs, class, props, register)
    if not self.IsProject(project) then
        return nil;
    end

    local wasMinor;
    local minorProps;
    if type(props) == 'table' then
        wasMinor = props.minor;
        minorProps = props;
        if type(wasMinor) == 'boolean' then
            self:Error(Module, "Effect link group "..tostring(name).." uses a minor flag; it will be overriden");
        end
    else
        minorProps = {};
    end

    -- Start by creating the last effect, because it is the most important one
    -- If it fails, don't even bother creating the rest
    local lastSpell = spellIDs[#spellIDs];
    minorProps.minor = false; -- Last spell is *not* minor
    local lastEffect = self:CreateEffect(name.."_link_max", project, lastSpell, class, minorProps, false);
    if not lastEffect then
        self:Error(Module, "Failed to create main effect for an effect link group of "..tostring(name));
        minorProps.minor = wasMinor;
        return nil;
    end
    minorProps.minor = true; -- All other spells will be minor

    local hasOverlay = type(props) == 'table' and (props.overlay or props.overlays);
    local hasButton = type(props) == 'table' and (props.button or props.buttons);

    local effects = {};

    for i, spell in ipairs(spellIDs) do
        if spell ~= lastSpell then
            if hasOverlay then
                self:AddOverlayLink(lastSpell, spell);
            end
            if hasButton then
                self:AddGlowingLink(lastSpell, spell);
            end

            local effect = self:CreateEffect(name.."_link_"..i, project, spell, class, minorProps, false);
            if effect then
                table.insert(effects, effect);
            end
        end
    end

    table.insert(effects, lastEffect);

    if register == nil or register == true then
        for _, effect in ipairs(effects) do
            self:RegisterNativeEffect(effect);
        end
    end

    minorProps.minor = wasMinor;
    return effects;
end
