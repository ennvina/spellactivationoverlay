local AddonName, SAO = ...

SAO.ERA = 1
SAO.SOD = 2
SAO.TBC = 4
SAO.WRATH = 8
SAO.CATA = 16
SAO.ALL_PROJECTS = SAO.ERA+SAO.TBC+SAO.WRATH+SAO.CATA

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

function SAO.IsSoD()
    return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and C_Engraving and C_Engraving.IsEngravingEnabled()
end

function SAO.IsProject(projectFlags)
    return (
        bit.band(projectFlags, SAO.ERA) ~= 0 and SAO.IsEra() or
        bit.band(projectFlags, SAO.SOD) ~= 0 and SAO.IsSoD() or
        bit.band(projectFlags, SAO.TBC) ~= 0 and SAO.IsTBC() or
        bit.band(projectFlags, SAO.WRATH) ~= 0 and SAO.IsWrath() or
        bit.band(projectFlags, SAO.CATA) ~= 0 and SAO.IsCata()
    );
end
