local addonName, MABF = ...

-- Builds the Action Bars > Offsets options page UI.
function MABF:BuildActionBarOffsetsPage(opts)
    if type(opts) ~= "table" then return nil end

    local CreateContentPage = opts.CreateContentPage
    local CreatePageTitle = opts.CreatePageTitle
    local StyleSlider = opts.StyleSlider
    if not CreateContentPage or not CreatePageTitle or not StyleSlider then
        return nil
    end
    local THEME_ACCENT = MABF:GetThemeAccentColor()

    local pageOffsets = CreateContentPage(2)
    local abOffsetsLabel = CreatePageTitle(pageOffsets, "AB Offsets")

    local abXOffsetSlider = CreateFrame("Slider", "MABFABXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abXOffsetSlider:SetSize(260, 14)
    abXOffsetSlider:SetPoint("TOPLEFT", abOffsetsLabel, "BOTTOMLEFT", 0, -18)
    abXOffsetSlider:SetMinMaxValues(-100, 100)
    abXOffsetSlider:SetValue(MattActionBarFontDB.abXOffset)
    abXOffsetSlider:SetValueStep(1)
    abXOffsetSlider:SetObeyStepOnDrag(true)
    local abXSliderName = abXOffsetSlider:GetName()
    _G[abXSliderName .. "Low"]:SetText("-100")
    _G[abXSliderName .. "High"]:SetText("100")
    _G[abXSliderName .. "Text"]:SetText("Action Bar Font X Offset: " .. MattActionBarFontDB.abXOffset)
    StyleSlider(abXOffsetSlider)
    abXOffsetSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetActionBarOffset("x", value)
        _G[abXSliderName .. "Text"]:SetText("Action Bar Font X Offset: " .. value)
    end)

    local abYOffsetSlider = CreateFrame("Slider", "MABFABYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abYOffsetSlider:SetSize(260, 14)
    abYOffsetSlider:SetPoint("TOPLEFT", abXOffsetSlider, "BOTTOMLEFT", 0, -22)
    abYOffsetSlider:SetMinMaxValues(-100, 100)
    abYOffsetSlider:SetValue(MattActionBarFontDB.abYOffset)
    abYOffsetSlider:SetValueStep(1)
    abYOffsetSlider:SetObeyStepOnDrag(true)
    local abYSliderName = abYOffsetSlider:GetName()
    _G[abYSliderName .. "Low"]:SetText("-100")
    _G[abYSliderName .. "High"]:SetText("100")
    _G[abYSliderName .. "Text"]:SetText("Action Bar Font Y Offset: " .. MattActionBarFontDB.abYOffset)
    StyleSlider(abYOffsetSlider)
    abYOffsetSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetActionBarOffset("y", value)
        _G[abYSliderName .. "Text"]:SetText("Action Bar Font Y Offset: " .. value)
    end)

    local extraOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    extraOffsetsLabel:SetPoint("TOPLEFT", abYOffsetSlider, "BOTTOMLEFT", 0, -28)
    extraOffsetsLabel:SetText("Extra Ability Offsets")
    extraOffsetsLabel:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    local extraXSlider = CreateFrame("Slider", "MABFExtraXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    extraXSlider:SetSize(260, 14)
    extraXSlider:SetPoint("TOPLEFT", extraOffsetsLabel, "BOTTOMLEFT", 0, -18)
    extraXSlider:SetMinMaxValues(-100, 100)
    extraXSlider:SetValue(MattActionBarFontDB.extraXOffset)
    extraXSlider:SetValueStep(1)
    extraXSlider:SetObeyStepOnDrag(true)
    local extraXName = extraXSlider:GetName()
    _G[extraXName .. "Low"]:SetText("-100")
    _G[extraXName .. "High"]:SetText("100")
    _G[extraXName .. "Text"]:SetText("Extra Ability Font X Offset: " .. MattActionBarFontDB.extraXOffset)
    StyleSlider(extraXSlider)
    extraXSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetExtraAbilityOffset("x", value)
        _G[extraXName .. "Text"]:SetText("Extra Ability Font X Offset: " .. value)
    end)

    local extraYSlider = CreateFrame("Slider", "MABFExtraYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    extraYSlider:SetSize(260, 14)
    extraYSlider:SetPoint("TOPLEFT", extraXSlider, "BOTTOMLEFT", 0, -22)
    extraYSlider:SetMinMaxValues(-100, 100)
    extraYSlider:SetValue(MattActionBarFontDB.extraYOffset)
    extraYSlider:SetValueStep(1)
    extraYSlider:SetObeyStepOnDrag(true)
    local extraYName = extraYSlider:GetName()
    _G[extraYName .. "Low"]:SetText("-100")
    _G[extraYName .. "High"]:SetText("100")
    _G[extraYName .. "Text"]:SetText("Extra Ability Font Y Offset: " .. MattActionBarFontDB.extraYOffset)
    StyleSlider(extraYSlider)
    extraYSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetExtraAbilityOffset("y", value)
        _G[extraYName .. "Text"]:SetText("Extra Ability Font Y Offset: " .. value)
    end)

    local countOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countOffsetsLabel:SetPoint("TOPLEFT", extraYSlider, "BOTTOMLEFT", 0, -28)
    countOffsetsLabel:SetText("Count Text Offsets")
    countOffsetsLabel:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    local xOffsetSlider = CreateFrame("Slider", "MABFXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    xOffsetSlider:SetSize(260, 14)
    xOffsetSlider:SetPoint("TOPLEFT", countOffsetsLabel, "BOTTOMLEFT", 0, -18)
    xOffsetSlider:SetMinMaxValues(-100, 100)
    xOffsetSlider:SetValue(MattActionBarFontDB.xOffset)
    xOffsetSlider:SetValueStep(1)
    xOffsetSlider:SetObeyStepOnDrag(true)
    local xSliderName = xOffsetSlider:GetName()
    _G[xSliderName .. "Low"]:SetText("-100")
    _G[xSliderName .. "High"]:SetText("100")
    _G[xSliderName .. "Text"]:SetText("Count Text X Offset: " .. MattActionBarFontDB.xOffset)
    StyleSlider(xOffsetSlider)
    xOffsetSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetCountTextOffset("x", value)
        _G[xSliderName .. "Text"]:SetText("Count Text X Offset: " .. value)
    end)

    local yOffsetSlider = CreateFrame("Slider", "MABFYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    yOffsetSlider:SetSize(260, 14)
    yOffsetSlider:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", 0, -22)
    yOffsetSlider:SetMinMaxValues(-100, 100)
    yOffsetSlider:SetValue(MattActionBarFontDB.yOffset)
    yOffsetSlider:SetValueStep(1)
    yOffsetSlider:SetObeyStepOnDrag(true)
    local ySliderName = yOffsetSlider:GetName()
    _G[ySliderName .. "Low"]:SetText("-100")
    _G[ySliderName .. "High"]:SetText("100")
    _G[ySliderName .. "Text"]:SetText("Count Text Y Offset: " .. MattActionBarFontDB.yOffset)
    StyleSlider(yOffsetSlider)
    yOffsetSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetCountTextOffset("y", value)
        _G[ySliderName .. "Text"]:SetText("Count Text Y Offset: " .. value)
    end)

    local resetOffsetsBtn = CreateFrame("Button", "MABFResetOffsetDefaultsBtn", pageOffsets, "BackdropTemplate")
    resetOffsetsBtn:SetSize(146, 20)
    resetOffsetsBtn:SetPoint("BOTTOMLEFT", pageOffsets, "BOTTOMLEFT", 12, 14)
    resetOffsetsBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    resetOffsetsBtn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    resetOffsetsBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local resetOffsetsBtnText = resetOffsetsBtn:CreateFontString(nil, "OVERLAY")
    resetOffsetsBtnText:SetPoint("CENTER", resetOffsetsBtn, "CENTER", 0, 0)
    resetOffsetsBtnText:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 9, "OUTLINE")
    resetOffsetsBtnText:SetText("Reset Position Defaults")
    resetOffsetsBtnText:SetTextColor(0.9, 0.9, 0.9, 1)

    resetOffsetsBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.8)
    end)
    resetOffsetsBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)
    resetOffsetsBtn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.04, 0.04, 0.06, 1)
    end)
    resetOffsetsBtn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)
    resetOffsetsBtn:SetScript("OnClick", function()
        MABF:ResetActionBarOffsetDefaults()
        local db = MattActionBarFontDB or {}

        abXOffsetSlider:SetValue(db.abXOffset or 0)
        abYOffsetSlider:SetValue(db.abYOffset or 0)
        extraXSlider:SetValue(db.extraXOffset or 0)
        extraYSlider:SetValue(db.extraYOffset or 0)
        xOffsetSlider:SetValue(db.xOffset or 0)
        yOffsetSlider:SetValue(db.yOffset or 0)

        MABF:ApplyAllActionBarOffsetSettings()
    end)

    return {
        page = pageOffsets,
    }
end
