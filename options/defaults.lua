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
        ["MAGE"] = {
            glow = {
                [44401] = { -- Missile Barrage
                    [5143] = true, -- Arcane Missiles
                },
                [48108] = { -- Hot Streak
                    [11366] = true, -- Pyroblast
                },
                [64343] = { -- Impact
                    [2136] = true, -- Fire Blast
                },
                [54741] = { -- Firestarter
                    [2120] = true, -- Flamestrike
                },
                [57761] = { -- Brain Freeze
                    [133]   = true, -- Fireball
                    [44614] = true, -- Frostfire Bolt
                },
            },
        },
        ["PALADIN"] = {
            glow = {
                [24275] = { -- Hammer of Wrath
                    [24275] = true, -- Hammer of Wrath
                },
                [54149] = { -- Infusion of Light (2/2)
                    [19750] = true, -- Flash of Light
                    [635]   = true, -- Holy Light
                },
                [59578] = {
                    [879]   = true, -- Exorcism
                    [19750] = true, -- Flash of Light
                },
            },
        },
        ["PRIEST"] = {
            glow = {
                [33151] = { -- Surge of Light
                    [585]  = true, -- Smite
                    [2061] = true, -- Flash Heal
                },
                [63734] = { -- Serendipity 3/3
                    [2060] = true, -- Greater Heal
                    [596]  = true, -- Prayer of Healing
                },
            },
        },
        ["ROGUE"] = {
            glow = {
                [14251] = { -- Riposte
                    [14251] = true, -- Riposte
                },
            },
        },
    }
}