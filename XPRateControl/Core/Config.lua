-- Core/Config.lua — Constants, color palette, and SavedVariables management for XPRateControl
local addonName, XPRate = ...

XPRate.ADDON_NAME = addonName or "XPRateControl"

-- Rate constraints & defaults
XPRate.RATE_MIN       = 0
XPRate.RATE_MAX       = 2
XPRate.RATE_STEP      = 0.01
XPRate.DEFAULT_RATE   = 1.0
XPRate.RATE_ZERO_SUB  = "1e-45"
XPRate.DEFAULT_MINIMAP_ANGLE = 195

-- Color Palette
XPRate.CLR = {
  bg        = { 0.05, 0.07, 0.10, 0.95 },
  panelBg   = { 0.08, 0.11, 0.16, 0.95 },
  cardBg    = { 0.11, 0.15, 0.22, 0.90 },
  cardEdge  = { 0.20, 0.28, 0.38, 0.60 },
  cyan      = { 0.00, 0.80, 1.00 },
  gold      = { 1.00, 0.82, 0.00 },
  green     = { 0.13, 0.80, 0.31 },
  red       = { 0.90, 0.22, 0.22 },
  dim       = { 0.55, 0.62, 0.72 },
  white     = { 0.92, 0.95, 0.98 },
  btnBg     = { 0.14, 0.19, 0.27 },
  btnHover  = { 0.20, 0.27, 0.38 },
  btnEdge   = { 0.25, 0.35, 0.48 },
  accent    = { 0.00, 0.70, 0.90 },
  accentBg  = { 0.00, 0.35, 0.50, 0.30 },
}

-- Print helper formatted with cyan prefix
function XPRate.PrintMessage(msg)
  DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[XPRate]|r " .. tostring(msg or ""))
end

-- Initialize SavedVariables table
function XPRate.InitDB()
  if not XPRateControlDB then
    XPRateControlDB = {}
  end

  local db = XPRateControlDB
  if db.minimapPos  == nil then db.minimapPos  = XPRate.DEFAULT_MINIMAP_ANGLE end
  if db.showMinimap == nil then db.showMinimap = true end
  if db.lastRate    == nil then db.lastRate    = XPRate.DEFAULT_RATE end
  if db.jjEnabled   == nil then db.jjEnabled   = true end
  if db.autoRested  == nil then db.autoRested  = false end
  if db.restedRate  == nil then db.restedRate  = 2.0 end
  if db.normalRate  == nil then db.normalRate  = 1.0 end
  if db.autoGroup   == nil then db.autoGroup   = false end
  if db.groupRates  == nil then db.groupRates  = {} end
  if db.groupRates[1] == nil then db.groupRates[1] = 1.00 end
  if db.groupRates[2] == nil then db.groupRates[2] = 1.25 end
  if db.groupRates[3] == nil then db.groupRates[3] = 1.50 end
  if db.groupRates[4] == nil then db.groupRates[4] = 1.75 end
  if db.autoMob     == nil then db.autoMob     = false end
  if db.mobRates    == nil then db.mobRates    = {} end
  if db.mobRates.gray   == nil then db.mobRates.gray   = 0.0 end
  if db.mobRates.green  == nil then db.mobRates.green  = 0.5 end
  if db.mobRates.yellow == nil then db.mobRates.yellow = 1.0 end
  if db.mobRates.red    == nil then db.mobRates.red    = 2.0 end
  if db.autoQuest   == nil then db.autoQuest   = false end
  if db.questRate   == nil then db.questRate   = 2.0 end
  if db.firstRun == nil then db.firstRun = true end

  return db
end
