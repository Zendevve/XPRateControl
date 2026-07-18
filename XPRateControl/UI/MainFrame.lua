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
version:SetText("v1.1")
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

local tabFrames = { RatesTabFrame, AutomationTabFrame, BuffsTabFrame }
local tabColors = { CLR.cyan, CLR.green, CLR.gold }

-- Navigation Tab Bar
local tabButtons = {}
local tabNames   = { "Rates", "Automation", "Buffs" }
local tabIcons   = {
  "Interface\\AddOns\\XPRateControl\\Textures\\Icon_XPRate",
  "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Automation",
  "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Buffs"
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
    if XPRate.UpdateAutomationStatus then XPRate.UpdateAutomationStatus() end
  end
end

for i = 1, 3 do
  local btn = CreateFrame("Button", nil, frame)
  btn:SetSize(98, 24)
  btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i-1)*101, -38)

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
  icon:SetSize(15, 15)
  icon:SetPoint("LEFT", btn, "LEFT", 5, 0)
  icon:SetTexture(tabIcons[i])
  btn.icon = icon

  local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  text:SetPoint("LEFT", icon, "RIGHT", 3, 0)
  text:SetText(tabNames[i])
  btn.text = text

  btn:SetScript("OnClick", function()
    XPRate.SetActiveTab(i)
  end)

  tabButtons[i] = btn
end

-- Footer bevel line & branding text
local footerBevel = frame:CreateTexture(nil, "ARTWORK")
footerBevel:SetSize(304, 1)
footerBevel:SetPoint("BOTTOM", frame, "BOTTOM", 0, 30)
footerBevel:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
footerBevel:SetVertexColor(CLR.cardEdge[1], CLR.cardEdge[2], CLR.cardEdge[3], 0.6)

local footerText = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footerText:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 12, 10)
footerText:SetText("XP Rate Control v1.1 | WotLK 3.3.5a")
footerText:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.7)
