local AddonName, SAO = ...

local avengersShield = 31935;
local divineLight = 82326;
local divineStorm = SAO.IsSoD() and 407778 or 53385;
local eternalFlame = 114163;
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

local handlerTruncateTo3HolyPower = {
    [SAO.MOP_AND_ONWARD] = {
        onAboutToApplyHash = function(hashCalculator)
            local holyPower = hashCalculator:getHolyPower();
            if type(holyPower) == 'number' and holyPower > 3 then
                -- Virtually cap holy power at 3
                hashCalculator:setHolyPower(3);
            end
        end
    },
}

local function useHolyPowerTracker()
    local holyPower = 85247; -- Not a real aura or action, but the game client has it

    local overlays = {}
    for hp=1,3 do
        local texture = "surge_of_light";
        local scale = 0.4 + 0.1*hp; -- 50%, 60%, 70%
        local pulse = hp == 3;
        tinsert(overlays, { holyPower = hp, texture = texture, position = "Left (vFlipped)", level = 4, scale = scale, pulse = pulse });
        tinsert(overlays, { holyPower = hp, texture = texture, position = "Right (180)",     level = 4, scale = scale, pulse = pulse, option = false });
    end

    SAO:CreateEffect(
        "holy_power_tracker",
        SAO.CATA_AND_ONWARD,
        holyPower,
        "generic",
        {
            useHolyPower = true,
            overlays = overlays,

            handlers = handlerTruncateTo3HolyPower,
        }
    );
end

local function useHammerOfWrath()
    SAO:CreateEffect(
        "how",
        SAO.ALL_PROJECTS - SAO.MOP_AND_ONWARD, -- Already glowing natively by the game client in Mists of Pandaria and onward
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

local function useHolySpender(name, spellID, project)
    SAO:CreateEffect(
        name,
        project or SAO.CATA_AND_ONWARD,
        spellID,
        "counter",
        {
            useHolyPower = true,
            holyPower = 3,

            handlers = handlerTruncateTo3HolyPower,
        }
    );
end

local function useDivineStorm()
    if SAO.IsProject(SAO.MOP_AND_ONWARD) then
        useHolySpender("divine_storm", divineStorm);
    else
        SAO:CreateEffect(
            "divine_storm",
            SAO.SOD + SAO.WRATH + SAO.CATA,
            divineStorm,
            "counter",
            { combatOnly = true }
        );
    end
end

local function useJudgementsOfThePure()
    local judgementOfLight, judgementOfWisdom, judgementOfJustice = 20271, 53408, 53407; -- Spells for Wrath
    local judgement = 20271; -- Unique spell for Cataclysm
    local judgementsOfThePureBuff = 53657;
    local judgementsOfThePureTalent = 53671;

    SAO:CreateEffect(
        "jotp",
        SAO.WRATH + SAO.CATA,
        judgementsOfThePureBuff,
        "aura",
        {
            talent = judgementsOfThePureTalent,
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
    if SAO.IsProject(SAO.MOP_AND_ONWARD) then
        local infusionOfLightBuff = 54149;
        local infusionOfLightTalent = 53576;

        SAO:CreateEffect(
            "infusion_of_light",
            SAO.MOP_AND_ONWARD,
            infusionOfLightBuff,
            "aura",
            {
                talent = infusionOfLightTalent,
                overlay = { texture = "daybreak", position = "Left + Right (Flipped)", option = { subText = SAO:RecentlyUpdated() } }, -- Updated 09-jul-2025
                -- buttons = { holyLight, divineLight, holyRadiance }, -- Buttons already glowing natively by the game client
            }
        );
    else
        local infusionOfLightBuff1 = 53672;
        local infusionOfLightBuff2 = 54149;
        local infusionOfLightTalent = 53569;

        SAO:CreateLinkedEffects(
            "infusion_of_light",
            SAO.WRATH_AND_ONWARD,
            { infusionOfLightBuff1, infusionOfLightBuff2 },
            "aura",
            {
                talent = infusionOfLightTalent,
                overlays = {
                    [SAO.WRATH] = { texture = "daybreak", position = "Left + Right (Flipped)" },
                    [SAO.CATA]  = { texture = "denounce", position = "Top" },
                },
                buttons = {
                    [SAO.WRATH] = { flashOfLight, holyLight },
                    [SAO.CATA]  = { flashOfLight, holyLight, divineLight, holyRadiance },
                },
            }
        );
    end
end

local function useDaybreak()
    SAO:CreateEffect(
        "daybreak",
        SAO.CATA_AND_ONWARD,
        88819, -- Daybreak (buff)
        "aura",
        {
            talent = { -- Daybreak (talent)
                [SAO.CATA] = 88820,
                [SAO.MOP_AND_ONWARD] = 88821,
            },
            action = holyShock,
            actionUsable = true,
            overlays = {
                [SAO.CATA] = { texture = "daybreak", position = "Left + Right (Flipped)" },
                [SAO.MOP_AND_ONWARD] = { texture = "eclipse_sun", position = "Top (CW)", scale = 0.8, level = 2, option = { subText = SAO:RecentlyUpdated() } }, -- Updated 09-jul-2025
            },
            buttons = {
                [SAO.CATA] = holyShock,
                -- [SAO.MOP_AND_ONWARD] = holyShock, -- Button already glowing natively by the game client
            }
        }
    );
end

local function useGrandCrusader()
    SAO:CreateEffect(
        "grand_crusader",
        SAO.CATA_AND_ONWARD,
        85416, -- Grand Crusader (buff)
        "aura",
        {
            talent = { -- Grand Crusader (talent)
                [SAO.CATA] = 75806,
                [SAO.MOP_AND_ONWARD] = 85043,
            },
            overlay = { texture = "grand_crusader", position = "Left + Right (Flipped)" },
            buttons = {
                [SAO.CATA] = avengersShield,
                -- [SAO.MOP_AND_ONWARD] = avengersShield, -- Button already glowing natively by the game client
            },
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

local function useDivinePurpose()
    SAO:CreateEffect(
        "divine_purpose",
        SAO.CATA_AND_ONWARD,
        90174, -- Divine Purpose (buff)
        "aura",
        {
            talent = {
                [SAO.CATA] = 85117, -- Divine Purpose (talent)
                [SAO.MOP_AND_ONWARD] = 86172, -- Divine Purpose (passive)
            },
            overlay = { texture = "hand_of_light", position = "Top" },
            buttons = {
                [SAO.CATA]           = { wordOfGlory, templarsVerdict, inquisition, zealotry },
                [SAO.MOP_AND_ONWARD] = { wordOfGlory, templarsVerdict, inquisition,           lightOfDawn, shieldOfTheRighteous, divineStorm, eternalFlame },
            },
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
    elseif SAO.IsProject(SAO.CATA_AND_ONWARD) then
        SAO:CreateEffect(
            "art_of_war",
            SAO.CATA_AND_ONWARD,
            59578, -- The Art of War (buff)
            "aura",
            {
                talent = {
                    [SAO.CATA] = 53486, -- The Art of War (talent)
                    [SAO.MOP_AND_ONWARD] = 87138, -- The Art of War (passive)
                },
                overlay = { texture = "art_of_war", position = "Left + Right (Flipped)" },
                buttons = {
                    [SAO.CATA] = exorcism,
                    -- [SAO.MOP_AND_ONWARD] = exorcism, -- Button already glowing natively by the game client
                },
            }
        );
    end
end

local function useSupplication()
    SAO:CreateEffect(
        "supplication",
        SAO.MOP,
        94686, -- Supplication (buff)
        "aura",
        {
            button = flashOfLight,
        }
    );
end

local function registerClass(self)
    -- Holy Power tracking
    useHolyPowerTracker();

    -- Counters
    useHammerOfWrath();
    useHolyShock();
    useExorcism();
    useDivineStorm(); -- Holy Power spender in Mists of Pandaria

    -- Holy Power spenders
    useHolySpender("word_of_glory", wordOfGlory);
    useHolySpender("light_of_dawn", lightOfDawn); -- Holy only
    useHolySpender("shield_of_the_righteous", shieldOfTheRighteous); -- Protection only
    useHolySpender("templars_verdict", templarsVerdict); -- Retribution only
    useHolySpender("inquisition", inquisition);
    useHolySpender("eternal_flame", eternalFlame, SAO.MOP_AND_ONWARD);

    -- Items
    self:RegisterAuraEyeOfGruul("eye_of_gruul_paladin", 37723); -- 37723 = Paladin buff
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

    -- Passive abilities
    useSupplication();
end

local function loadOptions(self)
    self:AddEyeOfGruulOverlayOption(37723); -- 37723 = Paladin buff
    self:AddSoulPreserverOverlayOption(60513); -- 60513 = Paladin buff
end

SAO.Class["PALADIN"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
