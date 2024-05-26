local AddonName, SAO = ...

local avengersShield = 31935;
local divineLight = 82326;
local divineStorm = SAO.IsSoD() and 407778 or 53385;
local exorcism = 879;
local flashOfLight = 19750;
local holyLight = 635;
local holyRadiance = 82327;
local holyShock = 20473;
local how = 24275;
local inquisition = 84963;
local lightOfDawn = 85222;
local shieldOfTheRighteous = 53600;
local templarsVerdict = 85256;
local wordOfGlory = 85673;
local zealotry = 85696;

local function useHolyPowerTracker()
    local holyPower = 85247; -- Not a real aura or action, but the game client has it

    local overlays = {}
    for hp=1,3 do
        local texture = "arcane_missiles_"..hp;
        local pulse = hp == 3;
        tinsert(overlays, { holyPower = hp, texture = texture, position = "Left (vFlipped)", scale = 0.8, color = { 222, 222, 44 }, pulse = pulse, });
        tinsert(overlays, { holyPower = hp, texture = texture, position = "Right (180)",     scale = 0.8, color = { 222, 222, 44 }, pulse = pulse, option = false });
    end

    SAO:CreateEffect(
        "holy_power_tracker",
        SAO.CATA,
        holyPower,
        "generic",
        {
            combatOnly = true,
            useHolyPower = true,
            overlays = overlays,
        }
    );
end

local function useHammerOfWrath()
    SAO:CreateEffect(
        "how",
        SAO.ALL_PROJECTS,
        how,
        "counter"
    );
end

local function useHolyShock()
    SAO:CreateEffect(
        "holy_shock",
        SAO.ALL_PROJECTS,
        holyShock,
        "counter",
        { combatOnly = true }
    );
end

local function useExorcism()
    SAO:CreateEffect(
        "exorcism",
        SAO.ALL_PROJECTS,
        exorcism,
        "counter",
        { combatOnly = true }
    );
end

local function useDivineStorm()
    SAO:CreateEffect(
        "divine_storm",
        SAO.SOD + SAO.WRATH + SAO.CATA,
        divineStorm,
        "counter",
        { combatOnly = true }
    );
end

local function useHolySpender(name, spellID)
    SAO:CreateEffect(
        name,
        SAO.CATA,
        spellID,
        "counter",
        {
            useHolyPower = true,
            holyPower = 3,
        }
    );
end

local function useJudgementsOfThePure()
    local judgementOfLight, judgementOfWisdom, judgementOfJustice = 20271, 53408, 53407; -- Spells for Wrath
    local judgement = 20271; -- Unique spell for Cataclysù
    local judgementsOfThePure = 53671; -- Talent

    SAO:CreateEffect(
        "jotp",
        SAO.WRATH + SAO.CATA,
        judgement,
        "aura",
        {
            talent = judgementsOfThePure,
            requireTalent = true,
            combatOnly = true,
            buttons = {
                default = { stacks = -1 },
                [SAO.WRATH] = { judgementOfLight, judgementOfWisdom, judgementOfJustice },
                [SAO.CATA] = judgement,
            }
        }
    );
end

local function useInfusionOfLight()
    local infusionOfLightBuff1 = 53672;
    local infusionOfLightBuff2 = 54149;
    local infusionOfLightTalent = 53569;

    SAO:CreateLinkedEffects(
        "infusion_of_light",
        SAO.WRATH + SAO.CATA,
        { infusionOfLightBuff1, infusionOfLightBuff2 },
        "aura",
        {
            talent = infusionOfLightTalent,
            overlays = {
                [SAO.WRATH] = { texture = "daybreak", position = "Left + Right (Flipped)" },
                [SAO.CATA] = { texture = "surge_of_light", position = "Top (CW)", option = { subText = SAO:RecentlyUpdated() } }, -- Updated 2024-04-30
            },
            buttons = {
                [SAO.WRATH] = { flashOfLight, holyLight },
                [SAO.CATA] = { flashOfLight, holyLight, divineLight, holyRadiance },
            },
        }
    );
end

local function useDaybreak()
    SAO:CreateEffect(
        "daybreak",
        SAO.CATA,
        88819, -- Daybreak (buff)
        "aura",
        {
            talent = 88820, -- Daybreak (talent)
            action = holyShock,
            actionUsable = true,
            overlay = { texture = "daybreak", position ="Left + Right (Flipped)" },
            button = holyShock,
        }
    );
end

local function useGrandCrusader()
    SAO:CreateEffect(
        "grand_crusader",
        SAO.CATA,
        85416, -- Grand Crusader (buff)
        "aura",
        {
            talent = 75806, -- Grand Crusader (talent)
            overlay = { texture = "grand_crusader", position = "Left + Right (Flipped)" },
            button = avengersShield,
        }
    );
end

local function useCrusade()
    SAO:CreateEffect(
        "crusade",
        SAO.CATA,
        94686, -- Crusader (buff)
        "aura",
        {
            talent = 31866, -- Crusade (talent),
            button = holyLight
        }
    );
end

local function registerArtOfWar(name, project, buff, glowingButtons, defaultOverlay, defaultButton)
    SAO:CreateEffect(
        name,
        project,
        buff,
        "aura",
        {
            talent = 53486, -- The Art of War (talent)
            overlays = {
                default = defaultOverlay,
                [project] = { texture = "art_of_war", position = "Left + Right (Flipped)" },
            },
            buttons = {
                default = defaultButton,
                [project] = glowingButtons,
            },
        }
    );
end

local function useDivinePurpose()
    SAO:CreateEffect(
        "divine_purpose",
        SAO.CATA,
        90174, -- Divine Purpose (buff)
        "aura",
        {
            talent = 85117, -- Divine Purpose (talent)
            overlay = { texture = "hand_of_light", position = "Top" },
            buttons = { wordOfGlory, templarsVerdict, inquisition, zealotry },
        }
    );
end

local function useArtOfWar()
    if SAO.IsWrath() then
        local artOfWarBuff1 = 53489;
        local artOfWarBuff2 = 59578;

        SAO:AddOverlayLink(artOfWarBuff2, artOfWarBuff1);
        SAO:AddGlowingLink(artOfWarBuff2, artOfWarBuff1);

        -- 1/2 talent point: smaller, does not pulse, no options (because linked to higher rank)
        registerArtOfWar("art_of_war_low", SAO.WRATH, artOfWarBuff1, { flashOfLight, exorcism }, { scale = 0.6, pulse = false, option = false }, { option = false });

        -- 2/2 talent points
        registerArtOfWar("art_of_war_high", SAO.WRATH, artOfWarBuff2, { flashOfLight, exorcism });
    elseif SAO.IsCata() then
        local artOfWarBuff = 59578;

        registerArtOfWar("art_of_war", SAO.CATA, artOfWarBuff, { exorcism });
    end
end

local function registerClass(self)
    -- Holy Power tracking
    useHolyPowerTracker();

    -- Counters
    useHammerOfWrath();
    useHolyShock();
    useExorcism();
    useDivineStorm();

    -- Holy Power spenders
    useHolySpender("word_of_glory", wordOfGlory);
    useHolySpender("light_of_dawn", lightOfDawn); -- Holy only
    useHolySpender("shield_of_the_righteous", shieldOfTheRighteous); -- Protection only
    useHolySpender("templars_verdict", templarsVerdict); -- Retribution only
    useHolySpender("inquisition", inquisition);

    -- Items
    self:RegisterAuraSoulPreserver("soul_preserver_paladin", 60513); -- 60513 = Paladin buff

    -- Holy
    useJudgementsOfThePure();
    useInfusionOfLight();
    useDaybreak();

    -- Protection
    useGrandCrusader();

    -- Retribution
    useCrusade();
    useArtOfWar();
    useDivinePurpose();
end

local function loadOptions(self)
    self:AddSoulPreserverOverlayOption(60513); -- 60513 = Paladin buff
end

SAO.Class["PALADIN"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
