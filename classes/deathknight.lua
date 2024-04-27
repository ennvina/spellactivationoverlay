local AddonName, SAO = ...

local runeStrike = {
    name = "rune_strike",
    project = SAO.WRATH + SAO.CATA,
    spellID = 56815; -- Rune Strike (ability)

    counter = true,

    buttons = {{
        spellID = nil, -- Inherits from effect
        useName = false,
    }}
}

local rime = {
    name = "rime",
    project = SAO.WRATH + SAO.CATA,
    spellID = 59052; -- Freezing Fog (buff)
    talent = 49188; -- Rime (talent)

    overlays = {{
        texture = "rime",
        location = "Top",
    }},

    buttons = {{
        project = SAO.WRATH + SAO.CATA,
        spellID = 49184, -- Howling Blast
        useName = true,
    }, {
        project = SAO.CATA,
        spellID = 45477, -- Icy Touch
        useName = true,
    }},
}

local killingMachine = {
    name = "killing_machine",
    project = SAO.WRATH + SAO.CATA,
    spellID = 51124; -- Killing Machine (buff)
    talent = 51123; -- Killing Machine (talent)

    overlays = {{
        texture = "killing_machine",
        location = "Left + Right (Flipped)",
    }},

    buttons = {{
        project = SAO.WRATH,
        spellID = 45477, -- Icy Touch
        useName = true,
    }, {
        project = SAO.WRATH + SAO.CATA,
        spellID = 49143, -- Frost Strike
        useName = true,
    }, {
        project = SAO.WRATH,
        spellID = 49184, -- Howling Blast
        useName = true,
    }, {
        project = SAO.CATA,
        spellID = 49020, -- Obliterate
        useName = true,
    }},
}

local suddenDoom = {
    name = "sudden_doom",
    project = SAO.CATA,
    spellID = 81340; -- Sudden Doom (buff)
    talent = 49018; -- Sudden Doom (talent)

    overlays = {{
        texture = "sudden_doom",
        location = "Left + Right (Flipped)",
    }},

    buttons = {{
        spellID = 47541, -- Death Coil
    }},
}

local function registerClass(self)
    self:RegisterEffect(runeStrike);
    self:RegisterEffect(rime);
    self:RegisterEffect(killingMachine);
    self:RegisterEffect(suddenDoom);
end

local function loadOptions(self)
    self:AddEffectOptions();
end

SAO.Class["DEATHKNIGHT"] = {
    ["Register"] = registerClass,
    ["LoadOptions"] = loadOptions,
}
