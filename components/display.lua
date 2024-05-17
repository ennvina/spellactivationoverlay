local AddonName, SAO = ...
local Module = "display"

--[[
    Display object
    Has a list of overlays and buttons
    Has functions to show/hide them
]]
SAO.Display = {
    new = function(self, parent, hash) -- parent is the bucket attached to the new trigger
        local display = {
            parent = parent,

            spellID = parent.spellID,
            hash = hash,
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
    -- @note unlike individual showOverlays() and showButtons(), this main show() will set the bucket's displayedHash
    show = function(self, options)
        SAO:Debug(Module, "Showing hash "..self.hash.." of "..self.parent.description);
        self.parent.displayedHash = self.hash;
        self:showOverlays(options);
        self:showButtons(options);
    end,

    -- Hide overlays and buttons
    -- @note unlike individual hideOverlays() and hideButtons(), this main hide() will unset the bucket's displayedHash
    hide = function(self)
        SAO:Debug(Module, "Hiding hash "..self.hash.." of "..self.parent.description);
        self.parent.displayedHash = nil;
        self:hideOverlays();
        self:hideButtons();
    end,

    refresh = function(self)
        SAO:Debug(Module, "Refreshing aura of "..self.spellID.." "..(GetSpellInfo(self.spellID) or ""));
        SAO:RefreshOverlayTimer(self.spellID);
    end,
}
