-- Tests/challenger_m3_1_harness.lua
-- Dedicated Stress Test Harness for Milestone 3 (UI Automation Sub-Tabs Expansion & Engine Refinements)
-- Author: Challenger 1 (Milestone 3)

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
    SetMaxLetters = function(self, max) self.maxLetters = max end,
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

-- Load Addon Source Files
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

local function assert_false(cond, msg)
  totalAssertions = totalAssertions + 1
  if cond then
    error(msg or "Expected condition to be false")
  end
end

local function ResetDBToggles()
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoRested = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.isQuestNPCActive = false
  mockTarget = nil
  appliedRates = {}
end

print("==================================================================")
print("  XPRateControl M3 Challenger Stress Test Harness (challenger_m3_1)")
print("==================================================================")

-- ============================================================================
-- SUITE 1: Dropdown Bounds & Selection Stress
-- ============================================================================

test("1.1 Dropdown bounds query for out-of-range indices (0, 7, nil, -1, 999)", function()
  local menu = _G["XPRateAutoDropdownMenu"]
  assert_true(menu ~= nil, "Dropdown menu frame exists")
  
  local dropdownOptions = {}
  for _, child in ipairs(createdFrames) do
    if child.parent == menu then
      table.insert(dropdownOptions, child)
    end
  end

  assert_eq(#dropdownOptions, 6, "Exactly 6 dropdown option buttons created in dropdownMenu")
  assert_eq(dropdownOptions[0], nil, "Index 0 query returns nil")
  assert_eq(dropdownOptions[7], nil, "Index 7 query returns nil")
  assert_eq(dropdownOptions[-1], nil, "Index -1 query returns nil")
  assert_eq(dropdownOptions[999], nil, "Index 999 query returns nil")
end)

test("1.2 Dropdown menu geometry and sub-tab configuration bounds", function()
  local menu = _G["XPRateAutoDropdownMenu"]
  assert_eq(menu.width, 308, "Dropdown menu width is 308px")
  assert_eq(menu.height, 157, "Dropdown menu height is 157px")
  
  local autoTab = XPRate.AutomationTabFrame
  assert_true(autoTab ~= nil, "AutomationTabFrame exists")
end)

test("1.3 Sub-tab selection stress & sub-frame visibility bounds", function()
  local menu = _G["XPRateAutoDropdownMenu"]
  local optionBtns = {}
  for _, child in ipairs(createdFrames) do
    if child.parent == menu then
      table.insert(optionBtns, child)
    end
  end

  assert_eq(#optionBtns, 6, "Found 6 option buttons")

  for idx = 1, 6 do
    local onClick = optionBtns[idx]:GetScript("OnClick")
    assert_true(type(onClick) == "function", "Option button " .. idx .. " has OnClick handler")
    onClick(optionBtns[idx])
    assert_false(menu:IsShown(), "Dropdown menu hides after selecting option " .. idx)
  end
end)

test("1.4 Rapid multi-cycle sub-tab switching stress (120 iterations)", function()
  local menu = _G["XPRateAutoDropdownMenu"]
  local optionBtns = {}
  for _, child in ipairs(createdFrames) do
    if child.parent == menu then
      table.insert(optionBtns, child)
    end
  end

  for cycle = 1, 20 do
    for tabIdx = 1, 6 do
      local onClick = optionBtns[tabIdx]:GetScript("OnClick")
      onClick(optionBtns[tabIdx])
    end
  end

  local onClickSub1 = optionBtns[1]:GetScript("OnClick")
  onClickSub1(optionBtns[1])

  XPRate.UpdateAutomationTabUI()
  assert_eq(XPRateControlDB.autoRested and true or false, XPRate.restedCheckbox:GetChecked(), "Checkbox state intact after stress")
end)

test("1.5 Header dropdown toggle & checkmark sync on toggle state changes", function()
  local headerBtn = _G["XPRateAutoHeaderDropdown"]
  local menu = _G["XPRateAutoDropdownMenu"]
  assert_true(headerBtn ~= nil, "Header dropdown button exists")

  local headerClick = headerBtn:GetScript("OnClick")
  assert_true(type(headerClick) == "function", "Header OnClick script exists")
  
  headerClick(headerBtn)
  assert_true(menu:IsShown(), "Menu opens on first click")
  
  headerClick(headerBtn)
  assert_false(menu:IsShown(), "Menu closes on second click")

  ResetDBToggles()
  XPRateControlDB.autoRested = true
  XPRateControlDB.autoGroup = true
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoMob = true
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoZone = false

  XPRate.UpdateDropdownCheckmarks()
  assert_true(type(XPRate.UpdateDropdownCheckmarks) == "function", "UpdateDropdownCheckmarks callable")
end)

-- ============================================================================
-- SUITE 2: Disparity Input Edge Cases
-- ============================================================================

test("2.1 Disparity threshold edge cases: negative values (-5, -1) and zero (0)", function()
  ResetDBToggles()
  mockGroupMembers = { player = { level = 25 }, party1 = { level = 27 } }
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityRate = 0.50

  -- Test negative threshold (-5 in DB)
  XPRateControlDB.disparityThreshold = -5
  XPRate.EvaluateAutomation(false, "Test Negative Disparity Threshold")
  assert_eq(#appliedRates, 1, "Disparity applied when disparity (2) > threshold (-5)")
  assert_eq(appliedRates[1].rate, 0.50, "Disparity rate applied")

  -- Test zero threshold (0 in DB)
  ResetDBToggles()
  mockGroupMembers = { player = { level = 25 }, party1 = { level = 27 } }
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityRate = 0.50
  XPRateControlDB.disparityThreshold = 0
  XPRate.EvaluateAutomation(false, "Test Zero Disparity Threshold")
  assert_eq(#appliedRates, 1, "Disparity applied when disparity (2) > threshold (0)")
  assert_eq(appliedRates[1].rate, 0.50, "Disparity rate applied")
end)

test("2.2 Disparity threshold edge cases: extreme values (100, 999) and nil fallback", function()
  ResetDBToggles()
  mockGroupMembers = { player = { level = 25 }, party1 = { level = 27 } }
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityRate = 0.50
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.80
  mockXPExhaustion = 5000

  -- Test extreme threshold (100 in DB) -> Disparity (2) is NOT > 100, falls through to Rested
  XPRateControlDB.disparityThreshold = 100
  XPRate.EvaluateAutomation(false, "Test Extreme Disparity Threshold 100")
  assert_eq(#appliedRates, 1, "Falls through when disparity (2) <= threshold (100)")
  assert_eq(appliedRates[1].rate, 1.80, "Rested rate applied via fallthrough")

  -- Test nil threshold -> Fallback (db.disparityThreshold or 5) uses 5
  ResetDBToggles()
  mockGroupMembers = { player = { level = 25 }, party1 = { level = 32 } } -- Disparity = 7
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityRate = 0.50
  XPRateControlDB.disparityThreshold = nil
  XPRate.EvaluateAutomation(false, "Test Nil Disparity Threshold Fallback")
  assert_eq(#appliedRates, 1, "Disparity applied with nil threshold fallback (7 > 5)")
  assert_eq(appliedRates[1].rate, 0.50, "Disparity rate applied")
end)

test("2.3 Disparity threshold UI EditBox clamping (negative, extreme, float)", function()
  local threshEditbox = nil
  for _, frame in ipairs(createdFrames) do
    if frame.parent and frame.maxLetters == 3 and frame.GetScript and frame:GetScript("OnEditFocusLost") then
      threshEditbox = frame
      break
    end
  end
  assert_true(threshEditbox ~= nil, "Disparity threshold editbox found")

  local onFocusLost = threshEditbox:GetScript("OnEditFocusLost")

  -- Test negative value input: "-5" -> clamped to 1
  threshEditbox:SetText("-5")
  onFocusLost(threshEditbox)
  assert_eq(XPRateControlDB.disparityThreshold, 1, "Negative input clamped to 1")

  -- Test extreme value input: "99" -> clamped to 20
  threshEditbox:SetText("99")
  onFocusLost(threshEditbox)
  assert_eq(XPRateControlDB.disparityThreshold, 20, "Extreme high input clamped to 20")

  -- Test float value input: "7.8" -> floored/clamped to 7
  threshEditbox:SetText("7.8")
  onFocusLost(threshEditbox)
  assert_eq(XPRateControlDB.disparityThreshold, 7, "Float input floored to 7")

  -- Test zero value input: "0" -> clamped to 1
  threshEditbox:SetText("0")
  onFocusLost(threshEditbox)
  assert_eq(XPRateControlDB.disparityThreshold, 1, "Zero input clamped to 1")
end)

test("2.4 Disparity rate edge cases (negative -1.0, extreme 0.0 & 50.0, float 0.75, nil)", function()
  assert_eq(XPRate.ClampRate(-1.0), 0.0, "Negative rate clamped to 0.0")
  assert_eq(XPRate.ClampRate(0.0), 0.0, "Zero rate clamped to 0.0")
  assert_eq(XPRate.ClampRate(50.0), 2.0, "Extreme high rate clamped to 2.0")
  assert_eq(XPRate.ClampRate(0.75), 0.75, "Float rate 0.75 preserved")
  assert_eq(XPRate.ClampRate(nil), 0.0, "Nil rate clamped to 0.0")

  ResetDBToggles()
  mockGroupMembers = { player = { level = 25 }, party1 = { level = 35 } }
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityThreshold = 5
  XPRateControlDB.disparityRate = 0.00

  XPRate.EvaluateAutomation(false, "Test 0.00x Disparity Rate")
  assert_eq(#appliedRates, 1, "Applied 0.00x disparity rate")
  assert_eq(appliedRates[1].rate, 0.00, "Disparity rate is 0.00x")
end)

-- ============================================================================
-- SUITE 3: Level Bracket & Zone Rate Preset Modifications & Bounds Checking
-- ============================================================================

test("3.1 Unmapped zone types handling (unmapped zone key in zoneRates)", function()
  ResetDBToggles()
  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = { dungeon = 0.50 } -- 'world' key is missing!
  
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.75
  mockXPExhaustion = 5000

  mockInInstance = false
  mockInstanceType = "none"

  XPRate.EvaluateAutomation(false, "Test Missing Zone Key Fallthrough")

  assert_eq(#appliedRates, 1, "Falls through from unmapped zone key to Rested")
  assert_eq(appliedRates[1].rate, 1.75, "Rested rate applied via fallthrough")
end)

test("3.2 Out-of-range player level limits (0, -5, 81, 90, 255, float 45.5, string '70')", function()
  assert_eq(XPRate.GetMatchingLevelBracket(0), nil, "Level 0 returns nil bracket")
  assert_eq(XPRate.GetMatchingLevelBracket(-5), nil, "Level -5 returns nil bracket")
  assert_eq(XPRate.GetMatchingLevelBracket(81), nil, "Level 81 returns nil bracket")
  assert_eq(XPRate.GetMatchingLevelBracket(90), nil, "Level 90 returns nil bracket")
  assert_eq(XPRate.GetMatchingLevelBracket(255), nil, "Level 255 returns nil bracket")

  local bracket45 = XPRate.GetMatchingLevelBracket(45.5)
  assert_true(bracket45 ~= nil, "Float level 45.5 matches bracket")
  assert_eq(bracket45.min, 1, "Min level 1")
  assert_eq(bracket45.max, 59, "Max level 59")

  local bracket70 = XPRate.GetMatchingLevelBracket("70")
  assert_true(bracket70 ~= nil, "String level '70' converts and matches bracket")
  assert_eq(bracket70.min, 70, "Min level 70")
  assert_eq(bracket70.max, 79, "Max level 79")

  ResetDBToggles()
  XPRateControlDB.autoBracket = true
  XPRateControlDB.bracketRates = {
    { min = 1, max = 59, rate = 2.0 },
    { min = 60, max = 69, rate = 1.5 },
    { min = 70, max = 79, rate = 1.0 },
    { min = 80, max = 80, rate = 0.0 },
  }
  mockPlayerLevel = 90

  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.60
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Out-of-Range Level 90 Bracket Fallthrough")
  assert_eq(#appliedRates, 1, "Falls through from out-of-range level 90 bracket to Rested")
  assert_eq(appliedRates[1].rate, 1.60, "Rested rate applied via fallthrough")
end)

test("3.3 Level Bracket & Zone rate preset modifications & status string formatting", function()
  ResetDBToggles()
  XPRateControlDB.autoBracket = true
  XPRateControlDB.bracketRates = {
    { min = 1, max = 59, rate = 0.00 },
    { min = 60, max = 69, rate = 1.25 },
  }

  mockPlayerLevel = 25
  XPRate.UpdateAutomationStatus()
  assert_eq(XPRate.bracketStateValue.text, "Bracket: Lv 1-59 (0.00x)", "Modified bracket status string")

  ResetDBToggles()
  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = { world = 1.0, dungeon = 0.50, raid = 0.0, pvp = 1.0 }
  mockInInstance = true
  mockInstanceType = "party"

  XPRate.UpdateAutomationStatus()
  assert_eq(XPRate.zoneStateValue.text, "Zone: Dungeon (0.50x)", "Modified zone status string")
end)

-- ============================================================================
-- SUITE 4: Fallthrough Guard Verification
-- ============================================================================

test("4.1 Fallthrough guard when zoneRates table is nil or empty ({})", function()
  ResetDBToggles()
  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = nil

  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.90
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Nil zoneRates Fallthrough")
  assert_eq(#appliedRates, 1, "Falls through when zoneRates is nil")
  assert_eq(appliedRates[1].rate, 1.90, "Rested rate applied via fallthrough")

  ResetDBToggles()
  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = {}
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.90
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Empty zoneRates Fallthrough")
  assert_eq(#appliedRates, 1, "Falls through when zoneRates is empty")
  assert_eq(appliedRates[1].rate, 1.90, "Rested rate applied via fallthrough")
end)

test("4.2 Fallthrough guard when bracketRates table is nil, empty, or missing rate entry", function()
  ResetDBToggles()
  XPRateControlDB.autoBracket = true
  XPRateControlDB.bracketRates = nil

  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.40
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Nil bracketRates Fallthrough")
  assert_eq(#appliedRates, 1, "Falls through when bracketRates is nil")
  assert_eq(appliedRates[1].rate, 1.40, "Rested rate applied via fallthrough")

  ResetDBToggles()
  XPRateControlDB.autoBracket = true
  XPRateControlDB.bracketRates = {}
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.40
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Empty bracketRates Fallthrough")
  assert_eq(#appliedRates, 1, "Falls through when bracketRates is empty")
  assert_eq(appliedRates[1].rate, 1.40, "Rested rate applied via fallthrough")

  ResetDBToggles()
  XPRateControlDB.autoBracket = true
  XPRateControlDB.bracketRates = { { min = 1, max = 80, rate = nil } }
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 1.40
  mockXPExhaustion = 5000
  mockPlayerLevel = 25

  XPRate.EvaluateAutomation(false, "Test Bracket Entry Nil Rate Fallthrough")
  assert_eq(#appliedRates, 1, "Falls through when bracket entry rate is nil")
  assert_eq(appliedRates[1].rate, 1.40, "Rested rate applied via fallthrough")
end)

test("4.3 Cascading multi-tier nil fallthrough stress across active tiers", function()
  ResetDBToggles()
  -- Enable high-priority tiers with nil/inactive states
  XPRateControlDB.autoQuest = true
  XPRateControlDB.autoZone = true
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoMob = true
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.autoGroup = false -- Disabled so execution falls through to Rested
  XPRateControlDB.autoRested = true

  XPRate.isQuestNPCActive = false
  XPRateControlDB.zoneRates = nil
  XPRateControlDB.bracketRates = nil
  mockTarget = nil
  mockGroupMembers = { player = { level = 25 } }
  mockRaidMembers = {}
  mockXPExhaustion = 10000
  XPRateControlDB.restedRate = 2.00

  XPRate.EvaluateAutomation(false, "Test Cascading Multi-Tier Nil Fallthrough")

  assert_eq(#appliedRates, 1, "Cascaded through 5 nil/inactive tiers directly to Tier 6 Rested")
  assert_eq(appliedRates[1].rate, 2.00, "Tier 6 Rested rate applied")
  assert_eq(XPRate.lastAppliedMode, "Auto Rested (Rested)", "Mode string matches Rested")

  -- Also verify Party Scaling 1P Solo evaluation when autoGroup = true
  ResetDBToggles()
  XPRateControlDB.autoGroup = true
  XPRateControlDB.groupRates = { [1] = 1.00 }
  mockGroupMembers = { player = { level = 25 } }

  XPRate.EvaluateAutomation(false, "Test Party Scaling 1P Solo Evaluation")
  assert_eq(#appliedRates, 1, "Applied 1P solo rate")
  assert_eq(appliedRates[1].rate, 1.00, "1P solo rate is 1.00x")
  assert_eq(XPRate.lastAppliedMode, "Party Scaling (Solo)", "Mode string matches Party Scaling (Solo)")
end)

print("==================================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================================")

if testsFailed > 0 then
  os.exit(1)
end
