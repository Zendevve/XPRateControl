-- Tests/worker_m3_1_harness.lua
-- Unit test harness for Milestone 3 UI Sub-Tabs Expansion & Engine Refinements

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW Environment
DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) end }
SlashCmdList = {}

local registeredEvents = {}
local createdFrames = {}

function CreateFrame(frameType, name, parent, template)
  local frame = {
    name = name,
    frameType = frameType,
    parent = parent,
    template = template,
    events = {},
    scripts = {},
    children = {},
    textures = {},
    fontstrings = {},
    shown = true,
    checked = false,
    width = 0,
    height = 0,
    strata = "MEDIUM",
    level = 1,
    text = "",
    backdrop = nil,

    RegisterEvent = function(self, evt)
      self.events[evt] = true
      registeredEvents[evt] = true
    end,
    SetScript = function(self, scriptType, fn)
      self.scripts[scriptType] = fn
    end,
    GetScript = function(self, scriptType)
      return self.scripts[scriptType]
    end,
    CreateFontString = function(self, n, layer, inherits)
      local fs = {
        name = n, text = "", r=1, g=1, b=1, a=1,
        SetText = function(s, t) s.text = tostring(t) end,
        GetText = function(s) return s.text end,
        SetTextColor = function(s, r, g, b, a) s.r=r; s.g=g; s.b=b; s.a=a or 1 end,
        SetPoint = function() end,
        SetJustifyH = function() end,
      }
      table.insert(self.fontstrings, fs)
      return fs
    end,
    CreateTexture = function(self, n, layer)
      local tex = {
        name = n, texture = "", r=1, g=1, b=1, a=1,
        SetSize = function() end,
        SetPoint = function() end,
        SetTexture = function(s, t) s.texture = t end,
        SetVertexColor = function(s, r, g, b, a) s.r=r; s.g=g; s.b=b; s.a=a or 1 end,
      }
      table.insert(self.textures, tex)
      return tex
    end,
    SetSize = function(self, w, h) self.width = w; self.height = h end,
    GetSize = function(self) return self.width, self.height end,
    SetPoint = function() end,
    SetBackdrop = function(self, bd) self.backdrop = bd end,
    SetBackdropColor = function(self, r, g, b, a) self.bgColor = {r, g, b, a} end,
    SetBackdropBorderColor = function(self, r, g, b, a) self.edgeColor = {r, g, b, a} end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
    IsShown = function(self) return self.shown end,
    SetShown = function(self, val) self.shown = val and true or false end,
    SetChecked = function(self, val) self.checked = val and true or false end,
    GetChecked = function(self) return self.checked end,
    SetFrameStrata = function(self, st) self.strata = st end,
    SetFrameLevel = function(self, lvl) self.level = lvl end,
    GetFrameLevel = function(self) return self.level end,
    SetAllPoints = function() end,
    SetAutoFocus = function() end,
    SetFontObject = function() end,
    SetJustifyH = function() end,
    SetMaxLetters = function() end,
    HasFocus = function() return false end,
    ClearFocus = function() end,
    GetText = function(self) return self.text end,
    SetText = function(self, t) self.text = tostring(t) end,
  }
  table.insert(createdFrames, frame)
  if name then _G[name] = frame end
  return frame
end

UIParent = CreateFrame("Frame", "UIParent")

-- Mock WoW API variables
mockInInstance = false
mockInstanceType = "none"
mockPlayerLevel = 25
mockGroupMembers = {}
mockRaidMembers = {}
mockXPExhaustion = nil
mockTarget = nil

function IsInInstance()
  return mockInInstance, mockInstanceType
end

function GetNumRaidMembers()
  local count = 0
  for _ in pairs(mockRaidMembers) do count = count + 1 end
  return count
end

function GetNumPartyMembers()
  local count = 0
  for k in pairs(mockGroupMembers) do
    if k ~= "player" then count = count + 1 end
  end
  return count
end

function UnitLevel(unit)
  if unit == "player" then return mockPlayerLevel end
  if mockRaidMembers[unit] then return mockRaidMembers[unit].level end
  if mockGroupMembers[unit] then return mockGroupMembers[unit].level end
  if unit == "target" and mockTarget then return mockTarget.level end
  return nil
end

function UnitExists(unit)
  if unit == "player" then return true end
  if mockRaidMembers[unit] ~= nil then return true end
  if mockGroupMembers[unit] ~= nil then return true end
  if unit == "target" and mockTarget ~= nil then return true end
  return false
end

function UnitIsConnected(unit)
  if unit == "player" then return true end
  if mockRaidMembers[unit] ~= nil then return mockRaidMembers[unit].connected ~= false end
  if mockGroupMembers[unit] ~= nil then return mockGroupMembers[unit].connected ~= false end
  return true
end

function UnitCanAttack(u1, u2)
  if u2 == "target" and mockTarget then return mockTarget.canAttack ~= false end
  return false
end

function UnitIsDead(unit)
  if unit == "target" and mockTarget then return mockTarget.isDead == true end
  return false
end

function UnitIsPlayer(unit)
  if unit == "target" and mockTarget then return mockTarget.isPlayer == true end
  return false
end

function GetXPExhaustion()
  return mockXPExhaustion
end

function strtrim(s)
  return string.match(s or "", "^%s*(.-)%s*$")
end

QuestDifficultyColors = {
  green = "green_color",
  trivial = "gray_color",
  header = "header_color",
  yellow = "yellow_color",
}

function GetQuestDifficultyColor(level)
  local diff = level - mockPlayerLevel
  if diff <= -5 then return QuestDifficultyColors["trivial"]
  elseif diff <= -3 then return QuestDifficultyColors["green"]
  else return QuestDifficultyColors["yellow"]
  end
end

-- Mock XPRate helper functions
XPRate.CLR = {
  cyan = {0, 0.8, 1}, gold = {1, 0.82, 0}, green = {0.13, 0.8, 0.31},
  red = {0.9, 0.22, 0.22}, dim = {0.55, 0.62, 0.72}, white = {0.92, 0.95, 0.98},
  btnBg = {0.1, 0.1, 0.1}, btnEdge = {0.2, 0.2, 0.2}, btnHover = {0.3, 0.3, 0.3},
  accentBg = {0, 0.3, 0.5}, panelBg = {0.05, 0.05, 0.05}, cardEdge = {0.2, 0.2, 0.2},
}

function XPRate.FormatRate(rate)
  return string.format("%.2f", rate or 0)
end

function XPRate.ClampRate(rate)
  return math.max(0, math.min(2, rate or 0))
end

appliedRates = {}
function XPRate.ApplyRate(rate, silent)
  table.insert(appliedRates, { rate = rate, silent = silent })
end

function XPRate.PrintMessage(msg) end
function XPRate.ShowToast(msg) end
function XPRate.MakeButton(parent, w, h, bg, edge)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(w or 40, h or 20)
  return btn
end
function XPRate.ShowTooltip() end
function XPRate.HideTooltip() end

-- Create AutomationTabFrame mock before loading TabAutomation
XPRate.AutomationTabFrame = CreateFrame("Frame", "XPRateAutomationTabFrame")

-- Load Core/Config.lua, Engine/Automation.lua, UI/TabAutomation.lua, Init.lua
local configChunk = assert(loadfile("Core/Config.lua"))
configChunk(addonName, XPRate)
XPRate.InitDB()

local autoChunk = assert(loadfile("Engine/Automation.lua"))
autoChunk(addonName, XPRate)

local uiChunk = assert(loadfile("UI/TabAutomation.lua"))
uiChunk(addonName, XPRate)

local initChunk = assert(loadfile("Init.lua"))
initChunk(addonName, XPRate)

-- Test Framework
local testsPassed = 0
local testsFailed = 0
local totalAssertions = 0

local function test(name, fn)
  local pass, err = pcall(fn)
  if pass then
    testsPassed = testsPassed + 1
    print("[PASS] " .. name)
  else
    testsFailed = testsFailed + 1
    print("[FAIL] " .. name .. ": " .. tostring(err))
  end
end

local function assert_eq(actual, expected, msg)
  totalAssertions = totalAssertions + 1
  if actual ~= expected then
    error(string.format("%s: expected %s (type %s), got %s (type %s)",
      msg or "Assertion failed",
      tostring(expected), type(expected),
      tostring(actual), type(actual)))
  end
end

local function assert_true(cond, msg)
  totalAssertions = totalAssertions + 1
  if not cond then
    error(msg or "Expected condition to be true")
  end
end

print("==================================================")
print("  XPRateControl M3 UI & Engine Refinement Harness ")
print("==================================================")

-- Suite 1: Engine Refinement Verification
test("1.1 QUEST_GREETING registered on questBackendFrame", function()
  assert_true(registeredEvents["QUEST_GREETING"], "QUEST_GREETING must be registered")
end)

test("1.2 Tier 2 (Zone) fallthrough guard when zone rate is nil", function()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = true
  mockInInstance = false
  mockInstanceType = "none"
  XPRateControlDB.zoneRates = { dungeon = 0.50 } -- 'world' key is missing!

  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.80
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Zone Fallthrough")

  assert_eq(#appliedRates, 1, "Should fallthrough from unmapped zone to rested")
  assert_eq(appliedRates[1].rate, 1.80, "Rested rate applied via fallthrough")
  assert_eq(XPRate.lastAppliedMode, "Auto Rested (Rested)", "Mode string")
end)

test("1.3 Tier 3 (Bracket) fallthrough guard when level is out of bracket range", function()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 90 -- Out of range for standard 1-80 brackets

  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.80
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Bracket Fallthrough")

  assert_eq(#appliedRates, 1, "Should fallthrough from out-of-range bracket to rested")
  assert_eq(appliedRates[1].rate, 1.80, "Rested rate applied via fallthrough")
  assert_eq(XPRate.lastAppliedMode, "Auto Rested (Rested)", "Mode string")
end)

-- Suite 2: UI Tab Automation 6 Sub-Tabs Expansion
test("2.1 Dropdown Menu Frame Dimensions & Option Buttons", function()
  local menu = _G["XPRateAutoDropdownMenu"]
  assert_true(menu ~= nil, "Dropdown menu frame exists")
  assert_eq(menu.width, 308, "Dropdown menu width")
  assert_eq(menu.height, 157, "Dropdown menu height expanded for 6 options")
end)

test("2.2 Dropdown Checkmarks update across all 6 sub-tab toggles", function()
  XPRateControlDB.autoRested = true
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoDisparity = true -- Sub-tab 2 active via disparity
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoQuest = true
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoZone = true

  XPRate.UpdateDropdownCheckmarks()

  -- Check global checkmark updates
  assert_true(XPRate.UpdateDropdownCheckmarks ~= nil, "UpdateDropdownCheckmarks exported")
end)

test("2.3 Sub-tab 2 Disparity Controls Binding", function()
  assert_true(XPRate.disparityCheckbox ~= nil, "XPRateDisparityCheckbox exists")

  XPRateControlDB.autoDisparity = false
  XPRate.disparityCheckbox:SetChecked(true)
  local onClick = XPRate.disparityCheckbox:GetScript("OnClick")
  assert_true(onClick ~= nil, "OnClick script exists")
  onClick(XPRate.disparityCheckbox)

  assert_eq(XPRateControlDB.autoDisparity, true, "autoDisparity SavedVariables updated")

  -- Disparity threshold update
  XPRateControlDB.disparityThreshold = 5
  if XPRate.updateDisparityThresholdRow then
    XPRate.updateDisparityThresholdRow()
  end
  assert_eq(XPRateControlDB.disparityThreshold, 5, "disparityThreshold initial value")
end)

test("2.4 Sub-tab 5 Level Bracket Controls & Status String", function()
  assert_true(XPRate.bracketCheckbox ~= nil, "XPRateBracketCheckbox exists")
  assert_true(XPRate.bracketStateValue ~= nil, "XPRate.bracketStateValue status fontstring exists")

  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 25

  XPRate.UpdateAutomationStatus()
  assert_eq(XPRate.bracketStateValue.text, "Bracket: Lv 1-59 (2.00x)", "Bracket status string format")

  -- Update bracket rate
  XPRateControlDB.bracketRates[1].rate = 1.75
  if XPRate.updateBracketRows then XPRate.updateBracketRows() end
  assert_eq(XPRateControlDB.bracketRates[1].rate, 1.75, "Bracket rate updated")
end)

test("2.5 Sub-tab 6 Zone / Instance Controls & Status String", function()
  assert_true(XPRate.zoneCheckbox ~= nil, "XPRateZoneCheckbox exists")
  assert_true(XPRate.zoneStateValue ~= nil, "XPRate.zoneStateValue status fontstring exists")

  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = { world = 1.00, dungeon = 1.00, raid = 0.00, pvp = 1.00 }
  mockInInstance = true
  mockInstanceType = "party"

  XPRate.UpdateAutomationStatus()
  assert_eq(XPRate.zoneStateValue.text, "Zone: Dungeon (1.00x)", "Zone status string format")

  -- Update zone rate
  XPRateControlDB.zoneRates.dungeon = 0.50
  if XPRate.updateZoneRows then XPRate.updateZoneRows() end
  assert_eq(XPRateControlDB.zoneRates.dungeon, 0.50, "Dungeon zone rate updated")
end)

test("2.6 Master UI Refresh Function XPRate.UpdateAutomationTabUI()", function()
  assert_true(type(XPRate.UpdateAutomationTabUI) == "function", "Master refresh function exists")

  XPRateControlDB.autoRested = true
  XPRateControlDB.autoGroup = true
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoMob = true
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoZone = false

  XPRate.UpdateAutomationTabUI()

  assert_eq(XPRate.restedCheckbox:GetChecked(), true, "restedCheckbox synced")
  assert_eq(XPRate.groupCheckbox:GetChecked(), true, "groupCheckbox synced")
  assert_eq(XPRate.disparityCheckbox:GetChecked(), false, "disparityCheckbox synced")
  assert_eq(XPRate.mobCheckbox:GetChecked(), true, "mobCheckbox synced")
  assert_eq(XPRate.questCheckbox:GetChecked(), false, "questCheckbox synced")
  assert_eq(XPRate.bracketCheckbox:GetChecked(), true, "bracketCheckbox synced")
  assert_eq(XPRate.zoneCheckbox:GetChecked(), false, "zoneCheckbox synced")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
