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
        ["HUNTER"] = {
            glow = {
                [53351] = { -- Kill Shot
                    [53351] = true -- Kill Shot
                },
                [19306] = { -- Counterattack
                    [19306] = true -- Counterattack
                },
                [53220] = { -- Improved Steady Shot
                    [19434] = true, --  Aimed Shot
                    [3044]  = true, --  Arcane Shot
                    [53209] = true, --  Chimera Shot
                },
                [56453] = { -- Lock and Load
                    [3044]  = true, --  Arcane Shot
                    [53301] = true, --  Explosive Shot
                },
            }
        },
    }
}