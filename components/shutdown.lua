local AddonName, SAO = ...
local Module = "shutdown"

-- Fix of options functions, also seen in options\InterfaceOptionsPanels.lua
local InterfaceOptionsFrame_OpenToCategory = InterfaceOptionsFrame_OpenToCategory
if Settings and Settings.RegisterCanvasLayoutCategory then
    -- Deprecated. Use Settings.OpenToCategory().
    InterfaceOptionsFrame_OpenToCategory = function(categoryIDOrFrame)
        if type(categoryIDOrFrame) == "table" then
            local categoryID = categoryIDOrFrame.name;
            return Settings.OpenToCategory(categoryID);
        else
            return Settings.OpenToCategory(categoryIDOrFrame);
        end
    end
end

local Categories = {
    UNSUPPORTED_CLASS = {
        Priority = 0,
        Get = function()
            return {
                Reason = SAO:unsupportedClass(),
                Button = nil, -- There are no obvious action to suggest
                DisableCondition = nil, -- There are no conditions: disabling is absolute
            }
        end,
    },
    DISABLED_CLASS = {
        Priority = 1,
        Get = function()
            return {
                Reason = SAO:disabledClass():gsub(" %%s", ""):gsub("%%s",""):gsub(" :%)", ""),
                Button = nil, -- There are no obvious action to suggest
                DisableCondition = nil, -- There are no conditions: disabling is absolute
            }
        end,
    },
    SAO_INSTALLED = {
        Priority = 2,
        Get = function()
            return {
                Reason = SAO:becauseOf("Spell".."ActivationOverlay"),
                Button = {
                    ShowIf = function()
                        return _G["Spell".."ActivationOverlayDB"] ~= nil;
                    end,
                    Text = SAO:openIt("Spell".."ActivationOverlay"),
                    OnClick = function() -- Passed to SetScript
                        InterfaceOptionsFrame_OpenToCategory(_G["Spell".."ActivationOverlayOptionsPanel"]);
                    end
                },
                DisableCondition = {
                    ShowIf = function()
                        return SpellActivationOverlayDB ~= nil;
                    end,
                    Text = SAO:disableWhenInstalled("Spell".."ActivationOverlay"),
                    OnValueChanged = function(self, checked)
                        SpellActivationOverlayDB.disableIfSAO = checked;
                    end,
                    IsDisabled = function()
                        -- Disable addon if option is set to true, and only true
                        return SpellActivationOverlayDB.disableIfSAO == true or SpellActivationOverlayDB.disableIfSAO == nil;
                    end,
                }
            }
        end,
    },
    NECROSIS_INSTALLED = {
        Priority = 3,
        Get = function()
            return {
                Reason = SAO:becauseOf("|CFFFF00FFNe|CFFFF50FFcr|CFFFF99FFos|CFFFFC4FFis|CFFFFFFFF"), -- "Necrosis", with colors
                Button = {
                    ShowIf = function()
                        return NecrosisSpellActivationOverlayOptionsPanel ~= nil;
                    end,
                    Text = SAO:openIt("Necrosis Spell Activations"),
                    OnClick = function() -- Passed to SetScript
                        InterfaceOptionsFrame_OpenToCategory(NecrosisSpellActivationOverlayOptionsPanel);
                    end
                },
                DisableCondition = {
                    ShowIf = function()
                        return NecrosisConfig ~= nil;
                    end,
                    Text = SAO:disableWhenInstalled("Necrosis"),
                    OnValueChanged = function(self, checked)
                        SpellActivationOverlayDB.disableIfNecrosis = checked;
                    end,
                    IsDisabled = function()
                        -- Disable addon if option is set to true, or option is not set yet (i.e. default value)
                        return SpellActivationOverlayDB.disableIfNecrosis == true;
                    end,
                },
            }
        end,
    },
}

local Shutdown = {
    TriggeredCategories = {},
    CurrentCategory = nil,
}

-- Check if the addon should be disabled due to shutdown
-- Shutting down does not mean the addon stops functioning, it means no new effects can happen
-- Effects currently active can still be disabled
function Shutdown:IsAddonDisabled()
    local category = self.CurrentCategory;
    if not category then
        -- No category means there's no reason to shut down
        return false;
    end
    if not category.DisableCondition then
        -- No disable condition means we must always shut down
        return true;
    end
    -- Otherwise, let the disable condition have the final word
    return category.DisableCondition.IsDisabled();
end

-- Get the current shutdown category
-- No category means there is no reason to shut down
function Shutdown:GetCategory()
    return self.CurrentCategory;
end

-- Set a new shutdown category candidate
-- The candidate will become the current category if it has a stronger priority (lower is stronger) than an existing candidate
function Shutdown:EnableCategory(name)
    local rawCategory = Categories[name];
    if not rawCategory then
        SAO:Error(Module, "Unknown shutdown category", name);
    end

    if tContains(self.TriggeredCategories, name) then
        SAO:Debug(Module, "Re-enabling shutdown category", name);
        return;
    end

    tinsert(self.TriggeredCategories, name);
    SAO:Debug(Module, "Enabling shutdown category", name);
    if self.CurrentCategory and self.CurrentCategory.Priority < rawCategory.Priority then
        return;
    end

    local category = rawCategory.Get();
    category.Name = name;
    category.Priority = rawCategory.Priority;

    self.CurrentCategory = category;
end

SAO.Shutdown = Shutdown;
