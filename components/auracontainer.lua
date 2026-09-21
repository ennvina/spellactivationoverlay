local AddonName, SAO = ...
local Module = "auracontainer"

local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn

local useAuraContainer = SAO.IsRetail()

local xOffset = -256

local function initializeAuraButton(button, overlayPod)
    -- @todo use overlayPod to determine the initial position and size of the button
    button:SetSize(128, 256)
    button:SetPoint("CENTER", xOffset, 0)
    xOffset = xOffset + 128

    button:SetIcon(button.auraIcon)

    local customTexture = overlayPod.texture
    if customTexture and type(customTexture) == 'function' then
        customTexture = customTexture()
    end
    if type(customTexture) == 'string' and tonumber(customTexture, 10) then
        customTexture = tonumber(customTexture, 10)
    end
    if customTexture and button.customTexture then
        button.customTexture:SetTexture(customTexture)
    end

    button:SetDurationCooldown(button.cooldown)
    button:SetApplicationCount(button.count)
end

function SAO:InitializeAuraContainer()
    if not useAuraContainer or self.AuraContainer then
        return
    end

    if LoadAddOn then
        local loaded, reason = LoadAddOn("Blizzard_AuraContainer")
        if not loaded and reason ~= "ALREADY_LOADED" then
            self:Warn(Module, "Unable to load Blizzard_AuraContainer: "..tostring(reason))
            return
        end
    end

    local parent = SpellActivationOverlayContainerFrame or UIParent
    local container = CreateFrame("AuraContainer", "SpellActivationOverlayAuraContainer", parent, "CustomAuraContainerTemplate")
    container:SetSize(256, 256)
    container:SetPoint("CENTER")
    container:SetUnit("player")
    container:SetEnabled(true)
    container:Show()

    -- if RegisterStateDriver then
    --     RegisterStateDriver(container, "visibility", "[combat] show; hide")
    -- end

    self.AuraContainer = container
    self.AuraContainerBuckets = {}
end

function SAO:RegisterAuraContainerOverlay(overlayPod)
    if not useAuraContainer then
        return nil
    end

    local container = self.AuraContainer
    if not container or not overlayPod then --[[BEGIN_DEV_ONLY]]
        SAO:Warn(Module, "Invalid overlayPod or container not initialized")
        return
    end --[[END_DEV_ONLY]]

    local id = overlayPod.index * 10000000 + overlayPod.spellID;
    if self.AuraContainerBuckets[id] then --[[BEGIN_DEV_ONLY]]
        SAO:Warn(Module, "Overlay already registered for id "..tostring(id))
        return
    end --[[END_DEV_ONLY]]

    local spellID = overlayPod.spellID

    local auraButton = container:AddAuraSlot("spell_"..id, "HELPFUL", {
        templateNames = { "SAOAuraButtonTemplate" },
        initializeFrame = function(button)
            initializeAuraButton(button, overlayPod)
        end,
        candidateFilters = {
            includeSpellIDs = { [spellID] = true },
        },
    })

    if auraButton:GetIcon() then
        -- Hide GetIcon() because it will be replaced by a custom texture
        auraButton:GetIcon():Hide()
    end

    self.AuraContainerBuckets[id] = auraButton

    return auraButton
end

function SAO:SetAuraContainerOverlayDisplayed(auraButton, displayed)
    if auraButton then
        if displayed then
            auraButton:Show() -- @todo set parent's opacity to 100% instead
        else
            auraButton:Hide() -- @todo set parent's opacity to 0% instead
        end
    end
end
