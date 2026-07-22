-- Init.lua — Addon entrypoint, event dispatcher, and /xp slash commands for XPRateControl
local addonName, XPRate = ...

local RATE_MIN                    = XPRate.RATE_MIN or 0.1
local RATE_MAX                    = XPRate.RATE_MAX or 2.0
local DEFAULT_RATE                = XPRate.DEFAULT_RATE or 1.0
local PrintMessage                = XPRate.PrintMessage
local RateColor                  = XPRate.RateColor
local ApplyRate                  = XPRate.ApplyRate
local UpdateUIFromValue           = XPRate.UpdateUIFromValue
local UpdateJJUI                  = XPRate.UpdateJJUI
local EvaluateAutomation          = XPRate.EvaluateAutomation
local UpdateAutomationStatus      = XPRate.UpdateAutomationStatus
local UpdateMinimapButtonPosition = XPRate.UpdateMinimapButtonPosition
local SetActiveTab                = XPRate.SetActiveTab

local initFrame = CreateFrame("Frame", "XPRateEventFrame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
initFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
initFrame:RegisterEvent("ZONE_CHANGED")
initFrame:RegisterEvent("ZONE_CHANGED_INDOORS")
initFrame:RegisterEvent("PLAYER_LEVEL_UP")
initFrame:RegisterEvent("GROUP_ROSTER_UPDATE")
initFrame:RegisterEvent("PARTY_MEMBERS_CHANGED")
initFrame:RegisterEvent("RAID_ROSTER_UPDATE")
initFrame:RegisterEvent("PARTY_LEADER_CHANGED")
initFrame:RegisterEvent("UNIT_LEVEL")
initFrame:RegisterEvent("PLAYER_TARGET_CHANGED")
initFrame:RegisterEvent("QUEST_GREETING")
initFrame:RegisterEvent("QUEST_DETAIL")
initFrame:RegisterEvent("QUEST_PROGRESS")
initFrame:RegisterEvent("QUEST_COMPLETE")
initFrame:RegisterEvent("QUEST_FINISHED")
initFrame:RegisterEvent("UPDATE_EXHAUSTION")

initFrame:SetScript("OnEvent", function(self, event, arg1, ...)
  if event == "ADDON_LOADED" then
    if arg1 ~= addonName and arg1 ~= "XPRateControl" then return end

    local db = XPRate.InitDB()

    -- Window Position restoration
    if db.framePos and XPRate.frame then
      XPRate.frame:ClearAllPoints()
      XPRate.frame:SetPoint(db.framePos.point, UIParent, db.framePos.relativePoint, db.framePos.xOfs, db.framePos.yOfs)
    elseif XPRate.frame then
      XPRate.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if XPRate.UpdateUIFromValue then XPRate.UpdateUIFromValue(db.lastRate) end
    if XPRate.UpdateJJUI then XPRate.UpdateJJUI(db.jjEnabled) end
    if XPRate.UpdateTabRatesUI then XPRate.UpdateTabRatesUI() end

    -- Re-synchronize Automation UI State across all 6 sub-tabs
    if XPRate.UpdateAutomationTabUI then
      XPRate.UpdateAutomationTabUI()
    else
      if XPRate.restedCheckbox then XPRate.restedCheckbox:SetChecked(db.autoRested) end
      if XPRate.groupCheckbox then XPRate.groupCheckbox:SetChecked(db.autoGroup) end
      if XPRate.disparityCheckbox then XPRate.disparityCheckbox:SetChecked(db.autoDisparity) end
      if XPRate.mobCheckbox then XPRate.mobCheckbox:SetChecked(db.autoMob) end
      if XPRate.questCheckbox then XPRate.questCheckbox:SetChecked(db.autoQuest) end
      if XPRate.bracketCheckbox then XPRate.bracketCheckbox:SetChecked(db.autoBracket) end
      if XPRate.zoneCheckbox then XPRate.zoneCheckbox:SetChecked(db.autoZone) end

      if XPRate.updateRestedRow then XPRate.updateRestedRow() end
      if XPRate.updateNormalRow then XPRate.updateNormalRow() end
      if XPRate.updateGroupRow then XPRate.updateGroupRow() end
      if XPRate.updateMobRows then XPRate.updateMobRows() end
      if XPRate.updateQuestRow then XPRate.updateQuestRow() end
      if XPRate.UpdateAutomationStatus then XPRate.UpdateAutomationStatus() end
    end

    if XPRate.UpdateMinimapButtonPosition then XPRate.UpdateMinimapButtonPosition() end

    if db.lastRate and XPRateMinimapButtonBorder then
      local getColor = XPRate.RateColor or RateColor
      local rc = getColor and getColor(db.lastRate)
      if rc then
        XPRateMinimapButtonBorder:SetVertexColor(rc[1], rc[2], rc[3])
      end
    end

    -- Initial silent automation evaluation
    if db.autoRested or db.autoGroup or db.autoDisparity or db.autoMob or db.autoQuest or db.autoBracket or db.autoZone then
      local eval = XPRate.EvaluateAutomation or EvaluateAutomation
      if eval then
        eval(true, "Addon Init")
      end
    end

    if XPRate.minimapButton then
      if db.showMinimap then
        XPRate.minimapButton:Show()
      else
        XPRate.minimapButton:Hide()
      end
    end

    if XPRate.SetActiveTab then XPRate.SetActiveTab(1) end

    -- First load banner
    if db.firstRun then
      local printFn = XPRate.PrintMessage or PrintMessage
      if printFn then
        printFn("Welcome to XP Rate Control v1.2!")
        printFn("  - Click minimap hourglass icon to toggle settings panel.")
        printFn("  - Right-click minimap icon for quick rate adjustments.")
        printFn("  - Changes are applied instantly. Check out the expanded automation sub-tabs!")
      end
      db.firstRun = false
    else
      local printFn = XPRate.PrintMessage or PrintMessage
      if printFn then
        printFn("Loaded v1.2. Type |cff00ff00/xp|r to open, |cff00ff00/xp help|r for commands.")
      end
    end

  elseif event == "PLAYER_LOGIN" or event == "PLAYER_ENTERING_WORLD" then
    if XPRate.UpdateMinimapButtonPosition then XPRate.UpdateMinimapButtonPosition() end
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(true, event)
    end

  elseif event == "ZONE_CHANGED_NEW_AREA" or event == "ZONE_CHANGED" or event == "ZONE_CHANGED_INDOORS" then
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, event)
    end

  elseif event == "PLAYER_LEVEL_UP" then
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, "PLAYER_LEVEL_UP")
    end

  elseif event == "GROUP_ROSTER_UPDATE" or event == "PARTY_MEMBERS_CHANGED" or event == "RAID_ROSTER_UPDATE" or event == "PARTY_LEADER_CHANGED" then
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, event)
    end

  elseif event == "UNIT_LEVEL" then
    if not arg1 or string.find(arg1, "party") or string.find(arg1, "raid") or arg1 == "player" or arg1 == "target" then
      if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
      local eval = XPRate.EvaluateAutomation or EvaluateAutomation
      if eval then
        eval(false, "UNIT_LEVEL")
      end
    end

  elseif event == "PLAYER_TARGET_CHANGED" then
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, "PLAYER_TARGET_CHANGED")
    end

  elseif event == "QUEST_GREETING" or event == "QUEST_DETAIL" or event == "QUEST_PROGRESS" or event == "QUEST_COMPLETE" then
    XPRate.isQuestNPCActive = true
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, event)
    end

  elseif event == "QUEST_FINISHED" then
    XPRate.isQuestNPCActive = false
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, "QUEST_FINISHED")
    end

  elseif event == "UPDATE_EXHAUSTION" then
    if XPRate.UpdateAutomationTabUI then XPRate.UpdateAutomationTabUI() end
    local eval = XPRate.EvaluateAutomation or EvaluateAutomation
    if eval then
      eval(false, "UPDATE_EXHAUSTION")
    end
  end
end)

-- Slash Command Handler: /xp
SLASH_XPRATECONTROL1 = "/xp"
SlashCmdList["XPRATECONTROL"] = function(msg)
  msg = strtrim(msg or "")

  if msg == "" then
    if XPRate.frame then
      if XPRate.frame:IsShown() then
        XPRate.frame:Hide()
      else
        XPRate.frame:Show()
      end
    end
    return
  end

  local cmd, subArg = msg:match("^(%S+)%s*(.-)$")
  cmd = cmd and cmd:lower() or ""
  subArg = subArg and subArg:lower() or ""

  local db = XPRateControlDB
  if not db then
    db = XPRate.InitDB and XPRate.InitDB() or {}
  end

  local printFn = XPRate.PrintMessage or PrintMessage
  local eval = XPRate.EvaluateAutomation or EvaluateAutomation
  local updateUI = XPRate.UpdateAutomationTabUI

  local function getToggleState(currentVal, arg)
    if not arg or arg == "" then
      return not currentVal
    end
    if arg == "on" or arg == "1" or arg == "true" or arg == "enable" then
      return true
    elseif arg == "off" or arg == "0" or arg == "false" or arg == "disable" then
      return false
    else
      return not currentVal
    end
  end

  if cmd == "auto" then
    if subArg == "status" then
      if printFn then
        printFn("--- Automation Status Summary ---")
        printFn(string.format("  Rested: %s | Group: %s | Disparity: %s", 
          db.autoRested and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          db.autoGroup and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          db.autoDisparity and "|cff20cc50ON|r" or "|cffcc3535OFF|r"))
        printFn(string.format("  Mob: %s | Quest: %s | Bracket: %s | Zone: %s",
          db.autoMob and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          db.autoQuest and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          db.autoBracket and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          db.autoZone and "|cff20cc50ON|r" or "|cffcc3535OFF|r"))
        printFn(string.format("  Notifications: Chat (%s) | Toast (%s) | Quiet Auto (%s)", 
          (db.showChat ~= false) and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          (db.showToast ~= false) and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
          (db.quietAuto == true) and "|cff20cc50ON|r" or "|cffcc3535OFF|r"))
        if XPRate.lastAppliedRate then
          local formatFn = XPRate.FormatRate
          printFn(string.format("  Active Rate: |cff00ccff%s|rx via |cff00ff00%s|r", 
            formatFn and formatFn(XPRate.lastAppliedRate) or tostring(XPRate.lastAppliedRate),
            XPRate.lastAppliedMode or "Manual"))
        end
      end
      return
    end

    local newState
    if subArg == "on" or subArg == "1" or subArg == "true" or subArg == "enable" then
      newState = true
    elseif subArg == "off" or subArg == "0" or subArg == "false" or subArg == "disable" then
      newState = false
    else
      local isAnyActive = db.autoRested or db.autoGroup or db.autoDisparity or db.autoMob or db.autoQuest or db.autoBracket or db.autoZone
      newState = not isAnyActive
    end

    db.autoRested = newState
    db.autoGroup = newState
    db.autoDisparity = newState
    db.autoMob = newState
    db.autoQuest = newState
    db.autoBracket = newState
    db.autoZone = newState

    if printFn then
      printFn("All automation modules " .. (newState and "|cff20cc50enabled|r" or "|cffcc3535disabled|r") .. ".")
    end

    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Master Auto Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "zone" then
    db.autoZone = getToggleState(db.autoZone, subArg)
    if printFn then
      printFn("Zone XP auto-scaling " .. (db.autoZone and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Zone Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "bracket" then
    db.autoBracket = getToggleState(db.autoBracket, subArg)
    if printFn then
      printFn("Level Bracket XP auto-scaling " .. (db.autoBracket and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Bracket Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "disparity" then
    db.autoDisparity = getToggleState(db.autoDisparity, subArg)
    if printFn then
      printFn("Party Level Disparity protection " .. (db.autoDisparity and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Disparity Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "group" then
    db.autoGroup = getToggleState(db.autoGroup, subArg)
    if XPRate.groupCheckbox then XPRate.groupCheckbox:SetChecked(db.autoGroup) end
    if printFn then
      printFn("Party XP auto-scaling " .. (db.autoGroup and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Group Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "mob" then
    db.autoMob = getToggleState(db.autoMob, subArg)
    if printFn then
      printFn("Mob Difficulty XP auto-scaling " .. (db.autoMob and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Mob Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "quest" then
    db.autoQuest = getToggleState(db.autoQuest, subArg)
    if printFn then
      printFn("Quest Interaction XP scaling " .. (db.autoQuest and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Quest Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "rested" then
    db.autoRested = getToggleState(db.autoRested, subArg)
    if printFn then
      printFn("Rested XP auto-scaling " .. (db.autoRested and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    XPRate.lastAppliedRate = nil
    XPRate.lastAppliedMode = nil
    if eval then eval(false, "Slash Cmd Rested Toggle") end
    if updateUI then updateUI() end
    return
  end

  if cmd == "chat" then
    db.showChat = getToggleState(db.showChat, subArg)
    if printFn then
      printFn("Chat notifications " .. (db.showChat and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    if XPRate.UpdateTabRatesUI then XPRate.UpdateTabRatesUI() end
    return
  end

  if cmd == "toast" then
    db.showToast = getToggleState(db.showToast, subArg)
    if printFn then
      printFn("Toast notifications " .. (db.showToast and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    if XPRate.UpdateTabRatesUI then XPRate.UpdateTabRatesUI() end
    return
  end

  if cmd == "quiet" then
    db.quietAuto = getToggleState(db.quietAuto, subArg)
    if printFn then
      printFn("Quiet automation " .. (db.quietAuto and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
    end
    if XPRate.UpdateTabRatesUI then XPRate.UpdateTabRatesUI() end
    return
  end

  if cmd == "status" then
    if printFn then
      printFn("--- Automation Status Summary ---")
      printFn(string.format("  Rested: %s | Group: %s | Disparity: %s", 
        db.autoRested and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        db.autoGroup and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        db.autoDisparity and "|cff20cc50ON|r" or "|cffcc3535OFF|r"))
      printFn(string.format("  Mob: %s | Quest: %s | Bracket: %s | Zone: %s",
        db.autoMob and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        db.autoQuest and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        db.autoBracket and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        db.autoZone and "|cff20cc50ON|r" or "|cffcc3535OFF|r"))
      printFn(string.format("  Notifications: Chat (%s) | Toast (%s) | Quiet Auto (%s)", 
        (db.showChat ~= false) and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        (db.showToast ~= false) and "|cff20cc50ON|r" or "|cffcc3535OFF|r",
        (db.quietAuto == true) and "|cff20cc50ON|r" or "|cffcc3535OFF|r"))
      if XPRate.lastAppliedRate then
        local formatFn = XPRate.FormatRate
        printFn(string.format("  Active Rate: |cff00ccff%s|rx via |cff00ff00%s|r", 
          formatFn and formatFn(XPRate.lastAppliedRate) or tostring(XPRate.lastAppliedRate),
          XPRate.lastAppliedMode or "Manual"))
      end
    end
    return
  end

  if cmd == "minimap" then
    db.showMinimap = not db.showMinimap
    if XPRate.minimapButton then
      if db.showMinimap then
        XPRate.minimapButton:Show()
        if printFn then printFn("Minimap button shown.") end
      else
        XPRate.minimapButton:Hide()
        if printFn then printFn("Minimap button hidden.") end
      end
    end
    return
  end

  if cmd == "help" then
    if printFn then
      printFn("Commands:")
      printFn("  |cff00ff00/xp|r - Toggle main panel visibility")
      printFn("  |cff00ff00/xp <0-2>|r - Set XP rate (e.g. /xp 1.25)")
      printFn("  |cff00ff00/xp auto [status|on|off]|r - Master automation toggle or status")
      printFn("  |cff00ff00/xp zone [on|off]|r - Toggle zone auto-scaling")
      printFn("  |cff00ff00/xp bracket [on|off]|r - Toggle level bracket auto-scaling")
      printFn("  |cff00ff00/xp disparity [on|off]|r - Toggle party level disparity protection")
      printFn("  |cff00ff00/xp group [on|off]|r - Toggle party size auto-scaling")
      printFn("  |cff00ff00/xp mob [on|off]|r - Toggle mob difficulty auto-scaling")
      printFn("  |cff00ff00/xp quest [on|off]|r - Toggle quest interaction scaling")
      printFn("  |cff00ff00/xp rested [on|off]|r - Toggle rested XP auto-scaling")
      printFn("  |cff00ff00/xp chat [on|off]|r - Toggle chat message notifications")
      printFn("  |cff00ff00/xp toast [on|off]|r - Toggle toast alert notifications")
      printFn("  |cff00ff00/xp quiet [on|off]|r - Toggle quiet automation mode")
      printFn("  |cff00ff00/xp minimap|r - Toggle minimap button visibility")
      printFn("  |cff00ff00/xp status|r - Display automation status summary")
    end
    return
  end

  local val = tonumber(msg)
  if not val then
    if printFn then printFn("Invalid command or rate value. Type |cff00ff00/xp help|r for usage.") end
    return
  end

  local minRate = XPRate.RATE_MIN or 0.1
  local maxRate = XPRate.RATE_MAX or 2.0
  if val < minRate or val > maxRate then
    if printFn then printFn("Rate must be between " .. minRate .. " and " .. maxRate .. ".") end
    return
  end

  local applyFn = XPRate.ApplyRate or ApplyRate
  if applyFn then applyFn(val) end
end
