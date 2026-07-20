-- UI/TabAutomation.lua — Tab 2 Automation UI (Auto Rested, Party Auto-Scaling & Mob Difficulty Scaling) for XPRateControl
local addonName, XPRate = ...

local CLR                     = XPRate.CLR
local FormatRate             = XPRate.FormatRate
local ClampRate              = XPRate.ClampRate
local RateColor              = XPRate.RateColor
local ShowTooltip             = XPRate.ShowTooltip
local HideTooltip             = XPRate.HideTooltip
local CreateSectionHeader     = XPRate.CreateSectionHeader
local EvaluateAutomation      = XPRate.EvaluateAutomation
local UpdateAutomationStatus  = XPRate.UpdateAutomationStatus
local GetCurrentGroupSize     = XPRate.GetCurrentGroupSize

local AutomationTabFrame = XPRate.AutomationTabFrame

local autoSubTabSelected = 1 -- 1 = Rested XP, 2 = Party Scaling, 3 = Mob Difficulty

-- Sub-Nav Segmented Buttons Container
local autoSubNavFrame = CreateFrame("Frame", nil, AutomationTabFrame)
autoSubNavFrame:SetSize(308, 24)
autoSubNavFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, 0)

local autoSubNavBtns = {}
local autoSubNavNames = { "Rested XP", "Party Scaling", "Mob Difficulty" }

local AutoRestedSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoRestedSubFrame:SetSize(308, 172)
AutoRestedSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -26)

local AutoGroupSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoGroupSubFrame:SetSize(308, 172)
AutoGroupSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -26)
AutoGroupSubFrame:Hide()

local AutoMobSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoMobSubFrame:SetSize(308, 172)
AutoMobSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -26)
AutoMobSubFrame:Hide()

local function SelectAutomationSubTab(tabIndex)
  autoSubTabSelected = tabIndex
  for i, btn in ipairs(autoSubNavBtns) do
    if i == tabIndex then
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.95)
      btn:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    else
      btn:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.6)
      btn:SetBackdropBorderColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.4)
      btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end

  if tabIndex == 1 then
    AutoRestedSubFrame:Show()
    AutoGroupSubFrame:Hide()
    AutoMobSubFrame:Hide()
  elseif tabIndex == 2 then
    AutoRestedSubFrame:Hide()
    AutoGroupSubFrame:Show()
    AutoMobSubFrame:Hide()
    if XPRate.UpdatePartyButtonsUI then XPRate.UpdatePartyButtonsUI() end
  else
    AutoRestedSubFrame:Hide()
    AutoGroupSubFrame:Hide()
    AutoMobSubFrame:Show()
    if XPRate.updateMobRows then XPRate.updateMobRows() end
    if UpdateAutomationStatus then UpdateAutomationStatus() end
  end
end

for i = 1, 3 do
  local btn = CreateFrame("Button", nil, autoSubNavFrame)
  btn:SetSize(98, 22)
  btn:SetPoint("TOPLEFT", autoSubNavFrame, "TOPLEFT", 4 + (i-1)*102, 0)

  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("CENTER")
  text:SetText(autoSubNavNames[i])
  btn.text = text

  btn:SetScript("OnClick", function()
    SelectAutomationSubTab(i)
  end)

  btn:SetScript("OnEnter", function(self)
    if i ~= autoSubTabSelected then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 0.9)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    if i ~= autoSubTabSelected then
      self:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.6)
    end
  end)

  autoSubNavBtns[i] = btn
end

-- Controls in AutoRestedSubFrame
CreateSectionHeader(AutoRestedSubFrame, "AUTO RESTED XP", "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Automation", CLR.green)

local restedCheckbox = CreateFrame("CheckButton", "XPRateRestedCheckbox", AutoRestedSubFrame, "UICheckButtonTemplate")
XPRate.restedCheckbox = restedCheckbox
restedCheckbox:SetSize(22, 22)
restedCheckbox:SetPoint("TOPLEFT", AutoRestedSubFrame, "TOPLEFT", 12, -26)

local restedCheckLabel = AutoRestedSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
restedCheckLabel:SetPoint("LEFT", restedCheckbox, "RIGHT", 6, 0)
restedCheckLabel:SetText("Auto-switch on Rested XP")
restedCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local restedStateValue = AutoRestedSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
restedStateValue:SetPoint("TOPLEFT", AutoRestedSubFrame, "TOPLEFT", 12, -52)
restedStateValue:SetText("Status: Inactive")
XPRate.restedStateValue = restedStateValue

-- Controls in AutoGroupSubFrame
CreateSectionHeader(AutoGroupSubFrame, "PARTY AUTO SCALING", "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Automation", CLR.cyan)

local groupCheckbox = CreateFrame("CheckButton", "XPRateGroupCheckbox", AutoGroupSubFrame, "UICheckButtonTemplate")
XPRate.groupCheckbox = groupCheckbox
groupCheckbox:SetSize(22, 22)
groupCheckbox:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12, -26)

local groupCheckLabel = AutoGroupSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
groupCheckLabel:SetPoint("LEFT", groupCheckbox, "RIGHT", 6, 0)
groupCheckLabel:SetText("Auto-scale rates by party size")
groupCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local groupStateValue = AutoGroupSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
groupStateValue:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12, -52)
groupStateValue:SetText("Status: Inactive")
XPRate.groupStateValue = groupStateValue

restedCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoRested = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Rested Auto ON" or "Rested Auto OFF")
end)

restedCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch XP rates depending on whether you have Rested XP.")
end)
restedCheckbox:SetScript("OnLeave", HideTooltip)

local updateRestedRow = XPRate.CreateRestedPresetRow(AutoRestedSubFrame, "Rested Rate", -72,
  function(val)
    XPRateControlDB.restedRate = ClampRate(val)
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Rested Rate Updated")
  end,
  function()
    return XPRateControlDB and XPRateControlDB.restedRate or 2.0
  end
)
XPRate.updateRestedRow = updateRestedRow

local updateNormalRow = XPRate.CreateRestedPresetRow(AutoRestedSubFrame, "Normal Rate", -114,
  function(val)
    XPRateControlDB.normalRate = ClampRate(val)
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Normal Rate Updated")
  end,
  function()
    return XPRateControlDB and XPRateControlDB.normalRate or 1.0
  end
)
XPRate.updateNormalRow = updateNormalRow

-- Controls in AutoGroupSubFrame
groupCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoGroup = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Party Auto ON" or "Party Auto OFF")
end)

groupCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically adjust XP rate based on current party size (1P-5P).")
end)
groupCheckbox:SetScript("OnLeave", HideTooltip)

local groupSelectedSize = 1
local partyLabels = { "1P Solo", "2P", "3P", "4P", "5P" }
local partyButtons = {}
local updateGroupRow = nil

local groupRatesLabel = AutoGroupSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
groupRatesLabel:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12, -72)
groupRatesLabel:SetText("Select Party Size to Configure:")
groupRatesLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

function XPRate.UpdatePartyButtonsUI()
  local currentGroupSize = GetCurrentGroupSize()
  for i, btn in ipairs(partyButtons) do
    if i == groupSelectedSize then
      btn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
      btn:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    elseif (math.min(currentGroupSize, 5) == i) and XPRateControlDB and XPRateControlDB.autoGroup then
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
      btn:SetBackdropBorderColor(CLR.green[1], CLR.green[2], CLR.green[3], 0.9)
      btn.text:SetTextColor(CLR.green[1], CLR.green[2], CLR.green[3])
    else
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
      btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
      btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end
end

for i = 1, 5 do
  local btn = CreateFrame("Button", nil, AutoGroupSubFrame)
  btn:SetSize(54, 20)
  btn:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12 + (i-1)*56, -88)

  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })
  btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
  btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("CENTER")
  text:SetText(partyLabels[i])
  text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
  btn.text = text

  btn:SetScript("OnClick", function()
    groupSelectedSize = i
    XPRate.UpdatePartyButtonsUI()
    if updateGroupRow then updateGroupRow() end
  end)

  btn:SetScript("OnEnter", function(self)
    if i ~= groupSelectedSize then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    XPRate.UpdatePartyButtonsUI()
  end)

  partyButtons[i] = btn
end

XPRate.UpdatePartyButtonsUI()

updateGroupRow = XPRate.CreateRestedPresetRow(AutoGroupSubFrame, "Target Rate for Party Size", -114,
  function(val)
    if XPRateControlDB and XPRateControlDB.groupRates then
      XPRateControlDB.groupRates[groupSelectedSize] = ClampRate(val)
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, string.format("%s Rate Updated", partyLabels[groupSelectedSize]))
      XPRate.UpdatePartyButtonsUI()
      if updateGroupRow then updateGroupRow() end
    end
  end,
  function()
    return XPRateControlDB and XPRateControlDB.groupRates and XPRateControlDB.groupRates[groupSelectedSize] or 1.0
  end
)
XPRate.updateGroupRow = updateGroupRow

-- Controls in AutoMobSubFrame
CreateSectionHeader(AutoMobSubFrame, "MOB DIFFICULTY SCALING", "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Automation", CLR.red)

local mobCheckbox = CreateFrame("CheckButton", "XPRateMobCheckbox", AutoMobSubFrame, "UICheckButtonTemplate")
XPRate.mobCheckbox = mobCheckbox
mobCheckbox:SetSize(22, 22)
mobCheckbox:SetPoint("TOPLEFT", AutoMobSubFrame, "TOPLEFT", 12, -26)

local mobCheckLabel = AutoMobSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mobCheckLabel:SetPoint("LEFT", mobCheckbox, "RIGHT", 6, 0)
mobCheckLabel:SetText("Auto-scale rates by mob color")
mobCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local mobStateValue = AutoMobSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mobStateValue:SetPoint("TOPLEFT", AutoMobSubFrame, "TOPLEFT", 12, -48)
mobStateValue:SetText("Target: None / Non-Enemy")
XPRate.mobStateValue = mobStateValue

mobCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoMob = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Mob Auto ON" or "Mob Auto OFF")
end)

mobCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch XP rate based on target mob difficulty color.")
end)
mobCheckbox:SetScript("OnLeave", HideTooltip)

local mobRowUpdaters = {}
local mobCategories = {
  { key = "gray",   label = "Gray Mobs (Trivial)",   yOfs = -64 },
  { key = "green",  label = "Green Mobs (Easy)",      yOfs = -92 },
  { key = "yellow", label = "Yellow Mobs (Equal)",     yOfs = -120 },
  { key = "red",    label = "Orange / Red (Hard)",     yOfs = -148 },
}

for i, cat in ipairs(mobCategories) do
  local updater = XPRate.CreateRestedPresetRow(AutoMobSubFrame, cat.label, cat.yOfs,
    function(val)
      if XPRateControlDB and XPRateControlDB.mobRates then
        XPRateControlDB.mobRates[cat.key] = ClampRate(val)
        XPRate.lastAppliedRate = nil
        XPRate.lastAppliedMode = nil
        EvaluateAutomation(false, cat.label .. " Rate Updated")
      end
    end,
    function()
      return XPRateControlDB and XPRateControlDB.mobRates and XPRateControlDB.mobRates[cat.key] or (cat.key == "gray" and 0.0 or (cat.key == "green" and 0.5 or (cat.key == "yellow" and 1.0 or 2.0)))
    end
  )
  tinsert(mobRowUpdaters, updater)
end

function XPRate.updateMobRows()
  for _, u in ipairs(mobRowUpdaters) do
    if u then u() end
  end
end

SelectAutomationSubTab(1)
