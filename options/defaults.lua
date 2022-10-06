local AddonName, SAO = ...

SAO.defaults = {
    classes = {
        ["DEATHKNIGHT"] = {
            glow = {
                [56815] = { -- Rune Strike
                    [56815] = true -- Rune Strike
                },
                [59052] = { -- Rime
                    [49184] = true --  Howling Blast
                },
                [51124] = { -- Killing Machine
                    [45477] = true, -- Icy Touch
                    [49143] = true, -- Frost Strike
                    [49184] = true, -- Howling Blast
                },
            }
        },
        ["DRUID"] = {
            glow = {
                [2912] = { -- Starfire
                    [2912] = true -- Starfire
                },
                [5176] = { -- Wrath
                    [5176] = true --  Wrath
                },
            }
        },
    }
}