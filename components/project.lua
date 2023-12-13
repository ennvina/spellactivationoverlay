local AddonName, SAO = ...

function SAO.IsEra()
    return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC;
end

function SAO.IsTBC()
    return WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC;
end

function SAO.IsWrath()
    return WOW_PROJECT_ID == WOW_PROJECT_WRATH_CLASSIC;
end

function SAO.IsSoD()
    return WOW_PROJECT_ID == WOW_PROJECT_CLASSIC and C_Engraving and C_Engraving.IsEngravingEnabled()
end
