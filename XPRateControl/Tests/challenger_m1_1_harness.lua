-- Tests/challenger_m1_1_harness.lua
-- Adversarial test harness for Core/Config.lua (Milestone 1)

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW environment
DEFAULT_CHAT_FRAME = { AddMessage = function(self, msg) end }

-- Load Core/Config.lua
local chunk, err = loadfile("Core/Config.lua")
if not chunk then
  error("Failed to load Core/Config.lua: " .. tostring(err))
end
chunk(addonName, XPRate)

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
    error(string.format("%s: expected type %s, got %s (value: %s)",
      msg or "Type assertion failed",
      expectedType, type(val), tostring(val)))
  end
end

print("==================================================")
print("  XPRateControl M1 Adversarial Challenge Suite    ")
print("==================================================")

-- Suite 1: Top-level XPRateControlDB Corruption
test("1.1 Top-level DB is nil", function()
  XPRateControlDB = nil
  local db = XPRate.InitDB()
  assert_type(db, "table", "db should be table")
  assert_eq(db, XPRateControlDB, "returned db should be global XPRateControlDB")
  assert_eq(db.lastRate, 1.0, "lastRate default")
  assert_eq(db.firstRun, true, "firstRun default")
end)

test("1.2 Top-level DB is boolean true", function()
  XPRateControlDB = true
  local db = XPRate.InitDB()
  assert_type(db, "table", "db should recover to table")
  assert_eq(db.lastRate, 1.0, "lastRate default")
end)

test("1.3 Top-level DB is boolean false", function()
  XPRateControlDB = false
  local db = XPRate.InitDB()
  assert_type(db, "table", "db should recover to table")
  assert_eq(db.lastRate, 1.0, "lastRate default")
end)

test("1.4 Top-level DB is string 'invalid'", function()
  XPRateControlDB = "invalid"
  local db = XPRate.InitDB()
  assert_type(db, "table", "db should recover to table")
  assert_eq(db.lastRate, 1.0, "lastRate default")
end)

test("1.5 Top-level DB is number 123", function()
  XPRateControlDB = 123
  local db = XPRate.InitDB()
  assert_type(db, "table", "db should recover to table")
  assert_eq(db.lastRate, 1.0, "lastRate default")
end)

-- Suite 2: groupRates Corruption
test("2.1 groupRates is boolean true", function()
  XPRateControlDB = { groupRates = true }
  local db = XPRate.InitDB()
  assert_type(db.groupRates, "table", "groupRates should recover to table")
  assert_eq(db.groupRates[1], 1.00, "groupRates[1]")
  assert_eq(db.groupRates[2], 1.25, "groupRates[2]")
  assert_eq(db.groupRates[3], 1.50, "groupRates[3]")
  assert_eq(db.groupRates[4], 1.75, "groupRates[4]")
  assert_eq(db.groupRates[5], 2.00, "groupRates[5]")
end)

test("2.2 groupRates is string 'corrupted'", function()
  XPRateControlDB = { groupRates = "corrupted" }
  local db = XPRate.InitDB()
  assert_type(db.groupRates, "table", "groupRates should recover to table")
  assert_eq(db.groupRates[5], 2.00, "groupRates[5]")
end)

test("2.3 groupRates is number 999", function()
  XPRateControlDB = { groupRates = 999 }
  local db = XPRate.InitDB()
  assert_type(db.groupRates, "table", "groupRates should recover to table")
  assert_eq(db.groupRates[1], 1.00, "groupRates[1]")
end)

-- Suite 3: mobRates Corruption
test("3.1 mobRates is string 'invalid'", function()
  XPRateControlDB = { mobRates = "invalid" }
  local db = XPRate.InitDB()
  assert_type(db.mobRates, "table", "mobRates should recover to table")
  assert_eq(db.mobRates.gray, 0.0, "mobRates.gray")
  assert_eq(db.mobRates.green, 0.5, "mobRates.green")
  assert_eq(db.mobRates.yellow, 1.0, "mobRates.yellow")
  assert_eq(db.mobRates.red, 2.0, "mobRates.red")
end)

test("3.2 mobRates is boolean false", function()
  XPRateControlDB = { mobRates = false }
  local db = XPRate.InitDB()
  assert_type(db.mobRates, "table", "mobRates should recover to table")
  assert_eq(db.mobRates.yellow, 1.0, "mobRates.yellow")
end)

-- Suite 4: bracketRates Corruption & Edge Cases
test("4.1 bracketRates is string 'corrupted'", function()
  XPRateControlDB = { bracketRates = "corrupted" }
  local db = XPRate.InitDB()
  assert_type(db.bracketRates, "table", "bracketRates should recover to table")
  assert_type(db.bracketRates[1], "table", "bracketRates[1] should be table")
  assert_eq(db.bracketRates[1].min, 1, "bracketRates[1].min")
  assert_eq(db.bracketRates[1].max, 59, "bracketRates[1].max")
  assert_eq(db.bracketRates[1].rate, 2.00, "bracketRates[1].rate")
  assert_eq(db.bracketRates[4].min, 80, "bracketRates[4].min")
  assert_eq(db.bracketRates[4].max, 80, "bracketRates[4].max")
  assert_eq(db.bracketRates[4].rate, 0.00, "bracketRates[4].rate")
end)

test("4.2 bracketRates[1] is string 'invalid_entry'", function()
  XPRateControlDB = { bracketRates = { [1] = "invalid_entry" } }
  local db = XPRate.InitDB()
  assert_type(db.bracketRates[1], "table", "bracketRates[1] should recover to table")
  assert_eq(db.bracketRates[1].min, 1, "bracketRates[1].min")
  assert_eq(db.bracketRates[1].rate, 2.00, "bracketRates[1].rate")
end)

test("4.3 bracketRates[1] is boolean true", function()
  XPRateControlDB = { bracketRates = { [1] = true } }
  local db = XPRate.InitDB()
  assert_type(db.bracketRates[1], "table", "bracketRates[1] should recover to table")
  assert_eq(db.bracketRates[1].min, 1, "bracketRates[1].min")
end)

test("4.4 bracketRates[1] has nil fields { min = nil, max = 59, rate = nil }", function()
  XPRateControlDB = { bracketRates = { [1] = { max = 59 } } }
  local db = XPRate.InitDB()
  assert_type(db.bracketRates[1], "table")
  assert_eq(db.bracketRates[1].min, 1, "min should be defaulted")
  assert_eq(db.bracketRates[1].max, 59, "max should be preserved")
  assert_eq(db.bracketRates[1].rate, 2.00, "rate should be defaulted")
end)

test("4.5 bracketRates[1] contains corrupted field types { min = 'one', max = false, rate = 'two' }", function()
  XPRateControlDB = { bracketRates = { [1] = { min = "one", max = false, rate = "two" } } }
  local db = XPRate.InitDB()
  assert_type(db.bracketRates[1], "table")
  -- InitDB checks only == nil, so non-nil corrupted fields are retained
  assert_eq(db.bracketRates[1].min, "one", "non-nil min preserved as-is")
  assert_eq(db.bracketRates[1].max, false, "non-nil max preserved as-is")
  assert_eq(db.bracketRates[1].rate, "two", "non-nil rate preserved as-is")
end)

test("4.6 bracketRates has missing middle entry [2]", function()
  XPRateControlDB = {
    bracketRates = {
      [1] = { min = 1, max = 59, rate = 2.00 },
      -- [2] is missing
      [3] = { min = 70, max = 79, rate = 1.00 }
    }
  }
  local db = XPRate.InitDB()
  assert_type(db.bracketRates[2], "table", "missing bracketRates[2] populated")
  assert_eq(db.bracketRates[2].min, 60, "bracketRates[2].min")
  assert_eq(db.bracketRates[2].max, 69, "bracketRates[2].max")
  assert_eq(db.bracketRates[2].rate, 1.50, "bracketRates[2].rate")
  assert_eq(db.bracketRates[1].min, 1, "bracketRates[1] preserved")
  assert_eq(db.bracketRates[3].min, 70, "bracketRates[3] preserved")
  assert_type(db.bracketRates[4], "table", "missing bracketRates[4] populated")
end)

-- Suite 5: zoneRates Corruption
test("5.1 zoneRates is boolean false", function()
  XPRateControlDB = { zoneRates = false }
  local db = XPRate.InitDB()
  assert_type(db.zoneRates, "table", "zoneRates recovered")
  assert_eq(db.zoneRates.world, 1.00, "zoneRates.world")
  assert_eq(db.zoneRates.dungeon, 1.00, "zoneRates.dungeon")
  assert_eq(db.zoneRates.raid, 0.00, "zoneRates.raid")
  assert_eq(db.zoneRates.pvp, 1.00, "zoneRates.pvp")
end)

test("5.2 zoneRates is string 'corrupted'", function()
  XPRateControlDB = { zoneRates = "corrupted" }
  local db = XPRate.InitDB()
  assert_type(db.zoneRates, "table", "zoneRates recovered")
  assert_eq(db.zoneRates.raid, 0.00, "zoneRates.raid")
end)

-- Suite 6: Non-table field preservation & type mismatch observations
test("6.1 Scalar fields corrupted with unexpected non-nil data types", function()
  XPRateControlDB = {
    minimapPos = "invalid_angle",
    showMinimap = "yes",
    lastRate = "one",
    autoDisparity = 1,
    disparityThreshold = "five"
  }
  local db = XPRate.InitDB()
  assert_eq(db.minimapPos, "invalid_angle", "minimapPos retained")
  assert_eq(db.showMinimap, "yes", "showMinimap retained")
  assert_eq(db.lastRate, "one", "lastRate retained")
  assert_eq(db.disparityThreshold, "five", "disparityThreshold retained")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
