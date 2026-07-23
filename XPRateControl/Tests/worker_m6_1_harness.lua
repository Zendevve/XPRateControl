-- Tests/worker_m6_1_harness.lua
-- Unit test harness for Milestone 6: Notification Suppression & Quiet Automation Mode

local XPRate = {}
local addonName = "XPRateControl"

-- Mock WoW Environment
local printedMessages = {}
local showToastCalls = {}
local showTooltipCalls = {}
local hideTooltipCalls = {}
local flashMinimapCalls = {}

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
    SetPoint = function() end,
    ClearAllPoints = function() end,
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

-- Target frame structure mocks
XPRate.frame = CreateFrame("Frame", "XPRateFrame")
XPRate.RatesTabFrame = CreateFrame("Frame", "XPRateRatesTabFrame")
XPRate.AutomationTabFrame = CreateFrame("Frame", "XPRateAutomationTabFrame")
XPRate.BuffsTabFrame = CreateFrame("Frame", "XPRateBuffsTabFrame")
XPRate.ratesPresets = {}

-- Load Addon Source Files in strict TOC order
local configChunk = assert(loadfile("Core/Config.lua"))
configChunk(addonName, XPRate)
XPRate.InitDB()

local uiHelpersChunk = assert(loadfile("Core/UIHelpers.lua"))
uiHelpersChunk(addonName, XPRate)

-- Override ShowToast to track calls
local originalShowToast = XPRate.ShowToast
XPRate.ShowToast = function(text, isError)
  table.insert(showToastCalls, text)
  return originalShowToast(text, isError)
end

local networkChunk = assert(loadfile("Core/Network.lua"))
networkChunk(addonName, XPRate)

local autoChunk = assert(loadfile("Engine/Automation.lua"))
autoChunk(addonName, XPRate)

XPRate.FlashMinimapButton = function(rate)
  table.insert(flashMinimapCalls, rate)
end

local mainFrameChunk = assert(loadfile("UI/MainFrame.lua"))
mainFrameChunk(addonName, XPRate)

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
  flashMinimapCalls = {}
end

print("==================================================")
print("  XPRateControl M6 Test Harness (worker_m6_1)")
print("==================================================")

-- 1. Core/Config.lua (R1) Verification
test("1.1 Default SavedVariables initialization in InitDB()", function()
  XPRateControlDB = nil
  local db = XPRate.InitDB()
  assert_equal(true, db.showChat, "db.showChat defaults to true")
  assert_equal(true, db.showToast, "db.showToast defaults to true")
  assert_equal(false, db.quietAuto, "db.quietAuto defaults to false")
end)

test("1.2 Preservation of non-nil SavedVariables in InitDB()", function()
  XPRateControlDB = {
    showChat = false,
    showToast = false,
    quietAuto = true,
  }
  local db = XPRate.InitDB()
  assert_equal(false, db.showChat, "db.showChat preserved as false")
  assert_equal(false, db.showToast, "db.showToast preserved as false")
  assert_equal(true, db.quietAuto, "db.quietAuto preserved as true")
end)

-- 2. Core/Network.lua & Engine/Automation.lua (R2) Verification
test("2.1 ApplyRate notification suppression when showChat / showToast are toggled", function()
  resetLogs()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true

  XPRate.ApplyRate(1.5, false)
  assert_equal(1, #showToastCalls, "ShowToast called when showToast is true")
  assert_equal(1, #printedMessages, "PrintMessage called when showChat is true")

  -- Suppress chat
  resetLogs()
  XPRateControlDB.showChat = false
  XPRateControlDB.showToast = true

  XPRate.ApplyRate(1.2, false)
  assert_equal(1, #showToastCalls, "ShowToast called when showToast is true")
  assert_equal(0, #printedMessages, "PrintMessage suppressed when showChat is false")

  -- Suppress toast
  resetLogs()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = false

  XPRate.ApplyRate(1.8, false)
  assert_equal(0, #showToastCalls, "ShowToast suppressed when showToast is false")
  assert_equal(1, #printedMessages, "PrintMessage called when showChat is true")

  -- Silent parameter override
  resetLogs()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true

  XPRate.ApplyRate(1.0, true)
  assert_equal(0, #showToastCalls, "ShowToast suppressed when silent=true")
  assert_equal(0, #printedMessages, "PrintMessage suppressed when silent=true")
end)

test("2.2 EvaluateAutomation quietAuto quiet mode suppression", function()
  resetLogs()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true
  XPRateControlDB.quietAuto = false
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 2.0
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  -- EvaluateAutomation non-silent with quietAuto = false
  XPRate.EvaluateAutomation(false, "Test Trigger")
  assert_equal(1, #flashMinimapCalls, "FlashMinimapButton called when quietAuto=false")
  assert_true(#showToastCalls >= 1, "ShowToast called during auto-switch when quietAuto=false")
  assert_true(#printedMessages >= 1, "PrintMessage called during auto-switch when quietAuto=false")

  -- Now test quietAuto = true
  resetLogs()
  XPRateControlDB.quietAuto = true
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  XPRate.EvaluateAutomation(false, "Test Quiet Trigger")
  assert_equal(0, #flashMinimapCalls, "FlashMinimapButton suppressed when quietAuto=true")
  assert_equal(0, #showToastCalls, "ShowToast suppressed when quietAuto=true")
  assert_equal(0, #printedMessages, "PrintMessage suppressed when quietAuto=true")
end)

-- 3. UI/TabRates.lua (R3) Verification
test("3.1 Notifications Card Checkbox Creation & Binding", function()
  assert_true(XPRate.chatCheckbox ~= nil, "XPRate.chatCheckbox exists")
  assert_true(XPRate.toastCheckbox ~= nil, "XPRate.toastCheckbox exists")
  assert_true(XPRate.quietCheckbox ~= nil, "XPRate.quietCheckbox exists")

  -- Test UI Sync function UpdateTabRatesUI()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = false
  XPRateControlDB.quietAuto = true

  XPRate.UpdateTabRatesUI()
  assert_equal(true, XPRate.chatCheckbox:GetChecked(), "chatCheckbox syncs showChat=true")
  assert_equal(false, XPRate.toastCheckbox:GetChecked(), "toastCheckbox syncs showToast=false")
  assert_equal(true, XPRate.quietCheckbox:GetChecked(), "quietCheckbox syncs quietAuto=true")

  -- Test Checkbox Clicks
  XPRate.chatCheckbox:SetChecked(false)
  XPRate.chatCheckbox:Click()
  assert_equal(false, XPRateControlDB.showChat, "Clicking chatCheckbox updates db.showChat")

  XPRate.toastCheckbox:SetChecked(true)
  XPRate.toastCheckbox:Click()
  assert_equal(true, XPRateControlDB.showToast, "Clicking toastCheckbox updates db.showToast")

  XPRate.quietCheckbox:SetChecked(false)
  XPRate.quietCheckbox:Click()
  assert_equal(false, XPRateControlDB.quietAuto, "Clicking quietCheckbox updates db.quietAuto")
end)

test("3.2 Notifications Checkbox Tooltips", function()
  resetLogs()
  local onEnterChat = XPRate.chatCheckbox:GetScript("OnEnter")
  local onLeaveChat = XPRate.chatCheckbox:GetScript("OnLeave")
  assert_true(type(onEnterChat) == "function", "chatCheckbox OnEnter script defined")
  assert_true(type(onLeaveChat) == "function", "chatCheckbox OnLeave script defined")

  onEnterChat(XPRate.chatCheckbox)
  assert_true(#showTooltipCalls > 0, "ShowTooltip called on chatCheckbox enter")
  onLeaveChat(XPRate.chatCheckbox)
  assert_true(#hideTooltipCalls > 0, "HideTooltip called on chatCheckbox leave")
end)

-- 4. Init.lua & Slash Commands (R4) Verification
test("4.1 Slash commands (/xp chat, /xp toast, /xp quiet)", function()
  local slashHandler = SlashCmdList["XPRATECONTROL"]
  assert_true(type(slashHandler) == "function", "SlashCmdList['XPRATECONTROL'] exists")

  -- /xp chat off & on
  slashHandler("chat off")
  assert_equal(false, XPRateControlDB.showChat, "/xp chat off sets db.showChat=false")
  assert_equal(false, XPRate.chatCheckbox:GetChecked(), "/xp chat off updates UI checkmark")

  slashHandler("chat on")
  assert_equal(true, XPRateControlDB.showChat, "/xp chat on sets db.showChat=true")
  assert_equal(true, XPRate.chatCheckbox:GetChecked(), "/xp chat on updates UI checkmark")

  slashHandler("chat")
  assert_equal(false, XPRateControlDB.showChat, "/xp chat toggles state")

  -- /xp toast off & on
  slashHandler("toast off")
  assert_equal(false, XPRateControlDB.showToast, "/xp toast off sets db.showToast=false")
  assert_equal(false, XPRate.toastCheckbox:GetChecked(), "/xp toast off updates UI checkmark")

  slashHandler("toast on")
  assert_equal(true, XPRateControlDB.showToast, "/xp toast on sets db.showToast=true")
  assert_equal(true, XPRate.toastCheckbox:GetChecked(), "/xp toast on updates UI checkmark")

  slashHandler("toast")
  assert_equal(false, XPRateControlDB.showToast, "/xp toast toggles state")

  -- /xp quiet off & on
  slashHandler("quiet on")
  assert_equal(true, XPRateControlDB.quietAuto, "/xp quiet on sets db.quietAuto=true")
  assert_equal(true, XPRate.quietCheckbox:GetChecked(), "/xp quiet on updates UI checkmark")

  slashHandler("quiet off")
  assert_equal(false, XPRateControlDB.quietAuto, "/xp quiet off sets db.quietAuto=false")
  assert_equal(false, XPRate.quietCheckbox:GetChecked(), "/xp quiet off updates UI checkmark")

  slashHandler("quiet")
  assert_equal(true, XPRateControlDB.quietAuto, "/xp quiet toggles state")
end)

test("4.2 Slash status (/xp status & /xp auto status) and help (/xp help) output", function()
  resetLogs()
  local slashHandler = SlashCmdList["XPRATECONTROL"]

  slashHandler("status")
  local foundNotifStatus = false
  for _, msg in ipairs(printedMessages) do
    if string.find(msg, "Notifications:") then
      foundNotifStatus = true
    end
  end
  assert_true(foundNotifStatus, "/xp status includes Notifications line")

  resetLogs()
  slashHandler("auto status")
  foundNotifStatus = false
  for _, msg in ipairs(printedMessages) do
    if string.find(msg, "Notifications:") then
      foundNotifStatus = true
    end
  end
  assert_true(foundNotifStatus, "/xp auto status includes Notifications line")

  resetLogs()
  slashHandler("help")
  local foundQuietHelp = false
  local foundChatHelp = false
  local foundToastHelp = false
  for _, msg in ipairs(printedMessages) do
    if string.find(msg, "/xp quiet") then foundQuietHelp = true end
    if string.find(msg, "/xp chat") then foundChatHelp = true end
    if string.find(msg, "/xp toast") then foundToastHelp = true end
  end
  assert_true(foundQuietHelp, "/xp help documents /xp quiet")
  assert_true(foundChatHelp, "/xp help documents /xp chat")
  assert_true(foundToastHelp, "/xp help documents /xp toast")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
end
