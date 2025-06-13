local AddonName, SAO = ...

local tranquilizingShot = 19801;

local function useComboBreakerBlackoutKick()
    SAO:CreateEffect(
        "cb_blackout_kick",
        SAO.MOP,
        116768, -- Combo Breaker: Blackout Kick (buff)
        "aura",
        {
            overlay = { texture = "monk_tiger", position = "Left + Right (Flipped)" },
        }
    );
end

local function useComboBreakerTigerPalm()
    SAO:CreateEffect(
        "cb_tiger_palm",
        SAO.MOP,
        118864, -- Combo Breaker: Tiger Palm
        "aura",
        {
            overlay = { texture = "monk_tiger", position = "Left + Right (Flipped)" },
        }
    );
end

local function registerClass(self)
    useComboBreakerBlackoutKick();
    useComboBreakerTigerPalm();
end

SAO.Class["MONK"] = {
    ["Register"] = registerClass,
}
