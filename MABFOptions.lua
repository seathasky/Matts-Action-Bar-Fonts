-- MABFOptions.lua
local addonName, MABF = ...

-----------------------------------------------------------
-- Options Window Creation with Vertical Tabs
-----------------------------------------------------------
function MABF:CreateOptionsWindow()
    local f = CreateFrame("Frame", "MABFOptionsFrame", UIParent, "BackdropTemplate")
    -- Store the options frame so other modules (e.g. slash command) can toggle it.
    self.optionsFrame = f

    f:Hide()
    f:SetSize(350, 300)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = true,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 4, right = 4, top = 4, bottom = 4 }
    })
    f:SetBackdropColor(0, 0, 0, 0.8)

    -- Window Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOP", f, "TOP", 0, -15)
    title:SetText("MATTS ACTIONBAR FONTS")
    title:SetTextColor(1, 1, 1)  -- White color
    title:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Championship.ttf", 22, "OUTLINE")

    -- Close Button
    local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

    ------------------------------------------------------------------------------
    -- Create Left Panel for Tabs
    ------------------------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetSize(100, 250)
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -40)
    leftPanel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    leftPanel:SetBackdropColor(0.1, 0.1, 0.1, 1)

    ------------------------------------------------------------------------------
    -- Create Right Panel for Content Pages
    ------------------------------------------------------------------------------
    local rightPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rightPanel:SetSize(220, 250) 
    rightPanel:SetPoint("TOPRIGHT", f, "TOPRIGHT", -10, -40)
    rightPanel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile     = false,
        tileSize = 16,
        edgeSize = 16,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    rightPanel:SetBackdropColor(0.2, 0.2, 0.2, 1)

    ------------------------------------------------------------------------------
    -- Declare Pages Table (used by tab buttons)
    ------------------------------------------------------------------------------
    local pages = {}

    ------------------------------------------------------------------------------
    -- Create Vertical Tab Buttons in Left Panel
    ------------------------------------------------------------------------------
    local tabNames = {"General", "Offsets", "Theme"}
    local tabButtons = {}
    local numTabs = #tabNames
    local tabHeight = 40  -- adjust as needed

    for i = 1, numTabs do
        local btn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
        btn:SetSize(80, tabHeight - 5)
        btn:SetText(tabNames[i])
        btn:SetPoint("TOP", leftPanel, "TOP", 0, -((i - 1) * tabHeight) - 10)
        btn:SetID(i)
        btn:SetScript("OnClick", function(self)
            for j, page in ipairs(pages) do
                page:Hide()
            end
            pages[self:GetID()]:Show()
            for k, button in ipairs(tabButtons) do
                if k == self:GetID() then
                    button:LockHighlight()
                else
                    button:UnlockHighlight()
                end
            end
        end)
        tabButtons[i] = btn
    end

    -- Create the "Keybind" button
    local keybindBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
    keybindBtn:SetSize(80, tabHeight - 5)
    keybindBtn:SetText("Keybind")
    keybindBtn:SetPoint("TOP", leftPanel, "TOP", 0, -((numTabs) * tabHeight) - 10)

    -- Temporary blocker flag
    local blockWoWSettings = false

    keybindBtn:SetScript("OnClick", function()
        local wasOptionsOpen = MABFOptionsFrame and MABFOptionsFrame:IsShown()
        if wasOptionsOpen then
            MABFOptionsFrame:Hide()
        end

        ChatFrame1EditBox:SetText("/kb")
        ChatEdit_SendText(ChatFrame1EditBox)
        blockWoWSettings = true

        local watcherFrame = CreateFrame("Frame")
        watcherFrame:SetScript("OnUpdate", function(self, elapsed)
            if QuickKeybindFrame and not QuickKeybindFrame:IsShown() then
                self:SetScript("OnUpdate", nil)
                self:Hide()
                if InterfaceOptionsFrame then HideUIPanel(InterfaceOptionsFrame) end
                if SettingsPanel then SettingsPanel:Hide() end
                if wasOptionsOpen then
                    MABFOptionsFrame:Show()
                end
                C_Timer.After(0.5, function()
                    blockWoWSettings = false
                end)
            end
        end)
    end)

    local function BlockWoWOptionsIfNeeded(self)
        if blockWoWSettings then
            HideUIPanel(self)
        end
    end

    if InterfaceOptionsFrame then
        InterfaceOptionsFrame:HookScript("OnShow", BlockWoWOptionsIfNeeded)
    end
    if SettingsPanel then
        SettingsPanel:HookScript("OnShow", BlockWoWOptionsIfNeeded)
    end

    -- Create the "Edit Mode" button on the leftPanel
    local editModeBtn = CreateFrame("Button", nil, leftPanel, "UIPanelButtonTemplate")
    editModeBtn:SetSize(80, tabHeight - 5)
    editModeBtn:SetText("Edit Mode")
    editModeBtn:SetPoint("TOP", keybindBtn, "BOTTOM", 0, -5)
    editModeBtn:SetScript("OnClick", function()
        if MABFOptionsFrame then
            MABFOptionsFrame:Hide()
        end
        ShowUIPanel(EditModeManagerFrame)
    end)

    ------------------------------------------------------------------------------
    -- Create Content Pages as Children of Right Panel
    ------------------------------------------------------------------------------
    -- Page 1: General Settings (with Macro slider integrated)
    local pageGeneral = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageGeneral:SetAllPoints(rightPanel)
    pages[1] = pageGeneral

    local genLabel = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    genLabel:SetPoint("TOP", pageGeneral, "TOP", 0, -10)
    genLabel:SetText("General Settings")

    -- Main Font Size Slider
    local mainSlider = CreateFrame("Slider", "MABFMainFontSizeSlider", pageGeneral, "OptionsSliderTemplate")
    mainSlider:SetSize(130, 15)
    mainSlider:SetPoint("TOP", genLabel, "BOTTOM", 0, -15)
    mainSlider:SetMinMaxValues(10, 50)
    mainSlider:SetValue(MattActionBarFontDB.fontSize)
    mainSlider:SetValueStep(1)
    mainSlider:SetObeyStepOnDrag(true)
    local mainSliderName = mainSlider:GetName()
    _G[mainSliderName.."Low"]:SetText("10")
    _G[mainSliderName.."High"]:SetText("50")
    _G[mainSliderName.."Text"]:SetText("Main Font Size: " .. MattActionBarFontDB.fontSize)
    mainSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.fontSize = value
        _G[mainSliderName.."Text"]:SetText("Main Font Size: " .. value)
        MABF:ApplyFontSettings()
        MABF:UpdatePetBarFontSettings()
    end)

    -- Count Font Size Slider
    local countSlider = CreateFrame("Slider", "MABFCountSizeSlider", pageGeneral, "OptionsSliderTemplate")
    countSlider:SetSize(130, 15)
    countSlider:SetPoint("TOP", mainSlider, "BOTTOM", 0, -20)
    countSlider:SetMinMaxValues(8, 30)
    countSlider:SetValue(MattActionBarFontDB.countFontSize)
    countSlider:SetValueStep(1)
    countSlider:SetObeyStepOnDrag(true)
    local countSliderName = countSlider:GetName()
    _G[countSliderName.."Low"]:SetText("8")
    _G[countSliderName.."High"]:SetText("30")
    _G[countSliderName.."Text"]:SetText("Count Font Size: " .. MattActionBarFontDB.countFontSize)
    countSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.countFontSize = value
        _G[countSliderName.."Text"]:SetText("Count Font Size: " .. value)
        MABF:UpdateSpecificBars()
        MABF:UpdateFontPositions()
    end)

    -- Macro Text Slider (integrated into General settings)
    local macroSlider = CreateFrame("Slider", "MABFMacroTextSizeSlider", pageGeneral, "OptionsSliderTemplate")
    macroSlider:SetSize(130, 15)
    macroSlider:SetPoint("TOP", countSlider, "BOTTOM", 0, -20)
    macroSlider:SetMinMaxValues(8, 30)
    macroSlider:SetValue(MattActionBarFontDB.macroTextSize)
    macroSlider:SetValueStep(1)
    macroSlider:SetObeyStepOnDrag(true)
    local macroSliderName = macroSlider:GetName()
    _G[macroSliderName.."Low"]:SetText("8")
    _G[macroSliderName.."High"]:SetText("30")
    _G[macroSliderName.."Text"]:SetText("Macro Text Size: " .. MattActionBarFontDB.macroTextSize)
    macroSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.macroTextSize = value
        _G[macroSliderName.."Text"]:SetText("Macro Text Size: " .. value)
        MABF:UpdateMacroText()
    end)

    -- Pet Bar Font Size Slider
    local petBarSlider = CreateFrame("Slider", "MABFPetBarSizeSlider", pageGeneral, "OptionsSliderTemplate")
    petBarSlider:SetSize(130, 15)
    petBarSlider:SetPoint("TOP", macroSlider, "BOTTOM", 0, -20)
    petBarSlider:SetMinMaxValues(10, 50)
    petBarSlider:SetValue(MattActionBarFontDB.petBarFontSize)
    petBarSlider:SetValueStep(1)
    local petBarSliderName = petBarSlider:GetName()
    _G[petBarSliderName.."Low"]:SetText("10")
    _G[petBarSliderName.."High"]:SetText("50")
    _G[petBarSliderName.."Text"]:SetText("Pet Bar Font Size: " .. MattActionBarFontDB.petBarFontSize)
    petBarSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.petBarFontSize = value
        _G[petBarSliderName.."Text"]:SetText("Pet Bar Font Size: " .. value)
        MABF:UpdatePetBarFontSettings()
    end)

    local dropdownTitle = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    dropdownTitle:SetPoint("TOP", petBarSlider, "BOTTOM", 0, -20)
    dropdownTitle:SetText("Actionbar Font:")
    local fontDropDown = CreateFrame("Frame", "MABFFontDropDown", pageGeneral, "UIDropDownMenuTemplate")
    fontDropDown:SetPoint("TOP", dropdownTitle, "BOTTOM", 0, -5)
    UIDropDownMenu_SetWidth(fontDropDown, 150)
    local function InitializeFontDropDown(self, level)
        local fontsList = {}
        for fontName, _ in pairs(MABF.availableFonts or {}) do
            table.insert(fontsList, fontName)
        end
        table.sort(fontsList)
        for _, fontName in ipairs(fontsList) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = fontName
            info.value = fontName
            info.func = function()
                MABF.availableFonts = MABF:ScanCustomFonts()
                MattActionBarFontDB.fontFamily = fontName
                MABF:ApplyFontSettings()
                MABF:UpdateMacroText()
                MABF:UpdateFontPositions()
                MABF:UpdateActionBarFontPositions()
                UIDropDownMenu_SetSelectedValue(fontDropDown, fontName)
                print("|cFF00FF00MattActionBarFont:|r Font updated to: " .. fontName)
            end
            info.checked = (fontName == MattActionBarFontDB.fontFamily)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(fontDropDown, InitializeFontDropDown)
    UIDropDownMenu_SetSelectedValue(fontDropDown, MattActionBarFontDB.fontFamily)

    -- Page 2: Offsets
    local pageOffsets = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageOffsets:SetAllPoints(rightPanel)
    pages[2] = pageOffsets

    local abOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    abOffsetsLabel:SetPoint("TOP", pageOffsets, "TOP", 0, -10)
    abOffsetsLabel:SetText("Action Bar Font Offsets")

    local abXOffsetSlider = CreateFrame("Slider", "MABFABXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abXOffsetSlider:SetSize(130, 15)
    abXOffsetSlider:SetPoint("TOP", abOffsetsLabel, "BOTTOM", 0, -15)
    abXOffsetSlider:SetMinMaxValues(-100, 100)
    abXOffsetSlider:SetValue(MattActionBarFontDB.abXOffset)
    abXOffsetSlider:SetValueStep(1)
    abXOffsetSlider:SetObeyStepOnDrag(true)
    local abXSliderName = abXOffsetSlider:GetName()
    _G[abXSliderName.."Low"]:SetText("-100")
    _G[abXSliderName.."High"]:SetText("100")
    _G[abXSliderName.."Text"]:SetText("Action Bar Font X Offset: " .. MattActionBarFontDB.abXOffset)
    abXOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.abXOffset = value
        _G[abXSliderName.."Text"]:SetText("Action Bar Font X Offset: " .. value)
        MABF:UpdateActionBarFontPositions()
    end)

    local abYOffsetSlider = CreateFrame("Slider", "MABFABYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abYOffsetSlider:SetSize(130, 15)
    abYOffsetSlider:SetPoint("TOP", abXOffsetSlider, "BOTTOM", 0, -20)
    abYOffsetSlider:SetMinMaxValues(-100, 100)
    abYOffsetSlider:SetValue(MattActionBarFontDB.abYOffset)
    abYOffsetSlider:SetValueStep(1)
    abYOffsetSlider:SetObeyStepOnDrag(true)
    local abYSliderName = abYOffsetSlider:GetName()
    _G[abYSliderName.."Low"]:SetText("-100")
    _G[abYSliderName.."High"]:SetText("100")
    _G[abYSliderName.."Text"]:SetText("Action Bar Font Y Offset: " .. MattActionBarFontDB.abYOffset)
    abYOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.abYOffset = value
        _G[abYSliderName.."Text"]:SetText("Action Bar Font Y Offset: " .. value)
        MABF:UpdateActionBarFontPositions()
    end)

    local countOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countOffsetsLabel:SetPoint("TOP", abYOffsetSlider, "BOTTOM", 0, -20)
    countOffsetsLabel:SetText("Count Text Offsets")

    local xOffsetSlider = CreateFrame("Slider", "MABFXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    xOffsetSlider:SetSize(130, 15)
    xOffsetSlider:SetPoint("TOP", countOffsetsLabel, "BOTTOM", 0, -15)
    xOffsetSlider:SetMinMaxValues(-100, 100)
    xOffsetSlider:SetValue(MattActionBarFontDB.xOffset)
    xOffsetSlider:SetValueStep(1)
    xOffsetSlider:SetObeyStepOnDrag(true)
    local xSliderName = xOffsetSlider:GetName()
    _G[xSliderName.."Low"]:SetText("-100")
    _G[xSliderName.."High"]:SetText("100")
    _G[xSliderName.."Text"]:SetText("Count Text X Offset: " .. MattActionBarFontDB.xOffset)
    xOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.xOffset = value
        _G[xSliderName.."Text"]:SetText("Count Text X Offset: " .. value)
        MABF:UpdateFontPositions()
    end)

    local yOffsetSlider = CreateFrame("Slider", "MABFYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    yOffsetSlider:SetSize(130, 15)
    yOffsetSlider:SetPoint("TOP", xOffsetSlider, "BOTTOM", 0, -20)
    yOffsetSlider:SetMinMaxValues(-100, 100)
    yOffsetSlider:SetValue(MattActionBarFontDB.yOffset)
    yOffsetSlider:SetValueStep(1)
    yOffsetSlider:SetObeyStepOnDrag(true)
    local ySliderName = yOffsetSlider:GetName()
    _G[ySliderName.."Low"]:SetText("-100")
    _G[ySliderName.."High"]:SetText("100")
    _G[ySliderName.."Text"]:SetText("Count Text Y Offset: " .. MattActionBarFontDB.yOffset)
    yOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.yOffset = value
        _G[ySliderName.."Text"]:SetText("Count Text Y Offset: " .. value)
        MABF:UpdateFontPositions()
    end)

    -- Page 3: Action Bar Theme
    local pageTheme = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageTheme:SetAllPoints(rightPanel)
    pages[3] = pageTheme

    -- Ensure cdTextEnabled is on by default if not set
    if MattActionBarFontDB.cdTextEnabled == nil then
        MattActionBarFontDB.cdTextEnabled = true
    end

    local themeTitle = pageTheme:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeTitle:SetPoint("TOP", pageTheme, "TOP", 0, -10)
    themeTitle:SetText("Action Bar Themes")

    local minimalThemeCheck = CreateFrame("CheckButton", "MABFMinimalThemeCheck", pageTheme, "InterfaceOptionsCheckButtonTemplate")
    minimalThemeCheck:ClearAllPoints()
    minimalThemeCheck:SetPoint("TOP", themeTitle, "BOTTOM", -45, -10)
    local checkText = _G[minimalThemeCheck:GetName().."Text"]
    checkText:SetText("Minimal Theme")
    checkText:SetTextColor(1, 1, 1)
    minimalThemeCheck:SetChecked(MattActionBarFontDB.minimalTheme)
    minimalThemeCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.minimalTheme = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    local cdTextCheck = CreateFrame("CheckButton", "MABFCDTextCheck", pageTheme, "InterfaceOptionsCheckButtonTemplate")
    cdTextCheck:ClearAllPoints()
    cdTextCheck:SetPoint("TOP", minimalThemeCheck, "BOTTOM", 0, -10)
    local cdCheckText = _G[cdTextCheck:GetName().."Text"]
    cdCheckText:SetText("CD Text")
    cdCheckText:SetTextColor(1, 1, 1)
    cdTextCheck:SetChecked(MattActionBarFontDB.cdTextEnabled)
    cdTextCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.cdTextEnabled = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    -- Add the macro text toggle option to the theme section
    local hideMacroTextCheckbox = CreateFrame("CheckButton", "MABFHideMacroTextCheckbox", pageTheme, "InterfaceOptionsCheckButtonTemplate")
    hideMacroTextCheckbox:SetPoint("TOPLEFT", cdTextCheck, "BOTTOMLEFT", 0, -15)
    hideMacroTextCheckbox.Text:SetText("Hide Macro Text")
    hideMacroTextCheckbox.tooltipText = "Toggle visibility of macro text on action buttons"
    hideMacroTextCheckbox:SetChecked(MattActionBarFontDB.hideMacroText)

    -- Add a macro text size slider that's truly centered in the frame
    local macroTextSizeSlider = CreateFrame("Slider", "MABFMacroTextSizeSlider", pageTheme, "OptionsSliderTemplate")
    -- Lower the position by increasing the offset from -130 to -160
    macroTextSizeSlider:SetPoint("TOP", pageTheme, "TOP", 0, -160)
    macroTextSizeSlider:SetMinMaxValues(6, 20)
    macroTextSizeSlider:SetValueStep(1)
    macroTextSizeSlider:SetObeyStepOnDrag(true)
    macroTextSizeSlider:SetWidth(140)
    macroTextSizeSlider.Text:SetText("Macro Text Size")
    macroTextSizeSlider.Low:SetText("6")
    macroTextSizeSlider.High:SetText("20")
    macroTextSizeSlider:SetValue(MattActionBarFontDB.macroTextSize or 8)
    macroTextSizeSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        MattActionBarFontDB.macroTextSize = value
        MABF:UpdateMacroText()
    end)

    -- Function to update visibility of macro text size slider
    -- IMPORTANT: Define the function after creating the slider but before using it
    local function UpdateMacroTextSizeVisibility()
        if MattActionBarFontDB.hideMacroText then
            macroTextSizeSlider:Disable()
            macroTextSizeSlider:SetAlpha(0.5)
        else
            macroTextSizeSlider:Enable()
            macroTextSizeSlider:SetAlpha(1.0)
        end
    end

    -- Now set up the click handler that uses the function
    hideMacroTextCheckbox:SetScript("OnClick", function(self)
        local checked = self:GetChecked()
        MattActionBarFontDB.hideMacroText = checked and true or false
        MABF:UpdateMacroText()
        UpdateMacroTextSizeVisibility()
    end)

    -- Initialize the visibility state
    UpdateMacroTextSizeVisibility()

    ------------------------------------------------------------------------------
    -- Initialize: Show first page and highlight first tab
    ------------------------------------------------------------------------------
    for i, page in ipairs(pages) do
        if i == 1 then
            page:Show()
        else
            page:Hide()
        end
    end
    tabButtons[1]:LockHighlight()

    -- Allow the options window to be closed with Escape.
    tinsert(UISpecialFrames, "MABFOptionsFrame")
end

-----------------------------------------------------------
-- Static Popup Dialog for Reload UI
-----------------------------------------------------------
StaticPopupDialogs["MABF_RELOAD_UI"] = {
    text = "You need to reload the UI for theme changes to take effect. Reload now?",
    button1 = "Reload UI",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
