local addonName, MABF = ...

-- Builds the Action Bars > Text options page UI.
function MABF:BuildActionBarTextPage(opts)
    if type(opts) ~= "table" then return nil end

    local CreateContentPage = opts.CreateContentPage
    local CreatePageTitle = opts.CreatePageTitle
    local StyleSlider = opts.StyleSlider
    local CreateMinimalDropdown = opts.CreateMinimalDropdown
    if not CreateContentPage or not CreatePageTitle or not StyleSlider or not CreateMinimalDropdown then
        return nil
    end
    local THEME_ACCENT = MABF:GetThemeAccentColor()

    local pageGeneral = CreateContentPage(1)
    local genLabel = CreatePageTitle(pageGeneral, "AB Text")

    local mainSlider = CreateFrame("Slider", "MABFMainFontSizeSlider", pageGeneral, "OptionsSliderTemplate")
    mainSlider:SetSize(260, 14)
    mainSlider:SetPoint("TOPLEFT", genLabel, "BOTTOMLEFT", 0, -18)
    mainSlider:SetMinMaxValues(10, 50)
    mainSlider:SetValue(MattActionBarFontDB.fontSize)
    mainSlider:SetValueStep(1)
    mainSlider:SetObeyStepOnDrag(true)
    local mainSliderName = mainSlider:GetName()
    _G[mainSliderName .. "Low"]:SetText("10")
    _G[mainSliderName .. "High"]:SetText("50")
    _G[mainSliderName .. "Text"]:SetText("Main Font Size: " .. MattActionBarFontDB.fontSize)
    StyleSlider(mainSlider)
    mainSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetMainFontSize(value)
        _G[mainSliderName .. "Text"]:SetText("Main Font Size: " .. value)
    end)

    local countSlider = CreateFrame("Slider", "MABFCountSizeSlider", pageGeneral, "OptionsSliderTemplate")
    countSlider:SetSize(260, 14)
    countSlider:SetPoint("TOPLEFT", mainSlider, "BOTTOMLEFT", 0, -22)
    countSlider:SetMinMaxValues(8, 30)
    countSlider:SetValue(MattActionBarFontDB.countFontSize)
    countSlider:SetValueStep(1)
    countSlider:SetObeyStepOnDrag(true)
    local countSliderName = countSlider:GetName()
    _G[countSliderName .. "Low"]:SetText("8")
    _G[countSliderName .. "High"]:SetText("30")
    _G[countSliderName .. "Text"]:SetText("Count Font Size: " .. MattActionBarFontDB.countFontSize)
    StyleSlider(countSlider)
    countSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetCountFontSize(value)
        _G[countSliderName .. "Text"]:SetText("Count Font Size: " .. value)
    end)

    local macroSlider = CreateFrame("Slider", "MABFMacroTextSizeSlider", pageGeneral, "OptionsSliderTemplate")
    macroSlider:SetSize(260, 14)
    macroSlider:SetPoint("TOPLEFT", countSlider, "BOTTOMLEFT", 0, -22)
    macroSlider:SetMinMaxValues(8, 30)
    macroSlider:SetValue(MattActionBarFontDB.macroTextSize)
    macroSlider:SetValueStep(1)
    macroSlider:SetObeyStepOnDrag(true)
    local macroSliderName = macroSlider:GetName()
    _G[macroSliderName .. "Low"]:SetText("8")
    _G[macroSliderName .. "High"]:SetText("30")
    _G[macroSliderName .. "Text"]:SetText("Macro Text Size: " .. MattActionBarFontDB.macroTextSize)
    StyleSlider(macroSlider)
    macroSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetMacroTextSize(value)
        _G[macroSliderName .. "Text"]:SetText("Macro Text Size: " .. value)
    end)

    local petBarSlider = CreateFrame("Slider", "MABFPetBarSizeSlider", pageGeneral, "OptionsSliderTemplate")
    petBarSlider:SetSize(260, 14)
    petBarSlider:SetPoint("TOPLEFT", macroSlider, "BOTTOMLEFT", 0, -22)
    petBarSlider:SetMinMaxValues(10, 50)
    petBarSlider:SetValue(MattActionBarFontDB.petBarFontSize)
    petBarSlider:SetValueStep(1)
    local petBarSliderName = petBarSlider:GetName()
    _G[petBarSliderName .. "Low"]:SetText("10")
    _G[petBarSliderName .. "High"]:SetText("50")
    _G[petBarSliderName .. "Text"]:SetText("Pet Bar Font Size: " .. MattActionBarFontDB.petBarFontSize)
    StyleSlider(petBarSlider)
    petBarSlider:SetScript("OnValueChanged", function(_, value)
        value = math.floor(value + 0.5)
        MABF:SetPetBarFontSize(value)
        _G[petBarSliderName .. "Text"]:SetText("Pet Bar Font Size: " .. value)
    end)

    local RefreshFontSectionState

    local customFontsCheck = CreateFrame("CheckButton", "MABFEnableCustomFontsCheck", pageGeneral, "InterfaceOptionsCheckButtonTemplate")
    customFontsCheck:ClearAllPoints()
    customFontsCheck:SetPoint("TOPLEFT", petBarSlider, "BOTTOMLEFT", 0, -22)
    local customFontsText = _G[customFontsCheck:GetName() .. "Text"]
    customFontsText:SetText("Enable Custom Fonts")
    customFontsText:SetTextColor(1, 1, 1)
    customFontsCheck:SetChecked(MattActionBarFontDB.enableCustomFontSection ~= false)
    customFontsCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableCustomFontSection = self:GetChecked() and true or false
        if MattActionBarFontDB.enableCustomFontSection == false then
            MattActionBarFontDB.fontFamily = "Blizzard Default"
        else
            MattActionBarFontDB.fontFamily = "Naowh"
        end
        if RefreshFontSectionState then
            RefreshFontSectionState()
        end
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    local dropdownTitle = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdownTitle:SetPoint("TOPLEFT", customFontsCheck, "BOTTOMLEFT", 26, -8)
    dropdownTitle:SetText("Actionbar Font:")
    dropdownTitle:SetTextColor(1, 1, 1)

    local fontDropDown = CreateMinimalDropdown(pageGeneral, 150, 10)
    fontDropDown:SetPoint("TOPLEFT", dropdownTitle, "BOTTOMLEFT", 0, -6)

    local function BuildFontOptions()
        local fontsList = MABF:GetFontOptions()
        local options = {}
        for _, fontName in ipairs(fontsList) do
            options[#options + 1] = { value = fontName, label = fontName }
        end
        return options
    end

    fontDropDown:SetOptions(BuildFontOptions())
    fontDropDown:SetSelectedValue(MattActionBarFontDB.fontFamily)
    fontDropDown:SetOnOpen(function(self)
        local options = BuildFontOptions()
        self:SetOptions(options)
        self:SetSelectedValue(MattActionBarFontDB.fontFamily)
    end)
    fontDropDown:SetOnSelect(function(value)
        if MattActionBarFontDB.enableCustomFontSection == false then
            return
        end
        MABF:SetSelectedFont(value)
        fontDropDown:SetSelectedValue(MattActionBarFontDB.fontFamily)
        print("|cFF00FF00MattActionBarFont:|r Font updated to: " .. tostring(MattActionBarFontDB.fontFamily))
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    function RefreshFontSectionState()
        local enabled = MattActionBarFontDB.enableCustomFontSection ~= false
        if not enabled then
            MattActionBarFontDB.fontFamily = "Blizzard Default"
        end
        customFontsCheck:SetChecked(enabled)
        local options = BuildFontOptions()
        fontDropDown:SetOptions(options)
        fontDropDown:SetSelectedValue(MattActionBarFontDB.fontFamily)
        if fontDropDown.SetAlpha then
            fontDropDown:SetAlpha(enabled and 1 or 0.55)
        end
        if enabled then
            dropdownTitle:SetTextColor(1, 1, 1)
        else
            dropdownTitle:SetTextColor(0.55, 0.55, 0.55)
        end
    end
    RefreshFontSectionState()

    local resetFontsBtn = CreateFrame("Button", "MABFResetFontDefaultsBtn", pageGeneral, "BackdropTemplate")
    resetFontsBtn:SetSize(132, 20)
    resetFontsBtn:SetPoint("BOTTOMLEFT", pageGeneral, "BOTTOMLEFT", 12, 14)
    resetFontsBtn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    resetFontsBtn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    resetFontsBtn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local resetFontsBtnText = resetFontsBtn:CreateFontString(nil, "OVERLAY")
    resetFontsBtnText:SetPoint("CENTER", resetFontsBtn, "CENTER", 0, 0)
    resetFontsBtnText:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 9, "OUTLINE")
    resetFontsBtnText:SetText("Reset Font Defaults")
    resetFontsBtnText:SetTextColor(0.9, 0.9, 0.9, 1)

    resetFontsBtn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.8)
    end)
    resetFontsBtn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)
    resetFontsBtn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.04, 0.04, 0.06, 1)
    end)
    resetFontsBtn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)
    resetFontsBtn:SetScript("OnClick", function()
        local db = MattActionBarFontDB or {}
        local customEnabled = db.enableCustomFontSection ~= false
        MABF:ResetActionBarTextSizeDefaults(customEnabled)
        db = MattActionBarFontDB or db

        mainSlider:SetValue(db.fontSize)
        countSlider:SetValue(db.countFontSize)
        macroSlider:SetValue(db.macroTextSize)
        petBarSlider:SetValue(db.petBarFontSize)

        customFontsCheck:SetChecked(customEnabled)
        if RefreshFontSectionState then
            RefreshFontSectionState()
        end

        MABF:ApplyAllActionBarTextSettings()
    end)

    return {
        page = pageGeneral,
        customFontsCheck = customFontsCheck,
    }
end

-- Backward-compatible alias for older call sites.
function MABF:BuildActionBarTextSizesPage(opts)
    return MABF.BuildActionBarTextPage(self, opts)
end
