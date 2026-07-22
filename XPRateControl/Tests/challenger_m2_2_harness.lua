-- Tests/challenger_m2_2_harness.lua
-- Empirical Challenger test suite for Automation.lua helper functions (Milestone 2)

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW API Environment
DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) end }

local createdFrames = {}
function CreateFrame(frameType, name, parent, template)
  local frame = {
    events = {},
    scripts = {},
    RegisterEvent = function(self, evt) self.events[evt] = true end,
    SetScript = function(self, scriptType, fn) self.scripts[scriptType] = fn end,
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

-- Global Mocks
mockInInstance = false
mockInstanceType = "none"
mockPlayerLevel = 1
mockGroupMembers = {} -- e.g. { player = { level = 10, connected = true }, party1 = { level = 15, connected = true } }
mockRaidMembers = {}

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
  return nil
end

function UnitExists(unit)
  if unit == "player" then return true end
  if mockRaidMembers[unit] ~= nil then return true end
  if mockGroupMembers[unit] ~= nil then return true end
  return false
end

function UnitIsConnected(unit)
  if unit == "player" then return true end
  if mockRaidMembers[unit] ~= nil then return mockRaidMembers[unit].connected ~= false end
  if mockGroupMembers[unit] ~= nil then return mockGroupMembers[unit].connected ~= false end
  return true
end

-- Mock XPRate prerequisites
XPRate.CLR = {
  cyan = {0, 0.8, 1}, gold = {1, 0.82, 0}, green = {0.13, 0.8, 0.31}, red = {0.9, 0.22, 0.22}, dim = {0.55, 0.62, 0.72}, white = {0.92, 0.95, 0.98}
}
function XPRate.FormatRate(rate) return string.format("%.2f", rate or 0) end
function XPRate.ClampRate(rate) return math.max(0, math.min(2, rate or 0)) end
function XPRate.ApplyRate() end
function XPRate.PrintMessage() end
function XPRate.ShowToast() end
function XPRate.MakeButton() return CreateFrame() end
function XPRate.ShowTooltip() end
function XPRate.HideTooltip() end

-- Load Core/Config.lua & InitDB
local configChunk, err = loadfile("Core/Config.lua")
if not configChunk then error("Failed to load Core/Config.lua: " .. tostring(err)) end
configChunk(addonName, XPRate)
XPRate.InitDB()

-- Load Engine/Automation.lua
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

local function assert_nil(val, msg)
  totalAssertions = totalAssertions + 1
  if val ~= nil then
    error(string.format("%s: expected nil, got %s (type %s)",
      msg or "Assertion failed",
      tostring(val), type(val)))
  end
end

print("==================================================")
print("  XPRateControl M2 Challenger Helper Suite        ")
print("==================================================")

--------------------------------------------------------------------------------
-- 1. GetCurrentZoneType Empirical Verification
--------------------------------------------------------------------------------
test("1.1 GetCurrentZoneType: 'party' mapping", function()
  mockInInstance = true
  mockInstanceType = "party"
  local cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "dungeon", "Zone category for party")
  assert_eq(label, "Dungeon", "Zone label for party")
end)

test("1.2 GetCurrentZoneType: 'raid' mapping", function()
  mockInInstance = true
  mockInstanceType = "raid"
  local cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "raid", "Zone category for raid")
  assert_eq(label, "Raid", "Zone label for raid")
end)

test("1.3 GetCurrentZoneType: 'pvp' mapping", function()
  mockInInstance = true
  mockInstanceType = "pvp"
  local cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "pvp", "Zone category for pvp")
  assert_eq(label, "Battleground / Arena", "Zone label for pvp")
end)

test("1.4 GetCurrentZoneType: 'arena' mapping", function()
  mockInInstance = true
  mockInstanceType = "arena"
  local cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "pvp", "Zone category for arena")
  assert_eq(label, "Battleground / Arena", "Zone label for arena")
end)

test("1.5 GetCurrentZoneType: 'none' mapping", function()
  mockInInstance = true
  mockInstanceType = "none"
  local cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "world", "Zone category for none instanceType")
  assert_eq(label, "Open World", "Zone label for none instanceType")

  mockInInstance = false
  mockInstanceType = "none"
  cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "world", "Zone category for mockInInstance=false")
  assert_eq(label, "Open World", "Zone label for mockInInstance=false")
end)

test("1.6 GetCurrentZoneType: nil instanceType / nil IsInInstance", function()
  mockInInstance = true
  mockInstanceType = nil
  local cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "world", "Zone category for nil instanceType")
  assert_eq(label, "Open World", "Zone label for nil instanceType")

  -- Test missing IsInInstance global function
  local origIsInInstance = IsInInstance
  IsInInstance = nil
  cat, label = XPRate.GetCurrentZoneType()
  assert_eq(cat, "world", "Zone category when IsInInstance is nil")
  assert_eq(label, "Open World", "Zone label when IsInInstance is nil")
  IsInInstance = origIsInInstance
end)

test("1.7 GetCurrentZoneType alias GetZoneCategory", function()
  assert_eq(XPRate.GetZoneCategory, XPRate.GetCurrentZoneType, "GetZoneCategory is alias for GetCurrentZoneType")
end)

--------------------------------------------------------------------------------
-- 2. GetMatchingLevelBracket Empirical Verification
--------------------------------------------------------------------------------
test("2.1 GetMatchingLevelBracket: Level 1", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(1)
  assert_eq(idx, 1, "Bracket index for Level 1")
  assert_eq(b.min, 1, "Bracket min")
  assert_eq(b.max, 59, "Bracket max")
  assert_eq(b.rate, 2.00, "Bracket rate")
end)

test("2.2 GetMatchingLevelBracket: Level 59", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(59)
  assert_eq(idx, 1, "Bracket index for Level 59")
  assert_eq(b.min, 1, "Bracket min")
  assert_eq(b.max, 59, "Bracket max")
end)

test("2.3 GetMatchingLevelBracket: Level 60", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(60)
  assert_eq(idx, 2, "Bracket index for Level 60")
  assert_eq(b.min, 60, "Bracket min")
  assert_eq(b.max, 69, "Bracket max")
  assert_eq(b.rate, 1.50, "Bracket rate")
end)

test("2.4 GetMatchingLevelBracket: Level 69", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(69)
  assert_eq(idx, 2, "Bracket index for Level 69")
  assert_eq(b.min, 60, "Bracket min")
  assert_eq(b.max, 69, "Bracket max")
end)

test("2.5 GetMatchingLevelBracket: Level 70", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(70)
  assert_eq(idx, 3, "Bracket index for Level 70")
  assert_eq(b.min, 70, "Bracket min")
  assert_eq(b.max, 79, "Bracket max")
  assert_eq(b.rate, 1.00, "Bracket rate")
end)

test("2.6 GetMatchingLevelBracket: Level 79", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(79)
  assert_eq(idx, 3, "Bracket index for Level 79")
  assert_eq(b.min, 70, "Bracket min")
  assert_eq(b.max, 79, "Bracket max")
end)

test("2.7 GetMatchingLevelBracket: Level 80", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(80)
  assert_eq(idx, 4, "Bracket index for Level 80")
  assert_eq(b.min, 80, "Bracket min")
  assert_eq(b.max, 80, "Bracket max")
  assert_eq(b.rate, 0.00, "Bracket rate")
end)

test("2.8 GetMatchingLevelBracket: Level 81 (out of range)", function()
  XPRate.InitDB()
  local b, idx = XPRate.GetMatchingLevelBracket(81)
  assert_nil(b, "Bracket for Level 81 should be nil")
  assert_nil(idx, "Bracket index for Level 81 should be nil")
end)

test("2.9 GetMatchingLevelBracket: Type conversions and missing DB edge cases", function()
  XPRate.InitDB()
  mockPlayerLevel = 65
  local b1, idx1 = XPRate.GetMatchingLevelBracket(nil) -- defaults to UnitLevel("player")=65
  assert_eq(idx1, 2, "Nil level defaults to player level 65")

  local b2, idx2 = XPRate.GetMatchingLevelBracket("75") -- string number coerced
  assert_eq(idx2, 3, "String '75' coerced to 75")

  local b3, idx3 = XPRate.GetMatchingLevelBracket("invalid") -- string non-number coerced to 1
  assert_eq(idx3, 1, "String 'invalid' coerced to 1")

  -- DB nil or missing bracketRates
  local saveDB = XPRateControlDB
  XPRateControlDB = nil
  assert_nil(XPRate.GetMatchingLevelBracket(50), "Returns nil if DB is nil")
  XPRateControlDB = { bracketRates = "invalid" }
  assert_nil(XPRate.GetMatchingLevelBracket(50), "Returns nil if bracketRates is non-table")
  XPRateControlDB = saveDB
end)

--------------------------------------------------------------------------------
-- 3. GetMaxPartyLevelDisparity Empirical Verification
--------------------------------------------------------------------------------
test("3.1 GetMaxPartyLevelDisparity: Solo", function()
  mockPlayerLevel = 80
  mockRaidMembers = {}
  mockGroupMembers = { player = { level = 80, connected = true } }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 0, "Solo disparity")
  assert_eq(minLvl, 80, "Solo min level")
  assert_eq(maxLvl, 80, "Solo max level")
end)

test("3.2 GetMaxPartyLevelDisparity: Party Gap 0", function()
  mockPlayerLevel = 80
  mockRaidMembers = {}
  mockGroupMembers = {
    player = { level = 80, connected = true },
    party1 = { level = 80, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 0, "Gap 0 disparity")
  assert_eq(minLvl, 80, "Gap 0 min level")
  assert_eq(maxLvl, 80, "Gap 0 max level")
end)

test("3.3 GetMaxPartyLevelDisparity: Party Gap 4", function()
  mockPlayerLevel = 80
  mockRaidMembers = {}
  mockGroupMembers = {
    player = { level = 80, connected = true },
    party1 = { level = 76, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 4, "Gap 4 disparity")
  assert_eq(minLvl, 76, "Gap 4 min level")
  assert_eq(maxLvl, 80, "Gap 4 max level")
end)

test("3.4 GetMaxPartyLevelDisparity: Party Gap 5", function()
  mockPlayerLevel = 80
  mockRaidMembers = {}
  mockGroupMembers = {
    player = { level = 80, connected = true },
    party1 = { level = 75, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 5, "Gap 5 disparity")
  assert_eq(minLvl, 75, "Gap 5 min level")
  assert_eq(maxLvl, 80, "Gap 5 max level")
end)

test("3.5 GetMaxPartyLevelDisparity: Party Gap 10", function()
  mockPlayerLevel = 80
  mockRaidMembers = {}
  mockGroupMembers = {
    player = { level = 80, connected = true },
    party1 = { level = 70, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 10, "Gap 10 disparity")
  assert_eq(minLvl, 70, "Gap 10 min level")
  assert_eq(maxLvl, 80, "Gap 10 max level")
end)

test("3.6 GetMaxPartyLevelDisparity: Offline Members", function()
  mockPlayerLevel = 80
  mockRaidMembers = {}
  -- Player is 80, party1 is offline (lvl 10), party2 is online (lvl 78)
  mockGroupMembers = {
    player = { level = 80, connected = true },
    party1 = { level = 10, connected = false },
    party2 = { level = 78, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 2, "Disparity ignoring offline member (80 - 78)")
  assert_eq(minLvl, 78, "Min level ignoring offline member")
  assert_eq(maxLvl, 80, "Max level ignoring offline member")

  -- All party members offline
  mockGroupMembers = {
    player = { level = 80, connected = true },
    party1 = { level = 10, connected = false },
  }
  disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 0, "Disparity when all party members are offline")
  assert_eq(minLvl, 80, "Min level when all party members offline")
  assert_eq(maxLvl, 80, "Max level when all party members offline")
end)

test("3.7 GetMaxPartyLevelDisparity: Skull Levels (-1)", function()
  mockPlayerLevel = 50
  mockRaidMembers = {}
  -- Player is 50, party1 is level -1 (skull), party2 is level 54
  mockGroupMembers = {
    player = { level = 50, connected = true },
    party1 = { level = -1, connected = true },
    party2 = { level = 54, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 4, "Disparity ignoring skull level (-1) member (54 - 50)")
  assert_eq(minLvl, 50, "Min level ignoring skull member")
  assert_eq(maxLvl, 54, "Max level ignoring skull member")

  -- Party member with level 0
  mockGroupMembers = {
    player = { level = 50, connected = true },
    party1 = { level = 0, connected = true },
  }
  disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 0, "Disparity ignoring level 0 member")
end)

test("3.8 GetMaxPartyLevelDisparity: Raid Group", function()
  mockPlayerLevel = 80
  mockGroupMembers = {}
  mockRaidMembers = {
    player = { level = 80, connected = true },
    raid1 = { level = 70, connected = true },
    raid2 = { level = -1, connected = true }, -- skull ignored
    raid3 = { level = 10, connected = false }, -- offline ignored
    raid4 = { level = 75, connected = true },
  }
  local disparity, minLvl, maxLvl = XPRate.GetMaxPartyLevelDisparity()
  assert_eq(disparity, 10, "Raid disparity (80 - 70)")
  assert_eq(minLvl, 70, "Raid min level")
  assert_eq(maxLvl, 80, "Raid max level")
end)

test("3.9 GetMaxPartyLevelDisparity alias GetPartyLevelDisparity", function()
  assert_eq(XPRate.GetPartyLevelDisparity, XPRate.GetMaxPartyLevelDisparity, "GetPartyLevelDisparity is alias for GetMaxPartyLevelDisparity")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
