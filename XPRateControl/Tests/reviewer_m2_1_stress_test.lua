-- Tests/reviewer_m2_1_stress_test.lua
-- Adversarial stress test for Engine/Automation.lua (Milestone 2)

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

mockInInstance = false
mockInstanceType = "none"
mockPlayerLevel = 1
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

-- Mock XPRate helper functions
XPRate.CLR = {
  cyan = {0, 0.8, 1},
  gold = {1, 0.82, 0},
  green = {0.13, 0.8, 0.31},
  red = {0.9, 0.22, 0.22},
  dim = {0.55, 0.62, 0.72},
  white = {0.92, 0.95, 0.98},
  btnBg = {0.1, 0.1, 0.1},
  btnEdge = {0.2, 0.2, 0.2},
  btnHover = {0.3, 0.3, 0.3},
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

local configChunk = assert(loadfile("Core/Config.lua"))
configChunk(addonName, XPRate)
XPRate.InitDB()

local autoChunk = assert(loadfile("Engine/Automation.lua"))
autoChunk(addonName, XPRate)

local testsPassed = 0
local testsFailed = 0

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
  if actual ~= expected then
    error(string.format("%s: expected %s, got %s", msg or "Assertion failed", tostring(expected), tostring(actual)))
  end
end

print("==================================================")
print("  Adversarial Edge Case Stress Test               ")
print("==================================================")

test("Edge Case 1: IsInInstance returns unexpected instanceType", function()
  mockInInstance = true
  mockInstanceType = "unknown_custom_type"
  local zType, zLabel = XPRate.GetCurrentZoneType()
  assert_eq(zType, "world", "Unknown instance type fallback")
  assert_eq(zLabel, "Open World", "Unknown instance label fallback")
end)

test("Edge Case 2: GetMatchingLevelBracket handles string level and corrupted bracket DB", function()
  XPRateControlDB.bracketRates = {
    "not_a_table",
    { min = "10", max = "20", rate = 1.2 },
    { min = 21, max = 30, rate = 1.5 }
  }
  local bracket, index = XPRate.GetMatchingLevelBracket("15")
  assert_eq(index, 2, "String level '15' matched index 2")
  assert_eq(bracket.rate, 1.2, "Matched rate 1.2")
end)

test("Edge Case 3: GetMaxPartyLevelDisparity with offline raid members and level 0", function()
  mockPlayerLevel = 40
  mockRaidMembers = {
    raid1 = { level = 80, connected = false },
    raid2 = { level = 45, connected = true },
    raid3 = { level = 35, connected = true },
    raid4 = { level = 0, connected = true }, -- invalid level 0 ignored
  }
  local disp, minL, maxL = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disp, 10, "Disparity is 45 - 35 = 10")
  assert_eq(minL, 35, "Min level 35")
  assert_eq(maxL, 45, "Max level 45")
end)

test("Edge Case 4: Mob difficulty for Skull/Boss mob (level -1)", function()
  mockPlayerLevel = 80
  mockTarget = { level = -1, canAttack = true, isDead = false, isPlayer = false }
  local cat, label = XPRate.GetUnitDifficultyCategory("target")
  assert_eq(cat, "red", "Boss mob level -1 is red")
  assert_eq(label, "Orange / Red", "Boss mob label")
end)

test("Edge Case 5: EvaluateAutomation rate change deduplication tolerance", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = 1.00
  XPRate.lastAppliedMode = "Auto Rested (Normal)"
  XPRateControlDB.autoRested = true
  XPRateControlDB.normalRate = 1.0001 -- extremely close to 1.00

  XPRate.EvaluateAutomation(false, "Test deduplication")
  assert_eq(#appliedRates, 0, "No re-application when rate difference < 0.005 and mode unchanged")
end)

print("==================================================")
print(string.format("  Stress Test Summary: %d Passed, %d Failed", testsPassed, testsFailed))
print("==================================================")

if testsFailed > 0 then os.exit(1) end
