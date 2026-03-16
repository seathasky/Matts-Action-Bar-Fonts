local addonName, MABF = ...

local function SaveOptionsFramePosition(frame)
    if not frame or not MattActionBarFontDB or not frame.GetCenter then return end
    local centerX, centerY = frame:GetCenter()
    if not centerX or not centerY then return end

    local parentScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    MattActionBarFontDB.optionsFramePos = {
        mode = "screenCenter",
        x = centerX * parentScale,
        y = centerY * parentScale,
    }
end

local function RestoreOptionsFramePosition(frame)
    frame:ClearAllPoints()
    local pos = MattActionBarFontDB and MattActionBarFontDB.optionsFramePos
    if type(pos) == "table" and pos.mode == "screenCenter" and tonumber(pos.x) and tonumber(pos.y) then
        local parentScale = UIParent:GetEffectiveScale() or 1
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / parentScale, pos.y / parentScale)
        return
    end
    frame:SetPoint("CENTER")
end

function MABF:BuildOptionsWindowShell()
    local f = CreateFrame("Frame", "MABFOptionsFrame", UIParent, "BackdropTemplate")
    self.optionsFrame = f
    self.optionsUI = self.optionsUI or {}
    local ui = self.optionsUI
    ui.frame = f

    f:Hide()
    f:SetSize(420, 580)
    f:SetClampedToScreen(true)
    RestoreOptionsFramePosition(f)
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SaveOptionsFramePosition(self)
        RestoreOptionsFramePosition(self)
    end)
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    f:SetBackdropColor(0.04, 0.04, 0.05, 0.98)
    f:SetBackdropBorderColor(0.1, 0.1, 0.12, 1)

    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
    title:SetText("MABF")
    title:SetTextColor(1, 1, 1)
    title:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 14, "OUTLINE")

    local taglines = {
        "\"I swear it was just a font addon at first.\"",
        "\"It started with fonts. Then I got ideas.\"",
        "\"Fonts today, auto-repair tomorrow.\"",
        "\"One slider led to another.\"",
        "\"Now with 90% more things that aren't fonts.\"",
        "\"All I wanted was bigger hotkey text.\"",
        "\"Probably a feature, not a bug.\"",
        "\"From Comic Sans to auto-sell junk, somehow.\"",
        "\"Proudly over-engineered since day one.\"",
        "\"Mr_Dishonored told me to do it!\"",
    }
    local tagline = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tagline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    tagline:SetText("|cff666666" .. taglines[math.random(#taglines)] .. "|r")
    tagline:SetFont("Fonts\\FRIZQT__.TTF", 8)

    local fullName = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fullName:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 6)
    fullName:SetText("|cffFFFFFFMatt's Action Bar Fonts & UI QoL|r")
    fullName:SetFont("Fonts\\FRIZQT__.TTF", 7)

    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetSize(100, 510)
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -45)
    leftPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    leftPanel:SetBackdropColor(0.08, 0.08, 0.1, 1)
    leftPanel:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local rightPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rightPanel:SetSize(295, 510)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 6, 0)
    rightPanel:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile = false,
        tileSize = 0,
        edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    rightPanel:SetBackdropColor(0.08, 0.08, 0.1, 1)
    rightPanel:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local THEME_ACCENT = (MABF.GetThemeAccentColor and MABF:GetThemeAccentColor()) or { 1.0, 0.25, 0.25 }
    local TAB_PALETTE = (MABF.GetTabPalette and MABF:GetTabPalette()) or {
        normal = { 0.06, 0.06, 0.08, 1 },
        selected = { 0.12, 0.12, 0.15, 1 },
        border = { 0.18, 0.18, 0.22, 1 },
        textNormal = { 0.7, 0.7, 0.7, 1 },
        textActive = { 1, 1, 1, 1 },
    }
    local MABF_FONT = (MABF.GetUIFontPath and MABF:GetUIFontPath()) or "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"

    local function CreateMinimalCloseButton(parent)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(22, 22)
        btn:SetPoint("TOPRIGHT", parent, "TOPRIGHT", -7, -7)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

        local label = btn:CreateFontString(nil, "OVERLAY")
        label:SetPoint("CENTER", 0, 0)
        label:SetFont(MABF_FONT, 12, "OUTLINE")
        label:SetText("X")
        label:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
        btn._mabfLabel = label

        btn:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.85)
        end)
        btn:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            self:SetBackdropColor(0.06, 0.06, 0.08, 1)
        end)
        btn:SetScript("OnMouseDown", function(self)
            self:SetBackdropColor(0.04, 0.04, 0.06, 1)
        end)
        btn:SetScript("OnMouseUp", function(self)
            self:SetBackdropColor(0.06, 0.06, 0.08, 1)
        end)
        btn:SetScript("OnClick", function()
            parent:Hide()
        end)
        return btn
    end

    local closeButton = CreateMinimalCloseButton(f)
    ui.closeButton = closeButton

    local function ClampGUIScale(value)
        local scale = tonumber(value)
        if type(scale) ~= "number" or scale ~= scale or scale == math.huge or scale == -math.huge then
            return 1.0
        end
        if scale < 0.5 then
            scale = 0.5
        elseif scale > 1.5 then
            scale = 1.5
        end
        return math.floor(scale * 10 + 0.5) / 10
    end

    MattActionBarFontDB = MattActionBarFontDB or {}

    local function ApplyGUIScale(scale)
        local normalized = ClampGUIScale(scale)
        MattActionBarFontDB.guiScale = normalized
        f:SetScale(normalized)
        SaveOptionsFramePosition(f)
        return normalized
    end

    local guiScaleContainer = CreateFrame("Frame", nil, f)
    guiScaleContainer:SetSize(134, 24)
    guiScaleContainer:SetPoint("TOPRIGHT", closeButton, "TOPLEFT", -14, -1)

    local scaleLabel = guiScaleContainer:CreateFontString(nil, "OVERLAY")
    scaleLabel:SetFont(MABF_FONT, 9, "")
    scaleLabel:SetPoint("LEFT", guiScaleContainer, "LEFT", 0, 0)
    scaleLabel:SetTextColor(0.8, 0.8, 0.8, 1)
    scaleLabel:SetText("Scale")
    scaleLabel:SetWidth(35)
    scaleLabel:SetJustifyH("LEFT")

    local scaleValueBg = CreateFrame("Frame", nil, guiScaleContainer, "BackdropTemplate")
    scaleValueBg:SetSize(36, 18)
    scaleValueBg:SetPoint("RIGHT", guiScaleContainer, "RIGHT", 0, 0)
    scaleValueBg:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    scaleValueBg:SetBackdropColor(0.06, 0.06, 0.08, 1)
    scaleValueBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local scaleValue = CreateFrame("EditBox", nil, scaleValueBg)
    scaleValue:SetAllPoints(scaleValueBg)
    scaleValue:SetAutoFocus(false)
    scaleValue:SetFont(MABF_FONT, 9, "")
    scaleValue:SetJustifyH("CENTER")
    scaleValue:SetJustifyV("MIDDLE")
    scaleValue:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    local guiScaleSlider = CreateFrame("Slider", nil, guiScaleContainer, "BackdropTemplate")
    guiScaleSlider:SetSize(48, 8)
    guiScaleSlider:SetPoint("LEFT", guiScaleContainer, "LEFT", 38, 0)
    guiScaleSlider:SetOrientation("HORIZONTAL")
    guiScaleSlider:SetMinMaxValues(0.5, 1.5)
    guiScaleSlider:SetValueStep(0.1)
    guiScaleSlider:SetObeyStepOnDrag(true)

    local guiScaleTrack = CreateFrame("Frame", nil, guiScaleSlider, "BackdropTemplate")
    guiScaleTrack:SetPoint("CENTER", guiScaleSlider, "CENTER", 0, 0)
    guiScaleTrack:SetSize(48, 8)
    guiScaleTrack:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    guiScaleTrack:SetBackdropColor(0.06, 0.06, 0.08, 1)
    guiScaleTrack:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    guiScaleSlider._mabfTrack = guiScaleTrack

    local guiScaleFill = guiScaleTrack:CreateTexture(nil, "ARTWORK")
    guiScaleFill:SetPoint("LEFT", guiScaleTrack, "LEFT", 0, 0)
    guiScaleFill:SetHeight(8)
    guiScaleFill:SetColorTexture(THEME_ACCENT[1] * 0.5, THEME_ACCENT[2] * 0.5, THEME_ACCENT[3] * 0.6, 0.85)
    guiScaleSlider._mabfFill = guiScaleFill

    local guiScaleThumb = guiScaleSlider:CreateTexture(nil, "OVERLAY")
    guiScaleThumb:SetSize(6, 12)
    guiScaleThumb:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
    guiScaleSlider:SetThumbTexture(guiScaleThumb)

    local currentScale = ApplyGUIScale(MattActionBarFontDB.guiScale or 1.0)
    guiScaleSlider:SetValue(currentScale)
    scaleValue:SetText(string.format("%.1f", currentScale))

    scaleValueBg:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
    end)
    scaleValueBg:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    scaleValue:SetScript("OnEnterPressed", function(self)
        local num = tonumber(self:GetText())
        if not num then
            self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
            self:ClearFocus()
            return
        end
        num = ApplyGUIScale(num)
        guiScaleSlider:SetValue(num)
        self:SetText(string.format("%.1f", num))
        self:ClearFocus()
    end)
    scaleValue:SetScript("OnEscapePressed", function(self)
        self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
        self:ClearFocus()
    end)
    scaleValue:SetScript("OnEditFocusLost", function(self)
        self:SetText(string.format("%.1f", guiScaleSlider:GetValue()))
    end)

    local function UpdateGUIScaleFill()
        local minV, maxV = guiScaleSlider:GetMinMaxValues()
        local val = guiScaleSlider:GetValue()
        local pct = 0
        if maxV and minV and maxV > minV then
            pct = (val - minV) / (maxV - minV)
        end
        guiScaleSlider._mabfFill:SetWidth(math.max(1, guiScaleSlider._mabfTrack:GetWidth() * pct))
    end
    UpdateGUIScaleFill()

    guiScaleSlider:SetScript("OnValueChanged", function(self, value)
        value = ClampGUIScale(value)
        scaleValue:SetText(string.format("%.1f", value))
        UpdateGUIScaleFill()
    end)
    guiScaleSlider:SetScript("OnMouseUp", function()
        local value = ClampGUIScale(guiScaleSlider:GetValue())
        value = ApplyGUIScale(value)
        guiScaleSlider:SetValue(value)
        scaleValue:SetText(string.format("%.1f", value))
    end)
    guiScaleSlider:SetScript("OnEnter", function()
        guiScaleSlider._mabfTrack:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
    end)
    guiScaleSlider:SetScript("OnLeave", function()
        guiScaleSlider._mabfTrack:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    f:HookScript("OnShow", function(self)
        local value = ApplyGUIScale(MattActionBarFontDB.guiScale or 1.0)
        guiScaleSlider:SetValue(value)
        scaleValue:SetText(string.format("%.1f", value))
    end)

    return {
        frame = f,
        leftPanel = leftPanel,
        rightPanel = rightPanel,
        themeAccent = THEME_ACCENT,
        tabBorder = TAB_PALETTE.border,
        tabTextNormal = TAB_PALETTE.textNormal,
        fontPath = MABF_FONT,
    }
end
