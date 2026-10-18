-- || Made by and for Weird Vibes of Turtle WoW || --
local L = AutoMarkerLocale
BINDING_HEADER_AUTOMARK = L["|cff22CC00 - AutoMark Bindings -"];
BINDING_NAME_MOUSEOVERKEY = L["Keys to hold to activate mouseover mark"];
BINDING_NAME_RUNKEY = L["Mark mouseover or target"];
BINDING_NAME_NEXTKEY =L["Mark next group based on default order"];
BINDING_NAME_CLEARKEY = L["Clear all current marks"];
BINDING_NAME_AUTOMARKER_TOGGLEGUI = L["Toggle pack editor"];


-- Utility -------------------

local color = {
  white = "|cffffffff",
  red = "|cffff0000",
  green = "|cff00ff00",
  blue = "|cff0000ff",
  yellow = "|cffffff00",
  cyan = "|cff00ffff",
  magenta = "|cffff00ff",
  grey = "|cff808080",
  orange = "|cffff8000",
  purple = "|cffff00ff"}

local function c(text, color)
  return color..text.."|r"
end

local super_ver = SUPERWOW_VERSION and tonumber(SUPERWOW_VERSION)
local np_major, np_minor, np_patch
if GetNampowerVersion then
  np_major, np_minor, np_patch = GetNampowerVersion()
end
local use_nampower = np_major and (np_major > 2 or (np_major == 2 and np_minor >= 39))
local use_superwow = not use_nampower and SetAutoloot
local has_unitxp = pcall(UnitXP, "nop", "nop")

if not use_superwow and not use_nampower then
  StaticPopupDialogs["NO_SUPERWOW_AUTOLOOT"] = {
    text = (c("AutoMarker",color.yellow)..c(" requires SuperWoW 1.4+ or nampower 2.39+ to operate.",color.red)),
    button1 = TEXT(OKAY),
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
    showAlert = 1,
  }

  StaticPopup_Show("NO_SUPERWOW_AUTOLOOT")
  return
end

-- localise global fucntions to reduce function lookup cpu use
local GetPlayerBuff = GetPlayerBuff
local GetPlayerBuffID = GetPlayerBuffID
local UnitExists = UnitExists
local UnitName = UnitName
local UnitIsDead = UnitIsDead
local UnitHealth = UnitHealth
local SetRaidTarget = SetRaidTarget
local GetRaidTargetIndex = GetRaidTargetIndex
local GetRealZoneText = GetRealZoneText
local IsShiftKeyDown = IsShiftKeyDown
local IsControlKeyDown = IsControlKeyDown
local IsAltKeyDown = IsAltKeyDown
local UnitAffectingCombat = UnitAffectingCombat
local sfind = string.find
-- local sgfind = string.gfind -- overkill
local ssub = string.sub
local tinsert = table.insert
local tsort = table.sort
local tremove = table.remove
local pairs = pairs
local ipairs = ipairs
local next = next
local SendAddonMessage = SendAddonMessage
local GetNumPartyMembers = GetNumPartyMembers
local GetNumRaidMembers = GetNumRaidMembers
local CheckInteractDistance = CheckInteractDistance
local chat_add_msg = DEFAULT_CHAT_FRAME.AddMessage

local function auto_print(msg)
  if DEFAULT_CHAT_FRAME then chat_add_msg(DEFAULT_CHAT_FRAME,msg) end
end

local function elem(t,item)
  for _,k in t do
    if item == k then
      return true
    end
  end
  return false
end

local function tsize(t)
  local c = 0
  for _ in pairs(t) do c = c + 1 end
  return c
end

local function sortTableByKey(tbl)
  local sortedKeys = {}
  for key in pairs(tbl) do
      tinsert(sortedKeys, key)
  end
  tsort(sortedKeys)

  local sortedTable = {}
  for _, key in ipairs(sortedKeys) do
      sortedTable[key] = tbl[key]
  end
  return sortedTable
end

--[[[
This lines up the mob tables and the update table and picks out what's newer:
Say we have
  ["spider_anubrekhan"] = {
    ["0x101"] = 6, -- spider 1
    ["0x102"] = 7, -- spider 2
    ["0x10"] = 8, -- anub
  },
And
  update = {
    ["0x105"] = 6, -- spider 1
    ["0x106"] = 7, -- spider 2
  },
We get
  updated = {
    ["0x105"] = 6, -- spider 1
    ["0x106"] = 7, -- spider 2
    ["0x10"] = 8, -- anub
  },
--]]
local function sortAndReplaceKeys(defaultTable, updateTable, reverse)
  local keys = {}
  for key in pairs(defaultTable) do
      tinsert(keys, key)
  end

  local comp = function (a,b)
    if reverse then
        return a < b
    else
        return a > b
    end
  end

  tsort(keys, comp)

  local values = {}
  for _, value in pairs(updateTable) do
      tinsert(values, value)
  end
  tsort(values, comp)

  local updatedTable = {}
  local i = 1

  for _, key in ipairs(keys) do
      if values[i] then
          updatedTable[values[i]] = defaultTable[key]
          i = i + 1
      else
          updatedTable[key] = defaultTable[key]
      end
  end

  return updatedTable
end

-- Addon ---------------------

-- /// Util functions /// --

local function PostHookFunction(original,hook)
  return function(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    original(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
    hook(a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
  end
end

local function InGroup()
  return (GetNumPartyMembers() + GetNumRaidMembers() > 0)
end

local function PlayerCanRaidMark()
  return InGroup() and (IsRaidOfficer() or IsPartyLeader())
end

-- You may mark when you're a lead, assist, or you're doing soloplay
local function PlayerCanMark()
  return PlayerCanRaidMark() or not InGroup()
end

-- returns false if the mark was solo
local warned_lead = false
local function MarkUnit(unit,mark)
  if PlayerCanRaidMark() then
    SetRaidTarget(unit,mark)
    return true
  elseif use_superwow then
    if InGroup() and not warned_lead then
      DEFAULT_CHAT_FRAME:AddMessage(c(L["Warning:"],color.red)..L[" a mark set while not a leader/assistant is not visible to others"])
      warned_lead = true
    end
    SetRaidTarget(unit,mark,1)
  end
  return false
end

local function MarkPack(pack)
  for guid,mark in pairs(pack) do
    if UnitExists(guid) then
      MarkUnit(guid,mark)
    end
  end
end

function AutoMarker_ClearMarks()
  local markfunc = InGroup() and
    SetRaidTarget or
    function (t,m) SetRaidTarget(t,m,1) end
  for i=1,8 do
    if UnitExists("mark"..i) then markfunc("mark"..i,0) end
  end
end

function AutoMarker_MarkName(name)
  local sortedCache = {}
  for guid,name in pairs(AutoMarkerDB.unitCache) do
    tinsert(sortedCache, { guid = guid, name = name })
  end

  local function sortUnitsByInteractDistance(units)
    tsort(units, function(a, b)
        local aInRange = CheckInteractDistance(a.guid,4)
        local bInRange = CheckInteractDistance(b.guid,4)
        if aInRange and not bInRange then
            return true
        elseif not aInRange and bInRange then
            return false
        else
            return false -- Maintain original order if both are the same
        end
    end)
  end
  sortUnitsByInteractDistance(sortedCache)

  -- clear far marks to help prio close
  for i=1,8 do
    local _,m = UnitExists("mark"..i)
    if m and not CheckInteractDistance(m,4) then
      MarkUnit(m,0)
    end
  end

  local hit = false
  for _, data in ipairs(sortedCache) do
    if not UnitExists(data.guid) then
      AutoMarkerDB.unitCache[data.guid] = nil
    elseif not UnitIsDead(data.guid) and string.lower(UnitName(data.guid)) == string.lower(name) then
      hit = true
      for i=8,1,-1 do
        local _,m = UnitExists("mark"..i)
        if m and UnitExists(m) and not UnitIsDead(m) then
          -- mark is used on already
        else
          MarkUnit(data.guid,i)
          break
        end
      end
    end
  end
  if not hit then
    auto_print(name .. L[" wasn't found nearby!"])
  end
end

function AutoMarker_MarkGuidPattern(guidPattern)
  local sortedCache = {}
  local cacheSize = 0
  for guid,name in pairs(AutoMarkerDB.unitCache) do
    cacheSize = cacheSize + 1
    if sfind(guid, "^" .. guidPattern) then
      tinsert(sortedCache, { guid = guid, name = name })
    end
  end
  auto_print("cache: " .. cacheSize .. " | matches: " .. getn(sortedCache) .. " | pattern: " .. guidPattern)

  tsort(sortedCache, function(a, b)
    if has_unitxp then
      local aDist = UnitXP("distanceBetween", "player", a.guid) or 999
      local bDist = UnitXP("distanceBetween", "player", b.guid) or 999
      return aDist < bDist
    else
      local aInRange = CheckInteractDistance(a.guid, 4)
      local bInRange = CheckInteractDistance(b.guid, 4)
      if aInRange and not bInRange then return true end
      return false
    end
  end)

  local hit = false
  for _, data in ipairs(sortedCache) do
    if not UnitExists(data.guid) then
      AutoMarkerDB.unitCache[data.guid] = nil
    elseif not UnitIsDead(data.guid) then
      hit = true
      for i=8,1,-1 do
        local _,m = UnitExists("mark"..i)
        if m and UnitExists(m) and not UnitIsDead(m) then
          -- mark is used already
        else
          MarkUnit(data.guid,i)
          break
        end
      end
    end
  end
  if not hit then
    auto_print(guidPattern .. L[" wasn't found nearby!"])
  end
end

-- /// Allow marking solo as well /// --

local function AM_UnitPopup_HideButtons()
  local dropdownMenu = _G[UIDROPDOWNMENU_INIT_MENU];

  for index, value in ipairs(UnitPopupMenus[dropdownMenu.which]) do
    if ( strsub(value, 1, 12)  == "RAID_TARGET_" ) then
      UnitPopupShown[UIDROPDOWNMENU_MENU_LEVEL][index] = 1;
    end
  end
end
UnitPopup_HideButtons = PostHookFunction(UnitPopup_HideButtons,AM_UnitPopup_HideButtons)

local function AM_UnitPopup_OnClick()
  local dropdownFrame = getglobal(UIDROPDOWNMENU_INIT_MENU);
  local button = this.value;
  local unit = dropdownFrame.unit;

  if ( strsub(button, 1, 12) == "RAID_TARGET_" and button ~= "RAID_TARGET_ICON" ) then
    local raidTargetIndex = strsub(button, 13);
    if ( raidTargetIndex == "NONE" ) then
      raidTargetIndex = 0;
    end
    MarkUnit(unit, tonumber(raidTargetIndex))
  end
  PlaySound("UChatScrollButton");
end
UnitPopup_OnClick = PostHookFunction(UnitPopup_OnClick,AM_UnitPopup_OnClick)

------------------------------

local raidMarks = { L["Unmarked"], L["Star"], L["Circle"], L["Diamond"], L["Triangle"], L["Moon"], L["Square"], L["Cross"], L["Skull"] }

local defaultSettings = {
  enabled = true,
  debug = false,
  autoAdd = true,             -- in a raid instance, add targeted unknown mobs as UNMARKED
  autoAddRadius = 10,         -- yards, also grab unknown mobs around the target into the same new pack (0 = target only, needs UnitXP)
  guiFollowTarget = true,     -- the editor follows the pack of your target
}

local sweep_on = false
local sweepPackName = nil
local currentPackName = nil
local currentNpcsToMark = {}
local last_pack_marked = nil
local elapsed = 0
local core_delay = 3
local core_delay_elapsed = 0
local aggro_tracker = {}

local solinus_prio = { L["Sanctum Supressor"], L["Sanctum Dragonkin"], L["Sanctum Wyrmkin"], L["Sanctum Scalebane"] }

local autoMarker = CreateFrame("Frame","AutoMarkerFrame")

local function guidToPack(id, zone)
  if not currentNpcsToMark or not currentNpcsToMark[zone] then
    return
  end
  -- scan for the id, but, we also want to prioritise custom markings
  local rPackName,rPack
  -- PERF (modif. locale) : acces direct packInfo[id] au lieu de parcourir chaque pack
  for packName, packInfo in pairs(currentNpcsToMark[zone]) do
    if packInfo[id] ~= nil then
      rPackName = packName
      rPack = packInfo
    end
  end
  for packName, packInfo in pairs(AutoMarkerDB.customNpcsToMark[zone] or {}) do
    if packInfo[id] ~= nil then
      rPackName = packName
      rPack = packInfo
    end
  end
  return rPackName,rPack
end

-- /// Global storage /// --------------------------------------------------
--[[
  SavedVariables are per account (or per character) on the 1.12 client.
  To share the configuration between every account and character, custom packs
  are written to a plain text file through ExportFile/ImportFile, provided by
  SuperWoW and nampower:  <WoW folder>\Imports\AutoMarker_Config.txt
  AutoMarkerDB.customNpcsToMark is still kept as a per-account backup / fallback.

  The file uses the same layout as NPCList.lua so blocks can be read, edited by hand
  or copied between both files:

    addToCustomNpcsToMark("Naxxramas", "spider_entrance_right", {
      ["0xF130003E680158F6"] = { mark = SKULL, name = "Venom Stalker", map = 533, x = 2873.4, y = -3416.2 },
    })

  * each block replaces the default pack of the same name (or adds a new pack)
  * map / x / y: spawn position recorded the first time the mob is targeted
    (map = Map.dbc id, x / y = world coordinates in yards, 0 = unknown)
  * mapInfo: name and type ("raid", "party" = dungeon, "pvp") of every instance map entered
  * when the file is missing or empty it is created from every pack of NPCList.lua
  The file is never executed: it is parsed line by line, so keep one entry per line.
--]]

local GLOBAL_FILE = "AutoMarker_Config"
local has_file_io = type(ExportFile) == "function" and type(ImportFile) == "function"
local npcNames = {}          -- guid -> name, learned in game (global file)
local npcPos = {}            -- guid -> { map =, x =, y = }, learned in game (global file)
local mapInfo = {}           -- map id -> { name =, type = "raid" | "party" | "pvp" }, learned in game (global file)
local save_dirty = false
local save_timer = 0
local SAVE_DELAY = 2         -- seconds of quiet before writing the file
-- PERF (modif. locale) : les changements automatiques (positions des mobs cibles,
-- type d'instance, packs decouverts) ne declenchent plus une reecriture complete
-- du fichier 2 s apres chaque cible ; ils sont ecrits au prochain ecran de
-- chargement, a la deconnexion, ou avec la prochaine sauvegarde normale.
local save_deferred = false
local warned_io = false

local function GetMobName(guid)
  if not guid then return nil end
  if UnitExists(guid) then
    local n = UnitName(guid)
    if n and n ~= "" and n ~= UNKNOWNOBJECT then
      npcNames[guid] = n
      return n
    end
  end
  local default = AutoMarkerDefaultNpcs and AutoMarkerDefaultNpcs[guid]
  return npcNames[guid]
    or (default and default.name)
    or (AutoMarkerDB and AutoMarkerDB.unitCache and AutoMarkerDB.unitCache[guid])
end

-- /// Positions /// --
-- Current map id (Map.dbc row: 0 Eastern Kingdoms, 1 Kalimdor, 409 Molten Core, 533 Naxxramas...)
local function GetCurrentMapId()
  if type(GetInstanceInfo) == "function" then
    -- ClassicAPI: name, type, difficultyID, difficultyName, maxPlayers, dynamicDifficulty, isDynamic, instanceID
    local ok, _, _, _, _, _, _, _, id = pcall(GetInstanceInfo)
    if ok and tonumber(id) then return tonumber(id) end
  end
  return 0
end

local function Round1(v)
  return math.floor(v * 10 + 0.5) / 10
end

-- returns map, x, y (world coordinates, yards) or nil
local function ReadUnitPosition(unit)
  if type(UnitPosition) ~= "function" or not unit then return nil end
  local ok, a, b, c, d = pcall(UnitPosition, unit)
  if not ok or not tonumber(a) or not tonumber(b) then return nil end
  if a == 0 and b == 0 then return nil end
  local x, y, map
  if tonumber(d) then
    -- ClassicAPI shape: posY, posX, posZ, mapID
    x, y, map = b, a, tonumber(d)
  else
    -- SuperWoW shape: x, y, z
    x, y = a, b
  end
  return map or GetCurrentMapId(), Round1(x), Round1(y)
end

-- returns map, x, y of the recorded position, or nil when it is missing / null
local function GetMobPos(guid)
  local p = npcPos[guid]
  if p then return p.map, p.x, p.y end
  local d = AutoMarkerDefaultNpcs and AutoMarkerDefaultNpcs[guid]
  if d and ((tonumber(d.x) or 0) ~= 0 or (tonumber(d.y) or 0) ~= 0) then
    return tonumber(d.map) or 0, d.x, d.y
  end
  return nil
end

local function SortedKeys(t)
  local keys = {}
  for k in pairs(t or {}) do tinsert(keys, k) end
  tsort(keys)
  return keys
end

local function CleanField(s)
  local r = string.gsub(tostring(s or ""), "[\t\r\n]", " ")
  return r
end

local function SplitTabs(line)
  local t, start = {}, 1
  while true do
    local s, e = sfind(line, "\t", start, true)
    if not s then
      tinsert(t, ssub(line, start))
      return t
    end
    tinsert(t, ssub(line, start, s - 1))
    start = e + 1
  end
end

local MARK_NAMES = { [0] = "UNMARKED", "STAR", "CIRCLE", "DIAMOND", "TRIANGLE", "MOON", "SQUARE", "CROSS", "SKULL" }
local MARK_VALUES = {}
for i = 0, 8 do MARK_VALUES[MARK_NAMES[i]] = i end

local function LuaQuote(str)
  local r = string.gsub(tostring(str or ""), '\\', '\\\\')
  r = string.gsub(r, '"', '\\"')
  r = string.gsub(r, "[\r\n]", " ")
  return '"' .. r .. '"'
end

-- reads the quoted string starting at `pos` (on the quote); returns the string and the position after it
local function ReadQuoted(line, pos)
  local q = ssub(line, pos, pos)
  if q ~= '"' and q ~= "'" then return nil end
  local out, i, len = {}, pos + 1, string.len(line)
  while i <= len do
    local ch = ssub(line, i, i)
    if ch == "\\" then
      local n = ssub(line, i + 1, i + 1)
      if n == "n" then n = "\n" end
      tinsert(out, n)
      i = i + 2
    elseif ch == q then
      return table.concat(out), i + 1
    else
      tinsert(out, ch)
      i = i + 1
    end
  end
  return nil
end

-- one mob entry, same layout as NPCList.lua
local function EntryLine(guid, mark)
  local map, x, y = GetMobPos(guid)
  return format("  [%s] = { mark = %s, name = %s, map = %d, x = %s, y = %s },",
    LuaQuote(guid), MARK_NAMES[mark] or "UNMARKED", LuaQuote(GetMobName(guid) or ""), map or 0,
    x and format("%.1f", x) or "0", y and format("%.1f", y) or "0")
end

-- packs of a zone in NPCList.lua order, then the others alphabetically
local function OrderedPackNames(zone, packs)
  local list, seen, rest = {}, {}, {}
  for _, p in ipairs(orderedPacks) do
    if p.instance == zone and packs[p.packName] and not seen[p.packName] then
      tinsert(list, p.packName)
      seen[p.packName] = true
    end
  end
  for name in pairs(packs) do
    if not seen[name] then tinsert(rest, name) end
  end
  tsort(rest)
  for _, name in ipairs(rest) do tinsert(list, name) end
  return list
end

local function SerializeConfig()
  local out = {
    "-- AutoMarker - global configuration, shared by every account and character.",
    "-- Same layout as NPCList.lua: each block replaces the default pack of the same name, or adds a new pack.",
    "-- mark: SKULL, CROSS, SQUARE, MOON, TRIANGLE, DIAMOND, CIRCLE, STAR, UNMARKED",
    "-- map / x / y: spawn position (Map.dbc id, world coordinates in yards), 0 = not recorded yet:",
    "-- it is filled the first time the mob is targeted out of combat.",
    "-- Written by the addon (/am save) and read back on login (/am reload): hand edits are fine, keep one entry per line.",
  }
  local maps = SortedKeys(mapInfo)
  if maps[1] then
    tinsert(out, "")
    tinsert(out, "--/////////////// Maps ///////////////")
    tinsert(out, "-- type: raid, party (dungeon) or pvp, recorded the first time the instance is entered")
    tinsert(out, "")
    tinsert(out, "mapInfo = {")
    for _, id in ipairs(maps) do
      local m = mapInfo[id]
      tinsert(out, format("  [%d] = { name = %s, type = %s },", id, LuaQuote(m.name or ""), LuaQuote(m.type or "")))
    end
    tinsert(out, "}")
  end

  local customs = AutoMarkerDB.customNpcsToMark
  local written = {}
  for _, zone in ipairs(SortedKeys(customs)) do
    tinsert(out, "")
    tinsert(out, "--/////////////// " .. string.gsub(zone, "[\r\n]", " ") .. " ///////////////")
    for _, packName in ipairs(OrderedPackNames(zone, customs[zone])) do
      local pack = customs[zone][packName]
      tinsert(out, "")
      tinsert(out, "addToCustomNpcsToMark(" .. LuaQuote(zone) .. ", " .. LuaQuote(packName) .. ", {")
      local guids = SortedKeys(pack)
      tsort(guids, function(a, b)
        local ma, mb = tonumber(pack[a]) or 0, tonumber(pack[b]) or 0
        if ma ~= mb then return ma > mb end
        return a < b
      end)
      for _, guid in ipairs(guids) do
        tinsert(out, EntryLine(guid, tonumber(pack[guid]) or 0))
        written[guid] = true
      end
      tinsert(out, "})")
    end
  end

  -- positions of mobs that are not in any pack of the file (moved out / removed)
  local orphans = {}
  for _, guid in ipairs(SortedKeys(npcPos)) do
    if not written[guid] then tinsert(orphans, guid) end
  end
  if orphans[1] then
    tinsert(out, "")
    tinsert(out, "--/////////////// Positions of mobs in no pack ///////////////")
    tinsert(out, "")
    tinsert(out, "npcPositions = {")
    for _, guid in ipairs(orphans) do
      local p = npcPos[guid]
      tinsert(out, format("  [%s] = { name = %s, map = %d, x = %.1f, y = %.1f },",
        LuaQuote(guid), LuaQuote(GetMobName(guid) or ""), p.map or 0, p.x, p.y))
    end
    tinsert(out, "}")
  end
  return table.concat(out, "\n") .. "\n"
end

-- Previous tab separated format (AutoMarker 1.23 - 1.25), still read once to migrate it.
local function ParseLegacyConfig(text, packs, names, positions)
  for line in string.gfind(text, "[^\r\n]+") do
    if ssub(line, 1, 1) ~= "#" then
      local f = SplitTabs(line)
      if f[1] == "P" and f[2] and f[3] then
        packs[f[2]] = packs[f[2]] or {}
        packs[f[2]][f[3]] = packs[f[2]][f[3]] or {}
      elseif f[1] == "M" and f[2] and f[3] and f[4] and f[4] ~= "" then
        packs[f[2]] = packs[f[2]] or {}
        packs[f[2]][f[3]] = packs[f[2]][f[3]] or {}
        local mark = tonumber(f[5]) or 0
        if mark < 0 or mark > 8 then mark = 0 end
        packs[f[2]][f[3]][f[4]] = mark
      elseif f[1] == "N" and f[2] and f[3] and f[3] ~= "" then
        names[f[2]] = f[3]
      elseif f[1] == "L" and f[2] and tonumber(f[4]) and tonumber(f[5]) then
        positions[f[2]] = { map = tonumber(f[3]) or 0, x = tonumber(f[4]), y = tonumber(f[5]) }
      end
    end
  end
end

-- returns packs, names, positions, is_legacy_format  or nil when there is no file
local function ParseConfig(text)
  if not text or text == "" then return nil end
  local packs, names, positions, maps = {}, {}, {}, {}

  if not sfind(text, "NpcsToMark", 1, true) and not sfind(text, "npcPositions", 1, true) then
    ParseLegacyConfig(text, packs, names, positions)
    return packs, names, positions, true, maps -- legacy: rewrite it in the new layout
  end

  local zone, packName, block -- block: "pack" or "positions"
  for raw in string.gfind(text, "[^\r\n]+") do
    local _, _, line = sfind(raw, "^%s*(.-)%s*$")
    if ssub(line, 1, 2) == "--" or line == "" then
      -- comment / blank line
    elseif sfind(line, "^addTo%a*NpcsToMark%s*%(") then
      local z, p, after, q2
      local q1 = sfind(line, "[\"']")
      if q1 then z, after = ReadQuoted(line, q1) end
      if after then q2 = sfind(line, "[\"']", after) end
      if q2 then p = ReadQuoted(line, q2) end
      if z and p then
        zone, packName, block = z, p, "pack"
        packs[zone] = packs[zone] or {}
        packs[zone][packName] = packs[zone][packName] or {}
      else
        block = nil
      end
      if sfind(line, "}%s*%)%s*;?%s*$") then block = nil end -- empty pack on one line
    elseif sfind(line, "^npcPositions%s*=%s*{") then
      block = "positions"
    elseif sfind(line, "^mapInfo%s*=%s*{") then
      block = "maps"
    elseif block == "maps" and sfind(line, "^%[%s*%d+%s*%]") then
      local _, _, id = sfind(line, "^%[%s*(%d+)%s*%]")
      local _, ne = sfind(line, "[%s{,]name%s*=%s*")
      local name = ne and ReadQuoted(line, ne + 1)
      local _, _, itype = sfind(line, "[%s{,]type%s*=%s*[\"'](%a+)[\"']")
      if tonumber(id) and itype then
        maps[tonumber(id)] = { name = name or "", type = itype }
      end
    elseif ssub(line, 1, 1) == "}" then
      block = nil
    elseif block and ssub(line, 1, 1) == "[" then
      local guid, after = ReadQuoted(line, 2)
      if guid and guid ~= "" then
        local body = " " .. ssub(line, after or 1)
        -- name: `name = "..."` field, or the comment of the old layout
        local name
        local _, ne = sfind(body, "[%s{,]name%s*=%s*")
        if ne then
          local qe
          name, qe = ReadQuoted(body, ne + 1)
          if name and qe then body = ssub(body, 1, ne) .. ssub(body, qe) end
        end
        local cut = sfind(body, "--", 1, true)
        if cut then
          if not name then
            local _, _, comment = sfind(ssub(body, cut), "^%-%-%s*(.-)%s*$")
            name = comment
          end
          body = ssub(body, 1, cut - 1)
        end
        if name and name ~= "" then
          local default = AutoMarkerDefaultNpcs and AutoMarkerDefaultNpcs[guid]
          if not (default and default.name == name) then names[guid] = name end
        end
        local _, _, map = sfind(body, "[%s{,]map%s*=%s*(%-?[%d%.]+)")
        local _, _, x = sfind(body, "[%s{,]x%s*=%s*(%-?[%d%.]+)")
        local _, _, y = sfind(body, "[%s{,]y%s*=%s*(%-?[%d%.]+)")
        if tonumber(x) and tonumber(y) and (tonumber(x) ~= 0 or tonumber(y) ~= 0) then
          positions[guid] = { map = tonumber(map) or 0, x = tonumber(x), y = tonumber(y) }
        end
        if block == "pack" then
          local _, _, value = sfind(body, "[%s{,]mark%s*=%s*([%w_]+)")
          if not value then _, _, value = sfind(body, "^%s*%]?%s*=%s*([%w_]+)") end
          local mark = value and (MARK_VALUES[value] or tonumber(value)) or 0
          if mark < 0 or mark > 8 then mark = 0 end
          packs[zone][packName][guid] = mark
        end
      end
    end
  end
  return packs, names, positions, false, maps
end

-- copies every default pack (NPCList.lua) that the configuration doesn't have yet
local function PopulateFromDefaults(customs)
  local added = 0
  for zone, packs in pairs(defaultNpcsToMark) do
    for packName, pack in pairs(packs) do
      customs[zone] = customs[zone] or {}
      if not customs[zone][packName] then
        local copy = {}
        for g, m in pairs(pack) do copy[g] = m end
        customs[zone][packName] = copy
        added = added + 1
      end
    end
  end
  return added
end

local function SaveGlobalConfig()
  save_dirty = false
  save_deferred = false
  if not has_file_io or not AutoMarkerDB then return false end
  local ok, err = pcall(ExportFile, GLOBAL_FILE, SerializeConfig())
  if not ok and not warned_io then
    warned_io = true
    auto_print(c("AutoMarker: ", color.yellow) .. c(L["unable to write "] .. "Imports\\" .. GLOBAL_FILE .. ".txt: ", color.red) .. tostring(err))
  end
  return ok
end

local function LoadGlobalConfig()
  if not has_file_io then return nil end
  local ok, text = pcall(ImportFile, GLOBAL_FILE)
  if not ok then return nil end
  return ParseConfig(text)
end

local function MarkConfigDirty(background)
  if background then
    save_deferred = true
  else
    save_dirty = true
    save_timer = 0
  end
  if AutoMarkerAPI and AutoMarkerAPI.OnDataChanged then
    AutoMarkerAPI.OnDataChanged()
  end
end

-- Records the position of a mob the first time it is seen (force = overwrite).
-- Skipped in combat so the stored position stays the spawn position.
-- current instance: map id, type ("raid", "party", "pvp", "none"), name
local function GetCurrentInstance()
  local id, itype, name
  if type(GetInstanceInfo) == "function" then
    local ok, n, t, _, _, _, _, _, i = pcall(GetInstanceInfo)
    if ok then name, itype, id = n, t, tonumber(i) end
  end
  if not itype then
    local inInstance, t = IsInInstance()
    itype = t or (inInstance and "unknown") or "none"
  end
  return id or 0, itype, name or GetRealZoneText()
end

-- remembers the type of the instance map we are in, returns its id and type
local function NoteCurrentMap()
  local id, itype, name = GetCurrentInstance()
  if id ~= 0 and itype ~= "none" and itype ~= "unknown" then
    local m = mapInfo[id]
    if not m or m.type ~= itype or m.name ~= name then
      mapInfo[id] = { name = name, type = itype }
      MarkConfigDirty(true)
    end
  end
  return id, itype
end

local function IsCurrentMapRaid()
  local id, itype = NoteCurrentMap()
  if itype == "raid" then return true end
  if itype ~= "unknown" then return false end
  return mapInfo[id] and mapInfo[id].type == "raid" or false
end

local function RecordMobPos(guid, unit, force)
  if not guid then return false end
  unit = unit or guid
  if not force and (GetMobPos(guid) or UnitAffectingCombat(unit)) then return false end
  local map, x, y = ReadUnitPosition(unit)
  if not map then return false end
  npcPos[guid] = { map = map, x = x, y = y }
  MarkConfigDirty(true)
  return true
end

-- Makes sure the pack has its own editable (custom) copy, seeded from the default pack.
local function EnsureCustomPack(zone, pack)
  local customs = AutoMarkerDB.customNpcsToMark
  customs[zone] = customs[zone] or {}
  if not customs[zone][pack] then
    local copy = {}
    local base = defaultNpcsToMark[zone] and defaultNpcsToMark[zone][pack]
    if base then
      for g, m in pairs(base) do copy[g] = m end
    end
    customs[zone][pack] = copy
  end
  currentNpcsToMark[zone] = currentNpcsToMark[zone] or {}
  currentNpcsToMark[zone][pack] = customs[zone][pack]
  return customs[zone][pack]
end

-- Remove a mob from every pack of the zone (except `keep`), creating overrides where needed.
local function RemoveMobEverywhere(zone, guid, keep)
  for packName, pack in pairs(currentNpcsToMark[zone] or {}) do
    if packName ~= keep and pack[guid] then
      EnsureCustomPack(zone, packName)[guid] = nil
    end
  end
  for packName, pack in pairs(AutoMarkerDB.customNpcsToMark[zone] or {}) do
    if packName ~= keep and pack[guid] then
      pack[guid] = nil
    end
  end
end

local function NewPackName(zone, prefix)
  prefix = prefix or "new_"
  local i = 1
  while true do
    local name = prefix .. (i < 10 and "0" or "") .. i
    if not (currentNpcsToMark[zone] and currentNpcsToMark[zone][name]) then
      return name
    end
    i = i + 1
  end
end

function AutoMarker_MarkGroup()
  local _, mouseoverGuid = UnitExists("mouseover")
  local _, targetGuid = UnitExists("target")
  targetGuid = mouseoverGuid or targetGuid
  if targetGuid and not UnitIsDead(targetGuid) and PlayerCanMark() then
    local pack, packMobs = guidToPack(targetGuid, GetRealZoneText())
    MarkPack(packMobs or {})
    last_pack_marked = pack
  end
end

function AutoMarker_MarkNextGroup()
  local zone = GetRealZoneText()

  for i, pack in ipairs(orderedPacks) do
    if pack.instance == zone then
      if not last_pack_marked or pack.packName == last_pack_marked then
        local nextPack = orderedPacks[i + (last_pack_marked and 1 or 0)]
        if nextPack and nextPack.instance == zone then
          auto_print(L["Marking: "] .. nextPack.packName)
          MarkPack(currentNpcsToMark[zone][nextPack.packName])
          last_pack_marked = nextPack.packName
          break
        end
      end
    end
  end
end

-- this should not spit out the result, only true or false whether it suceeded, maybe a 2nd return value of what the error was
local function AddToPack(guid,force_add,pack)
  local the_pack = pack or currentPackName
  local force = force_add or false
  if not guid then
    return false,"no_guid"
  end
  if not the_pack then
    return false,"no_pack_name"
  end

  local unitName, raidmark = UnitName(guid), GetRaidTargetIndex(guid) or 0
  local zoneName = GetRealZoneText()

  local mob_pack_name = guidToPack(guid, zoneName)
  if mob_pack_name and not force then
    return false,"mob_in_pack"
  end

  -- a mob belongs to a single pack: take it out of its previous one
  if mob_pack_name and mob_pack_name ~= the_pack then
    RemoveMobEverywhere(zoneName, guid, the_pack)
  end

  -- editable copy of the pack (seeded with the default pack if there is one), shared with the live table
  local pack_table = EnsureCustomPack(zoneName, the_pack)

  local existing_mark = pack_table[guid]
  local same = existing_mark and (existing_mark == raidmark)
  if not same then
    auto_print((existing_mark and L["Updating "] or L["Adding "]) .. (unitName or "?") .. "(" .. guid .. L[") in pack: "] .. the_pack .. L[" with new mark: "] .. raidMarks[raidmark + 1] .. L[" in zone: "] .. zoneName)
    pack_table[guid] = raidmark
    GetMobName(guid)
    MarkConfigDirty()
  end
  return true, nil
end

local function OnMouseover()
  if AutoMarkerDB.settings.enabled and IsShiftKeyDown() and (IsControlKeyDown() or IsAltKeyDown()) then
    AutoMarker_MarkGroup()
  end
end

-- Certain bosses have script spawned adds, so their id's are not consistent, this mechanism is to assign them marks.
local temporary_mobs = {
  [L["Deathknight Understudy"]] = {
    minCount = 4,
    pack = "military_razuvious",
    raid = L["Naxxramas"],
    queue = {},
  },
  ["Kodiak"] = {
    minCount = 1,
    pack = "rotgrowl",
    raid = L["Timbermaw Hold"],
    queue = {},
  },
  [L["Crypt Guard"]] = {
    minCount = 2,
    pack = "spider_anubrekhan",
    raid = L["Naxxramas"],
    queue = {},
  },
  ["Faerlina Add"] = {
    minCount = 6,
    pack = "spider_faerlina",
    raid = L["Naxxramas"],
    queue = {},
  },
  ["Domo Add"] = {
    minCount = 8,
    pack = "domo",
    raid = L["Molten Core"],
    queue = {},
    reverse = true, -- adds have lower id than boss
  },
  [L["The Prophet Skeram"]] = {
    minCount = 3,
    pack = "skeram",
    raid = L["Ahn'Qiraj"],
    live_mark = true, -- do the mobs change in combat
    queue = {},
  },
  [L["High Priestess Arlokk"]] = {
    minCount = 1,
    pack = "arlokk",
    raid = L["Zul'Gurub"],
    live_mark = true, -- do the mobs change in combat
    queue = {},
  },
  ["Gnarlmoon Owl"] = {
    minCount = 4,
    pack = "gnarlmoon_owls",
    raid = L["Tower of Karazhan"],
    live_mark = true, -- do the mobs change in combat
    queue = {},
    reverse = true,
  },
  ["Manascale Ley-Seeker"] = {
    minCount = 4,
    pack = "incantagos_seekers",
    raid = L["Tower of Karazhan"],
    queue = {},
    reverse = true,
  },
  ["Fragment of Rupturan"] = {
    minCount = 3,
    pack = "rupturan_fragments",
    raid = L["The Rock of Desolation"],
    live_mark = true,
    queue = {},
  },
  ["Crumbling Exile"] = {
    minCount = 4,
    pack = "rupturan_exile",
    raid = L["The Rock of Desolation"],
    live_mark = false,
    queue = {},
    reverse = true,
  },
  ["Hellfire Doomguard"] = {
    minCount = 2,
    pack = "mephistroth",
    raid = L["The Rock of Desolation"],
    live_mark = true,
    queue = {},
    -- reverse = true,
  },
  ["Onyxian Hatcher"] = {
    minCount = 2,
    pack = "onyxia_hatchers",
    raid = L["Onyxia's Lair"],
    live_mark = true,
    queue = {},
  },
  ["Withermaw Illuminator"] = {
    minCount = 2,
    pack = "chieftain_illuminators",
    raid = L["Timbermaw Hold"],
    queue = {},
  },
  ["Withermaw Shadowkeeper"] = {
    minCount = 2,
    pack = "chieftain_shadowkeepers",
    raid = L["Timbermaw Hold"],
    live_mark = true,
    queue = {},
  },
  ["Withermaw Corrupter"] = {
    minCount = 2,
    pack = "ursol_corrupters",
    raid = L["Timbermaw Hold"],
    queue = {},
    reverse = true,
  },
  ["Buru Egg"] = {
    minCount = 6,
    pack = "buru_eggs",
    raid = L["Ruins of Ahn'Qiraj"],
    live_mark = false, -- a different mechanism will handle live buru eggs
    queue = {},
  },
}

-- /// Discovery of unknown mobs /// ----------------------------------------
-- In a raid, targeting a mob that is not in any pack adds it (UNMARKED) to a new pack,
-- together with the unknown mobs standing around it, so it can be edited later in the GUI.

local function IsDiscoverable(guid)
  if not guid or ssub(guid, 1, 5) ~= "0xF13" then return false end -- creatures only (no players, pets, objects)
  if not UnitExists(guid) or UnitIsDead(guid) then return false end
  if UnitIsPlayer(guid) or UnitPlayerControlled(guid) then return false end
  if not UnitCanAttack("player", guid) then return false end
  local ctype = UnitCreatureType(guid)
  if ctype == "Critter" or ctype == "Non-combat Pet" then return false end
  local name = UnitName(guid)
  if not name or temporary_mobs[name] then return false end -- script spawned adds are handled elsewhere
  return true
end

local function DiscoverTarget()
  local s = AutoMarkerDB.settings
  if not s.autoAdd then return end
  if not IsCurrentMapRaid() then return end -- raid instances only (not dungeons / open world)

  local _, guid = UnitExists("target")
  if not IsDiscoverable(guid) then return end
  local zone = GetRealZoneText()
  if not zone or zone == "" or guidToPack(guid, zone) then return end

  local members = { guid }
  local radius = tonumber(s.autoAddRadius) or 0
  if radius > 0 and has_unitxp then
    for g in pairs(AutoMarkerDB.unitCache) do
      if g ~= guid and IsDiscoverable(g) and not UnitAffectingCombat(g) and not guidToPack(g, zone) then
        local ok, d = pcall(UnitXP, "distanceBetween", guid, g)
        if ok and d and d <= radius then
          tinsert(members, g)
        end
      end
    end
  end

  local packName = NewPackName(zone)
  local pack = EnsureCustomPack(zone, packName)
  for _, g in ipairs(members) do
    pack[g] = 0 -- UNMARKED
    GetMobName(g)
    RecordMobPos(g, g == guid and "target" or g)
  end
  MarkConfigDirty(true)
  auto_print(c("AutoMarker: ", color.yellow) .. L["new pack "] .. c(packName, color.orange) ..
    " (" .. getn(members) .. " mob" .. (getn(members) > 1 and "s" or "") .. ", " .. (UnitName(guid) or "?") .. ") - " ..
    c("/am ui", color.green) .. L[" to edit it"])
end

-- Order them and assign them ordered source marks
local function UpdateTemporaryMobs()
  for mob, config in pairs(temporary_mobs) do
    if GetRealZoneText() == config.raid and tsize(config.queue) >= config.minCount then
      -- Defensive: ensure default tables exist
      -- This was possibly causing wierd marking issues on skeram for people will broken/odd groups
      if not defaultNpcsToMark[config.raid] then
        config.queue = {}
        AutoMarkerDB.checkTemporaryMobs = false
        return
      end
      local defaultPack = defaultNpcsToMark[config.raid][config.pack]
      if not defaultPack then
        config.queue = {}
        AutoMarkerDB.checkTemporaryMobs = false
        return
      end

      -- Defensive: ensure current tables exist
      currentNpcsToMark[config.raid] = currentNpcsToMark[config.raid] or {}

      currentNpcsToMark[config.raid][config.pack] =
        sortAndReplaceKeys(defaultPack, config.queue, config.reverse)

      if config.live_mark then
        local updatedPack = currentNpcsToMark[config.raid][config.pack]
        if updatedPack then
          MarkPack(updatedPack)
        end
      end
      config.queue = {}
      AutoMarkerDB.checkTemporaryMobs = false
    end
  end
end

-- make it obvious what is the high hp hound
local function UpdateCorehound()
  if not next(AutoMarkerDB.temp_values.corehounds) or GetRealZoneText() ~= L["Molten Core"] then
    AutoMarkerDB.checkCoreHounds = false
    AutoMarkerDB.temp_values.corehounds = {}
    return
  end

  -- skip marking hounds if we marked a boss for pull
  if not UnitIsDead("mark8") and UnitName("mark8") ~= L["Core Hound"] then return end

  local t = {}
  for guid, _ in pairs(AutoMarkerDB.temp_values.corehounds) do
    if not UnitExists(guid) then
      AutoMarkerDB.temp_values.corehounds[guid] = nil
    elseif UnitAffectingCombat(guid) then
      tinsert(t, guid)
    end
  end
  -- if hp are the same, e.g. fight start, use lexigraphical sorting to keep mark stable
  tsort(t, function(a, b)
    if UnitHealth(a) == UnitHealth(b) then
      return a < b
    else
      return UnitHealth(a) > UnitHealth(b)
    end
  end)
  if t[1] and not GetRaidTargetIndex(t[1]) then
    MarkUnit(t[1], 8)
    SendAddonMessage(sync_prefix, "COREHOUND_MARKED", "RAID")
  end
end

-- keep close soliders visible using any spare marks
local function UpdateSoldiers()
  if not next(AutoMarkerDB.temp_values.soldiers) or GetRealZoneText() ~= L["The Upper Necropolis"] then
    AutoMarkerDB.checkSoliders = false
    AutoMarkerDB.temp_values.soldiers = {}
    return
  end

  for guid, _ in pairs(AutoMarkerDB.temp_values.soldiers) do
    if not UnitExists(guid) then
      AutoMarkerDB.temp_values.soldiers[guid] = nil
    elseif not GetRaidTargetIndex(guid) and UnitAffectingCombat(guid) and CheckInteractDistance(guid,4) then
      autoMarker:ApplyNextMark(guid)
    end
  end
end

local function UpdateKeepers()
  if not next(AutoMarkerDB.temp_values.keepers) or GetRealZoneText() ~= L["Blackrock Depths"] then
    AutoMarkerDB.checkKeepers = false
    AutoMarkerDB.temp_values.keepers = {}
    return
  end

  if GetSubZoneText() == L["The Lyceum"] then
    for guid, _ in pairs(AutoMarkerDB.temp_values.keepers) do
      if not UnitExists(guid) then
        AutoMarkerDB.temp_values.keepers[guid] = nil
      elseif not GetRaidTargetIndex(guid) then
        autoMarker:ApplyNextMark(guid)
      end
    end
  end
end

local function UpdateProtectors()
  if not next(AutoMarkerDB.temp_values.protectors) or GetRealZoneText() ~= L["Dire Maul"] then
    AutoMarkerDB.checkProtectors = false
    AutoMarkerDB.temp_values.protectors = {}
    return
  end

  if GetSubZoneText() == L["Capital Gardens"] then
    for guid, _ in pairs(AutoMarkerDB.temp_values.protectors) do
      if not UnitExists(guid) then
        AutoMarkerDB.temp_values.protectors[guid] = nil
      elseif not GetRaidTargetIndex(guid) then
        autoMarker:ApplyNextMark(guid) -- this might need a proper temp mob entry, depends if they all load at once
      end
    end
  end
end

local function AMUpdate()
  elapsed = elapsed + arg1
  core_delay_elapsed = core_delay_elapsed + arg1
  if save_dirty then
    save_timer = save_timer + arg1
    if save_timer > SAVE_DELAY and not UnitAffectingCombat("player") then SaveGlobalConfig() end
  end
  if elapsed > 0.25 then
    elapsed = 0

    if AutoMarkerDB.checkCoreHounds and core_delay_elapsed > core_delay then
      core_delay_elapsed = 0
      UpdateCorehound()
    end
    if AutoMarkerDB.checkSoliders then UpdateSoldiers() end
    if AutoMarkerDB.checkKeepers then UpdateKeepers() end
    if AutoMarkerDB.checkProtectors then UpdateProtectors() end
    if AutoMarkerDB.checkTemporaryMobs then UpdateTemporaryMobs() end
  end
end
autoMarker:SetScript("OnUpdate", AMUpdate)

-- EVENTS ----------------------

autoMarker:RegisterEvent("ADDON_LOADED")
autoMarker:RegisterEvent("UPDATE_MOUSEOVER_UNIT")
autoMarker:RegisterEvent("PLAYER_REGEN_DISABLED")
autoMarker:RegisterEvent("PLAYER_ENTERING_WORLD")
autoMarker:RegisterEvent("PLAYER_REGEN_ENABLED")
autoMarker:RegisterEvent("ZONE_CHANGED_NEW_AREA")
autoMarker:RegisterEvent("CHAT_MSG_ADDON") -- slow corehound mark swap
autoMarker:RegisterEvent("PLAYER_TARGET_CHANGED") -- discovery of unknown mobs + editor
autoMarker:RegisterEvent("PLAYER_LOGOUT") -- flush the global config file
autoMarker:RegisterEvent("PLAYER_LEAVING_WORLD") -- flush deferred changes behind the loading screen
autoMarker:RegisterEvent(use_nampower and "UNIT_MODEL_CHANGED_GUID" or "UNIT_MODEL_CHANGED")

autoMarker.TriggerEvent = function (self,event,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
  if autoMarker[event] then
    autoMarker[event](autoMarker,a1,a2,a3,a4,a5,a6,a7,a8,a9,a10)
  end
end

-- initial loading
autoMarker:SetScript("OnEvent", function ()
  if event == "ADDON_LOADED" and arg1 == "AutoMarker" then
    autoMarker:Initialize()
    autoMarker:SetScript("OnEvent", function ()
      if event == "PLAYER_LOGOUT" or event == "PLAYER_LEAVING_WORLD" then
        if save_dirty or save_deferred then SaveGlobalConfig() end
        return
      end
      if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
        NoteCurrentMap()
      end
      if event == "PLAYER_TARGET_CHANGED" then
        if AutoMarkerDB.settings.enabled then DiscoverTarget() end
        -- first time a known mob is targeted: remember where it stands
        local _, tguid = UnitExists("target")
        if tguid and guidToPack(tguid, GetRealZoneText()) then RecordMobPos(tguid, "target") end
        -- the editor works even when automatic marking is disabled
        if AutoMarkerAPI.OnTargetChanged then AutoMarkerAPI.OnTargetChanged() end
        return
      end
      if AutoMarkerDB.settings.enabled and autoMarker[event]then
        autoMarker[event](autoMarker,arg1,arg2,arg3,arg4,arg5,arg6,arg7,arg8,arg9,arg10)
      end
    end)
  end
end)

-- Event handlers
function autoMarker:Initialize()
  -- init vars
  if not AutoMarkerDB then AutoMarkerDB = {} end
  if not AutoMarkerDB.customNpcsToMark then AutoMarkerDB.customNpcsToMark = {} end
  if not AutoMarkerDB.temp_values then
    AutoMarkerDB.temp_values = {
      buru_egg_queue = {},
      corehounds = {},
      soldiers = {},
      keepers = {},
      protectors = {},
      solnius_adds = { count = 0 },
    }
  end
  if not AutoMarkerDB.unitCache then AutoMarkerDB.unitCache = {} end

  if not AutoMarkerDB.started_solnius then AutoMarkerDB.started_solnius = false end
  if not AutoMarkerDB.started_queen then AutoMarkerDB.started_queen = false end
  if not AutoMarkerDB.started_medivh then AutoMarkerDB.started_medivh = false end
  if not AutoMarkerDB.checkCoreHounds then AutoMarkerDB.checkCoreHounds = false end
  if not AutoMarkerDB.checkSoliders then AutoMarkerDB.checkSoliders = false end
  if not AutoMarkerDB.checkKeepers then AutoMarkerDB.checkKeepers = false end
  if not AutoMarkerDB.checkProtectors then AutoMarkerDB.checkProtectors = false end
  if not AutoMarkerDB.checkTemporaryMobs then AutoMarkerDB.checkTemporaryMobs = false end

  -- clear unit cache
  -- TODO: do this on logout instead?
  for guid, _ in pairs(AutoMarkerDB.unitCache) do
    if not UnitExists(guid) then
      AutoMarkerDB.unitCache[guid] = nil
    end
  end

  -- init settings (keeps `false` values, which `x or default` used to reset)
  do
    local s = {}
    local old = AutoMarkerDB.settings or (type(settings) == "table" and settings) or {}
    for k,v in pairs(defaultSettings) do
      if old[k] == nil then s[k] = v else s[k] = old[k] end
    end
    AutoMarkerDB.settings = s
  end

  -- migrate old customs (very old global variable)
  if customNpcsToMark and next(customNpcsToMark) then
    for raid_name,packs in pairs(customNpcsToMark) do
      if not AutoMarkerDB.customNpcsToMark[raid_name] then AutoMarkerDB.customNpcsToMark[raid_name] = {} end
      for pack_name,pack in pairs(packs) do
        AutoMarkerDB.customNpcsToMark[raid_name][pack_name] = customNpcsToMark[raid_name][pack_name]
      end
    end
  end

  -- global configuration file, shared by every account and character
  local filePacks, fileNames, filePos, fileLegacy, fileMaps = LoadGlobalConfig()
  if filePacks then
    -- first run of this account with the global file: keep its own customs that the file doesn't know
    if not AutoMarkerDB.migratedToGlobal then
      for zone, packs in pairs(AutoMarkerDB.customNpcsToMark) do
        for packName, pack in pairs(packs) do
          filePacks[zone] = filePacks[zone] or {}
          if not filePacks[zone][packName] then
            filePacks[zone][packName] = pack
            save_dirty = true
          end
        end
      end
    end
    -- empty file: start from NPCList.lua
    if not next(filePacks) and PopulateFromDefaults(filePacks) > 0 then save_dirty = true end
    AutoMarkerDB.customNpcsToMark = filePacks
    for g, n in pairs(fileNames) do npcNames[g] = n end
    for g, p in pairs(filePos) do npcPos[g] = p end
    for id, m in pairs(fileMaps or {}) do mapInfo[id] = m end
    if fileLegacy then save_dirty = true end -- convert an older file to the current layout right away
  elseif has_file_io then
    -- no file yet: create it from NPCList.lua plus this account's own custom packs
    PopulateFromDefaults(AutoMarkerDB.customNpcsToMark)
    save_dirty = true
  end
  if has_file_io then AutoMarkerDB.migratedToGlobal = true end

  -- load defaults
  for raid_name,packs in pairs(defaultNpcsToMark) do
    if not currentNpcsToMark[raid_name] then currentNpcsToMark[raid_name] = {} end
    for pack_name,pack in pairs(packs) do
      if not currentNpcsToMark[raid_name][pack_name] then
        currentNpcsToMark[raid_name][pack_name] = defaultNpcsToMark[raid_name][pack_name]
      end
    end
  end
  -- over-write with customs
  for raid_name,packs in pairs(AutoMarkerDB.customNpcsToMark) do
    if not currentNpcsToMark[raid_name] then currentNpcsToMark[raid_name] = {} end
    for pack_name,pack in pairs(packs) do
      currentNpcsToMark[raid_name][pack_name] = AutoMarkerDB.customNpcsToMark[raid_name][pack_name]
    end
  end

  auto_print(c(L["AutoMarker loaded!"],color.yellow)..L[" Type "]..c("/am",color.green)..L[" to see commands."]..
    (has_file_io and "" or c(L[" (no ExportFile: settings are saved per account only)"], color.grey)))
end

local function ClearTemps()
  -- print("clearin")
  for _,config in pairs(temporary_mobs) do
    for _,guid in pairs(config.queue) do
      if UnitAffectingCombat(guid) then -- will this work or is it too early? does it need to work?
        config.queue = {}
        break
      end
    end
  end

  AutoMarkerDB.temp_values = {
    buru_egg_queue = {},
    corehounds = {},
    soldiers = {},
    keepers = {},
    protectors = {},
    solnius_adds = {},
    solnius_adds = { count = 0 },
  }

  AutoMarkerDB.started_solnius = false
  AutoMarkerDB.started_queen = false
  AutoMarkerDB.started_medivh = false
  -- AutoMarkerDB.checkCoreHounds = false
  -- AutoMarkerDB.checkSoliders = false
  -- AutoMarkerDB.checkKeepers = false
  -- AutoMarkerDB.checkProtectors = false
  -- AutoMarkerDB.checkTemporaryMobs = false
end

function autoMarker:UPDATE_MOUSEOVER_UNIT()
  OnMouseover()
  local _,guid = UnitExists("mouseover")
  if not guid then return end
  if AutoMarkerDB.settings.debug then
    auto_print(guid .. " " .. (UnitName(guid) or "?"))
  end
  if sweep_on and ssub(guid, 1, 5) == "0xF13" and UnitCanAttack("player", guid) then
    local zone = GetRealZoneText()
    local pack = currentNpcsToMark[zone] and currentNpcsToMark[zone][sweepPackName]
    if not (pack and pack[guid]) then
      AddToPack(guid,true,sweepPackName)
    end
  end
end

function autoMarker:CHAT_MSG_MONSTER_YELL(msg,from)
  if from == L["Echo of Medivh"] and sfind(msg, L["^My patience has come to an end."]) then
    AutoMarkerDB.started_medivh = true
  end
  if from == L["Queen"] then
    AutoMarkerDB.started_queen = true
  end
end

function autoMarker:RAW_COMBATLOG(event, msg)
  if AutoMarkerDB.started_medivh and
  (event == "CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE" or
   event == "CHAT_MSG_SPELL_PERIODIC_FRIENDLYPLAYER_DAMAGE" or
   event == "CHAT_MSG_SPELL_PERIODIC_PARTY_DAMAGE") then
    if sfind(msg, L["Shadow damage from (.-)'s Corruption of Medivh%.$"]) then
      autoMarker.corruption_damage = GetTime()
    end
    return
  end

  if AutoMarkerDB.started_queen and
  (event == "CHAT_MSG_AURA_GONE_SELF" or
   event == "CHAT_MSG_AURA_GONE_PARTY" or
   event == "CHAT_MSG_AURA_GONE_OTHER") then
    local _,_,unit = sfind(msg, L["Dark Subservience fades from (.-).$"])
    if unit then
      -- clear mark from that unit
      MarkUnit(unit,autoMarker.old_queen_mark or 0)
      autoMarker.old_queen_mark = nil
    end
    return
  end
end

--[[
/run AutoMarkerFrame:CHAT_MSG_MONSTER_YELL("More uninvited guests? I have no time for intrusions.","Echo of Medivh")
/run AutoMarkerFrame:RAW_COMBATLOG("CHAT_MSG_SPELL_PERIODIC_SELF_DAMAGE","You take 800 Shadow damage from player's Corruption of Medivh.")
/run AutoMarkerFrame:UNIT_CASTEVENT("player","player","CAST", 52674,0)

/run AutoMarkerFrame:CHAT_MSG_MONSTER_YELL("","Queen")
/run AutoMarkerFrame:UNIT_CASTEVENT("player","player","CAST", 41647,0)
/run AutoMarkerFrame:RAW_COMBATLOG("CHAT_MSG_AURA_GONE_SELF","Dark Subservience fades from player.")

--]]

-- buru egg death tracking now handled via UNIT_FLAGS

-- todo, separate this into zones and load only each zone
local patterns = {
  flamewaker_healer           = "^0xF130002D8F27",
  flamewaker_elite            = "^0xF130002D9027",
  gnarlmoon_owl_blue          = "^0xF13000EA5E27",
  gnarlmoon_owl_red           = "^0xF13000EA5D27",
  incantagos_seekers          = "^0xF13000EA5527",
  incantagos_affinity_mana    = "^0xF13000EA4E27",
  incantagos_affinity_black   = "^0xF13000EA4F27",
  incantagos_affinity_blue    = "^0xF13000EA5027",
  incantagos_affinity_green   = "^0xF13000EA5127",
  incantagos_affinity_red     = "^0xF13000EA5227",
  incantagos_affinity_crystal = "^0xF13000EA5327",
  sanv_riftstalker            = "^0xF13000EA4827",
  sanv_netherwalker           = "^0xF13000EA4A27",
  rupturan_fragment           = "^0xF13000EA3527",
  rupturan_exile              = "^0xF13000EA3807",
  mephistroth_doomguards      = "^0xF130016C9827",
  onyxia_hatchers             = "^0xF13000C3E027",
  chieftain_illuminators      = "^0xF13000F5DE27",
  chieftain_shadowkeepers     = "^0xF13000F5DF27",
  rupturan_dirt_mound         = "^0xF13000EA3427",
  naxx_plague_gargs           = "^0xF130003F2801",
  buru_eggs                   = "^0xF130003C9A27",
  ursol_corrupters            = "^0xF13000732827",
  rotgrowl_kodiak             = "^0xF13000F5D927",
}

-- start with skull unless reversed
function autoMarker:ApplyNextMark(guid,reverse)
  local start,stop,step = 8,1,-1
  if reverse then start,stop,step = 1,8,1 end

  for i=start,stop,step do
    -- the "mark" unitid isn't performant, avoid using multiple times
    local _,m = UnitExists("mark"..i)
    if not (UnitExists(m) and not UnitIsDead(m)) then
      -- if mark isn't active, use it
      MarkUnit(guid,i)
      break
    end
  end
end

local function TryPatterns(guid,...)
  for i = 1, arg.n do
    if sfind(guid, arg[i]) then return true end
  end
end

-- nampower _GUID event wrappers
function autoMarker:UNIT_MODEL_CHANGED_GUID(guid)
  self:UNIT_MODEL_CHANGED(guid)
end

function autoMarker:UNIT_FLAGS_GUID(guid)
  self:UNIT_FLAGS(guid)
end

-- Workhorse, detects when a unit model is loaded in the client.
-- Units can technically be checked for exsitence before this but this event lets us do it on the fly.
function autoMarker:UNIT_MODEL_CHANGED(guid,debug_id,debug_name)
  -- Certain mobs are script spawned so their IDs need to be fetched

  local name = UnitName(guid)
  local zone = GetRealZoneText()

  -- store found guid, this is only for `/am markname` so far
  AutoMarkerDB.unitCache[guid] = name

  if AutoMarkerDB.settings.debug then
    _,guid = UnitExists(debug_id or guid)
    name = debug_name or UnitName(guid)
    auto_print(guid .. " " .. name)
  end

  -- player unit models change _often_, exit early if it's not a mob guid
  if ssub(guid,3,3) ~= "F" then return end -- use IsPlayer(guid) ?

  if zone == L["Tower of Karazhan"] or zone == L["The Rock of Desolation"] then

    if TryPatterns(guid,patterns.gnarlmoon_owl_blue,patterns.gnarlmoon_owl_red) then
      name = "Gnarlmoon Owl"

    elseif TryPatterns(guid,patterns.rupturan_fragment) then
      name = "Fragment of Rupturan"

    elseif TryPatterns(guid, patterns.rupturan_exile) then
      name = "Crumbling Exile"

    elseif TryPatterns(guid,patterns.rupturan_dirt_mound) then
      MarkUnit(guid,4)
      return

    elseif TryPatterns(guid, patterns.mephistroth_doomguards) then
      name = "Hellfire Doomguard"

    elseif TryPatterns(guid, patterns.incantagos_seekers) then
      name = "Manascale Ley-Seeker"
    -- mid-fight ley-seekers have a different guid base of 0xF14

    -- incantagos affinity - detect by guid pattern
    elseif not GetRaidTargetIndex(guid) and TryPatterns(guid,
        patterns.incantagos_affinity_mana, patterns.incantagos_affinity_black,
        patterns.incantagos_affinity_blue, patterns.incantagos_affinity_green,
        patterns.incantagos_affinity_red, patterns.incantagos_affinity_crystal) then
      MarkUnit(guid,8)
      return

    -- sanv stalkers
    elseif not GetRaidTargetIndex(guid) and TryPatterns(guid, patterns.sanv_riftstalker) then
      self:ApplyNextMark(guid) -- might have similar issue to owls if 2 spawn at once
      return
    elseif not GetRaidTargetIndex(guid) and TryPatterns(guid, patterns.sanv_netherwalker) then
      self:ApplyNextMark(guid,true) -- reverse, to hopefully leave skull/x for stalkers
      return
    end

  elseif zone == L["Timbermaw Hold"] then
    if TryPatterns(guid, patterns.chieftain_illuminators) then
      name = "Withermaw Illuminator"
    elseif TryPatterns(guid, patterns.ursol_corrupters) then
      name = "Withermaw Corrupter"
    elseif TryPatterns(guid, patterns.chieftain_shadowkeepers) then
      name = "Withermaw Shadowkeeper"
    elseif TryPatterns(guid, patterns.rotgrowl_kodiak) then
      name = "Kodiak"
    end

  elseif zone == L["Onyxia's Lair"] then
    if TryPatterns(guid, patterns.onyxia_hatchers) then
      name = "Onyxian Hatcher"
    end

  elseif zone == L["Naxxramas"] or zone == L["The Upper Necropolis"] then
    if name == L["Naxxramas Follower"] or name == L["Naxxramas Worshipper"] then
      name = "Faerlina Add"
    elseif name == L["Soldier of the Frozen Wastes"] then
      AutoMarkerDB.temp_values.soldiers[guid] = true
      AutoMarkerDB.checkSoliders = true
      return
    end
    -- ignore patrol garg
    if TryPatterns(guid,patterns.naxx_plague_gargs) and guid ~= "0xF130003F2801581E" then
      -- register for unit flag changes here, mark on flag change for these gargs
    end

  elseif zone == L["Blackrock Depths"] or zone == L["The Lyceum"] then
    if name == L["Shadowforge Flame Keeper"] then
      AutoMarkerDB.temp_values.keepers[guid] = true
      AutoMarkerDB.checkKeepers = true
      return
    end

  elseif zone == L["Dire Maul"] or zone == L["Capital Gardens"] then
    if name == L["Ironbark Protector"] then
      AutoMarkerDB.temp_values.protectors[guid] = true
      AutoMarkerDB.checkProtectors = true
      return
    end

  elseif zone == L["Ahn'Qiraj"] then
    -- fangkriss adds
    if name == L["Spawn of Fankriss"] and not GetRaidTargetIndex(guid) then
      self:ApplyNextMark(guid)
      return
    end

  elseif zone == L["Ruins of Ahn'Qiraj"] and TryPatterns(guid, patterns.buru_eggs) then
    name = "Buru Egg"
    -- buru eggs respawn throughout the fight but we want them marked still
    if AutoMarkerDB.temp_values.buru_egg_queue then
      local next_egg_mark = tremove(AutoMarkerDB.temp_values.buru_egg_queue,1)
      if next_egg_mark then
        MarkUnit(guid, next_egg_mark)
      end
      return
    end

  elseif zone == L["Emerald Sanctum"] then
    -- Solnius adds
    -- did solnius go dragonform
    if name == L["Solnius"] and UnitAffectingCombat(guid) then
      -- print("started")
      AutoMarkerDB.started_solnius = true
    end
    if AutoMarkerDB.started_solnius and elem(solinus_prio,name) then
      AutoMarkerDB.temp_values.solnius_adds[name] = AutoMarkerDB.temp_values.solnius_adds[name] or {}
      tinsert(AutoMarkerDB.temp_values.solnius_adds[name], guid)
      AutoMarkerDB.temp_values.solnius_adds.count = (AutoMarkerDB.temp_values.solnius_adds.count or 0) + 1

      if AutoMarkerDB.temp_values.solnius_adds.count >= 3 then
        -- check each entry by prio and assign marks
        local ix = 1
        for _,mobtype in ipairs(solinus_prio) do
          for _,guid in ipairs(AutoMarkerDB.temp_values.solnius_adds[mobtype] or {}) do
            local mark_id = 9-ix
            MarkUnit(guid,mark_id)
            ix = ix + 1
          end
        end
        ClearTemps()
      end
      return
    end

  elseif zone == L["Molten Core"] then
    if TryPatterns(guid, patterns.flamewaker_healer, patterns.flamewaker_elite) then
    -- if name == L["Flamewaker Healer"] or name == L["Flamewaker Elite"] then
      name = "Domo Add"
    elseif name == L["Core Hound"] then
      AutoMarkerDB.temp_values.corehounds[guid] = true
      AutoMarkerDB.checkCoreHounds = true
      return
    end

  elseif zone == L["Blackwing Lair"] and name == L["Lord Victor Nefarius"] then
    MarkUnit(guid,2)
    return
  end

  if temporary_mobs[name] then
    -- key by id in case you leave the area and come back, which would otherwise add the same mob twice
    temporary_mobs[name].queue[guid] = guid
    AutoMarkerDB.checkTemporaryMobs = true
    return
  end

end

-- clear solnius etc
function autoMarker:PLAYER_REGEN_ENABLED()
  -- As far as I know fd/vanish won't trigger this while the raid is still fighting.
  -- Combat ended, reset relevant model queues
  ClearTemps()
end

function autoMarker:PLAYER_ENTERING_WORLD()
  self:ZONE_CHANGED_NEW_AREA()
  ClearTemps()
end

function autoMarker:PLAYER_REGEN_DISABLED()
  -- Combat started, reset relevant model queues in case of incomplete loads
  -- ClearTemps()
end

function autoMarker:ZONE_CHANGED_NEW_AREA()
  local zone = GetRealZoneText()
  AutoMarkerDB.zone = zone
  if zone == L["Blackrock Spire"] and IsInInstance() and UnitExists("0xF13000290D104DD6") then
    UIErrorsFrame:AddMessage(L["Jed is in the instance!"],0,1,0)
  elseif zone == L["Naxxramas"] or zone == L["Ruins of Ahn'Qiraj"] then
    autoMarker:RegisterEvent(use_nampower and "UNIT_FLAGS_GUID" or "UNIT_FLAGS")
  end
end

-- scan for unit flag changes (aggro, death, etc.)
function autoMarker:UNIT_FLAGS(guid)
  if string.sub(guid, 3, 3) ~= "F" then return end -- only track mob guids

  -- naxx: gargoyle aggroed for the first time
  if UnitAffectingCombat(guid) and UnitCanAttack("player", guid) and not aggro_tracker[guid] and TryPatterns(guid, patterns.naxx_plague_gargs) then
    aggro_tracker[guid] = true
    local pack, packMobs = guidToPack(guid, GetRealZoneText())
    MarkPack(packMobs or {})
    return
  end

  -- aq20: buru egg died, store its mark for re-application on respawn
  if UnitIsDead(guid) and TryPatterns(guid, patterns.buru_eggs) then
    local mark = GetRaidTargetIndex(guid)
    if mark then
      if not AutoMarkerDB.temp_values.buru_egg_queue then AutoMarkerDB.temp_values.buru_egg_queue = {} end
      tinsert(AutoMarkerDB.temp_values.buru_egg_queue, mark)
    end
    return
  end
end

function autoMarker:CHAT_MSG_ADDON(prefix,msg,channel,sender)
  if prefix ~= sync_prefix then return end
  if channel ~= "RAID" and channel ~= "PARTY" then return end

  -- reset the delay if someone else already updated the mark
  if msg == "COREHOUND_MARKED" and sender ~= UnitName("player") then
    core_delay_elapsed = -1 -- you are no longer in control of the timing
  end
end
--------------------------------

-- /// API used by the editor (AutoMarkerGUI.lua) /// -------------------------

AutoMarkerAPI = AutoMarkerAPI or {}
local API = AutoMarkerAPI
API.raidMarks = raidMarks
API.has_file_io = has_file_io
API.file_name = "Imports\\" .. GLOBAL_FILE .. ".txt"

function API.GetZone() return GetRealZoneText() end
function API.GetName(guid) return GetMobName(guid) end
function API.GetPos(guid) return GetMobPos(guid) end
function API.GetPlayerPos() return ReadUnitPosition("player") end
-- name, type ("raid", "party", "pvp") of a map id, when it has been entered once
function API.GetMapInfo(id)
  local m = id and mapInfo[id]
  if m then return m.name, m.type end
end
function API.RecordPos(guid, unit, force) return RecordMobPos(guid, unit, force) end
function API.GetPackOf(guid, zone) return guidToPack(guid, zone or GetRealZoneText()) end
function API.GetPack(zone, pack) return currentNpcsToMark[zone] and currentNpcsToMark[zone][pack] end
function API.HasDefault(zone, pack) return (defaultNpcsToMark[zone] and defaultNpcsToMark[zone][pack]) and true or false end
-- true when the pack differs from its NPCList.lua version (or has none)
function API.IsModified(zone, pack)
  local custom = AutoMarkerDB.customNpcsToMark[zone] and AutoMarkerDB.customNpcsToMark[zone][pack]
  local default = defaultNpcsToMark[zone] and defaultNpcsToMark[zone][pack]
  if not custom then return false end
  if not default then return true end
  for g, m in pairs(custom) do if default[g] ~= m then return true end end
  for g in pairs(default) do if custom[g] == nil then return true end end
  return false
end
function API.IsCustom(zone, pack) return (AutoMarkerDB.customNpcsToMark[zone] and AutoMarkerDB.customNpcsToMark[zone][pack]) and true or false end
function API.Settings() return AutoMarkerDB.settings end
function API.CanMark() return PlayerCanMark() end
function API.Print(msg) auto_print(c("AutoMarker: ", color.yellow) .. msg) end

-- default packs in route order (NPCList.lua), then the other packs alphabetically
function API.GetPackList(zone)
  local list, seen, rest = {}, {}, {}
  local packs = currentNpcsToMark[zone] or {}
  for _, p in ipairs(orderedPacks) do
    if p.instance == zone and packs[p.packName] and not seen[p.packName] then
      tinsert(list, p.packName)
      seen[p.packName] = true
    end
  end
  for name in pairs(packs) do
    if not seen[name] then tinsert(rest, name) end
  end
  tsort(rest)
  for _, name in ipairs(rest) do tinsert(list, name) end
  return list
end

function API.SetMark(zone, pack, guid, mark, apply_live)
  local t = EnsureCustomPack(zone, pack)
  t[guid] = mark
  GetMobName(guid)
  if apply_live and UnitExists(guid) and not UnitIsDead(guid) and PlayerCanMark() then
    if (GetRaidTargetIndex(guid) or 0) ~= mark then MarkUnit(guid, mark) end
  end
  MarkConfigDirty()
end

function API.RemoveMob(zone, pack, guid)
  EnsureCustomPack(zone, pack)[guid] = nil
  MarkConfigDirty()
end

-- moves the mob into `pack` (out of any other pack of the zone)
function API.AddMob(zone, pack, guid, mark)
  RemoveMobEverywhere(zone, guid, pack)
  local t = EnsureCustomPack(zone, pack)
  if mark == nil then mark = t[guid] or GetRaidTargetIndex(guid) or 0 end
  t[guid] = mark
  GetMobName(guid)
  MarkConfigDirty()
end

function API.NewPack(zone)
  local name = NewPackName(zone)
  EnsureCustomPack(zone, name)
  MarkConfigDirty()
  return name
end

function API.RenamePack(zone, old, new)
  new = string.gsub(new or "", "^%s*(.-)%s*$", "%1")
  new = string.gsub(new, "[\t\r\n]", " ")
  if new == "" or new == old then return false, L["invalid name"] end
  if API.HasDefault(zone, old) then return false, L["default packs cannot be renamed"] end
  if currentNpcsToMark[zone] and currentNpcsToMark[zone][new] then return false, L["this name is already used"] end
  local customs = AutoMarkerDB.customNpcsToMark[zone]
  if not (customs and customs[old]) then return false, L["pack not found"] end
  customs[new], customs[old] = customs[old], nil
  currentNpcsToMark[zone][new], currentNpcsToMark[zone][old] = customs[new], nil
  if last_pack_marked == old then last_pack_marked = new end
  if sweepPackName == old then sweepPackName = new end
  MarkConfigDirty()
  return true, new
end

-- default pack: back to its NPCList.lua version / custom pack: deletes it
function API.ResetPack(zone, pack)
  if AutoMarkerDB.customNpcsToMark[zone] then AutoMarkerDB.customNpcsToMark[zone][pack] = nil end
  if currentNpcsToMark[zone] then currentNpcsToMark[zone][pack] = nil end
  if defaultNpcsToMark[zone] and defaultNpcsToMark[zone][pack] then
    EnsureCustomPack(zone, pack) -- fresh copy of the default pack, kept in the file
  end
  if sweep_on and sweepPackName == pack and not (currentNpcsToMark[zone] and currentNpcsToMark[zone][pack]) then
    sweep_on = false
  end
  MarkConfigDirty()
end

function API.MarkPack(zone, pack)
  local t = API.GetPack(zone, pack)
  if t and PlayerCanMark() then
    MarkPack(t)
    last_pack_marked = pack
  end
end

function API.ClearMarks() AutoMarker_ClearMarks() end

function API.SetSweep(pack)
  sweep_on = pack and true or false
  sweepPackName = pack
  API.Print(L["Sweep mode [ "] .. (sweep_on and c(L["on"], color.green) or c(L["off"], color.red)) .. " ]" ..
    (sweep_on and (" " .. c(pack, color.orange)) or ""))
end
function API.GetSweep() return sweep_on, sweepPackName end

function API.Save() return SaveGlobalConfig() end

-- adds the NPCList.lua packs missing from the configuration
function API.PopulateFromDefaults()
  local added = PopulateFromDefaults(AutoMarkerDB.customNpcsToMark)
  for zone, packs in pairs(AutoMarkerDB.customNpcsToMark) do
    currentNpcsToMark[zone] = currentNpcsToMark[zone] or {}
    for p, t in pairs(packs) do currentNpcsToMark[zone][p] = t end
  end
  if added > 0 then MarkConfigDirty() end
  return added
end

function API.ReloadGlobal()
  local packs, names, positions, legacy, maps = LoadGlobalConfig()
  if not packs then return false end
  -- back to defaults, then apply the file
  for zone, ps in pairs(AutoMarkerDB.customNpcsToMark) do
    for p in pairs(ps) do
      if currentNpcsToMark[zone] then
        currentNpcsToMark[zone][p] = defaultNpcsToMark[zone] and defaultNpcsToMark[zone][p] or nil
      end
    end
  end
  if not next(packs) and PopulateFromDefaults(packs) > 0 then legacy = true end
  AutoMarkerDB.customNpcsToMark = packs
  for zone, ps in pairs(packs) do
    currentNpcsToMark[zone] = currentNpcsToMark[zone] or {}
    for p, t in pairs(ps) do currentNpcsToMark[zone][p] = t end
  end
  for g, n in pairs(names) do npcNames[g] = n end
  for g, p in pairs(positions) do npcPos[g] = p end
  for id, m in pairs(maps or {}) do mapInfo[id] = m end
  save_dirty = legacy and true or false
  if API.OnDataChanged then API.OnDataChanged() end
  return true
end

local function handleCommands(msg, editbox)
  local args = {}
  for word in string.gfind(msg, '%S+') do
    if word ~= "" then
      tinsert(args, word)
    end
  end

  local command, packName = args[1], args[2]
  local force_add = command == "forceadd"
  local zoneName = GetRealZoneText()
  local function getGuid()
    local _, guid = UnitExists("target")
    return guid
  end

  -- Disable sweep if another command is used after sweep is enabled
  if sweep_on then
    sweep_on = false
    auto_print(L["Sweep mode [ "] .. c(L["off"], color.red) .. " ]")
    return
  end

  if command == "enabled" then
    AutoMarkerDB.settings.enabled = not AutoMarkerDB.settings.enabled
    auto_print(L["AutoMarker is now ["] ..
        (AutoMarkerDB.settings.enabled and c(L["enabled"], color.green) or c(L["disabled"], color.red)) .. "]")
  elseif command == "set" or command == "s" then
    if not packName then
      auto_print(L["You must provide a pack name as well when using set."])
      return
    end
    currentPackName = packName
    auto_print(L["Packname set to: "] .. c(currentPackName, color.orange))
  elseif command == "get" or command == "g" then
    auto_print(L["Current packname set to: "] .. c(currentPackName or L["none"], color.orange))
    local guid = getGuid()
    if guid then
      local packName,pack = guidToPack(guid, zoneName)
      if packName then
        local mark = pack[guid]+1
        auto_print(format(L["Mob %s (%s) is %s in pack: %s"],guid,UnitName(guid),raidMarks[mark],c(packName,color.orange)))
      else
        auto_print(format(L["Mob %s (%s) is not in any pack."],guid,UnitName(guid)))
      end
    end
  elseif command == "clear" or command == "c" then
    if currentPackName then
      if AutoMarkerDB.customNpcsToMark[zoneName] and AutoMarkerDB.customNpcsToMark[zoneName][currentPackName] then
        AutoMarkerAPI.ResetPack(zoneName, currentPackName)
        auto_print(L["Mobs in "] .. currentPackName .. L[" have been cleared."])
      end
    else
      auto_print(L["A packname isn't currently set."])
    end
  elseif command == "remove" or command == "r" then
    local guid = getGuid()
    if not guid then
      auto_print(L["Must target a mob to remove it from its pack."])
      return
    end
    local packName = guidToPack(guid, zoneName)
    if not packName then
      auto_print(L["Mob not in any pack."])
      return
    end
    auto_print(L["Removing mob "] .. UnitName(guid) .. L[" from pack: "] .. c(packName, color.orange))
    AutoMarkerAPI.RemoveMob(zoneName, packName, guid)
  elseif command == "add" or command == "a" or force_add then
    local guid = getGuid()
    local success, err = AddToPack(guid, force_add, packName)
    if not success then
      if err == "no_guid" then
        auto_print(L["You must target a mob."])
      elseif err == "no_pack_name" then
        auto_print(L["You must provide a pack name to add the mob to."])
      elseif err == "mob_in_pack" then
        auto_print(L["The mob is already in a pack. Use "] .. c("/am forceadd", color.yellow) .. L[" to override."])
      end
    end
  elseif command == "sweep" then
    local targetPackName = packName or currentPackName
    if not targetPackName then
      auto_print(L["Provide the pack name to this command as well or set one using "] .. c("/am set", color.yellow))
      return
    end
    sweep_on = true
    sweepPackName = targetPackName
    auto_print(L["Sweep mode [ "] .. c(L["on"], color.green) .. L[" ] sweep your mouse over enemies to add them to pack: "] .. c(sweepPackName, color
        .orange))
  elseif command == "clearmarks" then
    AutoMarker_ClearMarks()
  elseif command == "next" then
    AutoMarker_MarkNextGroup()
  elseif command == "mark" then
    AutoMarker_MarkGroup()
  elseif command == "markname" then
    if not packName then
      -- no name given, try to mark by target's guid pattern
      local _, guid = UnitExists("target")
      if guid then
        local guidPattern = ssub(guid, 1, 12)
        auto_print("target guid: " .. guid .. " | pattern: " .. guidPattern .. " | cache size: " .. getn(AutoMarkerDB.unitCache))
        AutoMarker_MarkGuidPattern(guidPattern)
      else
        auto_print(L["You must provide a name as well when using markname."])
      end
      return
    end
    tremove(args,1)
    AutoMarker_MarkName(table.concat(args, " "))
  elseif command == "debug" then
    AutoMarkerDB.settings.debug = not AutoMarkerDB.settings.debug
    auto_print(L["Debug mode set to: "] .. (AutoMarkerDB.settings.debug and c(L["on"], color.green) or c(L["off"], color.red)))
  elseif command == "ui" or command == "gui" or command == "edit" then
    AutoMarker_ToggleGUI()
  elseif command == "setpos" then
    local guid = getGuid()
    if guid and API.RecordPos(guid, "target", true) then
      local map, x, y = API.GetPos(guid)
      auto_print(format(L["Position of %s: map %d, x %s, y %s"], UnitName(guid) or guid, map, x, y))
    else
      auto_print(L["Unable to read the position of the target."])
    end
  elseif command == "populate" then
    auto_print(format(L["%d default packs added to the configuration."], API.PopulateFromDefaults()))
  elseif command == "minimap" then
    AutoMarker_ToggleMinimapButton()
  elseif command == "autoadd" then
    AutoMarkerDB.settings.autoAdd = not AutoMarkerDB.settings.autoAdd
    auto_print(L["Auto-add unknown raid mobs: "] .. (AutoMarkerDB.settings.autoAdd and c(L["on"], color.green) or c(L["off"], color.red)))
  elseif command == "autoradius" then
    local r = tonumber(packName)
    if r and r >= 0 then AutoMarkerDB.settings.autoAddRadius = r end
    auto_print(L["Unknown mobs grouping radius: "] .. c(AutoMarkerDB.settings.autoAddRadius .. L[" yd"], color.orange) ..
      (has_unitxp and "" or c(L[" (UnitXP missing: target only)"], color.grey)))
  elseif command == "save" then
    if SaveGlobalConfig() then auto_print(L["Settings saved to "] .. "Imports\\" .. GLOBAL_FILE .. ".txt") end
  elseif command == "reload" then
    if AutoMarkerAPI.ReloadGlobal() then
      auto_print(L["Settings reloaded from "] .. "Imports\\" .. GLOBAL_FILE .. ".txt")
    else
      auto_print("Imports\\" .. GLOBAL_FILE .. ".txt" .. L[" not found."])
    end
  else
      auto_print(L["Commands:"])
      auto_print("/am " .. c("e", color.green) .. L["nable - enabled or disable addon."])
      auto_print("/am " .. c("s", color.green) .. L["et <packname> - Set the current pack name."])
      auto_print("/am " .. c("g", color.green) .. L["et - Get the current pack name and information about the targeted mob."])
      auto_print("/am " .. c("c", color.green) .. L["lear - Clear all mobs in the current pack."])
      auto_print("/am " .. c("sweep", color.green) ..L[" [packname] - Toggle sweep mode to add mobs to a specified pack. If no pack name is provided, use the current pack name."])
      auto_print("/am " .. c("a", color.green) ..L["dd [packname] - Add the targeted mob to a specified pack. If no pack name is provided, use the current pack name."])
      auto_print("/am " .. c("r", color.green) .. L["emove - Remove the targeted mob from its current pack."])
      auto_print(L["/am clearmarks - Remove all active marks."])
      auto_print(L["/am next - Mark next pack."])
      auto_print(L["/am mark - Mark pack of current target or mouseover."])
      auto_print(L["/am markname - Mark all units of a given name."])

      auto_print(L["/am debug - Toggle debug mode."])
      auto_print("/am " .. c("ui", color.green) .. L[" - Pack editor (marks of the target's pack)."])
      auto_print("/am " .. c("setpos", color.green) .. L[" - Record (again) the position of the target."])
      auto_print("/am " .. c("populate", color.green) .. L[" - Add the NPCList.lua packs missing from the configuration file."])
      auto_print("/am " .. c("minimap", color.green) .. L[" - Show / hide the minimap button."])
      auto_print("/am " .. c("autoadd", color.green) .. L[" - Toggle auto-adding (UNMARKED) of unknown mobs targeted in a raid."])
      auto_print("/am " .. c("autoradius", color.green) .. L[" <yd> - Radius to group unknown mobs around the target (0 = target only)."])
      auto_print("/am " .. c("save", color.green) .. " / " .. c("reload", color.green) .. L[" - Write / read back "] .. "Imports\\" .. GLOBAL_FILE .. ".txt" .. L[" (global settings)."])
  end
end

SLASH_AUTOMARKER1 = "/automarker";
SLASH_AUTOMARKER2 = "/am";
SlashCmdList["AUTOMARKER"] = handleCommands
