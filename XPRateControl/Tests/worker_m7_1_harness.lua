-- Tests/worker_m7_1_harness.lua
-- Unit & Integration test harness for Milestone 7: Dedicated Settings Tab & UI Layout Cleanup

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW Environment
local printedMessages = {}
local showToastCalls = {}
local showTooltipCalls = {}
local hideTooltipCalls = {}
local applyRateCalls = {}

DEFAULT_CHAT_FRAME = {
  AddMessage = function(self, msg)
    table.insert(printedMessages, msg)
  end
}
SlashCmdList = {}
UISpecialFrames = {}

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
    point = nil,
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
        SetJustifyV = function() end,
        SetAllPoints = function() end,
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
        SetAllPoints = function() end,
        SetGradientAlpha = function() end,
        SetBlendMode = function() end,
        SetHeight = function() end,
      }
      table.insert(self.textures, tex)
      return tex
    end,
    SetSize = function(self, w, h) self.width = w; self.height = h end,
    SetWidth = function(self, w) self.width = w end,
    SetHeight = function(self, h) self.height = h end,
    GetSize = function(self) return self.width, self.height end,
    SetPoint = function(self, pt, relTo, relPt, x, y)
      self.point = { pt = pt, relTo = relTo, relPt = relPt, x = x, y = y }
    end,
    GetPoint = function(self)
      if self.point then
        return self.point.pt, self.point.relTo, self.point.relPt, self.point.x, self.point.y
      end
      return "CENTER", nil, "CENTER", 0, 0
    end,
    ClearAllPoints = function(self) self.point = nil end,
    SetBackdrop = function(self, bd) self.backdrop = bd end,
    SetBackdropColor = function(self, r, g, b, a) self.bgColor = {r, g, b, a} end,
    SetBackdropBorderColor = function(self, r, g, b, a) self.edgeColor = {r, g, b, a} end,
    Show = function(self) self.shown = true end,
    Hide = function(self) self.shown = false end,
    IsShown = function(self) return self.shown end,
    SetAlpha = function(self, a) self.alpha = a end,
    GetAlpha = function(self) return self.alpha or 1 end,
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
    SetMinMaxValues = function() end,
    SetValueStep = function() end,
    SetOrientation = function() end,
    SetThumbTexture = function() end,
    GetValue = function() return 1.0 end,
    SetValue = function() end,
    EnableMouseWheel = function() end,
    EnableMouse = function() end,
    SetMovable = function() end,
    SetClampedToScreen = function() end,
    RegisterForDrag = function() end,
    StartMoving = function() end,
    StopMovingOrSizing = function() end,
    Click = function(self)
      local onClick = self:GetScript("OnClick")
      if onClick then onClick(self) end
    end
  }
  table.insert(createdFrames, frame)
  if name then _G[name] = frame end
  return frame
end

UIParent = CreateFrame("Frame", "UIParent")
XPRateMinimapButtonBorder = { SetVertexColor = function() end }

-- Global API stubs
strtrim = function(s) return s and s:match("^%s*(.-)%s*$") or "" end
tinsert = table.insert
UnitLevel = function(unit) return 70 end
UnitGUID = function(unit) return "Player-1" end
GetNumPartyMembers = function() return 0 end
GetNumRaidMembers = function() return 0 end
IsInInstance = function() return false, "none" end
GetRealZoneText = function() return "Elwynn Forest" end
GetQuestDifficultyColor = function(level) return {r=1, g=1, b=1} end
GetXPExhaustion = function() return 0 end
SendChatMessage = function() end

GameTooltip = {
  SetOwner = function() end,
  SetText = function(self, txt)
    table.insert(showTooltipCalls, txt)
  end,
  Show = function() end,
  Hide = function()
    table.insert(hideTooltipCalls, true)
  end
}

-- Load Addon Source Files in strict TOC order
local configChunk = assert(loadfile("Core/Config.lua"))
configChunk(addonName, XPRate)
XPRate.InitDB()

local uiHelpersChunk = assert(loadfile("Core/UIHelpers.lua"))
uiHelpersChunk(addonName, XPRate)

-- Track ShowToast calls
local originalShowToast = XPRate.ShowToast
XPRate.ShowToast = function(text, isError)
  table.insert(showToastCalls, text)
  if originalShowToast then return originalShowToast(text, isError) end
end

local networkChunk = assert(loadfile("Core/Network.lua"))
networkChunk(addonName, XPRate)

-- Track ApplyRate calls
local originalApplyRate = XPRate.ApplyRate
XPRate.ApplyRate = function(rate, silent)
  table.insert(applyRateCalls, { rate = rate, silent = silent })
  if originalApplyRate then return originalApplyRate(rate, silent) end
end

local autoChunk = assert(loadfile("Engine/Automation.lua"))
autoChunk(addonName, XPRate)

XPRate.ratesPresets = {}

local mainFrameChunk = assert(loadfile("UI/MainFrame.lua"))
mainFrameChunk(addonName, XPRate)

-- Mock Minimap Button
local minimapButton = CreateFrame("Button", "XPRateMinimapButton", UIParent)
XPRate.minimapButton = minimapButton

local tabRatesChunk = assert(loadfile("UI/TabRates.lua"))
tabRatesChunk(addonName, XPRate)

local tabSettingsChunk = assert(loadfile("UI/TabSettings.lua"))
tabSettingsChunk(addonName, XPRate)

local initChunk = assert(loadfile("Init.lua"))
initChunk(addonName, XPRate)

-- Test Engine
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

local function resetLogs()
  printedMessages = {}
  showToastCalls = {}
  showTooltipCalls = {}
  hideTooltipCalls = {}
  applyRateCalls = {}
end

print("==================================================")
print("  XPRateControl M7 Test Harness (worker_m7_1)")
print("==================================================")

-- 1. MainFrame Navigation Bar (4 Tabs)
test("1.1 Navigation Bar 4-Tab Layout Allocation (Rates, Auto, Buffs, Settings)", function()
  assert_true(XPRate.SettingsTabFrame ~= nil, "XPRate.SettingsTabFrame exists")
  assert_equal(308, XPRate.SettingsTabFrame.width, "SettingsTabFrame width is 308")
  assert_equal(230, XPRate.SettingsTabFrame.height, "SettingsTabFrame height is 230")

  -- Verify SetActiveTab handles tab 4
  XPRate.SetActiveTab(4)
  assert_true(XPRate.SettingsTabFrame:IsShown(), "SettingsTabFrame is shown when active tab is 4")
  assert_equal(false, XPRate.RatesTabFrame:IsShown(), "RatesTabFrame is hidden when active tab is 4")
  assert_equal(false, XPRate.AutomationTabFrame:IsShown(), "AutomationTabFrame is hidden when active tab is 4")
  assert_equal(false, XPRate.BuffsTabFrame:IsShown(), "BuffsTabFrame is hidden when active tab is 4")

  -- Switch back to tab 1
  XPRate.SetActiveTab(1)
  assert_true(XPRate.RatesTabFrame:IsShown(), "RatesTabFrame is shown when active tab is 1")
  assert_equal(false, XPRate.SettingsTabFrame:IsShown(), "SettingsTabFrame is hidden when active tab is 1")
end)

-- 2. Rates Tab Clean Layout
test("2.1 Rates Tab Layout Cleanup (notifCard removed)", function()
  assert_equal(nil, _G["XPRateNotifCard"], "XPRateNotifCard is removed from RatesTabFrame")
  assert_true(type(XPRate.UpdateTabRatesUI) == "function", "UpdateTabRatesUI is defined as forwarder function")
end)

-- 3. Settings Tab Component Integrity
test("3.1 Settings Tab UI Cards and Widgets", function()
  assert_true(XPRate.showChatCheckbox ~= nil, "XPRate.showChatCheckbox exists")
  assert_true(XPRate.showToastCheckbox ~= nil, "XPRate.showToastCheckbox exists")
  assert_true(XPRate.quietAutoCheckbox ~= nil, "XPRate.quietAutoCheckbox exists")
  assert_true(XPRate.showMinimapCheckbox ~= nil, "XPRate.showMinimapCheckbox exists")
  assert_true(XPRate.masterEnableCheckbox ~= nil, "XPRate.masterEnableCheckbox exists")

  assert_true(_G["XPRateSettingsNotifCard"] ~= nil, "XPRateSettingsNotifCard exists")
  assert_true(_G["XPRateSettingsMinimapCard"] ~= nil, "XPRateSettingsMinimapCard exists")
  assert_true(_G["XPRateSettingsMaintCard"] ~= nil, "XPRateSettingsMaintCard exists")
end)

-- 4. Checkbox State Synchronization & OnClick Logic
test("4.1 Card 1 (Notifications) Checkbox Interactions", function()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = false
  XPRateControlDB.quietAuto = true

  XPRate.UpdateSettingsTabUI()
  assert_equal(true, XPRate.showChatCheckbox:GetChecked(), "showChatCheckbox syncs to db.showChat=true")
  assert_equal(false, XPRate.showToastCheckbox:GetChecked(), "showToastCheckbox syncs to db.showToast=false")
  assert_equal(true, XPRate.quietAutoCheckbox:GetChecked(), "quietAutoCheckbox syncs to db.quietAuto=true")

  -- Click chatCheckbox
  XPRate.showChatCheckbox:SetChecked(false)
  XPRate.showChatCheckbox:Click()
  assert_equal(false, XPRateControlDB.showChat, "Clicking showChatCheckbox sets db.showChat=false")

  -- Click toastCheckbox
  XPRate.showToastCheckbox:SetChecked(true)
  XPRate.showToastCheckbox:Click()
  assert_equal(true, XPRateControlDB.showToast, "Clicking showToastCheckbox sets db.showToast=true")

  -- Click quietAutoCheckbox
  XPRate.quietAutoCheckbox:SetChecked(false)
  XPRate.quietAutoCheckbox:Click()
  assert_equal(false, XPRateControlDB.quietAuto, "Clicking quietAutoCheckbox sets db.quietAuto=false")
end)

test("4.2 Card 2 (Minimap) Checkbox Interaction", function()
  XPRateControlDB.showMinimap = true
  XPRate.UpdateSettingsTabUI()
  assert_equal(true, XPRate.showMinimapCheckbox:GetChecked(), "showMinimapCheckbox syncs to db.showMinimap=true")

  -- Toggle Off
  XPRate.showMinimapCheckbox:SetChecked(false)
  XPRate.showMinimapCheckbox:Click()
  assert_equal(false, XPRateControlDB.showMinimap, "Clicking showMinimapCheckbox sets db.showMinimap=false")
  assert_equal(false, XPRate.minimapButton:IsShown(), "Minimap button hidden when showMinimap is false")

  -- Toggle On
  XPRate.showMinimapCheckbox:SetChecked(true)
  XPRate.showMinimapCheckbox:Click()
  assert_equal(true, XPRateControlDB.showMinimap, "Clicking showMinimapCheckbox sets db.showMinimap=true")
  assert_equal(true, XPRate.minimapButton:IsShown(), "Minimap button shown when showMinimap is true")
end)

test("4.3 Card 3 (Master Automation Toggle) Interaction", function()
  local db = XPRateControlDB
  db.autoRested = false
  db.autoGroup = false
  db.autoDisparity = false
  db.autoMob = false
  db.autoQuest = false
  db.autoBracket = false
  db.autoZone = false

  XPRate.UpdateSettingsTabUI()
  assert_equal(false, XPRate.masterEnableCheckbox:GetChecked(), "Master checkbox unchecked when auto modules are off")

  -- Enable Master Toggle
  XPRate.masterEnableCheckbox:SetChecked(true)
  XPRate.masterEnableCheckbox:Click()

  assert_equal(true, db.autoRested, "Master enable sets autoRested=true")
  assert_equal(true, db.autoGroup, "Master enable sets autoGroup=true")
  assert_equal(true, db.autoDisparity, "Master enable sets autoDisparity=true")
  assert_equal(true, db.autoMob, "Master enable sets autoMob=true")
  assert_equal(true, db.autoQuest, "Master enable sets autoQuest=true")
  assert_equal(true, db.autoBracket, "Master enable sets autoBracket=true")
  assert_equal(true, db.autoZone, "Master enable sets autoZone=true")

  assert_equal(true, XPRate.masterEnableCheckbox:GetChecked(), "Master checkbox checked when all modules are on")

  -- Disable Master Toggle
  XPRate.masterEnableCheckbox:SetChecked(false)
  XPRate.masterEnableCheckbox:Click()

  assert_equal(false, db.autoRested, "Master disable sets autoRested=false")
  assert_equal(false, db.autoGroup, "Master disable sets autoGroup=false")
  assert_equal(false, db.autoDisparity, "Master disable sets autoDisparity=false")
  assert_equal(false, db.autoMob, "Master disable sets autoMob=false")
  assert_equal(false, db.autoQuest, "Master disable sets autoQuest=false")
  assert_equal(false, db.autoBracket, "Master disable sets autoBracket=false")
  assert_equal(false, db.autoZone, "Master disable sets autoZone=false")
end)

test("4.4 Card 3 (Reset Defaults Button) Execution", function()
  resetLogs()
  XPRateControlDB.lastRate = 1.5
  XPRateControlDB.showChat = false
  XPRateControlDB.showToast = false
  XPRateControlDB.quietAuto = true
  XPRateControlDB.autoZone = true

  -- Find reset button inside maintCard
  local maintCard = _G["XPRateSettingsMaintCard"]
  assert_true(maintCard ~= nil, "maintCard frame exists")

  -- Trigger reset defaults OnClick
  local resetBtn
  for _, frame in ipairs(createdFrames) do
    if frame.parent == maintCard and frame.label and frame.label:GetText() == "Reset Defaults" then
      resetBtn = frame
      break
    end
  end

  assert_true(resetBtn ~= nil, "Reset Defaults button found")
  resetBtn:Click()

  -- Assert DB reset to defaults
  assert_equal(1.0, XPRateControlDB.lastRate, "Reset defaults restores lastRate=1.0")
  assert_equal(true, XPRateControlDB.showChat, "Reset defaults restores showChat=true")
  assert_equal(true, XPRateControlDB.showToast, "Reset defaults restores showToast=true")
  assert_equal(false, XPRateControlDB.quietAuto, "Reset defaults restores quietAuto=false")
  assert_equal(false, XPRateControlDB.autoZone, "Reset defaults restores autoZone=false")

  -- Assert toast notification fired
  assert_true(#showToastCalls > 0, "Toast notification displayed on Reset Defaults")
  assert_true(#applyRateCalls > 0, "ApplyRate called on Reset Defaults")
end)

-- 5. Slash Command Integration with Settings UI Sync
test("5.1 Slash Commands Update Settings Tab UI State", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]
  assert_true(type(slashHandler) == "function", "Slash handler exists")

  slashHandler("chat off")
  assert_equal(false, XPRateControlDB.showChat, "/xp chat off updates db")
  assert_equal(false, XPRate.showChatCheckbox:GetChecked(), "/xp chat off updates Settings UI checkbox")

  slashHandler("toast off")
  assert_equal(false, XPRateControlDB.showToast, "/xp toast off updates db")
  assert_equal(false, XPRate.showToastCheckbox:GetChecked(), "/xp toast off updates Settings UI checkbox")

  slashHandler("quiet on")
  assert_equal(true, XPRateControlDB.quietAuto, "/xp quiet on updates db")
  assert_equal(true, XPRate.quietAutoCheckbox:GetChecked(), "/xp quiet on updates Settings UI checkbox")

  slashHandler("minimap")
  assert_equal(false, XPRateControlDB.showMinimap, "/xp minimap toggles db.showMinimap")
  assert_equal(false, XPRate.showMinimapCheckbox:GetChecked(), "/xp minimap updates Settings UI checkbox")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
