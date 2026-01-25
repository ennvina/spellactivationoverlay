local AddonName, SAO = ...
local Module = "texture"

-- Credits to WeakAuras for listing these textures https://github.com/WeakAuras
local mapping =
{
    ["449486"]	= "Arcane Missiles",
    ["1027131"]	= "Arcane Missiles 1",
    ["1027132"]	= "Arcane Missiles 2",
    ["1027133"]	= "Arcane Missiles 3",
    ["450913"] 	= "Art of War",
    ["460830"] 	= "Backlash",
    ["801266"] 	= "Backlash Green",
    ["1030393"]	= "Bandits Guile",
    ["510822"] 	= "Berserk",
    ["511104"] 	= "Blood Boil",
    ["449487"] 	= "Blood Surge",
    ["449488"] 	= "Brain Freeze",
    ["603338"] 	= "Dark Tiger",
    ["461878"] 	= "Dark Transformation",
    ["459313"] 	= "Daybreak",
    ["2851787"]	= "Demonic Core", 
    ["2888300"]	= "Demonic Core Green",
    ["511469"] 	= "Denounce",
    ["1057288"]	= "Echo of the Elements",
    ["450914"] 	= "Eclipse Moon",
    ["450915"] 	= "Eclipse Sun",
    ["450916"] 	= "Focus Fire",
    ["449489"] 	= "Frozen Fingers",
    ["467696"] 	= "Fulmination",
    ["460831"] 	= "Fury of Stormrage",
    -- Yellow-ish version of Fury of Stormrage, for Holy spells
    ["30000006"]	= "Fury of Stormrage Yellow",
    ["450917"] 	= "GenericArc 01",
    ["450918"] 	= "GenericArc 02",
    ["450919"] 	= "GenericArc 03",
    ["450920"] 	= "GenericArc 04",
    ["450921"] 	= "GenericArc 05",
    ["450922"] 	= "GenericArc 06",
    ["450923"] 	= "GenericTop 01",
    ["450924"] 	= "GenericTop 02",
    ["450925"] 	= "Grand Crusader",
    ["459314"] 	= "Hand of Light",
    ["2851788"] = "High Tide",
    ["449490"] 	= "Hot Streak",
    ["449491"] 	= "Imp Empowerment",
    ["801267"] 	= "Imp Empowerment Green",
    ["457658"] 	= "Impact",
    ["458740"] 	= "Killing Machine",
    ["450926"] 	= "Lock and Load",
    ["1028136"]	= "Maelstrom Weapon 1",
    ["1028137"]	= "Maelstrom Weapon 2",
    ["1028138"]	= "Maelstrom Weapon 3",
    ["1028139"]	= "Maelstrom Weapon 4",
    ["450927"] 	= "Maelstrom Weapon", -- This acts as a "Maelstrom Weapon 5" texture
    -- Maelstrom Weapon 6-10 were made up for Season of Discovery
    ["30000001"]	= "Maelstrom Weapon 6",
    ["30000002"]	= "Maelstrom Weapon 7",
    ["30000003"]	= "Maelstrom Weapon 8",
    ["30000004"]	= "Maelstrom Weapon 9",
    ["30000005"]	= "Maelstrom Weapon 10",
    ["450928"] 	= "Master Marksman",
    ["458741"] 	= "Molten Core",
    ["801268"] 	= "Molten Core Green",
    ["1001511"]	= "Monk Blackout Kick",
    ["1028091"]	= "Monk Ox 2",
    ["1028092"]	= "Monk Ox 3",
    ["623950"] 	= "Monk Ox",
    ["623951"] 	= "Monk Serpent",
    ["1001512"]	= "Monk Tiger Palm",
    ["623952"] 	= "Monk Tiger",
    ["450929"] 	= "Nature's Grace",
    ["511105"] 	= "Necropolis",
    ["449492"] 	= "Nightfall",
    ["510823"] 	= "Feral OmenOfClarity",
    ["898423"] 	= "Predatory Swiftness",
    ["1518303"]	= "Predatory Swiftness Green",
    ["962497"] 	= "Raging Blow",
    ["450930"] 	= "Rime",
    ["469752"] 	= "Serendipity",
    ["656728"] 	= "Shadow Word Insanity",
    ["627609"] 	= "Shadow of Death",
    ["463452"] 	= "Shooting Stars",
    ["450931"] 	= "Slice and Dice",
    ["424570"] 	= "Spell Activation Overlay 0",
    ["449493"] 	= "Sudden Death",
    ["450932"] 	= "Sudden Doom",
    ["592058"] 	= "Surge of Darkness",
    ["450933"] 	= "Surge of Light",
    ["449494"] 	= "Sword and Board",
    ["1029138"]	= "Thrill of the Hunt 1",
    ["1029139"]	= "Thrill of the Hunt 2",
    ["1029140"]	= "Thrill of the Hunt 3",
    ["774420"] 	= "Tooth and Claw",
    ["627610"] 	= "Ultimatum",
    ["603339"] 	= "White Tiger",
}

SAO.TexName = {}
SAO.TextureFilenameFromFullname = {}
for retailTexture, classicTexture in pairs(mapping) do
  -- For now, all textures are copied locally in the addon's texture folder
  local filename = classicTexture:gsub(" ", "_"):gsub("'", "");
  local fullTextureName = "Interface\\Addons\\SpellActivationOverlay\\textures\\"..filename;
  local retailNumber = tonumber(retailTexture, 10);
  if (
    (SAO.IsCata() and retailNumber <= 511469) -- Cataclysm game files embed textures up to (at least) 511469
    or
    (SAO.IsMoP() and retailNumber <= 898423) -- Mists of Pandaria game files embed textures up to (at least) 898423
  ) and
    retailNumber ~= 450914 and retailNumber ~= 450915 then -- Eclipse textures in Cataclysm and Pandaria were different
    -- In this case, use texture embedded in game using its FileDataID, not from addon folder using a file path
    fullTextureName = retailTexture;
  end
  SAO.TexName[retailTexture] = fullTextureName;
  SAO.TexName[retailNumber] = fullTextureName;
  SAO.TexName[strlower(classicTexture)] = fullTextureName;
  SAO.TexName[strlower(classicTexture):gsub(" ", "_"):gsub("'", "")] = fullTextureName;
  SAO.TextureFilenameFromFullname[fullTextureName] = strlower(filename);
end

SAO.MarkedTextures = {}
function SAO.MarkTexture(self, texName)
  if not texName then return end

  local pointedTexName = self.TexName[texName];
  local fullTextureName;
  if pointedTexName then
    self.MarkedTextures[pointedTexName] = true;
    fullTextureName = pointedTexName;
  elseif self.TextureFilenameFromFullname[texName] then
    self.MarkedTextures[texName] = true;
    fullTextureName = texName;
  else
    self:Error(Module, "Unknown texture "..texName);
  end

  if fullTextureName and -- Has texture
    tostring(tonumber(fullTextureName,10)) ~= fullTextureName and -- Texture is not embedded (in theory we could test it, but not easily, cf. SAO_DB_LookForTexture)
    not GetFileIDFromPath(fullTextureName) -- File path is missing
  then
    self:Error(Module, "Missing file for texture "..texName);
  end
end

-- List fetched from bash: cd textures && ls -1 *.blp | cut -d. -f1 | tr 'A-Z' 'a-z' | sort | grep -vE '^(icon64|mask|maskzero|rkm128)$' | awk 'BEGIN{ print "local availableTextures = {" } {printf "  [\"%s\"] = true,\n", $0} END { print "}" }'
local availableTextures = {
  ["arcane_missiles"] = true,
  ["arcane_missiles_1"] = true,
  ["arcane_missiles_2"] = true,
  ["arcane_missiles_3"] = true,
  ["art_of_war"] = true,
  ["backlash"] = true,
  ["bandits_guile"] = true,
  ["blood_surge"] = true,
  ["brain_freeze"] = true,
  ["daybreak"] = true,
  ["echo_of_the_elements"] = true,
  ["eclipse_moon"] = true,
  ["eclipse_sun"] = true,
  ["feral_omenofclarity"] = true,
  ["frozen_fingers"] = true,
  ["fulmination"] = true,
  ["fury_of_stormrage"] = true,
  ["fury_of_stormrage_yellow"] = true,
  ["genericarc_02"] = true,
  ["genericarc_05"] = true,
  ["generictop_01"] = true,
  ["high_tide"] = true,
  ["hot_streak"] = true,
  ["imp_empowerment"] = true,
  ["impact"] = true,
  ["killing_machine"] = true,
  ["lock_and_load"] = true,
  ["maelstrom_weapon"] = true,
  ["maelstrom_weapon_1"] = true,
  ["maelstrom_weapon_2"] = true,
  ["maelstrom_weapon_3"] = true,
  ["maelstrom_weapon_4"] = true,
  ["maelstrom_weapon_6"] = true,
  ["maelstrom_weapon_7"] = true,
  ["maelstrom_weapon_8"] = true,
  ["maelstrom_weapon_9"] = true,
  ["maelstrom_weapon_10"] = true,
  ["master_marksman"] = true,
  ["molten_core"] = true,
  ["monk_serpent"] = true,
  ["natures_grace"] = true,
  ["nightfall"] = true,
  ["predatory_swiftness"] = true,
  ["raging_blow"] = true,
  ["rime"] = true,
  ["serendipity"] = true,
  ["shadow_word_insanity"] = true,
  ["shooting_stars"] = true,
  ["sudden_death"] = true,
  ["sudden_doom"] = true,
  ["surge_of_light"] = true,
  ["sword_and_board"] = true,
  ["thrill_of_the_hunt_1"] = true,
  ["thrill_of_the_hunt_2"] = true,
  ["thrill_of_the_hunt_3"] = true,
  ["tooth_and_claw"] = true,
  ["white_tiger"] = true,
}

-- Global functions, helpful for optimizing package

function SAO_DB_ResetMarkedTextures(output)
  if not SpellActivationOverlayDB.dev then
    SpellActivationOverlayDB.dev = { marked = { native = {}, addon = {} } };
  else
    SpellActivationOverlayDB.dev.marked = { native = {}, addon = {} };
  end
  if type(output) ~= 'boolean' or output then
    print("SAO_DB_ResetMarkedTextures() "..WrapTextInColorCode("OK", "FF00FF00"));
  end

  return { marked = SpellActivationOverlayDB.dev.marked };
end

function SAO_DB_AddMarkedTextures(output)
  if not SpellActivationOverlayDB.dev or not SpellActivationOverlayDB.dev.marked then
    SAO_DB_ResetMarkedTextures(false);
  end

  for fullTextureName, filename in pairs(SAO.TextureFilenameFromFullname) do
    if SAO.MarkedTextures[fullTextureName] then
      if type(tonumber(fullTextureName)) == 'number' then
        SpellActivationOverlayDB.dev.marked.native[filename] = true;
      else
        SpellActivationOverlayDB.dev.marked.addon[filename] = true;
      end
    end
  end

  if type(output) ~= 'boolean' or output then
    print("SAO_DB_AddMarkedTextures() "..WrapTextInColorCode("OK", "FF00FF00"));
  end

  return { marked = SpellActivationOverlayDB.dev.marked };
end

--[[
Lua function that compares if string a is lower than string b.
Split each string with the underscore delimiter, then compare each splitted segment with its counterpart
- compare 1st segment of a with 1st segment of b, if one is lower then return true or false
- if both are equal then go to next segment and compare 2nd segment of a with 2nd segment of b, etc.
For each segment, the comparison follows these rules:
- if both segments are identical, continue algorithm to next segment
- if a segment is empty and the other is not, then the empty segment belongs to the 'lowest' string
- if a segment can be converted to a number but not the other, then the number-ish segment belongs to the 'lowest' string
- if both segments are strings, compare both strings with the < operator, then lowest segment string belongs to the 'lowest' string
- if both segments can be converted to numbers, compare segments using the < operator on the tonumber() conversion, then the lowest segment number belongs to the 'lowest' string
]]
local function compareTextureNames(a, b)
  local function splitString(str)
    local segments = {};
    for segment in string.gmatch(str, "[^_]+") do
      table.insert(segments, segment);
    end
    return segments;
  end
  local function isNumber(segment)
    return tonumber(segment) ~= nil;
  end
  local segmentsA = splitString(a);
  local segmentsB = splitString(b);
  for i = 1, math.max(#segmentsA, #segmentsB) do
    local segA = segmentsA[i] or "";
    local segB = segmentsB[i] or "";
    if segA == segB then
      -- Segments are identical, continue to next segment
    elseif segA == "" then
      -- String A has less segments: a is lower
      return true;
    elseif segB == "" then
      -- String B has less segments: a is lower
      return false;
    elseif isNumber(segA) and not isNumber(segB) then
      -- Comparing number of A with non-number of B: A is lower
      return true;
    elseif not isNumber(segA) and isNumber(segB) then
      -- Comparing non-number of A with number of B: B is lower
      return false;
    elseif isNumber(segA) and isNumber(segB) then
      -- Comparing number of A with number of B
      -- This has a flaw if two numbers are identical but different string representations
      -- But considering how texture names are built, this should not be a problem in practice
      -- Even if it happens, it's probably no big deal
      return tonumber(segA) < tonumber(segB);
    else
      -- Comparing non-number of A with non-number of B; we know A and B are different here
      return segA < segB;
    end
  end
  -- If all segments are identical, the strings are equal
  -- This should not happen if texture name tables were built correctly
  return false; -- Arbitrarily return false
end

function SAO_DB_ComputeUnmarkedTextures(output)
  SAO_DB_AddMarkedTextures(false); -- Not needed in theory, but it avoids confusion
  SpellActivationOverlayDB.dev.unmarked = { native = {}, addon = {} };

  -- Find unmarked textures, and classify them as either native or addon
  for fullTextureName, filename in pairs(SAO.TextureFilenameFromFullname) do
    if availableTextures[filename] then
      if     not SAO.MarkedTextures[fullTextureName] -- Not marked by current class
        and (not SpellActivationOverlayDB.dev.marked -- Mark not stored in database
              or (not SpellActivationOverlayDB.dev.marked.native[filename]
              and not SpellActivationOverlayDB.dev.marked.addon[filename])
            )
      then
        if type(tonumber(fullTextureName)) == 'number' then
          SpellActivationOverlayDB.dev.unmarked.native[filename] = tonumber(fullTextureName);
        else
          SpellActivationOverlayDB.dev.unmarked.addon[filename] = fullTextureName;
        end
      end
    end
  end

  -- Find the list of textures to exclude from the package
  local excludeListSorted = {};
  for k, _ in pairs(SpellActivationOverlayDB.dev.unmarked.addon) do
    tinsert(excludeListSorted, k);
  end
  table.sort(excludeListSorted, compareTextureNames);
  SpellActivationOverlayDB.dev.unmarked.excludeList = excludeListSorted;

  if type(output) ~= 'boolean' or output then
    print("SAO_DB_ComputeUnmarkedTextures() "..WrapTextInColorCode("OK", "FF00FF00"));

    local excludeListAsString = "";
    for _, v in ipairs(excludeListSorted) do
      excludeListAsString = excludeListAsString .. v .. '\n';
    end
    SAO:DumpCopyableText("Files to exclude from package:", excludeListAsString);
  end

  return { unmarked = SpellActivationOverlayDB.dev.unmarked };
end

function SAO_DB_LookForTexture(fileDataID, output, saveToDev)
  local f = CreateFrame("Frame", nil);
  local tex = f:CreateTexture();
  tex:SetPoint('CENTER', WorldFrame);

  f:SetAllPoints(tex);
  if saveToDev and SpellActivationOverlayDB.dev then
    SpellActivationOverlayDB.dev.existing[fileDataID] = nil;
  end
  f:SetScript('OnSizeChanged', function(self, width, height)
      local isLoaded = width > 15 and height > 15
      if saveToDev and SpellActivationOverlayDB.dev then
        SpellActivationOverlayDB.dev.existing.id[fileDataID] = isLoaded;

        SpellActivationOverlayDB.dev.existing.remaining = SpellActivationOverlayDB.dev.existing.remaining-1;
        if SpellActivationOverlayDB.dev.existing.remaining == 0 and (type(output) ~= 'boolean' or output) then
          print("SAO_DB_DetectExistingMarkedTextures() "..WrapTextInColorCode("Complete", "FF00FF00"));
        end
      end
      if not saveToDev and (type(output) ~= 'boolean' or output) then
        if isLoaded then
          SAO:Info(Module, "Texture "..tostring(fileDataID).." has been found in game files.");
        else
          SAO:Warn(Module, "Texture "..tostring(fileDataID).." has *not* been found in game files.");
        end
      end
      f:Hide();
  end);

  tex:SetTexture(fileDataID);

  tex:SetSize(0, 0); -- Reset size to make sure OnSizeChanged will be triggered
end

function SAO_DB_LookForAllTextures(output)
  SAO_DB_AddMarkedTextures(false); -- Not needed in theory, but it avoids confusion
  SpellActivationOverlayDB.dev.existing = { remaining = 0, id = {} };

  local fileDataIDs = {};

  for retailTexture in pairs(mapping) do
    table.insert(fileDataIDs, tonumber(retailTexture, 10));
  end

  SpellActivationOverlayDB.dev.existing.remaining = #fileDataIDs;
  for _, fileDataID in ipairs(fileDataIDs) do
    SAO_DB_LookForTexture(fileDataID, output, true);
  end

  if type(output) ~= 'boolean' or output then
    print("SAO_DB_DetectExistingMarkedTextures() "..WrapTextInColorCode("Pending ("..#fileDataIDs..")...", "FFFFFF00"));
  end
end
