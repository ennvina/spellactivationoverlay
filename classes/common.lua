local AddonName, SAO = ...

-- List of classes
-- Each class defines its own stuff in their <classname>.lua
SAO.Class = {}

-- Special class "shared" for effects that can be acquired by classes other than the player
SAO.Class["__SHARED"] = {
    ["Register"] = function(self)
        local useLeapOfFaith = function(spellID, classFile)
            local classColor = { 255*RAID_CLASS_COLORS[classFile].r, 255*RAID_CLASS_COLORS[classFile].g, 255*RAID_CLASS_COLORS[classFile].b };
            local fromClass = self:FromClass(classFile);
            SAO:CreateEffect(
                "leap_of_faith_"..classFile:lower(),
                SAO.MOP_AND_ONWARD,
                spellID,
                "aura",
                {
                    overlay = {
                        texture = "genericarc_06", position = "Left + Right (Flipped)",
                        level = 9, -- On top of most alerts, to make it visible during its short lifetime
                        scale = 1.25, -- Slightly larger to avoid overlapping with other effects
                        color = classColor, -- Different color for each class to know which class is pulling the player
                        option = { subText = fromClass } -- Options texts "From:" help identify the effect is shared
                    },
                }
            );
        end
        useLeapOfFaith(92572, "PRIEST"); -- Leap of Faith (Priest)
        useLeapOfFaith(110724, "DRUID"); -- Leap of Faith (Druid)
    end,

    ["LoadOptions"] = function(self)
    end,
}