-- Engine/Automation.lua — Automation evaluator and backend listeners for XPRateControl
local addonName, XPRate = ...

local CLR           = XPRate.CLR
local PrintMessage  = XPRate.PrintMessage
local FormatRate    = XPRate.FormatRate
local ClampRate     = XPRate.ClampRate
local ApplyRate     = XPRate.ApplyRate
local MakeButton    = XPRate.MakeButton
local ShowToast     = XPRate.ShowToast

XPRate.lastAppliedRate = nil
XPRate.lastAppliedMode = nil

-- Group size calculator
function XPRate.GetCurrentGroupSize()
  local numRaid = GetNumRaidMembers()
  if numRaid and numRaid > 0 then
    return numRaid
  end
  local numParty = GetNumPartyMembers()
  if numParty and numParty > 0 then
    return numParty + 1
  end
  return 1
end

-- Evaluates auto-rested and party auto-scaling state
function XPRate.EvaluateAutomation(silent, reason)
  local db = XPRateControlDB
  if not db then return end

  local gSize = XPRate.GetCurrentGroupSize()
  local isRested = (GetXPExhaustion() and GetXPExhaustion() > 0) or false

  local targetRate = nil
  local activeMode = nil

  if gSize > 1 and db.autoGroup then
    local mappedSize = math.min(gSize, 5)
    targetRate = (db.groupRates and db.groupRates[mappedSize]) or 1.00
    local stateText = (gSize >= 5) and "5P Group" or (gSize .. "P Group")
    activeMode = "Party Scaling (" .. stateText .. ")"
  elseif db.autoRested then
    targetRate = isRested and db.restedRate or db.normalRate
    local stateStr = isRested and "Rested" or "Normal"
    activeMode = "Auto Rested (" .. stateStr .. ")"
  elseif db.autoGroup then
    targetRate = (db.groupRates and db.groupRates[1]) or 1.00
    activeMode = "Party Scaling (Solo)"
  end

  if targetRate then
    local rateChanged = (XPRate.lastAppliedRate == nil or math.abs(targetRate - XPRate.lastAppliedRate) > 0.005 or activeMode ~= XPRate.lastAppliedMode)
    if rateChanged then
      XPRate.lastAppliedRate = targetRate
      XPRate.lastAppliedMode = activeMode

      ApplyRate(targetRate, silent)

      if not silent then
        if XPRate.FlashMinimapButton then XPRate.FlashMinimapButton(targetRate) end
        local causeMsg = reason and (" [" .. reason .. "]") or ""
        PrintMessage("|cff00ff00Auto-Switched|r -> " .. FormatRate(targetRate) .. "x via |cff00ccff" .. activeMode .. "|r" .. causeMsg)
        ShowToast(string.format("Auto (%s) -> %sx", activeMode, FormatRate(targetRate)), false)
      end
    end
  end

  XPRate.UpdateAutomationStatus()
end

-- Updates status strings in the Automation tab UI
function XPRate.UpdateAutomationStatus()
  local db = XPRateControlDB
  if not db then return end

  local gSize = XPRate.GetCurrentGroupSize()
  local isRested = (GetXPExhaustion() and GetXPExhaustion() > 0) or false

  if XPRate.restedStateValue then
    if isRested then
      XPRate.restedStateValue:SetText("Rested XP Active")
      XPRate.restedStateValue:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])
    else
      XPRate.restedStateValue:SetText("Normal (No Rested)")
      XPRate.restedStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end

  if XPRate.groupStateValue then
    if gSize > 1 then
      local label = (gSize >= 5) and "5 Players (Max)" or (gSize .. " Players")
      XPRate.groupStateValue:SetText("Party: " .. label)
      XPRate.groupStateValue:SetTextColor(CLR.green[1], CLR.green[2], CLR.green[3])
    else
      XPRate.groupStateValue:SetText("Solo (1 Player)")
      XPRate.groupStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end

  if XPRate.UpdatePartyButtonsUI then
    XPRate.UpdatePartyButtonsUI()
  end
end

-- Helper for creating preset rows in Auto-Rested / Auto-Group subtabs
function XPRate.CreateRestedPresetRow(parent, labelText, yOfs, onClickCallback, getValCallback)
  local rowLabel = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
  rowLabel:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOfs)
  rowLabel:SetText(labelText)
  rowLabel:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

  local presetVals = { 0, 0.5, 1.0, 1.5, 2.0 }
  local presetLabels = { "0x", "0.5x", "1x", "1.5x", "2x" }
  local btns = {}

  local function updateSelection()
    local currentVal = getValCallback()
    for i, btn in ipairs(btns) do
      if math.abs(presetVals[i] - currentVal) < 0.005 then
        btn:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
        btn:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.95)
        btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
      else
        btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
        btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
        btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
      end
    end
  end

  for i = 1, 5 do
    local btn = MakeButton(parent, 54, 20, CLR.btnBg, CLR.btnEdge)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + (i-1)*56, yOfs - 16)

    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("CENTER")
    text:SetText(presetLabels[i])
    text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    btn.text = text

    local val = presetVals[i]
    btn:SetScript("OnClick", function()
      onClickCallback(val)
      updateSelection()
    end)

    btn:SetScript("OnEnter", function(self)
      if math.abs(presetVals[i] - getValCallback()) >= 0.005 then
        self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
      end
    end)
    btn:SetScript("OnLeave", function(self)
      updateSelection()
    end)

    btns[i] = btn
  end

  updateSelection()
  return updateSelection
end

-- Backend listener frames
local restedBackendFrame = CreateFrame("Frame")
restedBackendFrame:RegisterEvent("UPDATE_EXHAUSTION")
restedBackendFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
restedBackendFrame:SetScript("OnEvent", function(self, event)
  XPRate.EvaluateAutomation(event == "PLAYER_ENTERING_WORLD", event)
end)

local groupBackendFrame = CreateFrame("Frame")
groupBackendFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
groupBackendFrame:RegisterEvent("RAID_ROSTER_UPDATE")
groupBackendFrame:RegisterEvent("PARTY_LEADER_CHANGED")
groupBackendFrame:SetScript("OnEvent", function(self, event)
  XPRate.EvaluateAutomation(false, event)
end)
