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
local GetTime = GetTime
local UnitAura = UnitAura
local UnitClassBase = UnitClassBase

local GetAuraDataBySpellName = C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName
local GetPlayerAuraBySpellID = C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID

local GetNumSpecializationsForClassID = C_SpecializationInfo and C_SpecializationInfo.GetNumSpecializationsForClassID
      GetTalentInfo = C_SpecializationInfo and C_SpecializationInfo.GetTalentInfo or GetTalentInfo

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

function SAO.Trace(self, prefix, msg, ...)
    if SpellActivationOverlayDB and SpellActivationOverlayDB.trace and SpellActivationOverlayDB.trace[prefix] then
        print(WrapTextInColorCode("{"..ShortAddonName.."@"..GetTime().."} -"..prefix.."- "..msg, "FFAAFFCC"), ...);
    end
end

local timeOfLastTrace = {}
function SAO.TraceThrottled(self, key, prefix, ...)
    key = tostring(key)..tostring(prefix);
    if not timeOfLastTrace[key] or GetTime() > timeOfLastTrace[key]+1 then
        self:Trace(prefix, ...);
        timeOfLastTrace[key] = GetTime();
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
    Label builders
]]

-- Utility function to write a formatted 'number of stacks' text, translated with the client's locale
-- SAO:NbStacks(4) -- "4 Stacks"
-- SAO:NbStacks(7,9) -- "7-9 Stacks"
function SAO:NbStacks(minStacks, maxStacks)
    if maxStacks then
        return string.format(CALENDAR_TOOLTIP_DATE_RANGE, tostring(minStacks), string.format(STACKS, maxStacks));
    end
    return string.format(STACKS, minStacks);
end

-- Simple function telling something was updated recently
function SAO:RecentlyUpdated()
    return WrapTextInColor(KBASE_RECENTLY_UPDATED, GREEN_FONT_COLOR);
end

-- Execute text to tell enemy HP is below a certain threshold
function SAO:ExecuteBelow(threshold)
    return string.format(string.format(HEALTH_COST_PCT, "<%s%"), threshold);
end

local function tr(translations)
    local locale = GetLocale();
    return translations[locale] or translations[locale:sub(1,2)] or translations["en"];
end

-- Get the "Heating Up" localized buff name
function SAO:translateHeatingUp()
    local heatingUpTranslations = {
        ["en"] = "Heating Up",
        ["de"] = "Aufwärmen",
        ["fr"] = "Réchauffement",
        ["es"] = "Calentamiento",
        ["ru"] = "Разогрев",
        ["it"] = "Riscaldamento",
        ["pt"] = "Aquecendo",
        ["ko"] = "열기",
        ["zh"] = "热力迸发",
    };
    return tr(heatingUpTranslations);
end

-- Get the "Debuff" localized text
function SAO:translateDebuff()
    local debuffTranslations = {
        ["en"] = "Debuff",
        ["de"] = "Schwächung",
        ["fr"] = "Affaiblissement",
        ["es"] = "Perjuicio",
        ["ru"] = "Отрицательный эффект",
        ["it"] = "Penalità",
        ["pt"] = "Penalidade",
        ["ko"] = "약화",
        ["zh"] = "负面",
        ["zhTW"] = "減益",
    };
    return tr(debuffTranslations);
end

-- Get the "Responsive Mode" localized text
function SAO:responsiveMode()
    local responsiveTranslations = {
        ["en"] = "Responsive mode (decreases performance)",
        ["de"] = "Responsiver Modus (verringert die Leistung)",
        ["fr"] = "Mode réactif (diminue les performances)",
        ["es"] = "Modo de respuesta (disminuye el rendimiento)",
        ["ru"] = "Отзывчивый режим (снижает производительность)",
        ["it"] = "Modalità reattiva (riduce le prestazioni)",
        ["pt"] = "Modo responsivo (diminui o desempenho)",
        ["ko"] = "반응형 모드(성능 저하)",
        ["zh"] = "响应模式（降低性能）",
    };
    return tr(responsiveTranslations);
end

-- Get the "Unsupported class" localized text
function SAO:unsupportedClass()
    local unsupportedClassTranslations = {
        ["en"] = "Unsupported Class",
        ["de"] = "Nicht unterstützte Klasse",
        ["fr"] = "Classe non prise en charge",
        ["es"] = "Clase no compatible",
        ["ru"] = "Неподдерживаемый класс",
        ["it"] = "Classe non supportata",
        ["pt"] = "Classe sem suporte",
        ["ko"] = "지원되지 않는 클래스",
        ["zh"] = "不支持的类",
    };
    return tr(unsupportedClassTranslations);
end

-- Get the "because of {reason}" localized text
function SAO:becauseOf(reason)
    local becauseOfTranslations = {
        ["en"] = "because of %s",
        ["de"] = "wegen %s",
        ["fr"] = "à cause de %s",
        ["es"] = "por %s",
        ["ru"] = "из-за %s",
        ["it"] = "a causa di %s",
        ["pt"] = "por causa de %s",
        ["ko"] = "%s 때문에",
        ["zh"] = "因为 %s",
    };
    return string.format(tr(becauseOfTranslations), reason);
end

-- Get the "Open {x}" localized text
function SAO:openIt(x)
    local openItTranslations = {
        ["en"] = "Open %s",
        ["de"] = "Öffnen %s",
        ["fr"] = "Ouvrir %s",
        ["es"] = "Abrir %s",
        ["ru"] = "Открыть %s",
        ["it"] = "Aprire %s",
        ["pt"] = "Abrir %s",
        ["ko"] = "열기 %s",
        ["zh"] = "打开 %s",
    };
    return string.format(tr(openItTranslations), x);
end

-- Get the "Disabled when {addon} is installed" localized text
function SAO:disableWhenInstalled(addon)
    local disableWhenInstalledTranslations = {
        ["en"] = "Disable when %s is installed",
        ["de"] = "Deaktivieren, wenn %s installiert ist",
        ["fr"] = "Désactiver lorsque %s est installé",
        ["es"] = "Desactivar cuando %s está instalado",
        ["ru"] = "Отключить при установке %s",
        ["it"] = "Disattivare quando è installato %s",
        ["pt"] = "Desativar quando %s estiver instalado",
        ["ko"] = "%s가 설치되어 있으면 사용 안 함",
        ["zh"] = "安装 %s 时禁用",
    };
    return string.format(tr(disableWhenInstalledTranslations), addon);
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
    if self.IsMoP() then
        for tier = 1, MAX_NUM_TALENT_TIERS do
            for column = 1, NUM_TALENT_COLUMNS do
                local talentInfo = GetTalentInfo({ tier=tier, column=column });
                if talentInfo and talentInfo.name == talentName then
                    local rank = talentInfo.selected and 1 or 0; -- Use talentInfo.known, if .selected is unreliable
                    local maxRank = talentInfo.maxRank
                    return rank, maxRank, tier, column
                end
            end
        end
    else
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
    if self.IsMoP() then
        local talentInfo = GetTalentInfo({ tier=i, column=j });
        return talentInfo and talentInfo.selected and 1 or 0;
    else
        return (select(5, GetTalentInfo(i, j)));
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

-- Get the number of specializations for the current class
function SAO:GetNbSpecs()
    return GetNumSpecializationsForClassID(select(2, UnitClassBase("player")));
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
