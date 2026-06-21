local AddonName, SAO = ...
local Module = "db"

local applyDefaultClassData = function(classData, defaultClassData)
    for optionType, optionData in pairs(defaultClassData) do
        if (not classData[optionType]) then
            classData[optionType] = CopyTable(optionData);
        else
            for auraID, auraData in pairs(optionData) do
                if (not classData[optionType][auraID]) then
                    classData[optionType][auraID] = CopyTable(auraData);
                else
                    for hashID, hashData in pairs(auraData) do
                        if (type(classData[optionType][auraID][hashID]) == 'nil') then
                            if (type(hashData) == 'table') then
                                classData[optionType][auraID][hashID] = CopyTable(hashData);
                            else
                                classData[optionType][auraID][hashID] = hashData;
                            end
                        elseif (type(classData[optionType][auraID][hashID]) == "table" and type(hashData) == 'table') then
                            for id, value in pairs(hashData) do
                                if (type(classData[optionType][auraID][hashID][id]) == 'nil') then
                                    classData[optionType][auraID][hashID][id] = value;
                                end
                            end
                        end
                    end
                end
            end
        end
    end
end

--[[
    Utility functions to change a database option
]]

-- Transfer option between two different aura IDs and/or node IDs
local function transferOption(db, classFile, optionType, oldAuraID, oldNodeID, newAuraID, newNodeID)
    if type(db.classes[classFile][optionType][oldAuraID][oldNodeID]) ~= 'nil' and type(db.classes[classFile][optionType][newAuraID][newNodeID]) == 'nil' then
        db.classes[classFile][optionType][newAuraID][newNodeID] = db.classes[classFile][optionType][oldAuraID][oldNodeID];
    end
end

-- Forcefully disable an option from the database, even if the player had enabled it
local function retrogradeOption(db, classFile, optionType, auraID, nodeID)
    db.classes[classFile][optionType][auraID][nodeID] = false;
end

-- Promote an option from bool to string
local function promoteOptionFromBoolToString(db, classFile, optionType, auraID, nodeID)
    if db.classes[classFile][optionType][auraID][nodeID] == true and SAO.defaults.classes[classFile][optionType][auraID][nodeID] then
        db.classes[classFile][optionType][auraID][nodeID] = SAO.defaults.classes[classFile][optionType][auraID][nodeID];
    end
end

--[[
    Migration functions
]]

local migrations = {
    {"0.9.1", function(db)
        -- Warrior glowing buttons changed from boolean to string
        local warriorSpells = {
            7384, -- Overpower
            6572, -- Revenge
            5308, -- Execute
        }
        for _, spellID in ipairs(warriorSpells) do
            promoteOptionFromBoolToString(db, "WARRIOR", "glow", spellID, spellID);
        end

        -- Classic Era mages probably want Clearcasting by default, because it's the only proc available
        if SAO.IsEra() then
            db.classes["MAGE"]["alert"][12536][0] = SAO.defaults.classes["MAGE"]["alert"][12536][0];
        end
    end},

    {"1.1.2", function(db)
        -- Rogue Riposte options changed from boolean to string
        local riposte = 14251;
        promoteOptionFromBoolToString(db, "ROGUE", "alert", riposte, 0);
        promoteOptionFromBoolToString(db, "ROGUE", "glow", riposte, riposte);
    end},

    {"1.3.1", function(db)
        -- Cataclysm introduced Pyroblast!, a variant from Pyroblast (notice the bang '!' character in the former spell name)
        -- We copy options from Pyroblast to Pyroblast!, because we assume mages want to keep the same option
        local hotStreak = 48108;
        local pyro = 11366;
        local pyroBang = 92315;
        transferOption(db, "MAGE", "glow", hotStreak, pyro, hotStreak, pyroBang);

        -- Same for Fingers of Frost, which has a new spell ID, because the effect was reworked
        local fingersOfFrostWrath = 74396;
        local fingersOfFrostCata = 44544;
        local iceLance = 30455;
        local deepFreeze = 44572;
        transferOption(db, "MAGE", "alert", fingersOfFrostWrath, 0, fingersOfFrostCata, 0);
        transferOption(db, "MAGE", "glow", fingersOfFrostWrath, iceLance, fingersOfFrostCata, iceLance);
        transferOption(db, "MAGE", "glow", fingersOfFrostWrath, deepFreeze, fingersOfFrostCata, deepFreeze);
    end},

    {"1.4.0", function(db)
        -- Priest's Serendipity in Cataclysm has 2 stacks at most (down from 3 in Wrath)
        -- We copy options from Wrath:0/3 to Cataclysm:1/2, because we assume priests want to transfer these settings
        local serendipityWrath = 63734;
        local serendipityCata = 63735;
        local greaterHeal = 2060;
        local prayerOfHealing = 596;
        transferOption(db, "PRIEST", "alert", serendipityWrath, 0, serendipityCata, 1);
        transferOption(db, "PRIEST", "alert", serendipityWrath, 3, serendipityCata, 2);
        transferOption(db, "PRIEST", "glow", serendipityWrath, greaterHeal, serendipityCata, greaterHeal);
        transferOption(db, "PRIEST", "glow", serendipityWrath, prayerOfHealing, serendipityCata, prayerOfHealing);
    end},

    {"1.4.3", function(db)
        -- Priest's Surge of Lightning in Cataclysm triggers a new version of Flash Heal
        local surgeOfLightWrath = 33151;
        local surgeOfLightCata = 88688;
        local flashHeal = 2061;
        local flashHealNoMana = 101062;
        transferOption(db, "PRIEST", "glow", surgeOfLightWrath, flashHeal, surgeOfLightCata, flashHealNoMana);
    end},

    {"2.5.0", function(db)
        -- Priest's Surge of Lightning in Mists of Pandaria triggers again the normal Flash Heal, but uses another buff
        local surgeOfLightCata = 88688;
        local surgeOfLightMoP = 114255;
        local flashHealNoMana = 101062;
        local flashHeal = 2061;
        transferOption(db, "PRIEST", "alert", surgeOfLightCata, 0, surgeOfLightMoP, 0);
        transferOption(db, "PRIEST", "glow", surgeOfLightCata, flashHealNoMana, surgeOfLightMoP, flashHeal);
    end},

    {"2.5.7", function(db)
        -- Shaman's Lava Burst glowing button should be disabled by default starting from Mists of Pandaria
        if SAO.IsProject(SAO.MOP_AND_ONWARD) then
            local lavaBurst = 51505;
            retrogradeOption(db, "SHAMAN", "glow", lavaBurst, lavaBurst);
        end
    end},

    {"2.7.5", function(db)
        -- Era/TBC/Wrath Shaman Elemental Focus option changed from boolean to string
        if SAO.IsProject(SAO.ERA + SAO.TBC + SAO.WRATH) then
            local elemantalFocus = 16246;
            promoteOptionFromBoolToString(db, "SHAMAN", "alert", elemantalFocus, 0);
        end
    end},
}

-- Load database and use default values if needed
function SAO.LoadDB(self)
    local db = SpellActivationOverlayDB or {};

    if not db.alert then
        db.alert = {};
    end
    if (type(db.alert.enabled) == "nil" and type(db.alert.opacity) == "nil") then
        db.alert.enabled = true;
        db.alert.opacity = 1;
    elseif (type(db.alert.opacity) == "nil") then
        db.alert.opacity = db.alert.enabled and 1 or 0;
    elseif (type(db.alert.enabled) == "nil") then
        db.alert.enabled = db.alert.opacity > 0;
    end
    if (type(db.alert.offset) == "nil") then
        db.alert.offset = 0;
    end
    if (type(db.alert.scale) == "nil") then
        db.alert.scale = 1;
    end
    if (type(db.alert.timer) == "nil") then
        db.alert.timer = 1;
    end
    if (type(db.alert.sound) == "nil") then
        -- Enable sound by default in Cataclysm, where the "PowerAura" sound effect was added
        db.alert.sound = self.IsProject(SAO.CATA_AND_ONWARD) and 1 or 0;
    end

    if not db.glow then
        db.glow = {};
    end
    if (type(db.glow.enabled) == "nil") then
        db.glow.enabled = true;
    end

    if not db.classes then
        -- The first time, deep copy classes from defaults
        db.classes = CopyTable(SAO.defaults.classes);
    else
        -- Subsequent initializations will deep-merge from defaults
        for classFile, classData in pairs(SAO.defaults.classes) do
            if (not db.classes[classFile]) then
                db.classes[classFile] = CopyTable(classData);
            else
                applyDefaultClassData(db.classes[classFile], classData);
            end
        end
    end

    -- Apply shared class data to each known class so far
    for classFile, classData in pairs(db.classes) do
        applyDefaultClassData(classData, SAO.defaults.shared);
    end

    if not db.questions then
        db.questions = {};
    end

    -- Migration from older versions
    -- Each version string has 2 dots (e.g. 1.2.3) -> compute a number as if taling about gold/silver/copper coins, capped at 99 each
    -- For example: 1.2.3 -> 1g 2s 3c -> 1*100*100 + 2*100 + 3 -> 10203
    if db.version and db.version < 1000 then
        -- Versions before 2.7.5 used a different versioning system, so we need to convert it to the new system
        -- For example, version 1.2.3 was 123 in the old system, and should be converted to 10203
        db.version = math.floor(db.version / 100) * 10000 + math.floor((db.version % 100) / 10) * 100 + (db.version % 10);
    end
    local highestAppliedVersion = db.version or 0;
    for _, migration in ipairs(migrations) do
        local version, func = migration[1], migration[2];

        -- Convert version string to its coin value, as total copper coins
        local coins = { strsplit(".", version) };
        local copper = 0;
        for i = 1, 3 do
            local coin = tonumber(coins[i]);
            if (coin > 99) then --[[BEGIN_DEV_ONLY]]
                SAO:Warn(Module, string.format("Coin value %d exceeds maximum of 99", coin));
            end --[[END_DEV_ONLY]]
            copper = copper * 100 + coin;
        end

        -- Apply migration function, if applicable
        if not db.version or db.version < copper then
            func(db);
            SAO:Info(Module, SAO:migratedOptions(version));
        end

        -- Update highest known version
        if copper > highestAppliedVersion then
            highestAppliedVersion = copper;
        end
    end

    db.version = highestAppliedVersion;
    SpellActivationOverlayDB = db;

    -- At the very end, register the class
    -- This must be done after db init because registering may need options from db
    for _, classDef in ipairs({ SAO.CurrentClass, SAO.SharedClass }) do -- Iteration may fail if CurrentClass is nil and SharedClass is not, but this shouldn't happen
        if classDef then
            classDef.Register(SAO);
        end
    end
end

-- Utility frame dedicated to react to variable loading
local loader = CreateFrame("Frame", "SpellActivationOverlayDBLoader");
local loadingState = {
    loaded = false,
    questionsAsked = false,
    variablesApplied = false,
    optionsPanelInitialized = false,
};
SAO:RegisterEventHandler(loader, "VARIABLES_LOADED", "Static initializer: "..Module);
loader:SetScript("OnEvent", function (self, event)
    SAO:LoadDB();
    loadingState.loaded = true;

    SAO:AskQuestionsAtStart();
    loadingState.questionsAsked = true;

    SAO:ApplyAllVariables();
    loadingState.variablesApplied = true;

    SpellActivationOverlayOptionsPanel_Init(SAO.OptionsPanel);
    loadingState.optionsPanelInitialized = true;

    loader:UnregisterEvent("VARIABLES_LOADED");
end);

function SAO:GetDatabaseLoadingState()
    return loadingState;
end
