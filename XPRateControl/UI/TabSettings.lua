-- UI/TabSettings.lua — Dedicated Settings Tab (Notifications, Minimap Button, Maintenance) for XPRateControl
local addonName, XPRate = ...

local CLR                 = XPRate.CLR
local ShowTooltip         = XPRate.ShowTooltip
local HideTooltip         = XPRate.HideTooltip
local CreateSectionHeader  = XPRate.CreateSectionHeader
local MakeButton          = XPRate.MakeButton

function XPRate.CreateTabSettingsUI(parent)
  local SettingsTabFrame = parent or XPRate.SettingsTabFrame
  if not SettingsTabFrame then return end

  -- Header
  CreateSectionHeader(SettingsTabFrame, "SETTINGS", "Interface\\Icons\\Trade_Engineering", CLR.cyan)

  -- =========================================================================
  -- Card 1: Notifications (notifCard, Y = -28, Height = 56)
  -- =========================================================================
  local notifCard = CreateFrame("Frame", "XPRateSettingsNotifCard", SettingsTabFrame)
  notifCard:SetSize(288, 56)
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

  -- Checkbox 1: Chat Messages
  local chatCheckbox = CreateFrame("CheckButton", "XPRateSettingsChatCheckbox", notifCard, "UICheckButtonTemplate")
  chatCheckbox:SetSize(20, 20)
  chatCheckbox:SetPoint("TOPLEFT", notifCard, "TOPLEFT", 10, -24)
  XPRate.chatCheckbox = chatCheckbox
  XPRate.showChatCheckbox = chatCheckbox

  local chatLabel = notifCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  chatLabel:SetPoint("LEFT", chatCheckbox, "RIGHT", 4, 0)
  chatLabel:SetText("Chat Messages")
  chatLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

  chatCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked() and true or false
    if XPRateControlDB then XPRateControlDB.showChat = enabled end
  end)
  chatCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Enable chat message notifications on rate changes.")
  end)
  chatCheckbox:SetScript("OnLeave", HideTooltip)

  -- Checkbox 2: Toast Alerts
  local toastCheckbox = CreateFrame("CheckButton", "XPRateSettingsToastCheckbox", notifCard, "UICheckButtonTemplate")
  toastCheckbox:SetSize(20, 20)
  toastCheckbox:SetPoint("TOPLEFT", notifCard, "TOPLEFT", 104, -24)
  XPRate.toastCheckbox = toastCheckbox
  XPRate.showToastCheckbox = toastCheckbox

  local toastLabel = notifCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  toastLabel:SetPoint("LEFT", toastCheckbox, "RIGHT", 4, 0)
  toastLabel:SetText("Toast Alerts")
  toastLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

  toastCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked() and true or false
    if XPRateControlDB then XPRateControlDB.showToast = enabled end
  end)
  toastCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Enable floating toast popups on rate changes.")
  end)
  toastCheckbox:SetScript("OnLeave", HideTooltip)

  -- Checkbox 3: Quiet Auto
  local quietCheckbox = CreateFrame("CheckButton", "XPRateSettingsQuietCheckbox", notifCard, "UICheckButtonTemplate")
  quietCheckbox:SetSize(20, 20)
  quietCheckbox:SetPoint("TOPLEFT", notifCard, "TOPLEFT", 192, -24)
  XPRate.quietCheckbox = quietCheckbox
  XPRate.quietAutoCheckbox = quietCheckbox

  local quietLabel = notifCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  quietLabel:SetPoint("LEFT", quietCheckbox, "RIGHT", 4, 0)
  quietLabel:SetText("Quiet Auto")
  quietLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

  quietCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked() and true or false
    if XPRateControlDB then XPRateControlDB.quietAuto = enabled end
  end)
  quietCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Suppress notifications when rate changes automatically.")
  end)
  quietCheckbox:SetScript("OnLeave", HideTooltip)

  -- =========================================================================
  -- Card 2: Minimap Button (minimapCard, Y = -90, Height = 54)
  -- =========================================================================
  local minimapCard = CreateFrame("Frame", "XPRateSettingsMinimapCard", SettingsTabFrame)
  minimapCard:SetSize(288, 54)
  minimapCard:SetPoint("TOPLEFT", SettingsTabFrame, "TOPLEFT", 10, -90)
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
  local minimapCheckbox = CreateFrame("CheckButton", "XPRateSettingsMinimapCheckbox", minimapCard, "UICheckButtonTemplate")
  minimapCheckbox:SetSize(20, 20)
  minimapCheckbox:SetPoint("TOPLEFT", minimapCard, "TOPLEFT", 10, -24)
  XPRate.showMinimapCheckbox = minimapCheckbox

  local minimapLabel = minimapCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  minimapLabel:SetPoint("LEFT", minimapCheckbox, "RIGHT", 4, 0)
  minimapLabel:SetText("Show Minimap Icon")
  minimapLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

  minimapCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked() and true or false
    if XPRateControlDB then XPRateControlDB.showMinimap = enabled end
    if XPRate.minimapButton then
      if enabled then XPRate.minimapButton:Show() else XPRate.minimapButton:Hide() end
    end
  end)
  minimapCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Toggle visibility of the minimap hourglass button.")
  end)
  minimapCheckbox:SetScript("OnLeave", HideTooltip)

  -- =========================================================================
  -- Card 3: Maintenance (maintCard, Y = -148, Height = 76)
  -- =========================================================================
  local maintCard = CreateFrame("Frame", "XPRateSettingsMaintCard", SettingsTabFrame)
  maintCard:SetSize(288, 76)
  maintCard:SetPoint("TOPLEFT", SettingsTabFrame, "TOPLEFT", 10, -148)
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
  local masterCheckbox = CreateFrame("CheckButton", "XPRateMasterEnableCheckbox", maintCard, "UICheckButtonTemplate")
  masterCheckbox:SetSize(20, 20)
  masterCheckbox:SetPoint("TOPLEFT", maintCard, "TOPLEFT", 10, -22)
  XPRate.masterEnableCheckbox = masterCheckbox

  local masterLabel = maintCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  masterLabel:SetPoint("LEFT", masterCheckbox, "RIGHT", 4, 0)
  masterLabel:SetText("Master Automation Toggle (All Modules)")
  masterLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

  masterCheckbox:SetScript("OnClick", function(self)
    local enabled = self:GetChecked() and true or false
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
  end)
  masterCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Enable or disable all 7 automation modules simultaneously.")
  end)
  masterCheckbox:SetScript("OnLeave", HideTooltip)

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
  resetBtn:SetPoint("TOPLEFT", maintCard, "TOPLEFT", 10, -48)
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
