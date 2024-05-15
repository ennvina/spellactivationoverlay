local AddonName, SAO = ...
local Module = "display"

--[[
    Display object
    Has a list of overlays and buttons
    Has functions to show/hide them
]]
SAO.Display = {
    new = function(self, spellID, stacks)
        local display = {
            spellID = spellID,
            stacks = stacks,
            overlays = {},
            buttons = {},
            combatOnly = false,
        }

        self.__index = nil;
        setmetatable(display, self);
        self.__index = self;

        return display;
    end,

    addOverlay = function(self, overlay)
        if not overlay.spellID then
            SAO:Warn(Module, "Missing spellID for overlay");
        end
        if not overlay.texture then
            SAO:Warn(Module, "Missing texture for overlay");
        end
        if not overlay.position then
            SAO:Warn(Module, "Missing position for overlay");
        end

        local _overlay = {
            stacks = overlay.stacks or 0,
            spellID = overlay.spellID,
            texture = overlay.texture,
            position = overlay.position,
            scale = overlay.scale or 1,
            r = overlay.color and overlay.color[1] or 255,
            g = overlay.color and overlay.color[2] or 255,
            b = overlay.color and overlay.color[3] or 255,
            autoPulse = overlay.autoPulse ~= false, -- true by default
            combatOnly = overlay.combatOnly == true, -- false by default
        }

        if _overlay.stacks ~= self.stacks then
            SAO:Warn(Module, "Inconsistent stacks between display and overlay: "..tostring(self.stacks).." vs. "..tostring(_overlay.stacks));
        end
        if _overlay.spellID ~= self.spellID then
            SAO:Warn(Module, "Inconsistent spellID between display and overlay: "..tostring(self.spellID).." vs. "..tostring(_overlay.spellID));
        end

        tinsert(self.overlays, _overlay);
    end,

    addButton = function(self, button)
        if type(button) ~= 'number' and type(button) ~= 'string' then
            SAO:Warn(Module, "Wrong spell for button");
        end

        tinsert(self.buttons, button);
    end,

    setCombatOnly = function(self, combatOnly)
        self.combatOnly = combatOnly;
    end,

    showOverlays = function(self, options)
        for _, overlay in ipairs(self.overlays) do
            local forcePulsePlay = nil;
            if options and options.mimicPulse then
                forcePulsePlay = overlay.autoPulse;
            end
            SAO:ActivateOverlay(overlay.stacks, overlay.spellID, overlay.texture, overlay.position, overlay.scale, overlay.r, overlay.g, overlay.b, overlay.autoPulse, forcePulsePlay, nil, overlay.combatOnly);
        end
    end,

    hideOverlays = function(self)
        if #self.overlays > 0 then
            SAO:DeactivateOverlay(self.spellID);
        end
    end,

    showButtons = function(self, options)
        if #self.buttons > 0 then
            SAO:AddGlow(self.spellID, self.buttons);
        end
    end,

    hideButtons = function(self)
        if #self.buttons > 0 then
            SAO:RemoveGlow(self.spellID);
        end
    end,

    -- Display overlays and buttons
    -- @note unlike individual showOverlays() and showButtons(), this main show() will mark the display
    show = function(self, options)
        SAO:Debug(Module, "Showing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        SAO:MarkDisplay(self.spellID, self.stacks);
        self:showOverlays(options);
        self:showButtons(options);
    end,

    -- Hide overlays and buttons
    -- @note unlike individual hideOverlays() and hideButtons(), this main hide() will un-mark the display
    hide = function(self)
        SAO:Debug(Module, "Removing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        SAO:UnmarkDisplay(self.spellID);
        self:hideOverlays();
        self:hideButtons();
    end,

    refresh = function(self)
        SAO:Debug(Module, "Refreshing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        SAO:RefreshOverlayTimer(self.spellID);
    end,
}

--[[
    List of markers for each display activated excplicitly and completely with, usually from Display:show()
    Key = spellID, Value = number of stacks, or nil if marker is reset

    This list looks redundant with SAO.ActiveOverlays, but there are significant differences:
    - ActiveOverlays tracks absolutely every overlay, while DisplayMarkers is focused on "displays from CLEU"
    - ActiveOverlays is limited to effects that have an overlay, while DisplayMarkers tracks effects with or without overlays
]]
SAO.DisplayMarkers = {}

function SAO:MarkDisplay(spellID, count)
    if type(count) ~= 'number' then
        self:Debug(Module, "Marking display of "..tostring(spellID).." with invalid count "..tostring(count));
    end
    if type(self.DisplayMarkers[spellID]) == 'number' then
        self:Debug(Module, "Marking display of "..tostring(spellID).." with count "..tostring(count).." but it already has a count of "..self.DisplayMarkers[spellID]);
    end
    self.DisplayMarkers[spellID] = count;
end

function SAO:UnmarkDisplay(spellID)
    self.DisplayMarkers[spellID] = nil;
end

function SAO:GetDisplayMarker(spellID)
    return self.DisplayMarkers[spellID];
end
