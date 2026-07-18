-- UI/TabBuffs.lua — Tab 3 Buffs UI (Joyous Journeys 50% XP buff toggle) for XPRateControl
local addonName, XPRate = ...

local CLR                 = XPRate.CLR
local PrintMessage        = XPRate.PrintMessage
local SendJJCommand       = XPRate.SendJJCommand
local ShowTooltip          = XPRate.ShowTooltip
local HideTooltip          = XPRate.HideTooltip
local ShowToast            = XPRate.ShowToast
local CreateSectionHeader  = XPRate.CreateSectionHeader

local BuffsTabFrame = XPRate.BuffsTabFrame

CreateSectionHeader(BuffsTabFrame, "JOYOUS JOURNEYS", "Interface\\AddOns\\XPRateControl\\Textures\\Icon_Buffs", CLR.gold)

local jjDesc = BuffsTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
jjDesc:SetPoint("TOPLEFT", BuffsTabFrame, "TOPLEFT", 12, -30)
jjDesc:SetText("50% XP buff for characters below max level")
jjDesc:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

-- Visual Card Hero
local jjCard = CreateFrame("Frame", nil, BuffsTabFrame)
jjCard:SetSize(288, 80)
jjCard:SetPoint("TOP", BuffsTabFrame, "TOP", 0, -48)
jjCard:SetBackdrop({
  bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
  edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
  tile = true, tileSize = 10, edgeSize = 10,
  insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
jjCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
jjCard:SetBackdropBorderColor(CLR.cardEdge[1], CLR.cardEdge[2], CLR.cardEdge[3], 0.6)

local jjIcon = jjCard:CreateTexture(nil, "ARTWORK")
jjIcon:SetSize(36, 36)
jjIcon:SetPoint("CENTER", jjCard, "CENTER", 0, 10)
jjIcon:SetTexture("Interface\\AddOns\\XPRateControl\\Textures\\Icon_Buffs")

local jjStatusText = jjCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
jjStatusText:SetPoint("TOP", jjIcon, "BOTTOM", 0, -6)
jjStatusText:SetText("BUFF INACTIVE")

local jjCheckbox = CreateFrame("CheckButton", "XPRateJJCheckbox", BuffsTabFrame, "UICheckButtonTemplate")
XPRate.jjCheckbox = jjCheckbox
jjCheckbox:SetSize(22, 22)
jjCheckbox:SetPoint("TOPLEFT", jjCard, "BOTTOMLEFT", 4, -10)

local jjCheckLabel = BuffsTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
jjCheckLabel:SetPoint("LEFT", jjCheckbox, "RIGHT", 6, 0)
jjCheckLabel:SetText("Enable Joyous Journeys Buff")
jjCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

function XPRate.UpdateJJUI(enabled)
  jjCheckbox:SetChecked(enabled)
  if enabled then
    jjIcon:SetDesaturated(false)
    jjIcon:SetAlpha(1.0)
    jjCard:SetBackdropBorderColor(CLR.gold[1], CLR.gold[2], CLR.gold[3], 0.8)
    jjStatusText:SetText("BUFF ACTIVE")
    jjStatusText:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3])
  else
    jjIcon:SetDesaturated(true)
    jjIcon:SetAlpha(0.4)
    jjCard:SetBackdropBorderColor(CLR.cardEdge[1], CLR.cardEdge[2], CLR.cardEdge[3], 0.6)
    jjStatusText:SetText("BUFF INACTIVE")
    jjStatusText:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
  end
end

jjCheckbox:SetScript("OnClick", function(self)
  local enabled = self:GetChecked() and true or false
  SendJJCommand(enabled)
  if XPRateControlDB then
    XPRateControlDB.jjEnabled = enabled
  end
  XPRate.UpdateJJUI(enabled)
  ShowToast(enabled and "JJ Enabled [OK]" or "JJ Disabled [OK]", false)
  PrintMessage("Joyous Journeys " .. (enabled and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
end)

jjCheckbox:SetScript("OnEnter", function(self)
  ShowTooltip(self, "Toggle the Joyous Journeys 50% XP buff on the server")
end)
jjCheckbox:SetScript("OnLeave", HideTooltip)
