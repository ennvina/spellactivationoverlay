local AddonName, SAO = ...

SAO.defaults = {
    classes = {
        ["DEATHKNIGHT"] = { -- (Wrath+)
            alert = {
                [59052] = { -- Rime
                    [0] = true,
                },
                [51124] = { -- Killing Machine
                    [0] = true,
                },
                [81141] = { -- Crimson Scourge (Cataclysm)
                    [0] = true,
                },
                [81340] = { -- Sudden Doom (Cataclysm)
                    [0] = true,
                },
                [96171] = { -- Will of the Necropolis (Cataclysm)
                    [0] = true,
                },
            },
            glow = {
                [56815] = { -- Rune Strike
                    [56815] = true, -- Rune Strike
                },
                [59052] = { -- Rime
                    [49184] = true, --  Howling Blast
                    [45477] = true, --  Icy Touch (not for Wrath)
                },
                [51124] = { -- Killing Machine
                    [49020] = true, -- Obliterate (not for Wrath)
                    [45477] = true, -- Icy Touch (not for Cata)
                    [49143] = true, -- Frost Strike
                    [49184] = true, -- Howling Blast (not for Cata)
                },
                [81141] = { -- Crimson Scourge (Cataclysm)
                    [48721] = true, -- Blood Boil
                },
                [81340] = { -- Sudden Doom (Cataclysm)
                    [47541] = true, -- Death Coil
                },
                [96171] = { -- Will of the Necropolis (Cataclysm)
                    [48982] = true, -- Rune Tap
                },
            }
        },
        ["DRUID"] = {
            alert = {
                [16870] = { -- Omen of Clarity
                    [0] = true,
                },
                [48518] = { -- Eclipse (Lunar) (Wrath+)
                    [0] = true,
                },
                [48517] = { -- Eclipse (Solar) (Wrath+)
                    [0] = true,
                },
                [408255] = { -- Eclipse (Lunar, Season of Discovery)
                    [0] = true,
                },
                [408250] = { -- Eclipse (Solar, Season of Discovery)
                    [0] = true,
                },
                [93400] = { -- Shooting Stars (Cataclysm)
                    [0] = true,
                },
                [16886] = { -- Nature's Grace (Era - Wrath)
                    [0] = false,
                },
                [46833] = { -- Wrath of Elune (Wrath)
                    [0] = false,
                },
                [64823] = { -- Elune's Wrath (Wrath)
                    [0] = false,
                },
                [69369] = { -- Predatory Strikes (Wrath+)
                    [0] = true,
                },
                [60512] = { -- Healing Trance / Soul Preserver (Wrath)
                    [0] = false,
                },
                [81093] = { -- Fury of Stormrage (Cataclysm)
                    [0] = true,
                },
                [414800]= { -- Fury of Stormrage (Season of Discovery)
                    [0] = true,
                },
            },
            glow = {
                [2912] = { -- Starfire (Season of Discovery, Wrath+)
                    [2912] = true, -- Starfire
                },
                [5176] = { -- Wrath (Season of Discovery, Wrath+)
                    [5176] = true, -- Wrath
                },
                [93400] = { -- Shooting Stars (Cataclysm)
                    [78674] = true, -- Starsurge
                },
                [46833] = { -- Wrath of Elune (Wrath)
                    [2912] = true, -- Starfire
                },
                [64823] = { -- Elune's Wrath (Wrath)
                    [2912] = true, -- Starfire
                },
                [69369] = { -- Predatory Strikes (Wrath+)
                    [8936]  = false, -- Regrowth
                    [5185]  = true,  -- Healing Touch
                    [50464] = false, -- Nourish
                    [20484] = false, -- Rebirth
                    [5176]  = false, -- Wrath
                    [339]   = false, -- Entangling Roots
                    [33786] = true,  -- Cyclone
                    [2637]  = false, -- Hibernate
                },
                [81093] = { -- Fury of Stormrage (Cataclysm)
                    [2912] = true, -- Starfire
                },
                [414800]= { -- Fury of Stormrage (Season of Discovery)
                    [5185] = true, -- Healing Touch
                },
            }
        },
        ["HUNTER"] = {
            alert = {
                [53220] = { -- Improved Steady Shot (Wrath)
                    [0] = true,
                },
                [56453] = { -- Lock and Load (Wrath+)
                    [0] = true, -- any stacks
                },
                [82926] = { -- Master Marksman (Cataclysm)
                    [0] = true,
                },
                [415414]= { -- Lock and Load (Season of Discovery)
                    [0] = true, -- any stacks
                },
                [415320]= { -- Flanking Strike (Season of Discovery)
                    [0] = true,
                },
                [425714]= { -- Cobra Strikes (Season of Discovery)
                    [0] = true, -- any stacks
                },
            },
            glow = {
                [53351] = { -- Kill Shot (Wrath+)
                    [53351] = true, -- Kill Shot
                },
                [19306] = { -- Counterattack
                    [19306] = true, -- Counterattack
                },
                [53220] = { -- Improved Steady Shot (Wrath+)
                    [19434] = true, --  Aimed Shot
                    [3044]  = true, --  Arcane Shot
                    [53209] = true, --  Chimera Shot
                },
                [56453] = { -- Lock and Load (Wrath+)
                    [3044]  = true, --  Arcane Shot (not for Cata)
                    [53301] = true, --  Explosive Shot
                },
                [82926] = { -- Master Marksman (Cataclysm)
                    [82928] = true, -- Aimed Shot!
                },
                [1495] = { -- Mongoose Bite (Era, TBC)
                    [1495]  = true, -- Mongoose Bite
                },
                [415320]= { -- Flanking Strike (Season of Discovery)
                    [415320]= true, -- Flanking Strike (Season of Discovery)
                },
                -- [415401]= { -- Sniper Training (Season of Discovery)
                --     [19434] = true, -- Aimed Shot
                -- },
            }
        },
        ["MAGE"] = {
            alert = {
                [12536] = { -- Arcane Concentration
                    [0] = false,
                },
                [79683] = { -- Arcane Missiles! (Cataclysm)
                    [0] = true,
                },
                [44401] = { -- Missile Barrage (Wrath)
                    [0] = true,
                },
                [400589] = { -- Missile Barrage (Season of Discovery)
                    [0] = true,
                },
                [400573]= { -- Arcane Blast (Season of Discovery)
                    [4] = true, -- 4 stacks
                    [0] = true, -- any stacks but 4
                },
                [57531] = { -- Arcane Potency (2/2) (Cataclysm)
                    [0] = false,
                },
                [48107] = { -- Heating Up (not an actual buff) (Season of Discovery, Wrath+)
                    [0] = true,
                },
                [48108] = { -- Hot Streak (Wrath+)
                    [0] = true,
                },
                [400625] = { -- Hot Streak (Season of Discovery)
                    [0] = true,
                },
                [64343] = { -- Impact (Wrath+)
                    [0] = true,
                },
                [54741] = { -- Firestarter (Wrath)
                    [0] = true,
                },
                [74396] = { -- Fingers of Frost (Wrath)
                    [0] = true, -- any stacks
                },
                [44544] = { -- Fingers of Frost (Cataclysm)
                    [0] = nil,  -- any stacks, set to nil to simplify DB migration
                },
                [400670]= { -- Fingers of Frost (Season of Discovery)
                    [0] = true, -- any stacks
                },
                [57761] = { -- Brain Freeze (Wrath+)
                    [0] = true,
                },
                [400730] = { -- Brain Freeze (Season of Discovery)
                    [0] = true,
                },
                [96215] = { -- Hot Streak + Heating Up (not an actual buff) (Season of Discovery, Wrath)
                    [0] = false,
                },
                [5276] = { -- Representative of spells triggering Frozen effect
                    [0] = false,
                },
            },
            glow = {
                [79683] = { -- Arcane Missiles! (Cataclysm)
                    [5143] = true, -- Arcane Missiles
                },
                [44401] = { -- Missile Barrage (Wrath)
                    [5143] = true, -- Arcane Missiles
                },
                [400589] = { -- Missile Barrage (Season of Discovery)
                    [5143] = true, -- Arcane Missiles
                },
                [400573]= { -- Arcane Blast 4/4 (Season of Discovery)
                    [5143] = true,  -- Arcane Missiles
                    [1449] = false, -- Arcane Explosion
                },
                [48108] = { -- Hot Streak (Wrath+)
                    [11366] = true, -- Pyroblast
                    [92315] = nil,  -- Pyroblast! (Cataclysm), set to nil to simplify DB migration
                },
                [400625] = { -- Hot Streak (Season of Discovery)
                    [11366] = true, -- Pyroblast
                },
                [64343] = { -- Impact (Wrath)
                    [2136] = true, -- Fire Blast
                },
                [54741] = { -- Firestarter (Wrath)
                    [2120] = true, -- Flamestrike
                },
                [57761] = { -- Brain Freeze (Wrath, Cataclysm)
                    [133]   = true, -- Fireball
                    [44614] = true, -- Frostfire Bolt (Wrath+)
                },
                [400730] = { -- Brain Freeze (Season of Discovery)
                    [133]   = true, -- Fireball
                    [412532]= true, -- Spellfrost Bolt (Season of Discovery)
                    [401502]= true, -- Frostfire Bolt (Season of Discovery)
                },
                [74396] = { -- Fingers of Frost (Wrath)
                    [30455] = true, -- Ice Lance (TBC+)
                    [44572] = true, -- Deep Freeze (Wrath+)
                },
                [44544] = { -- Fingers of Frost (Cataclysm)
                    [30455] = nil,  -- Ice Lance (TBC+), set to nil to simplify DB migration
                    [44572] = nil,  -- Deep Freeze (Wrath+), set to nil to simplify DB migration
                },
                [400670]= { -- Fingers of Frost (Season of Discovery)
                    [400640]= true, -- Ice Lance (Season of Discovery)
                    [428739]= true, -- Deep Freeze (Season of Discovery)
                },
                [5276] = { -- Representative of spells triggering Frozen effect
                    [30455] = true, -- Ice Lance (TBC+)
                    [44572] = true, -- Deep Freeze (Wrath+)
                    [400640]= true, -- Ice Lance (Season of Discovery)
                    [428739]= true, -- Deep Freeze (Season of Discovery)
                },
            },
        },
        ["PALADIN"] = {
            alert = {
                [54149] = { -- Infusion of Light (2/2) (Wrath+)
                    [0] = true,
                },
                [59578] = { -- The Art of War (2/2) (Wrath+)
                    [0] = true,
                },
                [60513] = { -- Healing Trance / Soul Preserver (Wrath)
                    [0] = false,
                },
            },
            glow = {
                [879] = { -- Exorcism
                    [879] = false, -- Exorcism
                },
                [20473] = { -- Holy Shock
                    [20473] = false, -- Holy Shock
                },
                [24275] = { -- Hammer of Wrath
                    [24275] = true, -- Hammer of Wrath
                },
                [53385] = { -- Divine Storm (Wrath+)
                    [53385] = true, -- Divine Storm (Wrath+)
                },
                [407778] = { -- Divine Storm (Season of Discovery)
                    [407778]= true, -- Divine Storm (Season of Discovery)
                },
                [54149] = { -- Infusion of Light (2/2) (Wrath+)
                    [19750] = true, -- Flash of Light
                    [635]   = true, -- Holy Light
                    [82326] = true, -- Divine Light (Cataclysm)
                    [82327] = true, -- Holy Radiance (Cataclysm)
                },
                [59578] = { -- The Art of War (2/2) (Wrath+)
                    [879]   = true, -- Exorcism
                    [19750] = true, -- Flash of Light (not for Cata)
                },
            },
        },
        ["PRIEST"] = {
            alert = {
                [33151] = {  -- Surge of Light (TBC - Wrath)
                    [0] = true,
                },
                [88688] = {  -- Surge of Light (Cataclysm)
                    [0] = true,
                },
                [63734] = { -- Serendipity (Wrath)
                    [3] = true,  -- 3 stacks
                    [0] = false, -- any stacks but 3
                },
                [63735] = { -- Serendipity (Cataclysm)
                    [1] = nil, -- set to nil to simplify DB migration, from Serendipity at 0 stacks
                    [2] = nil, -- set to nil to simplify DB migration, from Serendipity at 3 stacks
                },
                [60514] = { -- Healing Trance / Soul Preserver (Wrath)
                    [0] = false,
                },
                [413247]= { -- Serendipity (Season of Discovery)
                    [3] = true,  -- 3 stacks
                    [0] = false, -- any stacks but 3
                },
                [431666] = {  -- Surge of Light (Season of Discovery)
                    [0] = true,
                },
                [431655] = {  -- Mind Spike (Season of Discovery)
                    [3] = true,  -- 3 stacks
                    [0] = false, -- any stacks but 3
                },
            },
            glow = {
                [33151] = { -- Surge of Light (TBC - Wrath)
                    [585]  = true, -- Smite
                    [2061] = true, -- Flash Heal (not for TBC)
                },
                [88688] = { -- Surge of Light (Cataclysm)
                    [2061] = true, -- Flash Heal, also 101062: must use name
                },
                [63734] = { -- Serendipity 3/3 (Wrath)
                    [2060] = true, -- Greater Heal
                    [596]  = true, -- Prayer of Healing
                },
                [63735] = { -- Serendipity 2/2 (Cataclysm)
                    [2060] = nil, -- Greater Heal, set to nil to simplify DB migration
                    [596]  = nil, -- Prayer of Healing, set to nil to simplify DB migration
                },
                [413247]= { -- Serendipity 3/3 (Season of Discovery)
                    [2050] = true, -- Lesser Heal
                    [2054] = true, -- Heal
                    [2060] = true, -- Greater Heal
                    [596]  = true, -- Prayer of Healing
                },
                [431666] = {  -- Surge of Light (Season of Discovery)
                    [585]  = true, -- Smite
                    [2061] = true, -- Flash Heal
                },
                [431655] = {  -- Mind Spike (Season of Discovery)
                    [8092] = true, -- Mind Blast
                }
            },
        },
        ["ROGUE"] = {
            alert = {
                [14251] = { -- Riposte (Era - Wrath)
                    [0] = "cd:off",
                },
            },
            glow = {
                [14251] = { -- Riposte (Era - Wrath)
                    [14251] = "cd:off", -- Riposte
                },
            },
        },
        ["SHAMAN"] = {
            alert = {
                [16246] = {  -- Elemental Focus
                    [0] = true,
                },
                [415105] = {  -- Power Surge (Season of Discovery)
                    [0] = true,
                },
                [51505] = {  -- Lava Burst, for Lava Surge (Cataclysm)
                    [0] = true,
                },
                [53817] = { -- Maelstrom Weapon
                    [5] = true, -- 5 stacks
                    [0] = true, -- any stacks but 5
                },
                [408505] = { -- Maelstrom Weapon (Season of Discovery)
                    [5] = true, -- 5 stacks
                    [0] = true, -- any stacks but 5
                },
                [53390] = { -- Tidal Waves
                    [0] = false, -- any stacks
                },
                [60515] = { -- Healing Trance / Soul Preserver
                    [0] = false,
                },
                [425339]= { -- Molten Blast (Season of Discovery)
                    [0] = true,
                },
                [324]= { -- Lightning Shield, for Rolling Thunder (Season of Discovery) / Fulmination (Cataclysm)
                    [6] = false,
                    [7] = false,
                    [8] = false,
                    [9] = true,
                },
                [432041] = { -- Tidal Waves (Season of Discovery)
                    [0] = false, -- any stacks
                },
            },
            glow = {
                [53817] = { -- Maelstrom Weapon
                    [403]   = false, -- Lightning Bolt
                    [421]   = false, -- Chain Lightning
                    [8004]  = false, -- Lesser Healing Wave / Healing Surge (Cataclysm)
                    [331]   = false, -- Healing Wave
                    [1064]  = false, -- Chain Heal
                    [51514] = false, -- Hex
                    [77472] = false, -- Greater Healing Wave (Cataclysm)
                    [73920] = false, -- Healing Rain (Cataclysm)
                },
                [408505] = { -- Maelstrom Weapon (Season of Discovery)
                    [403]   = false, -- Lightning Bolt
                    [421]   = false, -- Chain Lightning
                    [8004]  = false, -- Lesser Healing Wave
                    [331]   = false, -- Healing Wave
                    [1064]  = false, -- Chain Heal
                    [408490] = false, -- Lava Burst (Season of Discovery)
                },
                [415105] = {  -- Power Surge (Season of Discovery)
                    [421]   = false, -- Chain Lightning
                    [1064]  = false, -- Chain Heal
                    [408490] = false, -- Lava Burst (Season of Discovery)
                },
                [51505] = {  -- Lava Burst, for Lava Surge (Cataclysm)
                    [51505] = true,
                },
                [53390] = { -- Tidal Waves
                    [8004] = false, -- Lesser Healing Wave / Healing Surge (Cataclysm)
                    [331]  = false, -- Healing Wave
                    [77472] = false, -- Greater Healing Wave (Cataclysm)
                },
                [425339]= { -- Molten Blast (Season of Discovery)
                    [425339] = true, -- Molten Blast (Season of Discovery)
                },
                [432056]= { -- Rolling Thunder (Season of Discovery)
                    [8042] = true, -- Earth Shock, for Rolling Thunder (Season of Discovery)
                },
                [324]= {  -- Lightning Shield, for Fulmination (Cataclysm)
                    [8042] = true, -- Earth Shock, for Fulmination (Cataclysm)
                },
                [432041] = { -- Tidal Waves (Season of Discovery)
                    [8004] = false, -- Lesser Healing Wave
                    [331]  = false, -- Healing Wave
                },
            },
        },
        ["WARLOCK"] = {
            alert = {
                [17941] = { -- Nightfall
                    [0] = true,
                },
                [34936] = { -- Backlash
                    [0] = true,
                },
                [71165] = { -- Molten Core
                    [0] = true, -- any stacks
                },
                [63167] = { -- Decimation
                    [0] = true,
                },
                [47283] = { -- Empowered Imp
                    [0] = true,
                },
            },
            glow = {
                [17941] = { -- Nightfall
                    [686] = true, -- Shadow Bolt
                },
                [34936] = { -- Backlash
                    [686]   = true, -- Shadow Bolt
                    [29722] = true, -- Incinerate
                },
                [71165] = { -- Molten Core
                    [29722] = true, -- Incinerate
                    [6353]  = true, -- Soul Fire
                },
                [63167] = { -- Decimation
                    [6353] = true, -- Soul Fire
                },
                [1120] = { -- Drain Soul (Wrath+)
                    [1120] = "spec:1", -- Drain Soul
                },
            },
        },
        ["WARRIOR"] = {
            alert = {
                [52437] = { -- Sudden Death (Wrath+)
                    [0] = true, -- any stacks (up to 2 stacks with tier 10)
                },
                [46916] = { -- Bloodsurge (Wrath+)
                    [0] = true, -- any stacks (up to 2 stacks with tier 10)
                },
                [413399] = { -- Bloodsurge (Season of Discovery)
                    [0] = true,
                },
                [50227] = { -- Sword and Board (Wrath+)
                    [0] = true,
                },
                [426979] = { -- Sword and Board (Season of Discovery)
                    [0] = true,
                },
                [402911]= { -- Raging Blow (Season of Discovery)
                    [0] = true,
                },
            },
            glow = {
                [7384] = { -- Overpower
                    [7384] = "stance:1", -- Overpower
                },
                [6572] = { -- Revenge
                    [6572] = "stance:2", -- Revenge
                },
                [5308] = { -- Execute
                    [5308] = "stance:1/3", -- Execute
                },
                [34428] = { -- Victory Rush (TBC+)
                    [34428] = true, -- Victory Rush
                },
                [402927]= { -- Victory Rush (Season of Discovery)
                    [402927]= true, -- Victory Rush (Season of Discovery)
                },
                [402911]= { -- Raging Blow (Season of Discovery)
                    [402911]= true, -- Raging Blow (Season of Discovery)
                },
                [52437] = { -- Sudden Death (Wrath+)
                    [5308] = true, -- Execute (not for Cata)
                    [86346]= true, -- Colossus Smash (Cataclysm)
                },
                [46916] = { -- Bloodsurge (Wrath+)
                    [1464] = true, -- Slam
                },
                [413399] = { -- Bloodsurge (Season of Discovery)
                    [1464] = true, -- Slam
                },
                [50227] = { -- Sword and Board (Wrath+)
                    [23922] = true, -- Shield Slam
                },
                [426979] = { -- Sword and Board (Season of Discovery)
                    [23922] = true, -- Shield Slam
                },
            },
        },
    }
}

if WOW_PROJECT_ID == WOW_PROJECT_CLASSIC then
    -- Options that have different default values for Classic Era
    SAO.defaults.classes["MAGE"]["alert"][12536][0] = "genericarc_05";
end
