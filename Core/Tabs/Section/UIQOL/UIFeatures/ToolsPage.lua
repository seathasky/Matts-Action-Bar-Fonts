local addonName, MABF = ...

-- Builds UI / QoL > UI Features > Tools controls.
function MABF:BuildUIFeaturesToolsPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageUIFeatures = opts.pageUIFeatures
    local anchorControl = opts.anchorControl
    local CreateMinimalDropdown = opts.CreateMinimalDropdown
    local StyleSlider = opts.StyleSlider

    if not pageUIFeatures or not anchorControl or not CreateMinimalDropdown or not StyleSlider then
        return nil
    end

    local perfMonitorCheck = CreateFrame("CheckButton", "MABFPerfMonitorCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfMonitorCheck:ClearAllPoints()
    perfMonitorCheck:SetPoint("TOPLEFT", anchorControl, "BOTTOMLEFT", -20, -20)
    local perfMonitorText = _G[perfMonitorCheck:GetName() .. "Text"]
    perfMonitorText:SetText("Performance Monitor (FPS & MS)")
    perfMonitorText:SetTextColor(1, 1, 1)
    perfMonitorCheck:SetChecked(MattActionBarFontDB.enablePerformanceMonitor)
    perfMonitorCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enablePerformanceMonitor = self:GetChecked() and true or false
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    local perfMonitorDesc = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    perfMonitorDesc:SetPoint("TOPLEFT", perfMonitorCheck, "BOTTOMLEFT", 26, -5)
    perfMonitorDesc:SetText("|cff888888Shift+LeftClick to move the monitor|r")
    perfMonitorDesc:SetScale(0.85)

    local perfBgOpacitySlider = CreateFrame("Slider", "MABFPerfBgOpacitySlider", pageUIFeatures, "OptionsSliderTemplate")
    perfBgOpacitySlider:SetWidth(140)
    perfBgOpacitySlider:SetHeight(16)
    perfBgOpacitySlider:SetPoint("TOPLEFT", perfMonitorDesc, "BOTTOMLEFT", -6, -33)
    perfBgOpacitySlider:SetMinMaxValues(0, 100)
    perfBgOpacitySlider:SetValueStep(5)
    perfBgOpacitySlider:SetObeyStepOnDrag(true)
    _G[perfBgOpacitySlider:GetName() .. "Low"]:SetText("0%")
    _G[perfBgOpacitySlider:GetName() .. "High"]:SetText("100%")
    local perfBgOpacityTitle = _G[perfBgOpacitySlider:GetName() .. "Text"]
    perfBgOpacityTitle:SetText("BG Opacity: " .. math.floor((MattActionBarFontDB.perfMonitorBgOpacity or 0.5) * 100) .. "%")
    StyleSlider(perfBgOpacitySlider)
    perfBgOpacitySlider:SetValue((MattActionBarFontDB.perfMonitorBgOpacity or 0.5) * 100)
    perfBgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        local alpha = value / 100
        MattActionBarFontDB.perfMonitorBgOpacity = alpha
        _G[self:GetName() .. "Text"]:SetText("BG Opacity: " .. math.floor(value) .. "%")
        MABF:ApplyPerfMonitorStyle()
    end)

    local perfColorLabel = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    perfColorLabel:SetPoint("TOPLEFT", perfBgOpacitySlider, "BOTTOMLEFT", 0, -38)
    perfColorLabel:SetText("Text Color:")
    perfColorLabel:SetTextColor(0.8, 0.8, 0.8)

    local perfColorDropdown = CreateMinimalDropdown(pageUIFeatures, 110, 6)
    perfColorDropdown:SetPoint("LEFT", perfColorLabel, "RIGHT", 8, 0)

    local perfColorOptions = {
        { label = "White", value = "white" },
        { label = "Red", value = "red" },
        { label = "Green", value = "green" },
        { label = "Yellow", value = "yellow" },
        { label = "Blue", value = "blue" },
    }

    perfColorDropdown:SetOptions(perfColorOptions)
    perfColorDropdown:SetSelectedValue(MattActionBarFontDB.perfMonitorColor)
    perfColorDropdown:SetOnOpen(function(self)
        self:SetOptions(perfColorOptions)
        self:SetSelectedValue(MattActionBarFontDB.perfMonitorColor)
    end)
    perfColorDropdown:SetOnSelect(function(value)
        MattActionBarFontDB.perfMonitorColor = value
        perfColorDropdown:SetSelectedValue(value)
        MABF:ApplyPerfMonitorStyle()
    end)

    local perfVerticalCheck = CreateFrame("CheckButton", "MABFPerfVerticalCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfVerticalCheck:ClearAllPoints()
    perfVerticalCheck:SetPoint("TOPLEFT", perfColorLabel, "BOTTOMLEFT", -4, -20)
    local perfVerticalText = _G[perfVerticalCheck:GetName() .. "Text"]
    perfVerticalText:SetText("Vertical Layout")
    perfVerticalText:SetTextColor(0.8, 0.8, 0.8)
    perfVerticalCheck:SetChecked(MattActionBarFontDB.perfMonitorVertical)
    perfVerticalCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.perfMonitorVertical = self:GetChecked()
        MABF:ApplyPerfMonitorStyle()
    end)

    local perfShowWorldMSCheck = CreateFrame("CheckButton", "MABFPerfShowWorldMSCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfShowWorldMSCheck:ClearAllPoints()
    perfShowWorldMSCheck:SetPoint("TOPLEFT", perfVerticalCheck, "BOTTOMLEFT", 0, -4)
    local perfShowWorldMSText = _G[perfShowWorldMSCheck:GetName() .. "Text"]
    perfShowWorldMSText:SetText("Show World MS")
    perfShowWorldMSText:SetTextColor(0.8, 0.8, 0.8)
    perfShowWorldMSCheck:SetChecked(MattActionBarFontDB.perfMonitorShowWorldMS)

    local perfHideMSCheck = CreateFrame("CheckButton", "MABFPerfHideMSCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfHideMSCheck:ClearAllPoints()
    perfHideMSCheck:SetPoint("TOPLEFT", perfShowWorldMSCheck, "BOTTOMLEFT", 0, -4)
    local perfHideMSText = _G[perfHideMSCheck:GetName() .. "Text"]
    perfHideMSText:SetText("Hide MS")
    perfHideMSText:SetTextColor(0.8, 0.8, 0.8)
    perfHideMSCheck:SetChecked(MattActionBarFontDB.perfMonitorHideMS)

    local function UpdateWorldMSControlState()
        local hideMS = MattActionBarFontDB.perfMonitorHideMS and true or false
        if hideMS then
            perfShowWorldMSCheck:Disable()
            perfShowWorldMSCheck:SetAlpha(0.5)
            perfShowWorldMSText:SetTextColor(0.5, 0.5, 0.5)
        else
            perfShowWorldMSCheck:Enable()
            perfShowWorldMSCheck:SetAlpha(1.0)
            perfShowWorldMSText:SetTextColor(0.8, 0.8, 0.8)
        end
    end

    perfShowWorldMSCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.perfMonitorShowWorldMS = self:GetChecked()
        MABF:ApplyPerfMonitorStyle()
    end)

    perfHideMSCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.perfMonitorHideMS = self:GetChecked()
        UpdateWorldMSControlState()
        MABF:ApplyPerfMonitorStyle()
    end)

    UpdateWorldMSControlState()

    return {
        perfMonitorCheck = perfMonitorCheck,
        perfMonitorDesc = perfMonitorDesc,
        perfBgOpacitySlider = perfBgOpacitySlider,
        perfColorLabel = perfColorLabel,
        perfColorDropdown = perfColorDropdown,
        perfVerticalCheck = perfVerticalCheck,
        perfHideMSCheck = perfHideMSCheck,
        perfShowWorldMSCheck = perfShowWorldMSCheck,
    }
end
