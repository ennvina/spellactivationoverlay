--[[
    This file is an example of how to implement variables
    While variables are very powerful, mastering them is not easy
    Hopefully, this fully commented example should help understand variables
    And of course, it should help when creating new ones

    This file is an improved version of a real variable: stance
    The notation is as follows:
    - comments starting with -- are original comments
    - comments in --[ [ ] ] are documentation for this template

    PS. This file is excluded from the release
    It exists for educational purposes only
]]

local AddonName, SAO = ...
local Module = "_template" --[[ For debugging purposes. Good practice: set the filename of the current source file ]]

-- Optimize frequent calls
--[[
The goal is to make sure the game API functions are looked up more efficiently
The typical syntax is: local FunctionName = FunctionName
Please add at least the ones that might be called frequently, for example:
- functions called in bucket.fetchAndSet
- functions called by event functions
- functions called in import.dependency.prepareBucket
]]
local GetShapeshiftForm = GetShapeshiftForm
local GetShapeshiftFormInfo = GetShapeshiftFormInfo

--[[
List of possible states stored in the hash
- hashes should only describe which 'toggle' should be bound to displays
- hashes should not store a detailed ID specific to each effect
For example with stances:
- a hash only tells "the player's stance matches" or "it does not match"
- the hash does *not* know which are the exact stance list (e.g. Battle Stance)
- the stance list is stored outside the hash, more exactly in the bucket

Good practice:
- always use a notation of HASH_MYVAR_*
- always end with a HASH_MYVAR_MASK which is a or'ed bitfield of all hashes

The minimum number of bits to use is 2, even for on/off information
- in computer science, an on/off information is usually stored as 1 bit
- but here, this is not only a on/off situation, this is on/off/undefined

All hash values should be exclusive, addon-wide
To know which other bits are used in the addon, search "_MASK =" in all files
]]
-- Does the current stance match one of the expected stances
local HASH_STANCE_NO   = 0x08000
local HASH_STANCE_YES  = 0x10000
local HASH_STANCE_MASK = 0x18000

--[[
SAO.Variable:register is the one call that does it all
Because this call is invoked when the source file is read:
- Do not use information not known at start
- Do not call functions that may return invalid values at start
This limitation only applies to members evaluated immediately
For function members, it may be possible use information known after start
(of course, functions are still bound to information available when called)
]]
SAO.Variable:register({
    order = 7, --[[ order is a unique numbers, please search for "order = " to know which ones are already used ]]
    --[[ core is the main variable name
    - it will bound "setMatchStance" and "getMatchStance" functions
    - for example, it will be possible to call bucket:setMatchStance and hash:setMatchStance
    ]]
    core = "MatchStance", --[[ This is the main variable name; it will bound "setMatchStance" and "getMatchStance" functions ]]

    --[[ Triggers are flags that tell 'for my effect, I am interested in this and that information'
    - in this example, the trigger of the 'stance' variable will know which effects want to know in which stance they are in
    - effects who do not have the 'stance' trigger will not look for the current stance to make a decision
    - unless in specific cases (detailed later on), by default an effect does not care about any trigger
    - each effect created with CreateEffect must ask explicitly that they are interested in this trigger
    ]]
    trigger = {
        flag = SAO.TRIGGER_STANCE, --[[ Unique bit. Defined in trigger.lua, feel free to add a new flag there ]]
        name = "stance", --[[ Unique name. To make unicity easier, every variable should use a name similar to their filename ]]
    },

    --[[ Hashes are bit fields that combine all information of all variables
    Each variable should manipulate (read, write) its own bit field, limited to HASH_MYVAR_MASK
    ]]
    hash = {
        mask = HASH_STANCE_MASK, --[[ Must match the HASH_MYVAR_MASK defined at the beginning of this file ]]
        key = "match_stance", --[[ String for debugging purposes ]]

        --[[ setterFunc is a function that will be bound to the hash:setMatchStance function
        Its goal is to set the hash fragment (set of bits) dedicated to this variable, based on a parameter (e.g. boolean)
        The name "setMatchStance" is build from the "MatchStance" name defined in the .core string
        The function should always modify the hash fragment for this variable, using the hash:setMaskedHash utility function
        ]]
        setterFunc = function(self, matchStance)
            if type(matchStance) ~= 'boolean' then
                SAO:Warn(Module, "Invalid MatchStance flag "..tostring(matchStance));
            else
                local maskedHash = matchStance and HASH_STANCE_YES or HASH_STANCE_NO;
                self:setMaskedHash(maskedHash, HASH_STANCE_MASK);
            end
        end,
        --[[ getterFunc is the counterpart of setterFunc
        The goal is to read the hash fragment of this variable, and return its intuitive parameter equivalent (e.g. boolean)
        It should always start by fetching the current hash fragment for this variables, using hash:getMaskedHash
        Returning nil has the special meaning that the current hash cannot tell which value it is i.e., it is undefined yet
        ]]
        getterFunc = function(self)
            local maskedHash = self:getMaskedHash(HASH_STANCE_MASK);
            if maskedHash == nil then return nil; end

            return maskedHash == HASH_STANCE_YES;
        end,
        --[[ toAnyFunc is a special function that revolves around the 'any' concept
        - it simulates what bit field would be the full hash if the fragment of the variable was replaced with 'ANY'
        - this is currently used exclusively by aurastacks and is never called outside that variable
        - pretty much any new variable should set this function to nil, unless someday we want to generalize the 'any' concept
        ]]
        toAnyFunc = nil,

        --[[ toValue is a function that converts the hash fragment of this variable in a simple string
        - its main purpose is for debugging
        - in some special circumstances, it can be used to define a non-numeric key to an option's table
        ]]
        toValue = function(hash)
            local stance = hash:getMatchStance();
            return stance and "yes" or "no";
        end,
        --[[ fromValue is the counterpart of toValue ]]
        fromValue = function(hash, value)
            if value == "yes" then
                hash:setMatchStance(true);
                return true;
            elseif value == "no" then
                hash:setMatchStance(false);
                return true;
            else
                return nil; -- Not good
            end
        end,
        --[[ getHumanReadableValue is a function called to display the flag to humans
        If it returns nil, it means the player should be able to guess by themselves
        ]]
        getHumanReadableKeyValue = function(hash)
            return nil; -- Should be obvious
        end,
        --[[ optionIndexer maps between the extracted hash fragment for this variable, and a number
        - this is used to determine which key will be used to index the fragment in an option's table
        - returning 0 means "this is the most common fragment"
        - either way, if there is no ambiguity between hashes, this index will not be used
        Ambiguity arises when there are several displays, each one with a different fragment
        - for example, Shaman's Maelstrom Weapon has a different display for 1, 2, 3, 4 and 5 stacks
        - in this case, the option indexer allows players to setup a different option for different stack counts
        Apart from aurastacks, ambiguity is very unlikely to happen, hence this function is rarely called, if ever
        ]]
        optionIndexer = function(hash)
            return hash:getMatchStance() and 0 or -1;
        end,
    },

    --[[ Buckets are the main objects associated with each effect
    Their main goal is to hold:
    - the set of triggers that are of interest for the effect
    - the list of displays, each display is bound to a specific hash
    - the list of states for each variable necessary for its triggers
    ]]
    bucket = {
        --[[ impossibleValue is the value of the state that basically says "I don't know what that it" i.e., undefined ]]
        impossibleValue = nil,
        --[[ fetchAndSet is a function that can be called out of the blue to synchronize the state by readin the game API
        Usually, the state is updated incrementally using game events
        But sometimes, the state cannot rely on incremental updates
        - At start, the player may have some initial state that won't be updated soon, in which case we need a starting point
        - Some events just tell 'something has changed' without telling what, in which case we must fetch intel ourselves
        ]]
        fetchAndSet = function(bucket)
            --[[ A typical fetchAndSet function works as follows:
            1. get a specific state from the game API, usually something the player has (buff, talent, item...)
            2. get a detailed state expected for this effect, this state is usually set during imports (described later on)
            3. compare the current state with expected state, and change the bucket's state for this variable accordingly
            To change the bucket's state for this variable, please call bucket:setMatchStance
            The name "setMatchStance" is built from the variable's .core string
            Incidentally, the bucket:getMaskedHash can be called to compare with the previously known state
            - however, this is very rarely useful, calling getMaskedHash is often the result of a logic flaw
            - there is no need to compare the previous state with future state for performance reason, this is done already
            When setMatchStance is called, it checks the previous state and does nothing if the state hasn't changed
            ]]
            local currentStanceIndex = GetShapeshiftForm();
            if currentStanceIndex == nil then
                bucket:setMatchStance(nil);
            elseif currentStanceIndex == 0 then
                bucket:setMatchStance(false);
            else
                local _, _, _, currentStanceSpellID = GetShapeshiftFormInfo(currentStanceIndex);
                if not currentStanceSpellID then
                    bucket:setMatchStance(nil);
                elseif bucket.stanceID then
                    bucket:setMatchStance(currentStanceSpellID == bucket.stanceID);
                elseif bucket.stanceIDs then
                    -- When checking a list of stances, at least one stance must match
                    for _, expectedStanceID in ipairs(bucket.stanceIDs) do
                        if currentStanceSpellID == expectedStanceID then
                            bucket:setMatchStance(true);
                            return;
                        end
                    end
                    bucket:setMatchStance(false);
                end
            end
        end,
    },

    --[[ Events are strings recognized by the game engine to register to specific changes
    This is what allows addons to not check the game's state constantly, but rather to react on demand
    ]]
    event = {
        --[[ Usually true, but can be set to false to avoid registering events that won't be used
        - for example, the holypower variable is used only for Paladin, and only since Cataclysm
        - by setting isRequired to false to non-Paladin players or pre-Cataclysm expansions, events are not registered
        ]]
        isRequired = true,
        --[[ names is the list of events to register to, each of them will have a key in the .event table ]]
        names = { "UPDATE_SHAPESHIFT_FORM" },
        --[[ Since the above .event.names list has mentioned UPDATE_SHAPESHIFT_FORM, this event must have a function
        When the game broadcasts the UPDATE_SHAPESHIFT_FORM event, this function will be called
        ]]
        UPDATE_SHAPESHIFT_FORM = function(...)
            --[[ The most basic reaction to an event is updating all buckets associated to this variable
            - CheckManuallyAllBuckets will iterate through all known buckets and keep only the ones with the STANCE trigger
            - these buckets will be refreshed manually, eventually calling fetchAndSet for each bucket
            The process described above is easy to code but inefficient
            When the event gives enough information, it may be better to target buckets directly
            - for example, the nativesao variable uses the even parameters to pinpoint what to do
            - unfortunately, the UPDATE_SHAPESHIFT_FORM has no information, so there is little we can do
            ]]
            SAO:CheckManuallyAllBuckets(SAO.TRIGGER_STANCE);
        end,
    },

    --[[ Conditions are the states expected for each display
    For example, when an effect is created with CreateEffect using the following properties:
    - useHolyPower = true
    - holyPower = 3
    It has the following implications:
    - 'useHolyPower = true' tells that we are interested in tracking Holy Power (see .import below)
    - 'holyPower = 3' tells that we want to know when the Paladin has 3 charges of Holy Power
    That last property (holyPower = 3) is the 'condition'
    Side note: a 'property' is a key=value member of a table passed to SAO:CreateEffect, more exactly in its 5th argument
    ]]
    condition = {
        --[[ For the record, effects have 2 levels of description
        - NOE = Native Optimize Effect = optimized for the SAO engine but not suitable for developers
        - HRE = Human Readable Effect = easy to work with by developers
        The typical process is as follows:
        - HREs are written by developers, when calling SAO:CreateEffect
        - these CreateEffect calls will eventually transform each HRE into a NOE
        - each NOE will eventually create a bucket and all objects around it (triggers, displays, etc.)
        ]]
        noeVar = "stance", --[[ Unique name among NOE conditions ]]
        hreVar = "matchStance", --[[ Unique name among HRE conditions. Will be used by developers who call SAO:CreateEffect ]]
        noeDefault = true, --[[ Default value when the HRE variable is not set explicitly by developer ]]
        description = "stance match flag", --[[ String for debugging purposes ]]
        --[[ checker is a function that validates if the developer passed a 'good' value for the HRE property ]]
        checker = function(value) return type(value) == 'boolean' end,
        --[[ noeToHash is a function that transforms from a HRE property (passed to CreateEffect) to a hash value
        Most of the time we want this function to return the value itself
        Setting a transform function is useful e.g. if the hash value should be nil
        - to get a nil value to the hash fragment of this variable, we couldn't use the 'matchStance = nil' property
        - indeed, if the developer passed the HRE property 'matchStance = nil' it would be seen as if the property was missing
        There are other cases where setting a non-identify function can be useful, but nil is the most frequent reason
        (side note, this is called noeToHash and not hreToHash, simply because the sequence is to build HRE > NOE > hash)
        ]]
        noeToHash = function(value) return value end,
    },

    --[[ Import is the step when HRE properties passed to SAO:CreateEffect will be parsed to tell 'we want this variable'
    To get back to the useHolyPower vs. holyPower properties
    - the 'useHolyPower' property will be imported to tell the effect that it should add Holy Power to the list of triggers
    In the example below, about stances, the developer can pass up to 3 properties:
    - useStance = true, imported to tell that the effect is interested in tracking the player's stance
    - matchStance = true, which tells "when the stance changes, I want to know when the stance matches" (see .condition)
    - stances = { DK_STANCE_BLOOD }, which tells which stance(s) should be tested to tell our stance test is a match
    The 'stances' property is part of the import process (see below)
    ]]
    import = {
        noeTrigger = "stance", --[[ Must equal to the name set in .trigger.name earlier in this source file ]]
        hreTrigger = "useStance", --[[ HRE property read from SAO:CreateEffect to tell when an effect tracks this variable ]]
        --[[ A dependency is an additional value that gives information when the condition's value is not enough
        For example with the stance variable
        - the condition only knows whether the effect should be displayed when the stance matches or not
        - the condition does *not* know which are the stances the effect wants or does not want
        - the 'stances' property gives exactly that: the specific information that tells which are the stances to look for
        ]]
        dependency = {
            name = "stances", --[[ HRE property that holds the dependency ]]
            --[[ expectedType is a Lua type name that allows to check that the developer passed a 'good' value
            Beware when expecting a table
            - this is convenient because it can provides some advanced information
            - but this prevents the multi-project selection feature e.g., { [SAO.ERA] = 123, [SAO.TBC] = 345 }
            ]]
            expectedType = "table",
            --[[ default is the default value if the dependency is not found in HRE properties
            - it can either be a direct value, which is then stored as is
            - or it can be a function, which is called with the effect as parameter to guess a default value from the effect
            ]]
            default = function(effect) return nil end, -- Make the 'stances' property mandatory
            --[[ prepareBucket is the function that initializes the bucket with the dependency value
            - Usually, the dependency's value is stored in a unique member of the bucket
            - The value may be stored either as is, or after some changes e.g. after calling the game API
            Values set in the bucket during prepareBucket are typically used in functions such as fetchAndSet
            ]]
            prepareBucket = function(bucket, value)
                if #value == 1 then
                    bucket.stanceID = value[1];
                else
                    bucket.stanceIDs = value;
                end
            end,
        },
        --[[ Classes are shortcuts to create effect. They are the 4th argument of SAO:CreateEffect ]]
        classes = {
            --[[ The .force member tells which class(es) will import the trigger, even if the HRE import property is not set
            It may have the following values:
            - nil, indicates no class will automatically set the trigger of this variable
            - a class name (string), when creating an effect for this class, the trigger is set automatically
            - a list of class names (table of strings), same as above, but look for class name in the list
            ]]
            force = nil,
            --[[ The .ignore member tells which classes will never import the trigger, even if the HRE import property is set
            .ignore is basically the opposite of .force, and .ignore has priority over .force
            ]]
            ignore = nil,
        },
    },
});
