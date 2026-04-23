local addonName, MABF = ...

-- Builds the Action Bars > Themes options page UI.
function MABF:BuildActionBarThemesPage(opts)
    if type(opts) ~= "table" then return nil end

    local CreateContentPage = opts.CreateContentPage
    local CreatePageTitle = opts.CreatePageTitle
    local CreateMinimalDropdown = opts.CreateMinimalDropdown
    local StyleSlider = opts.StyleSlider

    if not CreateContentPage or not CreatePageTitle or not CreateMinimalDropdown or not StyleSlider then
        return nil
    end

    local pageTheme = CreateContentPage(3)
    local themeTitle = CreatePageTitle(pageTheme, "AB Themes")

    local themeDropdownTitle = pageTheme:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeDropdownTitle:SetPoint("TOPLEFT", themeTitle, "BOTTOMLEFT", 0, -14)
    themeDropdownTitle:SetText("Action Bar Theme:")
    themeDropdownTitle:SetTextColor(1, 1, 1)

    local themeOptions = MABF:GetActionBarThemeOptions()
    local themeDropDown = CreateMinimalDropdown(pageTheme, 170, 12)
    themeDropDown:SetPoint("TOPLEFT", themeDropdownTitle, "BOTTOMLEFT", 0, -6)

    MABF:NormalizeActionBarThemeSettings()

    local bgOpacitySlider = CreateFrame("Slider", "MABFBgOpacitySlider", pageTheme, "OptionsSliderTemplate")
    bgOpacitySlider:SetSize(260, 14)
    bgOpacitySlider:SetPoint("TOPLEFT", themeDropDown, "BOTTOMLEFT", 16, -22)
    bgOpacitySlider:SetMinMaxValues(0, 100)
    bgOpacitySlider:SetValue((MattActionBarFontDB.minimalThemeBgOpacity or 0.35) * 100)
    bgOpacitySlider:SetValueStep(1)
    bgOpacitySlider:SetObeyStepOnDrag(true)
    local bgOpacityName = bgOpacitySlider:GetName()
    _G[bgOpacityName .. "Low"]:SetText("0%")
    _G[bgOpacityName .. "High"]:SetText("100%")
    _G[bgOpacityName .. "Text"]:SetText("Background Opacity: " .. math.floor((MattActionBarFontDB.minimalThemeBgOpacity or 0.35) * 100) .. "%")
    StyleSlider(bgOpacitySlider)
    bgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        value = MABF:SetActionBarThemeBgOpacityPercent(value)
        _G[self:GetName() .. "Text"]:SetText("Background Opacity: " .. value .. "%")
    end)

    local borderSizeSlider = CreateFrame("Slider", "MABFBorderSizeSlider", pageTheme, "OptionsSliderTemplate")
    borderSizeSlider:SetSize(260, 14)
    borderSizeSlider:SetPoint("TOPLEFT", bgOpacitySlider, "BOTTOMLEFT", 0, -26)
    borderSizeSlider:SetMinMaxValues(1, 4)
    borderSizeSlider:SetValue(MattActionBarFontDB.minimalThemeBorderSize)
    borderSizeSlider:SetValueStep(1)
    borderSizeSlider:SetObeyStepOnDrag(true)
    local borderSizeName = borderSizeSlider:GetName()
    _G[borderSizeName .. "Low"]:SetText("1")
    _G[borderSizeName .. "High"]:SetText("4")
    _G[borderSizeName .. "Text"]:SetText("Pixel Border Size: " .. MattActionBarFontDB.minimalThemeBorderSize)
    StyleSlider(borderSizeSlider)
    borderSizeSlider:SetScript("OnValueChanged", function(self, value)
        local size = MABF:SetActionBarThemeBorderSize(value)
        _G[self:GetName() .. "Text"]:SetText("Pixel Border Size: " .. size)
    end)

    local function UpdateThemeSlidersVisibility()
        if MABF:IsMinimalActionBarThemeSelected() then
            bgOpacitySlider:Show()
            borderSizeSlider:Show()
        else
            bgOpacitySlider:Hide()
            borderSizeSlider:Hide()
        end
    end
    UpdateThemeSlidersVisibility()

    themeDropDown:SetOptions(themeOptions)
    themeDropDown:SetSelectedValue(MattActionBarFontDB.minimalTheme)
    themeDropDown:SetOnOpen(function(self)
        self:SetOptions(themeOptions)
        self:SetSelectedValue(MattActionBarFontDB.minimalTheme)
    end)
    themeDropDown:SetOnSelect(function(value)
        local requiresReload = MABF:SetActionBarTheme(value)
        themeDropDown:SetSelectedValue(value)
        UpdateThemeSlidersVisibility()
        if requiresReload then
            StaticPopup_Show("MABF_RELOAD_UI")
            return
        end
    end)

    return {
        page = pageTheme,
    }
end
