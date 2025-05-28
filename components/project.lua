local AddonName, SAO = ...
local Module = "project"

-- List of project flags, as bit field
-- Start high enough to be able to index project flag to a list, and avoid confusion with traditional lists
SAO.ERA = 256
SAO.SOD = 512
SAO.TBC = 1024
SAO.WRATH = 2048
SAO.CATA = 4096
SAO.MOP = 8192
SAO.ALL_PROJECTS = SAO.ERA+SAO.SOD+SAO.TBC+SAO.WRATH+SAO.CATA+SAO.MOP

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
