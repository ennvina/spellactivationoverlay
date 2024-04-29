local AddonName, SAO = ...

local deathCoil = 47541;
local frostStrike = 49143;
local howlingBlast = 49184;
local icyTouch = 45477;
local obliterate = 49020;
local runeStrike = 56815;

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

local function registerClass(self)
    useRuneStrike();
    useRime();
    useKillingMachine();
    useSuddenDoom();
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerClass,
}
