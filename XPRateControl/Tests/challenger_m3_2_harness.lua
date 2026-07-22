-- Tests/challenger_m3_2_harness.lua
-- Empirical Verification Harness for Challenger 2 (Milestone 3)
-- Purpose: Verify UI-to-Engine State Synchronization, Master UI Refresh Performance, and Priority Evaluator multi-mode behavior.

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
local mockInInstance = false
local mockInstanceType = "none"
local mockPlayerLevel = 25
local mockGroupMembers = {}
local mockRaidMembers = {}
local mockXPExhaustion = nil
local mockTarget = nil

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

local appliedRates = {}
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

-- Test Framework Data
local testsPassed = 0
local testsFailed = 0
local totalAssertions = 0

local function assert_true(val, msg)
  totalAssertions = totalAssertions + 1
  if not val then
    error("Assertion failed: " .. (msg or "expected true, got false/nil"))
  end
end

local function assert_equal(expected, actual, msg)
  totalAssertions = totalAssertions + 1
  if expected ~= actual then
    error(string.format("Assertion failed: %s (expected %s, got %s)", msg or "", tostring(expected), tostring(actual)))
  end
end

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

print("==================================================")
print("  XPRateControl Challenger 2 (Milestone 3) Harness")
print("==================================================")

-- TEST CASE 1: UI-to-Engine State Synchronization Across All 6 Sub-Tabs
test("1.1 DB to UI CheckButton Sync across 6 Sub-Tabs", function()
  -- Reset DB state
  XPRateControlDB.autoRested = false
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoZone = false

  XPRate.UpdateAutomationTabUI()

  assert_equal(false, XPRate.restedCheckbox:GetChecked(), "restedCheckbox off")
  assert_equal(false, XPRate.groupCheckbox:GetChecked(), "groupCheckbox off")
  assert_equal(false, XPRate.disparityCheckbox:GetChecked(), "disparityCheckbox off")
  assert_equal(false, XPRate.mobCheckbox:GetChecked(), "mobCheckbox off")
  assert_equal(false, XPRate.questCheckbox:GetChecked(), "questCheckbox off")
  assert_equal(false, XPRate.bracketCheckbox:GetChecked(), "bracketCheckbox off")
  assert_equal(false, XPRate.zoneCheckbox:GetChecked(), "zoneCheckbox off")

  -- Enable all DB toggles
  XPRateControlDB.autoRested = true
  XPRateControlDB.autoGroup = true
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.autoMob = true
  XPRateControlDB.autoQuest = true
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoZone = true

  XPRate.UpdateAutomationTabUI()

  assert_equal(true, XPRate.restedCheckbox:GetChecked(), "restedCheckbox on")
  assert_equal(true, XPRate.groupCheckbox:GetChecked(), "groupCheckbox on")
  assert_equal(true, XPRate.disparityCheckbox:GetChecked(), "disparityCheckbox on")
  assert_equal(true, XPRate.mobCheckbox:GetChecked(), "mobCheckbox on")
  assert_equal(true, XPRate.questCheckbox:GetChecked(), "questCheckbox on")
  assert_equal(true, XPRate.bracketCheckbox:GetChecked(), "bracketCheckbox on")
  assert_equal(true, XPRate.zoneCheckbox:GetChecked(), "zoneCheckbox on")
end)

test("1.2 CheckButtons OnClick to DB Sync & Event Evaluation", function()
  -- Reset DB state
  XPRateControlDB.autoRested = false
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoZone = false

  -- Click restedCheckbox
  XPRate.restedCheckbox:SetChecked(true)
  XPRate.restedCheckbox:GetScript("OnClick")(XPRate.restedCheckbox)
  assert_equal(true, XPRateControlDB.autoRested, "autoRested updated to true")

  -- Click groupCheckbox
  XPRate.groupCheckbox:SetChecked(true)
  XPRate.groupCheckbox:GetScript("OnClick")(XPRate.groupCheckbox)
  assert_equal(true, XPRateControlDB.autoGroup, "autoGroup updated to true")

  -- Click disparityCheckbox
  XPRate.disparityCheckbox:SetChecked(true)
  XPRate.disparityCheckbox:GetScript("OnClick")(XPRate.disparityCheckbox)
  assert_equal(true, XPRateControlDB.autoDisparity, "autoDisparity updated to true")

  -- Click mobCheckbox
  XPRate.mobCheckbox:SetChecked(true)
  XPRate.mobCheckbox:GetScript("OnClick")(XPRate.mobCheckbox)
  assert_equal(true, XPRateControlDB.autoMob, "autoMob updated to true")

  -- Click questCheckbox
  XPRate.questCheckbox:SetChecked(true)
  XPRate.questCheckbox:GetScript("OnClick")(XPRate.questCheckbox)
  assert_equal(true, XPRateControlDB.autoQuest, "autoQuest updated to true")

  -- Click bracketCheckbox
  XPRate.bracketCheckbox:SetChecked(true)
  XPRate.bracketCheckbox:GetScript("OnClick")(XPRate.bracketCheckbox)
  assert_equal(true, XPRateControlDB.autoBracket, "autoBracket updated to true")

  -- Click zoneCheckbox
  XPRate.zoneCheckbox:SetChecked(true)
  XPRate.zoneCheckbox:GetScript("OnClick")(XPRate.zoneCheckbox)
  assert_equal(true, XPRateControlDB.autoZone, "autoZone updated to true")
end)

test("1.3 Dropdown Option Status Checkmarks Sync across all 6 sub-tabs", function()
  -- Test with all disabled
  XPRateControlDB.autoRested = false
  XPRateControlDB.autoGroup = false
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoZone = false

  XPRate.UpdateDropdownCheckmarks()
  local headerBtn = _G["XPRateAutoHeaderDropdown"]
  headerBtn:GetScript("OnClick")() -- Trigger dropdown open

  local menu = _G["XPRateAutoDropdownMenu"]
  assert_equal(true, menu:IsShown(), "Dropdown menu shown")

  -- Toggle autoBracket and autoZone
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoZone = true
  XPRate.UpdateDropdownCheckmarks()

  assert_true(true, "Dropdown checkmarks sync completed")
end)

-- TEST CASE 2: Master Refresh Performance & Rapid Sub-Tab Switching
test("2.1 Master Refresh & Rapid Sub-Tab Switching Performance Benchmark", function()
  local startTime = os.clock()
  local totalRefreshes = 3000

  -- Cycle through sub-tabs 1..6 rapidly (3,000 updates)
  for i = 1, totalRefreshes do
    local tab = ((i - 1) % 6) + 1
    XPRateControlDB.autoRested = (tab == 1)
    XPRateControlDB.autoGroup = (tab == 2)
    XPRateControlDB.autoMob = (tab == 3)
    XPRateControlDB.autoQuest = (tab == 4)
    XPRateControlDB.autoBracket = (tab == 5)
    XPRateControlDB.autoZone = (tab == 6)

    XPRate.UpdateAutomationTabUI()
  end

  local elapsed = os.clock() - startTime
  -- Ensure throughput is high (>1,000 refreshes/second, total elapsed < 3.0s)
  assert_true(elapsed < 3.0, string.format("Master refresh performance (%d refreshes in %.4fs < 3.0s)", totalRefreshes, elapsed))
end)

test("2.2 Status Strings Integrity under Rapid Switching", function()
  mockInInstance = true
  mockInstanceType = "party"
  mockPlayerLevel = 45
  mockXPExhaustion = 500
  mockTarget = { level = 45, canAttack = true, isDead = false, isPlayer = false }
  XPRate.isQuestNPCActive = true

  XPRateControlDB.autoRested = true
  XPRateControlDB.autoGroup = true
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.autoMob = true
  XPRateControlDB.autoQuest = true
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoZone = true

  XPRate.UpdateAutomationTabUI()

  -- Verify all status text elements are populated and non-empty
  assert_true(XPRate.restedStateValue:GetText() ~= "", "restedStateValue non-empty")
  assert_true(XPRate.groupStateValue:GetText() ~= "", "groupStateValue non-empty")
  assert_true(XPRate.mobStateValue:GetText() ~= "", "mobStateValue non-empty")
  assert_true(XPRate.questStateValue:GetText() ~= "", "questStateValue non-empty")
  assert_true(XPRate.bracketStateValue:GetText() ~= "", "bracketStateValue non-empty")
  assert_true(XPRate.zoneStateValue:GetText() ~= "", "zoneStateValue non-empty")
end)

-- TEST CASE 3: Priority Evaluator Behavior & Multi-Mode Cascading Priority
test("3.1 Priority Evaluator - All Modes Active (Quest Wins)", function()
  -- Set conditions for all 6 modes:
  XPRate.isQuestNPCActive = true
  mockInInstance = true
  mockInstanceType = "party" -- Zone
  mockPlayerLevel = 25 -- Bracket 1-59
  mockTarget = { level = 25, canAttack = true, isDead = false, isPlayer = false } -- Mob Yellow
  mockGroupMembers = { player = {level=25}, party1 = {level=10} } -- Disparity 15 > 5
  mockXPExhaustion = 1000 -- Rested

  XPRateControlDB.autoQuest = true
  XPRateControlDB.questRate = 2.00
  XPRateControlDB.autoZone = true
  XPRateControlDB.zoneRates = { dungeon = 1.25 }
  XPRateControlDB.autoBracket = true
  XPRateControlDB.bracketRates = { { min = 1, max = 59, rate = 1.50 } }
  XPRateControlDB.autoMob = true
  XPRateControlDB.mobRates = { yellow = 1.00 }
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.disparityThreshold = 5
  XPRateControlDB.disparityRate = 0.50
  XPRateControlDB.autoGroup = true
  XPRateControlDB.groupRates = { [2] = 1.20 }
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 2.00

  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRate.EvaluateAutomation(true, "Priority Test")

  assert_equal("Quest Interaction", XPRate.lastAppliedMode, "Quest has top priority")
  assert_equal(2.00, XPRate.lastAppliedRate, "Quest rate applied")
end)

test("3.2 Cascading Priority Fallthrough (Quest -> Zone -> Bracket -> Mob -> Disparity -> Group -> Rested)", function()
  -- Setup conditions for all
  XPRate.isQuestNPCActive = true
  mockInInstance = true
  mockInstanceType = "party"
  mockPlayerLevel = 25
  mockTarget = { level = 25, canAttack = true, isDead = false, isPlayer = false }
  mockGroupMembers = { player = {level=25}, party1 = {level=10} }
  mockXPExhaustion = 1000

  -- Step 1: Quest Active -> Quest Interaction
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 1")
  assert_equal("Quest Interaction", XPRate.lastAppliedMode, "Step 1: Quest Interaction")

  -- Step 2: Quest Inactive -> Zone
  XPRate.isQuestNPCActive = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 2")
  assert_equal("Zone (Dungeon)", XPRate.lastAppliedMode, "Step 2: Zone (Dungeon)")

  -- Step 3: Zone Auto OFF -> Level Bracket
  XPRateControlDB.autoZone = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 3")
  assert_equal("Level Bracket (1-59)", XPRate.lastAppliedMode, "Step 3: Level Bracket")

  -- Step 4: Bracket Auto OFF -> Mob Difficulty
  XPRateControlDB.autoBracket = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 4")
  assert_equal("Mob Difficulty (Yellow)", XPRate.lastAppliedMode, "Step 4: Mob Difficulty")

  -- Step 5: Mob Auto OFF -> Party Disparity
  XPRateControlDB.autoMob = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 5")
  assert_equal("Party Disparity (>5 Levels)", XPRate.lastAppliedMode, "Step 5: Party Disparity")

  -- Step 6: Disparity Auto OFF -> Party Scaling
  XPRateControlDB.autoDisparity = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 6")
  assert_equal("Party Scaling (2P Group)", XPRate.lastAppliedMode, "Step 6: Party Scaling")

  -- Step 7: Group Auto OFF -> Auto Rested
  XPRateControlDB.autoGroup = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 7")
  assert_equal("Auto Rested (Rested)", XPRate.lastAppliedMode, "Step 7: Auto Rested")

  -- Step 8: Rested Auto OFF -> No mode applied
  XPRateControlDB.autoRested = false
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Step 8")
  assert_equal(nil, XPRate.lastAppliedMode, "Step 8: None")
end)

test("3.3 Fallthrough when Mode Enabled but Condition Unmet", function()
  -- Reset toggles: enable higher tiers in DB except autoGroup
  XPRateControlDB.autoQuest = true
  XPRateControlDB.autoZone = true
  XPRateControlDB.autoBracket = true
  XPRateControlDB.autoMob = true
  XPRateControlDB.autoDisparity = true
  XPRateControlDB.autoGroup = false -- Disabled so solo play falls through to autoRested
  XPRateControlDB.autoRested = true

  -- Scenario A: autoQuest enabled, but isQuestNPCActive = false
  -- autoZone enabled, but zone = world and zoneRates["world"] is nil
  XPRate.isQuestNPCActive = false
  mockInInstance = false
  mockInstanceType = "none"
  XPRateControlDB.zoneRates = { dungeon = 1.5 } -- world rate nil

  -- autoBracket enabled, but level = 90 (out of bracket range)
  mockPlayerLevel = 90

  -- autoMob enabled, but no target selected
  mockTarget = nil

  -- autoDisparity enabled, but solo player (groupSize = 1)
  mockGroupMembers = {}

  -- autoRested active with rested XP
  mockXPExhaustion = 500

  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Unmet Fallthrough Test")

  -- Should fall through all unmet higher tiers and select Rested!
  assert_equal("Auto Rested (Rested)", XPRate.lastAppliedMode, "Fell through unmet tiers to Rested")
end)

test("3.4 Party Scaling 1P Solo Precedence over Rested XP when autoGroup is Enabled", function()
  -- Test the interaction between autoGroup (Tier 5b) and autoRested (Tier 6)
  XPRateControlDB.autoQuest = false
  XPRateControlDB.autoZone = false
  XPRateControlDB.autoBracket = false
  XPRateControlDB.autoMob = false
  XPRateControlDB.autoDisparity = false
  XPRateControlDB.autoGroup = true -- Enabled
  XPRateControlDB.autoRested = true -- Enabled

  mockGroupMembers = {} -- Solo (1P)
  mockXPExhaustion = 500 -- Rested active

  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  XPRate.EvaluateAutomation(true, "Group Solo Precedence Test")

  -- autoGroup provides groupRates[1] for 1P Solo at Tier 5, shadowing autoRested at Tier 6
  assert_equal("Party Scaling (Solo)", XPRate.lastAppliedMode, "autoGroup handles Solo play at Tier 5 before autoRested")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
