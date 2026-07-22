-- Tests/challenger_m6_1_harness.lua
-- Standalone Lua stress-test harness for Milestone 6 (Notification Suppression & Quiet Automation Mode)

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
    value = 1.0,

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
        SetAllPoints = function() end,
        SetJustifyV = function() end,
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
        SetHeight = function() end,
        SetWidth = function() end,
        SetAllPoints = function() end,
        SetGradientAlpha = function() end,
        SetBlendMode = function() end,
        SetTexCoord = function() end,
        SetAlpha = function() end,
      }
      table.insert(self.textures, tex)
      return tex
    end,
    SetSize = function(self, w, h) self.width = w; self.height = h end,
    SetHeight = function(self, h) self.height = h end,
    SetWidth = function(self, w) self.width = w end,
    GetSize = function(self) return self.width, self.height end,
    SetPoint = function() end,
    GetPoint = function() return "CENTER", nil, "CENTER", 0, 0 end,
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
    GetFrameLevel = function(self) return self.level or 1 end,
    SetAllPoints = function() end,
    SetAutoFocus = function() end,
    SetFontObject = function() end,
    SetJustifyH = function() end,
    SetMaxLetters = function() end,
    HasFocus = function() return false end,
    ClearFocus = function() end,
    GetText = function(self) return self.text end,
    SetText = function(self, t) self.text = tostring(t) end,
    SetMovable = function() end,
    EnableMouse = function() end,
    RegisterForDrag = function() end,
    SetClampedToScreen = function() end,
    StartMoving = function() end,
    StopMovingOrSizing = function() end,
    SetThumbTexture = function() end,
    SetOrientation = function() end,
    SetMinMaxValues = function() end,
    SetValueStep = function() end,
    SetValue = function(self, val) self.value = val end,
    GetValue = function(self) return self.value or 1.0 end,
    EnableMouseWheel = function() end,
    SetAlpha = function() end,
    SetHighlightTexture = function() end,
    SetPushedTexture = function() end,
    SetNormalTexture = function() end,
    RegisterForClicks = function() end,
    tinsert = table.insert,
  }
  table.insert(createdFrames, frame)
  if name then _G[name] = frame end
  return frame
end

UIParent = CreateFrame("Frame", "UIParent")
GameTooltip = CreateFrame("Frame", "GameTooltip")
GameTooltip.SetOwner = function() end
GameTooltip.SetText = function() end

XPRateMinimapButtonBorder = { SetVertexColor = function() end }
tinsert = table.insert

-- Global API stubs
strtrim = function(s) return s and s:match("^%s*(.-)%s*$") or "" end
UnitLevel = function(unit) return 70 end
UnitGUID = function(unit) return "Player-1" end
GetNumPartyMembers = function() return 0 end
GetNumRaidMembers = function() return 0 end
IsInInstance = function() return false, "none" end
GetRealZoneText = function() return "Elwynn Forest" end
GetXPExhaustion = function() return 1000 end -- Rested active for automation tests
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

local toastCalls = {}
local originalShowToast = XPRate.ShowToast
XPRate.ShowToast = function(text, isError)
  table.insert(toastCalls, { text = text, isError = isError })
  if originalShowToast then originalShowToast(text, isError) end
end

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

-- Test Harness Engine
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
    print("[FAIL] " .. name .. " -> " .. tostring(err))
  end
end

local function resetLogs()
  printedMessages = {}
  toastCalls = {}
end

print("==================================================")
print("  XPRateControl M6 Challenger Test Harness (m6_1)")
print("==================================================")

-- Setup DB automation state for testing EvaluateAutomation
XPRateControlDB.autoRested = true
XPRateControlDB.restedRate = 2.0
XPRateControlDB.normalRate = 1.0

-- Matrix of 8 combinations of (showChat x showToast x quietAuto)
local combinations = {
  { showChat = true,  showToast = true,  quietAuto = false },
  { showChat = true,  showToast = true,  quietAuto = true  },
  { showChat = true,  showToast = false, quietAuto = false },
  { showChat = true,  showToast = false, quietAuto = true  },
  { showChat = false, showToast = true,  quietAuto = false },
  { showChat = false, showToast = true,  quietAuto = true  },
  { showChat = false, showToast = false, quietAuto = false },
  { showChat = false, showToast = false, quietAuto = true  },
}

local currentRateToggle = 1.0

for idx, combo in ipairs(combinations) do
  local cName = string.format("Comb %d (Chat=%s, Toast=%s, QuietAuto=%s)",
    idx, tostring(combo.showChat), tostring(combo.showToast), tostring(combo.quietAuto))

  -- 1. Manual Rate Change: ApplyRate(rate, false)
  test(cName .. " - Manual Rate Change (ApplyRate silent=false)", function()
    XPRateControlDB.showChat = combo.showChat
    XPRateControlDB.showToast = combo.showToast
    XPRateControlDB.quietAuto = combo.quietAuto

    resetLogs()
    currentRateToggle = (currentRateToggle == 1.0) and 1.5 or 1.0
    XPRate.ApplyRate(currentRateToggle, false)

    -- Assertions:
    -- When showChat is false, 0 chat msgs. When showChat is true, >0 chat msgs.
    if not combo.showChat then
      totalAssertions = totalAssertions + 1
      if #printedMessages ~= 0 then
        error(string.format("Expected 0 chat messages when showChat=false, got %d", #printedMessages))
      end
    else
      totalAssertions = totalAssertions + 1
      if #printedMessages == 0 then
        error("Expected chat message when showChat=true, got 0")
      end
    end

    -- When showToast is false, 0 toast alerts. When showToast is true, >0 toast alerts.
    if not combo.showToast then
      totalAssertions = totalAssertions + 1
      if #toastCalls ~= 0 then
        error(string.format("Expected 0 toast alerts when showToast=false, got %d", #toastCalls))
      end
    else
      totalAssertions = totalAssertions + 1
      if #toastCalls == 0 then
        error("Expected toast alert when showToast=true, got 0")
      end
    end
  end)

  -- 2. Silent Manual Rate Change: ApplyRate(rate, true)
  test(cName .. " - Silent Manual Rate Change (ApplyRate silent=true)", function()
    XPRateControlDB.showChat = combo.showChat
    XPRateControlDB.showToast = combo.showToast
    XPRateControlDB.quietAuto = combo.quietAuto

    resetLogs()
    currentRateToggle = (currentRateToggle == 1.0) and 1.5 or 1.0
    XPRate.ApplyRate(currentRateToggle, true)

    -- Assertions: Always 0 chat messages and 0 toasts regardless of settings when silent=true
    totalAssertions = totalAssertions + 1
    if #printedMessages ~= 0 then
      error(string.format("Expected 0 chat messages for silent ApplyRate, got %d", #printedMessages))
    end

    totalAssertions = totalAssertions + 1
    if #toastCalls ~= 0 then
      error(string.format("Expected 0 toast alerts for silent ApplyRate, got %d", #toastCalls))
    end
  end)

  -- 3. Automated Rate Change: EvaluateAutomation(false, "Event")
  test(cName .. " - Automated Rate Change (EvaluateAutomation silent=false)", function()
    XPRateControlDB.showChat = combo.showChat
    XPRateControlDB.showToast = combo.showToast
    XPRateControlDB.quietAuto = combo.quietAuto

    -- Ensure rate change triggers
    XPRate.lastAppliedRate = 0.5
    XPRate.lastAppliedMode = nil

    resetLogs()
    XPRate.EvaluateAutomation(false, "Event")

    -- Assertions:
    -- If quietAuto is true, EvaluateAutomation ALWAYS produces 0 chat msgs and 0 toast alerts regardless of showChat/showToast.
    if combo.quietAuto then
      totalAssertions = totalAssertions + 1
      if #printedMessages ~= 0 then
        error(string.format("Expected 0 chat messages when quietAuto=true, got %d", #printedMessages))
      end

      totalAssertions = totalAssertions + 1
      if #toastCalls ~= 0 then
        error(string.format("Expected 0 toast alerts when quietAuto=true, got %d", #toastCalls))
      end
    else
      -- When quietAuto is false:
      -- When showChat is false, 0 chat msgs MUST be printed.
      if not combo.showChat then
        totalAssertions = totalAssertions + 1
        if #printedMessages ~= 0 then
          error(string.format("Expected 0 chat messages when showChat=false, got %d", #printedMessages))
        end
      else
        totalAssertions = totalAssertions + 1
        if #printedMessages == 0 then
          error("Expected chat message when showChat=true, got 0")
        end
      end

      -- When showToast is false, 0 toast alerts MUST be rendered.
      if not combo.showToast then
        totalAssertions = totalAssertions + 1
        if #toastCalls ~= 0 then
          error(string.format("Expected 0 toast alerts when showToast=false, got %d", #toastCalls))
        end
      else
        totalAssertions = totalAssertions + 1
        if #toastCalls == 0 then
          error("Expected toast alert when showToast=true, got 0")
        end
      end
    end
  end)

  -- 4. Automated Rate Change: EvaluateAutomation(true, "Init")
  test(cName .. " - Automated Rate Change (EvaluateAutomation silent=true)", function()
    XPRateControlDB.showChat = combo.showChat
    XPRateControlDB.showToast = combo.showToast
    XPRateControlDB.quietAuto = combo.quietAuto

    -- Ensure rate change triggers
    XPRate.lastAppliedRate = 0.5
    XPRate.lastAppliedMode = nil

    resetLogs()
    XPRate.EvaluateAutomation(true, "Init")

    -- Assertions: Always 0 chat messages and 0 toast alerts when silent=true
    totalAssertions = totalAssertions + 1
    if #printedMessages ~= 0 then
      error(string.format("Expected 0 chat messages for silent EvaluateAutomation, got %d", #printedMessages))
    end

    totalAssertions = totalAssertions + 1
    if #toastCalls ~= 0 then
      error(string.format("Expected 0 toast alerts for silent EvaluateAutomation, got %d", #toastCalls))
    end
  end)

end

print("==================================================")
print(string.format("  Summary: Total Tests: %d | Passed: %d | Failed: %d | Assertions: %d",
  #combinations * 4, testsPassed, testsFailed, totalAssertions))
print("==================================================")

if testsFailed > 0 then
  os.exit(1)
else
  os.exit(0)
end
