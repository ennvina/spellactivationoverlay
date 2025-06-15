local AddonName, SAO = ...
local Module = "project"

-- List of project flags, as bit field
-- Start high enough to be able to index project flag to a list, and avoid confusion with traditional lists
SAO.ERA    = 0x0100
SAO.SOD    = 0x0200
SAO.TBC    = 0x0400
SAO.WRATH  = 0x0800
SAO.CATA   = 0x1000
SAO.MOP    = 0x2000
SAO.WOD    = 0x4000
SAO.LEGION = 0x8000
SAO.ALL_PROJECTS = SAO.ERA + SAO.SOD + SAO.TBC + SAO.WRATH + SAO.CATA + SAO.MOP -- + SAO.WOD + SAO.LEGION
SAO.TBC_AND_ONWARD   = SAO.ALL_PROJECTS - (SAO.ERA + SAO.SOD)
SAO.WRATH_AND_ONWARD = SAO.ALL_PROJECTS - (SAO.ERA + SAO.SOD + SAO.TBC)
SAO.CATA_AND_ONWARD  = SAO.ALL_PROJECTS - (SAO.ERA + SAO.SOD + SAO.TBC + SAO.WRATH)
SAO.MOP_AND_ONWARD   = SAO.ALL_PROJECTS - (SAO.ERA + SAO.SOD + SAO.TBC + SAO.WRATH + SAO.CATA)

function SAO.IsEra()
    return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;
end

function SAO.IsTBC()
    return WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC;
end

function SAO.IsWrath()
    return WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC;
end

function SAO.IsCata()
    return WOW_PROJECT_ID == WOW_PROJECT_CATACLYSM_CLASSIC;
end

function SAO.IsMoP()
    return WOW_PROJECT_ID == WOW_PROJECT_MISTS_CLASSIC;
end

function SAO.IsSoD()
    return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and C_Engraving and C_Engraving.IsEngravingEnabled()
end

function SAO.IsProject(projectFlags)
    if type(projectFlags) ~= 'number' then
        SAO:Debug(Module, "Checking project against invalid flags "..tostring(projectFlags));
        return false;
    end
    return (
        bit.band(projectFlags, SAO.ERA) ~= 0 and SAO.IsEra() or
        bit.band(projectFlags, SAO.SOD) ~= 0 and SAO.IsSoD() or
        bit.band(projectFlags, SAO.TBC) ~= 0 and SAO.IsTBC() or
        bit.band(projectFlags, SAO.WRATH) ~= 0 and SAO.IsWrath() or
        bit.band(projectFlags, SAO.CATA) ~= 0 and SAO.IsCata() or
        bit.band(projectFlags, SAO.MOP) ~= 0 and SAO.IsMoP()
    );
end

local flavorNames = {
    [WOW_PROJECT_CLASSIC or 2] = "Era",
    [WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5] = "TBC",
    [WOW_PROJECT_WRATH_CLASSIC or 11] = "Wrath",
    [WOW_PROJECT_CATACLYSM_CLASSIC or 14] = "Cata",
    [WOW_PROJECT_MISTS_CLASSIC or 19] = "MoP",
};

function SAO.GetFlavorName()
    if SAO.IsSoD() then
        return "SoD"; -- Special case for SoD, which does not have a dedicated WOW_PROJECT_ID
    end
    return flavorNames[WOW_PROJECT_ID] or "Unknown";
end

-- buildID is an internal code, such as universal, vanilla, tbc, ...
-- This is supposed to be the same as the suffix of package names
local projectNameForBuildID = {
    universal = "*",
    vanilla   = EXPANSION_NAME0 or "Classic",
    tbc       = EXPANSION_NAME1 or "The Burning Crusade",
    wrath     = EXPANSION_NAME2 or "Wrath of the Lich King",
    cata      = EXPANSION_NAME3 or "Cataclysm",
    mop       = EXPANSION_NAME4 or "Mists of Pandaria",
    -- wod       = EXPANSION_NAME5 or "Warlords of Draenor",
    -- legion    = EXPANSION_NAME6 or "Legion",
    -- bfa       = EXPANSION_NAME7 or "Battle for Azeroth",
    -- sl        = EXPANSION_NAME8 or "Shadowlands",
    -- df        = EXPANSION_NAME9 or "Dragonflight",
};

function SAO.GetFullProjectName(buildID)
    return projectNameForBuildID[buildID] or "Unknown";
end

local expectedBuildID = {
    [WOW_PROJECT_CLASSIC or 2] = "vanilla",
    [WOW_PROJECT_BURNING_CRUSADE_CLASSIC or 5] = "tbc",
    [WOW_PROJECT_WRATH_CLASSIC or 11] = "wrath",
    [WOW_PROJECT_CATACLYSM_CLASSIC or 14] = "cata",
    [WOW_PROJECT_MISTS_CLASSIC or 19] = "mop",
};

function SAO.GetExpectedBuildID()
    return expectedBuildID[WOW_PROJECT_ID] or "";
end
