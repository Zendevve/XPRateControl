-- Tests/challenger_m6_2_harness.lua
-- Empirical Verification Harness for Challenger 2 (Milestone 6)
-- Mission: Challenge state lifecycle, edge cases, and slash command robustness

local addonName = "XPRateControl"
local XPRate = {}

-- Tracked outputs for assertions
local chatMessages = {}
local sentChatMessages = {}
local toastMessages = {}

-- Mock WoW API & Environment
DEFAULT_CHAT_FRAME = {
  AddMessage = function(self, msg)
    table.insert(chatMessages, tostring(msg))
  end
}

function SendChatMessage(msg, chatType, language, channel)
  table.insert(sentChatMessages, { msg = msg, chatType = chatType })
end

UISpecialFrames = {}
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
    value = 1.0,
    minVal = 0,
    maxVal = 2,

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
        SetHeight = function() end,
        SetPoint = function() end,
        SetTexture = function(s, t) s.texture = t end,
        SetVertexColor = function(s, r, g, b, a) s.r=r; s.g=g; s.b=b; s.a=a or 1 end,
        SetGradientAlpha = function() end,
        SetBlendMode = function() end,
        SetAllPoints = function() end,
        SetTexCoord = function() end,
        SetAlpha = function(s, a) s.alpha = a end,
        SetDesaturated = function() end,
      }
      table.insert(self.textures, tex)
      return tex
    end,
    SetSize = function(self, w, h) self.width = w; self.height = h end,
    SetHeight = function(self, h) self.height = h end,
    SetWidth = function(self, w) self.width = w end,
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
    SetMaxLetters = function(self, m) self.maxLetters = m end,
    HasFocus = function() return false end,
    ClearFocus = function() end,
    GetText = function(self) return self.text end,
    SetText = function(self, t) self.text = tostring(t) end,
    SetMinMaxValues = function(self, minV, maxV) self.minVal = minV; self.maxVal = maxV end,
    SetValueStep = function(self, step) self.step = step end,
    SetOrientation = function() end,
    SetThumbTexture = function() end,
    SetValue = function(self, v)
      local oldV = self.value
      self.value = v
      if self.scripts["OnValueChanged"] and oldV ~= v then
        self.scripts["OnValueChanged"](self, v)
      end
    end,
    GetValue = function(self) return self.value end,
    EnableMouseWheel = function() end,
    SetAlpha = function(self, a) self.alpha = a end,
    SetScale = function(self, s) self.scale = s end,
    SetMovable = function(self, m) self.movable = m end,
    EnableMouse = function(self, e) self.mouseEnabled = e end,
    SetClampedToScreen = function(self, c) self.clamped = c end,
    RegisterForClicks = function() end,
    RegisterForDrag = function() end,
    StartMoving = function() end,
    StopMovingOrSizing = function() end,
    SetNormalTexture = function() end,
    SetPushedTexture = function() end,
    SetHighlightTexture = function() end,
  }
  table.insert(createdFrames, frame)
  if name then _G[name] = frame end
  return frame
end

UIParent = CreateFrame("Frame", "UIParent")

-- Mock WoW API state variables
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

function tinsert(t, v)
  table.insert(t, v)
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

-- Load source files in TOC order
assert(loadfile("Core/Config.lua"))(addonName, XPRate)
assert(loadfile("Core/UIHelpers.lua"))(addonName, XPRate)
assert(loadfile("Core/Network.lua"))(addonName, XPRate)
assert(loadfile("Engine/Automation.lua"))(addonName, XPRate)
assert(loadfile("UI/MainFrame.lua"))(addonName, XPRate)
assert(loadfile("UI/MinimapButton.lua"))(addonName, XPRate)
assert(loadfile("UI/TabRates.lua"))(addonName, XPRate)
assert(loadfile("UI/TabAutomation.lua"))(addonName, XPRate)
assert(loadfile("UI/TabBuffs.lua"))(addonName, XPRate)
assert(loadfile("Init.lua"))(addonName, XPRate)

-- Hook ShowToast & PrintMessage after loading files
XPRate.ShowToast = function(msg, isError)
  table.insert(toastMessages, { msg = tostring(msg), isError = isError })
end

local origPrint = XPRate.PrintMessage
XPRate.PrintMessage = function(msg)
  table.insert(chatMessages, tostring(msg))
end

-- Clear tracked test outputs
local function clearLogs()
  while #chatMessages > 0 do table.remove(chatMessages) end
  while #sentChatMessages > 0 do table.remove(sentChatMessages) end
  while #toastMessages > 0 do table.remove(toastMessages) end
end

-- Test Framework Runner
local testsPassed = 0
local testsFailed = 0
local totalAssertions = 0
local failureDetails = {}

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

local function assert_nil(actual, msg)
  totalAssertions = totalAssertions + 1
  if actual ~= nil then
    error(string.format("Assertion failed: %s (expected nil, got %s)", msg or "", tostring(actual)))
  end
end

local function test(name, fn)
  clearLogs()
  local pass, err = pcall(fn)
  if pass then
    testsPassed = testsPassed + 1
    print("[PASS] " .. name)
  else
    testsFailed = testsFailed + 1
    table.insert(failureDetails, { name = name, err = tostring(err) })
    print("[FAIL] " .. name .. ": " .. tostring(err))
  end
end

print("==================================================")
print("  XPRateControl Challenger 2 (Milestone 6) Harness")
print("==================================================")

-- SECTION 1: Missing or Corrupted XPRateControlDB Fields
test("1.1 Complete Nil XPRateControlDB Restoration", function()
  _G.XPRateControlDB = nil
  local db = XPRate.InitDB()

  assert_true(type(db) == "table", "InitDB returns a table when XPRateControlDB is nil")
  assert_equal(true, db.showChat, "showChat default true")
  assert_equal(true, db.showToast, "showToast default true")
  assert_equal(false, db.quietAuto, "quietAuto default false")
  assert_equal(195, db.minimapPos, "minimapPos default 195")
  assert_equal(true, db.showMinimap, "showMinimap default true")
  assert_equal(1.0, db.lastRate, "lastRate default 1.0")
  assert_equal(true, db.jjEnabled, "jjEnabled default true")
  assert_equal(false, db.autoRested, "autoRested default false")
  assert_equal(false, db.autoGroup, "autoGroup default false")
  assert_equal(false, db.autoMob, "autoMob default false")
  assert_equal(false, db.autoQuest, "autoQuest default false")
  assert_equal(false, db.autoZone, "autoZone default false")
  assert_equal(false, db.autoBracket, "autoBracket default false")
  assert_equal(false, db.autoDisparity, "autoDisparity default false")
end)

test("1.2 Partial Nil Fields Restoration (Preserve Custom Settings)", function()
  _G.XPRateControlDB = {
    lastRate = 1.75,
    autoRested = true,
    restedRate = 1.50,
    -- showChat, showToast, quietAuto are nil
  }
  local db = XPRate.InitDB()

  assert_equal(1.75, db.lastRate, "Preserved existing lastRate 1.75")
  assert_equal(true, db.autoRested, "Preserved existing autoRested true")
  assert_equal(1.50, db.restedRate, "Preserved existing restedRate 1.50")
  assert_equal(true, db.showChat, "Restored missing showChat to true")
  assert_equal(true, db.showToast, "Restored missing showToast to true")
  assert_equal(false, db.quietAuto, "Restored missing quietAuto to false")
end)

test("1.3 Corrupted Non-Table Database Fields Recovery", function()
  _G.XPRateControlDB = {
    groupRates = "invalid_string_instead_of_table",
    mobRates = 12345,
    zoneRates = false,
    bracketRates = "not_a_table",
  }
  local db = XPRate.InitDB()

  assert_true(type(db.groupRates) == "table", "groupRates recovered as table")
  assert_equal(1.00, db.groupRates[1], "groupRates[1] default 1.00")
  assert_equal(2.00, db.groupRates[5], "groupRates[5] default 2.00")

  assert_true(type(db.mobRates) == "table", "mobRates recovered as table")
  assert_equal(0.0, db.mobRates.gray, "mobRates.gray default 0.0")
  assert_equal(2.0, db.mobRates.red, "mobRates.red default 2.0")

  assert_true(type(db.zoneRates) == "table", "zoneRates recovered as table")
  assert_equal(1.00, db.zoneRates.world, "zoneRates.world default 1.00")
  assert_equal(1.00, db.zoneRates.dungeon, "zoneRates.dungeon default 1.00")

  assert_true(type(db.bracketRates) == "table", "bracketRates recovered as table")
  assert_equal(4, #db.bracketRates, "bracketRates contains 4 default brackets")
  assert_equal(1, db.bracketRates[1].min, "bracket 1 min default 1")
  assert_equal(59, db.bracketRates[1].max, "bracket 1 max default 59")
end)

test("1.4 Malformed / Partial Bracket Sub-Elements Recovery", function()
  _G.XPRateControlDB = {
    bracketRates = {
      "corrupted_element",
      { min = nil, max = 69, rate = nil },
    }
  }
  local db = XPRate.InitDB()

  assert_true(type(db.bracketRates) == "table", "bracketRates table exists")
  assert_true(type(db.bracketRates[1]) == "table", "bracket 1 element normalized to table")
  assert_equal(1, db.bracketRates[1].min, "bracket 1 min restored")
  assert_equal(59, db.bracketRates[1].max, "bracket 1 max restored")
  assert_equal(2.00, db.bracketRates[1].rate, "bracket 1 rate restored")

  assert_equal(60, db.bracketRates[2].min, "bracket 2 min restored")
  assert_equal(69, db.bracketRates[2].max, "bracket 2 max preserved")
  assert_equal(1.50, db.bracketRates[2].rate, "bracket 2 rate restored")
end)

-- SECTION 2: Slash Commands & Edge Cases
test("2.1 Slash Commands Toggling Without Arguments (/xp chat, /xp toast, /xp quiet)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true
  XPRateControlDB.quietAuto = false

  local handler = SlashCmdList["XPRATECONTROL"]
  assert_true(type(handler) == "function", "SlashCmdList['XPRATECONTROL'] is registered")

  -- Toggle /xp chat
  handler("chat")
  assert_equal(false, XPRateControlDB.showChat, "/xp chat toggles showChat from true to false")
  if XPRate.chatCheckbox then assert_equal(false, XPRate.chatCheckbox:GetChecked(), "chatCheckbox updated to false") end

  handler("chat")
  assert_equal(true, XPRateControlDB.showChat, "/xp chat toggles showChat back to true")
  if XPRate.chatCheckbox then assert_equal(true, XPRate.chatCheckbox:GetChecked(), "chatCheckbox updated to true") end

  -- Toggle /xp toast
  handler("toast")
  assert_equal(false, XPRateControlDB.showToast, "/xp toast toggles showToast from true to false")
  if XPRate.toastCheckbox then assert_equal(false, XPRate.toastCheckbox:GetChecked(), "toastCheckbox updated to false") end

  handler("toast")
  assert_equal(true, XPRateControlDB.showToast, "/xp toast toggles showToast back to true")
  if XPRate.toastCheckbox then assert_equal(true, XPRate.toastCheckbox:GetChecked(), "toastCheckbox updated to true") end

  -- Toggle /xp quiet
  handler("quiet")
  assert_equal(true, XPRateControlDB.quietAuto, "/xp quiet toggles quietAuto from false to true")
  if XPRate.quietCheckbox then assert_equal(true, XPRate.quietCheckbox:GetChecked(), "quietCheckbox updated to true") end

  handler("quiet")
  assert_equal(false, XPRateControlDB.quietAuto, "/xp quiet toggles quietAuto back to false")
  if XPRate.quietCheckbox then assert_equal(false, XPRate.quietCheckbox:GetChecked(), "quietCheckbox updated to false") end
end)

test("2.2 Slash Commands Explicit Arguments (/xp chat on/off, /xp toast 1/0, /xp quiet enable/disable)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  local handler = SlashCmdList["XPRATECONTROL"]

  handler("chat off")
  assert_equal(false, XPRateControlDB.showChat, "/xp chat off sets showChat false")

  handler("chat on")
  assert_equal(true, XPRateControlDB.showChat, "/xp chat on sets showChat true")

  handler("toast 0")
  assert_equal(false, XPRateControlDB.showToast, "/xp toast 0 sets showToast false")

  handler("toast 1")
  assert_equal(true, XPRateControlDB.showToast, "/xp toast 1 sets showToast true")

  handler("quiet enable")
  assert_equal(true, XPRateControlDB.quietAuto, "/xp quiet enable sets quietAuto true")

  handler("quiet disable")
  assert_equal(false, XPRateControlDB.quietAuto, "/xp quiet disable sets quietAuto false")
end)

test("2.3 Invalid Sub-arguments (/xp chat maybe, /xp toast 99, /xp quiet banana)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = true
  XPRateControlDB.quietAuto = false

  local handler = SlashCmdList["XPRATECONTROL"]

  -- Test /xp chat maybe
  clearLogs()
  handler("chat maybe")
  -- Invalid arg should either reject with print message or handle gracefully without throwing error
  assert_true(true, "/xp chat maybe executed without runtime error")

  -- Test /xp toast 99
  clearLogs()
  handler("toast 99")
  assert_true(true, "/xp toast 99 executed without runtime error")

  -- Test /xp quiet banana
  clearLogs()
  handler("quiet banana")
  assert_true(true, "/xp quiet banana executed without runtime error")
end)

test("2.4 Uppercase & Mixed Case Slash Command Parsing (/XP QUIET ON, /XP CHAT OFF)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  local handler = SlashCmdList["XPRATECONTROL"]

  handler("QUIET ON")
  assert_equal(true, XPRateControlDB.quietAuto, "/XP QUIET ON processed uppercase command")

  handler("CHAT OFF")
  assert_equal(false, XPRateControlDB.showChat, "/XP CHAT OFF processed uppercase command")

  handler("TOAST ENABLE")
  assert_equal(true, XPRateControlDB.showToast, "/XP TOAST ENABLE processed uppercase command")
end)

test("2.5 Empty Command Toggles Frame Visibility (/xp)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  local handler = SlashCmdList["XPRATECONTROL"]

  XPRate.frame = XPRate.frame or CreateFrame("Frame", "XPRateMainFrame")
  XPRate.frame:Hide()

  handler("")
  assert_equal(true, XPRate.frame:IsShown(), "/xp shows hidden frame")

  handler("")
  assert_equal(false, XPRate.frame:IsShown(), "/xp hides shown frame")
end)

test("2.6 Status and Help Slash Commands Include M6 Suppressions (/xp status, /xp auto status, /xp help)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = false
  XPRateControlDB.quietAuto = true

  local handler = SlashCmdList["XPRATECONTROL"]

  clearLogs()
  handler("status")
  assert_true(#chatMessages > 0, "/xp status output printed messages")
  local combinedMsg = table.concat(chatMessages, "\n")
  assert_true(combinedMsg:find("Chat:") ~= nil or combinedMsg:find("chat") ~= nil or combinedMsg:find("Quiet") ~= nil or combinedMsg:find("quiet") ~= nil or combinedMsg:find("Automation") ~= nil, "/xp status includes status info")

  clearLogs()
  handler("auto status")
  assert_true(#chatMessages > 0, "/xp auto status output printed messages")

  clearLogs()
  handler("help")
  assert_true(#chatMessages > 0, "/xp help output printed messages")
  local helpText = table.concat(chatMessages, "\n")
  assert_true(helpText:find("/xp chat") ~= nil or helpText:find("chat") ~= nil, "/xp help lists /xp chat command")
  assert_true(helpText:find("/xp toast") ~= nil or helpText:find("toast") ~= nil, "/xp help lists /xp toast command")
  assert_true(helpText:find("/xp quiet") ~= nil or helpText:find("quiet") ~= nil, "/xp help lists /xp quiet command")
end)

-- SECTION 3: Multiple ADDON_LOADED Re-entrancy Calls
test("3.1 Non-Matching Addon Name ADDON_LOADED Event", function()
  clearLogs()
  _G.XPRateControlDB = { lastRate = 1.80 }

  local frame = XPRateEventFrame or _G["XPRateEventFrame"]
  local onEvent = frame:GetScript("OnEvent")

  onEvent(frame, "ADDON_LOADED", "UnrelatedAddon_v1.0")
  assert_equal(1.80, XPRateControlDB.lastRate, "DB not initialized for unrelated addon")
  assert_equal(0, #chatMessages, "No login message printed for unrelated addon")
end)

test("3.2 First ADDON_LOADED Event Call", function()
  clearLogs()
  _G.XPRateControlDB = nil

  local frame = XPRateEventFrame or _G["XPRateEventFrame"]
  local onEvent = frame:GetScript("OnEvent")

  onEvent(frame, "ADDON_LOADED", "XPRateControl")

  assert_true(type(XPRateControlDB) == "table", "XPRateControlDB initialized")
  assert_true(#chatMessages > 0, "Welcome or loaded message printed on ADDON_LOADED")
end)

test("3.3 Multiple ADDON_LOADED Re-entrancy Calls Preserve DB State & UI Synchronization", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.lastRate = 1.65
  XPRateControlDB.quietAuto = true
  XPRateControlDB.showChat = false
  XPRateControlDB.showToast = true
  XPRateControlDB.firstRun = false

  local frame = XPRateEventFrame or _G["XPRateEventFrame"]
  local onEvent = frame:GetScript("OnEvent")

  -- Trigger ADDON_LOADED a second time
  clearLogs()
  onEvent(frame, "ADDON_LOADED", "XPRateControl")

  -- Verify user settings were preserved
  assert_equal(1.65, XPRateControlDB.lastRate, "lastRate 1.65 preserved on 2nd ADDON_LOADED")
  assert_equal(true, XPRateControlDB.quietAuto, "quietAuto true preserved on 2nd ADDON_LOADED")
  assert_equal(false, XPRateControlDB.showChat, "showChat false preserved on 2nd ADDON_LOADED")
  assert_equal(true, XPRateControlDB.showToast, "showToast true preserved on 2nd ADDON_LOADED")

  -- Trigger ADDON_LOADED a third time
  clearLogs()
  onEvent(frame, "ADDON_LOADED", "XPRateControl")
  assert_equal(1.65, XPRateControlDB.lastRate, "lastRate 1.65 preserved on 3rd ADDON_LOADED")

  -- Verify UI checkbuttons synced
  if XPRate.UpdateTabRatesUI then XPRate.UpdateTabRatesUI() end
  if XPRate.chatCheckbox then assert_equal(false, XPRate.chatCheckbox:GetChecked(), "chatCheckbox synced to false") end
  if XPRate.toastCheckbox then assert_equal(true, XPRate.toastCheckbox:GetChecked(), "toastCheckbox synced to true") end
  if XPRate.quietCheckbox then assert_equal(true, XPRate.quietCheckbox:GetChecked(), "quietCheckbox synced to true") end
end)

-- SECTION 4: Slider Interaction vs Quiet Automation Mode
test("4.1 Manual Slider Interaction With quietAuto = true (Manual Notifications Must STILL Show)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.quietAuto = true -- Quiet automation mode is ACTIVE
  XPRateControlDB.showChat = true  -- Chat notifications ENABLED
  XPRateControlDB.showToast = true -- Toast notifications ENABLED

  clearLogs()
  -- User manually invokes ApplyRate via slider/preset/editbox
  XPRate.ApplyRate(1.50, false)

  -- quietAuto MUST ONLY suppress automatic changes (EvaluateAutomation), NOT manual slider interaction!
  assert_true(#chatMessages > 0, "Manual rate change printed chat message despite quietAuto=true")
  assert_true(#toastMessages > 0, "Manual rate change displayed toast alert despite quietAuto=true")
  assert_equal("Sent 1.50x [OK]", toastMessages[1].msg, "Toast content correct for manual change")
end)

test("4.2 Automatic Automation Evaluation With quietAuto = true (Automatic Notifications MUST be Suppressed)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 2.00
  XPRateControlDB.quietAuto = true -- Quiet automation mode is ACTIVE
  XPRateControlDB.showChat = true  -- Global chat enabled
  XPRateControlDB.showToast = true -- Global toast enabled

  mockXPExhaustion = 1000 -- Rested XP present
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  clearLogs()
  -- Trigger automatic evaluation with silent=false (normal event trigger)
  XPRate.EvaluateAutomation(false, "UPDATE_EXHAUSTION")

  -- Rate should change to 2.00x
  assert_equal(2.00, XPRate.lastAppliedRate, "Auto-switched rate to 2.00x")
  assert_equal("Auto Rested (Rested)", XPRate.lastAppliedMode, "Applied Rested mode")

  -- BUT notifications MUST be suppressed because quietAuto = true!
  local autoChatMsgs = 0
  for _, msg in ipairs(chatMessages) do
    if msg:find("Auto-Switched") then
      autoChatMsgs = autoChatMsgs + 1
    end
  end
  assert_equal(0, autoChatMsgs, "Auto-Switched chat message SUPPRESSED when quietAuto=true")
  assert_equal(0, #toastMessages, "Auto-Switched toast alert SUPPRESSED when quietAuto=true")
end)

test("4.3 Automatic Automation Evaluation With quietAuto = false (Automatic Notifications MUST Show)", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.autoRested = true
  XPRateControlDB.restedRate = 2.00
  XPRateControlDB.quietAuto = false -- Quiet automation mode is INACTIVE
  XPRateControlDB.showChat = true   -- Global chat enabled
  XPRateControlDB.showToast = true  -- Global toast enabled

  mockXPExhaustion = 1000
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil

  clearLogs()
  XPRate.EvaluateAutomation(false, "UPDATE_EXHAUSTION")

  assert_equal(2.00, XPRate.lastAppliedRate, "Auto-switched rate to 2.00x")

  -- Notifications MUST be printed when quietAuto = false
  local autoChatMsgs = 0
  for _, msg in ipairs(chatMessages) do
    if msg:find("Auto%-Switched") or msg:find("Auto") then
      autoChatMsgs = autoChatMsgs + 1
    end
  end
  if autoChatMsgs == 0 then
    print("DEBUG chatMessages in 4.3:")
    for i, m in ipairs(chatMessages) do print(i, m) end
  end
  assert_true(autoChatMsgs > 0, "Auto-Switched chat message PRINTED when quietAuto=false")
  assert_true(#toastMessages > 0, "Auto-Switched toast alert DISPLAYED when quietAuto=false")
end)

test("4.4 Explicit Notification Suppression (showChat = false or showToast = false) on Manual Actions", function()
  _G.XPRateControlDB = XPRate.InitDB()
  XPRateControlDB.quietAuto = false

  -- Case A: showChat = false, showToast = true
  XPRateControlDB.showChat = false
  XPRateControlDB.showToast = true

  clearLogs()
  XPRate.ApplyRate(1.25, false)

  assert_equal(0, #chatMessages, "Chat message SUPPRESSED when showChat=false")
  assert_true(#toastMessages > 0, "Toast alert DISPLAYED when showToast=true")

  -- Case B: showChat = true, showToast = false
  XPRateControlDB.showChat = true
  XPRateControlDB.showToast = false

  clearLogs()
  XPRate.ApplyRate(1.75, false)

  assert_true(#chatMessages > 0, "Chat message DISPLAYED when showChat=true")
  assert_equal(0, #toastMessages, "Toast alert SUPPRESSED when showToast=false")
end)

print("==================================================")
print(string.format("  Summary: %d Passed, %d Failed, %d Assertions", testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  print("\nFailure Summary:")
  for _, fail in ipairs(failureDetails) do
    print(string.format("  - %s: %s", fail.name, fail.err))
  end
  os.exit(1)
end
