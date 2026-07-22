-- Tests/worker_m2_1_harness.lua
-- Unit test harness for Engine/Automation.lua (Milestone 2)

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

-- Mock WoW API variables
mockInInstance = false
mockInstanceType = "none"
mockPlayerLevel = 1
mockGroupMembers = {} -- e.g. { player = 10, party1 = 15 }
mockRaidMembers = {}
mockXPExhaustion = nil
mockTarget = nil -- e.g. { level = 12, canAttack = true, isDead = false, isPlayer = false }

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

-- Load Core/Config.lua
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

local function assert_type(val, expectedType, msg)
  totalAssertions = totalAssertions + 1
  if type(val) ~= expectedType then
    error(string.format("%s: expected type %s, got %s",
      msg or "Type assertion failed",
      expectedType, type(val)))
  end
end

print("==================================================")
print("  XPRateControl M2 Automation Engine Test Suite   ")
print("==================================================")

-- Suite 1: Helper Functions
test("1.1 GetCurrentZoneType mapping", function()
  mockInInstance = false
  mockInstanceType = "none"
  local zType, zLabel = XPRate.GetCurrentZoneType()
  assert_eq(zType, "world", "World zone type")
  assert_eq(zLabel, "Open World", "World zone label")

  mockInInstance = true
  mockInstanceType = "party"
  zType, zLabel = XPRate.GetCurrentZoneType()
  assert_eq(zType, "dungeon", "Dungeon zone type")
  assert_eq(zLabel, "Dungeon", "Dungeon zone label")

  mockInstanceType = "raid"
  zType, zLabel = XPRate.GetCurrentZoneType()
  assert_eq(zType, "raid", "Raid zone type")
  assert_eq(zLabel, "Raid", "Raid zone label")

  mockInstanceType = "pvp"
  zType, zLabel = XPRate.GetCurrentZoneType()
  assert_eq(zType, "pvp", "PVP zone type")
  assert_eq(zLabel, "Battleground / Arena", "PVP zone label")

  mockInstanceType = "arena"
  zType, zLabel = XPRate.GetCurrentZoneType()
  assert_eq(zType, "pvp", "Arena mapped to PVP zone type")
end)

test("1.2 GetMatchingLevelBracket lookup", function()
  XPRate.InitDB()
  local b1 = XPRate.GetMatchingLevelBracket(15)
  assert_type(b1, "table", "Bracket 1 table")
  assert_eq(b1.min, 1)
  assert_eq(b1.max, 59)
  assert_eq(b1.rate, 2.00)

  local b2 = XPRate.GetMatchingLevelBracket(65)
  assert_eq(b2.min, 60)
  assert_eq(b2.max, 69)
  assert_eq(b2.rate, 1.50)

  local b3 = XPRate.GetMatchingLevelBracket(75)
  assert_eq(b3.min, 70)
  assert_eq(b3.max, 79)
  assert_eq(b3.rate, 1.00)

  local b4 = XPRate.GetMatchingLevelBracket(80)
  assert_eq(b4.min, 80)
  assert_eq(b4.max, 80)
  assert_eq(b4.rate, 0.00)

  local bNone = XPRate.GetMatchingLevelBracket(99)
  assert_eq(bNone, nil, "Out of range level returns nil")
end)

test("1.3 GetMaxPartyLevelDisparity calculation", function()
  mockPlayerLevel = 20
  mockGroupMembers = { player = { level = 20 } }
  assert_eq(XPRate.GetMaxPartyLevelDisparity(), 0, "Solo disparity is 0")

  mockGroupMembers = {
    player = { level = 20, connected = true },
    party1 = { level = 28, connected = true },
    party2 = { level = 18, connected = true },
  }
  assert_eq(XPRate.GetMaxPartyLevelDisparity(), 10, "Disparity 28 - 18 = 10")

  -- Disconnected member should be ignored
  mockGroupMembers = {
    player = { level = 20, connected = true },
    party1 = { level = 80, connected = false },
    party2 = { level = 22, connected = true },
  }
  assert_eq(XPRate.GetMaxPartyLevelDisparity(), 2, "Offline member level 80 ignored, 22 - 20 = 2")
end)

-- Suite 2: Priority Evaluator Strict Hierarchy
test("2.1 Priority Tier 1 (Quest Interaction) overrides all lower tiers", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  -- Enable ALL automation options
  XPRateControlDB.autoQuest = true
  XPRateControlDB.questRate = 2.00
  XPRate.isQuestNPCActive = true

  XPRateControlDB.autoZone = true
  mockInInstance = true
  mockInstanceType = "raid"
  XPRateControlDB.zoneRates = { raid = 0.00 }

  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 80 -- bracket rate 0.00

  XPRateControlDB.autoMob = true
  mockTarget = { level = 80, canAttack = true, isDead = false, isPlayer = false } -- red mob

  XPRateControlDB.autoGroup = true
  XPRateControlDB.autoDisparity = true
  mockGroupMembers = { player = { level = 1 }, party1 = { level = 80 } }

  XPRateControlDB.autoRested = true
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Priority Tier 1")

  assert_eq(#appliedRates, 1, "Applied rate count")
  assert_eq(appliedRates[1].rate, 2.00, "Quest rate applied")
  assert_eq(XPRate.lastAppliedMode, "Quest Interaction", "Quest mode string")
end)

test("2.2 Priority Tier 2 (Zone) overrides Tier 3..6 when Quest is inactive", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = true
  XPRate.isQuestNPCActive = false -- inactive!

  XPRateControlDB.autoZone = true
  mockInInstance = true
  mockInstanceType = "raid"
  XPRateControlDB.zoneRates = { raid = 0.00 }

  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 15 -- bracket rate 2.00

  XPRateControlDB.autoRested = true
  mockXPExhaustion = 5000 -- rested rate 2.00

  XPRate.EvaluateAutomation(false, "Test Priority Tier 2")

  assert_eq(#appliedRates, 1, "Applied rate count")
  assert_eq(appliedRates[1].rate, 0.00, "Raid zone rate (0.00) applied")
  assert_eq(XPRate.lastAppliedMode, "Zone (Raid)", "Zone mode string")
end)

test("2.3 Priority Tier 3 (Bracket) overrides Tier 4..6 when Quest and Zone are inactive", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false

  XPRateControlDB.autoBracket = true
  mockPlayerLevel = 65 -- Bracket 2: 60-69 -> 1.50x

  XPRateControlDB.autoMob = true
  mockTarget = { level = 65, canAttack = true } -- yellow mob -> 1.00x

  XPRateControlDB.autoRested = true
  mockXPExhaustion = 5000 -- rested rate -> 2.00x

  XPRate.EvaluateAutomation(false, "Test Priority Tier 3")

  assert_eq(#appliedRates, 1, "Applied rate count")
  assert_eq(appliedRates[1].rate, 1.50, "Bracket rate (1.50) applied")
  assert_eq(XPRate.lastAppliedMode, "Level Bracket (60-69)", "Bracket mode string")
end)

test("2.4 Priority Tier 4 (Mob) overrides Tier 5..6 when Tiers 1-3 are inactive", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = false

  XPRateControlDB.autoMob = true
  mockPlayerLevel = 20
  mockTarget = { level = 10, canAttack = true, isDead = false, isPlayer = false } -- gray mob -> 0.0x
  XPRateControlDB.mobRates = { gray = 0.0, green = 0.5, yellow = 1.0, red = 2.0 }

  XPRateControlDB.autoRested = true
  mockXPExhaustion = 5000 -- rested -> 2.0x

  XPRate.EvaluateAutomation(false, "Test Priority Tier 4")

  assert_eq(#appliedRates, 1, "Applied rate count")
  assert_eq(appliedRates[1].rate, 0.0, "Mob gray rate (0.00) applied")
  assert_eq(XPRate.lastAppliedMode, "Mob Difficulty (Gray)", "Mob mode string")
end)

test("2.5 Priority Tier 5 (Disparity & Party Scaling) overrides Tier 6", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoMob = false

  XPRateControlDB.autoGroup = true
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityThreshold = 5
  XPRateControlDB.disparityRate = 0.50

  mockPlayerLevel = 20
  mockGroupMembers = {
    player = { level = 20, connected = true },
    party1 = { level = 30, connected = true },
  }

  XPRateControlDB.autoRested = true
  mockXPExhaustion = 5000

  XPRate.EvaluateAutomation(false, "Test Priority Tier 5 Disparity")

  assert_eq(#appliedRates, 1, "Applied rate count")
  assert_eq(appliedRates[1].rate, 0.50, "Disparity rate applied")
  assert_eq(XPRate.lastAppliedMode, "Party Disparity (>5 Levels)", "Disparity mode string")

  -- Test party size scaling when disparity threshold is not exceeded
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  mockGroupMembers = {
    player = { level = 20, connected = true },
    party1 = { level = 22, connected = true },
    party2 = { level = 21, connected = true },
  }
  XPRateControlDB.groupRates = { [1]=1.0, [2]=1.25, [3]=1.50, [4]=1.75, [5]=2.00 }

  XPRate.EvaluateAutomation(false, "Test Priority Tier 5 Party Size")
  assert_eq(appliedRates[1].rate, 1.50, "3P Group rate applied")
  assert_eq(XPRate.lastAppliedMode, "Party Scaling (3P Group)", "Party scaling mode string")
end)

test("2.6 Priority Tier 6 (Rested XP) acts as baseline fallback", function()
  XPRate.InitDB()
  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoDisparity = false

  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 2.00
  XPRateControlDB.normalRate = 1.00

  mockXPExhaustion = 1000
  XPRate.EvaluateAutomation(false, "Test Rested Active")
  assert_eq(appliedRates[1].rate, 2.00, "Rested rate applied")
  assert_eq(XPRate.lastAppliedMode, "Auto Rested (Rested)")

  appliedRates = {}
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  mockXPExhaustion = nil
  XPRate.EvaluateAutomation(false, "Test Normal (No Rested)")
  assert_eq(appliedRates[1].rate, 1.00, "Normal rate applied")
  assert_eq(XPRate.lastAppliedMode, "Auto Rested (Normal)")
end)

-- Suite 3: UI Status Text Updates
test("3.1 UpdateAutomationStatus updates UI FontStrings", function()
  XPRate.InitDB()

  local restedFS = CreateFrame():CreateFontString()
  local groupFS  = CreateFrame():CreateFontString()
  local mobFS    = CreateFrame():CreateFontString()
  local questFS  = CreateFrame():CreateFontString()
  local zoneFS   = CreateFrame():CreateFontString()
  local bracketFS= CreateFrame():CreateFontString()

  XPRate.restedStateValue = restedFS
  XPRate.groupStateValue  = groupFS
  XPRate.mobStateValue    = mobFS
  XPRate.questStateValue  = questFS
  XPRate.zoneStateValue   = zoneFS
  XPRate.bracketStateValue= bracketFS

  mockXPExhaustion = 100
  mockPlayerLevel = 25
  mockInInstance = true
  mockInstanceType = "party"
  XPRateControlDB.autoZone = true
  XPRateControlDB.autoBracket = true

  XPRate.UpdateAutomationStatus()

  assert_eq(restedFS.text, "Rested XP Active", "Rested state text")
  assert_eq(zoneFS.text, "Zone: Dungeon (1.00x)", "Zone state text")
  assert_eq(bracketFS.text, "Bracket: Lv 1-59 (2.00x)", "Bracket state text")
end)

-- Suite 4: Registered Events Verification
test("4.1 Event listeners are registered for required events", function()
  local requiredEvents = {
    "ZONE_CHANGED_NEW_AREA",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_LEVEL_UP",
    "UNIT_LEVEL",
    "PARTY_MEMBERS_CHANGED",
    "RAID_ROSTER_UPDATE",
    "QUEST_DETAIL",
    "PLAYER_TARGET_CHANGED"
  }

  for _, evt in ipairs(requiredEvents) do
    assert_eq(registeredEvents[evt], true, "Event registered: " .. evt)
  end
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
