local AddonName, SAO = ...
local Module = "db"

-- Migrate from pre-091 to 091 or higher
local function migrateTo091(db)

    -- Warrior glowing buttons changed from boolean to string
    local warriorSpells = {
        7384, -- Overpower
        6572, -- Revenge
        5308, -- Execute
    }
    for _, spellID in ipairs(warriorSpells) do
        if db.classes["WARRIOR"]["glow"][spellID][spellID] == true and SAO.defaults.classes["WARRIOR"]["glow"][spellID][spellID] then
            db.classes["WARRIOR"]["glow"][spellID][spellID] = SAO.defaults.classes["WARRIOR"]["glow"][spellID][spellID];
        end
    end

    -- Classic Era mages probably want Clearcasting by default, because it's the only proc available
    if SAO.IsEra() then
        db.classes["MAGE"]["alert"][12536][0] = SAO.defaults.classes["MAGE"]["alert"][12536][0];
    end

    SAO:Info(Module, "Migrated options from pre-0.9.1 to 0.9.1");
end

-- Migrate from pre-091 to 091 or higher
local function migrateTo112(db)

    -- Rogue Riposte options changed from boolean to string
    local riposte = 14251;
    if db.classes["ROGUE"]["alert"][riposte][0] == true and SAO.defaults.classes["ROGUE"]["alert"][riposte][0] then
        db.classes["ROGUE"]["alert"][riposte][0] = SAO.defaults.classes["ROGUE"]["alert"][riposte][0];
    end
    if db.classes["ROGUE"]["glow"][riposte][riposte] == true and SAO.defaults.classes["ROGUE"]["glow"][riposte][riposte] then
        db.classes["ROGUE"]["glow"][riposte][riposte] = SAO.defaults.classes["ROGUE"]["glow"][riposte][riposte];
    end

    SAO:Info(Module, "Migrated options from pre-1.1.2 to 1.1.2");
end

local function transferOption(db, classFile, optionType, oldAuraID, oldNodeID, newAuraID, newNodeID)
    if type(db.classes[classFile][optionType][oldAuraID][oldNodeID]) ~= 'nil' and type(db.classes[classFile][optionType][newAuraID][newNodeID]) == 'nil' then
        db.classes[classFile][optionType][newAuraID][newNodeID] = db.classes[classFile][optionType][oldAuraID][oldNodeID];
    end
end

-- Migrate from pre-131 to 131 or higher
local function migrateTo131(db)

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

    SAO:Info(Module, "Migrated options from pre-1.3.1 to 1.3.1");
end

-- Migrate from pre-140 to 140 or higher
local function migrateTo140(db)

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

    SAO:Info(Module, "Migrated options from pre-1.4.0 to 1.4.0");
end

-- Migrate from pre-143 to 143 or higher
local function migrateTo143(db)

    -- Priest's Surge of Lightning in Cataclysm triggers a new version of Flash Heal
    local surgeOfLightWrath = 33151;
    local surgeOfLightCata = 88688;
    local flashHeal = 2061;
    local flashHealNoMana = 101062;
    transferOption(db, "PRIEST", "glow", surgeOfLightWrath, flashHeal, surgeOfLightCata, flashHealNoMana);

    SAO:Info(Module, "Migrated options from pre-1.4.3 to 1.4.3");
end

-- Migrate from pre-250 to 250 or higher
local function migrateTo250(db)

    -- Priest's Surge of Lightning in Mists of Pandaria triggers again the normal Flash Heal, but uses another buff
    local surgeOfLightCata = 88688;
    local surgeOfLightMoP = 114255;
    local flashHealNoMana = 101062;
    local flashHeal = 2061;
    transferOption(db, "PRIEST", "alert", surgeOfLightCata, 0, surgeOfLightMoP, 0);
    transferOption(db, "PRIEST", "glow", surgeOfLightCata, flashHealNoMana, surgeOfLightMoP, flashHeal);

    SAO:Info(Module, "Migrated options from pre-2.5.0 to 2.5.0");
end

-- Load database and use default values if needed
function SAO.LoadDB(self)
    local currentversion = 250;
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
        db.alert.sound = not self.IsProject(SAO.ERA + SAO.TBC + SAO.WRATH) and 1 or 0;
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
                for optionType, optionData in pairs(classData) do
                    if (not db.classes[classFile][optionType]) then
                        db.classes[classFile][optionType] = CopyTable(optionData);
                    else
                        for auraID, auraData in pairs(optionData) do
                            if (not db.classes[classFile][optionType][auraID]) then
                                db.classes[classFile][optionType][auraID] = CopyTable(auraData);
                            else
                                for hashID, hashData in pairs(auraData) do
                                    if (type(db.classes[classFile][optionType][auraID][hashID]) == 'nil') then
                                        if (type(hashData) == 'table') then
                                            db.classes[classFile][optionType][auraID][hashID] = CopyTable(hashData);
                                        else
                                            db.classes[classFile][optionType][auraID][hashID] = hashData;
                                        end
                                    elseif (type(db.classes[classFile][optionType][auraID][hashID]) == "table" and type(hashData) == 'table') then
                                        for id, value in pairs(hashData) do
                                            if (type(db.classes[classFile][optionType][auraID][hashID][id]) == 'nil') then
                                                db.classes[classFile][optionType][auraID][hashID][id] = value;
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    -- Migration from older versions
    if not db.version or db.version < 091 then
        migrateTo091(db);
    end
    if not db.version or db.version < 112 then
        migrateTo112(db);
    end
    if not db.version or db.version < 131 then
        migrateTo131(db);
    end
    if not db.version or db.version < 140 then
        migrateTo140(db);
    end
    if not db.version or db.version < 143 then
        migrateTo143(db);
    end
    if not db.version or db.version < 250 then
        migrateTo250(db);
    end

    db.version = currentversion;
    SpellActivationOverlayDB = db;

    -- At the very end, register the class
    -- This must be done after db init because registering may need options from db
    if (self.CurrentClass) then
        self.CurrentClass.Register(SAO);
    end
end

-- Utility frame dedicated to react to variable loading
local loader = CreateFrame("Frame", "SpellActivationOverlayDBLoader");
loader:RegisterEvent("VARIABLES_LOADED");
loader:SetScript("OnEvent", function (self, event)
    SAO:LoadDB();
    SAO:ApplyAllVariables();
    SpellActivationOverlayOptionsPanel_Init(SAO.OptionsPanel);
    loader:UnregisterEvent("VARIABLES_LOADED");
end);
