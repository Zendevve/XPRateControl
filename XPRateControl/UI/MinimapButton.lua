-- UI/MinimapButton.lua — Minimap hourglass icon, radial menu, and drag positioning for XPRateControl
local addonName, XPRate = ...

local FormatRate             = XPRate.FormatRate
local ApplyRate              = XPRate.ApplyRate
local ShowTooltip            = XPRate.ShowTooltip
local HideTooltip            = XPRate.HideTooltip
local DEFAULT_MINIMAP_ANGLE  = XPRate.DEFAULT_MINIMAP_ANGLE
local DEFAULT_RATE           = XPRate.DEFAULT_RATE

-- Pulse Coordinator
local ratesPresets = {}
XPRate.ratesPresets = ratesPresets

function XPRate.FlashMinimapButton(targetRate)
  for i, btn in ipairs(ratesPresets) do
    if btn.val and math.abs(btn.val - targetRate) < 0.005 then
      if XPRate.TriggerPulse then XPRate.TriggerPulse() end
      break
    end
  end
end

-- Minimap Button Frame
local minimapButton = CreateFrame("Button", "XPRateMinimapButton", Minimap)
XPRate.minimapButton = minimapButton
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(8)
minimapButton:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

local background = minimapButton:CreateTexture("XPRateMinimapButtonBackground", "BACKGROUND")
background:SetSize(20, 20)
background:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -5)
background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")

minimapButton.icon = minimapButton:CreateTexture("XPRateMinimapButtonIcon", "ARTWORK")
minimapButton.icon:SetSize(20, 20)
minimapButton.icon:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 7, -5)
minimapButton.icon:SetTexture("Interface\\AddOns\\XPRateControl\\Textures\\Icon_Minimap")
minimapButton.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)

local border = minimapButton:CreateTexture("XPRateMinimapButtonBorder", "OVERLAY")
_G.XPRateMinimapButtonBorder = border
border:SetSize(53, 53)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

-- Glow ring (animated pulse for active feel)
local glowTex = minimapButton:CreateTexture(nil, "OVERLAY")
glowTex:SetSize(53, 53)
glowTex:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", 0, 0)
glowTex:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
glowTex:SetAlpha(0)

local glowElapsed = 0
local glowUpdater = CreateFrame("Frame", nil, minimapButton)
glowUpdater:SetScript("OnUpdate", function(self, elapsed)
  glowElapsed = glowElapsed + elapsed
  local alpha = 0.15 + 0.15 * math.sin(glowElapsed * 2.5)
  glowTex:SetAlpha(alpha)
end)

local minimapShapes = {
  ["ROUND"]                 = {true, true, true, true},
  ["SQUARE"]                = {false, false, false, false},
  ["CORNER-TOPLEFT"]        = {true, false, false, false},
  ["CORNER-TOPRIGHT"]       = {false, false, true, false},
  ["CORNER-BOTTOMLEFT"]     = {false, true, false, false},
  ["CORNER-BOTTOMRIGHT"]    = {false, false, false, true},
  ["SIDE-LEFT"]             = {true, true, false, false},
  ["SIDE-RIGHT"]            = {false, false, true, true},
  ["SIDE-TOP"]              = {true, false, true, false},
  ["SIDE-BOTTOM"]           = {false, true, false, true},
  ["TRICORNER-TOPLEFT"]     = {true, true, true, false},
  ["TRICORNER-TOPRIGHT"]    = {true, false, true, true},
  ["TRICORNER-BOTTOMLEFT"]  = {true, true, false, true},
  ["TRICORNER-BOTTOMRIGHT"] = {false, true, true, true},
}

function XPRate.UpdateMinimapButtonPosition()
  local deg = XPRateControlDB and XPRateControlDB.minimapPos or DEFAULT_MINIMAP_ANGLE
  local angle = math.rad(deg)
  local x, y, q = math.cos(angle), math.sin(angle), 1
  if x < 0 then q = q + 1 end
  if y > 0 then q = q + 2 end

  local minimapShape = GetMinimapShape and GetMinimapShape() or "ROUND"
  local quadTable = minimapShapes[minimapShape] or minimapShapes["ROUND"]
  if quadTable[q] then
    x, y = x * 80, y * 80
  else
    local diagRadius = 103.13708498985
    x = math.max(-80, math.min(x * diagRadius, 80))
    y = math.max(-80, math.min(y * diagRadius, 80))
  end

  minimapButton:ClearAllPoints()
  minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

local function OnMinimapButtonDragUpdate(self)
  local mx, my = Minimap:GetCenter()
  local px, py = GetCursorPosition()
  local scale = Minimap:GetEffectiveScale()
  if mx and my and scale and scale > 0 then
    px, py = px / scale, py / scale
    local angle = math.deg(math.atan2(py - my, px - mx)) % 360
    if XPRateControlDB then
      XPRateControlDB.minimapPos = angle
    end
    XPRate.UpdateMinimapButtonPosition()
  end
end

minimapButton:RegisterForDrag("LeftButton")

minimapButton:SetScript("OnMouseDown", function(self)
  self.icon:SetTexCoord(0, 1, 0, 1)
end)

minimapButton:SetScript("OnMouseUp", function(self)
  self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
end)

minimapButton:SetScript("OnDragStart", function(self)
  self:LockHighlight()
  self.icon:SetTexCoord(0, 1, 0, 1)
  self:SetScript("OnUpdate", OnMinimapButtonDragUpdate)
  self.isMoving = true
  HideTooltip()
end)

minimapButton:SetScript("OnDragStop", function(self)
  self:SetScript("OnUpdate", nil)
  self.icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
  self:UnlockHighlight()
  self.isMoving = nil
end)

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local dropdownFrame = CreateFrame("Frame", "XPRateMinimapDropdown", UIParent, "UIDropDownMenuTemplate")

local dropdownMenu = {
  { text = "XP Rate Control", isTitle = true, notCheckable = true },
  { text = "0x (Off)",        func = function() ApplyRate(0)   end, notCheckable = true },
  { text = "0.5x",           func = function() ApplyRate(0.5) end, notCheckable = true },
  { text = "1x (Blizzlike)", func = function() ApplyRate(1.0) end, notCheckable = true },
  { text = "1.5x",           func = function() ApplyRate(1.5) end, notCheckable = true },
  { text = "2x (Maximum)",   func = function() ApplyRate(2.0) end, notCheckable = true },
  { text = " ",              disabled = true, notCheckable = true },
  { text = "Open Panel...",  func = function() if XPRate.frame then XPRate.frame:Show() end end, notCheckable = true },
}

minimapButton:SetScript("OnClick", function(self, button)
  if self.isMoving then return end
  if button == "LeftButton" then
    if XPRate.frame then
      if XPRate.frame:IsShown() then
        XPRate.frame:Hide()
      else
        XPRate.frame:Show()
      end
    end
  elseif button == "RightButton" then
    EasyMenu(dropdownMenu, dropdownFrame, "cursor", 0, 0, "MENU")
  end
end)

minimapButton:SetScript("OnEnter", function(self)
  if self.isMoving then return end
  local rateStr = FormatRate(XPRateControlDB and XPRateControlDB.lastRate or DEFAULT_RATE)
  ShowTooltip(self,
    "|cff00ccffXP Rate Control|r\n" ..
    "Current Rate: |cff20cc50" .. rateStr .. "x|r\n\n" ..
    "|cffffffffLeft-Click:|r Toggle panel\n" ..
    "|cffffffffRight-Click:|r Quick menu\n" ..
    "|cffffffffDrag:|r Reposition"
  )
end)
minimapButton:SetScript("OnLeave", HideTooltip)
