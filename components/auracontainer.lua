local AddonName, SAO = ...
local Module = "auracontainer"

local LoadAddOn = C_AddOns and C_AddOns.LoadAddOn or LoadAddOn

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
    if not self.IsRetail() or self.AuraContainer then
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

function SAO:RegisterAuraContainerBucketOverlay(bucket, overlayPod)
    local container = self.AuraContainer
    local id = overlayPod.index * 10000000 + bucket.spellID;
    if not container or not bucket or self.AuraContainerBuckets[id] then
        return
    end

    local spellID = bucket.spellID

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
end
