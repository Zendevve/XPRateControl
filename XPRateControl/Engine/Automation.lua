-- Engine/Automation.lua — Automation evaluator and backend listeners for XPRateControl
local addonName, XPRate = ...

local CLR           = XPRate.CLR
local PrintMessage  = XPRate.PrintMessage
local FormatRate    = XPRate.FormatRate
local ClampRate     = XPRate.ClampRate
local ApplyRate     = XPRate.ApplyRate
local MakeButton    = XPRate.MakeButton
local ShowToast     = XPRate.ShowToast
local ShowTooltip   = XPRate.ShowTooltip
local HideTooltip   = XPRate.HideTooltip

XPRate.lastAppliedRate = nil
XPRate.lastAppliedMode = nil
XPRate.isQuestNPCActive = false

-- Group size calculator
function XPRate.GetCurrentGroupSize()
  local numRaid = GetNumRaidMembers and GetNumRaidMembers() or 0
  if numRaid and numRaid > 0 then
    return numRaid
  end
  local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
  if numParty and numParty > 0 then
    return numParty + 1
  end
  return 1
end

-- Current zone type resolver ("dungeon", "raid", "pvp", "world")
function XPRate.GetCurrentZoneType()
  if not IsInInstance then return "world", "Open World" end
  local inInstance, instanceType = IsInInstance()
  if not inInstance or not instanceType or instanceType == "none" then
    return "world", "Open World"
  elseif instanceType == "party" then
    return "dungeon", "Dungeon"
  elseif instanceType == "raid" then
    return "raid", "Raid"
  elseif instanceType == "pvp" or instanceType == "arena" then
    return "pvp", "Battleground / Arena"
  end
  return "world", "Open World"
end
XPRate.GetZoneCategory = XPRate.GetCurrentZoneType

-- Level bracket matcher against db.bracketRates
function XPRate.GetMatchingLevelBracket(level)
  level = level or (UnitLevel and UnitLevel("player")) or 1
  if type(level) ~= "number" then
    level = tonumber(level) or 1
  end
  local db = XPRateControlDB
  if not db or type(db.bracketRates) ~= "table" then return nil end

  for i, bracket in ipairs(db.bracketRates) do
    if type(bracket) == "table" and bracket.min and bracket.max then
      local bMin = tonumber(bracket.min) or 1
      local bMax = tonumber(bracket.max) or 80
      if level >= bMin and level <= bMax then
        return bracket, i
      end
    end
  end
  return nil
end

-- Max party level disparity calculator
function XPRate.GetMaxPartyLevelDisparity()
  local gSize = XPRate.GetCurrentGroupSize()
  local playerLevel = (UnitLevel and UnitLevel("player")) or 1
  if gSize <= 1 then return 0, playerLevel, playerLevel end

  local minLevel = playerLevel
  local maxLevel = playerLevel

  local numRaid = GetNumRaidMembers and GetNumRaidMembers() or 0
  if numRaid and numRaid > 0 then
    for i = 1, numRaid do
      local unit = "raid" .. i
      if UnitExists and UnitExists(unit) and (not UnitIsConnected or UnitIsConnected(unit)) then
        local lvl = UnitLevel(unit)
        if lvl and lvl > 0 then
          if lvl < minLevel then minLevel = lvl end
          if lvl > maxLevel then maxLevel = lvl end
        end
      end
    end
  else
    local numParty = GetNumPartyMembers and GetNumPartyMembers() or 0
    if numParty and numParty > 0 then
      for i = 1, numParty do
        local unit = "party" .. i
        if UnitExists and UnitExists(unit) and (not UnitIsConnected or UnitIsConnected(unit)) then
          local lvl = UnitLevel(unit)
          if lvl and lvl > 0 then
            if lvl < minLevel then minLevel = lvl end
            if lvl > maxLevel then maxLevel = lvl end
          end
        end
      end
    end
  end

  return maxLevel - minLevel, minLevel, maxLevel
end
XPRate.GetPartyLevelDisparity = XPRate.GetMaxPartyLevelDisparity

-- Difficulty category resolver (Gray, Green, Yellow, Orange/Red) for target unit
function XPRate.GetUnitDifficultyCategory(unit)
  unit = unit or "target"
  if not UnitExists or not UnitExists(unit) or not UnitCanAttack or not UnitCanAttack("player", unit) or (UnitIsDead and UnitIsDead(unit)) or (UnitIsPlayer and UnitIsPlayer(unit)) then
    return nil
  end

  local mobLevel = UnitLevel(unit)
  local playerLevel = UnitLevel("player")
  if not mobLevel or not playerLevel then return nil end

  if mobLevel <= 0 or (mobLevel - playerLevel) >= 3 then
    return "red", "Orange / Red"
  elseif (mobLevel - playerLevel) >= -2 and (mobLevel - playerLevel) <= 2 then
    return "yellow", "Yellow"
  else
    local color = GetQuestDifficultyColor and GetQuestDifficultyColor(mobLevel)
    if QuestDifficultyColors and color == QuestDifficultyColors["green"] then
      return "green", "Green"
    elseif QuestDifficultyColors and (color == QuestDifficultyColors["trivial"] or color == QuestDifficultyColors["header"]) then
      return "gray", "Gray"
    else
      local grayThreshold = 0
      if playerLevel <= 5 then grayThreshold = 0
      elseif playerLevel <= 9 then grayThreshold = playerLevel - 5
      elseif playerLevel <= 11 then grayThreshold = playerLevel - 6
      elseif playerLevel <= 19 then grayThreshold = playerLevel - 7
      elseif playerLevel <= 29 then grayThreshold = playerLevel - 8
      elseif playerLevel <= 39 then grayThreshold = playerLevel - 9
      elseif playerLevel <= 49 then grayThreshold = playerLevel - 11
      elseif playerLevel <= 59 then grayThreshold = playerLevel - 12
      elseif playerLevel <= 69 then grayThreshold = playerLevel - 13
      else grayThreshold = playerLevel - 14
      end

      if mobLevel <= grayThreshold then
        return "gray", "Gray"
      else
        return "green", "Green"
      end
    end
  end
end

-- Priority Evaluator: strict hierarchy (Quest > Zone > Bracket > Mob > Party Disparity/Scaling > Rested)
function XPRate.EvaluateAutomation(silent, reason)
  local db = XPRateControlDB
  if not db then return end

  local effectiveSilent = silent or (db and db.quietAuto == true)

  local gSize = XPRate.GetCurrentGroupSize()
  local isRested = (GetXPExhaustion and GetXPExhaustion() and GetXPExhaustion() > 0) or false
  local mobCategory, mobLabel = XPRate.GetUnitDifficultyCategory("target")
  local playerLevel = (UnitLevel and UnitLevel("player")) or 1

  local targetRate = nil
  local activeMode = nil

  -- 1. Quest Interaction
  if db.autoQuest and XPRate.isQuestNPCActive then
    targetRate = db.questRate or 2.00
    activeMode = "Quest Interaction"

  -- 2. Zone / Instance Type
  elseif db.autoZone and db.zoneRates and db.zoneRates[XPRate.GetCurrentZoneType()] ~= nil then
    local zoneCat, zoneLabel = XPRate.GetCurrentZoneType()
    targetRate = db.zoneRates[zoneCat]
    activeMode = "Zone (" .. zoneLabel .. ")"

  -- 3. Level Brackets
  elseif db.autoBracket and XPRate.GetMatchingLevelBracket(playerLevel) and XPRate.GetMatchingLevelBracket(playerLevel).rate ~= nil then
    local bracket = XPRate.GetMatchingLevelBracket(playerLevel)
    targetRate = bracket.rate
    activeMode = string.format("Level Bracket (%d-%d)", bracket.min or 1, bracket.max or 80)

  -- 4. Mob Difficulty
  elseif db.autoMob and mobCategory and db.mobRates and db.mobRates[mobCategory] ~= nil then
    targetRate = db.mobRates[mobCategory]
    activeMode = "Mob Difficulty (" .. mobLabel .. ")"

  -- 5. Party Scaling / Disparity
  elseif db.autoDisparity and gSize > 1 and XPRate.GetMaxPartyLevelDisparity() > (db.disparityThreshold or 5) then
    targetRate = db.disparityRate or 0.50
    activeMode = string.format("Party Disparity (>%d Levels)", db.disparityThreshold or 5)

  elseif db.autoGroup then
    if gSize > 1 then
      local mappedSize = math.min(gSize, 5)
      targetRate = (db.groupRates and db.groupRates[mappedSize]) or 1.00
      local stateText = (gSize >= 5) and "5P Group" or (gSize .. "P Group")
      activeMode = "Party Scaling (" .. stateText .. ")"
    else
      targetRate = (db.groupRates and db.groupRates[1]) or 1.00
      activeMode = "Party Scaling (Solo)"
    end

  -- 6. Rested XP
  elseif db.autoRested then
    targetRate = isRested and db.restedRate or db.normalRate
    local stateStr = isRested and "Rested" or "Normal"
    activeMode = "Auto Rested (" .. stateStr .. ")"
  end

  if targetRate then
    local rateChanged = (XPRate.lastAppliedRate == nil or math.abs(targetRate - XPRate.lastAppliedRate) > 0.005 or activeMode ~= XPRate.lastAppliedMode)
    if rateChanged then
      XPRate.lastAppliedRate = targetRate
      XPRate.lastAppliedMode = activeMode

      ApplyRate(targetRate, effectiveSilent)

      if not effectiveSilent then
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
  local isRested = (GetXPExhaustion and GetXPExhaustion() and GetXPExhaustion() > 0) or false

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

  if XPRate.disparityStateValue then
    local disparity = XPRate.GetMaxPartyLevelDisparity()
    local threshold = db.disparityThreshold or 5
    if gSize <= 1 then
      XPRate.disparityStateValue:SetText("Solo (No Party Members)")
      XPRate.disparityStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    elseif disparity > threshold then
      XPRate.disparityStateValue:SetText(string.format("Disparity Triggered: %d Lvs Gap (>%d Threshold)", disparity, threshold))
      XPRate.disparityStateValue:SetTextColor(CLR.red[1], CLR.red[2], CLR.red[3])
    else
      XPRate.disparityStateValue:SetText(string.format("Party Gap: %d Lvs (Threshold: %d Lvs)", disparity, threshold))
      XPRate.disparityStateValue:SetTextColor(CLR.green[1], CLR.green[2], CLR.green[3])
    end
  end

  if XPRate.mobStateValue then
    local mobCategory, mobLabel = XPRate.GetUnitDifficultyCategory("target")
    if mobCategory then
      local rate = db.mobRates and db.mobRates[mobCategory] or 1.0
      XPRate.mobStateValue:SetText("Target: " .. mobLabel .. " (" .. FormatRate(rate) .. "x)")
      if mobCategory == "red" then XPRate.mobStateValue:SetTextColor(CLR.red[1], CLR.red[2], CLR.red[3])
      elseif mobCategory == "yellow" then XPRate.mobStateValue:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3])
      elseif mobCategory == "green" then XPRate.mobStateValue:SetTextColor(CLR.green[1], CLR.green[2], CLR.green[3])
      else XPRate.mobStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
      end
    else
      XPRate.mobStateValue:SetText("Target: None / Non-Enemy")
      XPRate.mobStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end

  if XPRate.questStateValue then
    if XPRate.isQuestNPCActive and db.autoQuest then
      XPRate.questStateValue:SetText("Quest NPC Active (" .. FormatRate(db.questRate or 2.0) .. "x)")
      XPRate.questStateValue:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3])
    elseif XPRate.isQuestNPCActive then
      XPRate.questStateValue:SetText("Quest NPC Active (Auto OFF)")
      XPRate.questStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    else
      XPRate.questStateValue:SetText("Quest Window Closed")
      XPRate.questStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end

  if XPRate.zoneStateValue then
    local zoneCat, zoneLabel = XPRate.GetCurrentZoneType()
    local rate = db.zoneRates and db.zoneRates[zoneCat] or 1.00
    if db.autoZone then
      XPRate.zoneStateValue:SetText(string.format("Zone: %s (%sx)", zoneLabel, FormatRate(rate)))
      XPRate.zoneStateValue:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])
    else
      XPRate.zoneStateValue:SetText(string.format("Zone: %s (Auto OFF)", zoneLabel))
      XPRate.zoneStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end
  end

  if XPRate.bracketStateValue then
    local playerLevel = (UnitLevel and UnitLevel("player")) or 1
    local bracket = XPRate.GetMatchingLevelBracket(playerLevel)
    if bracket then
      if db.autoBracket then
        XPRate.bracketStateValue:SetText(string.format("Bracket: Lv %d-%d (%sx)", bracket.min or 1, bracket.max or 80, FormatRate(bracket.rate or 1.0)))
        XPRate.bracketStateValue:SetTextColor(CLR.green[1], CLR.green[2], CLR.green[3])
      else
        XPRate.bracketStateValue:SetText(string.format("Bracket: Lv %d-%d (Auto OFF)", bracket.min or 1, bracket.max or 80))
        XPRate.bracketStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
      end
    else
      XPRate.bracketStateValue:SetText("Bracket: Out of Range")
      XPRate.bracketStateValue:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
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

  -- Numeric EditBox for custom rate input
  local editbox = CreateFrame("EditBox", nil, parent)
  editbox:SetSize(52, 20)
  editbox:SetPoint("TOPLEFT", parent, "TOPLEFT", 240, yOfs - 16)
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

    if not editbox:HasFocus() then
      editbox:SetText(FormatRate(currentVal))
    end
  end

  for i = 1, 5 do
    local btn = MakeButton(parent, 42, 20, CLR.btnBg, CLR.btnEdge)
    btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + (i-1)*45, yOfs - 16)
    btn:SetBackdrop({
      bgFile   = "Interface\\ChatFrame\\ChatFrameBackground",
      edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
      tile = true, tileSize = 8, edgeSize = 8,
      insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })

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

  local function validateAndApplyEditBox()
    local text = editbox:GetText()
    local val = tonumber(text)
    if val then
      local clamped = ClampRate(val)
      onClickCallback(clamped)
    end
    updateSelection()
  end

  editbox:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
  end)

  editbox:SetScript("OnEscapePressed", function(self)
    self.reverting = true
    self:ClearFocus()
    updateSelection()
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
    validateAndApplyEditBox()
  end)

  editbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Type a rate (0.00 - 2.00), press Enter")
  end)
  editbox:SetScript("OnLeave", HideTooltip)

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
groupBackendFrame:RegisterEvent("UNIT_LEVEL")
groupBackendFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
groupBackendFrame:SetScript("OnEvent", function(self, event, unit)
  if event == "UNIT_LEVEL" and unit and unit ~= "player" and not string.find(unit, "party") and not string.find(unit, "raid") then
    return
  end
  XPRate.EvaluateAutomation(event == "PLAYER_ENTERING_WORLD", event)
end)

local mobBackendFrame = CreateFrame("Frame")
mobBackendFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
mobBackendFrame:SetScript("OnEvent", function(self, event)
  XPRate.EvaluateAutomation(false, event)
end)

local questBackendFrame = CreateFrame("Frame")
questBackendFrame:RegisterEvent("QUEST_GREETING")
questBackendFrame:RegisterEvent("QUEST_DETAIL")
questBackendFrame:RegisterEvent("QUEST_PROGRESS")
questBackendFrame:RegisterEvent("QUEST_COMPLETE")
questBackendFrame:RegisterEvent("QUEST_FINISHED")
questBackendFrame:SetScript("OnEvent", function(self, event)
  if event == "QUEST_FINISHED" then
    XPRate.isQuestNPCActive = false
    XPRate.EvaluateAutomation(false, "Quest Window Closed")
  else
    XPRate.isQuestNPCActive = true
    XPRate.EvaluateAutomation(false, "Quest Window Opened")
  end
end)

local zoneBackendFrame = CreateFrame("Frame")
zoneBackendFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
zoneBackendFrame:RegisterEvent("ZONE_CHANGED")
zoneBackendFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
zoneBackendFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
zoneBackendFrame:SetScript("OnEvent", function(self, event)
  XPRate.EvaluateAutomation(event == "PLAYER_ENTERING_WORLD", event)
end)

local bracketBackendFrame = CreateFrame("Frame")
bracketBackendFrame:RegisterEvent("PLAYER_LEVEL_UP")
bracketBackendFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
bracketBackendFrame:SetScript("OnEvent", function(self, event)
  XPRate.EvaluateAutomation(event == "PLAYER_ENTERING_WORLD", event)
end)
