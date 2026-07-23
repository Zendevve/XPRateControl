-- UI/MainFrame.lua — Main UI panel, window styling, and tab bar navigation for XPRateControl
local addonName, XPRate = ...

local CLR = XPRate.CLR

-- Main UI Frame
local frame = CreateFrame("Frame", "XPRateControlFrame", UIParent)
XPRate.frame = frame
frame:SetSize(320, 335)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetFrameStrata("HIGH")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:Hide()

tinsert(UISpecialFrames, "XPRateControlFrame")

frame:SetBackdrop({
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 32, edgeSize = 16,
  insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.97)
frame:SetBackdropBorderColor(CLR.cardEdge[1], CLR.cardEdge[2], CLR.cardEdge[3], 0.95)

-- Title Bar Drag Handle
local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -36, -6)
titleBar:SetHeight(32)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")

titleBar:SetScript("OnDragStart", function(self)
  frame:StartMoving()
end)

titleBar:SetScript("OnDragStop", function(self)
  frame:StopMovingOrSizing()
  local point, _, relativePoint, xOfs, yOfs = frame:GetPoint()
  if XPRateControlDB then
    XPRateControlDB.framePos = {
      point = point,
      relativePoint = relativePoint,
      xOfs = xOfs,
      yOfs = yOfs
    }
  end
end)

-- Header bar texture
local headerBg = titleBar:CreateTexture(nil, "BACKGROUND")
headerBg:SetAllPoints(titleBar)
headerBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
headerBg:SetGradientAlpha("HORIZONTAL",
  CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.95,
  CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.3)

-- Title
local title = titleBar:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("LEFT", titleBar, "LEFT", 6, 0)
title:SetText("XP Rate Control")
title:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

-- Version
local version = titleBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
version:SetPoint("LEFT", title, "RIGHT", 6, 0)
version:SetText("v1.4")
version:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

-- Close button
local closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)
closeBtn:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 10, edgeSize = 10,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
closeBtn:SetBackdropColor(0.35, 0.08, 0.08, 0.9)
closeBtn:SetBackdropBorderColor(0.7, 0.2, 0.2, 0.8)

local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 0)
closeText:SetText("X")
closeText:SetTextColor(0.9, 0.9, 0.9)

closeBtn:SetScript("OnEnter", function()
  closeBtn:SetBackdropColor(0.7, 0.12, 0.12, 1.0)
  closeBtn:SetBackdropBorderColor(1.0, 0.35, 0.35, 1.0)
  closeText:SetTextColor(1, 1, 1)
end)
closeBtn:SetScript("OnLeave", function()
  closeBtn:SetBackdropColor(0.35, 0.08, 0.08, 0.9)
  closeBtn:SetBackdropBorderColor(0.7, 0.2, 0.2, 0.8)
  closeText:SetTextColor(0.9, 0.9, 0.9)
end)
closeBtn:SetScript("OnClick", function()
  frame:Hide()
end)

-- Tab Layout Containers
local RatesTabFrame = CreateFrame("Frame", nil, frame)
RatesTabFrame:SetSize(308, 230)
RatesTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)
XPRate.RatesTabFrame = RatesTabFrame

local AutomationTabFrame = CreateFrame("Frame", nil, frame)
AutomationTabFrame:SetSize(308, 230)
AutomationTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)
AutomationTabFrame:Hide()
XPRate.AutomationTabFrame = AutomationTabFrame

local BuffsTabFrame = CreateFrame("Frame", nil, frame)
BuffsTabFrame:SetSize(308, 230)
BuffsTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)
BuffsTabFrame:Hide()
XPRate.BuffsTabFrame = BuffsTabFrame

local SettingsTabFrame = CreateFrame("Frame", nil, frame)
SettingsTabFrame:SetSize(308, 230)
SettingsTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)
SettingsTabFrame:Hide()
XPRate.SettingsTabFrame = SettingsTabFrame

local tabFrames = { RatesTabFrame, AutomationTabFrame, BuffsTabFrame, SettingsTabFrame }
local tabColors = { CLR.cyan, CLR.green, CLR.gold, CLR.cyan }

-- Navigation Tab Bar
local tabButtons = {}
local tabNames   = { "Rates", "Auto", "Buffs", "Settings" }
local tabIcons   = {
  "Interface\\AddOns\\XPRateControl\\Textures\\Icon_XPRate",
  "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Automation",
  "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Buffs",
  "Interface\\Icons\\Trade_Engineering"
}

function XPRate.SetActiveTab(index)
  for i, btn in ipairs(tabButtons) do
    if i == index then
      btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.95)
      btn:SetBackdropBorderColor(tabColors[i][1], tabColors[i][2], tabColors[i][3], 0.9)
      btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
      btn.icon:SetVertexColor(1, 1, 1, 1)
      tabFrames[i]:Show()
    else
      btn:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.6)
      btn:SetBackdropBorderColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.4)
      btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
      btn.icon:SetVertexColor(0.6, 0.6, 0.6, 0.7)
      tabFrames[i]:Hide()
    end
  end

  if XPRate.toast then
    XPRate.toast:Hide()
  end

  if index == 2 then
    if XPRate.updateRestedRow then XPRate.updateRestedRow() end
    if XPRate.updateNormalRow then XPRate.updateNormalRow() end
    if XPRate.updateMobRows then XPRate.updateMobRows() end
    if XPRate.UpdateAutomationStatus then XPRate.UpdateAutomationStatus() end
  elseif index == 4 then
    if XPRate.UpdateSettingsTabUI then XPRate.UpdateSettingsTabUI() end
    if XPRate.UpdateTabSettingsUI then XPRate.UpdateTabSettingsUI() end
  end
end

for i = 1, 4 do
  local btn = CreateFrame("Button", nil, frame)
  btn:SetSize(72, 24)
  btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i-1)*76, -38)

  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
  })

  local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  highlight:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.05, 1, 1, 1, 0.1)
  highlight:SetBlendMode("ADD")

  local icon = btn:CreateTexture(nil, "ARTWORK")
  icon:SetSize(14, 14)
  icon:SetPoint("LEFT", btn, "LEFT", 4, 0)
  icon:SetTexture(tabIcons[i])
  btn.icon = icon

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", icon, "RIGHT", 2, 0)
  text:SetText(tabNames[i])
  btn.text = text

  btn:SetScript("OnClick", function()
    XPRate.SetActiveTab(i)
  end)

  tabButtons[i] = btn
end

-- Footer bevel line & branding
local footerBevel = frame:CreateTexture(nil, "ARTWORK")
footerBevel:SetSize(304, 1)
footerBevel:SetPoint("BOTTOM", frame, "BOTTOM", 0, 30)
footerBevel:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
footerBevel:SetVertexColor(CLR.cardEdge[1], CLR.cardEdge[2], CLR.cardEdge[3], 0.6)

-- Support Copy Popup Dialog
local copyFrame = CreateFrame("Frame", "XPRateCopyFrame", UIParent)
copyFrame:SetSize(280, 80)
copyFrame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
copyFrame:SetFrameStrata("DIALOG")
copyFrame:SetBackdrop({
  bgFile   = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 16, edgeSize = 16,
  insets = { left = 4, right = 4, top = 4, bottom = 4 }
})
copyFrame:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.98)
copyFrame:SetBackdropBorderColor(CLR.gold[1], CLR.gold[2], CLR.gold[3], 0.9)
copyFrame:Hide()

local copyTitle = copyFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
copyTitle:SetPoint("TOP", copyFrame, "TOP", 0, -12)
copyTitle:SetText("Press Ctrl+C to copy link:")
copyTitle:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3])

local copyEditBox = CreateFrame("EditBox", nil, copyFrame)
copyEditBox:SetSize(248, 22)
copyEditBox:SetPoint("CENTER", copyFrame, "CENTER", 0, -6)
copyEditBox:SetFontObject("GameFontHighlightSmall")
copyEditBox:SetJustifyH("CENTER")
copyEditBox:SetAutoFocus(false)
copyEditBox:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
copyEditBox:SetBackdropColor(0.02, 0.03, 0.06, 0.9)
copyEditBox:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.8)
copyEditBox:SetText("https://buymeacoffee.com/zendevve")

copyEditBox:SetScript("OnEscapePressed", function(self)
  copyFrame:Hide()
end)
copyEditBox:SetScript("OnEditFocusLost", function(self)
  self:HighlightText(0, 0)
end)

local copyCloseBtn = CreateFrame("Button", nil, copyFrame)
copyCloseBtn:SetSize(18, 18)
copyCloseBtn:SetPoint("TOPRIGHT", copyFrame, "TOPRIGHT", -4, -4)
copyCloseBtn:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
copyCloseBtn:SetBackdropColor(0.35, 0.08, 0.08, 0.9)
copyCloseBtn:SetBackdropBorderColor(0.7, 0.2, 0.2, 0.8)

local copyCloseText = copyCloseBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
copyCloseText:SetPoint("CENTER", copyCloseBtn, "CENTER", 0, 0)
copyCloseText:SetText("X")
copyCloseText:SetTextColor(0.9, 0.9, 0.9)

copyCloseBtn:SetScript("OnClick", function()
  copyFrame:Hide()
end)

-- BuyMeACoffee Button (Centered Footer)
local donateBtn = CreateFrame("Button", nil, frame)
donateBtn:SetSize(170, 20)
donateBtn:SetPoint("BOTTOM", frame, "BOTTOM", 0, 5)

local coffeeIcon = donateBtn:CreateTexture(nil, "ARTWORK")
coffeeIcon:SetSize(14, 14)
coffeeIcon:SetPoint("LEFT", donateBtn, "LEFT", 0, 0)
coffeeIcon:SetTexture("Interface\\AddOns\\XPRateControl\\Textures\\Icon_Donate")

local donateText = donateBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
donateText:SetPoint("LEFT", coffeeIcon, "RIGHT", 4, 0)
donateText:SetText("buymeacoffee.com/zendevve")
donateText:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3], 0.9)

donateBtn:SetScript("OnEnter", function(self)
  donateText:SetTextColor(1, 1, 1, 1)
  if XPRate.ShowTooltip then
    XPRate.ShowTooltip(self, "Click to copy developer support link")
  end
end)

donateBtn:SetScript("OnLeave", function(self)
  donateText:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3], 0.9)
  if XPRate.HideTooltip then
    XPRate.HideTooltip()
  end
end)

donateBtn:SetScript("OnClick", function()
  if XPRate.PrintMessage then
    XPRate.PrintMessage("|cffffcc00Support the developer:|r https://buymeacoffee.com/zendevve")
  end
  copyFrame:Show()
  copyEditBox:SetFocus()
  copyEditBox:HighlightText()
end)
