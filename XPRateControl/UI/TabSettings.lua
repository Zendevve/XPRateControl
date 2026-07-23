-- UI/TabSettings.lua — Dedicated Settings Tab (Notifications, Minimap Button, Maintenance) for XPRateControl
local addonName, XPRate = ...

local CLR                 = XPRate.CLR
local ShowTooltip         = XPRate.ShowTooltip
local HideTooltip         = XPRate.HideTooltip
local CreateSectionHeader  = XPRate.CreateSectionHeader
local MakeButton          = XPRate.MakeButton
local PrintMessage        = XPRate.PrintMessage
local ShowToast            = XPRate.ShowToast

function XPRate.CreateTabSettingsUI(parent)
  local SettingsTabFrame = parent or XPRate.SettingsTabFrame
  if not SettingsTabFrame then return end
  if SettingsTabFrame.isBuilt then
    XPRate.UpdateSettingsTabUI()
    return
  end
  SettingsTabFrame.isBuilt = true

  -- Header
  CreateSectionHeader(SettingsTabFrame, "SETTINGS", "Interface\\Icons\\Trade_Engineering", CLR.cyan)

  -- Helper function to create a clean, clickable checkbox with label & tooltips
  local function CreateSettingCheckbox(parentFrame, globalName, xOfs, yOfs, labelText, tooltipText, onClickCallback)
    local cb = CreateFrame("CheckButton", globalName, parentFrame, "UICheckButtonTemplate")
    cb:SetSize(20, 20)
    cb:SetPoint("TOPLEFT", parentFrame, "TOPLEFT", xOfs, yOfs)

    local labelBtn = CreateFrame("Button", nil, parentFrame)
    labelBtn:SetPoint("LEFT", cb, "RIGHT", 4, 0)

    local fontString = labelBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fontString:SetPoint("LEFT", labelBtn, "LEFT", 0, 0)
    fontString:SetText(labelText)
    fontString:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

    labelBtn:SetSize(fontString:GetStringWidth() + 6, 20)

    cb:SetScript("OnClick", function(self)
      local checked = self:GetChecked() and true or false
      self:SetChecked(checked)
      if onClickCallback then
        onClickCallback(self, checked)
      end
    end)

    labelBtn:SetScript("OnClick", function()
      cb:Click()
    end)

    local function OnEnter(self)
      fontString:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])
      if tooltipText then ShowTooltip(self, tooltipText) end
    end

    local function OnLeave(self)
      fontString:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
      HideTooltip()
    end

    cb:SetScript("OnEnter", OnEnter)
    cb:SetScript("OnLeave", OnLeave)
    labelBtn:SetScript("OnEnter", OnEnter)
    labelBtn:SetScript("OnLeave", OnLeave)

    return cb
  end

  -- =========================================================================
  -- Card 1: Notifications (notifCard, Y = -28, Height = 74)
  -- =========================================================================
  local notifCard = CreateFrame("Frame", "XPRateSettingsNotifCard", SettingsTabFrame)
  notifCard:SetSize(288, 74)
  notifCard:SetPoint("TOPLEFT", SettingsTabFrame, "TOPLEFT", 10, -28)
  notifCard:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  notifCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
  notifCard:SetBackdropBorderColor(CLR.cardEdge[1] * 1.3, CLR.cardEdge[2] * 1.3, CLR.cardEdge[3] * 1.3, 0.8)

  local notifHeader = notifCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  notifHeader:SetPoint("TOPLEFT", notifCard, "TOPLEFT", 10, -6)
  notifHeader:SetText("NOTIFICATIONS")
  notifHeader:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

  -- Checkbox 1: Chat Messages (Row 1 Left)
  XPRate.showChatCheckbox = CreateSettingCheckbox(
    notifCard, "XPRateSettingsChatCheckbox", 10, -24,
    "Chat Messages",
    "Enable chat message notifications on rate changes.",
    function(self, enabled)
      if XPRateControlDB then XPRateControlDB.showChat = enabled end
      local printFn = XPRate.PrintMessage or PrintMessage
      local toastFn = XPRate.ShowToast or ShowToast
      if printFn then
        printFn("Chat notifications " .. (enabled and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
      end
      if toastFn then
        toastFn(enabled and "Chat Msg ON [OK]" or "Chat Msg OFF [OK]", false)
      end
    end
  )
  XPRate.chatCheckbox = XPRate.showChatCheckbox

  -- Checkbox 2: Toast Alerts (Row 1 Right)
  XPRate.showToastCheckbox = CreateSettingCheckbox(
    notifCard, "XPRateSettingsToastCheckbox", 150, -24,
    "Toast Alerts",
    "Enable floating toast popups on rate changes.",
    function(self, enabled)
      if XPRateControlDB then XPRateControlDB.showToast = enabled end
      local printFn = XPRate.PrintMessage or PrintMessage
      local toastFn = XPRate.ShowToast or ShowToast
      if printFn then
        printFn("Toast notifications " .. (enabled and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
      end
      if toastFn and enabled then
        toastFn("Toast Alerts ON [OK]", false)
      end
    end
  )
  XPRate.toastCheckbox = XPRate.showToastCheckbox

  -- Checkbox 3: Quiet Automation (Row 2 Left)
  XPRate.quietAutoCheckbox = CreateSettingCheckbox(
    notifCard, "XPRateSettingsQuietCheckbox", 10, -48,
    "Quiet Automation",
    "Suppress notifications when rate changes automatically.",
    function(self, enabled)
      if XPRateControlDB then XPRateControlDB.quietAuto = enabled end
      local printFn = XPRate.PrintMessage or PrintMessage
      local toastFn = XPRate.ShowToast or ShowToast
      if printFn then
        printFn("Quiet automation " .. (enabled and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
      end
      if toastFn then
        toastFn(enabled and "Quiet Auto ON [OK]" or "Quiet Auto OFF [OK]", false)
      end
    end
  )
  XPRate.quietCheckbox = XPRate.quietAutoCheckbox

  -- =========================================================================
  -- Card 2: Minimap Button (minimapCard, Y = -108, Height = 46)
  -- =========================================================================
  local minimapCard = CreateFrame("Frame", "XPRateSettingsMinimapCard", SettingsTabFrame)
  minimapCard:SetSize(288, 46)
  minimapCard:SetPoint("TOPLEFT", SettingsTabFrame, "TOPLEFT", 10, -108)
  minimapCard:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  minimapCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
  minimapCard:SetBackdropBorderColor(CLR.cardEdge[1] * 1.3, CLR.cardEdge[2] * 1.3, CLR.cardEdge[3] * 1.3, 0.8)

  local minimapHeader = minimapCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  minimapHeader:SetPoint("TOPLEFT", minimapCard, "TOPLEFT", 10, -6)
  minimapHeader:SetText("MINIMAP BUTTON")
  minimapHeader:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

  -- Checkbox: Show Minimap Icon
  XPRate.showMinimapCheckbox = CreateSettingCheckbox(
    minimapCard, "XPRateSettingsMinimapCheckbox", 10, -22,
    "Show Minimap Icon",
    "Toggle visibility of the minimap hourglass button.",
    function(self, enabled)
      if XPRateControlDB then XPRateControlDB.showMinimap = enabled end
      if XPRate.minimapButton then
        if enabled then XPRate.minimapButton:Show() else XPRate.minimapButton:Hide() end
      end
      local printFn = XPRate.PrintMessage or PrintMessage
      local toastFn = XPRate.ShowToast or ShowToast
      if printFn then
        printFn("Minimap icon " .. (enabled and "|cff20cc50shown|r" or "|cffcc3535hidden|r"))
      end
      if toastFn then
        toastFn(enabled and "Minimap Icon ON [OK]" or "Minimap Icon OFF [OK]", false)
      end
    end
  )

  -- =========================================================================
  -- Card 3: Maintenance (maintCard, Y = -160, Height = 68)
  -- =========================================================================
  local maintCard = CreateFrame("Frame", "XPRateSettingsMaintCard", SettingsTabFrame)
  maintCard:SetSize(288, 68)
  maintCard:SetPoint("TOPLEFT", SettingsTabFrame, "TOPLEFT", 10, -160)
  maintCard:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })
  maintCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
  maintCard:SetBackdropBorderColor(CLR.cardEdge[1] * 1.3, CLR.cardEdge[2] * 1.3, CLR.cardEdge[3] * 1.3, 0.8)

  local maintHeader = maintCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  maintHeader:SetPoint("TOPLEFT", maintCard, "TOPLEFT", 10, -6)
  maintHeader:SetText("MAINTENANCE")
  maintHeader:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

  -- Checkbox: Master Automation Toggle
  XPRate.masterEnableCheckbox = CreateSettingCheckbox(
    maintCard, "XPRateMasterEnableCheckbox", 10, -20,
    "Master Automation Toggle (All Modules)",
    "Enable or disable all 7 automation modules simultaneously.",
    function(self, enabled)
      local db = XPRateControlDB
      if db then
        db.autoRested    = enabled
        db.autoGroup     = enabled
        db.autoDisparity = enabled
        db.autoMob       = enabled
        db.autoQuest     = enabled
        db.autoBracket   = enabled
        db.autoZone      = enabled
      end
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      if XPRate.EvaluateAutomation then
        XPRate.EvaluateAutomation(false, enabled and "Master Enable ON" or "Master Enable OFF")
      end
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
      if XPRate.UpdateSettingsTabUI then XPRate.UpdateSettingsTabUI() end

      local printFn = XPRate.PrintMessage or PrintMessage
      local toastFn = XPRate.ShowToast or ShowToast
      if printFn then
        printFn("Master Automation " .. (enabled and "|cff20cc50enabled|r (all 7 modules)" or "|cffcc3535disabled|r"))
      end
      if toastFn then
        toastFn(enabled and "Master Auto ON [OK]" or "Master Auto OFF [OK]", false)
      end
    end
  )

  -- Reset Defaults Button
  local resetBtn = MakeButton and MakeButton(maintCard, 268, 20, CLR.btnBg, CLR.btnEdge) or CreateFrame("Button", nil, maintCard)
  if not MakeButton then
    resetBtn:SetSize(268, 20)
    resetBtn:SetBackdrop({
      bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 8, edgeSize = 8,
      insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
  end
  resetBtn:SetPoint("TOPLEFT", maintCard, "TOPLEFT", 10, -42)
  resetBtn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.85)
  resetBtn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)

  local resetLabel = resetBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  resetLabel:SetPoint("CENTER")
  resetLabel:SetText("Reset Defaults")
  resetLabel:SetTextColor(CLR.red[1], CLR.red[2], CLR.red[3])
  resetBtn.label = resetLabel

  resetBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(0.35, 0.08, 0.08, 0.95)
    self:SetBackdropBorderColor(1.0, 0.35, 0.35, 1.0)
    resetLabel:SetTextColor(1, 1, 1)
    ShowTooltip(self, "Reset all SavedVariables settings to default values.")
  end)

  resetBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.85)
    self:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
    resetLabel:SetTextColor(CLR.red[1], CLR.red[2], CLR.red[3])
    HideTooltip()
  end)

  resetBtn:SetScript("OnClick", function()
    XPRateControlDB = nil
    local db = XPRate.InitDB()

    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if XPRate.ApplyRate then
      XPRate.ApplyRate(XPRate.DEFAULT_RATE or 1.0)
    end

    if XPRate.UpdateUIFromValue then XPRate.UpdateUIFromValue(db.lastRate) end
    if XPRate.UpdateJJUI then XPRate.UpdateJJUI(db.jjEnabled) end
    if XPRate.UpdateTabRatesUI then XPRate.UpdateTabRatesUI() end
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    if XPRate.UpdateSettingsTabUI then XPRate.UpdateSettingsTabUI() end
    if XPRate.UpdateMinimapButtonPosition then XPRate.UpdateMinimapButtonPosition() end

    if XPRate.minimapButton then
      if db.showMinimap then XPRate.minimapButton:Show() else XPRate.minimapButton:Hide() end
    end

    if XPRate.ShowToast then XPRate.ShowToast("Defaults Restored [OK]", false) end
    if XPRate.PrintMessage then XPRate.PrintMessage("SavedVariables reset to default configuration.") end
  end)

  -- Initial UI state sync
  XPRate.UpdateSettingsTabUI()
end

function XPRate.UpdateSettingsTabUI()
  local db = XPRateControlDB
  if not db then return end

  if XPRate.showChatCheckbox then XPRate.showChatCheckbox:SetChecked(db.showChat ~= false) end
  if XPRate.showToastCheckbox then XPRate.showToastCheckbox:SetChecked(db.showToast ~= false) end
  if XPRate.quietAutoCheckbox then XPRate.quietAutoCheckbox:SetChecked(db.quietAuto == true) end
  if XPRate.showMinimapCheckbox then XPRate.showMinimapCheckbox:SetChecked(db.showMinimap ~= false) end

  local isAllAuto = db.autoRested and db.autoGroup and db.autoDisparity and db.autoMob and db.autoQuest and db.autoBracket and db.autoZone
  if XPRate.masterEnableCheckbox then XPRate.masterEnableCheckbox:SetChecked(isAllAuto and true or false) end
end

XPRate.UpdateTabSettingsUI = XPRate.UpdateSettingsTabUI

-- Automatically build if SettingsTabFrame exists when file is loaded
if XPRate.SettingsTabFrame then
  XPRate.CreateTabSettingsUI(XPRate.SettingsTabFrame)
end
