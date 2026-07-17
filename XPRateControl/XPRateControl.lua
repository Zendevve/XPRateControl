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

local tinsert = table.insert

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
}

------------------------------------------------------------
-- State Variables
------------------------------------------------------------
local pendingRate = nil
local pendingTime = nil
local isAwaitingConfirmation = false
local queuedRate = nil

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
frame:SetSize(320, 300)
frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
frame:SetFrameStrata("HIGH")
frame:SetMovable(true)
frame:EnableMouse(true)
frame:SetClampedToScreen(true)
frame:RegisterForDrag("LeftButton")

frame:SetScript("OnDragStart", frame.StartMoving)
frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
    if XPRateControlDB then
        XPRateControlDB.framePos = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs
        }
    end
end)
frame:Hide()

tinsert(UISpecialFrames, "XPRateControlFrame")

frame:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background-Dark",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 32, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 }
})
frame:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.97)
frame:SetBackdropBorderColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.95)

-- Header bar
local headerBg = frame:CreateTexture(nil, "BACKGROUND")
headerBg:SetPoint("TOPLEFT", frame, "TOPLEFT", 6, -6)
headerBg:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -6, -6)
headerBg:SetHeight(32)
headerBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
headerBg:SetGradientAlpha("HORIZONTAL",
    CLR.headerBg[1], CLR.headerBg[2], CLR.headerBg[3], 0.95,
    CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.3)

-- Title
local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
title:SetPoint("TOPLEFT", frame, "TOPLEFT", 12, -14)
title:SetText("XP Rate Control")
title:SetTextColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3])

-- Version
local version = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
version:SetPoint("LEFT", title, "RIGHT", 6, 0)
version:SetText("v1.2")
version:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

-- Close button
local closeBtn = CreateFrame("Button", nil, frame)
closeBtn:SetSize(26, 26)
closeBtn:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -8, -8)

local closeBg = closeBtn:CreateTexture(nil, "BACKGROUND")
closeBg:SetAllPoints()
closeBg:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
closeBg:SetVertexColor(0.35, 0.08, 0.08, 0.8)

local closeBorder = closeBtn:CreateTexture(nil, "OVERLAY")
closeBorder:SetAllPoints()
closeBorder:SetTexture("Interface\\Tooltips\\UI-Tooltip-Border")
closeBorder:SetTexCoord(0.28, 0.72, 0.28, 0.72)
closeBorder:SetVertexColor(0.8, 0.25, 0.25, 0.7)

local closeText = closeBtn:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
closeText:SetPoint("CENTER", closeBtn, "CENTER", 0, 1)
closeText:SetText("\226\156\149") -- ✕ glyph
closeText:SetTextColor(0.85, 0.85, 0.85)

closeBtn:SetScript("OnEnter", function()
    closeBg:SetVertexColor(0.7, 0.1, 0.1, 0.95)
    closeText:SetTextColor(1, 0.4, 0.4)
end)
closeBtn:SetScript("OnLeave", function()
    closeBg:SetVertexColor(0.35, 0.08, 0.08, 0.8)
    closeText:SetTextColor(0.85, 0.85, 0.85)
end)
closeBtn:SetScript("OnClick", function()
    frame:Hide()
end)

------------------------------------------------------------
-- Tab Layout Containers
------------------------------------------------------------
local RatesTabFrame = CreateFrame("Frame", nil, frame)
RatesTabFrame:SetSize(308, 196)
RatesTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)

local AutomationTabFrame = CreateFrame("Frame", nil, frame)
AutomationTabFrame:SetSize(308, 196)
AutomationTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)
AutomationTabFrame:Hide()

local BuffsTabFrame = CreateFrame("Frame", nil, frame)
BuffsTabFrame:SetSize(308, 196)
BuffsTabFrame:SetPoint("TOP", frame, "TOP", 0, -68)
BuffsTabFrame:Hide()

local tabFrames = { RatesTabFrame, AutomationTabFrame, BuffsTabFrame }
local tabColors = { CLR.cyan, CLR.green, CLR.gold }

------------------------------------------------------------
-- Toast Notification System
------------------------------------------------------------
local toast = CreateFrame("Frame", nil, frame)
toast:SetSize(240, 24)
toast:SetPoint("BOTTOM", frame, "BOTTOM", 0, 36)
toast:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
toast:SetBackdropColor(0.02, 0.08, 0.05, 0.95)
toast:SetBackdropBorderColor(0.2, 0.8, 0.4, 0.8)
toast:SetFrameStrata("DIALOG")
toast:Hide()

local toastText = toast:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
toastText:SetPoint("CENTER")

local toastTimer = 0
local function ShowToast(text, isError)
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

------------------------------------------------------------
-- Section Header Builder
------------------------------------------------------------
local function CreateSectionHeader(parent, name, iconPath, accentColor)
    local stripe = parent:CreateTexture(nil, "ARTWORK")
    stripe:SetSize(4, 18)
    stripe:SetPoint("TOPLEFT", parent, "TOPLEFT", 10, -6)
    stripe:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    stripe:SetVertexColor(accentColor[1], accentColor[2], accentColor[3])
    
    local icon = parent:CreateTexture(nil, "ARTWORK")
    icon:SetSize(14, 14)
    icon:SetPoint("LEFT", stripe, "RIGHT", 6, 0)
    icon:SetTexture(iconPath)
    
    local text = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
    text:SetText(name)
    text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    
    return stripe
end

------------------------------------------------------------
-- Preset Pulse Coordinator
------------------------------------------------------------
local ratesPresets = {}
local restedPresets = {}
local pulseElapsed = 0

local presetPulseFrame = CreateFrame("Frame")
presetPulseFrame:SetScript("OnUpdate", function(self, elapsed)
    pulseElapsed = pulseElapsed + elapsed
    local alpha = 0.45 + 0.35 * math.sin(pulseElapsed * 3.5)
    
    -- Tab 1 presets
    if RatesTabFrame:IsShown() and XPRateSliderWidget then
        local curRate = XPRateSliderWidget:GetValue()
        for _, item in ipairs(ratesPresets) do
            local isCurrent = (math.abs(curRate - item.val) < 0.005)
            if isCurrent then
                local rc = RateColor(item.val)
                item.btn:SetBackdropBorderColor(rc[1], rc[2], rc[3], alpha)
            end
        end
    end
    
    -- Tab 2 presets
    if AutomationTabFrame:IsShown() then
        for _, item in ipairs(restedPresets) do
            local targetVal = item.getVal()
            local isCurrent = (math.abs(targetVal - item.val) < 0.005)
            if isCurrent then
                local rc = RateColor(item.val)
                item.btn:SetBackdropBorderColor(rc[1], rc[2], rc[3], alpha)
            end
        end
    end
end)

------------------------------------------------------------
-- Minimap Flash Coordinator
------------------------------------------------------------
local flashTimer = 0
local flashCount = 0
local flashState = false
local originalColor = nil

local minimapFlashFrame = CreateFrame("Frame")
minimapFlashFrame:SetScript("OnUpdate", function(self, elapsed)
    if flashTimer > 0 and XPRateMinimapButtonIcon then
        flashTimer = flashTimer - elapsed
        if flashTimer <= 0 then
            if flashCount > 0 then
                flashCount = flashCount - 1
                flashState = not flashState
                if flashState then
                    XPRateMinimapButtonIcon:SetVertexColor(1, 0.5, 0)
                else
                    XPRateMinimapButtonIcon:SetVertexColor(originalColor[1], originalColor[2], originalColor[3])
                end
                flashTimer = 0.15
            else
                XPRateMinimapButtonIcon:SetVertexColor(originalColor[1], originalColor[2], originalColor[3])
            end
        end
    end
end)

local function FlashMinimapButton(targetRate)
    originalColor = RateColor(targetRate)
    flashCount = 6
    flashState = false
    flashTimer = 0.01
end

------------------------------------------------------------
-- Message Verification Helpers
------------------------------------------------------------
local function MatchSuccessMessage(msg, rate)
    local lowerMsg = msg:lower()
    local formattedRate = FormatRate(rate)
    local shortRate = tostring(rate)
    if string.find(lowerMsg, formattedRate, 1, true) or string.find(lowerMsg, shortRate, 1, true) then
        if string.find(lowerMsg, "xp") or string.find(lowerMsg, "rate") or string.find(lowerMsg, "experience") then
            return true
        end
    end
    return false
end

local function MatchErrorMessage(msg)
    local lowerMsg = msg:lower()
    if string.find(lowerMsg, "invalid") or string.find(lowerMsg, "error") or string.find(lowerMsg, "combat") or string.find(lowerMsg, "cannot") or string.find(lowerMsg, "fail") then
        return true
    end
    return false
end

------------------------------------------------------------
-- Tab 1: Rates UI Creation
------------------------------------------------------------
CreateSectionHeader(RatesTabFrame, "XP RATE", "Interface\\Icons\\INV_Misc_Experience_01", CLR.cyan)

-- Inset Card (Hero Element)
local heroCard = CreateFrame("Frame", nil, RatesTabFrame)
heroCard:SetSize(288, 86)
heroCard:SetPoint("TOP", RatesTabFrame, "TOP", 0, -28)
heroCard:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
heroCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
heroCard:SetBackdropBorderColor(CLR.panelEdge[1] * 1.3, CLR.panelEdge[2] * 1.3, CLR.panelEdge[3] * 1.3, 0.8)

-- Speedometer dial track
local dialTrack = heroCard:CreateTexture(nil, "BACKGROUND")
dialTrack:SetSize(72, 72)
dialTrack:SetPoint("CENTER", heroCard, "CENTER", 0, 0)
dialTrack:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
dialTrack:SetVertexColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.4)

-- Speedometer Dial Dot
local dialDot = heroCard:CreateTexture(nil, "OVERLAY")
dialDot:SetSize(8, 8)
dialDot:SetTexture("Interface\\SocialFrame\\ChatFrameSearchResult-Dot")

local function UpdateDial(rate)
    local percent = rate / RATE_MAX
    local currentAngle = 225 - (percent * 270)
    local rad = math.rad(currentAngle)
    local radius = 32
    local x = radius * math.cos(rad)
    local y = radius * math.sin(rad)
    dialDot:SetPoint("CENTER", heroCard, "CENTER", x, y)
    local rc = RateColor(rate)
    dialDot:SetVertexColor(rc[1], rc[2], rc[3])
end

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

local function TriggerPulse()
    pulseTime = 0
    pulseFrame:SetScript("OnUpdate", OnUpdatePulse)
end

-- Tag Chip
local tagChip = CreateFrame("Frame", nil, heroCard)
tagChip:SetSize(70, 14)
tagChip:SetPoint("TOP", pulseFrame, "BOTTOM", 0, -2)
tagChip:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
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
slider:SetSize(200, 14)
slider:SetPoint("TOPLEFT", heroCard, "BOTTOMLEFT", 12, -18)
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
trackBg:SetVertexColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.3)

local trackFill = slider:CreateTexture(nil, "ARTWORK")
trackFill:SetHeight(4)
trackFill:SetPoint("LEFT", slider, "LEFT", 0, 0)
trackFill:SetPoint("RIGHT", thumb, "CENTER", 0, 0)
trackFill:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")

local lowText = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
lowText:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -4)
lowText:SetText("0x")

local highText = slider:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
highText:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -4)
highText:SetText("2x")

-- Numeric editbox (beside slider)
local editbox = CreateFrame("EditBox", "XPRateEditBoxWidget", RatesTabFrame)
editbox:SetSize(54, 18)
editbox:SetPoint("LEFT", slider, "RIGHT", 12, 0)
editbox:SetAutoFocus(false)
editbox:SetFontObject("GameFontHighlightSmall")
editbox:SetJustifyH("CENTER")
editbox:SetMaxLetters(5)
editbox:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 8, edgeSize = 8,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
editbox:SetBackdropColor(0.02, 0.03, 0.06, 0.85)
editbox:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)

-- Floating value bubble
local sliderBubble = CreateFrame("Frame", nil, slider)
sliderBubble:SetSize(40, 18)
sliderBubble:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
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

local function UpdateUIFromValue(value, source)
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

    UpdateDial(valNum)
    UpdateTagChip(valNum)

    sliderBubbleText:SetText(formatted .. "x")
    sliderBubbleText:SetTextColor(rc[1], rc[2], rc[3])
    sliderBubble:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.8)

    if source and lastUIValue and math.abs(valNum - lastUIValue) > 0.005 then
        TriggerPulse()
    end
    lastUIValue = valNum

    isUpdating = false
end

-- Forward declaration of ApplyRate
local ApplyRate

slider:SetScript("OnValueChanged", function(self, value)
    local snapped = math.floor(value / RATE_STEP + 0.5) * RATE_STEP
    UpdateUIFromValue(snapped, "slider")
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
    ShowTooltip(self, "Drag to set XP rate (0x \226\136\147 2x)")
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
        UpdateUIFromValue(clamped, "editbox")
        ApplyRate(clamped)
    else
        UpdateUIFromValue(slider:GetValue(), nil)
    end
end

editbox:SetScript("OnEditFocusGained", function(self)
    self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
end)

editbox:SetScript("OnEscapePressed", function(self)
    self.reverting = true
    local lastVal = XPRateControlDB and XPRateControlDB.lastRate or DEFAULT_RATE
    self:SetText(FormatRate(lastVal))
    UpdateUIFromValue(lastVal, "editbox")
    self:ClearFocus()
end)

editbox:SetScript("OnEnterPressed", function(self)
    self:ClearFocus()
end)

editbox:SetScript("OnEditFocusLost", function(self)
    self:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
    if self.reverting then
        self.reverting = nil
        return
    end
    ValidateAndApplyEditBox()
end)

editbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Type a value (0.00 \226\136\147 2.00), press Enter")
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
    btn:SetSize(42, 22)
    btn:SetPoint("TOPLEFT", RatesTabFrame, "TOPLEFT", 12 + (i-1)*48, -156)
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
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
    
    tinsert(ratesPresets, { btn = btn, val = p.val, label = label })
end

------------------------------------------------------------
-- Profile Management Helpers
------------------------------------------------------------
local function GetActiveProfile()
    local db = XPRateControlDB
    if not db or not db.profiles or not db.currentProfile then return nil end
    return db.profiles[db.currentProfile]
end

local function SaveActiveProfileSettings()
    local db = XPRateControlDB
    local p = GetActiveProfile()
    if not p or not db then return end
    
    p.autoRested = db.autoRested
    p.restedRate = db.restedRate
    p.normalRate = db.normalRate
    p.jjEnabled = db.jjEnabled
    p.dungeonRate = db.dungeonRate
    p.dungeonEnabled = db.dungeonEnabled
    p.bgRate = db.bgRate
    p.bgEnabled = db.bgEnabled
    p.cityRate = db.cityRate
    p.cityEnabled = db.cityEnabled
end

local updateRestedRow
local updateNormalRow
local updateDungeonRow
local updateBgRow
local updateCityRow
local UpdateAutomationStatus
local EvaluateRules
local UpdateJJUI

local function LoadProfile(name)
    local db = XPRateControlDB
    if not db or not db.profiles or not db.profiles[name] then return end
    db.currentProfile = name
    local p = db.profiles[name]
    
    db.autoRested = p.autoRested
    db.restedRate = p.restedRate
    db.normalRate = p.normalRate
    db.dungeonRate = p.dungeonRate
    db.dungeonEnabled = p.dungeonEnabled
    db.bgRate = p.bgRate
    db.bgEnabled = p.bgEnabled
    db.cityRate = p.cityRate
    db.cityEnabled = p.cityEnabled
    
    if db.jjEnabled ~= p.jjEnabled then
        SendJJCommand(p.jjEnabled)
        db.jjEnabled = p.jjEnabled
    end
    
    if XPRateSliderWidget then
        UpdateUIFromValue(db.lastRate)
    end
    if XPRateRestedCheckbox then
        XPRateRestedCheckbox:SetChecked(db.autoRested)
    end
    if XPRateJJCheckbox then
        UpdateJJUI(db.jjEnabled)
    end
    
    if updateRestedRow and updateNormalRow then
        updateRestedRow()
        updateNormalRow()
    end
    if updateDungeonRow and updateBgRow and updateCityRow then
        updateDungeonRow()
        updateBgRow()
        updateCityRow()
    end
    
    if XPRateProfileButtonWidget then
        XPRateProfileButtonWidget:SetText("Profile: " .. name)
    end
    
    UpdateAutomationStatus()
    EvaluateRules()
end

local function ExportProfileString()
    local name = XPRateControlDB.currentProfile
    local p = GetActiveProfile()
    if not p then return "" end
    
    local parts = {
        "[XPRC",
        "v1",
        name,
        p.autoRested and "1" or "0",
        FormatRate(p.restedRate),
        FormatRate(p.normalRate),
        FormatRate(p.dungeonRate),
        FormatRate(p.bgRate),
        FormatRate(p.cityRate),
        p.jjEnabled and "1" or "0",
        p.dungeonEnabled and "1" or "0",
        p.bgEnabled and "1" or "0",
        p.cityEnabled and "1" or "0",
    }
    return table.concat(parts, ":") .. "]"
end

local function ImportProfileString(str)
    str = strtrim(str)
    if not string.find(str, "^%[XPRC:v1:") or not string.find(str, "%]$") then
        ShowToast("Invalid profile string \226\156\151", true)
        return
    end
    
    local payload = string.sub(str, 2, -2)
    local parts = {}
    for part in string.gmatch(payload, "[^:]+") do
        tinsert(parts, part)
    end
    
    if #parts < 13 then
        ShowToast("Invalid profile string \226\156\151", true)
        return
    end
    
    local name = parts[3]
    local uniqueName = name
    local counter = 1
    while XPRateControlDB.profiles[uniqueName] do
        uniqueName = name .. " (" .. counter .. ")"
        counter = counter + 1
    end
    
    XPRateControlDB.profiles[uniqueName] = {
        autoRested = (parts[4] == "1"),
        restedRate = ClampRate(tonumber(parts[5]) or 2.0),
        normalRate = ClampRate(tonumber(parts[6]) or 1.0),
        dungeonRate = ClampRate(tonumber(parts[7]) or 1.5),
        bgRate = ClampRate(tonumber(parts[8]) or 1.0),
        cityRate = ClampRate(tonumber(parts[9]) or 0.5),
        jjEnabled = (parts[10] == "1"),
        dungeonEnabled = (parts[11] == "1"),
        bgEnabled = (parts[12] == "1"),
        cityEnabled = (parts[13] == "1"),
    }
    
    LoadProfile(uniqueName)
    ShowToast("Imported: " .. uniqueName, false)
end

------------------------------------------------------------
-- Static Popup Dialog Registration
------------------------------------------------------------
StaticPopupDialogs["XPRATE_CREATE_PROFILE"] = {
    text = "Enter name for new profile:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        name = strtrim(name)
        name = string.gsub(name, ":", "-")
        if name ~= "" and not XPRateControlDB.profiles[name] then
            local active = GetActiveProfile()
            XPRateControlDB.profiles[name] = {
                autoRested = active.autoRested,
                restedRate = active.restedRate,
                normalRate = active.normalRate,
                jjEnabled = active.jjEnabled,
                dungeonRate = active.dungeonRate,
                dungeonEnabled = active.dungeonEnabled,
                bgRate = active.bgRate,
                bgEnabled = active.bgEnabled,
                cityRate = active.cityRate,
                cityEnabled = active.cityEnabled,
            }
            LoadProfile(name)
            ShowToast("Profile created: " .. name, false)
        end
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        StaticPopupDialogs["XPRATE_CREATE_PROFILE"].OnAccept(parent)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["XPRATE_DELETE_PROFILE"] = {
    text = "Are you sure you want to delete profile %s?",
    button1 = "Yes",
    button2 = "No",
    OnAccept = function(self)
        local name = XPRateControlDB.currentProfile
        if name ~= "Default" then
            XPRateControlDB.profiles[name] = nil
            LoadProfile("Default")
            ShowToast("Profile deleted: " .. name, false)
        end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["XPRATE_EXPORT_PROFILE"] = {
    text = "Copy Profile String (Ctrl+C):",
    button1 = "Close",
    hasEditBox = true,
    OnShow = function(self)
        local exp = ExportProfileString()
        self.editBox:SetText(exp)
        self.editBox:SetFocus()
        self.editBox:HighlightText()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

StaticPopupDialogs["XPRATE_IMPORT_PROFILE"] = {
    text = "Paste Profile String (Ctrl+V):",
    button1 = "Import",
    button2 = "Cancel",
    hasEditBox = true,
    OnAccept = function(self)
        local text = self.editBox:GetText()
        ImportProfileString(text)
    end,
    EditBoxOnEnterPressed = function(self)
        local parent = self:GetParent()
        local text = self:GetText()
        ImportProfileString(text)
        parent:Hide()
    end,
    EditBoxOnEscapePressed = function(self)
        self:GetParent():Hide()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
}

------------------------------------------------------------
-- Tab 2: Automation (Auto Rested) UI Creation
------------------------------------------------------------
-- Profile Row Controls
local profileBtn = MakeButton(AutomationTabFrame, 130, 18, CLR.btnBg, CLR.btnEdge)
profileBtn:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 12, -6)
profileBtn:SetFrameLevel(AutomationTabFrame:GetFrameLevel() + 2)

local profileBtnText = profileBtn:CreateFontString("XPRateProfileButtonWidget", "OVERLAY", "GameFontHighlightSmall")
profileBtnText:SetPoint("CENTER")
profileBtnText:SetText("Profile: Default")

local dropdownFrame = CreateFrame("Frame", "XPRateControlDropdown", UIParent, "UIDropDownMenuTemplate")

profileBtn:SetScript("OnClick", function(self)
    local menu = {}
    tinsert(menu, { text = "Select Profile", isTitle = true, notCheckable = true })
    
    for pName, _ in pairs(XPRateControlDB.profiles) do
        tinsert(menu, {
            text = pName,
            checked = (XPRateControlDB.currentProfile == pName),
            func = function()
                LoadProfile(pName)
                ShowToast("Profile loaded: " .. pName, false)
            end
        })
    end
    
    tinsert(menu, { text = "", disabled = true, notCheckable = true })
    tinsert(menu, {
        text = "New Profile...",
        notCheckable = true,
        func = function()
            StaticPopup_Show("XPRATE_CREATE_PROFILE")
        end
    })
    tinsert(menu, {
        text = "Delete Profile...",
        notCheckable = true,
        disabled = (XPRateControlDB.currentProfile == "Default"),
        func = function()
            StaticPopup_Show("XPRATE_DELETE_PROFILE", XPRateControlDB.currentProfile)
        end
    })
    
    EasyMenu(menu, dropdownFrame, "cursor", 0, 0, "MENU")
end)

local exportBtn = MakeButton(AutomationTabFrame, 62, 18, CLR.btnBg, CLR.btnEdge)
exportBtn:SetPoint("LEFT", profileBtn, "RIGHT", 10, 0)
local exportText = exportBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
exportText:SetPoint("CENTER")
exportText:SetText("Export")

exportBtn:SetScript("OnClick", function()
    StaticPopup_Show("XPRATE_EXPORT_PROFILE")
end)

local importBtn = MakeButton(AutomationTabFrame, 62, 18, CLR.btnBg, CLR.btnEdge)
importBtn:SetPoint("LEFT", exportBtn, "RIGHT", 10, 0)
local importText = importBtn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
importText:SetPoint("CENTER")
importText:SetText("Import")

importBtn:SetScript("OnClick", function()
    StaticPopup_Show("XPRATE_IMPORT_PROFILE")
end)

-- Rested Controls
local restedCheckbox = CreateFrame("CheckButton", "XPRateRestedCheckbox", AutomationTabFrame, "UICheckButtonTemplate")
restedCheckbox:SetSize(18, 18)
restedCheckbox:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 12, -30)

local restedCheckLabel = AutomationTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
restedCheckLabel:SetPoint("LEFT", restedCheckbox, "RIGHT", 4, 0)
restedCheckLabel:SetText("Auto Rested")
restedCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local automationStatusText = AutomationTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
automationStatusText:SetPoint("LEFT", restedCheckLabel, "RIGHT", 16, 0)
automationStatusText:SetText("Status: Inactive")

function UpdateAutomationStatus()
    local db = XPRateControlDB
    if not db then return end
    
    local activeReason = "Default (Normal)"
    local isRested = (GetXPExhaustion() and GetXPExhaustion() > 0) or false
    
    if db.autoRested and isRested then
        activeReason = "Rested XP"
    else
        local isInstance, instanceType = IsInInstance()
        if isInstance then
            if (instanceType == "party" or instanceType == "raid") and db.dungeonEnabled then
                activeReason = "Dungeon"
            elseif (instanceType == "pvp" or instanceType == "arena") and db.bgEnabled then
                activeReason = "Battleground"
            end
        elseif IsResting() and db.cityEnabled then
            activeReason = "Rest Area"
        end
    end
    
    local currentRate = db.lastRate or DEFAULT_RATE
    local rc = RateColor(currentRate)
    local colorHex = string.format("%02x%02x%02x", rc[1]*255, rc[2]*255, rc[3]*255)
    automationStatusText:SetText(string.format("Status: |cffffffffActive|r (%s) \226\145\146 |cff%s%sx|r", activeReason, colorHex, FormatRate(currentRate)))
end

function EvaluateRules()
    local db = XPRateControlDB
    if not db then return end
    
    local targetRate = nil
    local reason = nil
    
    -- Rule 1: Rested XP (if checked and player has rested XP)
    if db.autoRested then
        local isRested = (GetXPExhaustion() and GetXPExhaustion() > 0) or false
        if isRested then
            targetRate = db.restedRate
            reason = "Rested XP active"
        end
    end
    
    -- Rule 2: Zone / Instance / PvP Context rules
    if not targetRate then
        local isInstance, instanceType = IsInInstance()
        if isInstance then
            if (instanceType == "party" or instanceType == "raid") and db.dungeonEnabled then
                targetRate = db.dungeonRate
                reason = "Inside Dungeon/Raid"
            elseif (instanceType == "pvp" or instanceType == "arena") and db.bgEnabled then
                targetRate = db.bgRate
                reason = "Inside Battleground/Arena"
            end
        end
    end
    
    if not targetRate and db.cityEnabled then
        if IsResting() then
            targetRate = db.cityRate
            reason = "Inside Resting area"
        end
    end
    
    -- Rule 3: Default Rate
    if not targetRate then
        targetRate = db.normalRate
        reason = "Default (Normal)"
    end
    
    -- Queue or apply
    if not db.lastRate or math.abs(db.lastRate - targetRate) > 0.005 then
        local inCombat = UnitAffectingCombat("player")
        if inCombat then
            queuedRate = targetRate
            ShowToast(string.format("Pending: %sx (Combat) \226\143\179", FormatRate(targetRate)), false)
        else
            ApplyRate(targetRate, false)
            FlashMinimapButton(targetRate)
            PrintMessage(string.format("Context switch (%s). XP rate set to %sx", reason, FormatRate(targetRate)))
        end
    end
    
    UpdateAutomationStatus()
end

restedCheckbox:SetScript("OnClick", function(self)
    local enabled = (self:GetChecked() == 1)
    XPRateControlDB.autoRested = enabled
    SaveActiveProfileSettings()
    EvaluateRules()
    ShowToast(enabled and "Auto Rested Enabled \226\156\147" or "Auto Rested Disabled \226\156\147", false)
end)

restedCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Automatically switch XP rates depending on whether you have Rested XP.")
end)
restedCheckbox:SetScript("OnLeave", HideTooltip)

-- Rested presets row generator helper
local function CreateRestedPresetRow(parent, labelText, yOfs, onClickCallback, getValCallback)
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("TOPLEFT", parent, "TOPLEFT", 12, yOfs)
    label:SetText(labelText)
    label:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
    
    local rates = { 0.0, 0.5, 1.0, 1.5, 2.0 }
    local buttons = {}
    
    for i, r in ipairs(rates) do
        local btn = CreateFrame("Button", nil, parent)
        btn:SetSize(36, 18)
        btn:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + (i-1)*40, yOfs - 16)
        
        btn:SetBackdrop({
            bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
            edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
            tile = true, tileSize = 8, edgeSize = 8,
            insets = { left = 1, right = 1, top = 1, bottom = 1 }
        })
        btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
        
        local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("CENTER")
        text:SetText(FormatRate(r) .. "x")
        btn.text = text
        
        btn:SetScript("OnClick", function()
            onClickCallback(r)
        end)
        
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(CLR.btnHover[1], CLR.btnHover[2], CLR.btnHover[3], 1)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.8)
        end)
        
        buttons[r] = btn
        tinsert(restedPresets, { btn = btn, val = r, getVal = getValCallback })
    end
    
    -- Custom EditBox
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetSize(38, 18)
    edit:SetPoint("TOPLEFT", parent, "TOPLEFT", 12 + 5*40, yOfs - 16)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetJustifyH("CENTER")
    edit:SetMaxLetters(4)
    edit:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 8, edgeSize = 8,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    edit:SetBackdropColor(0.02, 0.03, 0.06, 0.85)
    edit:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
    
    local function UpdateRowUI()
        local currentVal = getValCallback()
        local matched = false
        
        for r, btn in pairs(buttons) do
            if math.abs(currentVal - r) < 0.005 then
                local rc = RateColor(r)
                btn:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.9)
                btn.text:SetTextColor(rc[1], rc[2], rc[3])
                matched = true
            else
                btn:SetBackdropBorderColor(CLR.btnEdge[1], CLR.btnEdge[2], CLR.btnEdge[3], 0.6)
                btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
            end
        end
        
        if not edit:HasFocus() then
            edit:SetText(FormatRate(currentVal))
            if matched then
                edit:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
                edit:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
            else
                local rc = RateColor(currentVal)
                edit:SetBackdropBorderColor(rc[1], rc[2], rc[3], 0.9)
                edit:SetTextColor(rc[1], rc[2], rc[3])
            end
        end
    end
    
    edit:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
    end)
    
    edit:SetScript("OnEscapePressed", function(self)
        self.reverting = true
        self:SetText(FormatRate(getValCallback()))
        self:ClearFocus()
    end)
    
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    edit:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
        if self.reverting then
            self.reverting = nil
            UpdateRowUI()
            return
        end
        local val = tonumber(self:GetText())
        if val then
            onClickCallback(val)
        else
            UpdateRowUI()
        end
    end)
    
    edit:SetScript("OnEnter", function(self)
        ShowTooltip(self, "Type a custom rate and press Enter")
    end)
    edit:SetScript("OnLeave", HideTooltip)
    
    return UpdateRowUI
end

updateRestedRow = CreateRestedPresetRow(AutomationTabFrame, "🛏 When Rested", -52, 
    function(val)
        XPRateControlDB.restedRate = ClampRate(val)
        SaveActiveProfileSettings()
        ShowToast("Rested Rate updated \226\156\147", false)
        lastRestedState = nil
        EvaluateRules()
    end,
    function()
        return XPRateControlDB and XPRateControlDB.restedRate or 2.0
    end
)

updateNormalRow = CreateRestedPresetRow(AutomationTabFrame, "⚔ When Normal", -90, 
    function(val)
        XPRateControlDB.normalRate = ClampRate(val)
        SaveActiveProfileSettings()
        ShowToast("Normal Rate updated \226\156\147", false)
        lastRestedState = nil
        EvaluateRules()
    end,
    function()
        return XPRateControlDB and XPRateControlDB.normalRate or 1.0
    end
)

-- Context Rules Builder
local contextSectionLine = AutomationTabFrame:CreateTexture(nil, "ARTWORK")
contextSectionLine:SetPoint("TOPLEFT", AutomationTabFrame, "TOPLEFT", 10, -128)
contextSectionLine:SetPoint("TOPRIGHT", AutomationTabFrame, "TOPRIGHT", -10, -128)
contextSectionLine:SetHeight(1)
contextSectionLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
contextSectionLine:SetVertexColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.4)

local contextHeader = AutomationTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
contextHeader:SetPoint("TOPLEFT", contextSectionLine, "BOTTOMLEFT", 2, -4)
contextHeader:SetText("CONTEXT AUTO-RATES")
contextHeader:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

local function CreateContextRow(parent, labelText, xOfs, getVal, setVal, getEnabled, setEnabled)
    local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    cb:SetSize(18, 18)
    cb:SetPoint("TOPLEFT", parent, "TOPLEFT", xOfs, -150)
    
    local label = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", cb, "RIGHT", 4, 0)
    label:SetText(labelText)
    label:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
    
    local edit = CreateFrame("EditBox", nil, parent)
    edit:SetSize(32, 16)
    edit:SetPoint("LEFT", label, "RIGHT", 4, 0)
    edit:SetAutoFocus(false)
    edit:SetFontObject("GameFontHighlightSmall")
    edit:SetJustifyH("CENTER")
    edit:SetMaxLetters(4)
    edit:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 6, edgeSize = 6,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    edit:SetBackdropColor(0.02, 0.03, 0.06, 0.85)
    edit:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
    
    local function UpdateUI()
        cb:SetChecked(getEnabled())
        if not edit:HasFocus() then
            edit:SetText(FormatRate(getVal()))
        end
    end
    
    cb:SetScript("OnClick", function(self)
        setEnabled(self:GetChecked() == 1)
        SaveActiveProfileSettings()
        EvaluateRules()
        ShowToast("Rules updated \226\156\147", false)
    end)
    
    edit:SetScript("OnEditFocusGained", function(self)
        self:SetBackdropBorderColor(CLR.cyan[1], CLR.cyan[2], CLR.cyan[3], 0.9)
    end)
    
    edit:SetScript("OnEscapePressed", function(self)
        self.reverting = true
        self:SetText(FormatRate(getVal()))
        self:ClearFocus()
    end)
    
    edit:SetScript("OnEnterPressed", function(self)
        self:ClearFocus()
    end)
    
    edit:SetScript("OnEditFocusLost", function(self)
        self:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.6)
        if self.reverting then
            self.reverting = nil
            UpdateUI()
            return
        end
        local val = tonumber(self:GetText())
        if val then
            setVal(ClampRate(val))
            SaveActiveProfileSettings()
            EvaluateRules()
            ShowToast("Rules updated \226\156\147", false)
        else
            UpdateUI()
        end
    end)
    
    edit:SetScript("OnEnter", function(self)
        ShowTooltip(self, "Type a custom rate and press Enter")
    end)
    edit:SetScript("OnLeave", HideTooltip)
    
    return UpdateUI
end

updateDungeonRow = CreateContextRow(AutomationTabFrame, "🏰 DG:", 10,
    function() return XPRateControlDB and XPRateControlDB.dungeonRate or 1.5 end,
    function(val) XPRateControlDB.dungeonRate = val end,
    function() return XPRateControlDB and XPRateControlDB.dungeonEnabled or false end,
    function(val) XPRateControlDB.dungeonEnabled = val end
)

updateBgRow = CreateContextRow(AutomationTabFrame, "⚔ PvP:", 112,
    function() return XPRateControlDB and XPRateControlDB.bgRate or 1.0 end,
    function(val) XPRateControlDB.bgRate = val end,
    function() return XPRateControlDB and XPRateControlDB.bgEnabled or false end,
    function(val) XPRateControlDB.bgEnabled = val end
)

updateCityRow = CreateContextRow(AutomationTabFrame, "💤 Inn:", 214,
    function() return XPRateControlDB and XPRateControlDB.cityRate or 0.5 end,
    function(val) XPRateControlDB.cityRate = val end,
    function() return XPRateControlDB and XPRateControlDB.cityEnabled or false end,
    function(val) XPRateControlDB.cityEnabled = val end
)

-- Rules Backend Frame
local restedBackendFrame = CreateFrame("Frame")
restedBackendFrame:RegisterEvent("UPDATE_EXHAUSTION")
restedBackendFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
restedBackendFrame:RegisterEvent("ZONE_CHANGED_NEW_AREA")
restedBackendFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
restedBackendFrame:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_REGEN_ENABLED" then
        if queuedRate then
            local r = queuedRate
            queuedRate = nil
            ApplyRate(r, false)
        else
            EvaluateRules()
        end
    elseif event == "PLAYER_ENTERING_WORLD" then
        EvaluateRules()
    else
        EvaluateRules()
    end
end)

------------------------------------------------------------
-- Tab 3: Buffs (Joyous Journeys) UI Creation
------------------------------------------------------------
CreateSectionHeader(BuffsTabFrame, "JOYOUS JOURNEYS", "Interface\\Icons\\Achievement_Quests_Completed_07", CLR.gold)

local jjDesc = BuffsTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
jjDesc:SetPoint("TOPLEFT", BuffsTabFrame, "TOPLEFT", 12, -30)
jjDesc:SetText("50% XP buff for characters below max level")
jjDesc:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])

-- Visual Card Hero
local jjCard = CreateFrame("Frame", nil, BuffsTabFrame)
jjCard:SetSize(288, 80)
jjCard:SetPoint("TOP", BuffsTabFrame, "TOP", 0, -48)
jjCard:SetBackdrop({
    bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 10, edgeSize = 10,
    insets = { left = 2, right = 2, top = 2, bottom = 2 }
})
jjCard:SetBackdropColor(0.02, 0.03, 0.05, 0.9)
jjCard:SetBackdropBorderColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.6)

local jjIcon = jjCard:CreateTexture(nil, "ARTWORK")
jjIcon:SetSize(36, 36)
jjIcon:SetPoint("CENTER", jjCard, "CENTER", 0, 10)
jjIcon:SetTexture("Interface\\Icons\\Achievement_Quests_Completed_07")

local jjStatusText = jjCard:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
jjStatusText:SetPoint("TOP", jjIcon, "BOTTOM", 0, -6)
jjStatusText:SetText("BUFF INACTIVE")

local jjCheckbox = CreateFrame("CheckButton", "XPRateJJCheckbox", BuffsTabFrame, "UICheckButtonTemplate")
jjCheckbox:SetSize(22, 22)
jjCheckbox:SetPoint("TOPLEFT", jjCard, "BOTTOMLEFT", 4, -10)

local jjCheckLabel = BuffsTabFrame:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
jjCheckLabel:SetPoint("LEFT", jjCheckbox, "RIGHT", 6, 0)
jjCheckLabel:SetText("Enable Joyous Journeys Buff")
jjCheckLabel:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])

function UpdateJJUI(enabled)
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
        jjCard:SetBackdropBorderColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.6)
        jjStatusText:SetText("BUFF INACTIVE")
        jjStatusText:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])
    end
end

jjCheckbox:SetScript("OnClick", function(self)
    local enabled = (self:GetChecked() == 1)
    SendJJCommand(enabled)
    XPRateControlDB.jjEnabled = enabled
    SaveActiveProfileSettings()
    UpdateJJUI(enabled)
    ShowToast(enabled and "JJ Enabled \226\156\147" or "JJ Disabled \226\156\147", false)
    PrintMessage("Joyous Journeys " .. (enabled and "|cff20cc50enabled|r" or "|cffcc3535disabled|r"))
end)

jjCheckbox:SetScript("OnEnter", function(self)
    ShowTooltip(self, "Toggle the Joyous Journeys 50% XP buff on the server")
end)
jjCheckbox:SetScript("OnLeave", HideTooltip)

------------------------------------------------------------
-- Navigation Tab Bar
------------------------------------------------------------
local tabButtons = {}
local tabNames = { "Rates", "Automation", "Buffs" }
local tabIcons = {
    "Interface\\Icons\\INV_Misc_Experience_01",
    "Interface\\Icons\\Spell_Holy_Restoration",
    "Interface\\Icons\\Achievement_Quests_Completed_07"
}

local function SetActiveTab(index)
    for i, btn in ipairs(tabButtons) do
        if i == index then
            btn:SetBackdropColor(CLR.btnBg[1], CLR.btnBg[2], CLR.btnBg[3], 0.95)
            btn:SetBackdropBorderColor(tabColors[i][1], tabColors[i][2], tabColors[i][3], 0.9)
            btn.text:SetTextColor(CLR.white[1], CLR.white[2], CLR.white[3])
            btn.icon:SetVertexColor(1, 1, 1, 1)
            tabFrames[i]:Show()
        else
            btn:SetBackdropColor(CLR.panelBg[1], CLR.panelBg[2], CLR.panelBg[3], 0.6)
            btn:SetBackdropBorderColor(CLR.muted[1], CLR.muted[2], CLR.muted[3], 0.4)
            btn.text:SetTextColor(CLR.dim[1], CLR.dim[2], CLR.dim[3])
            btn.icon:SetVertexColor(0.6, 0.6, 0.6, 0.7)
            tabFrames[i]:Hide()
        end
    end
    
    toast:Hide()
    
    if index == 2 then
        updateRestedRow()
        updateNormalRow()
        updateDungeonRow()
        updateBgRow()
        updateCityRow()
        UpdateAutomationStatus()
        if XPRateProfileButtonWidget then
            XPRateProfileButtonWidget:SetText("Profile: " .. XPRateControlDB.currentProfile)
        end
    end
end

for i = 1, 3 do
    local btn = CreateFrame("Button", nil, frame)
    btn:SetSize(98, 24)
    btn:SetPoint("TOPLEFT", frame, "TOPLEFT", 10 + (i-1)*101, -38)
    
    btn:SetBackdrop({
        bgFile = "Interface\\ChatFrame\\ChatFrameBackground",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = true, tileSize = 10, edgeSize = 10,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    
    local highlight = btn:CreateTexture(nil, "HIGHLIGHT")
    highlight:SetAllPoints()
    highlight:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
    highlight:SetGradientAlpha("HORIZONTAL", 1, 1, 1, 0.05, 1, 1, 1, 0.1)
    highlight:SetBlendMode("ADD")
    
    local icon = btn:CreateTexture(nil, "ARTWORK")
    icon:SetSize(12, 12)
    icon:SetPoint("LEFT", btn, "LEFT", 6, 0)
    icon:SetTexture(tabIcons[i])
    btn.icon = icon
    
    local text = btn:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    text:SetPoint("LEFT", icon, "RIGHT", 4, 0)
    text:SetText(tabNames[i])
    btn.text = text
    
    btn:SetScript("OnClick", function()
        SetActiveTab(i)
    end)
    
    tabButtons[i] = btn
end

------------------------------------------------------------
-- Footer bevel line and instructions
------------------------------------------------------------
local footerLine = frame:CreateTexture(nil, "ARTWORK")
footerLine:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 10, 28)
footerLine:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -10, 28)
footerLine:SetHeight(1)
footerLine:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
footerLine:SetVertexColor(CLR.panelEdge[1], CLR.panelEdge[2], CLR.panelEdge[3], 0.6)

local footerLine2 = frame:CreateTexture(nil, "ARTWORK")
footerLine2:SetPoint("TOPLEFT", footerLine, "BOTTOMLEFT", 0, -1)
footerLine2:SetPoint("TOPRIGHT", footerLine, "BOTTOMRIGHT", 0, -1)
footerLine2:SetHeight(1)
footerLine2:SetTexture("Interface\\ChatFrame\\ChatFrameBackground")
footerLine2:SetVertexColor(0, 0, 0, 0.8)

local footer = frame:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
footer:SetPoint("BOTTOM", frame, "BOTTOM", 0, 8)
footer:SetText("Drag title bar to move \226\148\140 ESC to close")
footer:SetTextColor(CLR.muted[1], CLR.muted[2], CLR.muted[3])

------------------------------------------------------------
-- Minimap Button
------------------------------------------------------------
local minimapButton = CreateFrame("Button", "XPRateMinimapButton", Minimap)
minimapButton:SetSize(31, 31)
minimapButton:SetFrameStrata("HIGH")
minimapButton:SetFrameLevel(20)

local background = minimapButton:CreateTexture("XPRateMinimapButtonBackground", "BACKGROUND")
background:SetSize(21, 21)
background:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
background:SetTexture("Interface/Minimap/UI-Minimap-Background")

minimapButton.icon = minimapButton:CreateTexture("XPRateMinimapButtonIcon", "BORDER")
minimapButton.icon:SetSize(20, 20)
minimapButton.icon:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
minimapButton.icon:SetTexture("Interface/Icons/inv_misc_hourglass_01")
minimapButton.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

local border = minimapButton:CreateTexture("XPRateMinimapButtonBorder", "ARTWORK")
border:SetSize(53, 53)
border:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
border:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")

local highlight = minimapButton:CreateTexture("XPRateMinimapButtonHighlight", "HIGHLIGHT")
highlight:SetSize(31, 31)
highlight:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
highlight:SetTexture("Interface/Minimap/UI-Minimap-ZoomButton-Highlight")

-- Glow ring (animated pulse for "active" feel)
local glowTex = minimapButton:CreateTexture(nil, "OVERLAY")
glowTex:SetSize(42, 42)
glowTex:SetPoint("CENTER", minimapButton, "CENTER", 0, 0)
glowTex:SetTexture("Interface/Minimap/MiniMap-TrackingBorder")
glowTex:SetAlpha(0)

local glowElapsed = 0
local glowUpdater = CreateFrame("Frame", nil, minimapButton)
glowUpdater:SetScript("OnUpdate", function(self, elapsed)
    glowElapsed = glowElapsed + elapsed
    local alpha = 0.15 + 0.15 * math.sin(glowElapsed * 2.5)
    glowTex:SetAlpha(alpha)
end)

local function UpdateMinimapButtonPosition()
    local angle = XPRateControlDB and XPRateControlDB.minimapPos or DEFAULT_MINIMAP_ANGLE
    local x = MINIMAP_RADIUS * math.cos(math.rad(angle))
    local y = MINIMAP_RADIUS * math.sin(math.rad(angle))
    minimapButton:ClearAllPoints()
    minimapButton:SetPoint("CENTER", Minimap, "CENTER", x, y)
    minimapButton:SetFrameStrata("HIGH")
    minimapButton:SetFrameLevel(20)
end

minimapButton:RegisterForDrag("LeftButton")
minimapButton.dragging = false

minimapButton:SetScript("OnDragStart", function(self)
    self.dragging = true
    self:SetScript("OnUpdate", function(self)
        local cx, cy = GetCursorPosition()
        local mx, my = Minimap:GetCenter()
        local scale = Minimap:GetEffectiveScale()
        if mx and my and scale then
            local x = cx - (mx * scale)
            local y = cy - (my * scale)
            local angle = math.deg(math.atan2(y, x))
            if angle < 0 then angle = angle + 360 end
            XPRateControlDB.minimapPos = angle
            UpdateMinimapButtonPosition()
        end
    end)
end)

minimapButton:SetScript("OnDragStop", function(self)
    self.dragging = false
    self:SetScript("OnUpdate", nil)
end)

minimapButton:RegisterForClicks("LeftButtonUp", "RightButtonUp")

local dropdownMenu = {
    { text = "XP Rate Control", isTitle = true, notCheckable = true },
    { text = "0x (Off)",         func = function() ApplyRate(0)   end, notCheckable = true },
    { text = "0.5x",            func = function() ApplyRate(0.5) end, notCheckable = true },
    { text = "1x (Blizzlike)",  func = function() ApplyRate(1.0) end, notCheckable = true },
    { text = "1.5x",            func = function() ApplyRate(1.5) end, notCheckable = true },
    { text = "2x (Maximum)",    func = function() ApplyRate(2.0) end, notCheckable = true },
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

------------------------------------------------------------
-- Confirmation Listener Frame & Timeout
------------------------------------------------------------
local confirmationFrame = CreateFrame("Frame")
confirmationFrame:RegisterEvent("CHAT_MSG_SYSTEM")
confirmationFrame:SetScript("OnEvent", function(self, event, msg)
    if event == "CHAT_MSG_SYSTEM" and isAwaitingConfirmation then
        if MatchSuccessMessage(msg, pendingRate) then
            isAwaitingConfirmation = false
            XPRateControlDB.lastRate = pendingRate
            
            local rc = RateColor(pendingRate)
            if XPRateSliderWidget then
                UpdateUIFromValue(pendingRate)
            end
            if XPRateMinimapButtonIcon then
                XPRateMinimapButtonIcon:SetVertexColor(rc[1], rc[2], rc[3])
            end
            
            ShowToast(string.format("Applied %sx \226\156\147", FormatRate(pendingRate)), false)
            PrintMessage("XP rate set to " .. FormatRate(pendingRate) .. "x (Server Confirmed)")
            UpdateAutomationStatus()
        elseif MatchErrorMessage(msg) then
            isAwaitingConfirmation = false
            local lastRate = XPRateControlDB.lastRate or DEFAULT_RATE
            if XPRateSliderWidget then
                UpdateUIFromValue(lastRate)
            end
            ShowToast("Server Rejected \226\156\151", true)
            PrintMessage("XP rate revert. Server rejected command.")
        end
    end
end)

local confirmationTimeoutFrame = CreateFrame("Frame")
local timeoutElapsed = 0
confirmationTimeoutFrame:SetScript("OnUpdate", function(self, elapsed)
    if isAwaitingConfirmation then
        timeoutElapsed = timeoutElapsed + elapsed
        if timeoutElapsed > 2.0 then
            isAwaitingConfirmation = false
            timeoutElapsed = 0
            local lastRate = XPRateControlDB.lastRate or DEFAULT_RATE
            if XPRateSliderWidget then
                UpdateUIFromValue(lastRate)
            end
            ShowToast("Sync Timeout \226\156\151", true)
            PrintMessage("XP rate revert. Server response timed out.")
        end
    else
        timeoutElapsed = 0
    end
end)

function ApplyRate(rate, silent)
    rate = ClampRate(tonumber(rate) or DEFAULT_RATE)
    
    if UnitAffectingCombat("player") then
        queuedRate = rate
        if not silent then
            ShowToast(string.format("Pending: %sx (Combat) \226\143\179", FormatRate(rate)), false)
        end
        return
    end

    SendXPCommand(rate)
    
    pendingRate = rate
    pendingTime = GetTime()
    isAwaitingConfirmation = true
    
    if not silent then
        ShowToast(string.format("Sent %sx...", FormatRate(rate)), false)
    end
end

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
    if db.firstRun    == nil then db.firstRun    = true end

    -- Initialize Profile Database
    if not db.profiles then
        db.profiles = {
            ["Default"] = {
                autoRested = false,
                restedRate = 2.0,
                normalRate = 1.0,
                jjEnabled = true,
                dungeonRate = 1.5,
                dungeonEnabled = false,
                bgRate = 1.0,
                bgEnabled = false,
                cityRate = 0.5,
                cityEnabled = false,
            }
        }
    end
    if not db.currentProfile then
        db.currentProfile = "Default"
    end

    -- Position restoration
    if db.framePos then
        frame:ClearAllPoints()
        frame:SetPoint(db.framePos.point, UIParent, db.framePos.relativePoint, db.framePos.xOfs, db.framePos.yOfs)
    else
        frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end

    -- Load active profile (syncs profile to DB variables)
    LoadProfile(db.currentProfile)

    -- Force override values to DB states
    UpdateUIFromValue(db.lastRate)
    UpdateJJUI(db.jjEnabled)
    restedCheckbox:SetChecked(db.autoRested)
    
    updateRestedRow()
    updateNormalRow()
    updateDungeonRow()
    updateBgRow()
    updateCityRow()
    UpdateAutomationStatus()
    UpdateMinimapButtonPosition()

    if db.lastRate and minimapButton.icon then
        local rc = RateColor(db.lastRate)
        minimapButton.icon:SetVertexColor(rc[1], rc[2], rc[3])
    end

    if db.showMinimap then
        minimapButton:Show()
    else
        minimapButton:Hide()
    end

    SetActiveTab(1)

    -- First load banner
    if db.firstRun then
        PrintMessage("Welcome to XP Rate Control v1.2!")
        PrintMessage("  - Profile switcher and context rules are available on Tab 2.")
        PrintMessage("  - Click minimap hourglass icon to toggle settings panel.")
        PrintMessage("  - Changes are validated with the server instantly.")
        db.firstRun = false
    else
        PrintMessage("Loaded. Type |cff00ff00/xp|r to open, |cff00ff00/xp help|r for commands.")
    end

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

    ApplyRate(val)
end
