-- AutoMarker - in game pack editor
-- /am ui  (or key binding) : shows the pack of the current target and lets you change the marks of its mobs.

local API = AutoMarkerAPI
local L = AutoMarkerLocale
if not API then return end -- core didn't load (no SuperWoW / nampower)

local ROWS = 12
local ROW_H = 20
local ICON = 16
local WIDTH = 440
local MARK_ORDER = { 8, 7, 6, 5, 4, 3, 2, 1, 0 } -- skull first, "no mark" last
local RAID_ICONS = "Interface\\TargetingFrame\\UI-RaidTargetingIcons"
local NO_MARK = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"

local state = {
  zone = nil,
  pack = nil,
  rows = {},  -- sorted guids of the shown pack
}

local gui -- main frame, created on first use

-- Utility ---------------------------------------------------------------------

local function SetIconTexture(tex, mark)
  if mark == 0 then
    tex:SetTexture(NO_MARK)
    tex:SetTexCoord(0, 1, 0, 1)
  else
    tex:SetTexture(RAID_ICONS)
    local col = math.mod(mark - 1, 4)
    local row = math.floor((mark - 1) / 4)
    tex:SetTexCoord(col * 0.25, (col + 1) * 0.25, row * 0.25, (row + 1) * 0.25)
  end
end

local function Skin(frame, kind)
  -- use pfUI look when available, default Blizzard look otherwise
  if pfUI and pfUI.api then
    if kind == "frame" and pfUI.api.CreateBackdrop then
      pcall(pfUI.api.CreateBackdrop, frame, nil, nil, .85)
      return
    elseif kind == "button" and pfUI.api.SkinButton then
      pcall(pfUI.api.SkinButton, frame)
      return
    elseif kind == "close" and pfUI.api.SkinCloseButton then
      pcall(pfUI.api.SkinCloseButton, frame, frame:GetParent(), -6, -6)
      return
    elseif kind == "check" and pfUI.api.SkinCheckbox then
      pcall(pfUI.api.SkinCheckbox, frame, 14)
      return
    end
  end
  if kind == "frame" then
    frame:SetBackdrop({
      bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
      edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
      tile = true, tileSize = 32, edgeSize = 32,
      insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
  end
end

local function Button(parent, text, width, onclick, tooltip)
  local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
  b:SetWidth(width)
  b:SetHeight(20)
  b:SetText(text)
  b:SetScript("OnClick", onclick)
  if tooltip then
    b:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_TOP")
      GameTooltip:SetText(tooltip, 1, 1, 1, 1, 1)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", function() GameTooltip:Hide() end)
  end
  Skin(b, "button")
  return b
end

local function PackStatus(zone, pack)
  local default = API.HasDefault(zone, pack)
  local custom = API.IsModified(zone, pack)
  if default and custom then return "|cffffcc00" .. L["modified"] .. "|r"
  elseif default then return "|cff9d9d9d" .. L["default"] .. "|r"
  else return "|cff33ccff" .. L["custom"] .. "|r" end
end

local function SortRows(pack)
  local rows = {}
  for guid in pairs(pack or {}) do tinsert(rows, guid) end
  table.sort(rows, function(a, b)
    local ma, mb = pack[a] or 0, pack[b] or 0
    if ma ~= mb then return ma > mb end
    local na, nb = API.GetName(a) or "", API.GetName(b) or ""
    if na ~= nb then return na < nb end
    return a < b
  end)
  return rows
end

local function TargetGuid()
  local _, guid = UnitExists("target")
  return guid
end

-- Refresh ---------------------------------------------------------------------

local Refresh -- forward

local function SelectPack(zone, pack)
  state.zone = zone
  state.pack = pack
  if gui then
    gui.scroll.offset = 0
    getglobal("AutoMarkerEditorScrollScrollBar"):SetValue(0)
  end
  Refresh()
end

local function CyclePack(step)
  local zone = state.zone or API.GetZone()
  local list = API.GetPackList(zone)
  local n = getn(list)
  if n == 0 then return end
  local idx = 0
  for i, name in ipairs(list) do
    if name == state.pack then idx = i break end
  end
  idx = idx + step
  if idx < 1 then idx = n elseif idx > n then idx = 1 end
  SelectPack(zone, list[idx])
end

local function UpdateRow(row, guid, pack, dupes)
  row.guid = guid
  local mark = pack[guid] or 0
  for _, ib in ipairs(row.icons) do
    if ib.mark == mark then
      ib.tex:SetAlpha(1)
      ib.tex:SetVertexColor(1, 1, 1)
      ib.sel:Show()
    else
      ib.tex:SetAlpha(0.2)
      ib.sel:Hide()
    end
  end

  local name = API.GetName(guid) or "?"
  local r, g, b = 0.6, 0.6, 0.6 -- not loaded / out of range
  if UnitExists(guid) then
    if UnitIsDead(guid) then r, g, b = 0.8, 0.2, 0.2
    else r, g, b = 0.2, 1, 0.2 end
  end
  if TargetGuid() == guid then name = "> " .. name end
  row.name:SetText(name)
  row.name:SetTextColor(r, g, b)
  row.guidText:SetText(string.sub(guid, -6))
  -- green id: spawn position known / grey: still missing (filled the first time the mob is targeted)
  if API.GetPos(guid) then row.guidText:SetTextColor(0.5, 0.9, 0.5) else row.guidText:SetTextColor(0.45, 0.45, 0.45) end
  if mark > 0 and dupes[mark] and dupes[mark] > 1 then
    row.warn:Show()
  else
    row.warn:Hide()
  end
  row:Show()
end

Refresh = function()
  if not gui or not gui:IsShown() then return end
  local zone = state.zone or API.GetZone()
  state.zone = zone
  local pack = state.pack and API.GetPack(zone, state.pack)
  if state.pack and not pack then state.pack = nil end

  gui.zoneText:SetText("Zone : |cffffffff" .. (zone or "?") .. "|r")

  local sweep_on, sweep_pack = API.GetSweep()
  gui.sweepBtn:SetText((sweep_on and sweep_pack == state.pack) and L["Stop sweep"] or L["Sweep"])

  if not state.pack then
    gui.packText:SetText("|cff9d9d9d" .. L["(no pack - target a mob or use the arrows)"] .. "|r")
    gui.countText:SetText("")
    state.rows = {}
    for i = 1, ROWS do gui.rows[i]:Hide() end
    FauxScrollFrame_Update(gui.scroll, 0, ROWS, ROW_H)
    gui.nameBox:SetText("")
    gui.resetBtn:Disable()
    gui.markBtn:Disable()
    gui.sweepBtn:Disable()
    gui.addBtn:Disable()
    return
  end

  gui.markBtn:Enable()
  gui.sweepBtn:Enable()
  gui.addBtn:Enable()
  gui.resetBtn:Enable()

  local list = API.GetPackList(zone)
  local pos = 0
  for i, name in ipairs(list) do if name == state.pack then pos = i break end end
  gui.packText:SetText("|cffffd100" .. state.pack .. "|r  " .. PackStatus(zone, state.pack) ..
    "  |cff9d9d9d(" .. pos .. "/" .. getn(list) .. ")|r")
  if not gui.nameBox.editing then gui.nameBox:SetText(state.pack) end

  if API.HasDefault(zone, state.pack) then
    gui.resetBtn:SetText(L["Reset"])
    if not API.IsModified(zone, state.pack) then gui.resetBtn:Disable() end
  else
    gui.resetBtn:SetText(L["Delete"])
  end

  state.rows = SortRows(pack)
  local dupes = {}
  for _, m in pairs(pack) do dupes[m] = (dupes[m] or 0) + 1 end
  local total = getn(state.rows)
  local marked = 0
  for _, guid in ipairs(state.rows) do if (pack[guid] or 0) > 0 then marked = marked + 1 end end
  gui.countText:SetText(format(L["%d mob(s), %d marked"], total, marked))

  FauxScrollFrame_Update(gui.scroll, total, ROWS, ROW_H)
  local offset = FauxScrollFrame_GetOffset(gui.scroll)
  for i = 1, ROWS do
    local guid = state.rows[i + offset]
    if guid then
      UpdateRow(gui.rows[i], guid, pack, dupes)
    else
      gui.rows[i]:Hide()
    end
  end
end

-- Actions ---------------------------------------------------------------------

local function FollowTarget(force)
  if not gui or not gui:IsShown() then return end
  if not force and not API.Settings().guiFollowTarget then
    Refresh()
    return
  end
  local guid = TargetGuid()
  local zone = API.GetZone()
  if guid then
    local pack = API.GetPackOf(guid, zone)
    if pack then
      if pack ~= state.pack or zone ~= state.zone then
        SelectPack(zone, pack)
        return
      end
    end
  end
  if zone ~= state.zone then state.zone = zone; state.pack = nil end
  Refresh()
end

local function AddTarget()
  local guid = TargetGuid()
  if not guid or string.sub(guid, 1, 5) ~= "0xF13" then
    API.Print(L["target a creature to add it to the pack."])
    return
  end
  local old = API.GetPackOf(guid, state.zone)
  API.AddMob(state.zone, state.pack, guid)
  API.Print((API.GetName(guid) or guid) .. " -> " .. state.pack .. (old and old ~= state.pack and (L[" (removed from "] .. old .. ")") or ""))
end

local function NewPack()
  local zone = state.zone or API.GetZone()
  local name = API.NewPack(zone)
  local guid = TargetGuid()
  if guid and string.sub(guid, 1, 5) == "0xF13" then
    API.AddMob(zone, name, guid)
  end
  SelectPack(zone, name)
  gui.nameBox:SetFocus()
  gui.nameBox:HighlightText()
end

StaticPopupDialogs["AUTOMARKER_RESET_PACK"] = {
  text = "%s",
  button1 = TEXT(YES),
  button2 = TEXT(NO),
  OnAccept = function()
    if state.confirm then
      API.ResetPack(state.confirm.zone, state.confirm.pack)
      if not API.GetPack(state.confirm.zone, state.confirm.pack) then state.pack = nil end
      state.confirm = nil
      Refresh()
    end
  end,
  OnCancel = function() state.confirm = nil end,
  timeout = 0,
  whileDead = 1,
  hideOnEscape = 1,
}

local function ResetPack()
  if not state.pack then return end
  state.confirm = { zone = state.zone, pack = state.pack }
  local msg
  if API.HasDefault(state.zone, state.pack) then
    msg = format(L["Reset pack %s to its default marks?"], "|cffffd100" .. state.pack .. "|r")
  else
    msg = format(L["Delete pack %s?\nIts mobs will become unknown again."], "|cffffd100" .. state.pack .. "|r")
  end
  StaticPopup_Show("AUTOMARKER_RESET_PACK", msg)
end

local function RenameFromBox()
  local new = gui.nameBox:GetText()
  if not state.pack or new == state.pack then return end
  local ok, res = API.RenamePack(state.zone, state.pack, new)
  if ok then
    state.pack = res
  else
    API.Print("|cffff0000" .. L["cannot rename"] .. "|r: " .. tostring(res))
    gui.nameBox:SetText(state.pack)
  end
  Refresh()
end

-- Construction ----------------------------------------------------------------

local function CreateRow(parent, i)
  local row = CreateFrame("Frame", nil, parent)
  row:SetWidth(WIDTH - 50)
  row:SetHeight(ROW_H)
  row:SetPoint("TOPLEFT", parent, "TOPLEFT", 16, -96 - (i - 1) * ROW_H)

  local bg = row:CreateTexture(nil, "BACKGROUND")
  bg:SetAllPoints(row)
  bg:SetTexture(1, 1, 1, math.mod(i, 2) == 0 and 0.04 or 0)

  row.icons = {}
  local x = 0
  for _, mark in ipairs(MARK_ORDER) do
    local ib = CreateFrame("Button", nil, row)
    ib:SetWidth(ICON + 2)
    ib:SetHeight(ICON + 2)
    ib:SetPoint("LEFT", row, "LEFT", x, 0)
    ib.mark = mark
    local sel = ib:CreateTexture(nil, "BACKGROUND")
    sel:SetAllPoints(ib)
    sel:SetTexture(1, 0.82, 0, 0.35)
    sel:Hide()
    ib.sel = sel
    local tex = ib:CreateTexture(nil, "ARTWORK")
    tex:SetWidth(ICON)
    tex:SetHeight(ICON)
    tex:SetPoint("CENTER", ib, "CENTER", 0, 0)
    SetIconTexture(tex, mark)
    ib.tex = tex
    local hl = ib:CreateTexture(nil, "HIGHLIGHT")
    hl:SetAllPoints(ib)
    hl:SetTexture(1, 1, 1, 0.25)
    ib:SetScript("OnClick", function()
      if not row.guid or not state.pack then return end
      -- shift-click: apply the mark on the mob right away if it is loaded
      API.SetMark(state.zone, state.pack, row.guid, this.mark, IsShiftKeyDown())
    end)
    ib:SetScript("OnEnter", function()
      GameTooltip:SetOwner(this, "ANCHOR_TOP")
      GameTooltip:SetText(API.raidMarks[this.mark + 1] or "", 1, 1, 1)
      GameTooltip:AddLine(L["Shift-click: also apply the mark in game"], 0.7, 0.7, 0.7)
      GameTooltip:Show()
    end)
    ib:SetScript("OnLeave", function() GameTooltip:Hide() end)
    tinsert(row.icons, ib)
    x = x + ICON + 3
  end

  local warn = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  warn:SetPoint("LEFT", row, "LEFT", x + 1, 0)
  warn:SetText("|cffff8000!|r")
  warn:Hide()
  row.warn = warn

  -- name: click to target the mob
  local nb = CreateFrame("Button", nil, row)
  nb:SetPoint("LEFT", row, "LEFT", x + 10, 0)
  nb:SetWidth(WIDTH - 50 - x - 10 - 70)
  nb:SetHeight(ROW_H)
  local name = nb:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  name:SetAllPoints(nb)
  name:SetJustifyH("LEFT")
  row.name = name
  local nhl = nb:CreateTexture(nil, "HIGHLIGHT")
  nhl:SetAllPoints(nb)
  nhl:SetTexture(1, 1, 1, 0.1)
  nb:SetScript("OnClick", function()
    if row.guid and UnitExists(row.guid) then TargetUnit(row.guid) end
  end)
  nb:SetScript("OnEnter", function()
    if not row.guid then return end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(API.GetName(row.guid) or "?", 1, 1, 1)
    GameTooltip:AddLine(row.guid, 0.7, 0.7, 0.7)
    if UnitExists(row.guid) then
      GameTooltip:AddLine(UnitIsDead(row.guid) and L["Dead"] or L["Nearby - click to target"], 0.2, 1, 0.2)
    else
      GameTooltip:AddLine(L["Not nearby"], 0.6, 0.6, 0.6)
    end
    local map, x, y = API.GetPos(row.guid)
    if map then
      local mname, mtype = API.GetMapInfo(map)
      local line = format(L["Map %d"], map) .. (mname and format(" (%s, %s)", mname, mtype) or "") ..
        format("  -  x %.1f  y %.1f", x, y)
      local pmap, px, py = API.GetPlayerPos()
      if pmap and pmap == map then
        line = line .. format(L["  (%d yd away)"], math.floor(math.sqrt((px - x) * (px - x) + (py - y) * (py - y)) + 0.5))
      end
      GameTooltip:AddLine(line, 0.5, 0.9, 0.5)
    else
      GameTooltip:AddLine(L["Position unknown - target the mob to record it"], 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
  end)
  nb:SetScript("OnLeave", function() GameTooltip:Hide() end)

  local guidText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  guidText:SetPoint("RIGHT", row, "RIGHT", -22, 0)
  row.guidText = guidText

  -- remove from pack
  local del = CreateFrame("Button", nil, row)
  del:SetWidth(16)
  del:SetHeight(16)
  del:SetPoint("RIGHT", row, "RIGHT", -2, 0)
  del:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
  del:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  del:SetScript("OnClick", function()
    if row.guid and state.pack then API.RemoveMob(state.zone, state.pack, row.guid) end
  end)
  del:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Remove from pack"], 1, 1, 1)
    GameTooltip:Show()
  end)
  del:SetScript("OnLeave", function() GameTooltip:Hide() end)

  row:Hide()
  return row
end

local function CreateGUI()
  local f = CreateFrame("Frame", "AutoMarkerEditor", UIParent)
  f:SetWidth(WIDTH)
  f:SetHeight(96 + ROWS * ROW_H + 92)
  f:SetFrameStrata("DIALOG")
  f:SetToplevel(true)
  f:EnableMouse(true)
  f:SetMovable(true)
  f:SetClampedToScreen(true)
  f:RegisterForDrag("LeftButton")
  f:SetScript("OnDragStart", function() this:StartMoving() end)
  f:SetScript("OnDragStop", function()
    this:StopMovingOrSizing()
    local point, _, relPoint, x, y = this:GetPoint()
    AutoMarkerDB.gui = { point = point, relPoint = relPoint, x = x, y = y }
  end)
  f:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  if AutoMarkerDB and AutoMarkerDB.gui and AutoMarkerDB.gui.x then
    f:ClearAllPoints()
    local g = AutoMarkerDB.gui
    f:SetPoint(g.point or "CENTER", UIParent, g.relPoint or "CENTER", g.x, g.y)
  end
  Skin(f, "frame")
  tinsert(UISpecialFrames, "AutoMarkerEditor") -- closes with Escape

  local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
  title:SetPoint("TOP", f, "TOP", 0, -16)
  title:SetText("AutoMarker - " .. L["Pack editor"])

  local close = CreateFrame("Button", nil, f, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", f, "TOPRIGHT", -6, -6)
  Skin(close, "close")

  f.zoneText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  f.zoneText:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -38)

  local follow = CreateFrame("CheckButton", "AutoMarkerEditorFollow", f, "UICheckButtonTemplate")
  follow:SetWidth(22)
  follow:SetHeight(22)
  follow:SetPoint("TOPRIGHT", f, "TOPRIGHT", -110, -32)
  getglobal("AutoMarkerEditorFollowText"):SetText(L["Follow target"])
  follow:SetScript("OnClick", function()
    API.Settings().guiFollowTarget = this:GetChecked() and true or false
    if API.Settings().guiFollowTarget then FollowTarget(true) end
  end)
  Skin(follow, "check")
  f.follow = follow

  -- pack selector
  local prev = CreateFrame("Button", nil, f)
  prev:SetWidth(24) prev:SetHeight(24)
  prev:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -54)
  prev:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up")
  prev:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down")
  prev:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  prev:SetScript("OnClick", function() CyclePack(-1) end)

  local nxt = CreateFrame("Button", nil, f)
  nxt:SetWidth(24) nxt:SetHeight(24)
  nxt:SetPoint("LEFT", prev, "RIGHT", 0, 0)
  nxt:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up")
  nxt:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down")
  nxt:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
  nxt:SetScript("OnClick", function() CyclePack(1) end)

  f.packText = f:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  f.packText:SetPoint("LEFT", nxt, "RIGHT", 6, 0)
  f.packText:SetJustifyH("LEFT")

  f.countText = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  f.countText:SetPoint("TOPLEFT", f, "TOPLEFT", 18, -80)

  -- rows
  local scroll = CreateFrame("ScrollFrame", "AutoMarkerEditorScroll", f, "FauxScrollFrameTemplate")
  scroll:SetPoint("TOPLEFT", f, "TOPLEFT", 16, -96)
  scroll:SetWidth(WIDTH - 50)
  scroll:SetHeight(ROWS * ROW_H)
  scroll:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(ROW_H, Refresh)
  end)
  f.scroll = scroll
  if pfUI and pfUI.api and pfUI.api.SkinScrollbar then
    pcall(pfUI.api.SkinScrollbar, getglobal("AutoMarkerEditorScrollScrollBar"))
  end

  f.rows = {}
  for i = 1, ROWS do f.rows[i] = CreateRow(f, i) end

  -- mouse wheel anywhere on the window scrolls the list
  f:EnableMouseWheel(true)
  f:SetScript("OnMouseWheel", function()
    local bar = getglobal("AutoMarkerEditorScrollScrollBar")
    if bar and scroll:IsShown() then bar:SetValue(bar:GetValue() - arg1 * ROW_H * 3) end
  end)

  -- bottom: name / rename
  local y = -96 - ROWS * ROW_H - 10
  local nameLabel = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
  nameLabel:SetPoint("TOPLEFT", f, "TOPLEFT", 18, y - 4)
  nameLabel:SetText(L["Name:"])

  local nameBox = CreateFrame("EditBox", "AutoMarkerEditorName", f, "InputBoxTemplate")
  nameBox:SetWidth(170)
  nameBox:SetHeight(20)
  nameBox:SetPoint("LEFT", nameLabel, "RIGHT", 10, 0)
  nameBox:SetAutoFocus(false)
  nameBox:SetMaxLetters(48)
  nameBox:SetScript("OnEditFocusGained", function() this.editing = true end)
  nameBox:SetScript("OnEditFocusLost", function() this.editing = false end)
  nameBox:SetScript("OnEnterPressed", function()
    this.editing = false
    this:ClearFocus()
    RenameFromBox()
  end)
  nameBox:SetScript("OnEscapePressed", function()
    this.editing = false
    this:ClearFocus()
    Refresh()
  end)
  f.nameBox = nameBox

  local renameBtn = Button(f, L["Rename"], 80, function() RenameFromBox() end,
    L["Rename the pack (custom packs only).\nPressing Enter in the field works too."])
  renameBtn:SetPoint("LEFT", nameBox, "RIGHT", 6, 0)

  f.resetBtn = Button(f, L["Delete"], 90, function() ResetPack() end,
    L["Default pack: discards your changes.\nCustom pack: deletes it."])
  f.resetBtn:SetPoint("LEFT", renameBtn, "RIGHT", 4, 0)

  -- bottom: actions
  y = y - 28
  f.markBtn = Button(f, L["Mark"], 70, function()
    API.MarkPack(state.zone, state.pack)
  end, L["Apply the pack marks to nearby mobs."])
  f.markBtn:SetPoint("TOPLEFT", f, "TOPLEFT", 16, y)

  local clearBtn = Button(f, L["Clear"], 64, function() API.ClearMarks() end, L["Remove all active marks."])
  clearBtn:SetPoint("LEFT", f.markBtn, "RIGHT", 4, 0)

  f.addBtn = Button(f, L["+ Target"], 64, function() AddTarget() end,
    L["Add the target to this pack (moves it out of its previous pack)."])
  f.addBtn:SetPoint("LEFT", clearBtn, "RIGHT", 4, 0)

  local newBtn = Button(f, L["New"], 70, function() NewPack() end,
    L["Create a custom pack (with the target if it is a creature)."])
  newBtn:SetPoint("LEFT", f.addBtn, "RIGHT", 4, 0)

  f.sweepBtn = Button(f, L["Sweep"], 86, function()
    local on, pack = API.GetSweep()
    if on and pack == state.pack then API.SetSweep(nil) else API.SetSweep(state.pack) end
    Refresh()
  end, L["Sweep mode: mouse over enemies to add them to this pack."])
  f.sweepBtn:SetPoint("LEFT", newBtn, "RIGHT", 4, 0)

  local hint = f:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
  hint:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 18, 14)
  hint:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -18, 14)
  hint:SetJustifyH("LEFT")
  hint:SetText(API.has_file_io and (L["Global settings file: "] .. API.file_name) or
    "|cffff8000" .. L["ExportFile unavailable: settings are saved per account only"] .. "|r")

  -- light periodic refresh (alive / in range colours)
  f.elapsed = 0
  f:SetScript("OnUpdate", function()
    this.elapsed = this.elapsed + arg1
    if this.elapsed > 1 then
      this.elapsed = 0
      if API.GetZone() ~= state.zone then FollowTarget(true) else Refresh() end
    end
  end)
  f:SetScript("OnShow", function()
    this.follow:SetChecked(API.Settings().guiFollowTarget)
    FollowTarget(true)
  end)

  f:Hide()
  return f
end

-- Public ----------------------------------------------------------------------

function AutoMarker_ToggleGUI()
  if not AutoMarkerDB then return end
  if not gui then gui = CreateGUI() end
  if gui:IsShown() then gui:Hide() else gui:Show() end
end

API.OnDataChanged = function() Refresh() end
API.OnTargetChanged = function() FollowTarget(false) end

-- Minimap button ----------------------------------------------------------------
-- Left-click: pack editor. Right-click: enable / disable automatic marking. Drag: move around the minimap.

local minimapButton

local function MinimapButton_UpdatePosition()
  local db = AutoMarkerDB.minimap
  local angle = math.rad(db.angle or 200)
  local x, y = math.cos(angle), math.sin(angle)
  local radius = 80
  if GetMinimapShape and GetMinimapShape() == "SQUARE" then
    -- square minimaps (pfUI...): project the circle onto the square
    local m = math.max(math.abs(x), math.abs(y))
    x, y = x / m, y / m
    radius = Minimap:GetWidth() / 2 + 6
  end
  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x * radius, y * radius)
end

local function MinimapButton_OnDragUpdate()
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  px, py = px / scale, py / scale
  AutoMarkerDB.minimap.angle = math.deg(math.atan2(py - my, px - mx))
  MinimapButton_UpdatePosition()
end

local function MinimapButton_Tooltip()
  GameTooltip:SetOwner(this, "ANCHOR_LEFT")
  GameTooltip:SetText("AutoMarker", 1, 0.82, 0)
  local enabled = API.Settings().enabled
  GameTooltip:AddLine(enabled and ("|cff00ff00" .. L["enabled"] .. "|r") or ("|cffff0000" .. L["disabled"] .. "|r"))
  GameTooltip:AddLine(L["Left-click: open the pack editor"], 1, 1, 1)
  GameTooltip:AddLine(L["Right-click: enable / disable automatic marking"], 1, 1, 1)
  GameTooltip:AddLine(L["Drag: move the button"], 0.7, 0.7, 0.7)
  GameTooltip:Show()
end

local function CreateMinimapButton()
  local b = CreateFrame("Button", "AutoMarkerMinimapButton", Minimap)
  b:SetWidth(31)
  b:SetHeight(31)
  b:SetFrameStrata("MEDIUM")
  b:SetFrameLevel(8)
  b:SetToplevel(true)
  b:SetMovable(true)
  b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
  b:RegisterForDrag("LeftButton")
  b:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

  local bg = b:CreateTexture(nil, "BACKGROUND")
  bg:SetWidth(20)
  bg:SetHeight(20)
  bg:SetPoint("TOPLEFT", b, "TOPLEFT", 7, -5)
  bg:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

  local icon = b:CreateTexture(nil, "ARTWORK")
  icon:SetWidth(18)
  icon:SetHeight(18)
  icon:SetPoint("TOPLEFT", b, "TOPLEFT", 7, -6)
  SetIconTexture(icon, 8) -- skull
  b.icon = icon

  local border = b:CreateTexture(nil, "OVERLAY")
  border:SetWidth(53)
  border:SetHeight(53)
  border:SetPoint("TOPLEFT", b, "TOPLEFT", 0, 0)
  border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

  b:SetScript("OnClick", function()
    if arg1 == "RightButton" then
      local s = API.Settings()
      s.enabled = not s.enabled
      API.Print(L["AutoMarker is now ["] .. (s.enabled and ("|cff00ff00" .. L["enabled"] .. "|r") or ("|cffff0000" .. L["disabled"] .. "|r")) .. "]")
      if s.enabled then this.icon:SetVertexColor(1, 1, 1) else this.icon:SetVertexColor(0.4, 0.4, 0.4) end
      if GameTooltip:IsOwned(this) then MinimapButton_Tooltip() end
    else
      AutoMarker_ToggleGUI()
    end
  end)
  b:SetScript("OnDragStart", function()
    GameTooltip:Hide()
    this:SetScript("OnUpdate", MinimapButton_OnDragUpdate)
  end)
  b:SetScript("OnDragStop", function()
    this:SetScript("OnUpdate", nil)
  end)
  b:SetScript("OnEnter", MinimapButton_Tooltip)
  b:SetScript("OnLeave", function() GameTooltip:Hide() end)

  if not API.Settings().enabled then icon:SetVertexColor(0.4, 0.4, 0.4) end
  return b
end

function AutoMarker_ToggleMinimapButton()
  if not minimapButton then return end
  local db = AutoMarkerDB.minimap
  db.hide = not db.hide
  if db.hide then minimapButton:Hide() else minimapButton:Show() end
  API.Print(L["Minimap button: "] .. (db.hide and ("|cffff0000" .. L["off"] .. "|r") or ("|cff00ff00" .. L["on"] .. "|r")))
end

local minimapLoader = CreateFrame("Frame")
minimapLoader:RegisterEvent("PLAYER_LOGIN")
minimapLoader:SetScript("OnEvent", function()
  if not AutoMarkerDB or not AutoMarkerDB.settings then return end
  AutoMarkerDB.minimap = AutoMarkerDB.minimap or { angle = 200, hide = false }
  minimapButton = CreateMinimapButton()
  MinimapButton_UpdatePosition()
  if AutoMarkerDB.minimap.hide then minimapButton:Hide() end
end)
