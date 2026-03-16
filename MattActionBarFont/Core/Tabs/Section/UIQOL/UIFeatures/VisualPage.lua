local addonName, MABF = ...

-- Builds UI / QoL > UI Features > Visual controls.
function MABF:BuildUIFeaturesVisualPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageUIFeatures = opts.pageUIFeatures
    local anchorControl = opts.anchorControl
    local CreateMinimalDropdown = opts.CreateMinimalDropdown
    local StyleSlider = opts.StyleSlider

    if not pageUIFeatures or not anchorControl or not CreateMinimalDropdown or not StyleSlider then
        return nil
    end

    local cursorCircleCheck = CreateFrame("CheckButton", "MABFCursorCircleCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    cursorCircleCheck:ClearAllPoints()
    cursorCircleCheck:SetPoint("TOPLEFT", anchorControl, "BOTTOMLEFT", 0, -4)
    local cursorCircleText = _G[cursorCircleCheck:GetName() .. "Text"]
    cursorCircleText:SetText("Cursor Circle")
    cursorCircleText:SetTextColor(1, 1, 1)
    cursorCircleCheck:SetChecked(MattActionBarFontDB.enableCursorCircle)

    local cursorCircleColorLabel = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorCircleColorLabel:SetPoint("TOPLEFT", cursorCircleCheck, "BOTTOMLEFT", 26, -10)
    cursorCircleColorLabel:SetText("Color:")
    cursorCircleColorLabel:SetTextColor(0.8, 0.8, 0.8)

    local cursorCircleColorDropdown = CreateMinimalDropdown(pageUIFeatures, 130, 7)
    cursorCircleColorDropdown:SetPoint("LEFT", cursorCircleColorLabel, "RIGHT", 8, 0)

    local cursorCircleColorOptions = {
        { label = "Light Blue", value = "lightBlue" },
        { label = "White", value = "white" },
        { label = "Red", value = "red" },
        { label = "Green", value = "green" },
        { label = "Yellow", value = "yellow" },
        { label = "Blue", value = "blue" },
        { label = "Purple", value = "purple" },
    }

    local function GetCursorCircleColorValue()
        return MattActionBarFontDB.cursorCircleColor or "lightBlue"
    end

    cursorCircleColorDropdown:SetOptions(cursorCircleColorOptions)
    cursorCircleColorDropdown:SetSelectedValue(GetCursorCircleColorValue())
    cursorCircleColorDropdown:SetOnOpen(function(self)
        self:SetOptions(cursorCircleColorOptions)
        self:SetSelectedValue(GetCursorCircleColorValue())
    end)
    cursorCircleColorDropdown:SetOnSelect(function(value)
        MattActionBarFontDB.cursorCircleColor = value
        cursorCircleColorDropdown:SetSelectedValue(value)
        MABF:ApplyCursorCircleStyle()
    end)

    local cursorCircleScaleSlider = CreateFrame("Slider", "MABFCursorCircleScaleSlider", pageUIFeatures, "OptionsSliderTemplate")
    cursorCircleScaleSlider:SetWidth(140)
    cursorCircleScaleSlider:SetHeight(16)
    cursorCircleScaleSlider:SetPoint("TOPLEFT", cursorCircleColorLabel, "BOTTOMLEFT", -6, -42)
    cursorCircleScaleSlider:SetMinMaxValues(50, 200)
    cursorCircleScaleSlider:SetValueStep(5)
    cursorCircleScaleSlider:SetObeyStepOnDrag(true)
    _G[cursorCircleScaleSlider:GetName() .. "Low"]:SetText("50%")
    _G[cursorCircleScaleSlider:GetName() .. "High"]:SetText("200%")
    local cursorCircleScaleTitle = _G[cursorCircleScaleSlider:GetName() .. "Text"]
    cursorCircleScaleTitle:SetText("Size Scale: " .. math.floor((MattActionBarFontDB.cursorCircleScale or 1.0) * 100) .. "%")
    StyleSlider(cursorCircleScaleSlider)
    cursorCircleScaleSlider:SetValue((MattActionBarFontDB.cursorCircleScale or 1.0) * 100)
    cursorCircleScaleSlider:SetScript("OnValueChanged", function(self, value)
        local scale = value / 100
        MattActionBarFontDB.cursorCircleScale = scale
        _G[self:GetName() .. "Text"]:SetText("Size Scale: " .. math.floor(value) .. "%")
        MABF:ApplyCursorCircleScale()
    end)

    local cursorCircleOpacitySlider = CreateFrame("Slider", "MABFCursorCircleOpacitySlider", pageUIFeatures, "OptionsSliderTemplate")
    cursorCircleOpacitySlider:SetWidth(140)
    cursorCircleOpacitySlider:SetHeight(16)
    cursorCircleOpacitySlider:SetPoint("TOPLEFT", cursorCircleScaleSlider, "BOTTOMLEFT", 0, -42)
    cursorCircleOpacitySlider:SetMinMaxValues(0, 100)
    cursorCircleOpacitySlider:SetValueStep(5)
    cursorCircleOpacitySlider:SetObeyStepOnDrag(true)
    _G[cursorCircleOpacitySlider:GetName() .. "Low"]:SetText("0%")
    _G[cursorCircleOpacitySlider:GetName() .. "High"]:SetText("100%")
    local cursorCircleOpacityTitle = _G[cursorCircleOpacitySlider:GetName() .. "Text"]
    cursorCircleOpacityTitle:SetText("Opacity: " .. math.floor((MattActionBarFontDB.cursorCircleOpacity or 1.0) * 100) .. "%")
    StyleSlider(cursorCircleOpacitySlider)
    cursorCircleOpacitySlider:SetValue((MattActionBarFontDB.cursorCircleOpacity or 1.0) * 100)
    cursorCircleOpacitySlider:SetScript("OnValueChanged", function(self, value)
        local alpha = value / 100
        MattActionBarFontDB.cursorCircleOpacity = alpha
        _G[self:GetName() .. "Text"]:SetText("Opacity: " .. math.floor(value) .. "%")
        MABF:ApplyCursorCircleStyle()
    end)

    local function UpdateCursorCircleControls()
        local enabled = MattActionBarFontDB.enableCursorCircle and true or false
        if enabled then
            cursorCircleColorLabel:SetTextColor(0.8, 0.8, 0.8)
            cursorCircleColorDropdown:SetAlpha(1)
            cursorCircleColorDropdown.button:Enable()
            cursorCircleScaleSlider:SetAlpha(1)
            cursorCircleScaleSlider:EnableMouse(true)
            _G[cursorCircleScaleSlider:GetName() .. "Text"]:SetTextColor(1, 1, 1)
            _G[cursorCircleScaleSlider:GetName() .. "Low"]:SetTextColor(0.8, 0.8, 0.8)
            _G[cursorCircleScaleSlider:GetName() .. "High"]:SetTextColor(0.8, 0.8, 0.8)
            cursorCircleOpacitySlider:SetAlpha(1)
            cursorCircleOpacitySlider:EnableMouse(true)
            _G[cursorCircleOpacitySlider:GetName() .. "Text"]:SetTextColor(1, 1, 1)
            _G[cursorCircleOpacitySlider:GetName() .. "Low"]:SetTextColor(0.8, 0.8, 0.8)
            _G[cursorCircleOpacitySlider:GetName() .. "High"]:SetTextColor(0.8, 0.8, 0.8)
        else
            cursorCircleColorLabel:SetTextColor(0.45, 0.45, 0.45)
            cursorCircleColorDropdown:SetAlpha(0.6)
            cursorCircleColorDropdown.button:Disable()
            cursorCircleScaleSlider:SetAlpha(0.6)
            cursorCircleScaleSlider:EnableMouse(false)
            _G[cursorCircleScaleSlider:GetName() .. "Text"]:SetTextColor(0.6, 0.6, 0.6)
            _G[cursorCircleScaleSlider:GetName() .. "Low"]:SetTextColor(0.5, 0.5, 0.5)
            _G[cursorCircleScaleSlider:GetName() .. "High"]:SetTextColor(0.5, 0.5, 0.5)
            cursorCircleOpacitySlider:SetAlpha(0.6)
            cursorCircleOpacitySlider:EnableMouse(false)
            _G[cursorCircleOpacitySlider:GetName() .. "Text"]:SetTextColor(0.6, 0.6, 0.6)
            _G[cursorCircleOpacitySlider:GetName() .. "Low"]:SetTextColor(0.5, 0.5, 0.5)
            _G[cursorCircleOpacitySlider:GetName() .. "High"]:SetTextColor(0.5, 0.5, 0.5)
            if cursorCircleColorDropdown.list and cursorCircleColorDropdown.list:IsShown() then
                cursorCircleColorDropdown:Close()
            end
        end
    end

    cursorCircleCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableCursorCircle = self:GetChecked() and true or false
        MABF:SetupCursorCircle()
        UpdateCursorCircleControls()
    end)
    UpdateCursorCircleControls()

    return {
        cursorCircleCheck = cursorCircleCheck,
        cursorCircleColorLabel = cursorCircleColorLabel,
        cursorCircleColorDropdown = cursorCircleColorDropdown,
        cursorCircleScaleSlider = cursorCircleScaleSlider,
        cursorCircleOpacitySlider = cursorCircleOpacitySlider,
    }
end
