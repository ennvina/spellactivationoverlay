local AddonName, SAO = ...
local Module = "auracontainer"

local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn

local useAuraContainer = (SAO.IsForever() or SAO.IsRetail()) and C_Secrets ~= nil and C_Secrets.GetSpellAuraSecrecy ~= nil

local function traceBooleanChange(intro, oldValue, newValue, id) --[[BEGIN_DEV_ONLY]]
    if not SAO:HasTrace(Module) then
        return
    end
    local coloredBool = function(bool)
        return bool and "|cFF00FF00true|r" or "|cFFFF0000false|r"
    end
    SAO:Trace(Module, intro, "from", coloredBool(oldValue), "to", coloredBool(newValue), "for", tostring(id))
end --[[END_DEV_ONLY]]

local function splitPositions(position)
    local positions = {}
    for component in string.gmatch(position or "", "[^%+]+") do
        component = string.match(component, "^%s*(.-)%s*$")
        tinsert(positions, component)
    end
    return positions
end

-- Return hash information for container auras, or nil if the hash is not supported
local function getInfoFromHash(hash, macroCondition, spellID)
    local requiresAura = type(SAO.Hash.hasAuraStacks) == 'function' and hash:hasAuraStacks()
    if not requiresAura then
        -- The aura container, as its name implies, only handles overlays that require an aura (i.e., have aura stacks)
        return nil
    end

    local unit = "player" -- For now, aura containers only support the "player" unit

    -- Fill in item information
    local itemInfo = { unit = unit }

    local nbAuraStacks = hash:getAuraStacks()
    itemInfo.nbAuraStacks = nbAuraStacks

    if nbAuraStacks == nil then
        SAO:Warn(Module, "Spell "..tostring(spellID).." uses an inverse aura trigger, but aura containers do not support inverse auras") --[[DEV_ONLY]]
        return nil
    end

    -- Fill in container information
    local containerInfo = { unit = unit }

    local hasStance = type(SAO.Hash.hasMatchStance) == 'function' and hash:hasMatchStance()

    local hashOnlyAnyStacks = SAO.Hash:new(SAO.Hash:new():toAnyAuraStacks())
    if hasStance and hash:toWithoutMatchStance() ~= hashOnlyAnyStacks.hash then
        SAO:Warn(Module, "Spell "..tostring(spellID).." has a hash that has more than aura stacks and a stance trigger:", hash.hash)
        return nil
    end

    if hasStance then
        containerInfo.matchStance = hash:getMatchStance()
    end

    if hasStance and type(macroCondition) ~= 'string' then
        SAO:Warn(Module, "Spell "..tostring(spellID).." has a stance but no macro condition") --[[DEV_ONLY]]
        return nil
    end
    containerInfo.macroCondition = macroCondition

    containerInfo.key = unit ..
        "_" .. (type(macroCondition) == 'string' and macroCondition or "nomacro")

    return { container = containerInfo, item = itemInfo }
end

local positionInfo = {
    CENTER = { location = "CENTER" },
    LEFT = { location = "LEFT" },
    RIGHT = { location = "RIGHT" },
    TOP = { location = "TOP" },
    BOTTOM = { location = "BOTTOM" },
    TOPRIGHT = { location = "TOPRIGHT" },
    TOPLEFT = { location = "TOPLEFT" },
    BOTTOMRIGHT = { location = "BOTTOMRIGHT" },
    BOTTOMLEFT = { location = "BOTTOMLEFT" },
    ["RIGHT (FLIPPED)"] = { location = "RIGHT", hFlip = true },
    ["BOTTOM (FLIPPED)"] = { location = "BOTTOM", vFlip = true },
    ["LEFT (CW)"] = { location = "LEFT", cw = 1 },
    ["LEFT (CCW)"] = { location = "LEFT", cw = -1 },
    ["LEFT (180)"] = { location = "LEFT", hFlip = true, vFlip = true },
    ["LEFT (VFLIPPED)"] = { location = "LEFT", vFlip = true },
    ["RIGHT (CW)"] = { location = "RIGHT", cw = 1 },
    ["RIGHT (CCW)"] = { location = "RIGHT", cw = -1 },
    ["RIGHT (180)"] = { location = "RIGHT", hFlip = true, vFlip = true },
    ["RIGHT (VFLIPPED)"] = { location = "RIGHT", vFlip = true },
    ["TOP (CW)"] = { location = "TOP", cw = 1 },
    ["TOP (CCW)"] = { location = "TOP", cw = -1 },
    ["TOP (180)"] = { location = "TOP", hFlip = true, vFlip = true },
    ["TOP (HFLIPPED)"] = { location = "TOP", hFlip = true },
    ["BOTTOM (CW)"] = { location = "BOTTOM", cw = 1 },
    ["BOTTOM (CCW)"] = { location = "BOTTOM", cw = -1 },
    ["BOTTOM (180)"] = { location = "BOTTOM", hFlip = true, vFlip = true },
    ["BOTTOM (HFLIPPED)"] = { location = "BOTTOM", hFlip = true },
}

--[[
    AuraContainerItem represents an individual aura within the container.
    It handles the creation and initialization of the aura button, as well as
    setting its texture, geometry, and visibility.
]]
SAO.AuraContainerItem = {
    new = function(self, id, container, overlay, options)
        local item = {
            id = id,
            container = container,

            -- Constants
            spellID = overlay.spellID,
            unit = options.unit,
            scale = overlay.scale,
            fontScale = 3,
            positions = splitPositions(overlay.position),
            level = overlay.level,
            autoPulse = overlay.autoPulse,
            useSound = overlay.autoPulse, -- Only pulsing overlays are worth having a sound
            texture = overlay.texture,
            r = overlay.r,
            g = overlay.g,
            b = overlay.b,

            -- Variables
            enabled = true, -- By default, the aura container item is enabled
            visible = true, -- By default, the aura container item is visible
            internallyEnabled = true, -- Whether the enable/visible state are applied internally
            auraButtons = {}, -- Assigned below; there will be as many buttons as there are positions
            slotKeys = {}, -- Assigned below; there will be as many slot keys as there are buttons
        }

        self.__index = nil
        setmetatable(item, self)
        self.__index = self

        for index, position in ipairs(item.positions) do
            local slotKey = "item_"..id.."_index_"..index

            local auraSlotOptions = {
                globalGeometry = options.globalGeometry,
                position = position,
                applications = options.nbAuraStacks,
            }

            local includeSpellIDs = { [overlay.spellID] = true }
            local akaSpellIDs = SAO:GetAkaSpellIDsByEffectSpellID(overlay.spellID)
            if akaSpellIDs then
                for _, akaSpellID in ipairs(akaSpellIDs) do
                    SAO:Trace(Module, "Adding aura slot with key "..tostring(slotKey).." for a.k.a. spellID", tostring(akaSpellID));
                    includeSpellIDs[akaSpellID] = true
                end
            end

            local auraButton = container:AddAuraSlot(slotKey, "HELPFUL", {
                templateNames = { "SAOAuraButtonTemplate" },
                initializeFrame = function(auraButton)
                    item:initializeAuraButton(auraButton, auraSlotOptions)
                end,
                candidateFilters = {
                    includeSpellIDs = includeSpellIDs,
                },
            })

            item.auraButtons[index] = auraButton
            item.slotKeys[index] = slotKey
        end

        if item.useSound then
            SAO.AuraSoundLibrary:enableItem(item)
        end

        return item
    end,

    initializeAuraButton = function(self, auraButton, options)
        -- Please note, at this point, we cannot rely on the fact that this button is in self.auraButtons

        auraButton:EnableMouse(false) -- Disable tooltip

        -- local auraIcon = auraButton.pulsableItem.applicationBar.auraIcon
        -- auraButton:SetIcon(auraIcon)

        self:setTexture(auraButton, options.position)

        self:setApplications(auraButton, options.applications)

        -- auraButton.staticItem.applicationCount:SetScale(self.fontScale * options.globalGeometry.scale)
        -- auraButton:SetApplicationCount(auraButton.staticItem.applicationCount)

        self:setCooldown(auraButton)

        auraButton:SetFrameLevel(self.level or 3)
        auraButton.staticItem:SetFrameLevel(auraButton:GetFrameLevel() + 1) -- @todo Maybe find a better way to give priority to the static item

        self:setButtonGeometry(auraButton, options.globalGeometry, options.position)

        if auraButton.pulsableItem.pulse then
            local mustPulse = self.autoPulse ~= false -- True by default
            if mustPulse then
                auraButton.pulsableItem.pulse:Play()
            end
        end

        if auraButton:GetIcon() then
            -- Hide GetIcon() because we want to control which texture is displayed
            -- Ideally, we would set the icon's texture, but it looks like the game client overrides it
            auraButton:GetIcon():Hide()
        end
    end,

    setTexture = function(self, auraButton, position)
        local texture = auraButton.pulsableItem.applicationBar.customTexture

        -- Set filename or file ID
        local textureFilenameOrID = self.texture
        if textureFilenameOrID and type(textureFilenameOrID) == 'function' then
            textureFilenameOrID = textureFilenameOrID()
        end
        if type(textureFilenameOrID) == 'string' and tonumber(textureFilenameOrID, 10) then
            textureFilenameOrID = tonumber(textureFilenameOrID, 10)
        end
        texture:SetTexture(textureFilenameOrID)

        -- local applicationBar = auraButton.staticItem.applicationBar
        -- applicationBar:SetStatusBarTexture(textureFilenameOrID)
        -- local applicationBarTexture = applicationBar:GetStatusBarTexture()
        -- Cannot use the application bar's texture directly because some features are not working as intended e.g., texcoords
        -- Rather, we use the application bar as a parent of other UI elements to filter based on number of applications

        -- Set texture coordinates
        position = position and strupper(position)
        local info = positionInfo[position]
        local texLeft, texRight, texTop, texBottom = 0, 1, 0, 1
        if info and info.cw and info.cw > 0 then
            texture:SetTexCoord(texLeft, texBottom, texRight, texBottom, texLeft, texTop, texRight, texTop)
        elseif info and info.cw and info.cw < 0 then
            texture:SetTexCoord(texRight, texTop, texLeft, texTop, texRight, texBottom, texLeft, texBottom)
        else
            if info and info.hFlip then
                texLeft, texRight = 1, 0
            end
            if info and info.vFlip then
                texTop, texBottom = 1, 0
            end
            texture:SetTexCoord(texLeft, texRight, texTop, texBottom)
        end

        -- Set vertex color
        texture:SetVertexColor(self.r / 255, self.g / 255, self.b / 255)
    end,

    setApplications = function(self, auraButton, applications)
        local applicationBar = auraButton.pulsableItem.applicationBar

        local minApplications, maxApplications = 0, 1
        if applications ~= 0 then
            minApplications, maxApplications = applications, applications
            applicationBar:SetFillStyle(Enum.StatusBarFillStyle.StandardNoRangeFill)
        end

        auraButton:SetApplicationBar(applicationBar, {
            minApplications = minApplications,
            maxApplications = maxApplications,
        })
    end,

    setCooldown = function(self, auraButton)
        local cooldown = auraButton.pulsableItem.applicationBar.cooldown
        auraButton:SetDurationCooldown(cooldown)
    end,

    setButtonGeometry = function(self, auraButton, globalGeometry, position)
        position = position and strupper(position)
        local info = positionInfo[position]
        local parent = auraButton:GetParent()
        local width, height
        local longSide = globalGeometry.longSide
        local shortSide = globalGeometry.shortSide

        auraButton:ClearAllPoints()
        if info and info.location == "CENTER" then
            width, height = longSide, longSide
            auraButton:SetPoint("CENTER", parent, "CENTER", 0, 0)
        elseif info and info.location == "LEFT" then
            width, height = shortSide, longSide
            auraButton:SetPoint("RIGHT", parent, "LEFT", 0, 0)
        elseif info and info.location == "RIGHT" then
            width, height = shortSide, longSide
            auraButton:SetPoint("LEFT", parent, "RIGHT", 0, 0)
        elseif info and info.location == "TOP" then
            width, height = longSide, shortSide
            auraButton:SetPoint("BOTTOM", parent, "TOP")
        elseif info and info.location == "BOTTOM" then
            width, height = longSide, shortSide
            auraButton:SetPoint("TOP", parent, "BOTTOM")
        elseif info and info.location == "TOPRIGHT" then
            width, height = shortSide, shortSide
            auraButton:SetPoint("BOTTOMLEFT", parent, "TOPRIGHT", 0, 0)
        elseif info and info.location == "TOPLEFT" then
            width, height = shortSide, shortSide
            auraButton:SetPoint("BOTTOMRIGHT", parent, "TOPLEFT", 0, 0)
        elseif info and info.location == "BOTTOMRIGHT" then
            width, height = shortSide, shortSide
            auraButton:SetPoint("TOPLEFT", parent, "BOTTOMRIGHT", 0, 0)
        elseif info and info.location == "BOTTOMLEFT" then
            width, height = shortSide, shortSide
            auraButton:SetPoint("TOPRIGHT", parent, "BOTTOMLEFT", 0, 0)
        else
            SAO:Warn(Module, "Unknown aura position is not supported: "..tostring(position)) --[[DEV_ONLY]]
            return
        end

        auraButton.staticItem.applicationCount:SetScale(self.fontScale * globalGeometry.scale)

        auraButton:SetSize(width * self.scale, height * self.scale)
    end,

    setGeometry = function(self, globalGeometry)
        for index, auraButton in ipairs(self.auraButtons) do
            self:setButtonGeometry(auraButton, globalGeometry, self.positions[index])
        end
    end,

    -- 'Enabled' means wanted by the player
    -- The item is enabled unless the player explicitly disables it from the options panel
    setEnabled = function(self, enabled)
        traceBooleanChange("setEnabled", self.enabled, enabled, self.id) --[[DEV_ONLY]]
        if enabled == self.enabled then
            return
        end
        self.enabled = enabled
        self:_internalSetAuraSlotEnabled(self.enabled and self.visible)
    end,

    -- 'Visible' means currently explicitly wanted to be shown
    -- The item is visible unless a non-aura trigger (e.g. stance) explicitly asks to hide it
    setVisible = function(self, visible)
        traceBooleanChange("setVisible", self.visible, visible, self.id) --[[DEV_ONLY]]
        if visible == self.visible then
            return
        end
        self.visible = visible
        self:_internalSetAuraSlotEnabled(self.enabled and self.visible)
    end,

    _internalSetAuraSlotEnabled = function(self, enabled)
        if self.internallyEnabled == enabled then
            return
        end
        self.internallyEnabled = enabled

        if self.useSound then
            if enabled then
                SAO.AuraSoundLibrary:enableItem(self)
            else
                SAO.AuraSoundLibrary:disableItem(self)
            end
        end

        if not self.container.SetAuraSlotEnabled then -- AuraContainer:SetAuraSlotEnabled is required to make this functionality work
            SAO:Debug(Module, "Cannot change internal enabling state of aura container item ", tostring(self.id))
            return
        end

        for _, slotKey in ipairs(self.slotKeys) do
            self.container:SetAuraSlotEnabled(slotKey, enabled)
        end
    end,
}

--[[
    AuraContainer manages a collection of AuraContainerItem(s).
    It handles:
    - the creation of new aura container items
    - the updating of all container items from a single entry point
]]
SAO.AuraContainer = {
    initialize = function(self, parent, initialGlobalGeometry)
        if not useAuraContainer or self.initialized then
            return
        end

        if LoadAddOn then
            local loaded, reason = LoadAddOn("Blizzard_AuraContainer")
            if not loaded and reason ~= "ALREADY_LOADED" then
                SAO:Warn(Module, "Unable to load Blizzard_AuraContainer: "..tostring(reason))
                return
            end
        end

        self.globalGeometry = {
            geometry = initialGlobalGeometry,
            updatedAt = GetTime(),
            pendingTimer = nil,
        }
        self.parent = parent
        self.containers = {} -- Will be populated by getOrCreateContainer
        self.items = {} -- Will be populated by registerOverlay
        self.initialized = true
    end,

    -- Get or create an aura container based on the provided hash information
    getOrCreateContainer = function(self, hashInfo)
        assertsafe(type(hashInfo) == 'table' and type(hashInfo.container) == 'table' and type(hashInfo.container.key) == 'string')

        local container = self.containers[hashInfo.container.key]
        if container then
            return container
        end

        container = CreateFrame("AuraContainer", "SpellActivationOverlayAuraContainer", self.parent, "CustomAuraContainerTemplate")
        container:SetAllPoints()
        container:SetPoint("CENTER")
        container:SetUnit(hashInfo.container.unit)
        container:SetEnabled(true)

        if type(hashInfo.container.macroCondition) == 'string' then
            if InCombatLockdown() then
                -- RegisterStateDriver will trigger errors if called during combat
                SAO:Debug(Module, "Delaying macro conditional until leaving combat:", hashInfo.container.macroCondition)
                container:Hide()
                SAO:AddPendingOperation("ooc", function()
                    container:Show()
                    RegisterStateDriver(container, "visibility", hashInfo.container.macroCondition .. " show; hide")
                end)
            else
                RegisterStateDriver(container, "visibility", hashInfo.container.macroCondition .. " show; hide")
            end
        end

        self.containers[hashInfo.container.key] = container
        return container
    end,

    --[[
        Register a secret-compatible overlay for a spell
        Returns nil if either
        - the addon is not capable of handling secret-compatible overlays
        - or the spell does not need such overlay (e.g., is not secret in combat)
    ]]
    registerOverlay = function(self, overlay)
        if not useAuraContainer then
            -- Aura containers are not supported / not required for the current flavor
            return nil
        end

        if not self.initialized then
            SAO:Error(Module, "Registering an overlay of spell "..tostring(overlay.spellID).." before AuraContainer is initialized")
            return nil
        end

        if not SAO:IsSpellSecret(overlay.spellID) then
            -- We don't need to create a secret-compatible overlay for spells that are not secret in combat
            return nil
        end

        local hashInfo = getInfoFromHash(SAO.Hash:new(overlay.hash), overlay.macroCondition, overlay.spellID)
        if not hashInfo then
            -- An empty hash info means the hash is not supported, for good or bad reasons (look for messages to know more)
            return nil
        end

        local container = self:getOrCreateContainer(hashInfo)
        assertsafe(container)

        local id = ("container:"..hashInfo.container.key) ..
            ("_spell:"..overlay.spellID) ..
            ("_hash:"..tostring(overlay.hash)) ..
            ("_pos:"..overlay.position)

        if self.items[id] then
            SAO:Error(Module, "Overlay already registered for id "..tostring(id))
            return
        end

        local buttonOptions = hashInfo.item
        buttonOptions.globalGeometry = self.globalGeometry.geometry
        local button = SAO.AuraContainerItem:new(id, container, overlay, buttonOptions)

        self.items[id] = button

        return button
    end,

    updateGeometry = function(self, globalGeometry)
        if not useAuraContainer or not self.initialized then
            return
        end

        for _, item in pairs(self.items) do
            item:setGeometry(globalGeometry)
        end

        self.globalGeometry.geometry = globalGeometry
        self.globalGeometry.updatedAt = GetTime()
    end,
}
