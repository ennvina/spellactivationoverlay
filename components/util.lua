local AddonName, SAO = ...
local ShortAddonName = strlower(AddonName):sub(0,8) == "necrosis" and "Necrosis" or "SAO"
local Module = "util"

-- This script file is not a 'component' per se, but its functions are used across components

-- Optimize frequent calls
local GetActionInfo = GetActionInfo
local GetMacroSpell = GetMacroSpell
local GetNumSpellTabs = GetNumSpellTabs
local GetNumTalents = GetNumTalents
local GetNumTalentTabs = GetNumTalentTabs
local GetSpellBookItemName = GetSpellBookItemName
local GetSpellCooldown = GetSpellCooldown
local GetSpellInfo = GetSpellInfo
local GetSpellTabInfo = GetSpellTabInfo
local GetTalentInfo = GetTalentInfo
local GetTalentTabInfo = GetTalentTabInfo
local GetTime = GetTime
local UnitAura = UnitAura
local UnitClassBase = UnitClassBase

local GetAuraDataBySpellName = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
local GetPlayerAuraBySpellID = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID

local GetNumSpecializationsForClassID = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID
local GetSpecializationInfo = C_SpecializationInfo and C_SpecializationInfo.GetSpecializationInfo
      GetTalentInfo = C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo or GetTalentInfo

local IsEquippedItem = C_Item and C_Item.IsEquippedItem

--[[
    Logging functions
]]

function SAO.Error(self, prefix, msg, ...)
    print(WrapTextInColor("**"..ShortAddonName.."** -"..prefix.."- "..msg, RED_FONT_COLOR), ...);
end

function SAO.Warn(self, prefix, msg, ...)
    print(WrapTextInColor("!"..ShortAddonName.."!  -"..prefix.."- "..msg, WARNING_FONT_COLOR), ...);
end

function SAO.Info(self, prefix, msg, ...)
    print(WrapTextInColor(ShortAddonName.." -"..prefix.."- "..msg, LIGHTBLUE_FONT_COLOR), ...);
end

function SAO:HasDebug()
    return SpellActivationOverlayDB and SpellActivationOverlayDB.debug;
end

function SAO.Debug(self, prefix, msg, ...)
    if SpellActivationOverlayDB and SpellActivationOverlayDB.debug then
        print(WrapTextInColorCode("["..ShortAddonName.."@"..GetTime().."] -"..prefix.."- "..msg, "FFFFFFAA"), ...);
    end
end

function SAO:HasTrace(prefix)
    return SpellActivationOverlayDB and SpellActivationOverlayDB.trace and SpellActivationOverlayDB.trace[prefix];
end

function SAO.Trace(self, prefix, msg, ...) -- Defined as SAO.Trace instead of --SAO:Trace to dodge line removal during packaging
    if SpellActivationOverlayDB and SpellActivationOverlayDB.trace and SpellActivationOverlayDB.trace[prefix] then
        print(WrapTextInColorCode("{"..ShortAddonName.."@"..GetTime().."} -"..prefix.."- "..msg, "FFAAFFCC"), ...);
    end
end

function SAO.LogPersistent(self, prefix, msg)
    if SpellActivationOverlayDB then
        local line = "[@"..GetTime().."] :"..prefix..": "..msg;
        if not SpellActivationOverlayDB.logs then
            SpellActivationOverlayDB.logs = { line };
        else
            tinsert(SpellActivationOverlayDB.logs, line);
        end
    end
end

local timeOfLastTrace = {}
function SAO.TraceThrottled(self, key, prefix, ...) -- Defined as SAO.TraceThrottled instead of --SAO:TraceThrottled to dodge line removal during packaging
    key = tostring(key)..tostring(prefix);
    if not timeOfLastTrace[key] or GetTime() > timeOfLastTrace[key]+1 then
        self:Trace(prefix, ...);
        timeOfLastTrace[key] = GetTime();
    end
end

function SAO:CanReport()
--    return SAO.IsProject(SAO.CATA_AND_ONWARD);
    -- Should be CATA_AND_ONWARD, but too late for Cataclysm. Maybe something to consider for Cata Classic Classic?
    return SAO.IsProject(SAO.MOP_AND_ONWARD);
end

function SAO:HasReport()
    return SpellActivationOverlayDB and SpellActivationOverlayDB.report ~= false; -- Default to true
end

function SAO:ReportUnknownEffect(prefix, spellID, texture, positions, scale, r, g, b)
    if self:CanReport() -- Does the project support reporting?
    and self:HasReport() -- Has the player enabled the report option?
    and self:AreEffectsInitialized() -- Are effects initialized? If not, we are probably still logging in, and the following conditions will yield false positives
    and spellID -- Is the spellID valid? It should always be valid in theory, but the game client sometimes messes up
    and not self:GetBucketBySpellID(spellID) -- Do we have a bucket for this spellID? If not, then the effect is unknown
    and not self:IsAka(spellID) -- Is the spellID an a.k.a. spell? If so, then the spellID is a shortcut for another bucket, which means this spellID is supported
    then
        if not self.UnknownNativeEffects then
            self.UnknownNativeEffects = {}
        end
        if not self.UnknownNativeEffects[spellID] then
            local text = "";
            text = text..", flavor="..tostring(self.GetFlavorName());
            text = text..", spell="..tostring(spellID).." ("..(GetSpellInfo(spellID) or "unknown spell")..")"
            text = text..", tex="..tostring(texture);
            text = text..", pos="..((type(positions) == 'string') and ("'"..positions.."'") or tostring(positions));
            text = text..", scale="..tostring(scale);
            text = text..", rgb=("..tostring(r).." "..tostring(g).." "..tostring(b)..")";
            self:Info(prefix, SAO:unsupportedShowEvent(text));

            self.UnknownNativeEffects[spellID] = true;
        end
    end
end

--[[
    Global Cooldown
]]

-- Get the Global Cooldown duration
function SAO.GetGCD(self)
    if self:IsEra() or self:IsTBC() then
        -- Most spells and abilities incur a 1.5-second Global Cooldown
        -- Some spells and abilities incur a 1-second cooldown, such as Shaman totems or most Rogue abilities
        -- But these are very hard to detect, requiring to catch the last spell/ability which triggered the GCD
        -- Also, it's not so bad to return a 'slightly too high' duration (slightly too low would be problematic)
        -- All in all, 1.5 shall be a good generic value for everyone
        return 1.5;
    else
        local _, gcdDuration, _, _ = GetSpellCooldown(61304); -- 61304 is GCD SpellID, introduced in Wrath
        -- gcdDuration will return the GCD duration if on GCD or 0 if not on GCD
        -- Returning 0 should not be an issue; who needs to compare ability CD with GCD when the player is not on GCD?
        return gcdDuration;
    end
end

--[[
    Formatting utility functions
]]

-- Usage: SAO:gradientText("YOLO", { {r=1, g=0, b=0}, {r=0, g=0, b=1} })
-- There must be at least two characters in the text and at least two colors in the colors table
function SAO:gradientText(text, colors)
    -- Helper to iterate UTF-8 codepoints
    local function utf8_iter(str)
        local pos = 1;
        local len = #str;
        return function()
            if pos > len then return nil; end
            local c = str:byte(pos);
            local bytes;
            if c < 0x80 then
                bytes = 1;
            elseif c < 0xE0 then
                bytes = 2;
            elseif c < 0xF0 then
                bytes = 3;
            else
                bytes = 4;
            end
            local char = str:sub(pos, pos + bytes - 1);
            pos = pos + bytes;
            return char;
        end
    end

    -- Collect codepoints from UTF-8 string
    local chars = {};
    for ch in utf8_iter(text) do
        table.insert(chars, ch);
    end
    local len = #chars;

    local result = "";
    for i = 1, len do
        local t = (i-1)/(len-1);
        local idx, localT;
        if t <= 0 then
            idx = 1;
            localT = 0;
        elseif t >= 1 then
            idx = #colors - 1;
            localT = 1;
        else
            -- May be subject to floating point errors, we might need to fix it if we see glitched
            idx = math.floor(t * (#colors - 1)) + 1;
            localT = (t * (#colors - 1)) % 1;
        end
        local c1 = colors[idx];
        local c2 = colors[idx+1];
        local r = c1.r + (c2.r-c1.r)*localT;
        local g = c1.g + (c2.g-c1.g)*localT;
        local b = c1.b + (c2.b-c1.b)*localT;
        local hex = string.format("%02x%02x%02x", r*255, g*255, b*255);
        result = result .. "|cff" .. hex .. chars[i] .. "|r";
    end
    return result;
end

--[[
    Addon mode
]]

function SAO:IsResponsiveMode()
    return SpellActivationOverlayDB and SpellActivationOverlayDB.responsiveMode == true;
end

--[[
    Time utility functions
]]

-- Utility function to assume times are identical or almost identical
function SAO.IsTimeAlmostEqual(self, t1, t2, delta)
	return t1-delta < t2 and t2 < t1+delta;
end

--[[
    Aura utility functions
]]

-- Factorize API calls to get player buff or debuff or whatever
local function PlayerAura(index, filter)
    return UnitAura("player", index, filter);
end

-- Aura parsing function that includes both buffs and debuffs
-- If the condition is true on more than one aura, refer to this priority list:
-- - buffs are always favored before debuffs
-- - early indexes are favored
local function FindPlayerAuraBy(condition)
    for _, filter in ipairs({"HELPFUL", "HARMFUL"}) do
        local i = 1
        local name, _, _, _, _, _, _, _, _, spellId = PlayerAura(i, filter);
        while name do
            if condition(spellId, name) then
                return i, filter;
            end
            i = i+1
            name, _, _, _, _, _, _, _, _, spellId = PlayerAura(i, filter);
        end
    end
end

-- Utility aura function, one of the many that Blizzard could've done better years ago...
local function FindPlayerAuraByID(self, id)
    local index, filter = FindPlayerAuraBy(function(_id, _name) return _id == id end);
    if index then
        return PlayerAura(index, filter);
    end
end

-- Utility aura function, similar to AuraUtil.FindAuraByName
local function FindPlayerAuraByName(self, name)
    local index, filter = FindPlayerAuraBy(function(_id, _name) return _name == name end);
    if index then
        return PlayerAura(index, filter);
    end
end

function SAO:HasPlayerAuraBySpellID(id)
    if GetPlayerAuraBySpellID then
        return GetPlayerAuraBySpellID(id) ~= nil;
    else
        return FindPlayerAuraByID(id) ~= nil;
    end
end

function SAO:GetPlayerAuraStacksBySpellID(id)
    if GetPlayerAuraBySpellID then
        local aura = GetPlayerAuraBySpellID(id);
        if aura then
            return aura.applications;
        end
    else
        local exists, _, count = FindPlayerAuraByID(id);
        if exists then
            return count;
        end
    end
    return nil;
end

function SAO:GetPlayerAuraDurationExpirationTimBySpellIdOrName(spellIdOrName)
    if type(spellIdOrName) == 'string' then
        if GetAuraDataBySpellName then
            local aura = GetAuraDataBySpellName("player", spellIdOrName, "HELPFUL");
            if not aura then
                aura = GetAuraDataBySpellName("player", spellIdOrName, "HARMFUL");
            end
            if aura then
                return aura.duration, aura.expirationTime;
            end
        else
            local exists, _, _, _, duration, expirationTime = FindPlayerAuraByName(spellIdOrName);
            if exists then
                return duration, expirationTime;
            end
        end
    elseif type(spellIdOrName) == 'number' and not self:IsFakeSpell(spellIdOrName) then -- Don't look for fake spells
        if GetPlayerAuraBySpellID then
            local aura = GetPlayerAuraBySpellID(spellIdOrName);
            if aura then
                return aura.duration, aura.expirationTime;
            end
        else
            local exists, _, _, _, duration, expirationTime = FindPlayerAuraByID(spellIdOrName);
            if exists then
                return duration, expirationTime;
            end
        end
    end
    return nil, nil;
end

--[[
    Spell utility functions
]]

--[[
    Utility function to know how many talent points the player has spent on a specific talent

    If the talent is found, returns:
    - the number of points spent for this talent
    - the total number of points possible for this talent
    - the tabulation in which the talent was found (for MoP+, the row/tier where it was found)
    - the index in which the talent was found (for MoP+, the column where it was found)
    Tabulation and index can be re-used in GetTalentInfo to avoid re-parsing all talents
    For MoP+, the tier and column can be re-used in C_SpecializationInfo.GetTalentInfo({ tier=tier, column=column })

    Returns nil if no talent is found with this name e.g., in the wrong expansion
]]
function SAO:GetTalentByName(talentName)
    if self.IsProject(SAO.MOP_AND_ONWARD) then
        for tier = 1, MAX_NUM_TALENT_TIERS do
            for column = 1, NUM_TALENT_COLUMNS do
                local talentInfo = GetTalentInfo({ tier=tier, column=column });
                if talentInfo and talentInfo.name == talentName then
                    local rank = talentInfo.selected and 1 or 0; -- Use talentInfo.known, if .selected is unreliable
                    local maxRank = talentInfo.maxRank;
                    return rank, maxRank, tier, column;
                end
            end
        end
    elseif C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
        -- Revamped pre-MoP talent API (introduced in Classic Era patch 1.15.8)
        assert(GetTalentInfo == C_SpecializationInfo.GetTalentInfo);
        for tab = 1, GetNumTalentTabs() do
            local nbTabs = GetNumTalents(tab)
            for index = 1, nbTabs do
                local talentInfo = GetTalentInfo({ specializationIndex = tab, talentIndex = index });
                if talentInfo and talentInfo.name == talentName then
                    local rank = talentInfo.selected and 1 or 0; -- Use talentInfo.known, if .selected is unreliable
                    local maxRank = talentInfo.maxRank;
                    return rank, maxRank, tab, index;
                end
            end
        end
    else
        -- Legacy code (Classic Era up to 1.15.7, and pre-Anniversary TBC/Wrath/Cataclysm)
        for tab = 1, GetNumTalentTabs() do
            for index = 1, GetNumTalents(tab) do
                local name, iconTexture, tier, column, rank, maxRank, isExceptional, available = GetTalentInfo(tab, index);
                if name == talentName then
                    return rank, maxRank, tab, index;
                end
            end
        end
    end
end

--[[
    Get the number of talent points spent at a specific talent coordinate
    - for Era-Cataclysm, i is the tab and j is the index
    - for MoP+, i is the tier and j is the column

    Return a number, or nil if the talent is not found
]]
function SAO:GetNbTalentPoints(i, j)
    if self.IsProject(SAO.MOP_AND_ONWARD) then
        local talentInfo = GetTalentInfo({ tier=i, column=j });
        return talentInfo and talentInfo.selected and 1 or 0;
    elseif C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo then
        -- Revamped pre-MoP talent API
        assert(GetTalentInfo == C_SpecializationInfo.GetTalentInfo);
        local talentInfo = GetTalentInfo({ specializationIndex = i, talentIndex = j });
        return talentInfo and talentInfo.rank and 1 or 0;
    else
        -- Legacy code
        return (select(5, GetTalentInfo(i, j)));
    end
end

--[[
    Get the number of points the player has spent on a specific talent tab
    - for Era-Cataclysm, this counts points spent in e.g. Arcane tree, Fire tree, etc.
    - for MoP+, this counting does not make sense anymore, as talents are no longer grouped in trees
]]
function SAO:GetTotalPointsInTree(specIndex)
    if self.IsProject(SAO.MOP_AND_ONWARD) then
        -- No more talent trees in MoP+
        self:Error(Module, "Getting total points in tree for specIndex "..tostring(specIndex).." but no talent trees exist in MoP+");
        return nil;
    elseif GetSpecializationInfo then
        -- Revamped pre-MoP talent API
        return (select(7, GetSpecializationInfo(specIndex)));
    else
        -- Legacy code
        local selector = SAO.IsCata() and 5 or 3;
        return (select(selector, GetTalentTabInfo(specIndex)));
    end
end

-- Get the list of specializations based on a negative talent bit-field
function SAO:GetSpecsFromTalent(talentID)
    if type(talentID) ~= 'number' or talentID >= 0 then
        SAO:Error(Module, "Getting specializations for a non-negative talentID "..tostring(talentID));
        return nil;
    end

    local specs = {};
    for spec = 1, SAO:GetNbSpecs() do
        local hasSpec = bit.band(-talentID, bit.lshift(1, spec-1)) ~= 0;
        if hasSpec then
            tinsert(specs, spec);
        end
    end
    return specs;
end

-- Get text and icon for either a talent as spellID, or as spec bit-field
function SAO:GetTalentText(talentID)
    if type(talentID) == 'number' and talentID < 0 then
        if not self:IsMoP() then
            self:Error(Module, "Getting talent text for a negative talentID "..talentID.." but prior to the Mists of Pandaria specialization rework");
            return nil;
        end
        local specs = self:GetSpecsFromTalent(talentID);
        if not specs or #specs == 0 then
            return nil;
        elseif #specs == 1 then
            local _, name, _, icon = GetSpecializationInfo(specs[1]);
            local text = "|T"..icon..":0|t "..name;
            return SPECIALIZATION..": "..text;
        else
            local text = "";
            for _, spec in ipairs(specs) do
                local _, name, _, icon = GetSpecializationInfo(spec);
                if text ~= "" then text = text.." / " end
                text = text.."|T"..icon..":0|t "..name;
            end
            return SPECIALIZATION..": "..text;
        end
    else
        local spellName, _, spellIcon = GetSpellInfo(talentID);
        if not spellName then
            self:Error(Module, "Unknown spell for talentID "..tostring(talentID));
            return nil;
        end
        return "|T"..spellIcon..":0|t "..spellName;
    end
end

-- Get the number of specializations for the current class
function SAO:GetNbSpecs()
    return GetNumSpecializationsForClassID(select(2, UnitClassBase("player")));
end

-- Get the name of a specialization by its index or tab
function SAO:GetSpecName(specIndex)
    if SAO.IsProject(SAO.MOP_AND_ONWARD) == false then
        return (select(2, GetSpecializationInfo(specIndex)));
    elseif GetSpecializationInfo then
        -- Revamped pre-MoP talent API
        return (select(2, GetSpecializationInfo(specIndex)));
    else
        -- Legacy code
        local selector = SAO.IsCata() and 2 or 1;
        return (select(selector, GetTalentTabInfo(specIndex)));
    end
end

-- Get a function that retrieves the name of the specialization
-- It returns a function that must be invoked explicitly, e.g. SAO:GetSpecNameFunction(1)()
-- The reason for that is that specializations are not queriable at start
-- Returns nil for flavors that do not support Specializations
function SAO:GetSpecNameFunction(specIndex)
    if not GetSpecializationInfo then
        return nil;
    end
    return function()
        return (select(2, GetSpecializationInfo(specIndex)));
    end;
end

-- Utility function to get the spell ID associated to an action
function SAO.GetSpellIDByActionSlot(self, actionSlot)
    local actionType, id, subType = GetActionInfo(actionSlot);
    if (actionType == "spell") then
        return id;
    elseif (actionType == "macro") then
        return GetMacroSpell(id);
    end
end

-- Utility function to return the list spellIDs for spells in the spellbook matching the same of a given spell
-- Spells are searched into the *current* spellbook, not through all available spells ever
-- This means the returned list will be obsolete if e.g. new spells are learned afterwards or if the player re-specs
-- @param spell Either the spell name (as string) or the spell ID (as number)
function SAO.GetHomonymSpellIDs(self, spell)
    local spellName;
    if (type(spell) == "string") then
        spellName = spell;
    elseif (type(spell) == "number") then
        spellName = GetSpellInfo(spell);
    end
    if (not spellName) then
        return {};
    end

    local homonyms = {};

    for tab = 1, GetNumSpellTabs() do
        local offset, numSlots = select(3, GetSpellTabInfo(tab));
        for index = offset+1, offset+numSlots do
            local name, _, id = GetSpellBookItemName(index, BOOKTYPE_SPELL);
            if (name == spellName) then
                table.insert(homonyms, id);
            end
        end
    end

    return homonyms;
end

--[[
    Item utility functions
]]

-- Returns the number of items the player has currently equipped
function SAO:GetNbItemsEquipped(itemList)
    local nbItems = 0;

    for _, item in ipairs(itemList) do
        if IsEquippedItem(item) then
            nbItems = nbItems + 1;
        end
    end

    return nbItems;
end

--[[
    Hash utility functions
]]

-- Computes a hash string based on a hash numerical value
function SAO:HashNameFromHashNumber(hash)
    return self.Hash:new(hash):toString();
end

-- Computes a hash string based only from a number of stacks
-- Used for legacy code
function SAO:HashNameFromStacks(stacks)
    local hash = self.Hash:new();
    hash:setAuraStacks(stacks);
    return hash:toString();
end

--[[
    Event Management
]]

local eventHandlers = {};

local function getHandlerName(handler)
    return handler.GetName and tostring(handler:GetName()) or tostring(handler);
end

local function getFromDescription(from)
    if type(from) == 'string' then
        return " from "..from;
    else
        return "";
    end
end

function SAO:RegisterEventHandler(handler, event, from)
    if false or -- Uncomment one of the following events to see how performance is affected
--    event == "COMBAT_LOG_EVENT_UNFILTERED" or
--    event == "SPELL_UPDATE_USABLE" or
    false then
        self:Warn(Module, "Refusing to register handler for " ..tostring(event).. " for "..getHandlerName(handler)..getFromDescription(from));
        return;
    end
    if not eventHandlers then
        eventHandlers = {};
    end
    if not eventHandlers[event] then
        eventHandlers[event] = {};
    end
    table.insert(eventHandlers[event], handler);
    handler:RegisterEvent(event);
    SAO:Debug(Module, "Handling event "..tostring(event).." for "..getHandlerName(handler)..getFromDescription(from));
end

function SAO:UnregisterEventHandler(handler, event, from)
    local found = false;
    for i, h in ipairs(eventHandlers[event] or {}) do
        if h == handler then
            table.remove(eventHandlers[event], i);
            handler:UnregisterEvent(event);
            SAO:Debug(Module, "Un-handling event "..tostring(event).." for "..getHandlerName(handler)..getFromDescription(from));
            found = true;
            break;
        end
    end
    if not found then
        SAO:Warn(Module, "Could not unregister event "..tostring(event).." for "..getHandlerName(handler)..getFromDescription(from));
    end
end

--[[
    GlowInterface generalizes how to invoke custom glowing buttons

    Inheritance is done by the bind function, then init must be called e.g.
        MyHandler = { var = 42 }
        GlowInterface:bind(MyHandler);
        MyHandler:init(spellID, spellName);

    Once this is done, the glow() and unglow() methods can be called
        MyHandler:glow();
        MyHandler:unglow();
]]
SAO.GlowInterface = {
    bind = function(self, obj)
        self.__index = nil;
        setmetatable(obj, self);
        self.__index = self;
    end,

    initVars = function(self, id, name, separateAuraID, maxDuration, variantValues, optionTestFunc)
        -- IDs
        self.spellID = id;
        self.spellName = name;
        local shiftID = separateAuraID and 1000000 or 0; -- 1M ought to be enough for anybody
        if type(separateAuraID) == 'number' then
            shiftID = shiftID * separateAuraID;
        end
        self.auraID = id + shiftID;
        self.optionID = id;

        -- Glowing state
        self.glowing = false;

        -- Timers
        self.vanishTime = nil;
        self.maxDuration = maxDuration;

        -- Variants
        self.variants = variantValues and SAO:CreateStringVariants("glow", self.optionID, self.spellID, variantValues) or nil;
        self.optionTestFunc = self.variants and optionTestFunc or nil;
    end,

    -- Make the button glow if the glowing button is enabled in options
    -- When the button glows, start or restart the timer, unless either condtion is true
    -- - the glowing button was not initialized with a duration
    -- - the skipTimer argument is true
    glow = function(self, skipTimer)
        if type(self.optionTestFunc) ~= 'function' or self.optionTestFunc(self.variants.getOption()) then
            -- Let it glow
            SAO:AddGlow(self.auraID, { self.spellName });
            self.glowing = true;

            -- Start timer if needed
            if self.maxDuration and not skipTimer then
                local tolerance = 0.2;
                self.vanishTime = GetTime() + self.maxDuration - tolerance;
                C_Timer.After(self.maxDuration, function()
                    self:timeout();
                end)
            end
        end
    end,

    -- Make the button unglow
    -- The button unglows even if it was disabled in options; better unglow too much than not enough
    -- The vanish timer, if any, is reset unless skipTimer is true
    unglow = function(self, skipTimer)
        SAO:RemoveGlow(self.auraID);
        self.glowing = false;
        if not skipTimer then
            self.vanishTime = nil;
        end
    end,

    timeout = function(self)
        if self.vanishTime and GetTime() > self.vanishTime then
            self:unglow();
            if type(self.onTimeout) == 'function' then
                self:onTimeout()
            end
        end
    end,
}

-- Create a quick UI element that can be copy/pasted
-- Forked from https://github.com/Zarant/WoW_Hardcore/blob/master/Achievements/Thunderstruck.lua
-- For the record, I submitted this code here https://github.com/Zarant/WoW_Hardcore/commit/a6730a36fda24b10de6773ad8ea92b9eb3b2cebd
function SAO:DumpCopyableText(title, text)
    local f=CreateFrame("Frame") f:SetPoint("TOPLEFT",200,-200) f:SetWidth(256) f:SetHeight(256) f.t=f:CreateTexture() f.t:SetColorTexture(0,0,0.5); f.t:SetAllPoints()
    local CBT = function(b,icon) b[icon]=b:CreateTexture() b[icon]:SetTexture("Interface/Buttons/UI-Panel-MinimizeButton-"..icon) b[icon]:SetAllPoints() b[icon]:SetTexCoord(0.08,0.9,0.1,0.9) return b[icon] end
    local b=CreateFrame("Button",nil,f) b:SetPoint("TOPRIGHT",0,0) b:SetWidth(14) b:SetHeight(14) b:SetScript("OnClick", function() f:Hide() end) b:SetNormalTexture(CBT(b,"Up")) b:SetPushedTexture(CBT(b,"Down")) b:SetHighlightTexture(CBT(b,"Highlight"))
    local g=CreateFrame("EditBox", nil, f) g:SetMultiLine(true) g:SetAutoFocus(false) g:SetAllPoints() g:SetFontObject(GameTooltipTextSmall) g:SetText(title.."\n"..text)
end
