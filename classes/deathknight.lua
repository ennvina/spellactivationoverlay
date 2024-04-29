local AddonName, SAO = ...

local bloodBoil = 48721;
local deathCoil = 47541;
local frostStrike = 49143;
local howlingBlast = 49184;
local icyTouch = 45477;
local obliterate = 49020;
local runeStrike = 56815;
local runeTap = 48982;

local function useRuneStrike()
    SAO:CreateEffect(
        "rune_strike",
        SAO.WRATH + SAO.CATA,
        runeStrike, -- Rune Strike (ability)
        "counter",
        { useName = false }
    );
end

local function useRime()
    SAO:CreateEffect(
        "rime",
        SAO.WRATH + SAO.CATA,
        59052, -- Freezing Fog (buff)
        "aura",
        {
            talent = 49188, -- Rime (talent)
            overlay = { texture = "rime", location = "Top" },
            buttons = {
                [SAO.WRATH] = howlingBlast,
                [SAO.CATA] = { howlingBlast, icyTouch },
            },
        }
    );
end

local function useKillingMachine()
    SAO:CreateEffect(
        "killing_machine",
        SAO.WRATH + SAO.CATA,
        51124, -- Killing Machine (buff)
        "aura",
        {
            talent = 51123, -- Killing Machine (talent)
            overlay = { texture = "killing_machine", location = "Left + Right (Flipped)" },
            buttons = {
                [SAO.WRATH] = { icyTouch, frostStrike, howlingBlast },
                [SAO.CATA] = { frostStrike, obliterate },
            },
        }
    );
end

local function useCrimsonScourge()
    SAO:CreateEffect(
        "crimson_scourge",
        SAO.CATA,
        81141, -- Crimson Scourge (buff)
        "aura",
        {
            talent = 81135, -- Crimson Scourge (talent)
            overlay = { texture = "blood_boil", location = "Left + Right (Flipped)" },
            button = bloodBoil,
        }
    );
end

local function useSuddenDoom()
    SAO:CreateEffect(
        "sudden_doom",
        SAO.CATA,
        81340, -- Sudden Doom (buff)
        "aura",
        {
            talent = 49018, -- Sudden Doom (talent)
            overlay = { texture = "sudden_doom", location = "Left + Right (Flipped)" },
            button = deathCoil,
        }
    );
end

local function useWotn()
    SAO:CreateEffect(
        "wotn",
        SAO.CATA,
        96171, -- Will of the Necropolis (buff)
        "aura",
        {
            talent = 52284, -- Will of the Necropolis (talent)
            overlay = { texture = "necropolis", location = "Top" },
            button = runeTap,
        }
    );
end

local function registerClass(self)
    useRuneStrike();
    useRime();
    useKillingMachine();
    useCrimsonScourge();
    useSuddenDoom();
    useWotn();
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerClass,
}
