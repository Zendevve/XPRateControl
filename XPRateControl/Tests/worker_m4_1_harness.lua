-- Tests/worker_m4_1_harness.lua
-- Unit test harness for Milestone 4 (Addon Initialization, Event Wiring & Slash Commands)

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW Environment
local printedMessages = {}
DEFAULT_CHAT_FRAME = {
  AddMessage = function(self, msg)
    table.insert(printedMessages, msg)
  end
}
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
    shown = false,
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
    ClearAllPoints = function() end,
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
XPRateMinimapButtonBorder = { SetVertexColor = function() end }

-- Global API stubs
strtrim = function(s) return s and s:match("^%s*(.-)%s*$") or "" end
UnitLevel = function(unit) return 70 end
UnitGUID = function(unit) return "Player-1" end
GetNumPartyMembers = function() return 0 end
GetNumRaidMembers = function() return 0 end
IsInInstance = function() return false, "none" end
GetRealZoneText = function() return "Elwynn Forest" end
UnitDifficultyColor = {
  impossible = {r=1, g=0.1, b=0.1},
  verydifficult = {r=1, g=0.5, b=0.25},
  difficult = {r=1, g=1, b=0.2},
  standard = {r=0.25, g=0.75, b=0.25},
  trivial = {r=0.5, g=0.5, b=0.5},
}
GetQuestDifficultyColor = function(level) return {r=1, g=1, b=1} end
GetXPExhaustion = function() return 0 end
UnitXPMax = function(unit) return 10000 end
SendChatMessage = function() end
UIDropDownMenu_SetWidth = function() end
UIDropDownMenu_SetText = function() end
ToggleDropDownMenu = function() end

-- Frame structure mocks for UI Tab load
XPRate.frame = CreateFrame("Frame", "XPRateFrame")
XPRate.RatesTabFrame = CreateFrame("Frame", "XPRateRatesTabFrame")
XPRate.AutomationTabFrame = CreateFrame("Frame", "XPRateAutomationTabFrame")
XPRate.BuffsTabFrame = CreateFrame("Frame", "XPRateBuffsTabFrame")

-- Load Addon Source Files in strict TOC order
local configChunk = assert(loadfile("Core/Config.lua"))
configChunk(addonName, XPRate)
XPRate.InitDB()

local uiHelpersChunk = assert(loadfile("Core/UIHelpers.lua"))
uiHelpersChunk(addonName, XPRate)

local networkChunk = assert(loadfile("Core/Network.lua"))
networkChunk(addonName, XPRate)

local autoChunk = assert(loadfile("Engine/Automation.lua"))
autoChunk(addonName, XPRate)

local mainFrameChunk = assert(loadfile("UI/MainFrame.lua"))
mainFrameChunk(addonName, XPRate)

local minimapChunk = assert(loadfile("UI/MinimapButton.lua"))
minimapChunk(addonName, XPRate)

local tabRatesChunk = assert(loadfile("UI/TabRates.lua"))
tabRatesChunk(addonName, XPRate)

local tabAutoChunk = assert(loadfile("UI/TabAutomation.lua"))
tabAutoChunk(addonName, XPRate)

local tabBuffsChunk = assert(loadfile("UI/TabBuffs.lua"))
tabBuffsChunk(addonName, XPRate)

local initChunk = assert(loadfile("Init.lua"))
initChunk(addonName, XPRate)

-- Harness Test Engine
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
    print("[FAIL] " .. name .. " -> " .. tostring(err))
  end
end

print("==================================================")
print("  XPRateControl M4 Worker Test Harness (worker_m4_1)")
print("==================================================")

-- 1. Event Registration & Dispatching Verification
test("1.1 Core Event Listener Registration Verification", function()
  local requiredEvents = {
    "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD",
    "ZONE_CHANGED_NEW_AREA", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS",
    "PLAYER_LEVEL_UP", "GROUP_ROSTER_UPDATE", "PARTY_MEMBERS_CHANGED",
    "RAID_ROSTER_UPDATE", "PARTY_LEADER_CHANGED", "UNIT_LEVEL",
    "PLAYER_TARGET_CHANGED", "QUEST_GREETING", "QUEST_DETAIL",
    "QUEST_PROGRESS", "QUEST_COMPLETE", "QUEST_FINISHED", "UPDATE_EXHAUSTION"
  }

  assert_true(_G["XPRateEventFrame"] ~= nil, "XPRateEventFrame must be globally created")
  local eventFrame = _G["XPRateEventFrame"]
  local onEventScript = eventFrame:GetScript("OnEvent")
  assert_true(type(onEventScript) == "function", "OnEvent script handler must be registered on XPRateEventFrame")

  for _, evt in ipairs(requiredEvents) do
    assert_true(eventFrame.events[evt] == true, "Event " .. evt .. " must be registered on XPRateEventFrame")
  end
end)

test("1.2 ADDON_LOADED Initialization & State Restoration", function()
  local eventFrame = _G["XPRateEventFrame"]
  local onEventScript = eventFrame:GetScript("OnEvent")

  -- Mutate DB to non-default state
  XPRateControlDB.autoZone = true
  XPRateControlDB.autoQuest = false
  XPRateControlDB.lastRate = 1.5

  onEventScript(eventFrame, "ADDON_LOADED", addonName)

  assert_equal(true, XPRateControlDB.autoZone, "DB autoZone preserved")
  assert_equal(false, XPRateControlDB.autoQuest, "DB autoQuest preserved")
  assert_equal(1.5, XPRateControlDB.lastRate, "DB lastRate restored")
end)

test("1.3 Quest Event Dispatching & NPC Active State Tracking", function()
  local eventFrame = _G["XPRateEventFrame"]
  local onEventScript = eventFrame:GetScript("OnEvent")

  -- Trigger QUEST_DETAIL
  onEventScript(eventFrame, "QUEST_DETAIL")
  assert_true(XPRate.isQuestNPCActive == true, "QUEST_DETAIL sets isQuestNPCActive to true")

  -- Trigger QUEST_FINISHED
  onEventScript(eventFrame, "QUEST_FINISHED")
  assert_true(XPRate.isQuestNPCActive == false, "QUEST_FINISHED sets isQuestNPCActive to false")
end)

-- 2. Slash Command Dispatcher (/xp) Verification
test("2.1 Main Panel Toggle (/xp)", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]
  assert_true(type(slashHandler) == "function", "SlashCmdList['XPRATECONTROL'] handler exists")

  XPRate.frame:Hide()
  slashHandler("")
  assert_true(XPRate.frame:IsShown() == true, "/xp toggles hidden main frame to shown")

  slashHandler("")
  assert_true(XPRate.frame:IsShown() == false, "/xp toggles shown main frame to hidden")
end)

test("2.2 Rate Value Assignment (/xp <number>)", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]

  slashHandler("1.75")
  assert_equal(1.75, XPRateControlDB.lastRate, "/xp 1.75 sets lastRate to 1.75")

  -- Out of range rates should not change lastRate
  slashHandler("3.5")
  assert_equal(1.75, XPRateControlDB.lastRate, "/xp 3.5 (out of range) is rejected")
end)

test("2.3 Master Automation Command (/xp auto [on|off|status])", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]

  -- Test /xp auto off
  slashHandler("auto off")
  assert_equal(false, XPRateControlDB.autoRested, "/xp auto off sets autoRested=false")
  assert_equal(false, XPRateControlDB.autoGroup, "/xp auto off sets autoGroup=false")
  assert_equal(false, XPRateControlDB.autoDisparity, "/xp auto off sets autoDisparity=false")
  assert_equal(false, XPRateControlDB.autoMob, "/xp auto off sets autoMob=false")
  assert_equal(false, XPRateControlDB.autoQuest, "/xp auto off sets autoQuest=false")
  assert_equal(false, XPRateControlDB.autoBracket, "/xp auto off sets autoBracket=false")
  assert_equal(false, XPRateControlDB.autoZone, "/xp auto off sets autoZone=false")

  -- Test /xp auto on
  slashHandler("auto on")
  assert_equal(true, XPRateControlDB.autoRested, "/xp auto on sets autoRested=true")
  assert_equal(true, XPRateControlDB.autoGroup, "/xp auto on sets autoGroup=true")
  assert_equal(true, XPRateControlDB.autoDisparity, "/xp auto on sets autoDisparity=true")
  assert_equal(true, XPRateControlDB.autoMob, "/xp auto on sets autoMob=true")
  assert_equal(true, XPRateControlDB.autoQuest, "/xp auto on sets autoQuest=true")
  assert_equal(true, XPRateControlDB.autoBracket, "/xp auto on sets autoBracket=true")
  assert_equal(true, XPRateControlDB.autoZone, "/xp auto on sets autoZone=true")

  -- Test /xp auto toggle
  slashHandler("auto")
  assert_equal(false, XPRateControlDB.autoRested, "/xp auto toggles all active modules to false")

  -- Test /xp auto status (should execute cleanly)
  local passStatus = pcall(function() slashHandler("auto status") end)
  assert_true(passStatus, "/xp auto status executes without error")
end)

test("2.4 Feature-Specific Slash Commands (/xp zone, bracket, disparity, group, mob, quest, rested)", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]

  slashHandler("zone off")
  assert_equal(false, XPRateControlDB.autoZone, "/xp zone off sets autoZone=false")
  slashHandler("zone on")
  assert_equal(true, XPRateControlDB.autoZone, "/xp zone on sets autoZone=true")

  slashHandler("bracket off")
  assert_equal(false, XPRateControlDB.autoBracket, "/xp bracket off sets autoBracket=false")

  slashHandler("disparity on")
  assert_equal(true, XPRateControlDB.autoDisparity, "/xp disparity on sets autoDisparity=true")

  slashHandler("group off")
  assert_equal(false, XPRateControlDB.autoGroup, "/xp group off sets autoGroup=false")

  slashHandler("mob off")
  assert_equal(false, XPRateControlDB.autoMob, "/xp mob off sets autoMob=false")

  slashHandler("quest off")
  assert_equal(false, XPRateControlDB.autoQuest, "/xp quest off sets autoQuest=false")

  slashHandler("rested off")
  assert_equal(false, XPRateControlDB.autoRested, "/xp rested off sets autoRested=false")
end)

test("2.5 Utility Slash Commands (/xp minimap, status, help)", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]

  local currentMinimap = XPRateControlDB.showMinimap
  slashHandler("minimap")
  assert_equal(not currentMinimap, XPRateControlDB.showMinimap, "/xp minimap toggles showMinimap state")

  local passStatus = pcall(function() slashHandler("status") end)
  assert_true(passStatus, "/xp status executes cleanly")

  local passHelp = pcall(function() slashHandler("help") end)
  assert_true(passHelp, "/xp help executes cleanly")
end)

test("3.1 UI State Synchronization across Slash Command Modifications", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]

  slashHandler("zone on")
  assert_equal(true, XPRate.zoneCheckbox:GetChecked(), "UI zoneCheckbox updated to checked after slash command")

  slashHandler("zone off")
  assert_equal(false, XPRate.zoneCheckbox:GetChecked(), "UI zoneCheckbox updated to unchecked after slash command")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
