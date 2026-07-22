-- Tests/challenger_m2_1_harness.lua
-- Adversarial test harness for Engine/Automation.lua Priority Evaluator (Milestone 2)

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW API Environment
DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) end }

local registeredEvents = {}
local createdFrames = {}

function CreateFrame(frameType, name, parent, template)
  local frame = {
    events = {},
    scripts = {},
    RegisterEvent = function(self, evt)
      self.events[evt] = true
      registeredEvents[evt] = true
    end,
    SetScript = function(self, scriptType, fn)
      self.scripts[scriptType] = fn
    end,
    CreateFontString = function(self)
      local fs = { text = "", r=1, g=1, b=1 }
      function fs:SetText(t) self.text = t end
      function fs:SetTextColor(r,g,b) self.r=r; self.g=g; self.b=b end
      function fs:SetPoint() end
      return fs
    end,
    CreateTexture = function(self)
      return { SetSize=function() end, SetPoint=function() end, SetTexture=function() end, SetVertexColor=function() end }
    end,
    SetSize = function() end,
    SetPoint = function() end,
    SetBackdrop = function() end,
    SetBackdropColor = function() end,
    SetBackdropBorderColor = function() end,
    HasFocus = function() return false end,
    ClearFocus = function() end,
  }
  table.insert(createdFrames, frame)
  return frame
end

-- Mock WoW state
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
  accentBg = {0, 0.3, 0.5},
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
function XPRate.MakeButton() return CreateFrame() end
function XPRate.ShowTooltip() end
function XPRate.HideTooltip() end

-- Load Core/Config.lua & Engine/Automation.lua
local configChunk, err1 = loadfile("Core/Config.lua")
if not configChunk then error("Failed to load Core/Config.lua: " .. tostring(err1)) end
configChunk(addonName, XPRate)
XPRate.InitDB()

local autoChunk, err2 = loadfile("Engine/Automation.lua")
if not autoChunk then error("Failed to load Engine/Automation.lua: " .. tostring(err2)) end
autoChunk(addonName, XPRate)

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

local function resetState()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.isQuestNPCActive = false
  mockInInstance = false
  mockInstanceType = "none"
  mockPlayerLevel = 25
  mockGroupMembers = { player = { level = 25, connected = true } }
  mockRaidMembers = {}
  mockXPExhaustion = nil
  mockTarget = nil
  
  -- Disable all by default
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoRested = false
end

-- Helpers to activate specific triggers
local function activateQuest(rate)
  XPRateControlDB.autoQuest = true
  XPRateControlDB.questRate = rate or 2.00
  XPRate.isQuestNPCActive = true
end

local function activateZone(rate)
  XPRateControlDB.autoZone = true
  mockInInstance = true
  mockInstanceType = "party"
  XPRateControlDB.zoneRates = { dungeon = rate or 0.50 }
end

local function activateBracket(rate)
  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 25
  XPRateControlDB.bracketRates = {
    { min = 1, max = 59, rate = rate or 1.50 },
    { min = 60, max = 69, rate = rate or 1.50 },
    { min = 70, max = 79, rate = 1.00 },
    { min = 80, max = 80, rate = 0.00 },
  }
end

local function activateMob(rate)
  XPRateControlDB.autoMob = true
  mockTarget = { level = 25, canAttack = true, isDead = false, isPlayer = false } -- Yellow mob for lvl 25
  XPRateControlDB.mobRates = {
    gray = rate or 1.00,
    green = rate or 1.00,
    yellow = rate or 1.00,
    red = rate or 1.00,
  }
end

local function activateDisparity(rate, thresh)
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityThreshold = thresh or 5
  XPRateControlDB.disparityRate = rate or 0.25
  -- Keep existing group size if set, ensure disparity > threshold
  mockGroupMembers["player"] = { level = 20, connected = true }
  mockGroupMembers["party1"] = { level = 40, connected = true }
  mockPlayerLevel = 20
end

local function activateGroup(rate, size)
  XPRateControlDB.autoGroup = true
  -- If disparity is NOT active, keep levels equal. If disparity IS active, preserve the level gap.
  local hasDisparity = XPRateControlDB.autoDisparity
  local targetSize = size or 2
  for i = 1, targetSize do
    local k = (i == 1) and "player" or ("party" .. (i-1))
    if not mockGroupMembers[k] then
      mockGroupMembers[k] = { level = (hasDisparity and i > 1 and 40 or 20), connected = true }
    end
  end
  XPRateControlDB.groupRates = { [1]=1.0, [2]=rate or 1.25, [3]=rate or 1.25, [4]=rate or 1.25, [5]=rate or 1.25 }
end

local function activateRested(rate)
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = rate or 1.80
  mockXPExhaustion = 10000
end

print("==================================================")
print("  XPRateControl M2 Priority Evaluator Challenger   ")
print("==================================================")

-- Section 1: Comprehensive Pairwise Priority Matrix (21 Pairs)
test("1.1 Quest (2.00) vs Zone (0.50) -> Quest wins", function()
  resetState(); activateQuest(2.00); activateZone(0.50)
  XPRate.EvaluateAutomation(false, "Pair 1.1")
  assert_eq(appliedRates[1].rate, 2.00, "Quest wins over Zone")
end)

test("1.2 Quest (2.00) vs Bracket (1.50) -> Quest wins", function()
  resetState(); activateQuest(2.00); activateBracket(1.50)
  XPRate.EvaluateAutomation(false, "Pair 1.2")
  assert_eq(appliedRates[1].rate, 2.00, "Quest wins over Bracket")
end)

test("1.3 Quest (2.00) vs Mob (1.00) -> Quest wins", function()
  resetState(); activateQuest(2.00); activateMob(1.00)
  XPRate.EvaluateAutomation(false, "Pair 1.3")
  assert_eq(appliedRates[1].rate, 2.00, "Quest wins over Mob")
end)

test("1.4 Quest (2.00) vs Disparity (0.25) -> Quest wins", function()
  resetState(); activateQuest(2.00); activateDisparity(0.25)
  XPRate.EvaluateAutomation(false, "Pair 1.4")
  assert_eq(appliedRates[1].rate, 2.00, "Quest wins over Disparity")
end)

test("1.5 Quest (2.00) vs Party Size (1.25) -> Quest wins", function()
  resetState(); activateQuest(2.00); activateGroup(1.25)
  XPRate.EvaluateAutomation(false, "Pair 1.5")
  assert_eq(appliedRates[1].rate, 2.00, "Quest wins over Party Size")
end)

test("1.6 Quest (2.00) vs Rested (1.80) -> Quest wins", function()
  resetState(); activateQuest(2.00); activateRested(1.80)
  XPRate.EvaluateAutomation(false, "Pair 1.6")
  assert_eq(appliedRates[1].rate, 2.00, "Quest wins over Rested")
end)

test("1.7 Zone (0.50) vs Bracket (1.50) -> Zone wins", function()
  resetState(); activateZone(0.50); activateBracket(1.50)
  XPRate.EvaluateAutomation(false, "Pair 1.7")
  assert_eq(appliedRates[1].rate, 0.50, "Zone wins over Bracket")
end)

test("1.8 Zone (0.50) vs Mob (1.00) -> Zone wins", function()
  resetState(); activateZone(0.50); activateMob(1.00)
  XPRate.EvaluateAutomation(false, "Pair 1.8")
  assert_eq(appliedRates[1].rate, 0.50, "Zone wins over Mob")
end)

test("1.9 Zone (0.50) vs Disparity (0.25) -> Zone wins", function()
  resetState(); activateZone(0.50); activateDisparity(0.25)
  XPRate.EvaluateAutomation(false, "Pair 1.9")
  assert_eq(appliedRates[1].rate, 0.50, "Zone wins over Disparity")
end)

test("1.10 Zone (0.50) vs Party Size (1.25) -> Zone wins", function()
  resetState(); activateZone(0.50); activateGroup(1.25)
  XPRate.EvaluateAutomation(false, "Pair 1.10")
  assert_eq(appliedRates[1].rate, 0.50, "Zone wins over Party Size")
end)

test("1.11 Zone (0.50) vs Rested (1.80) -> Zone wins", function()
  resetState(); activateZone(0.50); activateRested(1.80)
  XPRate.EvaluateAutomation(false, "Pair 1.11")
  assert_eq(appliedRates[1].rate, 0.50, "Zone wins over Rested")
end)

test("1.12 Bracket (1.50) vs Mob (1.00) -> Bracket wins", function()
  resetState(); activateBracket(1.50); activateMob(1.00)
  XPRate.EvaluateAutomation(false, "Pair 1.12")
  assert_eq(appliedRates[1].rate, 1.50, "Bracket wins over Mob")
end)

test("1.13 Bracket (1.50) vs Disparity (0.25) -> Bracket wins", function()
  resetState(); activateBracket(1.50); activateDisparity(0.25)
  XPRate.EvaluateAutomation(false, "Pair 1.13")
  assert_eq(appliedRates[1].rate, 1.50, "Bracket wins over Disparity")
end)

test("1.14 Bracket (1.50) vs Party Size (1.25) -> Bracket wins", function()
  resetState(); activateBracket(1.50); activateGroup(1.25)
  XPRate.EvaluateAutomation(false, "Pair 1.14")
  assert_eq(appliedRates[1].rate, 1.50, "Bracket wins over Party Size")
end)

test("1.15 Bracket (1.50) vs Rested (1.80) -> Bracket wins", function()
  resetState(); activateBracket(1.50); activateRested(1.80)
  XPRate.EvaluateAutomation(false, "Pair 1.15")
  assert_eq(appliedRates[1].rate, 1.50, "Bracket wins over Rested")
end)

test("1.16 Mob (1.00) vs Disparity (0.25) -> Mob wins", function()
  resetState(); activateMob(1.00); activateDisparity(0.25)
  XPRate.EvaluateAutomation(false, "Pair 1.16")
  assert_eq(appliedRates[1].rate, 1.00, "Mob wins over Disparity")
end)

test("1.17 Mob (1.00) vs Party Size (1.25) -> Mob wins", function()
  resetState(); activateMob(1.00); activateGroup(1.25)
  XPRate.EvaluateAutomation(false, "Pair 1.17")
  assert_eq(appliedRates[1].rate, 1.00, "Mob wins over Party Size")
end)

test("1.18 Mob (1.00) vs Rested (1.80) -> Mob wins", function()
  resetState(); activateMob(1.00); activateRested(1.80)
  XPRate.EvaluateAutomation(false, "Pair 1.18")
  assert_eq(appliedRates[1].rate, 1.00, "Mob wins over Rested")
end)

test("1.19 Disparity (0.25) vs Party Size (1.25) -> Disparity wins", function()
  resetState(); activateDisparity(0.25); activateGroup(1.25)
  XPRate.EvaluateAutomation(false, "Pair 1.19")
  assert_eq(appliedRates[1].rate, 0.25, "Disparity wins over Party Size")
end)

test("1.20 Disparity (0.25) vs Rested (1.80) -> Disparity wins", function()
  resetState(); activateDisparity(0.25); activateRested(1.80)
  XPRate.EvaluateAutomation(false, "Pair 1.20")
  assert_eq(appliedRates[1].rate, 0.25, "Disparity wins over Rested")
end)

test("1.21 Party Size (1.25) vs Rested (1.80) -> Party Size wins", function()
  resetState(); activateGroup(1.25); activateRested(1.80)
  XPRate.EvaluateAutomation(false, "Pair 1.21")
  assert_eq(appliedRates[1].rate, 1.25, "Party Size wins over Rested")
end)

-- Section 2: All Active Simultaneously (Full Stack Test)
test("2.1 All 6 Tiers Active -> Quest wins top priority", function()
  resetState()
  activateQuest(2.00)
  activateZone(0.50)
  activateBracket(1.50)
  activateMob(1.00)
  activateDisparity(0.25)
  activateGroup(1.25)
  activateRested(1.80)

  XPRate.EvaluateAutomation(false, "Test 2.1 Full Stack")
  assert_eq(#appliedRates, 1, "Applied rate count")
  assert_eq(appliedRates[1].rate, 2.00, "Quest rate (2.00) wins top priority")
  assert_eq(XPRate.lastAppliedMode, "Quest Interaction", "Quest mode")
end)

-- Section 3: Stress Testing Fallthrough and Trapping Bugs
test("3.1 [BUG FIXED] Zone enabled with missing/nil zoneRate now falls through to lower active tiers", function()
  resetState()
  -- autoZone enabled, but zoneRates is missing 'world' key or zoneRates is nil
  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = { dungeon = 0.50 } -- 'world' is nil!
  mockInInstance = false
  mockInstanceType = "none" -- GetCurrentZoneType returns ("world", "Open World")

  -- Lower priority tier autoRested is enabled
  activateRested(1.80)

  XPRate.EvaluateAutomation(false, "Test 3.1 Zone Fallthrough Fix")
  
  -- Since Tier 2 condition checks db.zoneRates[XPRate.GetCurrentZoneType()] ~= nil,
  -- missing 'world' key causes condition to evaluate false, falling through to Tier 6 autoRested.
  assert_eq(#appliedRates, 1, "Rate applied via fallthrough to autoRested")
  assert_eq(appliedRates[1].rate, 1.80, "Rested rate applied")
end)

test("3.2 [BUG FIXED] Bracket enabled with level out of range now falls through to lower active tiers", function()
  resetState()
  -- autoBracket enabled, but player level is out of bracket range (e.g. level 99)
  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 99 -- GetMatchingLevelBracket(99) returns nil

  -- Lower priority tier autoRested is enabled
  activateRested(1.80)

  XPRate.EvaluateAutomation(false, "Test 3.2 Bracket Fallthrough Fix")
  
  -- Since Tier 3 condition checks GetMatchingLevelBracket(playerLevel) and bracket.rate ~= nil,
  -- level 99 out-of-range causes condition to evaluate false, falling through to Tier 6 autoRested.
  assert_eq(#appliedRates, 1, "Rate applied via fallthrough to autoRested")
  assert_eq(appliedRates[1].rate, 1.80, "Rested rate applied")
end)

test("3.3 Contrast: Mob enabled without target properly falls through to lower tiers", function()
  resetState()
  -- autoMob enabled, but no target present
  XPRateControlDB.autoMob = true
  mockTarget = nil -- GetUnitDifficultyCategory("target") returns nil

  -- Lower priority tier autoRested is enabled
  activateRested(1.80)

  XPRate.EvaluateAutomation(false, "Test 3.3 Mob Fallthrough")
  
  -- Since autoMob condition is `db.autoMob and mobCategory and ...`, 
  -- when mobCategory is nil, the condition is false, so it falls through!
  assert_eq(#appliedRates, 1, "Rate applied via fallthrough to autoRested")
  assert_eq(appliedRates[1].rate, 1.80, "Rested rate applied")
  assert_eq(XPRate.lastAppliedMode, "Auto Rested (Rested)")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
