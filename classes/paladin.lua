local AddonName, SAO = ...

local divineStorm = SAO.IsSoD() and 407778 or 53385;
local exorcism = 879;
local flashOfLight = 19750;
local holyLight = 635;
local holyShock = 20473;
local how = 24275;

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


local function useArtOfWar()
    local artOfWarTalent = 53486;
    local overlay = { texture = "art_of_war", position = "Left + Right (Flipped)" };

    if SAO.IsWrath() then
        local artOfWarBuff1 = 53489;
        local artOfWarBuff2 = 59578;

        SAO:AddOverlayLink(artOfWarBuff2, artOfWarBuff1);
        SAO:AddGlowingLink(artOfWarBuff2, artOfWarBuff1);

        SAO:CreateEffect(
            "art_of_war_low",
            SAO.WRATH,
            artOfWarBuff1, -- 1/2 talent point
            "aura",
            {
                talent = artOfWarTalent,
                overlays = { overlay, default = { scale = 0.6, pulse = false, option = false } }, -- Smaller, does not pulse
                buttons = { flashOfLight, exorcism, default = { option = false } },
            }
        );

        SAO:CreateEffect(
            "art_of_war_high",
            SAO.WRATH,
            artOfWarBuff2, -- 2/2 talent points
            "aura",
            {
                talent = artOfWarTalent,
                overlay = overlay,
                buttons = { flashOfLight, exorcism },
            }
        );
    elseif SAO.IsCata() then
        local artOfWarBuff = 59578;

        SAO:CreateEffect(
            "art_of_war",
            SAO.CATA,
            artOfWarBuff,
            "aura",
            {
                talent = artOfWarTalent,
                overlay = overlay,
                button = exorcism,
            }
        );
    end
end

local function registerClass(self)
    -- Counters
    useHammerOfWrath();
    useHolyShock();
    useExorcism();
    useDivineStorm();

    if self.IsWrath() then
        local infusionOfLightBuff1 = 53672;
        local infusionOfLightBuff2 = 54149;

        -- Add option links during registerClass(), not because loadOptions() which would be loaded only when the options panel is opened
        -- Add option links before RegisterAura() calls, so that options they are used by initial triggers, if any
        self:AddOverlayLink(infusionOfLightBuff2, infusionOfLightBuff1);
        self:AddGlowingLink(infusionOfLightBuff2, infusionOfLightBuff1);

        -- Infusion of Light, 1/2 talent points
        self:RegisterAura("infusion_of_light_low", 0, infusionOfLightBuff1, "daybreak", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(flashOfLight)), (GetSpellInfo(holyLight)) });

        -- Infusion of Light, 2/2 talent points
        self:RegisterAura("infusion_of_light_high", 0, infusionOfLightBuff2, "daybreak", "Left + Right (Flipped)", 1, 255, 255, 255, true, { (GetSpellInfo(flashOfLight)), (GetSpellInfo(holyLight)) });

        -- Healing Trance / Soul Preserver
        self:RegisterAuraSoulPreserver("soul_preserver_paladin", 60513); -- 60513 = Paladin buff
    elseif self.IsCata() then
        local infusionOfLightBuff1 = 53672;
        local infusionOfLightBuff2 = 54149;

        local divineLight = 82326;
        local holyRadiance = 82327;
        local infusionOfLightButtons = { flashOfLight, holyLight, divineLight, holyRadiance };

        -- Add option links during registerClass(), not because loadOptions() which would be loaded only when the options panel is opened
        -- Add option links before RegisterAura() calls, so that options they are used by initial triggers, if any
        self:AddOverlayLink(infusionOfLightBuff2, infusionOfLightBuff1);
        self:AddGlowingLink(infusionOfLightBuff2, infusionOfLightBuff1);

        -- Infusion of Light, 1/2 talent points
        self:RegisterAura("infusion_of_light_low", 0, infusionOfLightBuff1, "surge_of_light", "Top (CW)", 1, 255, 255, 255, true, infusionOfLightButtons);

        -- Infusion of Light, 2/2 talent points
        self:RegisterAura("infusion_of_light_high", 0, infusionOfLightBuff2, "surge_of_light", "Top (CW)", 1, 255, 255, 255, true, infusionOfLightButtons);
    end

    -- Retribution
    useArtOfWar();
end

local function loadOptions(self)
    if self.IsWrath() then
--        local infusionOfLightBuff1 = 53672;
        local infusionOfLightBuff2 = 54149;
        local infusionOfLightTalent = 53569;

        self:AddOverlayOption(infusionOfLightTalent, infusionOfLightBuff2);
        self:AddSoulPreserverOverlayOption(60513); -- 60513 = Paladin buff

        self:AddGlowingOption(infusionOfLightTalent, infusionOfLightBuff2, flashOfLight);
        self:AddGlowingOption(infusionOfLightTalent, infusionOfLightBuff2, holyLight);
    elseif self.IsCata() then
        local divineLight = 82326;
        local holyRadiance = 82327;

--        local infusionOfLightBuff1 = 53672;
        local infusionOfLightBuff2 = 54149;
        local infusionOfLightTalent = 53569;

        self:AddOverlayOption(infusionOfLightTalent, infusionOfLightBuff2, 0, self:RecentlyUpdated()); -- Updated 2024-04-30

        self:AddGlowingOption(infusionOfLightTalent, infusionOfLightBuff2, flashOfLight);
        self:AddGlowingOption(infusionOfLightTalent, infusionOfLightBuff2, holyLight);
        self:AddGlowingOption(infusionOfLightTalent, infusionOfLightBuff2, divineLight);
        self:AddGlowingOption(infusionOfLightTalent, infusionOfLightBuff2, holyRadiance);
    end
end

SAO.Class["PALADIN"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
