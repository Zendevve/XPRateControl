-- XPRateControl.lua
-- XP Rate Control WoW Addon for WotLK 3.3.5a Private Servers (e.g. ChromieCraft)
-- Folder name MUST match: Interface/AddOns/XPRateControl/

------------------------------------------------------------
-- Constants
------------------------------------------------------------
local ADDON_NAME = "XPRateControl"
local RATE_MIN = 0
local RATE_MAX = 2
local RATE_STEP = 0.01
local MINIMAP_RADIUS = 80
local DEFAULT_MINIMAP_ANGLE = 45
local DEFAULT_RATE = 1.0
local RATE_ZERO_SUB = "1e-45"

-- Color palette (RGB 0-1)
local CLR = {
    cyan      = { 0.0, 0.82, 1.0 },
    gold      = { 1.0, 0.82, 0.0 },
    green     = { 0.2, 0.92, 0.4 },
    red       = { 1.0, 0.35, 0.3 },
    orange    = { 1.0, 0.6, 0.2 },
    white     = { 1.0, 1.0, 1.0 },
    dim       = { 0.5, 0.55, 0.65 },
    muted     = { 0.35, 0.38, 0.45 },
    panelBg   = { 0.04, 0.05, 0.08 },
    panelEdge = { 0.18, 0.22, 0.32 },
    headerBg  = { 0.08, 0.14, 0.28 },
    btnBg     = { 0.08, 0.12, 0.22 },
    btnEdge   = { 0.22, 0.35, 0.55 },
    btnHover  = { 0.12, 0.22, 0.38 },
    btnPress  = { 0.05, 0.1, 0.18 },
    accentBg  = { 0.06, 0.22, 0.42 },
    accentEdge= { 0.25, 0.55, 0.9 },
    accentHover={ 0.1, 0.32, 0.55 },
    dangerBg  = { 0.35, 0.08, 0.08 },
    dangerEdge= { 0.8, 0.25, 0.25 },
    dangerHover={ 0.5, 0.12, 0.12 },
}

------------------------------------------------------------
-- Helpers
------------------------------------------------------------
local function PrintMessage(msg)
    DEFAULT_CHAT_FRAME:AddMessage("|cff00ccff[XPRate]|r " .. msg)
end

local function FormatRate(val)
    return string.format("%.2f", val)
end

local function ClampRate(val)
    if val < RATE_MIN then return RATE_MIN end
    if val > RATE_MAX then return RATE_MAX end
    return val
end

local function RateColor(val)
    if val <= 0 then return CLR.red end
    if val < 1 then return CLR.orange end
    if val == 1 then return CLR.gold end
    if val <= 1.5 then return CLR.green end
    return CLR.cyan
end

local function RateLabel(val)
    if val <= 0 then return "OFF" end
    if val == 1 then return "Blizzlike" end
    if val == 2 then return "Maximum" end
    return ""
end

local function SendXPCommand(rate)
    local rateStr = (rate == 0) and RATE_ZERO_SUB or FormatRate(rate)
    SendChatMessage(".w r " .. rateStr, "SAY")
end

local function SendJJCommand(enabled)
    local state = enabled and "on" or "off"
    SendChatMessage(".weekendxp j " .. state, "SAY")
end

local function ShowTooltip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:SetText(text, nil, nil, nil, nil, true)
    GameTooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

local function MakeButton(parent, width, height, bgColor, edgeColor)
    local btn = CreateFrame("Button", nil, parent)
    btn:SetSize(width, height)
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
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

------------------------------------------------------------
-- Main UI Frame
------------------------------------------------------------
local frame = CreateFrame("Frame", "XPRateControlFrame", UIParent)
frame:SetSize(280, 380)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetFrameStrata("HIGH")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")
frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
frame:Hide()

tinsert(UISpecialFrames, "XPRateControlFrame")

frame:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.97)
frame:SetBackdropBorderColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.95)

-- Header bar
local headerBg = frame:CreateTexture(nil, "BACKGROUND")
headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
headerBg:SetHeight(36)
headerBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
headerBg:SetGradientAlpha("HORIZONTAL",
    CLR.headerBg[1], CLR.headerBg[2], CLR.headerBg[3], 0.95,
    CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.3)

-- Accent line under header
local accentLine = frame:CreateTexture(nil, "ARTWORK")
accentLine:SetPoint("TOPLEFT", frame, "TOPLEFT", 8, -42)
accentLine:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -42)
accentLine:SetHeight(1)
accentLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
accentLine:SetVertexColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.35)

-- Title
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOP", frame, "TOP", 0, -14)
title:SetText("XP Rate Control")
title:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

-- Version
local version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
version:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -16)
version:SetText("v1.0")
version:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

-- Close button
local closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(22, 22)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -10, -10)

local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
closeBg:SetAllPoints()
closeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
closeBg:SetVertexColor(0.3, 0.08, 0.08, 0.6)

local closeBorder = closeBtn:CreateTexture(nil, "OVERLAY")
closeBorder:SetPoint("TOPLEFT", closeBtn, "TOPLEFT", 0, 0)
closeBorder:SetPoint("TOPRIGHT", closeBtn, "TOPRIGHT", 0, 0)
closeBorder:SetPoint("BOTTOMLEFT", closeBtn, "BOTTOMLEFT", 0, 0)
closeBorder:SetPoint("BOTTOMRIGHT", closeBtn, "BOTTOMRIGHT", 0, 0)
closeBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
closeBorder:SetTexCoord(0.28, 0.72, 0.28, 0.72)
closeBorder:SetVertexColor(0.8, 0.25, 0.25, 0.7)

local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
closeText:SetPoint("CENTER")
closeText:SetText("x")
closeText:SetTextColor(0.85, 0.85, 0.85)

closeBtn:SetScript("OnEnter", function()
    closeBg:SetVertexColor(0.55, 0.1, 0.1, 0.85)
    closeText:SetTextColor(1, 0.3, 0.3)
end)
closeBtn:SetScript("OnLeave", function()
    closeBg:SetVertexColor(0.3, 0.08, 0.08, 0.6)
    closeText:SetTextColor(0.85, 0.85, 0.85)
end)
closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

------------------------------------------------------------
-- XP Rate Section
------------------------------------------------------------
local sectionXP = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sectionXP:SetPoint("TOPLEFT", frame, "TOPLEFT", 16, -52)
sectionXP:SetText("XP RATE")
sectionXP:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

-- Rate value display (large, centered)
local valueText = frame:CreateFontString("XPRateValueTextWidget", "OVERLAY", "GameFontNormalHuge")
valueText:SetPoint("TOP", frame, "TOP", 0, -72)
valueText:SetText("1.00x")
valueText:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3])

-- Status label under value
local statusText = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusText:SetPoint("TOP", valueText, "BOTTOM", 0, -2)
statusText:SetText("Blizzlike")
statusText:SetTextColor(CLR.gold[1], CLR.gold[2], CLR.gold[3], 0.7)

-- Slider
local slider = CreateFrame("Slider", "XPRateSliderWidget", frame, "OptionsSliderTemplate")
slider:SetSize(240, 18)
slider:SetPoint("TOP", statusText, "BOTTOM", 0, -10)
slider:SetMinMaxValues(RATE_MIN, RATE_MAX)
slider:SetValueStep(RATE_STEP)
slider:SetValue(DEFAULT_RATE)

_G[slider:GetName() .. "Text"]:SetText("")
_G[slider:GetName() .. "Low"]:SetText("0")
_G[slider:GetName() .. "Low"]:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])
_G[slider:GetName() .. "High"]:SetText("2")
_G[slider:GetName() .. "High"]:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

-- Numeric input
local editbox = CreateFrame("EditBox", "XPRateEditBoxWidget", frame)
editbox:SetSize(72, 24)
editbox:SetPoint("TOP", slider, "BOTTOM", 0, -8)
editbox:SetAutoFocus(false)
editbox:SetFontObject("GameFontHighlight")
editbox:SetJustifyH("CENTER")
editbox:SetMaxLetters(5)

editbox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 12, edgeSize = 12,
    insets = { left = 3, right = 3, top = 3, bottom = 3 }
})
editbox:SetBackdropColor(0.02, 0.03, 0.06, 0.85)
editbox:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)

editbox:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
end)
editbox:SetScript("OnEditFocusLost", function(self)
    self:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
end)

------------------------------------------------------------
-- Slider <-> EditBox synchronization
------------------------------------------------------------
local isUpdating = false

local function UpdateUIFromValue(value, source)
    if isUpdating then return end
    isUpdating = true

    local valNum = ClampRate(tonumber(value) or DEFAULT_RATE)
    local formatted = FormatRate(valNum)
    local rc = RateColor(valNum)
    local label = RateLabel(valNum)

    if source ~= "slider" then
        slider:SetValue(valNum)
    end
    if source ~= "editbox" then
        editbox:SetText(formatted)
    end

    valueText:SetText(formatted .. "x")
    valueText:SetTextColor(rc[1], rc[2], rc[3])

    statusText:SetText(label)
    statusText:SetTextColor(rc[1], rc[2], rc[3], 0.7)

    isUpdating = false
end

slider:SetScript("OnValueChanged", function(self, value)
    local snapped = math.floor(value / RATE_STEP + 0.5) * RATE_STEP
    UpdateUIFromValue(snapped, "slider")
end)

local function ValidateAndApplyEditBox()
    local text = editbox:GetText()
    local val = tonumber(text)
    if val then
        UpdateUIFromValue(val, "editbox")
    else
        UpdateUIFromValue(slider:GetValue(), nil)
    end
end

editbox:SetScript("OnEnterPressed", function(self)
    ValidateAndApplyEditBox()
    self:ClearFocus()
end)

editbox:SetScript("OnEscapePressed", function(self)
    self:ClearFocus()
end)

editbox:SetScript("OnEditFocusLost", function()
    ValidateAndApplyEditBox()
end)

-- Tooltips
slider:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Drag to set XP rate (0x \226\136\147 2x)")
end)
slider:SetScript("OnLeave", HideTooltip)

editbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Type a value (0.00 \226\136\147 2.00), press Enter")
end)
editbox:SetScript("OnLeave", HideTooltip)

------------------------------------------------------------
-- Apply Rate Button (primary CTA)
------------------------------------------------------------
local applyRateBtn = MakeButton(frame, 140, 28, CLR.accentBg, CLR.accentEdge)
applyRateBtn:SetPoint("TOP", editbox, "BOTTOM", 0, -6)

local applyRateText = applyRateBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
applyRateText:SetPoint("CENTER")
applyRateText:SetText("Apply Rate")
applyRateText:SetTextColor(0.85, 0.95, 1)

applyRateBtn:SetScript("OnClick", function()
    local val = slider:GetValue()
    SendXPCommand(val)
    XPRateControlDB.lastRate = val
    PrintMessage("XP rate set to " .. FormatRate(val) .. "x")
end)
applyRateBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(CLR.accentHover[1], CLR.accentHover[2], CLR.accentHover[3], 1)
    ShowTooltip(self, "Send the selected XP rate to the server")
end)
applyRateBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
    HideTooltip()
end)

------------------------------------------------------------
-- Preset Buttons
------------------------------------------------------------
local presets = { { val = 0,   label = "0x" }, { val = 0.5, label = "0.5x" },
                  { val = 1.0, label = "1x" }, { val = 1.5, label = "1.5x" },
                  { val = 2.0, label = "2x" } }

local presetBar = frame:CreateTexture(nil, "ARTWORK")
presetBar:SetPoint("TOP", applyRateBtn, "BOTTOM", 0, -10)
presetBar:SetHeight(32)

local presetContainer = CreateFrame("Frame", nil, frame)
presetContainer:SetPoint("TOP", applyRateBtn, "BOTTOM", 0, -10)
presetContainer:SetSize(260, 32)

local presetLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontDisable")
presetLabel:SetPoint("TOP", applyRateBtn, "BOTTOM", 0, -10)
presetLabel:SetText("PRESETS")
presetLabel:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

for i, p in ipairs(presets) do
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(44, 24)

    local xOfs = 14 + (i - 1) * 52
    btn:SetPoint("TOPLEFT", presetLabel, "BOTTOM", xOfs - 140, -4)

    local isActive = (p.val == DEFAULT_RATE)

    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 10, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
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

    local rc = RateColor(p.val)
    if p.val == DEFAULT_RATE then
        label:SetTextColor(rc[1], rc[2], rc[3])
        btn:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.8)
    else
        label:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    end

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
        self:SetBackdropBorderColor(CLR.white[1], CLR.white[2], CLR.white[3], 0.5)
        label:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
        ShowTooltip(self, "Set XP rate to " .. FormatRate(p.val) .. "x")
    end)
    btn:SetScript("OnLeave", function(self)
        local curVal = slider:GetValue()
        local isCurrent = (math.abs(curVal - p.val) < 0.005)
        self:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.85)
        if isCurrent then
            local r2 = RateColor(p.val)
            self:SetBackdropBorderColor(r2[1], r2[2], r2[3], 0.8)
            label:SetTextColor(r2[1], r2[2], r2[3])
        else
            self:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
            label:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
        end
        HideTooltip()
    end)
    btn:SetScript("OnClick", function()
        UpdateUIFromValue(p.val, "preset")
        SendXPCommand(p.val)
        XPRateControlDB.lastRate = p.val
        PrintMessage("XP rate set to " .. FormatRate(p.val) .. "x")
    end)
end

------------------------------------------------------------
-- Divider
------------------------------------------------------------
local separator = frame:CreateTexture(nil, "ARTWORK")
separator:SetPoint("TOPLEFT", presetContainer, "BOTTOMLEFT", 2, -30)
separator:SetPoint("TOPRIGHT", presetContainer, "BOTTOMRIGHT", -2, -30)
separator:SetHeight(1)
separator:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
separator:SetVertexColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.4)

------------------------------------------------------------
-- Joyous Journeys Section
------------------------------------------------------------
local sectionJJ = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
sectionJJ:SetPoint("TOPLEFT", separator, "BOTTOMLEFT", 0, -8)
sectionJJ:SetText("JOYOUS JOURNEYS")
sectionJJ:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

local jjDesc = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
jjDesc:SetPoint("TOPLEFT", sectionJJ, "BOTTOMLEFT", 0, -4)
jjDesc:SetText("50% XP buff for characters below max level")
jjDesc:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

local jjCheckbox = CreateFrame("CheckButton", "XPRateJJCheckbox", frame, "UICheckButtonTemplate")
jjCheckbox:SetSize(22, 22)
jjCheckbox:SetPoint("TOPLEFT", jjDesc, "BOTTOMLEFT", 0, -8)

local jjCheckLabel = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
jjCheckLabel:SetPoint("LEFT", jjCheckbox, "RIGHT", 6, 0)
jjCheckLabel:SetText("Enabled")
jjCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local applyJJBtn = MakeButton(frame, 80, 24, CLR.accentBg, CLR.accentEdge)
applyJJBtn:SetPoint("LEFT", jjCheckLabel, "RIGHT", 20, 0)

local applyJJText = applyJJBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
applyJJText:SetPoint("CENTER")
applyJJText:SetText("Apply")
applyJJText:SetTextColor(0.85, 0.95, 1)

applyJJBtn:SetScript("OnClick", function()
    local enabled = (jjCheckbox:GetChecked() == 1) and true or false
    SendJJCommand(enabled)
    XPRateControlDB.jjEnabled = enabled
    PrintMessage("Joyous Journeys " .. (enabled and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
end)
applyJJBtn:SetScript("OnEnter", function(self)
    self:SetBackdropColor(CLR.accentHover[1], CLR.accentHover[2], CLR.accentHover[3], 1)
    ShowTooltip(self, "Toggle the Joyous Journeys 50% XP buff on the server")
end)
applyJJBtn:SetScript("OnLeave", function(self)
    self:SetBackdropColor(CLR.accentBg[1], CLR.accentBg[2], CLR.accentBg[3], 0.95)
    HideTooltip()
end)

jjCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Check to enable Joyous Journeys")
end)
jjCheckbox:SetScript("OnLeave", HideTooltip)

------------------------------------------------------------
-- Footer
------------------------------------------------------------
local footerLine = frame:CreateTexture(nil, "ARTWORK")
footerLine:SetPoint("TOPLEFT", jjCheckbox, "BOTTOMLEFT", -2, -12)
footerLine:SetPoint("RIGHT", frame, "RIGHT", -16, 0)
footerLine:SetHeight(1)
footerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
footerLine:SetVertexColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.3)

local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("TOP", footerLine, "BOTTOM", 0, -6)
footer:SetText("Drag title bar to move \226\148\140 ESC to close")
footer:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

------------------------------------------------------------
-- Minimap Button
------------------------------------------------------------
local minimapButton = CreateFrame("Button", "XPRateMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("MEDIUM")
minimapButton:SetFrameLevel(10)

minimapButton.icon = minimapButton:CreateTexture("XPRateMinimapButtonIcon", "BACKGROUND")
minimapButton.icon:SetSize(18, 18)
minimapButton.icon:SetPoint("CENTER")
minimapButton.icon:SetTexture("Interface\\Icons\\INV_Misc_Hourglass_01")
minimapButton.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local border = minimapButton:CreateTexture("XPRateMinimapButtonBorder", "OVERLAY")
border:SetSize(53, 53)
border:SetPoint("TOPLEFT", minimapButton, "TOPLEFT", -11, 11)
border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")

local highlight = minimapButton:CreateTexture("XPRateMinimapButtonHighlight", "HIGHLIGHT")
highlight:SetSize(31, 31)
highlight:SetPoint("CENTER")
highlight:SetTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")

-- Glow ring (animated pulse for "active" feel)
local glowTex = minimapButton:CreateTexture(nil, "OVERLAY")
glowTex:SetSize(42, 42)
glowTex:SetPoint("CENTER")
glowTex:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
glowTex:SetAlpha(0)
glowTex.isAnimating = false

local glowElapsed = 0
local function GlowPulse(elapsed)
    glowElapsed = glowElapsed + elapsed
    local alpha = 0.15 + 0.15 * math.sin(glowElapsed * 2.5)
    glowTex:SetAlpha(alpha)
end

local function UpdateMinimapButtonPosition()
    local angle = XPRateControlDB and XPRateControlDB.minimapPos or DEFAULT_MINIMAP_ANGLE
    local x = MINIMAP_RADIUS * math.cos(math.rad(angle))
    local y = MINIMAP_RADIUS * math.sin(math.rad(angle))
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Drag
minimapButton:RegisterForDrag("LeftButton")
minimapButton.dragging = false

minimapButton:SetScript("OnDragStart", function(self)
    self.dragging = true
    self:SetScript("OnUpdate", function(self)
        local cx, cy = GetCursorPosition()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        cx, cy = cx / scale, cy / scale
        local angle = math.deg(math.atan2(cy - my, cx - mx))
        if angle < 0 then angle = angle + 360 end
        XPRateControlDB.minimapPos = angle
        UpdateMinimapButtonPosition()
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self.dragging = false
    self:SetScript("OnUpdate", nil)
end)

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local dropdownFrame = CreateFrame("Frame", "XPRateMinimapDropdown", UIParent, "UIDropDownMenuTemplate")

local function ApplyRateFromMenu(rate)
    UpdateUIFromValue(rate)
    SendXPCommand(rate)
    XPRateControlDB.lastRate = rate
    PrintMessage("XP rate set to " .. FormatRate(rate) .. "x")
end

local dropdownMenu = {
    { text = "XP Rate Control", isTitle = true, notCheckable = true },
    { text = "0x (Off)",         func = function() ApplyRateFromMenu(0)   end, notCheckable = true },
    { text = "0.5x",            func = function() ApplyRateFromMenu(0.5) end, notCheckable = true },
    { text = "1x (Blizzlike)",  func = function() ApplyRateFromMenu(1.0) end, notCheckable = true },
    { text = "1.5x",            func = function() ApplyRateFromMenu(1.5) end, notCheckable = true },
    { text = "2x (Maximum)",    func = function() ApplyRateFromMenu(2.0) end, notCheckable = true },
    { text = " ",               disabled = true, notCheckable = true },
    { text = "Open Panel...",   func = function() frame:Show() end, notCheckable = true },
}

minimapButton:SetScript("OnClick", function(self, button)
    if self.dragging then return end
    if button == "LeftButton" then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
    elseif button == "RightButton" then
        EasyMenu(dropdownMenu, dropdownFrame, "cursor", 0, 0, "MENU")
    end
end)

minimapButton:SetScript("OnEnter", function(self)
    ShowTooltip(self,
        "|cff00ccffXP Rate Control|r\n" ..
        "|cffffffffLeft-Click:|r Toggle panel\n" ..
        "|cffffffffRight-Click:|r Quick menu\n" ..
        "|cffffffffDrag:|r Reposition"
    )
end)
minimapButton:SetScript("OnLeave", HideTooltip)

------------------------------------------------------------
-- Initialization
------------------------------------------------------------
local initFrame = CreateFrame("Frame")
initFrame:RegisterEvent("ADDON_LOADED")
initFrame:SetScript("OnEvent", function(self, event, loadedAddon)
    if loadedAddon ~= ADDON_NAME then return end

    if not XPRateControlDB then
        XPRateControlDB = {}
    end

    local db = XPRateControlDB
    if db.minimapPos  == nil then db.minimapPos  = DEFAULT_MINIMAP_ANGLE end
    if db.showMinimap == nil then db.showMinimap = true end
    if db.lastRate    == nil then db.lastRate    = DEFAULT_RATE end
    if db.jjEnabled   == nil then db.jjEnabled   = true end

    UpdateUIFromValue(db.lastRate)
    jjCheckbox:SetChecked(db.jjEnabled)
    UpdateMinimapButtonPosition()

    if db.showMinimap then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end

    PrintMessage("Loaded. Type |cff00ff00/xp|r to open, |cff00ff00/xp help|r for commands.")
    self:UnregisterEvent("ADDON_LOADED")
end)

------------------------------------------------------------
-- Slash Command: /xp
------------------------------------------------------------
SLASH_XPRATECONTROL1 = "/xp"
SlashCmdList["XPRATECONTROL"] = function(msg)
    msg = strtrim(msg)

    if msg == "" then
        if frame:IsShown() then
            frame:Hide()
        else
            frame:Show()
        end
        return
    end

    if msg:lower() == "minimap" then
        XPRateControlDB.showMinimap = not XPRateControlDB.showMinimap
        if XPRateControlDB.showMinimap then
            minimapButton:Show()
            PrintMessage("Minimap button shown.")
        else
            minimapButton:Hide()
            PrintMessage("Minimap button hidden.")
        end
        return
    end

    if msg:lower() == "help" then
        PrintMessage("Commands:")
        PrintMessage("  |cff00ff00/xp|r - Toggle panel")
        PrintMessage("  |cff00ff00/xp <0-2>|r - Set XP rate (e.g. /xp 1.25)")
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

    UpdateUIFromValue(val)
    SendXPCommand(val)
    XPRateControlDB.lastRate = val
    PrintMessage("XP rate set to " .. FormatRate(val) .. "x")
end
