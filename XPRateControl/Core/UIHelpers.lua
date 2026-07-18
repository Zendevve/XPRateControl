-- Core/UIHelpers.lua — Widget generators, tooltips, and toast frame for XPRateControl
local addonName, XPRate = ...

local CLR = XPRate.CLR

-- Tooltip helpers
function XPRate.ShowTooltip(owner, text)
  GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
  GameTooltip:SetText(text, nil, nil, nil, nil, true)
  GameTooltip:Show()
end

function XPRate.HideTooltip()
  GameTooltip:Hide()
end

-- Custom backdrop button generator
function XPRate.MakeButton(parent, width, height, bgColor, edgeColor)
  local btn = CreateFrame("Button", nil, parent)
  btn:SetSize(width, height)
  btn:SetBackdrop({
    bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
  })
  btn:SetBackdropColor(bgColor[1], bgColor[2], bgColor[3], 0.95)
  btn:SetBackdropBorderColor(edgeColor[1], edgeColor[2], edgeColor[3], 0.9)

  local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
  highlight:SetAllPoints()
  highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  highlight:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.06, 1, 1, 1, 0.12)
  highlight:SetBlendMode("ADD")

  return btn
end

-- Toast popup notification system
local toast = CreateFrame("Frame", "XPRateToastFrame", UIParent)
XPRate.toast = toast
toast:SetSize(220, 32)
toast:SetPoint("TOP", UIParent, "TOP", 0, -120)
toast:SetFrameStrata("TOOLTIP")
toast:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 12, edgeSize = 12,
  insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
toast:Hide()

local toastText = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toastText:SetPoint("CENTER")

local toastTimer = 0

function XPRate.ShowToast(text, isError)
  toastText:SetText(text)
  if isError then
    toast:SetBackdropColor(0.15, 0.02, 0.02, 0.95)
    toast:SetBackdropBorderColor(0.8, 0.2, 0.2, 0.8)
    toastText:SetTextColor(1, 0.3, 0.3)
  else
    toast:SetBackdropColor(0.02, 0.08, 0.05, 0.95)
    toast:SetBackdropBorderColor(0.2, 0.8, 0.4, 0.8)
    toastText:SetTextColor(0.4, 1, 0.6)
  end
  toast:SetAlpha(1)
  toast:Show()
  toastTimer = 2.0
end

local toastUpdater = CreateFrame("Frame", nil, toast)
toastUpdater:SetScript("OnUpdate", function(self, elapsed)
  if toastTimer > 0 then
    toastTimer = toastTimer - elapsed
    if toastTimer <= 0 then
      toast:Hide()
    elseif toastTimer < 0.5 then
      toast:SetAlpha(toastTimer / 0.5)
    end
  end
end)

-- Section header builder
function XPRate.CreateSectionHeader(parent, name, iconPath, accentColor)
  local stripe = parent:CreateTexture(nil, "ARTWORK")
  stripe:SetSize(4, 18)
  stripe:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -6)
  stripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
  stripe:SetVertexColor(accentColor[1], accentColor[2], accentColor[3])

  local icon = parent:CreateTexture(nil, "ARTWORK")
  icon:SetSize(18, 18)
  icon:SetPoint("LEFT", stripe, "RIGHT", 6, 0)
  icon:SetTexture(iconPath)

  local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
  text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
  text:SetText(name)
  text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

  return stripe
end
