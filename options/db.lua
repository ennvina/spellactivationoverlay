local AddonName, SAO = ...

-- Load database and use default values if needed
function SAO.LoadDB(self)
    local currentversion = 060;
    local db = SpellActivationOverlayDB or {};

    if not db.alert then
        db.alert = {};
        db.alert.enabled = true;
        db.alert.opacity = 1;
        db.alert.offset = 0;
        db.alert.scale = 1;
    end

    if not db.glow then
        db.glow = {};
        db.glow.enabled = true;
    end

    db.version = currentversion;
    SpellActivationOverlayDB = db;
end

-- Utility frame dedicated to react to variable loading
local loader = CreateFrame("Frame", "SpellActivationOverlayDBLoader");
loader:RegisterEvent("VARIABLES_LOADED");
loader:SetScript("OnEvent", function (event)
    SAO:LoadDB();
    SAO:ApplyAllVariables();
    SpellActivationOverlayOptionsPanel_Init(SAO.OptionsPanel);
    loader:UnregisterEvent("VARIABLES_LOADED");
end);
