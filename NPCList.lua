local L = AutoMarkerLocale

local SKULL    = 8
local CROSS    = 7
local SQUARE   = 6
local MOON     = 5
local TRIANGLE = 4
local DIAMOND  = 3
local CIRCLE   = 2
local STAR     = 1
local UNMARKED = 0

defaultNpcsToMark = {}
orderedPacks = {}

--[[

  Some ids such as anub adds, raz adds, faerlina adds, and buru adds are interesting and special.
  Special from each other in fact, each boss has a different behavior in how id's are consistent or not.

  When buru eggs die during the fight the id counter increases multiple times. Shortly after death a spawner is created for them which is one id higher,
  and when the egg spawns back in it will be one id higher than the spawner. If multiple eggs die at once this id increase is likely expounded
  and somewhat unpredictable.
  A mechanism which detects the order of deaths for marked eggs and re-applies marks in order of final respawn accounts for this.

  Anub'rekhan's adds are always fresh ids and not consistent each instance start. When fight resets they will be fresh yet again.
  A mechanism which detects 2 of his adds respawning is in effect.

  Raz has adds which have a consistent mark when the instance starts, but every time the fight resets the adds are all respawned with new ids
  one at a time in a clockwise order.
  A mechanism which detects 4 of his adds respawning is in effect.

  Skeram spawns clones when he does his 3-way split but his own id never changes.
  A mechanism which detects 3 of his adds respawning is in effect. Since they all share the same name.

  Arlokk doesn't have adds to mark exactly, but she does disappear in the fight.
  The mechanism to detect 1 add respawning is used to remark her.

  Faerlina adds which aren't dead will not respawn and not gain new ids if the fight resets, they simply run back to their start positions,
  however dead adds will gain new ids.
  A mechanism like the buru egg one could work to update them, tracking order of mark deaths, assuming they respawn while the marker isn't released.
  **If** there's any consistency with their new id's a composite approach can be used.
  The queue for if we res in room, or detecting the add id's when we run back to her and using the fact that new id's are higher, we can re-mark
  based on identifying what adds are missing marks and then comparing their death order vs sorted ids.
  Alternatively we can just do a sweeping re-mark every time we see a new one, though the marks won't stay consistent.

--]]


--[[
  Entry layout (same as Imports\AutoMarker_Config.txt):
    ["guid"] = { mark = SKULL, name = "Mob name", map = 0, x = 0, y = 0 },
  * mark: SKULL, CROSS, SQUARE, MOON, TRIANGLE, DIAMOND, CIRCLE, STAR or UNMARKED
  * name: display name used by the pack editor
  * map / x / y: spawn position (Map.dbc id, world coordinates in yards), 0 = unknown.
    Unknown positions are recorded in game the first time the mob is targeted (saved in the config file).
  The short layout ["guid"] = SKULL, is still accepted.
--]]

-- guid -> { name =, map =, x =, y = }, used by the pack editor
AutoMarkerDefaultNpcs = {}

-- Function to add entries while maintaining order
function addToDefaultNpcsToMark(instance, packName, npcs)
  if not defaultNpcsToMark[instance] then
    defaultNpcsToMark[instance] = {}
  end
  local marks = {}
  for guid, info in pairs(npcs) do
    if type(info) == "table" then
      marks[guid] = info.mark or UNMARKED
      local data = AutoMarkerDefaultNpcs[guid] or {}
      if info.name and info.name ~= "" then data.name = info.name end
      if (tonumber(info.x) or 0) ~= 0 or (tonumber(info.y) or 0) ~= 0 then
        data.map, data.x, data.y = tonumber(info.map) or 0, info.x, info.y
      end
      AutoMarkerDefaultNpcs[guid] = data
    else
      marks[guid] = info
    end
  end
  defaultNpcsToMark[instance][packName] = marks
  table.insert(orderedPacks, {instance = instance, packName = packName})
end

addToDefaultNpcsToMark("Orgrimmar", "org_dummies", {
  ["0xF13000C55326FDD0"] = { mark = SKULL, name = "", map = 0, x = 0, y = 0 },
  ["0xF13000C55226FDCE"] = { mark = SQUARE, name = "", map = 0, x = 0, y = 0 },
  ["0xF13000C55426FE5A"] = { mark = CROSS, name = "", map = 0, x = 0, y = 0 },
})

--/////////////// Naxxramas ///////////////

defaultNpcsToMark[L["Naxxramas"]] = {}

--/////////////// SPIDER ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "spider_entrance_patrol", {
  ["0xF130003E69269C39"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C38"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C37"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C36"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C35"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C34"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C33"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C32"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C05"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C0F"] = { mark = STAR, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_entrance_right", {
  ["0xF130003E680158F6"] = { mark = SKULL, name = "Venom Stalker", map = 0, x = 0, y = 0 },
  ["0xF130003E6601590E"] = { mark = CROSS, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E6601590F"] = { mark = SQUARE, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E670158F4"] = { mark = MOON, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E670158F5"] = { mark = TRIANGLE, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E670158F3"] = { mark = DIAMOND, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_entrance_left", {
  ["0xF130003E680158F7"] = { mark = SKULL, name = "Venom Stalker", map = 0, x = 0, y = 0 },
  ["0xF130003E66015911"] = { mark = CROSS, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E66015910"] = { mark = SQUARE, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E670158F9"] = { mark = MOON, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E670158FA"] = { mark = TRIANGLE, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E670158F8"] = { mark = DIAMOND, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_anubrekhan_hallway", {
  ["0xF130003E68015917"] = { mark = SKULL, name = "Venom Stalker", map = 0, x = 0, y = 0 },
  ["0xF130003E66015912"] = { mark = CROSS, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E66015913"] = { mark = SQUARE, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E67015914"] = { mark = MOON, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E67015915"] = { mark = TRIANGLE, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E67015916"] = { mark = DIAMOND, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_anubrekhan", {
  ["0xF130003E5401591A"] = { mark = SKULL, name = "Anub'Rekhan", map = 0, x = 0, y = 0 },
  ["0xF1300040BD04B2DF"] = { mark = CROSS, name = "Crypt Guard", map = 0, x = 0, y = 0 },
  ["0xF1300040BD04B2DE"] = { mark = SQUARE, name = "Crypt Guard", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_central_right", {
  ["0xF130003E6A0159DF"] = { mark = SKULL, name = "Crypt Reaver", map = 0, x = 0, y = 0 },
  ["0xF130003E67269C2D"] = { mark = CROSS, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E67269C2C"] = { mark = SQUARE, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E67269C2B"] = { mark = TRIANGLE, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E67269C2A"] = { mark = DIAMOND, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E670159F3"] = { mark = MOON, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
  ["0xF130003E670159F4"] = { mark = CIRCLE, name = "Carrion Spinner", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_central_patrol", {
  ["0xF130003E69269C0B"] = { mark = STAR, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C0C"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C13"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C12"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C11"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C10"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C0E"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69269C0D"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_necro_1", {
  ["0xF130004045015A20"] = { mark = SKULL, name = "Necro Stalker", map = 0, x = 0, y = 0 },
  ["0xF130004045015A1F"] = { mark = CROSS, name = "Necro Stalker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_necro_2", {
  ["0xF130004045269C25"] = { mark = SKULL, name = "Necro Stalker", map = 0, x = 0, y = 0 },
  ["0xF130004045269C24"] = { mark = CROSS, name = "Necro Stalker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_patrol", {
  ["0xF130003E69049D6A"] = { mark = STAR, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D6B"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D6C"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D69"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D68"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D67"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D66"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
  ["0xF130003E69049D65"] = { mark = UNMARKED, name = "Infectious Skitterer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_left_1", {
  ["0xF130003E6D269BFD"] = { mark = CROSS, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269C02"] = { mark = CIRCLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BFE"] = { mark = TRIANGLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269C01"] = { mark = MOON, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BFC"] = { mark = STAR, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BFB"] = { mark = SQUARE, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269C00"] = { mark = DIAMOND, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BFF"] = { mark = SKULL, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_left_2", {
  ["0xF130003E6D269BFA"] = { mark = MOON, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BF5"] = { mark = CIRCLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BF3"] = { mark = TRIANGLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BF7"] = { mark = DIAMOND, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BF8"] = { mark = SQUARE, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BF9"] = { mark = STAR, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BF4"] = { mark = SKULL, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BF6"] = { mark = CROSS, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_left_3", {
  ["0xF130003E6C269BDA"] = { mark = STAR, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BD9"] = { mark = SQUARE, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BD8"] = { mark = DIAMOND, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BD7"] = { mark = SKULL, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BD6"] = { mark = CIRCLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BD5"] = { mark = CROSS, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BD4"] = { mark = MOON, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BD3"] = { mark = TRIANGLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_right_1", {
  ["0xF130003E6D269BE2"] = { mark = SQUARE, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BE1"] = { mark = DIAMOND, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BE0"] = { mark = CROSS, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BDF"] = { mark = TRIANGLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BDE"] = { mark = MOON, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BDD"] = { mark = CIRCLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BDC"] = { mark = STAR, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BDB"] = { mark = SKULL, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_right_2", {
  ["0xF130003E6C269BE3"] = { mark = CIRCLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BE5"] = { mark = DIAMOND, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BE7"] = { mark = STAR, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BE9"] = { mark = TRIANGLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BE8"] = { mark = CROSS, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BEA"] = { mark = SQUARE, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BE6"] = { mark = MOON, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BE4"] = { mark = SKULL, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina_right_3", {
  ["0xF130003E6D269BED"] = { mark = SQUARE, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BF0"] = { mark = DIAMOND, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BF1"] = { mark = MOON, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BF2"] = { mark = STAR, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BEB"] = { mark = SKULL, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BEC"] = { mark = TRIANGLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
  ["0xF130003E6D269BEF"] = { mark = CROSS, name = "Naxxramas Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003E6C269BEE"] = { mark = CIRCLE, name = "Naxxramas Cultist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_faerlina", {
  ["0xF130003E510159B0"] = { mark = TRIANGLE, name = "Grand Widow Faerlina", map = 0, x = 0, y = 0 },
  ["0xF130004079276DE5"] = { mark = CROSS, name = "Naxxramas Follower", map = 0, x = 0, y = 0 },
  ["0xF130004079276DE6"] = { mark = SKULL, name = "Naxxramas Follower", map = 0, x = 0, y = 0 },
  ["0xF13000407A276DE7"] = { mark = CIRCLE, name = "Naxxramas Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000407A276DE8"] = { mark = SQUARE, name = "Naxxramas Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000407A276DE9"] = { mark = MOON, name = "Naxxramas Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000407A276DEA"] = { mark = STAR, name = "Naxxramas Worshipper", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_final", {
  ["0xF130003E66269C1A"] = { mark = CROSS, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E66269C18"] = { mark = TRIANGLE, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E66015A2F"] = { mark = SQUARE, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E66269C19"] = { mark = MOON, name = "Dread Creeper", map = 0, x = 0, y = 0 },
  ["0xF130003E6B01F3EE"] = { mark = SKULL, name = "Tomb Horror", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"],"spider_ring_ghouls_1", {
  ["0xF13000403F269C03"] = { mark = SKULL, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F269C04"] = { mark = SQUARE, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F269C06"] = { mark = CROSS, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"],"spider_ring_ghouls_2", {
  ["0xF13000403F269BAE"] = { mark = SKULL, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F269BAD"] = { mark = SQUARE, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F269BAC"] = { mark = CROSS, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_pats", {
  -- addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_acolyte_1", {
    ["0xF130003FF0015AD7"] = { mark = CROSS, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
    ["0xF130003FF0015AD8"] = { mark = SKULL, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  -- })
  -- ["spider_ring_spiders1"] = {
    ["0xF130004045269C07"] = { mark = CIRCLE, name = "Necro Stalker", map = 0, x = 0, y = 0 },
    ["0xF130004045269C08"] = { mark = UNMARKED, name = "Necro Stalker", map = 0, x = 0, y = 0 },
  -- },
  -- ["spider_ring_spiders2"] = {
    ["0xF130004045269C09"] = { mark = UNMARKED, name = "Necro Stalker", map = 0, x = 0, y = 0 },
    ["0xF130004045269C0A"] = { mark = STAR, name = "Necro Stalker", map = 0, x = 0, y = 0 },
  -- },
  -- ["garg1"] = {
    ["0xF13000403E269C44"] = { mark = UNMARKED, name = "Plagued Gargoyle", map = 0, x = 0, y = 0 },
    ["0xF13000403E269C45"] = { mark = TRIANGLE, name = "Plagued Gargoyle", map = 0, x = 0, y = 0 },
  -- },
  -- ["garg2"] = {
    ["0xF13000403E269C43"] = { mark = DIAMOND, name = "Plagued Gargoyle", map = 0, x = 0, y = 0 },
    ["0xF13000403E015B18"] = { mark = UNMARKED, name = "Plagued Gargoyle", map = 0, x = 0, y = 0 },
  -- },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_acolyte_2", {
  ["0xF130003FF0015AD5"] = { mark = CROSS, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003FF0015AD6"] = { mark = SKULL, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "spider_ring_acolyte_3", {
  ["0xF130003FF0015AD4"] = { mark = SKULL, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003FF0015AD3"] = { mark = CROSS, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
})

----/////////////// MILITARY ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "military_entrance_middle", {
  ["0xF130003F1101594B"] = { mark = SKULL, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
  ["0xF130003F1101594C"] = { mark = CROSS, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_entrance_left", {
  ["0xF130003F1201594A"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1A015950"] = { mark = CROSS, name = "Risen Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1A015951"] = { mark = SQUARE, name = "Risen Deathknight", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_entrance_right", {
  ["0xF130003F12015949"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1A015953"] = { mark = CROSS, name = "Risen Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1A015952"] = { mark = SQUARE, name = "Risen Deathknight", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_entrance_patrol", {
  ["0xF130003F2401594D"] = { mark = SKULL, name = "Shade of Naxxramas", map = 0, x = 0, y = 0 },
  ["0xF130003F2501594F"] = { mark = CROSS, name = "Necro Knight", map = 0, x = 0, y = 0 },
  ["0xF130003F2501594E"] = { mark = SQUARE, name = "Necro Knight", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_1", {
  ["0xF130003F12015967"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1C015956"] = { mark = CROSS, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1E015955"] = { mark = SQUARE, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F11015954"] = { mark = MOON, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_captains", {
  ["0xF130003F11015968"] = { mark = SKULL, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
  ["0xF130003F11015969"] = { mark = CROSS, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_shade_patrol", {
  ["0xF130003F24015957"] = { mark = STAR, name = "Shade of Naxxramas", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_shades", {
  ["0xF130003F24015961"] = { mark = SKULL, name = "Shade of Naxxramas", map = 0, x = 0, y = 0 },
  ["0xF130003F24015960"] = { mark = CROSS, name = "Shade of Naxxramas", map = 0, x = 0, y = 0 },
  ["0xF130003F2501596A"] = { mark = SQUARE, name = "Necro Knight", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_constructs", {
  ["0xF130003F27015962"] = { mark = SKULL, name = "Bony Construct", map = 0, x = 0, y = 0 },
  ["0xF130003F27015963"] = { mark = CROSS, name = "Bony Construct", map = 0, x = 0, y = 0 },
  ["0xF130003F27015964"] = { mark = SQUARE, name = "Bony Construct", map = 0, x = 0, y = 0 },
  ["0xF130003F27015965"] = { mark = MOON, name = "Bony Construct", map = 0, x = 0, y = 0 },
  ["0xF130003F27015966"] = { mark = TRIANGLE, name = "Bony Construct", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_forge_smiths", {
  ["0xF130003F4101595A"] = { mark = SKULL, name = "Skeletal Smith", map = 0, x = 0, y = 0 },
  ["0xF130003F41015958"] = { mark = CROSS, name = "Skeletal Smith", map = 0, x = 0, y = 0 },
  ["0xF130003F41015959"] = { mark = SQUARE, name = "Skeletal Smith", map = 0, x = 0, y = 0 },
  ["0xF130003F4101595B"] = { mark = MOON, name = "Skeletal Smith", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_2", {
  ["0xF130003F1201595E"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1201595D"] = { mark = CROSS, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1101595C"] = { mark = SQUARE, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
  ["0xF130003F1101595F"] = { mark = MOON, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_3", {
  ["0xF130003F1201596E"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1C01596B"] = { mark = CROSS, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1D01596C"] = { mark = SQUARE, name = "Doom Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1101596D"] = { mark = MOON, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_upper_patrol", {
  ["0xF130003F12015978"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1E01597A"] = { mark = CROSS, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1E015979"] = { mark = SQUARE, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_4", {
  ["0xF130003F12015973"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F12015972"] = { mark = CROSS, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1101596F"] = { mark = SQUARE, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_5", {
  ["0xF130003F12015975"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F12015974"] = { mark = CROSS, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F11015970"] = { mark = SQUARE, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_6", {
  ["0xF130003F12015977"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F12015976"] = { mark = CROSS, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F11015971"] = { mark = SQUARE, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_static_7", {
  ["0xF130003F1201597C"] = { mark = SKULL, name = "Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1E01597B"] = { mark = CROSS, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1D01597E"] = { mark = SQUARE, name = "Doom Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1101597D"] = { mark = MOON, name = "Deathknight Captain", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_duo", {
  ["0xF130003F23269C6E"] = { mark = SKULL, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F23269C6D"] = { mark = CROSS, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_1", {
  ["0xF130003F2301597F"] = { mark = SKULL, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F1E015982"] = { mark = CROSS, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1E015981"] = { mark = SQUARE, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1E015989"] = { mark = MOON, name = "Death Touched Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_2", {
  ["0xF130003F23015980"] = { mark = SKULL, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F1C015983"] = { mark = CROSS, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1C015984"] = { mark = SQUARE, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1D015985"] = { mark = MOON, name = "Doom Touched Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_3", {
  ["0xF130003F23269C6C"] = { mark = SKULL, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F1C015988"] = { mark = CROSS, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1A015987"] = { mark = SQUARE, name = "Risen Deathknight", map = 0, x = 0, y = 0 },
  ["0xF130003F1A015986"] = { mark = MOON, name = "Risen Deathknight", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_trio", {
  ["0xF1300041DD082208"] = { mark = SKULL, name = "Death Lord", map = 0, x = 0, y = 0 },
  ["0xF130003F23015992"] = { mark = CROSS, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F23015991"] = { mark = SQUARE, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_horse_4", {
  ["0xF130003F23015993"] = { mark = SKULL, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F1C01598A"] = { mark = CROSS, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1C01598B"] = { mark = SQUARE, name = "Dark Touched Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003F1D01598C"] = { mark = MOON, name = "Doom Touched Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_razuvious", {
  ["0xF1300041A304A65F"] = { mark = DIAMOND, name = "Deathknight Understudy", map = 0, x = 0, y = 0 }, -- Deathknight Understudy, left far
  ["0xF1300041A304A660"] = { mark = STAR, name = "Deathknight Understudy", map = 0, x = 0, y = 0 }, -- Deathknight Understudy, right far
  ["0xF1300041A304A661"] = { mark = TRIANGLE, name = "Deathknight Understudy", map = 0, x = 0, y = 0 }, -- Deathknight Understudy, left close
  ["0xF1300041A304A662"] = { mark = CIRCLE, name = "Deathknight Understudy", map = 0, x = 0, y = 0 }, -- Deathknight Understudy, right close
  ["0xF130003EBD01598C"] = { mark = SKULL, name = "Instructor Razuvious", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_1", {
  ["0xF130003F4201F334"] = { mark = SKULL, name = "Unholy Axe", map = 0, x = 0, y = 0 },
  ["0xF130003F4201F335"] = { mark = CROSS, name = "Unholy Axe", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_2", {
  ["0xF130003F5801F350"] = { mark = SKULL, name = "Unholy Swords", map = 0, x = 0, y = 0 },
  ["0xF130003F4201F336"] = { mark = CROSS, name = "Unholy Axe", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_3", {
  ["0xF130003F5801F34F"] = { mark = SKULL, name = "Unholy Swords", map = 0, x = 0, y = 0 },
  ["0xF130003F4201F337"] = { mark = CROSS, name = "Unholy Axe", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_4", {
  ["0xF130003F5701F34A"] = { mark = SKULL, name = "Unholy Staff", map = 0, x = 0, y = 0 },
  ["0xF130003F4201F333"] = { mark = CROSS, name = "Unholy Axe", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_weps_5", {
  ["0xF130003F5701F34B"] = { mark = SKULL, name = "Unholy Staff", map = 0, x = 0, y = 0 },
  ["0xF130003F57269C68"] = { mark = CROSS, name = "Unholy Staff", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_gothik_horses", {
  ["0xF130003F2301599A"] = { mark = SKULL, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
  ["0xF130003F23015999"] = { mark = CROSS, name = "Deathknight Cavalier", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_gothik_shade", {
  ["0xF130003F24015996"] = { mark = SKULL, name = "Shade of Naxxramas", map = 0, x = 0, y = 0 },
  ["0xF130003F25015998"] = { mark = CROSS, name = "Necro Knight", map = 0, x = 0, y = 0 },
  ["0xF130003F25015997"] = { mark = SQUARE, name = "Necro Knight", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "gothick_ring_ghouls", {
  ["0xF13000403F015B30"] = { mark = SQUARE, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015B33"] = { mark = SKULL, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015B31"] = { mark = MOON, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015B32"] = { mark = CROSS, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "gothick_ring_horse", {
  ["0xF130004044015ADC"] = { mark = SKULL, name = "Necro Knight Guardian", map = 0, x = 0, y = 0 },
  ["0xF130004044015ADD"] = { mark = CROSS, name = "Necro Knight Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_acolyte_1", {
  ["0xF130003FF0015AD9"] = { mark = SKULL, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003FF0015ADA"] = { mark = CROSS, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130004043015ADB"] = { mark = DIAMOND, name = "Deathknight Vindicator", map = 0, x = 0, y = 0 },
  ["0xF13000403E015B42"] = { mark = TRIANGLE, name = "Plagued Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF13000403E269C6F"] = { mark = UNMARKED, name = "Plagued Gargoyle", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_acolyte_2", {
  ["0xF130003FF0015ADE"] = { mark = SKULL, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003FF0015ADF"] = { mark = CROSS, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_ghouls1", {
  ["0xF13000403F015B39"] = { mark = SKULL, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015B3A"] = { mark = MOON, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015B3B"] = { mark = SQUARE, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015B3C"] = { mark = CROSS, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_acolyte_3", {
  ["0xF130003FF0015AE0"] = { mark = SKULL, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
  ["0xF130003FF0015AE1"] = { mark = CROSS, name = "Necropolis Acolyte", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "military_ring_four_horsemen", {
  ["0xF130003EBE015AB3"] = { mark = SKULL, name = "Highlord Mograine", map = 0, x = 0, y = 0 },
  ["0xF130003EC0015AB0"] = { mark = CROSS, name = "Thane Korth'azz", map = 0, x = 0, y = 0 },
  ["0xF130003EBF015AB2"] = { mark = SQUARE, name = "Sir Zeliek", map = 0, x = 0, y = 0 },
  ["0xF130003EC1015AB1"] = { mark = MOON, name = "Lady Blaumeux", map = 0, x = 0, y = 0 },
})

----/////////////// PLAGUE ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "plague_1", {
  ["0xF130003F2801581F"] = { mark = CIRCLE, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF130003F74015811"] = { mark = SQUARE, name = "Infectious Ghoul", map = 0, x = 0, y = 0 },
  ["0xF130003F74015813"] = { mark = CROSS, name = "Infectious Ghoul", map = 0, x = 0, y = 0 },
  ["0xF130003F74015812"] = { mark = SKULL, name = "Infectious Ghoul", map = 0, x = 0, y = 0 },
  ["0xF130003F73015810"] = { mark = MOON, name = "Plague Slime", map = 0, x = 0, y = 0 },
  ["0xF130003F7301580F"] = { mark = STAR, name = "Plague Slime", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_2", {
  ["0xF130003F73015817"] = { mark = MOON, name = "Plague Slime", map = 0, x = 0, y = 0 },
  ["0xF130003F73015816"] = { mark = STAR, name = "Plague Slime", map = 0, x = 0, y = 0 },
  ["0xF130003F74015814"] = { mark = SQUARE, name = "Infectious Ghoul", map = 0, x = 0, y = 0 },
  ["0xF130003F74015815"] = { mark = CROSS, name = "Infectious Ghoul", map = 0, x = 0, y = 0 },
  ["0xF130003F74015818"] = { mark = SKULL, name = "Infectious Ghoul", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs1_pat", {
  ["0xF130003F2801581E"] = { mark = STAR, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs1", {
  ["0xF130003F2801581C"] = { mark = SKULL, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF130003F2801581D"] = { mark = CROSS, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs2", {
  ["0xF130003F28015820"] = { mark = SKULL, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF130003F28015821"] = { mark = CROSS, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_gargs3", {
  ["0xF130003F28015822"] = { mark = SKULL, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF130003F28015823"] = { mark = CROSS, name = "Stoneskin Gargoyle", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_ring_ghouls1", {
  ["0xF13000403F015C0C"] = { mark = SKULL, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015C0A"] = { mark = CROSS, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015C0D"] = { mark = SQUARE, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015C0B"] = { mark = MOON, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "plague_ring_ghouls2", {
  ["0xF13000403F015C0F"] = { mark = SKULL, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015C10"] = { mark = CROSS, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015C11"] = { mark = SQUARE, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
  ["0xF13000403F015C0E"] = { mark = MOON, name = "Plagued Ghoul", map = 0, x = 0, y = 0 },
})


----/////////////// CONSTRUCT ///////////////

addToDefaultNpcsToMark(L["Naxxramas"], "construct_entrance", {
  ["0xF130003E910158C7"] = { mark = SKULL, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158C6"] = { mark = CROSS, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158C5"] = { mark = SQUARE, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158C8"] = { mark = MOON, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_entrance_patrol", {
  ["0xF130003E920158CD"] = { mark = TRIANGLE, name = "Bile Retcher", map = 0, x = 0, y = 0 },
  ["0xF130003E920158CE"] = { mark = DIAMOND, name = "Bile Retcher", map = 0, x = 0, y = 0 },
  ["0xF130003E9D015A90"] = { mark = CIRCLE, name = "Sludge Belcher", map = 0, x = 0, y = 0 },
  ["0xF130003E9D015A91"] = { mark = STAR, name = "Sludge Belcher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_central_left", {
  ["0xF130003E920158CF"] = { mark = SKULL, name = "Bile Retcher", map = 0, x = 0, y = 0 },
  ["0xF130003E910158CA"] = { mark = CROSS, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158C9"] = { mark = SQUARE, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_central_right", {
  ["0xF130003E920158D0"] = { mark = SKULL, name = "Bile Retcher", map = 0, x = 0, y = 0 },
  ["0xF130003E910158CB"] = { mark = CROSS, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158CC"] = { mark = SQUARE, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_central", {
  ["0xF130003E910158D8"] = { mark = SKULL, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158D7"] = { mark = CROSS, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158D6"] = { mark = SQUARE, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E910158D9"] = { mark = MOON, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_patchwerk_patrol", {
  ["0xF130003E92015A93"] = { mark = SKULL, name = "Bile Retcher", map = 0, x = 0, y = 0 },
  ["0xF130003E92015A8E"] = { mark = TRIANGLE, name = "Bile Retcher", map = 0, x = 0, y = 0 },
  ["0xF130003E9D015A92"] = { mark = CIRCLE, name = "Sludge Belcher", map = 0, x = 0, y = 0 },
  ["0xF130003E92015A8F"] = { mark = STAR, name = "Bile Retcher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_1", {
  ["0xF130003E95269C46"] = { mark = SKULL, name = "Living Monstrosity", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C4B"] = { mark = MOON, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C4C"] = { mark = SQUARE, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C4D"] = { mark = CROSS, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C4E"] = { mark = DIAMOND, name = "Mad Scientist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_2", {
  ["0xF130003E95269C4F"] = { mark = SKULL, name = "Living Monstrosity", map = 0, x = 0, y = 0 },
  ["0xF130003E94015AA1"] = { mark = MOON, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94015AA0"] = { mark = SQUARE, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94015A9F"] = { mark = CROSS, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94015A9E"] = { mark = DIAMOND, name = "Mad Scientist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_patchwerk", {
  ["0xF130003E91015A96"] = { mark = SKULL, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E91015A94"] = { mark = CROSS, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E91015A97"] = { mark = SQUARE, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
  ["0xF130003E91015A95"] = { mark = MOON, name = "Patchwork Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_3", {
  ["0xF130003E95269C54"] = { mark = SKULL, name = "Living Monstrosity", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C5C"] = { mark = MOON, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C5B"] = { mark = SQUARE, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C59"] = { mark = CROSS, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C5A"] = { mark = DIAMOND, name = "Mad Scientist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_4", {
  ["0xF130003E95269C5D"] = { mark = SKULL, name = "Living Monstrosity", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C61"] = { mark = MOON, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C60"] = { mark = SQUARE, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C5F"] = { mark = CROSS, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94269C5E"] = { mark = DIAMOND, name = "Mad Scientist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_scientist_5", {
  ["0xF130003E95269C66"] = { mark = SKULL, name = "Living Monstrosity", map = 0, x = 0, y = 0 },
  ["0xF130003E94015A85"] = { mark = MOON, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94015A86"] = { mark = SQUARE, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94015A87"] = { mark = CROSS, name = "Mad Scientist", map = 0, x = 0, y = 0 },
  ["0xF130003E94015A88"] = { mark = DIAMOND, name = "Mad Scientist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_grobb_entrance", {
  ["0xF130003E990158F2"] = { mark = SKULL, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
  ["0xF130003E990158F1"] = { mark = CROSS, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_grobb_left", {
  ["0xF130003E990158EC"] = { mark = SKULL, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
  ["0xF130003E990158EB"] = { mark = CROSS, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Naxxramas"], "construct_grobb_far", {
  ["0xF130003E990158ED"] = { mark = SKULL, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
  ["0xF130003E99269D08"] = { mark = CROSS, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
  ["0xF130003E990158EE"] = { mark = SQUARE, name = "Stitched Spewer", map = 0, x = 0, y = 0 },
})

--/////////////// AQ40 ///////////////

defaultNpcsToMark[L["Ahn'Qiraj"]] = {}

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "entrance_1", {
  ["0xF130003BA0015613"] = { mark = SKULL, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
  ["0xF130003BA0015610"] = { mark = MOON, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
  ["0xF130003BA0015611"] = { mark = SQUARE, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
  ["0xF130003BA0015612"] = { mark = CROSS, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "entrance_2", {
  ["0xF130003BA001560C"] = { mark = SKULL, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
  ["0xF130003BA001560D"] = { mark = CROSS, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
  ["0xF130003BA001560F"] = { mark = MOON, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
  ["0xF130003BA001560E"] = { mark = SQUARE, name = "Anubisath Sentinel", map = 0, x = 0, y = 0 },
})
addToDefaultNpcsToMark(L["Ahn'Qiraj"], "entrance_patrols", {
  ["0xF130003B9E130799"] = { mark = STAR, name = "Obsidian Eradicator", map = 0, x = 0, y = 0 },
  ["0xF130003B9E01580A"] = { mark = TRIANGLE, name = "Obsidian Eradicator", map = 0, x = 0, y = 0 },
  ["0xF130003B9E13079A"] = { mark = DIAMOND, name = "Obsidian Eradicator", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "skeram", {
  ["0xF130003B9F01580B"] = { mark = SQUARE, name = "The Prophet Skeram", map = 0, x = 0, y = 0 },
  ["0xF130003B9F04A65A"] = { mark = CROSS, name = "Clone", map = 0, x = 0, y = 0 },
  ["0xF130003B9F04A659"] = { mark = SKULL, name = "Clone", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_1", {
  ["0xF130003B8F01562D"] = { mark = SKULL, name = "Qiraji Brainwasher", map = 0, x = 0, y = 0 },
  ["0xF130003B8101562C"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101562B"] = { mark = CROSS, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "warrior_1", {
  ["0xF130003B7E01567A"] = { mark = TRIANGLE, name = "Vekniss Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003B7E015679"] = { mark = UNMARKED, name = "Vekniss Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003B7E015678"] = { mark = UNMARKED, name = "Vekniss Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_2", {
  ["0xF130003B81015630"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101562F"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015677"] = { mark = CROSS, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8F01562E"] = { mark = SKULL, name = "Qiraji Brainwasher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_left", {
  ["0xF130003B8101563A"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8F015636"] = { mark = CROSS, name = "Qiraji Brainwasher", map = 0, x = 0, y = 0 },
  ["0xF130003B81015639"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015638"] = { mark = TRIANGLE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8F015637"] = { mark = SKULL, name = "Qiraji Brainwasher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "brainwasher_right", {
  ["0xF130003B8101563C"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8F015634"] = { mark = SKULL, name = "Qiraji Brainwasher", map = 0, x = 0, y = 0 },
  ["0xF130003B8101563D"] = { mark = TRIANGLE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101563B"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8F015635"] = { mark = CROSS, name = "Qiraji Brainwasher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "warrior_2", {
  ["0xF130003B7E049CA2"] = { mark = STAR, name = "Vekniss Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003B7E049CA4"] = { mark = UNMARKED, name = "Vekniss Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003B7E049CA3"] = { mark = UNMARKED, name = "Vekniss Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_1", {
  ["0xF130003B81015644"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015645"] = { mark = DIAMOND, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8113079F"] = { mark = CROSS, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015642"] = { mark = SKULL, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015643"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015641"] = { mark = TRIANGLE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_2", {
  ["0xF130003B81015648"] = { mark = CROSS, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015649"] = { mark = TRIANGLE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015647"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101564A"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015646"] = { mark = DIAMOND, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101564B"] = { mark = SKULL, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_3", {
  ["0xF130003B8101564E"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101564F"] = { mark = SKULL, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101564C"] = { mark = CROSS, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015650"] = { mark = DIAMOND, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101564D"] = { mark = TRIANGLE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015651"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "guardian_4", {
  ["0xF130003B8101565B"] = { mark = TRIANGLE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015657"] = { mark = CROSS, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101565A"] = { mark = DIAMOND, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015658"] = { mark = SQUARE, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B8101565C"] = { mark = MOON, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003B81015659"] = { mark = SKULL, name = "Vekniss Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "sartura", {
  ["0xF130003E70015662"] = { mark = CROSS, name = "Sartura's Royal Guard", map = 0, x = 0, y = 0 },
  ["0xF130003E70015661"] = { mark = SQUARE, name = "Sartura's Royal Guard", map = 0, x = 0, y = 0 },
  ["0xF130003E70015663"] = { mark = MOON, name = "Sartura's Royal Guard", map = 0, x = 0, y = 0 },
  ["0xF130003C9C015660"] = { mark = SKULL, name = "Battleguard Sartura", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "soldiers", {
  ["0xF130003B7D015762"] = { mark = SKULL, name = "Vekniss Soldier", map = 0, x = 0, y = 0 },
  ["0xF130003B7D01575D"] = { mark = TRIANGLE, name = "Vekniss Soldier", map = 0, x = 0, y = 0 },
  ["0xF130003B7D01575F"] = { mark = SQUARE, name = "Vekniss Soldier", map = 0, x = 0, y = 0 },
  ["0xF130003B7D015760"] = { mark = CROSS, name = "Vekniss Soldier", map = 0, x = 0, y = 0 },
  ["0xF130003B7D01575E"] = { mark = MOON, name = "Vekniss Soldier", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "scorpions", {
  ["0xF130003B88015798"] = { mark = SKULL, name = "Vekniss Hive Crawler", map = 0, x = 0, y = 0 },
  ["0xF130003B88015799"] = { mark = CROSS, name = "Vekniss Hive Crawler", map = 0, x = 0, y = 0 },
  ["0xF130003B881307A3"] = { mark = MOON, name = "Vekniss Hive Crawler", map = 0, x = 0, y = 0 },
  ["0xF130003B881307A4"] = { mark = SQUARE, name = "Vekniss Hive Crawler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "scorpions2", {
  ["0xF130003B8801578E"] = { mark = SKULL, name = "Vekniss Hive Crawler", map = 0, x = 0, y = 0 },
  ["0xF130003B8801578F"] = { mark = CROSS, name = "Vekniss Hive Crawler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "lashers", {
  ["0xF130003B830157CD"] = { mark = CIRCLE, name = "Vekniss Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003B910157BF"] = { mark = MOON, name = "Qiraji Lasher", map = 0, x = 0, y = 0 },
  ["0xF130003B910157C3"] = { mark = CROSS, name = "Qiraji Lasher", map = 0, x = 0, y = 0 },
  ["0xF130003B910157C0"] = { mark = UNMARKED, name = "Vekniss Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003B910157C1"] = { mark = UNMARKED, name = "Vekniss Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003B910157C2"] = { mark = SQUARE, name = "Qiraji Lasher", map = 0, x = 0, y = 0 },
  ["0xF130003B910157C8"] = { mark = SKULL, name = "Qiraji Lasher", map = 0, x = 0, y = 0 },
  ["0xF130003B910157BC"] = { mark = TRIANGLE, name = "Qiraji Lasher", map = 0, x = 0, y = 0 },
  ["0xF130003B830157B6"] = { mark = DIAMOND, name = "Vekniss Stinger", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "defenders", {
  ["0xF130003BAD0157CF"] = { mark = SKULL, name = "Anubisath Defender", map = 0, x = 0, y = 0 },
  ["0xF130003BAD0157D1"] = { mark = CROSS, name = "Anubisath Defender", map = 0, x = 0, y = 0 },
  ["0xF130003BAD0157D2"] = { mark = SQUARE, name = "Anubisath Defender", map = 0, x = 0, y = 0 },
  ["0xF130003BAD0157D0"] = { mark = MOON, name = "Anubisath Defender", map = 0, x = 0, y = 0 },
  ["0xF130003BAD0157D3"] = { mark = TRIANGLE, name = "Anubisath Defender", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ahn'Qiraj"], "champions", {
  ["0xF130003B940157E7"] = { mark = SQUARE, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157E5"] = { mark = DIAMOND, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157E6"] = { mark = CIRCLE, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157F9"] = { mark = CROSS, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157E4"] = { mark = MOON, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157FA"] = { mark = TRIANGLE, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157E3"] = { mark = SKULL, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
  ["0xF130003B940157DE"] = { mark = STAR, name = "Qiraji Champion", map = 0, x = 0, y = 0 },
})

--/////////////// ZG ///////////////

defaultNpcsToMark[L["Zul'Gurub"]] = {}

--/////////////// Entrance to Jindo ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "entrance_snakes_left_1", {
  ["0xF130002C6C00BFC2"] = { mark = SKULL, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFC3"] = { mark = CROSS, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
})
addToDefaultNpcsToMark(L["Zul'Gurub"], "entrance_priest_left", {
  ["0xF130002E3600BFDB"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5600BFDA"] = { mark = MOON, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_entrance_patrols", {
  ["0xF1300039E911E65A"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130002E36016542"] = { mark = DIAMOND, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF1300039E911E65D"] = { mark = STAR, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130002C5800CAEC"] = { mark = SKULL, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF1300039E911E65C"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E911E65B"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130002C57016541"] = { mark = TRIANGLE, name = "Gurubashi Headhunter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_misress_1_patrol", {
  ["0xF1300039E911E657"] = { mark = STAR, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0F6"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0F5"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E911E658"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E911E659"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C0F7"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E911E656"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C0F8"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C1A8"] = { mark = DIAMOND, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C1A9"] = { mark = CIRCLE, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_mistress_2", {
  ["0xF130003A2300C0DB"] = { mark = MOON, name = "Voodoo Slave", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0D5"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0D6"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2300C0DA"] = { mark = SKULL, name = "Voodoo Slave", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C0D8"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C0D9"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2300C0DC"] = { mark = SQUARE, name = "Voodoo Slave", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0D3"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C0D7"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "jindo_boss_pack", {
  ["0xF1300039E900C1A5"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0FA"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C1A7"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130002C7400C1F7"] = { mark = SKULL, name = "Jin'do the Hexxer", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C0FB"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C1A8"] = { mark = DIAMOND, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C1A9"] = { mark = CIRCLE, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF1300039E900C10D"] = { mark = UNMARKED, name = "Withered Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2300C1F2"] = { mark = SQUARE, name = "Voodoo Slave", map = 0, x = 0, y = 0 },
  ["0xF130003A2200C1A6"] = { mark = UNMARKED, name = "Atal'ai Mistress", map = 0, x = 0, y = 0 },
  ["0xF130003A2300C1C9"] = { mark = MOON, name = "Voodoo Slave", map = 0, x = 0, y = 0 },
})

--/////////////// Marli(Bat) ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "hill_bottom_priest", {
  ["0xF130002C6B00BFC9"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFC8"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002E3600C25A"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5800C261"] = { mark = STAR, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002C5600C259"] = { mark = CROSS, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
})

bat1= {}
bat1["bat_one_rider_1"] = {
  ["0xF13000399E00BFFB"] = { mark = STAR, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFF7"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFF9"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFF8"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFFA"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
}
bat1["bat_one_rider_2"] = {
  ["0xF130002C6800C024"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C023"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFFF"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C001"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00C025"] = { mark = TRIANGLE, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
}
bat1["bat_two_rider_1"] = {
  ["0xF130002C6800C004"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C009"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00C003"] = { mark = CIRCLE, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C007"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFFE"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00C002"] = { mark = DIAMOND, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
}
bat1["bat_headhunter_1"] = {
  ["0xF130002E3700BFF0"] = { mark = SQUARE, name = "Hakkari Witch Doctor", map = 0, x = 0, y = 0 },
  ["0xF130002C5700BFEE"] = { mark = CROSS, name = "Gurubashi Headhunter", map = 0, x = 0, y = 0 },
  ["0xF130002C5700BFEF"] = { mark = SKULL, name = "Gurubashi Headhunter", map = 0, x = 0, y = 0 },
}

local cbat = {}
for _,pack in pairs(bat1) do
  for guid,mark in pairs(pack) do
    cbat[guid] = mark
  end
end
addToDefaultNpcsToMark(L["Zul'Gurub"], "consolidated_bat_1", cbat)

bat2 = {}
bat2["bat_two_rider_rtv"] = {
  ["0xF130002C6800BFF2"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFF3"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00BFF5"] = { mark = MOON, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF13000399E00BFF6"] = { mark = SQUARE, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFF1"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
}
bat2["bat_two_rider_2"] = {
  ["0xF130002C6800BFE8"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFE7"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFE3"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFE5"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800BFE4"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00BFEA"] = { mark = CIRCLE, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF13000399E00BFE9"] = { mark = DIAMOND, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
}
bat2["bat_two_rider_3"] = {
  ["0xF130002C6800BFF4"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C022"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00C021"] = { mark = STAR, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C006"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
  ["0xF13000399E00C00F"] = { mark = TRIANGLE, name = "Gurubashi Bat Rider", map = 0, x = 0, y = 0 },
  ["0xF130002C6800C005"] = { mark = UNMARKED, name = "Bloodseeker Bat", map = 0, x = 0, y = 0 },
}
bat2["bat_headhunter_2"] = {
  ["0xF130002C5700BFED"] = { mark = SKULL, name = "Gurubashi Headhunter", map = 0, x = 0, y = 0 },
  ["0xF130002E3700BFEB"] = { mark = CROSS, name = "Hakkari Witch Doctor", map = 0, x = 0, y = 0 },
  ["0xF130002E3700BFEC"] = { mark = SQUARE, name = "Hakkari Witch Doctor", map = 0, x = 0, y = 0 },
}

local cbat = {}
for _,pack in pairs(bat2) do
  for guid,mark in pairs(pack) do
    cbat[guid] = mark
  end
end
addToDefaultNpcsToMark(L["Zul'Gurub"], "consolidated_bat_2", cbat)


--/////////////// Venoxis ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_two_axethrower", {
  ["0xF130002C5600BFD1"] = { mark = MOON, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
  ["0xF130002C5600BFD0"] = { mark = SKULL, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_priest_pat", {
  ["0xF130002C6C00C8FB"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002E3600C258"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00C8FC"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C5600C257"] = { mark = MOON, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_room", {
  ["0xF130002C5600C248"] = { mark = MOON, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFCB"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFD3"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002E3600C249"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFCC"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFD7"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFD9"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFD2"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFD6"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFCD"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C7B00C24A"] = { mark = UNMARKED, name = "Sandfury Speaker", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFD8"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00BFCA"] = { mark = UNMARKED, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_exit_snake_1", {
  ["0xF130002C6B00C250"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00C251"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6C00C252"] = { mark = SKULL, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00C24F"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "venoxis_exit_snake_2", {
  ["0xF130002C6C00BFC7"] = { mark = SKULL, name = "Razzashi Adder", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFC6"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFC5"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
  ["0xF130002C6B00BFC4"] = { mark = UNMARKED, name = "Razzashi Serpent", map = 0, x = 0, y = 0 },
})

--/////////////// Mandokir //////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "zanza_tower_zerks", {
  ["0xF130002C5800CAFA"] = { mark = TRIANGLE, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002C5800CAEB"] = { mark = DIAMOND, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002C58016565"] = { mark = CIRCLE, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002C5800C222"] = { mark = STAR, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "mandokir_entrance_and_zerk", {
  ["0xF130002E3600C278"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C280"] = { mark = UNMARKED, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C27F"] = { mark = SQUARE, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C271"] = { mark = UNMARKED, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002E3600C279"] = { mark = CROSS, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C270"] = { mark = MOON, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002C5800C229"] = { mark = STAR, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "mandokir_room", {
  ["0xF130002E3600C287"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C285"] = { mark = MOON, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00C282"] = { mark = STAR, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00C283"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00C281"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00CB5B"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00C284"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00CB88"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },

  -- to mark room easier
  ["0xF1300039E500C974"] = { mark = UNMARKED, name = "Razzashi Raptor", map = 0, x = 0, y = 0 },
  ["0xF1300039E500CB00"] = { mark = UNMARKED, name = "Razzashi Raptor", map = 0, x = 0, y = 0 },
  ["0xF1300039E500C972"] = { mark = UNMARKED, name = "Razzashi Raptor", map = 0, x = 0, y = 0 },
  ["0xF1300039E500C973"] = { mark = UNMARKED, name = "Razzashi Raptor", map = 0, x = 0, y = 0 },
  ["0xF1300039E500CAFF"] = { mark = UNMARKED, name = "Razzashi Raptor", map = 0, x = 0, y = 0 },
  ["0xF1300039E500CB01"] = { mark = UNMARKED, name = "Razzashi Raptor", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "zanaz_witchdoctor_rtv", {
  ["0xF130002C6100CAF2"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002E37016557"] = { mark = SKULL, name = "Hakkari Witch Doctor", map = 0, x = 0, y = 0 },
  ["0xF130002C6100CAF1"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C56016556"] = { mark = MOON, name = "Gurubashi Axe Thrower", map = 0, x = 0, y = 0 },
})

--/////////////// Madness /////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness1", {
  ["0xF130003B0700BFA4"] = { mark = DIAMOND, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA3"] = { mark = SKULL, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA5"] = { mark = CROSS, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130000B6200BF8D"] = { mark = UNMARKED, name = "Snake", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA0"] = { mark = CIRCLE, name = "Mad Servant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness2", {
  ["0xF130003B0700BF9F"] = { mark = DIAMOND, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA1"] = { mark = CROSS, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BF9D"] = { mark = SKULL, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BF9E"] = { mark = TRIANGLE, name = "Mad Servant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness3", {
  ["0xF130003B0700BFAA"] = { mark = CROSS, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA9"] = { mark = DIAMOND, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFAB"] = { mark = TRIANGLE, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130002C4C00BF9B"] = { mark = SKULL, name = "Hakkari Blood Priest", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "madness4", {
  ["0xF130002C4C00BF9C"] = { mark = SKULL, name = "Hakkari Blood Priest", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA8"] = { mark = DIAMOND, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA6"] = { mark = TRIANGLE, name = "Mad Servant", map = 0, x = 0, y = 0 },
  ["0xF130003B0700BFA7"] = { mark = CROSS, name = "Mad Servant", map = 0, x = 0, y = 0 },
})

--/////////////// Thekal //////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "thekal_pack", {
  ["0xF13000390700C09E"] = { mark = DIAMOND, name = "High Priest Thekal", map = 0, x = 0, y = 0 },
  ["0xF130002C5300C0A2"] = { mark = SQUARE, name = "Zealot Lor'Khan", map = 0, x = 0, y = 0 },
  ["0xF130002C5400C0A1"] = { mark = TRIANGLE, name = "Zealot Zath", map = 0, x = 0, y = 0 },

  -- to mark thekal easier
  ["0xF130002C6100C08D"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C6100C08A"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C6100C089"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C6100C08E"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C6100C08C"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C6100C08B"] = { mark = UNMARKED, name = "Zulian Tiger", map = 0, x = 0, y = 0 },
  ["0xF130002C6000C09A"] = { mark = UNMARKED, name = "Zulian Cub", map = 0, x = 0, y = 0 },
  ["0xF130002C6000C098"] = { mark = UNMARKED, name = "Zulian Cub", map = 0, x = 0, y = 0 },
  ["0xF130002C6000C97C"] = { mark = UNMARKED, name = "Zulian Cub", map = 0, x = 0, y = 0 },
  ["0xF130002C6000C97D"] = { mark = UNMARKED, name = "Zulian Cub", map = 0, x = 0, y = 0 },
  ["0xF130002C6000C288"] = { mark = UNMARKED, name = "Zulian Cub", map = 0, x = 0, y = 0 },
  ["0xF130002C6000C292"] = { mark = UNMARKED, name = "Zulian Cub", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "gaz_fish", {
  ["0xF130002C6E00C242"] = { mark = TRIANGLE, name = "Hooktooth Frenzy", map = 0, x = 0, y = 0 },
  ["0xF130002C6E00BFAD"] = { mark = CIRCLE, name = "Hooktooth Frenzy", map = 0, x = 0, y = 0 },
  ["0xF130002C6E00C8F4"] = { mark = DIAMOND, name = "Hooktooth Frenzy", map = 0, x = 0, y = 0 },
  ["0xF130002C6E00C23E"] = { mark = STAR, name = "Hooktooth Frenzy", map = 0, x = 0, y = 0 },
  ["0xF130002C6E00BFAF"] = { mark = CROSS, name = "Hooktooth Frenzy", map = 0, x = 0, y = 0 },

  -- to mark fish easier
  ["0xF130003AC300C22C"] = { mark = UNMARKED, name = "Zulian Crocolisk", map = 0, x = 0, y = 0 },
  ["0xF130003AC300C22D"] = { mark = UNMARKED, name = "Zulian Crocolisk", map = 0, x = 0, y = 0 },
  ["0xF130003AC300C22B"] = { mark = SKULL, name = "Zulian Crocolisk", map = 0, x = 0, y = 0 },
  ["0xF130003AC300C22A"] = { mark = UNMARKED, name = "Zulian Crocolisk", map = 0, x = 0, y = 0 },

})

addToDefaultNpcsToMark(L["Zul'Gurub"], "thekal_zerk_panther", {
  ["0xF130002C5801652B"] = { mark = STAR, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0A6"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0A7"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0A8"] = { mark = CIRCLE, name = "Zulian Panther", map = 0, x = 0, y = 0 },
})

--/////////////// Arlok ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_1", {
  ["0xF130002C4B00C899"] = { mark = UNMARKED, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
  ["0xF130002C4B00C8A4"] = { mark = SKULL, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
  ["0xF130002C4B00C89A"] = { mark = CROSS, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
  ["0xF130002C4B00C8A3"] = { mark = UNMARKED, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_2", {
  ["0xF130002C6500C0C2"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0C1"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C98B"] = { mark = MOON, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002C5900C98A"] = { mark = SQUARE, name = "Gurubashi Blood Drinker", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0C0"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0BF"] = { mark = SKULL, name = "Zulian Panther", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_3", {
  ["0xF130002C6500C0BD"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0BE"] = { mark = SKULL, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C4B00C0B1"] = { mark = TRIANGLE, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0BB"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C0BC"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlok_4", {
  ["0xF130002C6500C8B7"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C8B5"] = { mark = SKULL, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C8AF"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C4B00C8A5"] = { mark = DIAMOND, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
  ["0xF130002C6500C8B6"] = { mark = UNMARKED, name = "Zulian Panther", map = 0, x = 0, y = 0 },
  ["0xF130002C4B00C8A6"] = { mark = TRIANGLE, name = "Hakkari Shadow Hunter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "arlokk", {
  ["0xF1300038B3276EF0"] = { mark = CIRCLE, name = "", map = 0, x = 0, y = 0 },
})

--/////////////// Hakkar ///////////////

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_bottom", {
  ["0xF130003AC300C231"] = { mark = CROSS, name = "Zulian Crocolisk", map = 0, x = 0, y = 0 },
  ["0xF130002C5800C8C3"] = { mark = STAR, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002C5800C8C4"] = { mark = SKULL, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_sons", {
  ["0xF130002C5D00BF8A"] = { mark = DIAMOND, name = "Son of Hakkar", map = 0, x = 0, y = 0 },
  ["0xF130002C5D00BF89"] = { mark = CIRCLE, name = "Son of Hakkar", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_soulflayer_1", {
  ["0xF130002C5F00C8E0"] = { mark = MOON, name = "Soulflayer", map = 0, x = 0, y = 0 },
  ["0xF130002C5D00C8E2"] = { mark = SKULL, name = "Son of Hakkar", map = 0, x = 0, y = 0 },
  ["0xF130002C5D00C8E1"] = { mark = CROSS, name = "Son of Hakkar", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_soulflayer_2", {
  ["0xF130002C5D00C8E4"] = { mark = CROSS, name = "Son of Hakkar", map = 0, x = 0, y = 0 },
  ["0xF130002C5D00C8E5"] = { mark = SKULL, name = "Son of Hakkar", map = 0, x = 0, y = 0 },
  ["0xF130002C5F00C8E3"] = { mark = MOON, name = "Soulflayer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_large_1", {
  ["0xF130002C5F00C8D7"] = { mark = MOON, name = "Soulflayer", map = 0, x = 0, y = 0 },
  ["0xF130002C5800C204"] = { mark = UNMARKED, name = "Gurubashi Berserker", map = 0, x = 0, y = 0 },
  ["0xF130002E3600C8D6"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5C00C8D8"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
  ["0xF130002E3600C8D9"] = { mark = CROSS, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5F11E679"] = { mark = SQUARE, name = "Soulflayer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Zul'Gurub"], "hakkar_large_2", {
  ["0xF130002C5F11F381"] = { mark = SQUARE, name = "Soulflayer", map = 0, x = 0, y = 0 },
  ["0xF130002E3611F383"] = { mark = SKULL, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002E3611F384"] = { mark = CROSS, name = "Hakkari Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5F11F380"] = { mark = MOON, name = "Soulflayer", map = 0, x = 0, y = 0 },
  ["0xF130002C4C11F37E"] = { mark = UNMARKED, name = "Hakkari Blood Priest", map = 0, x = 0, y = 0 },
  ["0xF130002C5C11F382"] = { mark = UNMARKED, name = "Gurubashi Champion", map = 0, x = 0, y = 0 },
})

--/////////////// ES ///////////////

local errenius = "0xF13000ED4B2739FA"
local errenius_mark = CIRCLE

addToDefaultNpcsToMark(L["Emerald Sanctum"], "entrance", {
  ["0xF13000ED482739F2"] = { mark = SQUARE, name = "Sanctum Wyrm", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A273A45"] = { mark = MOON, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A273A43"] = { mark = TRIANGLE, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },

  -- dreamer_pack_left_1
  ["0xF13000ED462739E2"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E3"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E4"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E5"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E6"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E7"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E8"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739E9"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739EB"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },

  -- wyrmkin_pack_right_1
  ["0xF13000ED462739F1"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739F0"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739EF"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739EE"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED472739ED"] = { mark = SKULL, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED472739EA"] = { mark = CROSS, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_right_2", {
  ["0xF13000ED492739F3"] = { mark = SKULL, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED492739F4"] = { mark = CROSS, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED472739F5"] = { mark = SQUARE, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739F6"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739F7"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462739F8"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "dreamer_pack_left_2", {
  ["0xF13000ED49273A17"] = { mark = SKULL, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A16"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A15"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A14"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A12"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A10"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A0F"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A0D"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A0C"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A0B"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_left_1", {
  ["0xF13000ED47273A1C"] = { mark = SQUARE, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A273A1A"] = { mark = MOON, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },
  ["0xF13000ED49273A18"] = { mark = CROSS, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000EF1C275495"] = { mark = SKULL, name = "Sanctum Supressor", map = 0, x = 0, y = 0 },
  ["0xF13000ED47273A1E"] = { mark = STAR, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_left_2", {
  ["0xF13000ED46273A26"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A1F"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED49273A25"] = { mark = SKULL, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED49273A24"] = { mark = STAR, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A20"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A27"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED48273A19"] = { mark = CROSS, name = "Sanctum Wyrm", map = 0, x = 0, y = 0 },
  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "dreamer_pack_right_1", {
  ["0xF13000ED462754A3"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A4"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A5"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A6"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A7"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A8"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A9"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_left_3", {
  ["0xF13000ED46273A4B"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A4C"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A54"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A56"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A57"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A58"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A59"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A273A48"] = { mark = STAR, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A273A49"] = { mark = SKULL, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },
  ["0xF13000ED49273A47"] = { mark = CROSS, name = "Sanctum Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED47273A1C"] = { mark = SQUARE, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "dreamer_pack_end", {
  ["0xF13000ED47273A46"] = { mark = CROSS, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A28"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A29"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A2A"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A2B"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A2C"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A2D"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A2E"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A2F"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED46273A31"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000EF1C275497"] = { mark = SKULL, name = "Sanctum Supressor", map = 0, x = 0, y = 0 },

  [errenius] = errenius_mark, -- increase chance of spotting him early
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "wyrmkin_pack_right_3", {
  ["0xF13000ED462754A2"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED4627549E"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A0"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A1"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000ED462754A2"] = { mark = UNMARKED, name = "Sanctum Dreamer", map = 0, x = 0, y = 0 },
  ["0xF13000EF1C275499"] = { mark = SKULL, name = "Sanctum Supressor", map = 0, x = 0, y = 0 },
  ["0xF13000ED4727549C"] = { mark = STAR, name = "Sanctum Dragonkin", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A27549D"] = { mark = CROSS, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },
  ["0xF13000ED4A27549B"] = { mark = SQUARE, name = "Sanctum Scalebane", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Emerald Sanctum"], "solnius", {
  ["0xF13000ED4C2739E1"] = { mark = UNMARKED, name = "Solnius", map = 0, x = 0, y = 0 },
})

--/////////////// MC ///////////////

addToDefaultNpcsToMark(L["Molten Core"], "giants1", {
  ["0xF130002D8A00DD81"] = { mark = CROSS, name = "Molten Giant", map = 0, x = 0, y = 0 },
  ["0xF130002D8A00DD80"] = { mark = SKULL, name = "Molten Giant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "pats1", {
  ["0xF130002D9900DE21"] = { mark = MOON, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE0C"] = { mark = TRIANGLE, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE07"] = { mark = CIRCLE, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE15"] = { mark = STAR, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE13"] = { mark = CROSS, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE14"] = { mark = SQUARE, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE16"] = { mark = DIAMOND, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "giants2", {
  ["0xF130002D8A00DD8C"] = { mark = CROSS, name = "Molten Giant", map = 0, x = 0, y = 0 },
  ["0xF130002D8A00DD8D"] = { mark = SKULL, name = "Molten Giant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "lucifron", {
  ["0xF130002F5700DD1F"] = { mark = CROSS, name = "Flamewaker Protector", map = 0, x = 0, y = 0 },
  ["0xF130002F5600DD1D"] = { mark = CIRCLE, name = "Lucifron", map = 0, x = 0, y = 0 },
  ["0xF130002F5700DD1E"] = { mark = SKULL, name = "Flamewaker Protector", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "imp_surgers", {
  ["0xF130002F4500DE0A"] = { mark = DIAMOND, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE0B"] = { mark = TRIANGLE, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE08"] = { mark = SKULL, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE09"] = { mark = CROSS, name = "Lava Surger", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "giants3", {
  ["0xF130002D8A00DD83"] = { mark = CROSS, name = "Molten Giant", map = 0, x = 0, y = 0 },
  ["0xF130002D8A00DD82"] = { mark = SKULL, name = "Molten Giant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "giants4", {
  ["0xF130002D8A00DD86"] = { mark = CROSS, name = "Molten Giant", map = 0, x = 0, y = 0 },
  ["0xF130002D8B00DD87"] = { mark = SKULL, name = "Molten Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "pats2", {
  ["0xF130002D9900DE1E"] = { mark = CIRCLE, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE1A"] = { mark = TRIANGLE, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE20"] = { mark = DIAMOND, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE17"] = { mark = CROSS, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE11"] = { mark = STAR, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE19"] = { mark = SKULL, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
  ["0xF130002F4500DE10"] = { mark = MOON, name = "Lava Surger", map = 0, x = 0, y = 0 },
  ["0xF130002D9900DE18"] = { mark = SQUARE, name = "Ancient Core Hound", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "giants5", {
  ["0xF130002D8B00DD7D"] = { mark = CROSS, name = "Molten Destroyer", map = 0, x = 0, y = 0 },
  ["0xF130002D8B00DD7C"] = { mark = SKULL, name = "Molten Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "garr", {
  ["0xF130002F4300DD28"] = { mark = STAR, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD2E"] = { mark = CIRCLE, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD2C"] = { mark = SQUARE, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD34"] = { mark = DIAMOND, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD2B"] = { mark = SKULL, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD32"] = { mark = CROSS, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD33"] = { mark = MOON, name = "Firesworn", map = 0, x = 0, y = 0 },
  ["0xF130002F4300DD22"] = { mark = TRIANGLE, name = "Firesworn", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_1", {
  ["0xF130002D93016498"] = { mark = CROSS, name = "Flameguard", map = 0, x = 0, y = 0 },
  ["0xF130002F2C016497"] = { mark = CIRCLE, name = "Lava Elemental", map = 0, x = 0, y = 0 },
  ["0xF130002D92016496"] = { mark = SKULL, name = "Firewalker", map = 0, x = 0, y = 0 },
  ["0xF130002F2C016499"] = { mark = DIAMOND, name = "Lava Elemental", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_2", {
  ["0xF130002F2C016480"] = { mark = CIRCLE, name = "Lava Elemental", map = 0, x = 0, y = 0 },
  ["0xF130002F2C01647E"] = { mark = DIAMOND, name = "Lava Elemental", map = 0, x = 0, y = 0 },
  ["0xF130002D9301647F"] = { mark = CROSS, name = "Flameguard", map = 0, x = 0, y = 0 },
  ["0xF130002D9201647D"] = { mark = SKULL, name = "Firewalker", map = 0, x = 0, y = 0 },
  ["0xF130002F1800DD4F"] = { mark = STAR, name = "Baron Geddon", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_3", {
  ["0xF130002D9301649C"] = { mark = CROSS, name = "Flameguard", map = 0, x = 0, y = 0 },
  ["0xF130002D9201649A"] = { mark = SKULL, name = "Firewalker", map = 0, x = 0, y = 0 },
  ["0xF130002F4401649B"] = { mark = CIRCLE, name = "Lava Reaver", map = 0, x = 0, y = 0 },
  ["0xF130002FE800DD20"] = { mark = STAR, name = "Shazzrah", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_4", {
  ["0xF130002D9200DD92"] = { mark = SKULL, name = "Firewalker", map = 0, x = 0, y = 0 },
  ["0xF130002F4400DD93"] = { mark = CIRCLE, name = "Lava Reaver", map = 0, x = 0, y = 0 },
  ["0xF130002D9300DD94"] = { mark = CROSS, name = "Flameguard", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "baron_pack_5", {
  ["0xF130002F2C00DDD9"] = { mark = CIRCLE, name = "Lava Elemental", map = 0, x = 0, y = 0 },
  ["0xF130002D9300DDDA"] = { mark = CROSS, name = "Flameguard", map = 0, x = 0, y = 0 },
  ["0xF130002D9200DDD8"] = { mark = SKULL, name = "Firewalker", map = 0, x = 0, y = 0 },
  ["0xF130002F2C00DDDB"] = { mark = DIAMOND, name = "Lava Elemental", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "sulfuron", {
  ["0xF130002D8E00DD69"] = { mark = DIAMOND, name = "Flamewaker Priest", map = 0, x = 0, y = 0 },
  ["0xF130002D8E00DD66"] = { mark = CIRCLE, name = "Flamewaker Priest", map = 0, x = 0, y = 0 },
  ["0xF130002D8E00DD67"] = { mark = CROSS, name = "Flamewaker Priest", map = 0, x = 0, y = 0 },
  ["0xF130002F4200DD65"] = { mark = TRIANGLE, name = "Sulfuron Harbinger", map = 0, x = 0, y = 0 },
  ["0xF130002D8E00DD6A"] = { mark = SKULL, name = "Flamewaker Priest", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "golemag_shadowforge_pack", {
  ["0xF130002D9300DDC7"] = { mark = SKULL, name = "Flameguard", map = 0, x = 0, y = 0 },
  ["0xF130002F2C00DDAF"] = { mark = DIAMOND, name = "Lava Elemental", map = 0, x = 0, y = 0 },
  ["0xF130002F2C00DDC8"] = { mark = CIRCLE, name = "Lava Elemental", map = 0, x = 0, y = 0 },
  ["0xF130002D9200DDAE"] = { mark = CROSS, name = "Firewalker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "twin_golems", {
  ["0xF13000FDFC278C2C"] = { mark = CROSS, name = "Basalthar", map = 0, x = 0, y = 0 },
  ["0xF13000FDFD278C2D"] = { mark = SKULL, name = "Smoldaris", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_1", {
  ["0xF13000CBB7278CD2"] = { mark = DIAMOND, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CD3"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB8278CD4"] = { mark = CROSS, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
  ["0xF13000CBB8278CD5"] = { mark = CIRCLE, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_2", {
  ["0xF13000CBB6278CDD"] = { mark = CROSS, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CDE"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_3", {
  ["0xF13000CBB8278CDA"] = { mark = CROSS, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
  ["0xF13000CBB8278CDB"] = { mark = SKULL, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
  ["0xF13000CBB8278CDC"] = { mark = CIRCLE, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_4", {
  ["0xF13000CBB7278CDF"] = { mark = CROSS, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CE0"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_left_5", {
  ["0xF13000CBB8278CC4"] = { mark = CIRCLE, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CC1"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB8278CC3"] = { mark = DIAMOND, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CC2"] = { mark = CROSS, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_1", {
  ["0xF13000CBB6278CB8"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB8278CB7"] = { mark = DIAMOND, name = "Shadowforge Blazeweaver", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CB9"] = { mark = CROSS, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CB3"] = { mark = CIRCLE, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_2", {
  ["0xF13000CBB6278CC6"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CC5"] = { mark = CROSS, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_3", {
  ["0xF13000CBB7278CE3"] = { mark = SKULL, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
  ["0xF13000CBB7278CE2"] = { mark = CIRCLE, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
  ["0xF13000CBB7278CE1"] = { mark = CROSS, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_4", {
  ["0xF13000CBB6278CCB"] = { mark = CROSS, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CCC"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "shadowforge_right_5", {
  ["0xF13000CBB6278CC0"] = { mark = CROSS, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB6278CBF"] = { mark = SKULL, name = "Shadowforge Guardian", map = 0, x = 0, y = 0 },
  ["0xF13000CBB7278CBD"] = { mark = DIAMOND, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
  ["0xF13000CBB7278CBE"] = { mark = CIRCLE, name = "Shadowforge Hierophant", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Molten Core"], "domo", {
  ["0xF130002D90278D51"] = { mark = DIAMOND, name = "elite", map = 0, x = 0, y = 0 },
  ["0xF130002D90278D52"] = { mark = CROSS, name = "elite", map = 0, x = 0, y = 0 },
  ["0xF130002D90278D53"] = { mark = CIRCLE, name = "elite", map = 0, x = 0, y = 0 },
  ["0xF130002D90278D54"] = { mark = SKULL, name = "elite", map = 0, x = 0, y = 0 },
  ["0xF130002D8F278D55"] = { mark = TRIANGLE, name = "healer", map = 0, x = 0, y = 0 },
  ["0xF130002D8F278D56"] = { mark = SQUARE, name = "healer", map = 0, x = 0, y = 0 },
  ["0xF130002D8F278D57"] = { mark = MOON, name = "healer", map = 0, x = 0, y = 0 },
  ["0xF130002D8F278D58"] = { mark = STAR, name = "healer", map = 0, x = 0, y = 0 },
  ["0xF130002EF2278D50"] = { mark = UNMARKED, name = "domo", map = 0, x = 0, y = 0 },
})

--/////////////// AQ20 ///////////////

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "entrance", {
  ["0xF130003BEF11FB53"] = { mark = TRIANGLE, name = "Qiraji Swarmguard", map = 0, x = 0, y = 0 },
  ["0xF130003BDC0155E6"] = { mark = CIRCLE, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FAC8"] = { mark = SKULL, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "entrance_pats", {
  ["0xF130003BDF0155DA"] = { mark = STAR, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAD8"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAD7"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FADF"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAD6"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAD5"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BEF11FB4D"] = { mark = CIRCLE, name = "Qiraji Swarmguard", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FADB"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FADA"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FADE"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAD4"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDF0155DB"] = { mark = SQUARE, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BEF11FAE1"] = { mark = DIAMOND, name = "Qiraji Swarmguard", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FAE0"] = { mark = SKULL, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAD3"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BEF11FAE2"] = { mark = TRIANGLE, name = "Qiraji Swarmguard", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FADD"] = { mark = MOON, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FB4E"] = { mark = CROSS, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "entrance_pats_2", {
  ["0xF130003BDD11FAF3"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAF7"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAEF"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FAF5"] = { mark = SQUARE, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAFA"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAF4"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FAF0"] = { mark = DIAMOND, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FAF2"] = { mark = MOON, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FAF8"] = { mark = CROSS, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BF40162B5"] = { mark = TRIANGLE, name = "Kurinnaxx", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAF6"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAF1"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FAF9"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FACA"] = { mark = CIRCLE, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FAC9"] = { mark = SKULL, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FB50"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
  ["0xF130003BDF11FB4F"] = { mark = STAR, name = "Hive'Zara Stinger", map = 0, x = 0, y = 0 },
  ["0xF130003BDD11FB52"] = { mark = UNMARKED, name = "Hive'Zara Wasp", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "general_rajaxx", {
  ["0xF130003C1B11FB5A"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB71"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB57"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB5C"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB72"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1C11FC00"] = { mark = CIRCLE, name = "Major Pakkon", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB6D"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB89"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1911FBFF"] = { mark = DIAMOND, name = "Colonel Zerran", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB84"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB7D"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB6F"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB78"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB66"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB79"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB7F"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB6B"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1D11FBFD"] = { mark = CROSS, name = "Captain Drenn", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB80"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB64"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB59"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB5F"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB77"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB60"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB68"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB62"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1F11FB5D"] = { mark = SKULL, name = "Captain Qeez", map = 0, x = 0, y = 0 },
  ["0xF130003C2011FB5E"] = { mark = SQUARE, name = "Captain Tuubid", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB76"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB81"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB5B"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB61"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB58"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB63"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB69"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB6A"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB67"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1E11FC01"] = { mark = MOON, name = "Captain Xurrem", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB85"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BED0162F7"] = { mark = UNMARKED, name = "General Rajaxx", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB82"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1A11FBFE"] = { mark = TRIANGLE, name = "Major Yeggeth", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB87"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB70"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB86"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB7E"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003BF011FB6E"] = { mark = UNMARKED, name = "Swarmguard Needler", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB7A"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
  ["0xF130003C1B11FB88"] = { mark = UNMARKED, name = "Qiraji Warrior", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "buru_path", {
  ["0xF130003BE7014F7D"] = { mark = STAR, name = "Flesh Hunter", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FACC"] = { mark = CIRCLE, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FACD"] = { mark = SKULL, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BDB11FB96"] = { mark = TRIANGLE, name = "Hive'Zara Sandstalker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "buru_slimes", {
  ["0xF130003BE711FE02"] = { mark = CROSS, name = "Flesh Hunter", map = 0, x = 0, y = 0 },
  ["0xF130003BE711FB9F"] = { mark = SKULL, name = "Flesh Hunter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "buru_eggs", {
  ["0xF130003C9A276DE0"] = { mark = CIRCLE, name = "egg", map = 0, x = 0, y = 0 },
  ["0xF130003C9A276DE1"] = { mark = DIAMOND, name = "egg", map = 0, x = 0, y = 0 },
  ["0xF130003C9A276DE2"] = { mark = TRIANGLE, name = "egg", map = 0, x = 0, y = 0 },
  ["0xF130003C9A276DE3"] = { mark = MOON, name = "egg", map = 0, x = 0, y = 0 },
  ["0xF130003C9A276DE4"] = { mark = SQUARE, name = "egg", map = 0, x = 0, y = 0 },
  ["0xF130003C9A276DE5"] = { mark = STAR, name = "egg", map = 0, x = 0, y = 0 },
  ["0xF130003C0A0162F9"] = { mark = UNMARKED, name = "Buru the Gorger", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "resevoir", {
  ["0xF130003BE711FC27"] = { mark = SQUARE, name = "Flesh Hunter", map = 0, x = 0, y = 0 },
  ["0xF130003BEA11FC12"] = { mark = DIAMOND, name = "Obsidian Destroyer", map = 0, x = 0, y = 0 },
  ["0xF130003BEA0153E5"] = { mark = MOON, name = "Obsidian Destroyer", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FACE"] = { mark = SKULL, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BEA11FC39"] = { mark = TRIANGLE, name = "Obsidian Destroyer", map = 0, x = 0, y = 0 },
  ["0xF130003BDC11FACF"] = { mark = CIRCLE, name = "Qiraji Gladiator", map = 0, x = 0, y = 0 },
  ["0xF130003BE711FC2B"] = { mark = STAR, name = "Flesh Hunter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Ruins of Ahn'Qiraj"], "ossirian_room", {
  ["0xF130003BFB11FBDC"] = { mark = CROSS, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB11FBDD"] = { mark = SKULL, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB0155C3"] = { mark = SQUARE, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB11FBE0"] = { mark = TRIANGLE, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB11FBDF"] = { mark = STAR, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB11FBDB"] = { mark = DIAMOND, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB11FBDE"] = { mark = CIRCLE, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
  ["0xF130003BFB11FBE1"] = { mark = MOON, name = "Anubisath Guardian", map = 0, x = 0, y = 0 },
})

--/////////////// BWL ///////////////

addToDefaultNpcsToMark(L["Blackwing Lair"], "bwl_razor", {
  ["0xF1300030930149A4"] = { mark = STAR, name = "Razorgore the Untamed", map = 0, x = 0, y = 0 },
  ["0xF13000310D0149A5"] = { mark = SKULL, name = "Grethok the Controller", map = 0, x = 0, y = 0 },
  ["0xF1300038780149A7"] = { mark = UNMARKED, name = "Blackwing Guardsman", map = 0, x = 0, y = 0 },
  ["0xF1300038780149A6"] = { mark = UNMARKED, name = "Blackwing Guardsman", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "vael", {
  ["0xF1300032DC014A20"] = { mark = STAR, name = "Vaelastrasz the Corrupt", map = 0, x = 0, y = 0 },
  ["0xF1300036AC104CD6"] = { mark = CROSS, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC104CD5"] = { mark = SQUARE, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC104CD4"] = { mark = MOON, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC104DD3"] = { mark = TRIANGLE, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC104DD2"] = { mark = DIAMOND, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC104DD1"] = { mark = CIRCLE, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrm1", {
  ["0xF1300030B1014A2E"] = { mark = DIAMOND, name = "Death Talon Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF1300030B3014A27"] = { mark = STAR, name = "Death Talon Captain", map = 0, x = 0, y = 0 },
  ["0xF1300030B0014A2C"] = { mark = SQUARE, name = "Death Talon Seether", map = 0, x = 0, y = 0 },
  ["0xF1300030AF014A33"] = { mark = SKULL, name = "Death Talon Flamescale", map = 0, x = 0, y = 0 },
  ["0xF1300030AF014A34"] = { mark = CROSS, name = "Death Talon Flamescale", map = 0, x = 0, y = 0 },
  ["0xF1300030B1014A2D"] = { mark = CIRCLE, name = "Death Talon Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF1300030B0014A2B"] = { mark = MOON, name = "Death Talon Seether", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrm2", {
  ["0xF1300030B0014A29"] = { mark = SKULL, name = "Death Talon Seether", map = 0, x = 0, y = 0 },
  ["0xF1300030B3014A28"] = { mark = STAR, name = "Death Talon Captain", map = 0, x = 0, y = 0 },
  ["0xF1300030B1014A30"] = { mark = CIRCLE, name = "Death Talon Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF1300030B1014A2F"] = { mark = DIAMOND, name = "Death Talon Wyrmkin", map = 0, x = 0, y = 0 },
  ["0xF1300030B0014A2A"] = { mark = CROSS, name = "Death Talon Seether", map = 0, x = 0, y = 0 },
  ["0xF1300030AF014A31"] = { mark = SQUARE, name = "Death Talon Flamescale", map = 0, x = 0, y = 0 },
  ["0xF1300030AF014A32"] = { mark = MOON, name = "Death Talon Flamescale", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress1", {
  ["0xF1300030AA104BD1"] = { mark = CROSS, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BD0"] = { mark = SQUARE, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BCF"] = { mark = SKULL, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA218"] = { mark = TRIANGLE, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA216"] = { mark = DIAMOND, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA08B"] = { mark = STAR, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress1_2", {
  ["0xF1300030AA104BD5"] = { mark = CROSS, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BD4"] = { mark = SQUARE, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BD3"] = { mark = SKULL, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA43A"] = { mark = TRIANGLE, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA3BF"] = { mark = DIAMOND, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA395"] = { mark = STAR, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress2", {
  ["0xF1300030AA104BD8"] = { mark = CROSS, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BD7"] = { mark = SQUARE, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BD6"] = { mark = SKULL, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA441"] = { mark = TRIANGLE, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA43F"] = { mark = DIAMOND, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA43D"] = { mark = STAR, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "supress2_2", {
  ["0xF1300030AA104BDB"] = { mark = CROSS, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BDA"] = { mark = SQUARE, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030AA104BD9"] = { mark = SKULL, name = "Blackwing Taskmaster", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA632"] = { mark = TRIANGLE, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA630"] = { mark = DIAMOND, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF1300030B40BA62E"] = { mark = STAR, name = "Death Talon Hatcher", map = 0, x = 0, y = 0 },
  ["0xF130002EF10149A3"] = { mark = CIRCLE, name = "Broodlord Lashlayer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab1", {
  ["0xF1300036AC11F796"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A3C"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F797"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A37"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A3B"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A38"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A3E"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A3D"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab2", {
  ["0xF1300036AC11F79B"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030A9014A44"] = { mark = MOON, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014A4D"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F79A"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A46"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A4A"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A42"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A47"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A48"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A49"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A4B"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A43"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab3", {
  ["0xF1300036AC014A53"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A51"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A57"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A55"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A5A"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F79D"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A58"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014A4E"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A50"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A56"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A54"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030A911F78B"] = { mark = MOON, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrmguard1", {
  ["0xF1300030AD014A6F"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300030AC014A70"] = { mark = SKULL, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014A6D"] = { mark = MOON, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014A6E"] = { mark = CROSS, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab4", {
  ["0xF1300030A911F78C"] = { mark = MOON, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A7E"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A87"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A90"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A76"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A8B"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014A91"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014B68"] = { mark = CIRCLE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A7D"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AD11F78F"] = { mark = TRIANGLE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014A77"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014A86"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F798"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab5", {
  ["0xF1300036AC014B1A"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014AAE"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F791"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014AD1"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014AAD"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300030AD014B68"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014AD0"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030A911F78D"] = { mark = MOON, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014AD3"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014B1B"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014AAC"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014B19"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
})


addToDefaultNpcsToMark(L["Blackwing Lair"], "lab6", {
  ["0xF1300030A9014EFE"] = { mark = MOON, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F794"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014F07"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014F06"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014F00"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014F0C"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014F0D"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014F04"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030A9014F08"] = { mark = STAR, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300030AD11F78F"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F795"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014EFD"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014F0F"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "lab7", {
  ["0xF1300036AC014E77"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014E61"] = { mark = CROSS, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300030A9014E6D"] = { mark = STAR, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300036AC11F792"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030A9014E75"] = { mark = MOON, name = "Blackwing Spellbinder", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014E79"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014E69"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014E74"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014E6C"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014E6B"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300036AC014E70"] = { mark = UNMARKED, name = "Blackwing Technician", map = 0, x = 0, y = 0 },
  ["0xF1300030AB014E4D"] = { mark = SKULL, name = "Blackwing Warlock", map = 0, x = 0, y = 0 },
  ["0xF1300030AD11F78E"] = { mark = SQUARE, name = "Death Talon Overseer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrmguard2", {
  ["0xF1300030AC014A9B"] = { mark = SKULL, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
  ["0xF1300030AC014A9A"] = { mark = CROSS, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
  ["0xF1300030AC014A94"] = { mark = SQUARE, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
  ["0xF130003841014A93"] = { mark = MOON, name = "Master Elemental Shaper Krixix", map = 0, x = 0, y = 0 },
  ["0xF130002ECD014F17"] = { mark = DIAMOND, name = "Flamegor", map = 0, x = 0, y = 0 },
  ["0xF130003909014F14"] = { mark = TRIANGLE, name = "Ebonroc", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Blackwing Lair"], "wyrmguard3", {
  ["0xF1300030AC014A9F"] = { mark = SQUARE, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
  ["0xF1300030AC014AAA"] = { mark = SKULL, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
  ["0xF1300030AC014AA8"] = { mark = CROSS, name = "Death Talon Wyrmguard", map = 0, x = 0, y = 0 },
})


--/////////////// KARA10 ///////////////

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara1", {
  ["0xF13000EF0A2747D1"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747D2"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747D0"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF092747CF"] = { mark = UNMARKED, name = "Shadowbane Ambusher", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747D3"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara2", {
  ["0xF13000EF082747C1"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747C9"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF092747C7"] = { mark = UNMARKED, name = "Shadowbane Ambusher", map = 0, x = 0, y = 0 },
  ["0xF130003A212755AA"] = { mark = UNMARKED, name = "Spider", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747C4"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747C6"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara3", {
  ["0xF13000EF0A2747AD"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747AE"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF072747AA"] = { mark = STAR, name = "Shadowbane Alpha", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747B3"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747AF"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF130000FEB2755A4"] = { mark = UNMARKED, name = "Rat", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara4", {
  ["0xF13000EF082747A9"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747A8"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF092747AB"] = { mark = UNMARKED, name = "Shadowbane Ambusher", map = 0, x = 0, y = 0 },
  ["0xF13000EF072747AA"] = { mark = STAR, name = "Shadowbane Alpha", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747AC"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "rider", {
  ["0xF13000EF1B274792"] = { mark = CROSS, name = "Shadowbane Glutton", map = 0, x = 0, y = 0 },
  ["0xF13000EF1427470C"] = { mark = TRIANGLE, name = "Dark Rider Champion", map = 0, x = 0, y = 0 },
  ["0xF13000EF13277329"] = { mark = UNMARKED, name = "", map = 0, x = 0, y = 0 },
  ["0xF13000EF1327732A"] = { mark = UNMARKED, name = "", map = 0, x = 0, y = 0 },
  ["0xF13000EF12274794"] = { mark = DIAMOND, name = "Haunted Blacksmith", map = 0, x = 0, y = 0 },
  ["0xF13000EF1B274795"] = { mark = SQUARE, name = "Shadowbane Glutton", map = 0, x = 0, y = 0 },
  ["0xF13000EF1B2747A2"] = { mark = SKULL, name = "Shadowbane Glutton", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara5", {
  ["0xF13000EF152756BF"] = { mark = SKULL, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF102756C0"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF102747BD"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF102747BE"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF152756BE"] = { mark = CROSS, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF072747D4"] = { mark = TRIANGLE, name = "Shadowbane Alpha", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara6", {
  ["0xF13000EF082747EB"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747AE"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747AF"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747AD"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747E7"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747E8"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747E9"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara7", {
  ["0xF13000EF0A2747DD"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747DE"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747DC"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara8", {
  ["0xF13000EF082747DA"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747DB"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747D9"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps1", {
  ["0xF13000EF0C274822"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF102747F0"] = { mark = SQUARE, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF182747F4"] = { mark = TRIANGLE, name = "Skitterweb Venomfang", map = 0, x = 0, y = 0 },
  ["0xF13000EF102747F1"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF102747E5"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274824"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF102747E4"] = { mark = CROSS, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps2", {
  ["0xF13000EF0C274808"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274802"] = { mark = MOON, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274801"] = { mark = SQUARE, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274803"] = { mark = CROSS, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274806"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D274809"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D274804"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps3", {
  ["0xF13000EF0D27480F"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C274812"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B27480D"] = { mark = CROSS, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274811"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D27480E"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps4", {
  ["0xF13000EF0B27481B"] = { mark = SQUARE, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B27481C"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274819"] = { mark = CROSS, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C274815"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF130003A212755AD"] = { mark = UNMARKED, name = "Spider", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps5", {
  ["0xF13000EF0C2747F9"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B2747F7"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D2747FB"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF130000FEB2755AE"] = { mark = UNMARKED, name = "Rat", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C274800"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C2747F8"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps6", {
  ["0xF13000EF0D27481F"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C274823"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D274814"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D27481A"] = { mark = TRIANGLE, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C27481D"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D274817"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D274818"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B274820"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C27481E"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "imps7", {
  ["0xF13000EF0C2747FD"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B2747FA"] = { mark = SKULL, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0D2747FE"] = { mark = UNMARKED, name = "Grellkin Channeler", map = 0, x = 0, y = 0 },
  ["0xF13000EF0B2747FC"] = { mark = CROSS, name = "Grellkin Shadow Weaver", map = 0, x = 0, y = 0 },
  ["0xF13000EF0C2747FF"] = { mark = UNMARKED, name = "Grellkin Primalist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "spiderpats", {
  ["0xF130003A212755BA"] = { mark = UNMARKED, name = "Spider", map = 0, x = 0, y = 0 },
  ["0xF13000EF16274778"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF13000EF1927477B"] = { mark = UNMARKED, name = "Skitterweb Leaper", map = 0, x = 0, y = 0 },
  ["0xF13000EF16274776"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF13000EF152756C3"] = { mark = CROSS, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF1627477E"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF13000EF16274772"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF13000EF182747F4"] = { mark = TRIANGLE, name = "Skitterweb Venomfang", map = 0, x = 0, y = 0 },
  ["0xF13000EF19274775"] = { mark = UNMARKED, name = "Skitterweb Leaper", map = 0, x = 0, y = 0 },
  ["0xF13000EF1827477A"] = { mark = SKULL, name = "Skitterweb Venomfang", map = 0, x = 0, y = 0 },
  ["0xF13000EF1827475C"] = { mark = SQUARE, name = "Skitterweb Venomfang", map = 0, x = 0, y = 0 },
  ["0xF13000EF18274753"] = { mark = CIRCLE, name = "Skitterweb Venomfang", map = 0, x = 0, y = 0 },
  ["0xF13000EF19274774"] = { mark = UNMARKED, name = "Skitterweb Leaper", map = 0, x = 0, y = 0 },
  ["0xF13000EF16274777"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF130003A212755B3"] = { mark = UNMARKED, name = "Spider", map = 0, x = 0, y = 0 },
  ["0xF13000EF1627477F"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF13000EF19274773"] = { mark = UNMARKED, name = "Skitterweb Leaper", map = 0, x = 0, y = 0 },
  ["0xF130003A212755B2"] = { mark = UNMARKED, name = "Spider", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes1", {
  ["0xF13000EF072747D5"] = { mark = SKULL, name = "Shadowbane Alpha", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747D7"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
  ["0xF13000EF082747EF"] = { mark = CROSS, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0F2756DE"] = { mark = CIRCLE, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  ["0xF13000EF0A2747D6"] = { mark = UNMARKED, name = "Shadowbane Ragefang", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes2", {
  ["0xF13000EF0F2756DD"] = { mark = CROSS, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  ["0xF13000EF0F2756E3"] = { mark = DIAMOND, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  ["0xF13000EF0F2756E4"] = { mark = TRIANGLE, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  ["0xF13000EF0F2756DE"] = { mark = CIRCLE, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  ["0xF13000EF0F2756DC"] = { mark = SKULL, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  })

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes3", {
  ["0xF13000EF0E274841"] = { mark = UNMARKED, name = "Shattercage Spearman", map = 0, x = 0, y = 0 },
  ["0xF13000EF0E27483D"] = { mark = UNMARKED, name = "Shattercage Spearman", map = 0, x = 0, y = 0 },
  ["0xF13000EF1027484C"] = { mark = CROSS, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF0E274842"] = { mark = UNMARKED, name = "Shattercage Spearman", map = 0, x = 0, y = 0 },
  ["0xF13000EF0E27483E"] = { mark = UNMARKED, name = "Shattercage Spearman", map = 0, x = 0, y = 0 },
  ["0xF13000EF10274840"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF0827483C"] = { mark = SKULL, name = "Shadowbane Darkcaster", map = 0, x = 0, y = 0 },
  ["0xF13000EF0F27482A"] = { mark = CIRCLE, name = "Shattercage Magiskull", map = 0, x = 0, y = 0 },
  ["0xF13000EF0E27483F"] = { mark = STAR, name = "Shattercage Spearman", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes4", {
  ["0xF13000EF15274838"] = { mark = TRIANGLE, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF19274828"] = { mark = UNMARKED, name = "Skitterweb Leaper", map = 0, x = 0, y = 0 },
  ["0xF13000EF15274839"] = { mark = SKULL, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF1027483A"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF16274826"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
  ["0xF13000EF15274832"] = { mark = DIAMOND, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF15274837"] = { mark = CROSS, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF16274827"] = { mark = UNMARKED, name = "Skitterweb Crawler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "moroes5", {
  ["0xF13000EF15274845"] = { mark = SKULL, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF10274849"] = { mark = UNMARKED, name = "Phantom Guardsman", map = 0, x = 0, y = 0 },
  ["0xF13000EF15274847"] = { mark = CROSS, name = "Phantom Servant", map = 0, x = 0, y = 0 },
  ["0xF13000EF15274832"] = { mark = DIAMOND, name = "Phantom Servant", map = 0, x = 0, y = 0 },
})

--/////////////// Kara40 ///////////////


addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_patrols", {
  ["0xF13000F1F0276B43"] = { mark = CIRCLE, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1F2276B2C"] = { mark = TRIANGLE, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1ED276B19"] = { mark = DIAMOND, name = "Greater Gloomwing", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_1", {
  ["0xF13000F1EE276B1F"] = { mark = SKULL, name = "Spectral Worker", map = 0, x = 0, y = 0 },
  ["0xF13000F1EE276B20"] = { mark = SQUARE, name = "Spectral Worker", map = 0, x = 0, y = 0 },
  ["0xF13000F1EE276B21"] = { mark = CROSS, name = "Spectral Worker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_2", {
  ["0xF13000F1EE276B25"] = { mark = SKULL, name = "Spectral Worker", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B24"] = { mark = CROSS, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B23"] = { mark = SQUARE, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_worgen_1", {
  ["0xF13000F1F1276B29"] = { mark = TRIANGLE, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B2B"] = { mark = SQUARE, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B27"] = { mark = MOON, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F0276B28"] = { mark = SKULL, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1F2276B26"] = { mark = CROSS, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B57"] = { mark = DIAMOND, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_worgen_2", {
  ["0xF13000F1F0276B33"] = { mark = DIAMOND, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1EC276B2D"] = { mark = SQUARE, name = "Vampiric Gloomwing", map = 0, x = 0, y = 0 },
  ["0xF13000F1ED276B2E"] = { mark = MOON, name = "Greater Gloomwing", map = 0, x = 0, y = 0 },
  ["0xF13000F1EF276B36"] = { mark = SKULL, name = "Duskfang Creeper", map = 0, x = 0, y = 0 },
  ["0xF13000F1F2276B31"] = { mark = CROSS, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1ED276B2F"] = { mark = TRIANGLE, name = "Greater Gloomwing", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B30"] = { mark = UNMARKED, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_worker", {
  ["0xF13000F1EE276B34"] = { mark = SKULL, name = "Spectral Worker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_outer", {
  ["0xF13000F1ED276B39"] = { mark = SQUARE, name = "Greater Gloomwing", map = 0, x = 0, y = 0 },
  ["0xF13000F1EE276B37"] = { mark = SKULL, name = "Spectral Worker", map = 0, x = 0, y = 0 },
  ["0xF13000F1EE276B38"] = { mark = CROSS, name = "Spectral Worker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_outer_2", {
  ["0xF13000F1EE276B3B"] = { mark = SKULL, name = "Spectral Worker", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B3A"] = { mark = CROSS, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_outer_3", {
  ["0xF13000F1F2276B41"] = { mark = SQUARE, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1F2276B42"] = { mark = CROSS, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B3D"] = { mark = TRIANGLE, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B3E"] = { mark = MOON, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F0276B40"] = { mark = SKULL, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_inner_2", {
  ["0xF13000F1F0276B48"] = { mark = SKULL, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1EC276B44"] = { mark = CROSS, name = "Vampiric Gloomwing", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_gnarlmoon", {
  ["0xF13000F1F2276B51"] = { mark = TRIANGLE, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1F0276B4F"] = { mark = CROSS, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B54"] = { mark = DIAMOND, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F2276B52"] = { mark = MOON, name = "Shadowclaw Rager", map = 0, x = 0, y = 0 },
  ["0xF13000F1F0276B53"] = { mark = SKULL, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B55"] = { mark = CIRCLE, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1F0276B50"] = { mark = SQUARE, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_3", {
  ["0xF13000F48C278713"] = { mark = DIAMOND, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48C278714"] = { mark = SKULL, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48D278715"] = { mark = CROSS, name = "Desolate Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_entrance_inner_1", {
  ["0xF13000F1F0276B48"] = { mark = CROSS, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1F0276B4A"] = { mark = SKULL, name = "Shadowclaw Darkbringer", map = 0, x = 0, y = 0 },
  ["0xF13000F1F1276B46"] = { mark = SQUARE, name = "Shadowclaw Worgen", map = 0, x = 0, y = 0 },
  ["0xF13000F1EC276B44"] = { mark = MOON, name = "Vampiric Gloomwing", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "gnarlmoon_owls", {
  ["0xF13000EA5E278C14"] = { mark = STAR, name = "", map = 0, x = 0, y = 0 }, -- blue owl 1, fake id
  ["0xF13000EA5E278C15"] = { mark = CIRCLE, name = "", map = 0, x = 0, y = 0 }, -- blue owl 2, fake id
  ["0xF13000EA5D278C16"] = { mark = DIAMOND, name = "", map = 0, x = 0, y = 0 }, -- red owl 1, fake id
  ["0xF13000EA5D278C17"] = { mark = TRIANGLE, name = "", map = 0, x = 0, y = 0 }, -- red owl 2, fake id
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_1", {
  ["0xF13000F1F8276B9C"] = { mark = CROSS, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276B9E"] = { mark = SKULL, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276B9B"] = { mark = SQUARE, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B8A"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B9F"] = { mark = DIAMOND, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_patrols", {
  ["0xF13000F1F7276B70"] = { mark = DIAMOND, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276B8C"] = { mark = STAR, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276BA0"] = { mark = TRIANGLE, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F9276B5F"] = { mark = CIRCLE, name = "Manascale Overseer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_2", {
  ["0xF13000EA54276B98"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B9A"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B97"] = { mark = SKULL, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_3", {
  ["0xF13000EA54276B66"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B61"] = { mark = CROSS, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B63"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B65"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B62"] = { mark = SKULL, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276B60"] = { mark = SQUARE, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B64"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_4", {
  ["0xF13000EA54276B8E"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F4276B71"] = { mark = SKULL, name = "Manascale Drake", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B94"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B91"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B92"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B96"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B8F"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B93"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B8D"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B95"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
})

-- skippable
addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_5", {
  ["0xF13000F1F8276B80"] = { mark = CROSS, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B81"] = { mark = SQUARE, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B82"] = { mark = SKULL, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
})

-- skippable
addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_6", {
  ["0xF13000EA54276B79"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B7B"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276B73"] = { mark = SQUARE, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276B72"] = { mark = MOON, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B76"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276B75"] = { mark = SKULL, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276B74"] = { mark = CROSS, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B7F"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B7C"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B7D"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B7E"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B77"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B78"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276B7A"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
})

-- skippable
addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_7", {
  ["0xF13000EA54276BA8"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276BA4"] = { mark = SKULL, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276BA3"] = { mark = CROSS, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BA7"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BA6"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BAB"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276BA2"] = { mark = SQUARE, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BA9"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276BA1"] = { mark = TRIANGLE, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276BA5"] = { mark = MOON, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BAC"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BAA"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_8", {
  ["0xF13000F1F7276BAF"] = { mark = CROSS, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F8276BB0"] = { mark = SQUARE, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276BB1"] = { mark = TRIANGLE, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000F1F6276BB2"] = { mark = MOON, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000F1F4276BAE"] = { mark = SKULL, name = "Manascale Drake", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "incantagos_seekers", {
  ["0xF13000EA55278B84"] = { mark = SQUARE, name = "Manascale Ley-Seeker", map = 0, x = 0, y = 0 },
  ["0xF13000EA55278B83"] = { mark = CROSS, name = "Manascale Ley-Seeker", map = 0, x = 0, y = 0 },
  ["0xF13000EA55278B82"] = { mark = MOON, name = "Manascale Ley-Seeker", map = 0, x = 0, y = 0 },
  ["0xF13000EA55278B81"] = { mark = SKULL, name = "Manascale Ley-Seeker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_1", {
  ["0xF13000F1F8276BC0"] = { mark = SQUARE, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
  ["0xF13000F1F72783E5"] = { mark = SKULL, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1F62783E9"] = { mark = MOON, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000F1F62783E7"] = { mark = TRIANGLE, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BBE"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BBF"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BBB"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BBC"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F82783E8"] = { mark = CROSS, name = "Manascale Mageweaver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_patrols", {
  ["0xF13000F1F6276BC1"] = { mark = DIAMOND, name = "Manascale Dragon Guard", map = 0, x = 0, y = 0 },
  ["0xF13000F1FE276BD6"] = { mark = CIRCLE, name = "Arcane Anomaly", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_2", {
  ["0xF13000F1F7276BC2"] = { mark = CROSS, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BC9"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BC5"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BCA"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BC7"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000EA54276BC8"] = { mark = UNMARKED, name = "Manascale Whelp", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276BC3"] = { mark = SKULL, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1FC2783E4"] = { mark = SQUARE, name = "Unstable Arcane Elemental", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_upper_3", {
  ["0xF13000F1FC276BCE"] = { mark = DIAMOND, name = "Unstable Arcane Elemental", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BCF"] = { mark = SQUARE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BCC"] = { mark = MOON, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276BCB"] = { mark = SKULL, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BCD"] = { mark = TRIANGLE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FC2783E3"] = { mark = CROSS, name = "Unstable Arcane Elemental", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_library_anomalus", {
  ["0xF13000F1FC276BDC"] = { mark = CROSS, name = "Unstable Arcane Elemental", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB2783E2"] = { mark = TRIANGLE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FC276BD9"] = { mark = DIAMOND, name = "Unstable Arcane Elemental", map = 0, x = 0, y = 0 },
  ["0xF13000F1FD276BDA"] = { mark = SKULL, name = "Disrupted Arcane Elemental", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BDB"] = { mark = MOON, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BD8"] = { mark = SQUARE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_1", {
  ["0xF13000F1FB276BE1"] = { mark = MOON, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BDD"] = { mark = TRIANGLE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FE276BE0"] = { mark = DIAMOND, name = "Arcane Anomaly", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276BDF"] = { mark = SQUARE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1FC276BDE"] = { mark = SKULL, name = "Unstable Arcane Elemental", map = 0, x = 0, y = 0 },
  ["0xF13000F1FD2783E1"] = { mark = CROSS, name = "Disrupted Arcane Elemental", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_patrols", {
  ["0xF13000F1FB276D3D"] = { mark = MOON, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D40"] = { mark = DIAMOND, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F1FB276D3F"] = { mark = STAR, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F1F7276D3C"] = { mark = TRIANGLE, name = "Manascale Suppressor", map = 0, x = 0, y = 0 },
  ["0xF13000F205276D3E"] = { mark = CIRCLE, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_2", {
  ["0xF13000F204276D36"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D37"] = { mark = SQUARE, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D35"] = { mark = CROSS, name = "Lingering Magus", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_left", {
  ["0xF13000F202276D38"] = { mark = CROSS, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F205276D39"] = { mark = MOON, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D3A"] = { mark = SQUARE, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D3B"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_3", {
  ["0xF13000F1FE276D4D"] = { mark = CIRCLE, name = "Arcane Anomaly", map = 0, x = 0, y = 0 },
  ["0xF13000F201276D61"] = { mark = SKULL, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
  ["0xF13000F201276D60"] = { mark = CROSS, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_observatory_6", {
  ["0xF13000F200276D68"] = { mark = SQUARE, name = "Crumbling Protector", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D52"] = { mark = CROSS, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F201276D66"] = { mark = TRIANGLE, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D51"] = { mark = SKULL, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F201276D67"] = { mark = MOON, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_echo_pre_1", {
  ["0xF13000F205276D33"] = { mark = TRIANGLE, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D30"] = { mark = MOON, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D2F"] = { mark = CROSS, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D32"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D31"] = { mark = SQUARE, name = "Lingering Magus", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_echo_pre_2_1", {
  ["0xF13000F1FE2783E6"] = { mark = CROSS, name = "Arcane Anomaly", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D2E"] = { mark = SQUARE, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F200276D62"] = { mark = SKULL, name = "Crumbling Protector", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_echo_pre_2_2", {
  ["0xF13000F200276D63"] = { mark = SQUARE, name = "Crumbling Protector", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D2B"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
  ["0xF13000F205276D2C"] = { mark = MOON, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D2D"] = { mark = CROSS, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess_1", {
  ["0xF13000F1FB276D47"] = { mark = TRIANGLE, name = "Arcane Overflow", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D43"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
  ["0xF13000F200276D64"] = { mark = MOON, name = "Crumbling Protector", map = 0, x = 0, y = 0 },
  ["0xF13000F205276D44"] = { mark = CROSS, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
  ["0xF13000F201276D65"] = { mark = SQUARE, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess_2", {
  ["0xF13000F1FD2783E0"] = { mark = SQUARE, name = "Disrupted Arcane Elemental", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D4A"] = { mark = CROSS, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D49"] = { mark = SKULL, name = "Lingering Magus", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess_3", {
  ["0xF13000F201276D66"] = { mark = TRIANGLE, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D52"] = { mark = CROSS, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F201276D67"] = { mark = MOON, name = "Karazhan Protector Golem", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D51"] = { mark = SKULL, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F200276D68"] = { mark = SQUARE, name = "Crumbling Protector", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_chess", {
  ["0xF13000EA42276C07"] = { mark = CIRCLE, name = "Rook", map = 0, x = 0, y = 0 },
  ["0xF13000BF75278779"] = { mark = SKULL, name = "Decaying Bishop", map = 0, x = 0, y = 0 },
  ["0xF13000EA40276C08"] = { mark = TRIANGLE, name = "Knight", map = 0, x = 0, y = 0 },
  ["0xF13000EA43276C06"] = { mark = DIAMOND, name = "Bishop", map = 0, x = 0, y = 0 },
  ["0xF13000BF74278778"] = { mark = SQUARE, name = "Broken Rook", map = 0, x = 0, y = 0 },
  ["0xF13000BF76278777"] = { mark = CROSS, name = "Malfunctioning Knight", map = 0, x = 0, y = 0 },
  ["0xF13000EA3F276C05"] = { mark = STAR, name = "King", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_foyer_1", {
  ["0xF13000F203276D54"] = { mark = CROSS, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F205276D55"] = { mark = MOON, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
  ["0xF13000F202276D53"] = { mark = SQUARE, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D56"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_foyer_2", {
  ["0xF13000F202276D57"] = { mark = SQUARE, name = "Lingering Magus", map = 0, x = 0, y = 0 },
  ["0xF13000F205276D5A"] = { mark = MOON, name = "Lingering Enchanter", map = 0, x = 0, y = 0 },
  ["0xF13000F203276D5B"] = { mark = CROSS, name = "Lingering Arcanist", map = 0, x = 0, y = 0 },
  ["0xF13000F204276D58"] = { mark = SKULL, name = "Lingering Astrologist", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_foyer_3", {
  ["0xF13000F48F278747"] = { mark = CROSS, name = "Forgotten Echo", map = 0, x = 0, y = 0 },
  ["0xF13000F48F278746"] = { mark = SKULL, name = "Forgotten Echo", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_roof", {
  ["0xF13000F48F278741"] = { mark = SKULL, name = "Forgotten Echo", map = 0, x = 0, y = 0 },
  ["0xF13000F48F27873F"] = { mark = SQUARE, name = "Forgotten Echo", map = 0, x = 0, y = 0 },
  ["0xF13000F48F278740"] = { mark = CROSS, name = "Forgotten Echo", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_1", {
  ["0xF13000F48D278726"] = { mark = CROSS, name = "Desolate Destroyer", map = 0, x = 0, y = 0 },
  ["0xF13000F48C278725"] = { mark = DIAMOND, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48C278724"] = { mark = SKULL, name = "Desolate Invader", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_2", {
  ["0xF13000F48C278713"] = { mark = DIAMOND, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48C278714"] = { mark = SKULL, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48D278715"] = { mark = CROSS, name = "Desolate Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_3", {
  ["0xF13000F48C278710"] = { mark = DIAMOND, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48C278711"] = { mark = SKULL, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48D278712"] = { mark = CROSS, name = "Desolate Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Tower of Karazhan"], "kara_upper_demon_4", {
  ["0xF13000F48C27870F"] = { mark = SKULL, name = "Desolate Invader", map = 0, x = 0, y = 0 },
  ["0xF13000F48D27870D"] = { mark = SQUARE, name = "Desolate Destroyer", map = 0, x = 0, y = 0 },
  ["0xF13000F48E27870B"] = { mark = MOON, name = "Ima'ghaol", map = 0, x = 0, y = 0 },
  ["0xF13000F48D27870C"] = { mark = CROSS, name = "Desolate Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "darkbinders1", {
  ["0xF13000F243276CCD"] = { mark = SKULL, name = "Warbringer Overseer", map = 0, x = 0, y = 0 },
  ["0xF13000F245276CE7"] = { mark = CROSS, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F245276CE6"] = { mark = SQUARE, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F244276C76"] = { mark = MOON, name = "Outcast Souleater", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "village_1", {
  ["0xF13000F243276CCC"] = { mark = SKULL, name = "Warbringer Overseer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "village_2", {
  ["0xF13000F240276CCB"] = { mark = SKULL, name = "Doomguard Annihilator", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC9"] = { mark = CROSS, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC8"] = { mark = SQUARE, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "village_3", {
  ["0xF13000F245276CD7"] = { mark = SKULL, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F245276CE2"] = { mark = CROSS, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F246276CDF"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276CE1"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276CE0"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276CDE"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F245276CD6"] = { mark = SQUARE, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "infernal_2", {
  ["0xF13000F241276D0A"] = { mark = SKULL, name = "Infernal Destroyer", map = 0, x = 0, y = 0 },
  ["0xF13000F242276D0C"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276D0D"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276D0B"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276D0E"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_1", {
  ["0xF13000F245276CDA"] = { mark = SKULL, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F244276CD9"] = { mark = CROSS, name = "Outcast Souleater", map = 0, x = 0, y = 0 },
  ["0xF13000F244276CD8"] = { mark = SQUARE, name = "Outcast Souleater", map = 0, x = 0, y = 0 },
  ["0xF13000F246276CDD"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276CDB"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_2", {
  ["0xF13000F245276C92"] = { mark = SKULL, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F244276C94"] = { mark = CROSS, name = "Outcast Souleater", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C85"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C7D"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C80"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C81"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C7F"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C82"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C83"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
})
addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_3", {
  ["0xF13000F245276C8E"] = { mark = SKULL, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F245276C8F"] = { mark = CROSS, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F244276C8D"] = { mark = SQUARE, name = "Outcast Souleater", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C7E"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C91"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C90"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "sanv_3", {
  ["0xF13000F245276C87"] = { mark = SKULL, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F245276C86"] = { mark = CROSS, name = "Draenei Darkbinder", map = 0, x = 0, y = 0 },
  ["0xF13000F244276C88"] = { mark = SQUARE, name = "Outcast Souleater", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C84"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C8C"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
  ["0xF13000F246276C8B"] = { mark = UNMARKED, name = "Draenei Worshipper", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_rupturan_1", {
  ["0xF13000F241276CBE"] = { mark = SKULL, name = "Infernal Destroyer", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC7"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC4"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC6"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC3"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
  ["0xF13000F242276CC5"] = { mark = UNMARKED, name = "Darkflame Imp", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "rupturan_exile", {
  ["0xF13000EA38073D39"] = { mark = SKULL, name = "Crumbling Exile", map = 0, x = 0, y = 0 },
  ["0xF13000EA38073D38"] = { mark = CROSS, name = "Crumbling Exile", map = 0, x = 0, y = 0 },
  ["0xF13000EA38073D37"] = { mark = SQUARE, name = "Crumbling Exile", map = 0, x = 0, y = 0 },
  ["0xF13000EA38073D36"] = { mark = MOON, name = "Crumbling Exile", map = 0, x = 0, y = 0 },
  ["0xF13000EA39073D35"] = { mark = UNMARKED, name = "Rupturan the Broken", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "rupturan_fragments", {
  ["0xF13000EA35279A2F"] = { mark = SKULL, name = "Fragment of Rupturan", map = 0, x = 0, y = 0 },
  ["0xF13000EA35279A30"] = { mark = CROSS, name = "Fragment of Rupturan", map = 0, x = 0, y = 0 },
  ["0xF13000EA35279A31"] = { mark = SQUARE, name = "Fragment of Rupturan", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "outland_patrols", {
  ["0xF13000F240276CB1"] = { mark = 3, name = "Doomguard Annihilator", map = 0, x = 0, y = 0 },
  ["0xF13000F241276D09"] = { mark = 2, name = "Infernal Destroyer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_kruul_1", {
  ["0xF13000F240276D11"] = { mark = CROSS, name = "Doomguard Annihilator", map = 0, x = 0, y = 0 },
  ["0xF13000F240276D10"] = { mark = SQUARE, name = "Doomguard Annihilator", map = 0, x = 0, y = 0 },
  ["0xF13000F243276D0F"] = { mark = SKULL, name = "Warbringer Overseer", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "pre_kruul_2", {
  ["0xF13000F23F276D12"] = { mark = SKULL, name = "Dreadlord Doomseeker", map = 0, x = 0, y = 0 },
  ["0xF13000F23F276D17"] = { mark = CROSS, name = "Dreadlord Doomseeker", map = 0, x = 0, y = 0 },
  ["0xF13000F23F276D14"] = { mark = SQUARE, name = "Dreadlord Doomseeker", map = 0, x = 0, y = 0 },
  ["0xF13000F23F276D13"] = { mark = MOON, name = "Dreadlord Doomseeker", map = 0, x = 0, y = 0 },
  ["0xF13000F23F276D15"] = { mark = TRIANGLE, name = "Dreadlord Doomseeker", map = 0, x = 0, y = 0 },
  ["0xF13000F23F276D16"] = { mark = DIAMOND, name = "Dreadlord Doomseeker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["The Rock of Desolation"], "mephistroth", {
  ["0xF130016C98271234"] = { mark = SKULL, name = "", map = 0, x = 0, y = 0 }, -- hellfire doomguard, fake id
  ["0xF130016C98271235"] = { mark = CROSS, name = "", map = 0, x = 0, y = 0 }, -- hellfire doomguard, fake id
})

--/////////////// Stratholme ///////////////

addToDefaultNpcsToMark(L["Stratholme"], "live_pats", {
  ["0xF1300028AB11E66A"] = { mark = STAR, name = "Eye of Naxxramas", map = 0, x = 0, y = 0 },
  ["0xF1300028AB11E66B"] = { mark = TRIANGLE, name = "Eye of Naxxramas", map = 0, x = 0, y = 0 },
  ["0xF1300028AE00D2C1"] = { mark = SQUARE, name = "Patchwork Horror", map = 0, x = 0, y = 0 },
  ["0xF1300028AE00D2C2"] = { mark = CIRCLE, name = "Patchwork Horror", map = 0, x = 0, y = 0 },
  ["0xF1300028AE00D2B7"] = { mark = DIAMOND, name = "Patchwork Horror", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Stratholme"], "dead_pats", {
  ["0xF1300028A800D22E"] = { mark = SKULL, name = "Rockwing Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF1300028A800D22B"] = { mark = CROSS, name = "Rockwing Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF1300028A800D229"] = { mark = SQUARE, name = "Rockwing Screecher", map = 0, x = 0, y = 0 },
  ["0xF1300028A800D227"] = { mark = MOON, name = "Rockwing Gargoyle", map = 0, x = 0, y = 0 },
  ["0xF1300028A800D225"] = { mark = TRIANGLE, name = "Rockwing Screecher", map = 0, x = 0, y = 0 },
  ["0xF1300028A800D223"] = { mark = DIAMOND, name = "Rockwing Screecher", map = 0, x = 0, y = 0 },
  ["0xF1300028A800D221"] = { mark = CIRCLE, name = "Rockwing Screecher", map = 0, x = 0, y = 0 },
  -- ["0xF130002A3900D22F"] = STAR,-- Stonespine -- need the mark for eye
  ["0xF1300028AB11E66C"] = { mark = STAR, name = "Eye of Naxxramas", map = 0, x = 0, y = 0 },
})

--/////////////// Timbermaw Hold ///////////////

addToDefaultNpcsToMark(L["Timbermaw Hold"], "entrance_1", {
  ["0xF13000F59C279368"] = { mark = CROSS, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F59B279367"] = { mark = SQUARE, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
  ["0xF13000F598279366"] = { mark = DIAMOND, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
  ["0xF13000F599279370"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "entrance_2", {
  ["0xF13000F59627936B"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59727936E"] = { mark = CROSS, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F599279735"] = { mark = SQUARE, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "entrance_3", {
  ["0xF13000F596279739"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F597279737"] = { mark = SQUARE, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F596279738"] = { mark = CROSS, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59927936F"] = { mark = MOON, name = "Withermaw Totemic -- random loner", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_1", {
  ["0xF13000F59C279D57"] = { mark = CROSS, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F596279D58"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F598279D59"] = { mark = SQUARE, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
  ["0xF13000F598279D5A"] = { mark = MOON, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_loose", {
  ["0xF13000F596279D61"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59F279D60"] = { mark = CROSS, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F5A5279D5C"] = { mark = DIAMOND, name = "Son of Ursol", map = 0, x = 0, y = 0 },
  ["0xF13000F59E279D5E"] = { mark = CIRCLE, name = "Tainted Mass", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_2", {
  ["0xF13000F59F279D62"] = { mark = SKULL, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F59F279D63"] = { mark = CROSS, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_1", {
  ["0xF13000F59D279D6B"] = { mark = CROSS, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F596279D6C"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_2", {
  ["0xF13000F59F279D7E"] = { mark = SKULL, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D81"] = { mark = CROSS, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
  ["0xF13000F5A1279D7F"] = { mark = SQUARE, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_3", {
  ["0xF13000F5A3279D86"] = { mark = SKULL, name = "Foulheart Trickster", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D87"] = { mark = CROSS, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_1", {
  ["0xF13000F5A2279D82"] = { mark = SKULL, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D83"] = { mark = CROSS, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
  ["0xF13000F5A1279D84"] = { mark = SQUARE, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
  ["0xF13000F5A1279D85"] = { mark = MOON, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_2", {
  ["0xF13000F5A4279D89"] = { mark = SKULL, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D8A"] = { mark = CROSS, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_3", {
  ["0xF13000F5A2279D8B"] = { mark = SKULL, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
  ["0xF13000F5A3279D91"] = { mark = CROSS, name = "Foulheart Trickster", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D90"] = { mark = SQUARE, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_4", {
  ["0xF13000F5A3279D8F"] = { mark = SKULL, name = "Foulheart Trickster", map = 0, x = 0, y = 0 },
  ["0xF13000F5A4279D8D"] = { mark = CROSS, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D8C"] = { mark = SQUARE, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
  ["0xF13000F5A1279D8E"] = { mark = MOON, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_5", {
  ["0xF13000F5A1279D9A"] = { mark = SKULL, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D99"] = { mark = CROSS, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "satyr_6", {
  ["0xF13000F5A1279D96"] = { mark = SKULL, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
  ["0xF13000F5A4279D97"] = { mark = CROSS, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F5A4279D98"] = { mark = SQUARE, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279D95"] = { mark = MOON, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "karrsh_2", {
  ["0xF13000F5D627973C"] = { mark = UNMARKED, name = "Karrsh the Sentinel", map = 0, x = 0, y = 0 },
  ["0xF13000F59627973E"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59327973F"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279740"] = { mark = MOON, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279741"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

-- TODO: karrsh_1 has identical GUIDs/marks as left_upper_1 - need to resolve this over time
addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_1", {
  ["0xF13000F59C279D4F"] = { mark = SKULL, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F599279D51"] = { mark = CROSS, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F59B279D50"] = { mark = SQUARE, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "karrsh_1", {
  ["0xF13000F59C279D4F"] = { mark = CROSS, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F599279D51"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F59B279D50"] = { mark = SQUARE, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_2", {
  ["0xF13000F593279D55"] = { mark = SKULL, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279D54"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5A5279D52"] = { mark = DIAMOND, name = "Son of Ursol", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_3", {
  ["0xF13000F593279725"] = { mark = SKULL, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279722"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279723"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279724"] = { mark = MOON, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_4", {
  ["0xF13000F59727971C"] = { mark = SQUARE, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F59927971D"] = { mark = CROSS, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F59627971E"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59327971F"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279720"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279721"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_6", {
  ["0xF13000F59927971B"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F59327971A"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279719"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279718"] = { mark = MOON, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_7", {
  ["0xF13000F596279717"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F593279716"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279715"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279713"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279714"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "stump_1", {
  ["0xF13000F599279710"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F593279711"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "stump_2", {
  ["0xF13000F59D27970B"] = { mark = CROSS, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F59927970C"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F59C27970F"] = { mark = SQUARE, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F59827970D"] = { mark = MOON, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_1", {
  ["0xF13000F5972796CF"] = { mark = SKULL, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796CD"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796CC"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "village_1", {
  ["0xF13000F5962796C9"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796D1"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "pre_kronn", {
  ["0xF13000F59C2796C2"] = { mark = SQUARE, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F59B2796C3"] = { mark = MOON, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
  ["0xF13000F5962796C5"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F5992796C4"] = { mark = CROSS, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2", {
  ["0xF13000F5992796F1"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796F5"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796F2"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796F3"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796F4"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_3", {
  ["0xF13000F59C2796D4"] = { mark = SKULL, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F59B2796D5"] = { mark = CROSS, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
  ["0xF13000F5982796D3"] = { mark = SQUARE, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796D6"] = { mark = MOON, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2b", {
  ["0xF13000F59B2796F9"] = { mark = SKULL, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796FA"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796FB"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796FC"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_4", {
  ["0xF13000F5932796DB"] = { mark = SKULL, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796D7"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796D8"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796DA"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796D9"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_5", {
  ["0xF13000F59C2796DE"] = { mark = SKULL, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F5972796DD"] = { mark = CROSS, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F59B2796DF"] = { mark = SQUARE, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_7", {
  ["0xF13000F59D2796E1"] = { mark = SQUARE, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F5972796E0"] = { mark = CROSS, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F5962796E2"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796E3"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796E4"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796E5"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796E6"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796E7"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_6", {
  ["0xF13000F59D2796E8"] = { mark = SQUARE, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F5992796EA"] = { mark = CROSS, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F5962796E9"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796EE"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796EB"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796ED"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796EC"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796EF"] = { mark = UNMARKED, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_illuminators", {
  ["0xF13000F5DD2796C0"] = { mark = SKULL, name = "Chieftain Partath", map = 0, x = 0, y = 0 },
  ["0xF13000F5DE2797AD"] = { mark = SQUARE, name = "Withermaw Illuminator", map = 0, x = 0, y = 0 },
  ["0xF13000F5DE2797AE"] = { mark = MOON, name = "Withermaw Illuminator", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_shadowkeepers", {
  ["0xF13000F5DF27ADA2"] = { mark = SKULL, name = "Withermaw Shadowkeeper", map = 0, x = 0, y = 0 },
  ["0xF13000F5DF27ADA3"] = { mark = CROSS, name = "Withermaw Shadowkeeper", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2c", {
  ["0xF13000F5982796F7"] = { mark = SKULL, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796F8"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796F6"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2d", {
  ["0xF13000F5962796FF"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796FE"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F5932796FD"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2e", {
  ["0xF13000F59B279700"] = { mark = SKULL, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
  ["0xF13000F593279701"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "chieftain_2f", {
  ["0xF13000F593279703"] = { mark = SKULL, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279702"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279704"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_1", {
  ["0xF13000F59F279A35"] = { mark = SKULL, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F59C279A34"] = { mark = CROSS, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F598279A33"] = { mark = SQUARE, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "center_upper_2", {
  ["0xF13000F59327972A"] = { mark = SKULL, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F59327972C"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F59327972B"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "center_loose", {
  ["0xF13000F59D279730"] = { mark = DIAMOND, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F59B27972F"] = { mark = CIRCLE, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "center_upper_1", {
  ["0xF13000F597279728"] = { mark = CROSS, name = "Withermaw Shaman", map = 0, x = 0, y = 0 },
  ["0xF13000F599279729"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F598279726"] = { mark = SQUARE, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "left_upper_5", {
  ["0xF13000F596279731"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F593279733"] = { mark = CROSS, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
  ["0xF13000F593279732"] = { mark = SQUARE, name = "Enraged Withermaw", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "rotgrowl", {
  ["0xF13000F5D927A7C6"] = { mark = STAR, name = "Kodiak", map = 0, x = 0, y = 0 },
  ["0xF13000F5D8279798"] = { mark = CROSS, name = "Rotgrowl", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_2", {
  ["0xF13000F59F27975E"] = { mark = SKULL, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F59F27975F"] = { mark = CROSS, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F59E27975D"] = { mark = SQUARE, name = "Tainted Mass", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_3", {
  ["0xF13000F596279757"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59E279759"] = { mark = CROSS, name = "Tainted Mass", map = 0, x = 0, y = 0 },
  ["0xF13000F599279758"] = { mark = SQUARE, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
})

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_1", {
--   ["0xF13000085D27AAFC"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AAFB"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AAFA"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AAFD"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_2", {
--   ["0xF13000085D27AB04"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB03"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB02"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB01"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_3", {
--   ["0xF13000085D27AB10"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB0F"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB0E"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB0D"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_4", {
--   ["0xF13000085D27AB18"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB17"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB16"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB15"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_5", {
--   ["0xF13000085D27AB1B"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB1E"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB1D"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB1C"] = MOON, -- Corrupted Globule
-- })

-- addToDefaultNpcsToMark(L["Timbermaw Hold"], "globules_6", {
--   ["0xF13000085D27AB23"] = SKULL, -- Corrupted Globule
--   ["0xF13000085D27AB22"] = CROSS, -- Corrupted Globule
--   ["0xF13000085D27AB21"] = SQUARE, -- Corrupted Globule
--   ["0xF13000085D27AB20"] = MOON, -- Corrupted Globule
-- })

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_4", {
  ["0xF13000F59627975C"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59F27975B"] = { mark = CROSS, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
  ["0xF13000F59F27975A"] = { mark = SQUARE, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "twisted_rumblers", {
  ["0xF13000F5A0279A28"] = { mark = SKULL, name = "Twisted Rumbler", map = 0, x = 0, y = 0 },
  ["0xF13000F5A0279A29"] = { mark = CROSS, name = "Twisted Rumbler", map = 0, x = 0, y = 0 },
  ["0xF13000F5A0279A2A"] = { mark = SQUARE, name = "Twisted Rumbler", map = 0, x = 0, y = 0 },
  -- ["0xF13000F5A0279A2B"] = MOON, -- Twisted Rumbler -- no need to fight
  -- ["0xF13000F5A0279A2C"] = TRIANGLE, -- Twisted Rumbler -- no need to fight
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "corruption_5", {
  ["0xF13000F596279A31"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59F279A2F"] = { mark = CROSS, name = "Corruption of Loktanag", map = 0, x = 0, y = 0 },
})

-- here for posterity but no real reason to mark these
addToDefaultNpcsToMark(L["Timbermaw Hold"], "kronn", {
  ["0xF13000F5962796C7"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
  ["0xF13000F59B2796C6"] = { mark = CROSS, name = "Withermaw Tracker", map = 0, x = 0, y = 0 },
  ["0xF13000F5982796C8"] = { mark = SQUARE, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_lower_3", {
  ["0xF13000F59C279D64"] = { mark = CROSS, name = "Withermaw Den Watcher", map = 0, x = 0, y = 0 },
  ["0xF13000F599279D66"] = { mark = SKULL, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
  ["0xF13000F598279D65"] = { mark = SQUARE, name = "Withermaw Pathfinder", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_hut_1", {
  ["0xF13000F5A4279DA9"] = { mark = SKULL, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F5A4279DAA"] = { mark = CROSS, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F59D279DAC"] = { mark = MOON, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F599279DAB"] = { mark = SQUARE, name = "Withermaw Totemic", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_patrol", {
  ["0xF13000F5A1279DA7"] = { mark = DIAMOND, name = "Foulheart Deceiver", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_4", {
  ["0xF13000F5A4279DA6"] = { mark = CROSS, name = "Foulheart Hellcaller", map = 0, x = 0, y = 0 },
  ["0xF13000F5A2279DA5"] = { mark = SQUARE, name = "Foulheart Satyr", map = 0, x = 0, y = 0 },
  ["0xF13000F59D279DA3"] = { mark = MOON, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F596279DA4"] = { mark = SKULL, name = "Withermaw Defiler", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "right_ramp_5", {
  ["0xF13000F5A5279D9F"] = { mark = SKULL, name = "Son of Ursol", map = 0, x = 0, y = 0 },
  ["0xF13000F5A5279D9D"] = { mark = CROSS, name = "Son of Ursol", map = 0, x = 0, y = 0 },
  ["0xF13000F5A5279D9E"] = { mark = SQUARE, name = "Son of Ursol", map = 0, x = 0, y = 0 },
  ["0xF13000F5A5279DA0"] = { mark = MOON, name = "Son of Ursol", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "inner_1", {
  ["0xF13000F59D279DA2"] = { mark = SKULL, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
  ["0xF13000F59D279DA1"] = { mark = CROSS, name = "Withermaw Ursa", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Timbermaw Hold"], "ursol_corrupters", {
  ["0xF13000F5E3279B8E"] = { mark = UNMARKED, name = "Ursol", map = 0, x = 0, y = 0 },
  ["0xF13000732827A7C5"] = { mark = SKULL, name = "Withermaw Corrupter", map = 0, x = 0, y = 0 },
  ["0xF13000732827A7C6"] = { mark = CROSS, name = "Withermaw Corrupter", map = 0, x = 0, y = 0 },
})

--/////////////// Onyxia's Lair ///////////////

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_1", {
  ["0xF13000BF782792E7"] = { mark = SKULL, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
  ["0xF13000BF782792E4"] = { mark = CROSS, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
})

-- brood commnader is here

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_2", {
  ["0xF13000BF782792EC"] = { mark = SKULL, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
  ["0xF13000BF792792EB"] = { mark = CROSS, name = "Onyxian Flamespawn", map = 0, x = 0, y = 0 },
  ["0xF13000BF792792EA"] = { mark = CIRCLE, name = "Onyxian Flamespawn", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_3", {
  ["0xF130002F6100CB55"] = { mark = SKULL, name = "Onyxian Warder", map = 0, x = 0, y = 0 },
  ["0xF13000BF782792E8"] = { mark = CROSS, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
  ["0xF13000BF782792E9"] = { mark = CIRCLE, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_4", {
  ["0xF130002F6100CB50"] = { mark = SKULL, name = "Onyxian Warder", map = 0, x = 0, y = 0 },
  ["0xF13000BF792792F3"] = { mark = CROSS, name = "Onyxian Flamespawn", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_5", {
  ["0xF130002F612792F2"] = { mark = SKULL, name = "Onyxian Warder", map = 0, x = 0, y = 0 },
  ["0xF13000BF782792F1"] = { mark = CIRCLE, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
  ["0xF13000BF782792F0"] = { mark = DIAMOND, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
  ["0xF13000BF792792ED"] = { mark = CROSS, name = "Onyxian Flamespawn", map = 0, x = 0, y = 0 },
})

-- ony path
addToDefaultNpcsToMark(L["Onyxia's Lair"], "trash_left", {
  ["0xF13000BF792792E5"] = { mark = CROSS, name = "Onyxian Flamespawn", map = 0, x = 0, y = 0 },
  ["0xF13000BF782792E6"] = { mark = SKULL, name = "Onyxian Inciter", map = 0, x = 0, y = 0 },
})

addToDefaultNpcsToMark(L["Onyxia's Lair"], "onyxia_hatchers", {
  ["0xF13000C3E027A8B0"] = { mark = CROSS, name = "Onyxian Hatcher", map = 0, x = 0, y = 0 },
  ["0xF13000C3E027A8B1"] = { mark = SKULL, name = "Onyxian Hatcher", map = 0, x = 0, y = 0 },
})
