-- Init.lua — Addon entrypoint, event dispatcher, and /xp slash commands for XPRateControl
local addonName, XPRate = ...

local RATE_MIN                    = XPRate.RATE_MIN
local RATE_MAX                    = XPRate.RATE_MAX
local DEFAULT_RATE                = XPRate.DEFAULT_RATE
local PrintMessage                = XPRate.PrintMessage
local RateColor                  = XPRate.RateColor
local ApplyRate                  = XPRate.ApplyRate
local UpdateUIFromValue           = XPRate.UpdateUIFromValue
local UpdateJJUI                  = XPRate.UpdateJJUI
local EvaluateAutomation          = XPRate.EvaluateAutomation
local UpdateAutomationStatus      = XPRate.UpdateAutomationStatus
local UpdateMinimapButtonPosition = XPRate.UpdateMinimapButtonPosition
local SetActiveTab                = XPRate.SetActiveTab

local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:RegisterEvent("PLAYER_LOGIN")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
  if event == "ADDON_LOADED" then
    if loadedAddon ~= addonName and loadedAddon ~= "XPRateControl" then return end

    local db = XPRate.InitDB()

    -- Position restoration
    if db.framePos and XPRate.frame then
      XPRate.frame:ClearAllPoints()
      XPRate.frame:SetPoint(db.framePos.point, UIParent, db.framePos.relativePoint, db.framePos.xOfs, db.framePos.yOfs)
    elseif XPRate.frame then
      XPRate.frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    if UpdateUIFromValue then UpdateUIFromValue(db.lastRate) end
    if UpdateJJUI then UpdateJJUI(db.jjEnabled) end
    if XPRate.restedCheckbox then XPRate.restedCheckbox:SetChecked(db.autoRested) end
    if XPRate.groupCheckbox then XPRate.groupCheckbox:SetChecked(db.autoGroup) end
    if XPRate.mobCheckbox then XPRate.mobCheckbox:SetChecked(db.autoMob) end

    if XPRate.updateRestedRow then XPRate.updateRestedRow() end
    if XPRate.updateNormalRow then XPRate.updateNormalRow() end
    if XPRate.updateGroupRow then XPRate.updateGroupRow() end
    if XPRate.updateMobRows then XPRate.updateMobRows() end
    if UpdateAutomationStatus then UpdateAutomationStatus() end
    if UpdateMinimapButtonPosition then UpdateMinimapButtonPosition() end

    if db.lastRate and XPRateMinimapButtonBorder then
      local rc = RateColor(db.lastRate)
      XPRateMinimapButtonBorder:SetVertexColor(rc[1], rc[2], rc[3])
    end

    if db.autoRested or db.autoGroup or db.autoMob then
      EvaluateAutomation(true, "Addon Init")
    end

    if XPRate.minimapButton then
      if db.showMinimap then
        XPRate.minimapButton:Show()
      else
        XPRate.minimapButton:Hide()
      end
    end

    if SetActiveTab then SetActiveTab(1) end

    -- First load banner
    if db.firstRun then
      PrintMessage("Welcome to XP Rate Control v1.1!")
      PrintMessage("  - Click minimap hourglass icon to toggle settings panel.")
      PrintMessage("  - Right-click minimap icon for quick rate adjustments.")
      PrintMessage("  - Changes are applied instantly. Check out the new tabs!")
      db.firstRun = false
    else
      PrintMessage("Loaded. Type |cff00ff00/xp|r to open, |cff00ff00/xp help|r for commands.")
    end
  elseif event == "PLAYER_LOGIN" then
    if UpdateMinimapButtonPosition then UpdateMinimapButtonPosition() end
  end
end)

-- Slash Command: /xp
SLASH_XPRATECONTROL1 = "/xp"
SlashCmdList["XPRATECONTROL"] = function(msg)
  msg = strtrim(msg)

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

  if msg:lower() == "minimap" then
    if XPRateControlDB then
      XPRateControlDB.showMinimap = not XPRateControlDB.showMinimap
      if XPRate.minimapButton then
        if XPRateControlDB.showMinimap then
          XPRate.minimapButton:Show()
          PrintMessage("Minimap button shown.")
        else
          XPRate.minimapButton:Hide()
          PrintMessage("Minimap button hidden.")
        end
      end
    end
    return
  end

  if msg:lower() == "group" then
    if XPRateControlDB then
      XPRateControlDB.autoGroup = not XPRateControlDB.autoGroup
      if XPRate.groupCheckbox then XPRate.groupCheckbox:SetChecked(XPRateControlDB.autoGroup) end
      PrintMessage("Party XP auto-scaling " .. (XPRateControlDB.autoGroup and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
      XPRate.lastAppliedRate = nil
      XPRate.lastAppliedMode = nil
      EvaluateAutomation(false, "Slash Cmd Toggle")
    end
    return
  end

  if msg:lower() == "help" then
    PrintMessage("Commands:")
    PrintMessage("  |cff00ff00/xp|r - Toggle panel")
    PrintMessage("  |cff00ff00/xp <0-2>|r - Set XP rate (e.g. /xp 1.25)")
    PrintMessage("  |cff00ff00/xp group|r - Toggle party auto-scaling")
    PrintMessage("  |cff00ff00/xp minimap|r - Toggle minimap button")
    return
  end

  local val = tonumber(msg)
  if not val then
    PrintMessage("Invalid value. Type |cff00ff00/xp help|r for usage.")
    return
  end

  if val < RATE_MIN or val > RATE_MAX then
    PrintMessage("Rate must be between " .. RATE_MIN .. " and " .. RATE_MAX .. ".")
    return
  end

  ApplyRate(val)
end
