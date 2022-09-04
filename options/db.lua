Addon, SAO =...

-- Load database and use default values if needed
function SAO.LoadDB(self)
    local currentversion = 060;
    local db = SpellActivationOverlayDB or {};

    if not db.alert then
        db.alert = {};
        db.alert.enabled = true;
        db.alert.opacity = 1;
    end

    if not db.glow then
        db.glow = {};
        db.glow.enabled = true;
    end

    db.version = currentversion;
    SpellActivationOverlayDB = db;
end

local frame = CreateFrame("Frame", "SpellActivationOverlayDBLoader");
frame:RegisterEvent("VARIABLES_LOADED");
frame:SetScript("OnEvent", function (event)
    SAO.LoadDB();
    SpellActivationOverlayOptionsPanel_Init();
    frame:UnregisterEvent("VARIABLES_LOADED");
end);
