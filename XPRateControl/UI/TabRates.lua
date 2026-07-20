-- UI/TabRates.lua — Tab 1 Rates UI (Hero card, interactive slider, quick presets) for XPRateControl
local addonName, XPRate = ...

local CLR                 = XPRate.CLR
local RATE_MIN            = XPRate.RATE_MIN
local RATE_MAX            = XPRate.RATE_MAX
local RATE_STEP           = XPRate.RATE_STEP
local DEFAULT_RATE        = XPRate.DEFAULT_RATE
local FormatRate          = XPRate.FormatRate
local ClampRate           = XPRate.ClampRate
local RateColor           = XPRate.RateColor
local ApplyRate            = XPRate.ApplyRate
local ShowTooltip          = XPRate.ShowTooltip
local HideTooltip          = XPRate.HideTooltip
local CreateSectionHeader  = XPRate.CreateSectionHeader

local RatesTabFrame = XPRate.RatesTabFrame

-- Header
CreateSectionHeader(RatesTabFrame, "XP RATE", "Interface\\AddOns\\XPRateControl\\Textures\\Icon_XPRate", CLR.cyan)

-- Inset Card (Hero Element)
local heroCard = CreateFrame("Frame", nil, RatesTabFrame)
heroCard:SetSize(288, 86)
heroCard:SetPoint("TOP", RatesTabFrame, "TOP", 0, -28)
heroCard:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 10, edgeSize = 10,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
heroCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
heroCard:SetBackdropBorderColor(CLR.cardEdge[1] * 1.3, CLR.cardEdge[2] * 1.3, CLR.cardEdge[3] * 1.3, 0.8)

-- Value scaling pulse container
local pulseFrame = CreateFrame("Frame", nil, heroCard)
pulseFrame:SetSize(100, 24)
pulseFrame:SetPoint("CENTER", heroCard, "CENTER", 0, 3)

local valueText = pulseFrame:CreateFontString("XPRateValueTextWidget", "OVERLAY", "GameFontNormalHuge")
valueText:SetAllPoints(pulseFrame)
valueText:SetJustifyH("CENTER")
valueText:SetJustifyV("MIDDLE")

local pulseTime = 0
local pulseDuration = 0.18
local function OnUpdatePulse(self, elapsed)
  pulseTime = pulseTime + elapsed
  if pulseTime >= pulseDuration then
    self:SetScale(1.0)
    self:SetScript("OnUpdate", nil)
  else
    local percent = pulseTime / pulseDuration
    local scale = 1.15 - (0.15 * percent)
    self:SetScale(scale)
  end
end

function XPRate.TriggerPulse()
  pulseTime = 0
  pulseFrame:SetScript("OnUpdate", OnUpdatePulse)
end

-- Tag Chip
local tagChip = CreateFrame("Frame", nil, heroCard)
tagChip:SetSize(70, 14)
tagChip:SetPoint("TOP", pulseFrame, "BOTTOM", 0, -2)
tagChip:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 6, edgeSize = 6,
  insets = { left = 1, right = 1, top = 1, bottom = 1 }
})
tagChip:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)

local tagText = tagChip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
tagText:SetPoint("CENTER")

local function UpdateTagChip(rate)
  local tag = "BLIZZLIKE"
  if rate == 0 then
    tag = "OFF"
  elseif rate < 1 then
    tag = "SLOW"
  elseif rate == 1 then
    tag = "BLIZZLIKE"
  elseif rate < 2 then
    tag = "FAST"
  else
    tag = "MAX"
  end

  local rc = RateColor(rate)
  tagText:SetText(tag)
  tagText:SetTextColor(rc[1], rc[2], rc[3])
  tagChip:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.7)
end

-- Custom Slider
local slider = CreateFrame("Slider", "XPRateSliderWidget", RatesTabFrame)
XPRate.XPRateSliderWidget = slider
slider:SetSize(210, 14)
slider:SetPoint("TOPLEFT", RatesTabFrame, "TOPLEFT", 14, -132)
slider:SetMinMaxValues(RATE_MIN, RATE_MAX)
slider:SetValueStep(RATE_STEP)
slider:SetOrientation("HORIZONTAL")

local thumb = slider:CreateTexture(nil, "ARTWORK")
thumb:SetSize(8, 16)
thumb:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
slider:SetThumbTexture(thumb)

local trackBg = slider:CreateTexture(nil, "BACKGROUND")
trackBg:SetHeight(4)
trackBg:SetPoint("LEFT", slider, "LEFT", 0, 0)
trackBg:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
trackBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
trackBg:SetVertexColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.3)

local trackFill = slider:CreateTexture(nil, "ARTWORK")
trackFill:SetHeight(4)
trackFill:SetPoint("LEFT", slider, "LEFT", 0, 0)
trackFill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
trackFill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

-- Numeric editbox (beside slider)
local editbox = CreateFrame("EditBox", "XPRateEditBoxWidget", RatesTabFrame)
editbox:SetSize(52, 20)
editbox:SetPoint("LEFT", slider, "RIGHT", 12, 0)
editbox:SetAutoFocus(false)
editbox:SetFontObject("GameFontHighlightSmall")
editbox:SetJustifyH("CENTER")
editbox:SetMaxLetters(5)
editbox:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
editbox:SetBackdropColor(0.02, 0.03, 0.06, 0.85)
editbox:SetBackdropBorderColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.6)

-- Floating value bubble
local sliderBubble = CreateFrame("Frame", nil, slider)
sliderBubble:SetSize(40, 18)
sliderBubble:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 8, edgeSize = 8,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
sliderBubble:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.95)
sliderBubble:SetPoint("BOTTOM", thumb, "TOP", 0, 6)
sliderBubble:Hide()

local sliderBubbleText = sliderBubble:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
sliderBubbleText:SetPoint("CENTER")

-- Synchronization logic
local isUpdating = false
local lastUIValue = nil

function XPRate.UpdateUIFromValue(value, source)
  if isUpdating then return end
  isUpdating = true

  local valNum = ClampRate(tonumber(value) or DEFAULT_RATE)
  local formatted = FormatRate(valNum)
  local rc = RateColor(valNum)

  if source ~= "slider" then
    slider:SetValue(valNum)
  end
  if source ~= "editbox" then
    editbox:SetText(formatted)
  end

  valueText:SetText(formatted .. "x")
  valueText:SetTextColor(rc[1], rc[2], rc[3])

  trackFill:SetVertexColor(rc[1], rc[2], rc[3], 0.9)
  thumb:SetVertexColor(rc[1], rc[2], rc[3])

  UpdateTagChip(valNum)

  sliderBubbleText:SetText(formatted .. "x")
  sliderBubbleText:SetTextColor(rc[1], rc[2], rc[3])
  sliderBubble:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.8)

  if source and lastUIValue and math.abs(valNum - lastUIValue) > 0.005 then
    XPRate.TriggerPulse()
  end
  lastUIValue = valNum

  isUpdating = false
end

slider:SetScript("OnValueChanged", function(self, value)
  local snapped = math.floor(value / RATE_STEP + 0.5) * RATE_STEP
  XPRate.UpdateUIFromValue(snapped, "slider")
end)

slider:SetScript("OnMouseUp", function(self)
  ApplyRate(self:GetValue())
end)

slider:EnableMouseWheel(true)
slider:SetScript("OnMouseWheel", function(self, delta)
  local val = self:GetValue()
  local newVal = ClampRate(val + delta * RATE_STEP * 5)
  self:SetValue(newVal)
  ApplyRate(newVal)
end)

slider:SetScript("OnEnter", function(self)
  sliderBubble:Show()
  ShowTooltip(self, "Drag to set XP rate (0x - 2x)")
end)
slider:SetScript("OnLeave", function(self)
  sliderBubble:Hide()
  HideTooltip()
end)

local function ValidateAndApplyEditBox()
  local text = editbox:GetText()
  local val = tonumber(text)
  if val then
    local clamped = ClampRate(val)
    XPRate.UpdateUIFromValue(clamped, "editbox")
    ApplyRate(clamped)
  else
    XPRate.UpdateUIFromValue(slider:GetValue(), nil)
  end
end

editbox:SetScript("OnEditFocusGained", function(self)
  self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
end)

editbox:SetScript("OnEscapePressed", function(self)
  self.reverting = true
  local lastVal = XPRateControlDB and XPRateControlDB.lastRate or DEFAULT_RATE
  self:SetText(FormatRate(lastVal))
  XPRate.UpdateUIFromValue(lastVal, "editbox")
  self:ClearFocus()
end)

editbox:SetScript("OnEnterPressed", function(self)
  self:ClearFocus()
end)

editbox:SetScript("OnEditFocusLost", function(self)
  self:SetBackdropBorderColor(CLR.dim[1], CLR.dim[2], CLR.dim[3], 0.6)
  if self.reverting then
    self.reverting = nil
    return
  end
  ValidateAndApplyEditBox()
end)

editbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Type a value (0.00 - 2.00), press Enter")
end)
editbox:SetScript("OnLeave", HideTooltip)

-- Main Presets Row
local presets = {
  { val = 0.0, label = "0x" },
  { val = 0.5, label = "0.5x" },
  { val = 1.0, label = "1x" },
  { val = 1.5, label = "1.5x" },
  { val = 2.0, label = "2x" }
}

for i, p in ipairs(presets) do
  local btn = CreateFrame("Button", nil, RatesTabFrame)
  btn:SetSize(54, 22)
  btn:SetPoint("TOPLEFT", RatesTabFrame, "TOPLEFT", 12 + (i-1)*56, -164)

  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 1, right = 1, top = 1, bottom = 1 }
  })
  btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.85)
  btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)

  local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  highlight:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.05, 1, 1, 1, 0.1)
  highlight:SetBlendMode("ADD")

  local label = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  label:SetPoint("CENTER")
  label:SetText(p.label)
  label:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

  btn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
    self:SetBackdropBorderColor(CLR.white[1], CLR.white[2], CLR.white[3], 0.5)
    label:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    ShowTooltip(self, "Instantly set rate to " .. FormatRate(p.val) .. "x")
  end)

  btn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.85)
    local curVal = slider:GetValue()
    local isCurrent = (math.abs(curVal - p.val) < 0.005)
    if isCurrent then
      local rc = RateColor(p.val)
      self:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.8)
      label:SetTextColor(rc[1], rc[2], rc[3])
    else
      self:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
      label:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
    HideTooltip()
  end)

  btn:SetScript("OnClick", function()
    ApplyRate(p.val)
  end)

  tinsert(XPRate.ratesPresets, { btn = btn, val = p.val, label = label })
end
