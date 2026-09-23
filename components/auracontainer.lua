local AddonName, SAO = ...
local Module = "auracontainer"

local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn

local useAuraContainer = SAO.IsRetail()

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
    new = function(self, id, container, overlay, initialGlobalGeometry)
        local item = {
            id = id,

            -- Constants
            spellID = overlay.spellID,
            scale = overlay.scale,
            position = overlay.position,
            level = overlay.level,
            autoPulse = overlay.autoPulse,
            texture = overlay.texture,
            r = overlay.r,
            g = overlay.g,
            b = overlay.b,

            -- Variables
            auraButton = nil, -- Assigned before the end of the constructor
        }

        self.__index = nil;
        setmetatable(item, self);
        self.__index = self;

        local auraButton = container:AddAuraSlot("spell_"..id, "HELPFUL", {
            templateNames = { "SAOAuraButtonTemplate" },
            initializeFrame = function(auraButton)
                item:initializeAuraButton(auraButton, initialGlobalGeometry)
            end,
            candidateFilters = {
                includeSpellIDs = { [overlay.spellID] = true },
            },
        })

        item.auraButton = auraButton

        return item;
    end,

    initializeAuraButton = function(self, auraButton, initialGlobalGeometry)
        -- Please note, at this point, we cannot rely on the fact that self.auraButton == auraButton
        self.pulse = auraButton.pulse
        auraButton:SetIcon(auraButton.auraIcon)

        self:setTexture(auraButton)

        auraButton:SetDurationCooldown(auraButton.cooldown)
        auraButton:SetApplicationCount(auraButton.count)

        if self.level then -- Optional
            auraButton:SetFrameLevel(self.level)
        end

        self:setGeometry(auraButton, initialGlobalGeometry)

        if auraButton:GetIcon() then
            -- Hide GetIcon() because we want to control which texture is displayed
            -- Ideally, we would set the icon's texture, but it looks like the game client overrides it
            auraButton:GetIcon():Hide()
        end
    end,

    setTexture = function(self, auraButton)
        local texture = auraButton.customTexture

        -- Set filename or file ID
        local customTexture = self.texture
        if customTexture and type(customTexture) == 'function' then
            customTexture = customTexture()
        end
        if type(customTexture) == 'string' and tonumber(customTexture, 10) then
            customTexture = tonumber(customTexture, 10)
        end
        texture:SetTexture(customTexture)

        -- Set texture coordinates
        local position = self.position and strupper(self.position)
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

    setGeometry = function(self, auraButton, globalGeometry)
        local position = self.position and strupper(self.position)
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
            if position then --[[BEGIN_DEV_ONLY]]
                SAO:Warn(Module, "Composite or unknown aura position is not supported: "..tostring(self.position))
            end --[[END_DEV_ONLY]]
            return
        end

        auraButton:SetSize(width * self.scale, height * self.scale)
    end,

    setVisible = function(self, visible)
        local auraButton = self.auraButton

        if auraButton then
            local pulse = self.pulse
            if visible then
                if pulse then
                    pulse.autoPlay = self.autoPulse
                    if pulse.autoPlay and not pulse:IsPlaying() then
                        pulse:Play()
                    end
                end
                auraButton:Show() -- @todo set parent's opacity to 100% instead
            else
                if pulse then
                    pulse:Stop()
                end
                auraButton:Hide() -- @todo set parent's opacity to 0% instead
            end
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

        local container = CreateFrame("AuraContainer", "SpellActivationOverlayAuraContainer", parent, "CustomAuraContainerTemplate")
        container:SetSize(initialGlobalGeometry.containerSize, initialGlobalGeometry.containerSize)
        container:SetPoint("CENTER")
        container:SetUnit("player")
        container:SetEnabled(true)

        -- if RegisterStateDriver then
        --     RegisterStateDriver(container, "visibility", "[combat] show; hide")
        -- end

        self.container = container
        self.globalGeometry = {
            geometry = initialGlobalGeometry,
            updatedAt = GetTime(),
            pendingTimer = nil,
        }
        self.items = {}
        self.initialized = true
    end,

    registerOverlay = function(self, overlay)
        if not useAuraContainer or not self.initialized then
            return nil
        end

        local id = overlay.index * 10000000 + overlay.spellID;
        if self.items[id] then --[[BEGIN_DEV_ONLY]]
            SAO:Warn(Module, "Overlay already registered for id "..tostring(id))
            return
        end --[[END_DEV_ONLY]]

        local button = SAO.AuraContainerItem:new(id, self.container, overlay, self.globalGeometry.geometry)

        self.items[id] = button

        return button
    end,

    updateGeometry = function(self, globalGeometry)
        if not useAuraContainer or not self.initialized then
            return
        end

        local containerSize = globalGeometry.containerSize
        local recentUpdate = self.globalGeometry.updatedAt
        if GetTime() == recentUpdate then
            -- Must delay ever so slightly, otherwise the new size might not be applied correctly
            if self.globalGeometry.pendingTimer then
                self.globalGeometry.pendingTimer:Cancel()
            end
            self.globalGeometry.pendingTimer = C_Timer.NewTimer(0, function()
                self.container:SetSize(containerSize, containerSize)
                self.globalGeometry.pendingTimer = nil
            end)
        else
            self.container:SetSize(containerSize, containerSize)
        end

        for _, item in pairs(self.items) do
            item:setGeometry(item.auraButton, globalGeometry)
        end

        self.globalGeometry.geometry = globalGeometry
        self.globalGeometry.updatedAt = GetTime()
    end,
}
