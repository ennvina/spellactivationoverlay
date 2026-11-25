local AddonName, SAO = ...
local Module = "custom"

-- Optimize frequent calls

-- Does the current custom variable match one of the expected values
local HASH_CUSTOM_ACTIVATED   = 0x20000000
local HASH_CUSTOM_DEACTIVATED = 0x40000000
local HASH_CUSTOM_MASK        = 0x60000000

SAO.Variable:register({
    order = 99,
    core = "Custom",

    trigger = {
        flag = SAO.TRIGGER_CUSTOM,
        name = "custom",
    },

    hash = {
        mask = HASH_CUSTOM_MASK,
        key = "custom_activated",

        setterFunc = function(self, customActivated)
            if type(customActivated) ~= 'boolean' then
                SAO:Warn(Module, "Invalid CustomActivated flag "..tostring(customActivated));
            else
                local maskedHash = customActivated and HASH_CUSTOM_ACTIVATED or HASH_CUSTOM_DEACTIVATED;
                self:setMaskedHash(maskedHash, HASH_CUSTOM_MASK);
            end
        end,
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_CUSTOM_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_CUSTOM_ACTIVATED;
        end,
        toAnyFunc = nil,

        toValue = function(hash)
            local customActivated = hash:getCustom();
            return customActivated and "yes" or "no";
        end,
        fromValue = function(hash, value)
            if value == "yes" then
                hash:setCustom(true);
                return true;
            elseif value == "no" then
                hash:setCustom(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        optionIndexer = function(hash)
            return hash:getCustom() and 0 or -1;
        end,
    },

    bucket = {
        impossibleValue = nil,
        fetchAndSet = function(bucket)
            if  not bucket
             or not bucket.custom
             or type(bucket.custom.isActivated) ~= 'function'
             or type(bucket.custom.state) ~= 'table'
             then
                bucket:setCustom(nil);
                return;
            end

            local isActivated = bucket.custom.isActivated(bucket, bucket.custom.state);
            if isActivated == nil then
                bucket:setCustom(nil);
            else
                bucket:setCustom(isActivated);
            end
        end,
    },

    event = {
        isRequired = false,
        names = {},
        unitNames = nil,
    },

    condition = {
        noeVar = "custom",
        hreVar = "customActivated",
        noeDefault = true,
        description = "custom activation flag",
        checker = function(value) return type(value) == 'boolean' end,
        noeToHash = function(value) return value end,
    },

    import = {
        noeTrigger = "custom",
        hreTrigger = "useCustom",

        dependency = {
            name = "custom",
            expectedType = "table",
            default = function(effect) return nil end, -- Make the 'custom' property mandatory
            prepareBucket = function(bucket, value)
                if type(value) == 'table' and value.isActivated and value.events then
                    local frame = CreateFrame("Frame");
                    local custom = {
                        isActivated = value.isActivated,
                        events = value.events,
                        frame = frame,
                        state = {},
                    };

                    local eventFunctions = {};
                    for eventName, eventFunc in pairs(custom.events) do
                        if type(eventFunc) ~= 'function' then --[[BEGIN_DEV_ONLY]]
                            SAO:Error(Module, "Invalid event function for event "..tostring(eventName).." in custom variable of "..bucket.description);
                        end --[[END_DEV_ONLY]]

                        if type(eventName) == 'string' then

                            -- Usual event
                            frame:RegisterEvent(eventName);
                            eventFunctions[eventName] = eventFunc;

                        elseif type(eventName) == 'table' and type(eventName[1]) == 'string' and eventName[1]:upper():match("^UNIT_") then

                            -- Unit event with unitID(s) to filter
                            local realEventName = eventName[1];
                            if type(frame.RegisterUnitEvent) == 'function' then
                                -- RegisterUnitEvent is supported, use it
                                frame:RegisterUnitEvent(realEventName, unpack(eventName, 2));
                                eventFunctions[realEventName] = eventFunc;
                            else
                                -- RegisterUnitEvent is not supported, fallback to RegisterEvent and filter manually
                                frame:RegisterEvent(realEventName);
                                eventFunctions[realEventName] = function(bucket, state, unitID, ...)
                                    for i = 2, #eventName do
                                        if unitID == eventName[i] then
                                            eventFunc(bucket, state, unitID, ...);
                                            return; -- Stop after the first match, to avoid calling the function several times for the same event
                                        end
                                    end
                                end;
                            end

                        else --[[DEV_ONLY]]
                            SAO:Error(Module, "Invalid event name "..tostring(eventName).." in custom variable of "..bucket.description); --[[DEV_ONLY]]
                        end
                    end

                    frame:SetScript("OnEvent", function(self, event, ...)
                        local eventFunc = eventFunctions[event];
                        eventFunc(bucket, custom.state, ...);
                    end);

                    bucket.custom = custom;
                else
                    SAO:Warn(Module, "Invalid custom dependency value "..tostring(value));
                end
            end,
        },

        classes = {
            force = "custom",
            ignore = nil,
        },
    },

    macro = {
        getCondition = nil,
    },
});

SAO.VariableHelpers.custom = {
    createPropForTargetableEnemy = function()
        return {
            isActivated = function(bucket, state)
                state.canAttack = UnitCanAttack("player", "target");
                if not canaccessvalue(state.canAttack) then
                    state.canAttack = true; -- In doubt, assume we can attack the target
                end

                state.isAlive = not UnitIsDead("target")
                if not canaccessvalue(state.isAlive) then
                    state.isAlive = true;
                end

                return state.canAttack and state.isAlive;
            end,
            events = {
                ["PLAYER_TARGET_CHANGED"] = function(bucket, state)
                    SAO:Trace(Module, "Target changed, updating tragetable enemy custom variable");
                    local isActivated = bucket.custom.isActivated(bucket, state);
                    bucket:setCustom(isActivated);
                end,
                [{"UNIT_HEALTH", "target"}] = function(bucket, state, unitID)
                    if canaccessvalue(UnitIsDead("target")) and UnitIsDead("target") then
                        SAO:Trace(Module, "Target died, resetting targetable enemy custom variable");
                        state.isAlive = false;
                        bucket:setCustom(false);
                    end
                end,
                [{"UNIT_FACTION", "target"}] = function(bucket, state, unitID)
                    SAO:Trace(Module, "Target faction changed, updating targetable enemy custom variable");
                    state.canAttack = UnitCanAttack("player", "target");
                    if not canaccessvalue(state.canAttack) then
                        state.canAttack = true; -- In doubt, assume we can attack the target
                    end
                    bucket:setCustom(state.canAttack and state.isAlive);
                end,
            },
        }
    end,

    createPropForExorcim = function()
        return {
            isActivated = function(bucket, state)
                state.canAttack = UnitCanAttack("player", "target");
                if not canaccessvalue(state.canAttack) then
                    state.canAttack = true; -- In doubt, assume we can attack the target
                end

                local creatureType = select(2, UnitCreatureType("target"));
                if canaccessvalue(creatureType) then
                    state.isDemonOrUndead = creatureType == 3 or creatureType == 6; -- 3 = Demon, 6 = Undead
                else
                    state.isDemonOrUndead = false; -- In doubt, assume the target is neither Demon nor Undead
                end

                state.isAlive = not UnitIsDead("target")
                if not canaccessvalue(state.isAlive) then
                    state.isAlive = true; -- In doubt, assume the target is alive
                end

                return state.canAttack and state.isDemonOrUndead and state.isAlive;
            end,
            events = {
                ["PLAYER_TARGET_CHANGED"] = function(bucket, state)
                    SAO:Trace(Module, "Target changed, updating Exorcism custom variable");
                    local isActivated = bucket.custom.isActivated(bucket, state);
                    bucket:setCustom(isActivated);
                end,
                [{"UNIT_HEALTH", "target"}] = function(bucket, state, unitID)
                    if canaccessvalue(UnitIsDead("target")) and UnitIsDead("target") then
                        SAO:Trace(Module, "Target died, resetting Exorcism custom variable");
                        state.isAlive = false;
                        bucket:setCustom(false);
                    end
                end,
                [{"UNIT_FACTION", "target"}] = function(bucket, state, unitID)
                    SAO:Trace(Module, "Target faction changed, updating Exorcism custom variable");
                    state.canAttack = UnitCanAttack("player", "target");
                    if not canaccessvalue(state.canAttack) then
                        state.canAttack = true; -- In doubt, assume we can attack the target
                    end
                    bucket:setCustom(state.canAttack and state.isDemonOrUndead and state.isAlive);
                end,
            },
        }
    end,

    createPropForPlayerParry = function(counterSpellIDs, maxDuration)
        return {
            isActivated = function(bucket, state)
                return state.overpowered == true; -- Return false if nil
            end,
            events = {
                --[[
                    Track the following events:
                    [{"UNIT_COMBAT", "player"}] to know when the player parries
                    [{"UNIT_SPELLCAST_SENT", "player"}] (or maybe "UNIT_SPELLCAST_SUCCEEDED", needs testing) to know when a parry-counter spell is cast
                    ["PLAYER_DEAD"] to reset instantly when the player dies
                ]]
                [{"UNIT_COMBAT", "player"}] = function(bucket, state, unitTarget, action)
                    if issecretvalue and (issecretvalue(unitTarget) or issecretvalue(action)) then
                        return;
                    end;
                    assertsafe(unitTarget == "player");

                    if action == "PARRY" then
                        SAO:Debug(Module, "Parry-counter triggered by parry");
                        if state.overpowerTimer then
                            state.overpowerTimer:Cancel();
                        end;

                        state.overpowered = true;
                        bucket:setCustom(true);

                        -- Effect will end after x seconds no matter what, unless refreshed by another parry
                        state.overpowerTimer = C_Timer.NewTimer(maxDuration, function()
                            state.overpowered = false;
                            bucket:setCustom(false);
                        end);
                    end
                end,
                [{"UNIT_SPELLCAST_SENT", "player"}] = function(bucket, state, unitTarget, target, castGUID, spellID)
                    if issecretvalue and (issecretvalue(unitTarget) or issecretvalue(spellID)) then
                        return;
                    end;
                    assertsafe(unitTarget == "player");

                    if counterSpellIDs[spellID] then
                        SAO:Debug(Module, "Parry-counter reset due to spell cast");
                        if state.overpowerTimer then
                            state.overpowerTimer:Cancel();
                        end;
                        state.overpowered = false;
                        bucket:setCustom(false);
                    end;
                end,
                ["PLAYER_DEAD"] = function(bucket, state)
                    SAO:Debug(Module, "Parry-counter reset due to player death");
                    if state.overpowerTimer then
                        state.overpowerTimer:Cancel();
                    end;
                    state.overpowered = false;
                    bucket:setCustom(false);
                end,
            },
        }
    end,

    createPropForTargetDodge = function(counterSpellIDs, maxDuration)
        return {
            isActivated = function(bucket, state)
                return state.dodged == true; -- Return false if nil
            end,
            events = {
                --[[
                    Track the following events:
                    [{"UNIT_COMBAT", "target"}] to know when the target dodges
                    [{"UNIT_SPELLCAST_SENT", "player"}] (or maybe "UNIT_SPELLCAST_SUCCEEDED", needs testing) to know when a dodge-counter spell is cast
                    ["PLAYER_DEAD"] to reset instantly when the player dies
                ]]
                [{"UNIT_COMBAT", "target"}] = function(bucket, state, unitTarget, action)
                    if not issecretvalue(action) and action ~= "WOUND" then
                        DevTools_Dump({ UNIT_COMBAT = { unitTarget = unitTarget, action = action }}) --[[DEV_ONLY]]
                    end
                    if issecretvalue and (issecretvalue(unitTarget) or issecretvalue(action)) then
                        return;
                    end;
                    assertsafe(unitTarget == "target");

                    if action == "DODGE" then
                        SAO:Debug(Module, "Dodge-counter triggered by dodge");
                        if state.overpowerTimer then
                            state.overpowerTimer:Cancel();
                        end;

                        state.dodged = true;
                        bucket:setCustom(true);

                        -- Effect will end after x seconds no matter what, unless refreshed by another dodge
                        state.overpowerTimer = C_Timer.NewTimer(maxDuration, function()
                            state.dodged = false;
                            bucket:setCustom(false);
                        end);
                    end
                end,
                [{"UNIT_SPELLCAST_SENT", "player"}] = function(bucket, state, unitTarget, target, castGUID, spellID)
                    if issecretvalue and (issecretvalue(unitTarget) or issecretvalue(spellID)) then
                        return;
                    end;
                    assertsafe(unitTarget == "player");

                    if counterSpellIDs[spellID] then
                        SAO:Debug(Module, "Dodge-counter reset due to spell cast");
                        if state.overpowerTimer then
                            state.overpowerTimer:Cancel();
                        end;
                        state.dodged = false;
                        bucket:setCustom(false);
                    end;
                end,
                ["PLAYER_DEAD"] = function(bucket, state)
                    SAO:Debug(Module, "Dodge-counter reset due to player death");
                    if state.overpowerTimer then
                        state.overpowerTimer:Cancel();
                    end;
                    state.dodged = false;
                    bucket:setCustom(false);
                end,
            },
        }
    end,
}
