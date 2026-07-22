-- UI/TabAutomation.lua — Tab 2 Automation UI (7 Sub-Tabs Expansion & Clean Layout) for XPRateControl
local addonName, XPRate = ...

local CLR                     = XPRate.CLR
local FormatRate             = XPRate.FormatRate
local ClampRate              = XPRate.ClampRate
local RateColor              = XPRate.RateColor
local MakeButton             = XPRate.MakeButton
local ShowTooltip             = XPRate.ShowTooltip
local HideTooltip             = XPRate.HideTooltip
local EvaluateAutomation      = XPRate.EvaluateAutomation
local UpdateAutomationStatus  = XPRate.UpdateAutomationStatus
local GetCurrentGroupSize     = XPRate.GetCurrentGroupSize

local AutomationTabFrame = XPRate.AutomationTabFrame

local autoSubTabSelected = 1 -- 1=Rested, 2=Party Size, 3=Disparity, 4=Mob, 5=Quest, 6=Bracket, 7=Zone

-- Sub-Frames Container Setup (7 frames)
local AutoRestedSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoRestedSubFrame:SetSize(308, 172)
AutoRestedSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)

local AutoGroupSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoGroupSubFrame:SetSize(308, 172)
AutoGroupSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)
AutoGroupSubFrame:Hide()

local AutoDisparitySubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoDisparitySubFrame:SetSize(308, 172)
AutoDisparitySubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)
AutoDisparitySubFrame:Hide()

local AutoMobSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoMobSubFrame:SetSize(308, 172)
AutoMobSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)
AutoMobSubFrame:Hide()

local AutoQuestSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoQuestSubFrame:SetSize(308, 172)
AutoQuestSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)
AutoQuestSubFrame:Hide()

local AutoBracketSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoBracketSubFrame:SetSize(308, 172)
AutoBracketSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)
AutoBracketSubFrame:Hide()

local AutoZoneSubFrame = CreateFrame("Frame", nil, AutomationTabFrame)
AutoZoneSubFrame:SetSize(308, 172)
AutoZoneSubFrame:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, -32)
AutoZoneSubFrame:Hide()

local subTabFrames = {
  AutoRestedSubFrame,
  AutoGroupSubFrame,
  AutoDisparitySubFrame,
  AutoMobSubFrame,
  AutoQuestSubFrame,
  AutoBracketSubFrame,
  AutoZoneSubFrame
}

-- Sub-tab configurations (7 options)
local autoSubTabConfig = {
  { name = "AUTO RESTED XP",             icon = "Interface\\AddOns\\XPRateControl\\Textures\\Icon_AutoRested", color = CLR.green },
  { name = "PARTY SIZE SCALING",         icon = "Interface\\AddOns\\XPRateControl\\Textures\\Icon_AutoParty",  color = CLR.cyan },
  { name = "PARTY LEVEL DISPARITY",      icon = "Interface\\Icons\\Spell_Holy_PrayerOfHealing",               color = CLR.red },
  { name = "MOB DIFFICULTY SCALING",      icon = "Interface\\AddOns\\XPRateControl\\Textures\\Icon_AutoMob",    color = CLR.red },
  { name = "QUEST TURN-IN SCALING",      icon = "Interface\\GossipFrame\\AvailableQuestIcon",                 color = CLR.gold },
  { name = "LEVEL BRACKET SCALING",      icon = "Interface\\Icons\\Spell_Holy_PrayerOfFortitude",            color = CLR.gold },
  { name = "ZONE / INSTANCE SCALING",    icon = "Interface\\Icons\\Spell_Arcane_PortalIronforge",            color = CLR.cyan },
}

-- Header Dropdown Container Button
local headerBtn = CreateFrame("Button", "XPRateAutoHeaderDropdown", AutomationTabFrame)
headerBtn:SetSize(308, 26)
headerBtn:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 0, 0)

headerBtn:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 12, edgeSize = 12,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
headerBtn:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.95)
headerBtn:SetBackdropBorderColor(CLR.cardEdge[1], CLR.cardEdge[2], CLR.cardEdge[3], 0.9)

local headerStripe = headerBtn:CreateTexture(nil, "ARTWORK")
headerStripe:SetSize(4, 18)
headerStripe:SetPoint("LEFT", headerBtn, "LEFT", 8, 0)
headerStripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

local headerIcon = headerBtn:CreateTexture(nil, "ARTWORK")
headerIcon:SetSize(18, 18)
headerIcon:SetPoint("LEFT", headerStripe, "RIGHT", 6, 0)

local headerTitle = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
headerTitle:SetPoint("LEFT", headerIcon, "RIGHT", 6, 0)

local headerArrow = headerBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
headerArrow:SetPoint("RIGHT", headerBtn, "RIGHT", -12, 0)
headerArrow:SetText("v")
headerArrow:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

-- Fullscreen invisible backdrop for click-outside dismissal
local coverFrame = CreateFrame("Button", nil, UIParent)
coverFrame:SetAllPoints(UIParent)
coverFrame:SetFrameStrata("FULLSCREEN_DIALOG")
coverFrame:Hide()

-- Custom Dropdown Popup Menu Frame (308, 182 for 7 options)
local dropdownMenu = CreateFrame("Frame", "XPRateAutoDropdownMenu", AutomationTabFrame)
dropdownMenu:SetSize(308, 182)
dropdownMenu:SetPoint("TOPLEFT", headerBtn, "BOTTOMLEFT", 0, -2)
dropdownMenu:SetFrameStrata("FULLSCREEN_DIALOG")
dropdownMenu:SetFrameLevel(coverFrame:GetFrameLevel() + 1)
dropdownMenu:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 12, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
dropdownMenu:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.98)
dropdownMenu:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
dropdownMenu:Hide()

local function HideDropdownMenu()
  dropdownMenu:Hide()
  coverFrame:Hide()
  headerArrow:SetText("v")
end

coverFrame:SetScript("OnClick", HideDropdownMenu)

local dropdownOptionBtns = {}

function XPRate.UpdateDropdownCheckmarks()
  if not XPRateControlDB then return end
  local states = {
    XPRateControlDB.autoRested and true or false,
    XPRateControlDB.autoGroup and true or false,
    XPRateControlDB.autoDisparity and true or false,
    XPRateControlDB.autoMob and true or false,
    XPRateControlDB.autoQuest and true or false,
    XPRateControlDB.autoBracket and true or false,
    XPRateControlDB.autoZone and true or false,
  }

  for i, optBtn in ipairs(dropdownOptionBtns) do
    if optBtn.statusTag then
      if states[i] then
        optBtn.statusTag:SetText("[v]")
        optBtn.statusTag:SetTextColor(CLR.green[1], CLR.green[2], CLR.green[3])
      else
        optBtn.statusTag:SetText("[ ]")
        optBtn.statusTag:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.5)
      end
    end
  end
end

local function SelectAutomationSubTab(tabIndex)
  autoSubTabSelected = tabIndex

  -- Update Header Display
  local cfg = autoSubTabConfig[tabIndex]
  headerStripe:SetVertexColor(cfg.color[1], cfg.color[2], cfg.color[3])
  headerIcon:SetTexture(cfg.icon)
  headerTitle:SetText(cfg.name)

  -- Update Sub-Frames Visibility
  for i, frame in ipairs(subTabFrames) do
    if i == tabIndex then
      frame:Show()
    else
      frame:Hide()
    end
  end

  if XPRate.UpdateAutomationTabUI then
    XPRate.UpdateAutomationTabUI()
  end

  -- Update Option Highlights in Menu
  for i, optBtn in ipairs(dropdownOptionBtns) do
    if i == tabIndex then
      optBtn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.9)
      optBtn:SetBackdropBorderColor(autoSubTabConfig[i].color[1], autoSubTabConfig[i].color[2], autoSubTabConfig[i].color[3], 0.95)
    else
      optBtn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.6)
      optBtn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.4)
    end
  end

  HideDropdownMenu()
end

-- Populate Dropdown Menu Options (7 options)
for i = 1, #autoSubTabConfig do
  local cfg = autoSubTabConfig[i]
  local optBtn = CreateFrame("Button", nil, dropdownMenu)
  optBtn:SetSize(296, 24)
  optBtn:SetPoint("TOPLEFT", dropdownMenu, "TOPLEFT", 6, -5 - (i-1)*25)

  optBtn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })

  local stripe = optBtn:CreateTexture(nil, "ARTWORK")
  stripe:SetSize(3, 14)
  stripe:SetPoint("LEFT", optBtn, "LEFT", 6, 0)
  stripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  stripe:SetVertexColor(cfg.color[1], cfg.color[2], cfg.color[3])

  local icon = optBtn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(14, 14)
  icon:SetPoint("LEFT", stripe, "RIGHT", 6, 0)
  icon:SetTexture(cfg.icon)

  local text = optBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  text:SetText(cfg.name)

  local statusTag = optBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  statusTag:SetPoint("RIGHT", optBtn, "RIGHT", -10, 0)
  optBtn.statusTag = statusTag

  optBtn:SetScript("OnClick", function()
    SelectAutomationSubTab(i)
  end)

  optBtn:SetScript("OnEnter", function(self)
    if i ~= autoSubTabSelected then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 0.9)
    end
  end)
  optBtn:SetScript("OnLeave", function(self)
    if i ~= autoSubTabSelected then
      self:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.6)
    end
  end)

  dropdownOptionBtns[i] = optBtn
end

headerBtn:SetScript("OnClick", function()
  if dropdownMenu:IsShown() then
    HideDropdownMenu()
  else
    XPRate.UpdateDropdownCheckmarks()
    dropdownMenu:Show()
    coverFrame:Show()
    headerArrow:SetText("^")
  end
end)

headerBtn:SetScript("OnEnter", function(self)
  self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 0.95)
  headerArrow:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
end)
headerBtn:SetScript("OnLeave", function(self)
  self:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.95)
  headerArrow:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])
end)

AutomationTabFrame:SetScript("OnHide", HideDropdownMenu)

-- ==================== Controls in AutoRestedSubFrame ====================
local restedCheckbox = CreateFrame("CheckButton", "XPRateRestedCheckbox", AutoRestedSubFrame, "UICheckButtonTemplate")
XPRate.restedCheckbox = restedCheckbox
restedCheckbox:SetSize(22, 22)
restedCheckbox:SetPoint("TOPLEFT", AutoRestedSubFrame, "TOPLEFT", 12, -6)

local restedCheckLabel = AutoRestedSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
restedCheckLabel:SetPoint("LEFT", restedCheckbox, "RIGHT", 6, 0)
restedCheckLabel:SetText("Auto-switch on Rested XP")
restedCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local restedStateValue = AutoRestedSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
restedStateValue:SetPoint("TOPLEFT", AutoRestedSubFrame, "TOPLEFT", 12, -32)
restedStateValue:SetText("Status: Inactive")
XPRate.restedStateValue = restedStateValue

restedCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoRested = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Rested Auto ON" or "Rested Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)

restedCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch XP rates depending on whether you have Rested XP.")
end)
restedCheckbox:SetScript("OnLeave", HideTooltip)

local updateRestedRow = XPRate.CreateRestedPresetRow(AutoRestedSubFrame, "Rested Rate", -52,
  function(val)
    XPRateControlDB.restedRate = ClampRate(val)
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Rested Rate Updated")
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
  end,
  function()
    return XPRateControlDB and XPRateControlDB.restedRate or 2.0
  end
)
XPRate.updateRestedRow = updateRestedRow

local updateNormalRow = XPRate.CreateRestedPresetRow(AutoRestedSubFrame, "Normal Rate", -94,
  function(val)
    XPRateControlDB.normalRate = ClampRate(val)
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Normal Rate Updated")
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
  end,
  function()
    return XPRateControlDB and XPRateControlDB.normalRate or 1.0
  end
)
XPRate.updateNormalRow = updateNormalRow

-- ==================== Controls in AutoGroupSubFrame (Party Size) ====================
local groupCheckbox = CreateFrame("CheckButton", "XPRateGroupCheckbox", AutoGroupSubFrame, "UICheckButtonTemplate")
XPRate.groupCheckbox = groupCheckbox
groupCheckbox:SetSize(22, 22)
groupCheckbox:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12, -6)

local groupCheckLabel = AutoGroupSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
groupCheckLabel:SetPoint("LEFT", groupCheckbox, "RIGHT", 6, 0)
groupCheckLabel:SetText("Auto-scale rates by party size")
groupCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local groupStateValue = AutoGroupSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
groupStateValue:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12, -32)
groupStateValue:SetText("Status: Inactive")
XPRate.groupStateValue = groupStateValue

groupCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoGroup = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Party Auto ON" or "Party Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
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
groupRatesLabel:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12, -50)
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
  btn:SetPoint("TOPLEFT", AutoGroupSubFrame, "TOPLEFT", 12 + (i-1)*56, -66)

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

updateGroupRow = XPRate.CreateRestedPresetRow(AutoGroupSubFrame, "Target Rate for Party Size", -92,
  function(val)
    if XPRateControlDB and XPRateControlDB.groupRates then
      XPRateControlDB.groupRates[groupSelectedSize] = ClampRate(val)
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, string.format("%s Rate Updated", partyLabels[groupSelectedSize]))
      XPRate.UpdatePartyButtonsUI()
      if updateGroupRow then updateGroupRow() end
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    end
  end,
  function()
    return XPRateControlDB and XPRateControlDB.groupRates and XPRateControlDB.groupRates[groupSelectedSize] or 1.0
  end
)
XPRate.updateGroupRow = updateGroupRow

-- ==================== Controls in AutoDisparitySubFrame (Disparity Protection) ====================
local disparityCheckbox = CreateFrame("CheckButton", "XPRateDisparityCheckbox", AutoDisparitySubFrame, "UICheckButtonTemplate")
XPRate.disparityCheckbox = disparityCheckbox
disparityCheckbox:SetSize(22, 22)
disparityCheckbox:SetPoint("TOPLEFT", AutoDisparitySubFrame, "TOPLEFT", 12, -6)

local disparityCheckLabel = AutoDisparitySubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
disparityCheckLabel:SetPoint("LEFT", disparityCheckbox, "RIGHT", 6, 0)
disparityCheckLabel:SetText("Auto-dampen rate on level disparity")
disparityCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local disparityStateValue = AutoDisparitySubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
disparityStateValue:SetPoint("TOPLEFT", AutoDisparitySubFrame, "TOPLEFT", 12, -32)
disparityStateValue:SetText("Status: Inactive")
XPRate.disparityStateValue = disparityStateValue

disparityCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoDisparity = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Party Disparity Auto ON" or "Party Disparity Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)

disparityCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch to Disparity Rate when level gap between group members exceeds threshold.")
end)
disparityCheckbox:SetScript("OnLeave", HideTooltip)

local disparityThreshLabel = AutoDisparitySubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
disparityThreshLabel:SetPoint("TOPLEFT", AutoDisparitySubFrame, "TOPLEFT", 12, -50)
disparityThreshLabel:SetText("Select Disparity Threshold (Levels):")
disparityThreshLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local threshPresetVals = { 3, 5, 7, 10 }
local threshPresetBtns = {}

local threshEditbox = CreateFrame("EditBox", nil, AutoDisparitySubFrame)
threshEditbox:SetSize(52, 20)
threshEditbox:SetPoint("TOPLEFT", AutoDisparitySubFrame, "TOPLEFT", 240, -66)
threshEditbox:SetAutoFocus(false)
threshEditbox:SetFontObject("GameFontHighlightSmall")
threshEditbox:SetJustifyH("CENTER")
threshEditbox:SetMaxLetters(3)
threshEditbox:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
threshEditbox:SetBackdropColor(0.02, 0.03, 0.06, 0.85)
threshEditbox:SetBackdropBorderColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.6)

local function updateThreshSelection()
  local currentVal = XPRateControlDB and XPRateControlDB.disparityThreshold or 5
  for i, btn in ipairs(threshPresetBtns) do
    if threshPresetVals[i] == currentVal then
      btn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
      btn:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    else
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
      btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
      btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end
  if not threshEditbox:HasFocus() then
    threshEditbox:SetText(tostring(currentVal))
  end
end

for i = 1, 4 do
  local btn = MakeButton(AutoDisparitySubFrame, 54, 20, CLR.btnBg, CLR.btnEdge)
  btn:SetPoint("TOPLEFT", AutoDisparitySubFrame, "TOPLEFT", 12 + (i-1)*56, -66)
  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("CENTER")
  text:SetText(threshPresetVals[i] .. " Lvs")
  text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
  btn.text = text

  local val = threshPresetVals[i]
  btn:SetScript("OnClick", function()
    XPRateControlDB.disparityThreshold = val
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Disparity Threshold Updated")
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
  end)

  btn:SetScript("OnEnter", function(self)
    if (XPRateControlDB and XPRateControlDB.disparityThreshold) ~= val then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    updateThreshSelection()
  end)

  threshPresetBtns[i] = btn
end

threshEditbox:SetScript("OnEditFocusGained", function(self)
  self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
end)
threshEditbox:SetScript("OnEscapePressed", function(self)
  self.reverting = true
  self:ClearFocus()
  updateThreshSelection()
end)
threshEditbox:SetScript("OnEnterPressed", function(self)
  self:ClearFocus()
end)
threshEditbox:SetScript("OnEditFocusLost", function(self)
  self:SetBackdropBorderColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.6)
  if self.reverting then
    self.reverting = nil
    return
  end
  local val = tonumber(self:GetText())
  if val then
    local clamped = math.max(1, math.min(20, math.floor(val)))
    XPRateControlDB.disparityThreshold = clamped
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Disparity Threshold Updated")
  end
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)
threshEditbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Type disparity threshold in levels (1-20), press Enter")
end)
threshEditbox:SetScript("OnLeave", HideTooltip)

XPRate.updateDisparityThresholdRow = updateThreshSelection

local updateDisparityRateRow = XPRate.CreateRestedPresetRow(AutoDisparitySubFrame, "Disparity Rate (Multiplier)", -92,
  function(val)
    if XPRateControlDB then
      XPRateControlDB.disparityRate = ClampRate(val)
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, "Disparity Rate Updated")
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    end
  end,
  function()
    return XPRateControlDB and XPRateControlDB.disparityRate or 0.50
  end
)
XPRate.updateDisparityRateRow = updateDisparityRateRow

-- ==================== Controls in AutoMobSubFrame ====================
local mobCheckbox = CreateFrame("CheckButton", "XPRateMobCheckbox", AutoMobSubFrame, "UICheckButtonTemplate")
XPRate.mobCheckbox = mobCheckbox
mobCheckbox:SetSize(22, 22)
mobCheckbox:SetPoint("TOPLEFT", AutoMobSubFrame, "TOPLEFT", 12, -6)

local mobCheckLabel = AutoMobSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
mobCheckLabel:SetPoint("LEFT", mobCheckbox, "RIGHT", 6, 0)
mobCheckLabel:SetText("Auto-scale rates by mob color")
mobCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local mobStateValue = AutoMobSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mobStateValue:SetPoint("TOPLEFT", AutoMobSubFrame, "TOPLEFT", 12, -32)
mobStateValue:SetText("Target: None / Non-Enemy")
XPRate.mobStateValue = mobStateValue

mobCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoMob = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Mob Auto ON" or "Mob Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)

mobCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch XP rate based on target mob difficulty color.")
end)
mobCheckbox:SetScript("OnLeave", HideTooltip)

local mobSelectedCategory = 1 -- 1=gray, 2=green, 3=yellow, 4=red
local mobCategories = {
  { key = "gray",   label = "Gray",       color = CLR.dim },
  { key = "green",  label = "Green",      color = CLR.green },
  { key = "yellow", label = "Yellow",     color = CLR.gold },
  { key = "red",    label = "Orange/Red", color = CLR.red },
}
local mobButtons = {}
local updateMobRow = nil

local mobRatesLabel = AutoMobSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
mobRatesLabel:SetPoint("TOPLEFT", AutoMobSubFrame, "TOPLEFT", 12, -50)
mobRatesLabel:SetText("Select Mob Color to Configure:")
mobRatesLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

function XPRate.UpdateMobButtonsUI()
  local currentCategory = XPRate.GetUnitDifficultyCategory and XPRate.GetUnitDifficultyCategory("target")
  for i, btn in ipairs(mobButtons) do
    local cat = mobCategories[i]
    if i == mobSelectedCategory then
      btn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
      btn:SetBackdropBorderColor(cat.color[1], cat.color[2], cat.color[3], 0.95)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    elseif (currentCategory == cat.key) and XPRateControlDB and XPRateControlDB.autoMob then
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
      btn:SetBackdropBorderColor(cat.color[1], cat.color[2], cat.color[3], 0.9)
      btn.text:SetTextColor(cat.color[1], cat.color[2], cat.color[3])
    else
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
      btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
      btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end
end

for i = 1, 4 do
  local btn = CreateFrame("Button", nil, AutoMobSubFrame)
  btn:SetSize(68, 20)
  btn:SetPoint("TOPLEFT", AutoMobSubFrame, "TOPLEFT", 12 + (i-1)*71, -66)

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
  text:SetText(mobCategories[i].label)
  text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
  btn.text = text

  btn:SetScript("OnClick", function()
    mobSelectedCategory = i
    XPRate.UpdateMobButtonsUI()
    if updateMobRow then updateMobRow() end
  end)

  btn:SetScript("OnEnter", function(self)
    if i ~= mobSelectedCategory then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    XPRate.UpdateMobButtonsUI()
  end)

  mobButtons[i] = btn
end

XPRate.UpdateMobButtonsUI()

updateMobRow = XPRate.CreateRestedPresetRow(AutoMobSubFrame, "Target Rate for Mob Color", -92,
  function(val)
    local catKey = mobCategories[mobSelectedCategory].key
    if XPRateControlDB and XPRateControlDB.mobRates then
      XPRateControlDB.mobRates[catKey] = ClampRate(val)
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, string.format("%s Rate Updated", mobCategories[mobSelectedCategory].label))
      XPRate.UpdateMobButtonsUI()
      if updateMobRow then updateMobRow() end
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    end
  end,
  function()
    local catKey = mobCategories[mobSelectedCategory].key
    local defaultVal = (catKey == "gray" and 0.0 or (catKey == "green" and 0.5 or (catKey == "yellow" and 1.0 or 2.0)))
    return XPRateControlDB and XPRateControlDB.mobRates and XPRateControlDB.mobRates[catKey] or defaultVal
  end
)

function XPRate.updateMobRows()
  XPRate.UpdateMobButtonsUI()
  if updateMobRow then updateMobRow() end
end

-- ==================== Controls in AutoQuestSubFrame ====================
local questCheckbox = CreateFrame("CheckButton", "XPRateQuestCheckbox", AutoQuestSubFrame, "UICheckButtonTemplate")
XPRate.questCheckbox = questCheckbox
questCheckbox:SetSize(22, 22)
questCheckbox:SetPoint("TOPLEFT", AutoQuestSubFrame, "TOPLEFT", 12, -6)

local questCheckLabel = AutoQuestSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
questCheckLabel:SetPoint("LEFT", questCheckbox, "RIGHT", 6, 0)
questCheckLabel:SetText("Auto-switch on Quest Interaction")
questCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local questStateValue = AutoQuestSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
questStateValue:SetPoint("TOPLEFT", AutoQuestSubFrame, "TOPLEFT", 12, -32)
questStateValue:SetText("Status: Inactive")
XPRate.questStateValue = questStateValue

questCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoQuest = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Quest Auto ON" or "Quest Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)

questCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch XP rate when interacting with Quest NPCs.")
end)
questCheckbox:SetScript("OnLeave", HideTooltip)

local updateQuestRow = XPRate.CreateRestedPresetRow(AutoQuestSubFrame, "Quest Interaction Rate", -52,
  function(val)
    XPRateControlDB.questRate = ClampRate(val)
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    EvaluateAutomation(false, "Quest Rate Updated")
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
  end,
  function()
    return XPRateControlDB and XPRateControlDB.questRate or 2.0
  end
)
XPRate.updateQuestRow = updateQuestRow

-- ==================== Controls in AutoBracketSubFrame ====================
local bracketCheckbox = CreateFrame("CheckButton", "XPRateBracketCheckbox", AutoBracketSubFrame, "UICheckButtonTemplate")
XPRate.bracketCheckbox = bracketCheckbox
bracketCheckbox:SetSize(22, 22)
bracketCheckbox:SetPoint("TOPLEFT", AutoBracketSubFrame, "TOPLEFT", 12, -6)

local bracketCheckLabel = AutoBracketSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
bracketCheckLabel:SetPoint("LEFT", bracketCheckbox, "RIGHT", 6, 0)
bracketCheckLabel:SetText("Auto-scale rates by level bracket")
bracketCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local bracketStateValue = AutoBracketSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bracketStateValue:SetPoint("TOPLEFT", AutoBracketSubFrame, "TOPLEFT", 12, -32)
bracketStateValue:SetText("Bracket: Lv 1-59 (Auto OFF)")
XPRate.bracketStateValue = bracketStateValue

bracketCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoBracket = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Bracket Auto ON" or "Bracket Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)

bracketCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically adjust XP rate based on player's level bracket.")
end)
bracketCheckbox:SetScript("OnLeave", HideTooltip)

local bracketSelectedCategory = 1 -- 1=1-59, 2=60-69, 3=70-79, 4=80
local bracketCategories = {
  { index = 1, label = "Lv 1-59", min = 1,  max = 59, default = 2.0 },
  { index = 2, label = "Lv 60-69", min = 60, max = 69, default = 1.5 },
  { index = 3, label = "Lv 70-79", min = 70, max = 79, default = 1.0 },
  { index = 4, label = "Lv 80",    min = 80, max = 80, default = 0.0 },
}
local bracketButtons = {}
local updateBracketRow = nil

local bracketRatesLabel = AutoBracketSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
bracketRatesLabel:SetPoint("TOPLEFT", AutoBracketSubFrame, "TOPLEFT", 12, -50)
bracketRatesLabel:SetText("Select Level Bracket to Configure:")
bracketRatesLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

function XPRate.UpdateBracketButtonsUI()
  local playerLevel = (UnitLevel and UnitLevel("player")) or 1
  for i, btn in ipairs(bracketButtons) do
    local cat = bracketCategories[i]
    local isPlayerInBracket = (playerLevel >= cat.min and playerLevel <= cat.max)
    if i == bracketSelectedCategory then
      btn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
      btn:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    elseif isPlayerInBracket and XPRateControlDB and XPRateControlDB.autoBracket then
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

for i = 1, 4 do
  local btn = CreateFrame("Button", nil, AutoBracketSubFrame)
  btn:SetSize(68, 20)
  btn:SetPoint("TOPLEFT", AutoBracketSubFrame, "TOPLEFT", 12 + (i-1)*71, -66)

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
  text:SetText(bracketCategories[i].label)
  text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
  btn.text = text

  btn:SetScript("OnClick", function()
    bracketSelectedCategory = i
    XPRate.UpdateBracketButtonsUI()
    if updateBracketRow then updateBracketRow() end
  end)

  btn:SetScript("OnEnter", function(self)
    if i ~= bracketSelectedCategory then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    XPRate.UpdateBracketButtonsUI()
  end)

  bracketButtons[i] = btn
end

XPRate.UpdateBracketButtonsUI()

updateBracketRow = XPRate.CreateRestedPresetRow(AutoBracketSubFrame, "Target Rate for Level Bracket", -92,
  function(val)
    if XPRateControlDB and XPRateControlDB.bracketRates and XPRateControlDB.bracketRates[bracketSelectedCategory] then
      XPRateControlDB.bracketRates[bracketSelectedCategory].rate = ClampRate(val)
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, string.format("%s Rate Updated", bracketCategories[bracketSelectedCategory].label))
      XPRate.UpdateBracketButtonsUI()
      if updateBracketRow then updateBracketRow() end
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    end
  end,
  function()
    if XPRateControlDB and XPRateControlDB.bracketRates and XPRateControlDB.bracketRates[bracketSelectedCategory] then
      return XPRateControlDB.bracketRates[bracketSelectedCategory].rate
    end
    return bracketCategories[bracketSelectedCategory].default
  end
)

function XPRate.updateBracketRows()
  XPRate.UpdateBracketButtonsUI()
  if updateBracketRow then updateBracketRow() end
end

-- ==================== Controls in AutoZoneSubFrame ====================
local zoneCheckbox = CreateFrame("CheckButton", "XPRateZoneCheckbox", AutoZoneSubFrame, "UICheckButtonTemplate")
XPRate.zoneCheckbox = zoneCheckbox
zoneCheckbox:SetSize(22, 22)
zoneCheckbox:SetPoint("TOPLEFT", AutoZoneSubFrame, "TOPLEFT", 12, -6)

local zoneCheckLabel = AutoZoneSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
zoneCheckLabel:SetPoint("LEFT", zoneCheckbox, "RIGHT", 6, 0)
zoneCheckLabel:SetText("Auto-scale rates by zone / instance")
zoneCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local zoneStateValue = AutoZoneSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
zoneStateValue:SetPoint("TOPLEFT", AutoZoneSubFrame, "TOPLEFT", 12, -32)
zoneStateValue:SetText("Zone: Open World (Auto OFF)")
XPRate.zoneStateValue = zoneStateValue

zoneCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  XPRateControlDB.autoZone = enabled
  XPRate.lastAppliedRate = nil
  XPRate.lastAppliedMode = nil
  EvaluateAutomation(false, enabled and "Zone Auto ON" or "Zone Auto OFF")
  if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
end)

zoneCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Automatically switch XP rates when entering Dungeons, Raids, PvP, or Open World.")
end)
zoneCheckbox:SetScript("OnLeave", HideTooltip)

local zoneSelectedCategory = 1 -- 1=world, 2=dungeon, 3=raid, 4=pvp
local zoneCategories = {
  { key = "world",   label = "World",   default = 1.0 },
  { key = "dungeon", label = "Dungeon", default = 1.0 },
  { key = "raid",    label = "Raid",    default = 0.0 },
  { key = "pvp",     label = "PvP",     default = 1.0 },
}
local zoneButtons = {}
local updateZoneRow = nil

local zoneRatesLabel = AutoZoneSubFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
zoneRatesLabel:SetPoint("TOPLEFT", AutoZoneSubFrame, "TOPLEFT", 12, -50)
zoneRatesLabel:SetText("Select Zone Type to Configure:")
zoneRatesLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

function XPRate.UpdateZoneButtonsUI()
  local currentZoneCat = XPRate.GetCurrentZoneType and XPRate.GetCurrentZoneType() or "world"
  for i, btn in ipairs(zoneButtons) do
    local cat = zoneCategories[i]
    if i == zoneSelectedCategory then
      btn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
      btn:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    elseif (currentZoneCat == cat.key) and XPRateControlDB and XPRateControlDB.autoZone then
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

for i = 1, 4 do
  local btn = CreateFrame("Button", nil, AutoZoneSubFrame)
  btn:SetSize(68, 20)
  btn:SetPoint("TOPLEFT", AutoZoneSubFrame, "TOPLEFT", 12 + (i-1)*71, -66)

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
  text:SetText(zoneCategories[i].label)
  text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
  btn.text = text

  btn:SetScript("OnClick", function()
    zoneSelectedCategory = i
    XPRate.UpdateZoneButtonsUI()
    if updateZoneRow then updateZoneRow() end
  end)

  btn:SetScript("OnEnter", function(self)
    if i ~= zoneSelectedCategory then
      self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
    end
  end)
  btn:SetScript("OnLeave", function(self)
    XPRate.UpdateZoneButtonsUI()
  end)

  zoneButtons[i] = btn
end

XPRate.UpdateZoneButtonsUI()

updateZoneRow = XPRate.CreateRestedPresetRow(AutoZoneSubFrame, "Target Rate for Zone Type", -92,
  function(val)
    local catKey = zoneCategories[zoneSelectedCategory].key
    if XPRateControlDB and XPRateControlDB.zoneRates then
      XPRateControlDB.zoneRates[catKey] = ClampRate(val)
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, string.format("%s Rate Updated", zoneCategories[zoneSelectedCategory].label))
      XPRate.UpdateZoneButtonsUI()
      if updateZoneRow then updateZoneRow() end
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    end
  end,
  function()
    local catKey = zoneCategories[zoneSelectedCategory].key
    if XPRateControlDB and XPRateControlDB.zoneRates and XPRateControlDB.zoneRates[catKey] ~= nil then
      return XPRateControlDB.zoneRates[catKey]
    end
    return zoneCategories[zoneSelectedCategory].default
  end
)

function XPRate.updateZoneRows()
  XPRate.UpdateZoneButtonsUI()
  if updateZoneRow then updateZoneRow() end
end

-- ==================== Master UI Refresh Function ====================
function XPRate.UpdateAutomationTabUI()
  local db = XPRateControlDB
  if not db then return end

  -- 1. Refresh Checkbox Toggle States
  if XPRate.restedCheckbox then XPRate.restedCheckbox:SetChecked(db.autoRested and true or false) end
  if XPRate.groupCheckbox then XPRate.groupCheckbox:SetChecked(db.autoGroup and true or false) end
  if XPRate.disparityCheckbox then XPRate.disparityCheckbox:SetChecked(db.autoDisparity and true or false) end
  if XPRate.mobCheckbox then XPRate.mobCheckbox:SetChecked(db.autoMob and true or false) end
  if XPRate.questCheckbox then XPRate.questCheckbox:SetChecked(db.autoQuest and true or false) end
  if XPRate.bracketCheckbox then XPRate.bracketCheckbox:SetChecked(db.autoBracket and true or false) end
  if XPRate.zoneCheckbox then XPRate.zoneCheckbox:SetChecked(db.autoZone and true or false) end

  -- 2. Refresh Dropdown Menu Checkmarks (1..7)
  if XPRate.UpdateDropdownCheckmarks then XPRate.UpdateDropdownCheckmarks() end

  -- 3. Refresh Sub-Tab Control Rows / Inputs
  if XPRate.updateRestedRow then XPRate.updateRestedRow() end
  if XPRate.updateNormalRow then XPRate.updateNormalRow() end
  if XPRate.updateGroupRow then XPRate.updateGroupRow() end
  if XPRate.updateDisparityThresholdRow then XPRate.updateDisparityThresholdRow() end
  if XPRate.updateDisparityRateRow then XPRate.updateDisparityRateRow() end
  if XPRate.updateMobRows then XPRate.updateMobRows() end
  if XPRate.updateQuestRow then XPRate.updateQuestRow() end
  if XPRate.updateBracketRows then XPRate.updateBracketRows() end
  if XPRate.updateZoneRows then XPRate.updateZoneRows() end

  -- 4. Refresh Button Highlights
  if XPRate.UpdatePartyButtonsUI then XPRate.UpdatePartyButtonsUI() end
  if XPRate.UpdateMobButtonsUI then XPRate.UpdateMobButtonsUI() end
  if XPRate.UpdateBracketButtonsUI then XPRate.UpdateBracketButtonsUI() end
  if XPRate.UpdateZoneButtonsUI then XPRate.UpdateZoneButtonsUI() end

  -- 5. Refresh Status Texts across all 7 Sub-Tabs
  if XPRate.UpdateAutomationStatus then XPRate.UpdateAutomationStatus() end
end

-- Initialize default selection (1 = Rested XP)
SelectAutomationSubTab(1)
