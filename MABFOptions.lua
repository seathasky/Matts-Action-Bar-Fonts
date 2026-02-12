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
    f:SetSize(420, 500)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", f.StartMoving)
    f:SetScript("OnDragStop", f.StopMovingOrSizing)
    f:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        tileSize = 0,
        edgeSize = 1,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
    })
    f:SetBackdropColor(0.05, 0.05, 0.1, 0.95)  -- Midnight theme: very dark blue-black
    f:SetBackdropBorderColor(0.45, 0.04, 0.04, 0.8) -- Subtle red outline

    -- Window Title
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    title:SetPoint("TOPLEFT", f, "TOPLEFT", 14, -12)
    title:SetText("MABF")
    title:SetTextColor(1, 1, 1)
    title:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 14, "OUTLINE")

    -- Tagline (random on each reload)
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
    }
    local tagline = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tagline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    tagline:SetText("|cff666666" .. taglines[math.random(#taglines)] .. "|r")
    tagline:SetFont("Fonts\\FRIZQT__.TTF", 8)

    -- Close Button
    local closeButton = CreateFrame("Button", nil, f, "UIPanelCloseButton")
    closeButton:SetPoint("TOPRIGHT", f, "TOPRIGHT", -5, -5)

    -- Full name in tiny text bottom
    local fullName = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fullName:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 6)
    fullName:SetText("|cffFFFFFFMatt's Action Bar Fonts & UI QoL|r")
    fullName:SetFont("Fonts\\FRIZQT__.TTF", 7)

    ------------------------------------------------------------------------------
    -- Create Left Panel for Tabs
    ------------------------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetSize(100, 430)
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -45)
    leftPanel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        tileSize = 0,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    leftPanel:SetBackdropColor(0.08, 0.08, 0.12, 1)  -- Dark midnight gray
    leftPanel:SetBackdropBorderColor(0.35, 0.03, 0.03, 0.7) -- Subtle red outline

    ------------------------------------------------------------------------------
    -- Create Right Panel for Content Pages
    ------------------------------------------------------------------------------
    local rightPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rightPanel:SetSize(295, 430)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 6, 0)
    rightPanel:SetBackdrop({
        bgFile   = "Interface\\Tooltips\\UI-Tooltip-Background",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        tileSize = 0,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    rightPanel:SetBackdropColor(0.10, 0.10, 0.13, 1)
    rightPanel:SetBackdropBorderColor(0.35, 0.03, 0.03, 0.7) -- Subtle red outline

    -- Theme variables for a minimal, cohesive look (red accent)
    local THEME_ACCENT = {0.86, 0, 0}
    local TAB_NORMAL = {0.35, 0.04, 0.04, 1}
    local TAB_HOVER = {0.55, 0.08, 0.08, 1}
    local TAB_SELECTED = {0.75, 0, 0, 1}
    local PANEL_BORDER = {0.35, 0.03, 0.03, 0.7}
    -- Unified spacing constants
    local CONTENT_SPACING = -22
    local PAGE_WIDTH = 260

    local function CreatePageTitle(page, text)
        local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
        title:SetText(text)
        title:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
        return title
    end

    ------------------------------------------------------------------------------
    -- Declare Pages Table (used by tab buttons)
    ------------------------------------------------------------------------------
    local pages = {}

    ------------------------------------------------------------------------------
    -- Create Vertical Tab Buttons in Left Panel (with section headers)
    ------------------------------------------------------------------------------
    local tabButtons = {}  -- all page-switching buttons (indices match pages[])
    local allTabButtons = {} -- all buttons for unified deselect
    local tabHeight = 28
    local tabGap = 2
    local sectionGap = 6
    local TAB_FONT = "Fonts\\FRIZQT__.TTF"
    local TAB_FONT_SIZE = 9

    -- Helper: create a section header label in the left panel
    local function CreateSectionHeader(parent, text, anchorFrame, anchorPoint, yOffset)
        local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        if anchorFrame then
            header:SetPoint("TOPLEFT", anchorFrame, anchorPoint or "BOTTOMLEFT", 0, yOffset or -sectionGap)
        else
            header:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset or -6)
        end
        header:SetText("|cff" .. string.format("%02x%02x%02x", THEME_ACCENT[1]*255, THEME_ACCENT[2]*255, THEME_ACCENT[3]*255) .. text .. "|r")
        header:SetFont(TAB_FONT, 7, "OUTLINE")
        return header
    end

    -- Helper: create a tab button
    local function CreateTabButton(parent, label, pageIndex, anchorFrame, anchorPoint, yOffset)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(86, tabHeight)
        btn:SetPoint("TOP", anchorFrame, anchorPoint or "BOTTOM", 0, yOffset or -tabGap)
        btn:SetID(pageIndex or 0)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false, edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        btn:SetBackdropColor(TAB_NORMAL[1], TAB_NORMAL[2], TAB_NORMAL[3], TAB_NORMAL[4])
        btn:SetBackdropBorderColor(PANEL_BORDER[1], PANEL_BORDER[2], PANEL_BORDER[3], PANEL_BORDER[4])
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER")
        btnText:SetText(label)
        btnText:SetTextColor(1, 1, 1, 1)
        btnText:SetFont(TAB_FONT, TAB_FONT_SIZE, "OUTLINE")
        btn:SetScript("OnEnter", function(self)
            self:SetBackdropColor(TAB_HOVER[1], TAB_HOVER[2], TAB_HOVER[3], TAB_HOVER[4])
        end)
        btn:SetScript("OnLeave", function(self)
            local isSelected = pageIndex and pages[pageIndex] and pages[pageIndex]:IsShown()
            if isSelected then
                self:SetBackdropColor(TAB_SELECTED[1], TAB_SELECTED[2], TAB_SELECTED[3], TAB_SELECTED[4])
            else
                self:SetBackdropColor(TAB_NORMAL[1], TAB_NORMAL[2], TAB_NORMAL[3], TAB_NORMAL[4])
            end
        end)
        table.insert(allTabButtons, btn)
        return btn
    end

    -- Unified click handler for any page-tab button
    local function TabOnClick(btn, pageIndex)
        for j, page in ipairs(pages) do page:Hide() end
        pages[pageIndex]:Show()
        for _, b in ipairs(allTabButtons) do
            b:SetBackdropColor(TAB_NORMAL[1], TAB_NORMAL[2], TAB_NORMAL[3], TAB_NORMAL[4])
        end
        btn:SetBackdropColor(TAB_SELECTED[1], TAB_SELECTED[2], TAB_SELECTED[3], TAB_SELECTED[4])
    end

    --------------------------------------------------------------------------
    -- SECTION: ACTION BARS (tabs 1-4)
    --------------------------------------------------------------------------
    local abHeader = CreateSectionHeader(leftPanel, "ACTION BARS", nil, nil, -4)

    local btnTextSizes = CreateTabButton(leftPanel, "Text Sizes", 1, leftPanel, "TOP", -14)
    tabButtons[1] = btnTextSizes

    local btnOffsets = CreateTabButton(leftPanel, "Offsets", 2, btnTextSizes)
    tabButtons[2] = btnOffsets

    local btnThemes = CreateTabButton(leftPanel, "Themes", 3, btnOffsets)
    tabButtons[3] = btnThemes

    local btnABFeatures = CreateTabButton(leftPanel, "Features", 4, btnThemes)
    tabButtons[4] = btnABFeatures

    --------------------------------------------------------------------------
    -- SECTION: UI / QoL (tabs 5, 8, 9)
    --------------------------------------------------------------------------
    local uiHeader = CreateSectionHeader(leftPanel, "UI / QoL", btnABFeatures, "BOTTOMLEFT", -sectionGap)

    local btnUIFeatures = CreateTabButton(leftPanel, "UI Features", 5, btnABFeatures, "BOTTOM", -(sectionGap + 12))
    tabButtons[5] = btnUIFeatures

    local btnQuests = CreateTabButton(leftPanel, "Quests", 8, btnUIFeatures)
    tabButtons[8] = btnQuests

    local btnBags = CreateTabButton(leftPanel, "Bags", 9, btnQuests)
    tabButtons[9] = btnBags

    local btnMerchant = CreateTabButton(leftPanel, "Merchant", 10, btnBags)
    tabButtons[10] = btnMerchant

    --------------------------------------------------------------------------
    -- SECTION: SHORTCUTS (Keybind + Edit Mode action buttons)
    --------------------------------------------------------------------------
    local shortcutsHeader = CreateSectionHeader(leftPanel, "SHORTCUTS", btnMerchant, "BOTTOMLEFT", -sectionGap)

    local keybindBtn = CreateTabButton(leftPanel, "Keybind", nil, btnMerchant, "BOTTOM", -(sectionGap + 12))

    local editModeBtn = CreateTabButton(leftPanel, "Edit Mode", nil, keybindBtn)

    --------------------------------------------------------------------------
    -- SECTION: SYSTEM (Quick Commands tab 6 + System tab 7)
    --------------------------------------------------------------------------
    local systemHeader = CreateSectionHeader(leftPanel, "SYSTEM", editModeBtn, "BOTTOMLEFT", -sectionGap)

    local qcTabBtn = CreateTabButton(leftPanel, "Quick Cmds", 6, editModeBtn, "BOTTOM", -(sectionGap + 12))
    tabButtons[6] = qcTabBtn

    local systemTabBtn = CreateTabButton(leftPanel, "System", 7, qcTabBtn)
    tabButtons[7] = systemTabBtn

    -- Wire up page-switching click handlers
    for idx, btn in pairs(tabButtons) do
        local pi = idx
        btn:SetScript("OnClick", function(self) TabOnClick(self, pi) end)
    end

    -- Keybind button: action only (no page)
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

    -- Edit Mode button: action only (no page)
    editModeBtn:SetScript("OnClick", function()
        if MABFOptionsFrame then
            MABFOptionsFrame:Hide()
        end
        ShowUIPanel(EditModeManagerFrame)
    end)

    ------------------------------------------------------------------------------
    -- Create Content Pages as Children of Right Panel
    ------------------------------------------------------------------------------
    -- Helper: style slider text to match addon theme
    local SLIDER_FONT = "Fonts\\FRIZQT__.TTF"
    local SLIDER_FONT_SIZE = 9
    local SLIDER_MINMAX_SIZE = 8
    local function StyleSlider(slider)
        local name = slider:GetName()
        local textLabel = _G[name.."Text"]
        local lowLabel = _G[name.."Low"]
        local highLabel = _G[name.."High"]
        if textLabel then
            textLabel:SetFont(SLIDER_FONT, SLIDER_FONT_SIZE, "OUTLINE")
            textLabel:SetTextColor(1, 1, 1)
        end
        if lowLabel then
            lowLabel:SetFont(SLIDER_FONT, SLIDER_MINMAX_SIZE, "OUTLINE")
            lowLabel:SetTextColor(0.6, 0.6, 0.6)
        end
        if highLabel then
            highLabel:SetFont(SLIDER_FONT, SLIDER_MINMAX_SIZE, "OUTLINE")
            highLabel:SetTextColor(0.6, 0.6, 0.6)
        end
    end

    -- Page 1: General Settings (with Macro slider integrated)
    local pageGeneral = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageGeneral:SetAllPoints(rightPanel)
    pages[1] = pageGeneral

    local genLabel = CreatePageTitle(pageGeneral, "AB Text Sizes")

    -- Main Font Size Slider
    local mainSlider = CreateFrame("Slider", "MABFMainFontSizeSlider", pageGeneral, "OptionsSliderTemplate")
    mainSlider:SetSize(PAGE_WIDTH, 14)
    mainSlider:SetPoint("TOPLEFT", genLabel, "BOTTOMLEFT", 0, -18)
    mainSlider:SetMinMaxValues(10, 50)
    mainSlider:SetValue(MattActionBarFontDB.fontSize)
    mainSlider:SetValueStep(1)
    mainSlider:SetObeyStepOnDrag(true)
    local mainSliderName = mainSlider:GetName()
    _G[mainSliderName.."Low"]:SetText("10")
    _G[mainSliderName.."High"]:SetText("50")
    _G[mainSliderName.."Text"]:SetText("Main Font Size: " .. MattActionBarFontDB.fontSize)
    StyleSlider(mainSlider)
    mainSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.fontSize = value
        _G[mainSliderName.."Text"]:SetText("Main Font Size: " .. value)
        MABF:ApplyFontSettings()
        MABF:UpdatePetBarFontSettings()
    end)

    -- Count Font Size Slider
    local countSlider = CreateFrame("Slider", "MABFCountSizeSlider", pageGeneral, "OptionsSliderTemplate")
    countSlider:SetSize(PAGE_WIDTH, 14)
    countSlider:SetPoint("TOPLEFT", mainSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    countSlider:SetMinMaxValues(8, 30)
    countSlider:SetValue(MattActionBarFontDB.countFontSize)
    countSlider:SetValueStep(1)
    countSlider:SetObeyStepOnDrag(true)
    local countSliderName = countSlider:GetName()
    _G[countSliderName.."Low"]:SetText("8")
    _G[countSliderName.."High"]:SetText("30")
    _G[countSliderName.."Text"]:SetText("Count Font Size: " .. MattActionBarFontDB.countFontSize)
    StyleSlider(countSlider)
    countSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.countFontSize = value
        _G[countSliderName.."Text"]:SetText("Count Font Size: " .. value)
        MABF:UpdateSpecificBars()
        MABF:UpdateFontPositions()
    end)

    -- Macro Text Slider (integrated into General settings)
    local macroSlider = CreateFrame("Slider", "MABFMacroTextSizeSlider", pageGeneral, "OptionsSliderTemplate")
    macroSlider:SetSize(PAGE_WIDTH, 14)
    macroSlider:SetPoint("TOPLEFT", countSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    macroSlider:SetMinMaxValues(8, 30)
    macroSlider:SetValue(MattActionBarFontDB.macroTextSize)
    macroSlider:SetValueStep(1)
    macroSlider:SetObeyStepOnDrag(true)
    local macroSliderName = macroSlider:GetName()
    _G[macroSliderName.."Low"]:SetText("8")
    _G[macroSliderName.."High"]:SetText("30")
    _G[macroSliderName.."Text"]:SetText("Macro Text Size: " .. MattActionBarFontDB.macroTextSize)
    StyleSlider(macroSlider)
    macroSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.macroTextSize = value
        _G[macroSliderName.."Text"]:SetText("Macro Text Size: " .. value)
        MABF:UpdateMacroText()
    end)

    -- Pet Bar Font Size Slider
    local petBarSlider = CreateFrame("Slider", "MABFPetBarSizeSlider", pageGeneral, "OptionsSliderTemplate")
    petBarSlider:SetSize(PAGE_WIDTH, 14)
    petBarSlider:SetPoint("TOPLEFT", macroSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    petBarSlider:SetMinMaxValues(10, 50)
    petBarSlider:SetValue(MattActionBarFontDB.petBarFontSize)
    petBarSlider:SetValueStep(1)
    local petBarSliderName = petBarSlider:GetName()
    _G[petBarSliderName.."Low"]:SetText("10")
    _G[petBarSliderName.."High"]:SetText("50")
    _G[petBarSliderName.."Text"]:SetText("Pet Bar Font Size: " .. MattActionBarFontDB.petBarFontSize)
    StyleSlider(petBarSlider)
    petBarSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.petBarFontSize = value
        _G[petBarSliderName.."Text"]:SetText("Pet Bar Font Size: " .. value)
        MABF:UpdatePetBarFontSettings()
    end)

    local dropdownTitle = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdownTitle:SetPoint("TOPLEFT", petBarSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    dropdownTitle:SetText("Actionbar Font:")
    dropdownTitle:SetTextColor(1, 1, 1)
    local fontDropDown = CreateFrame("Frame", "MABFFontDropDown", pageGeneral, "UIDropDownMenuTemplate")
    fontDropDown:SetPoint("TOPLEFT", dropdownTitle, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(fontDropDown, 130)
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

    local abOffsetsLabel = CreatePageTitle(pageOffsets, "AB Offsets")

    local abXOffsetSlider = CreateFrame("Slider", "MABFABXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abXOffsetSlider:SetSize(PAGE_WIDTH, 14)
    abXOffsetSlider:SetPoint("TOPLEFT", abOffsetsLabel, "BOTTOMLEFT", 0, -18)
    abXOffsetSlider:SetMinMaxValues(-100, 100)
    abXOffsetSlider:SetValue(MattActionBarFontDB.abXOffset)
    abXOffsetSlider:SetValueStep(1)
    abXOffsetSlider:SetObeyStepOnDrag(true)
    local abXSliderName = abXOffsetSlider:GetName()
    _G[abXSliderName.."Low"]:SetText("-100")
    _G[abXSliderName.."High"]:SetText("100")
    _G[abXSliderName.."Text"]:SetText("Action Bar Font X Offset: " .. MattActionBarFontDB.abXOffset)
    StyleSlider(abXOffsetSlider)
    abXOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.abXOffset = value
        _G[abXSliderName.."Text"]:SetText("Action Bar Font X Offset: " .. value)
        MABF:UpdateActionBarFontPositions()
    end)

    local abYOffsetSlider = CreateFrame("Slider", "MABFABYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abYOffsetSlider:SetSize(PAGE_WIDTH, 14)
    abYOffsetSlider:SetPoint("TOPLEFT", abXOffsetSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    abYOffsetSlider:SetMinMaxValues(-100, 100)
    abYOffsetSlider:SetValue(MattActionBarFontDB.abYOffset)
    abYOffsetSlider:SetValueStep(1)
    abYOffsetSlider:SetObeyStepOnDrag(true)
    local abYSliderName = abYOffsetSlider:GetName()
    _G[abYSliderName.."Low"]:SetText("-100")
    _G[abYSliderName.."High"]:SetText("100")
    _G[abYSliderName.."Text"]:SetText("Action Bar Font Y Offset: " .. MattActionBarFontDB.abYOffset)
    StyleSlider(abYOffsetSlider)
    abYOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.abYOffset = value
        _G[abYSliderName.."Text"]:SetText("Action Bar Font Y Offset: " .. value)
        MABF:UpdateActionBarFontPositions()
    end)

    -- Extra Ability Offsets (separate offsets for ExtraAction / ExtraAbility widgets)
    local extraOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    extraOffsetsLabel:SetPoint("TOPLEFT", abYOffsetSlider, "BOTTOMLEFT", 0, -28)
    extraOffsetsLabel:SetText("Extra Ability Offsets")
    extraOffsetsLabel:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    local extraXSlider = CreateFrame("Slider", "MABFExtraXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    extraXSlider:SetSize(PAGE_WIDTH, 14)
    extraXSlider:SetPoint("TOPLEFT", extraOffsetsLabel, "BOTTOMLEFT", 0, -18)
    extraXSlider:SetMinMaxValues(-100, 100)
    extraXSlider:SetValue(MattActionBarFontDB.extraXOffset)
    extraXSlider:SetValueStep(1)
    extraXSlider:SetObeyStepOnDrag(true)
    local extraXName = extraXSlider:GetName()
    _G[extraXName.."Low"]:SetText("-100")
    _G[extraXName.."High"]:SetText("100")
    _G[extraXName.."Text"]:SetText("Extra Ability Font X Offset: " .. MattActionBarFontDB.extraXOffset)
    StyleSlider(extraXSlider)
    extraXSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.extraXOffset = value
        _G[extraXName.."Text"]:SetText("Extra Ability Font X Offset: " .. value)
        MABF:UpdateActionBarFontPositions()
    end)

    local extraYSlider = CreateFrame("Slider", "MABFExtraYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    extraYSlider:SetSize(PAGE_WIDTH, 14)
    extraYSlider:SetPoint("TOPLEFT", extraXSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    extraYSlider:SetMinMaxValues(-100, 100)
    extraYSlider:SetValue(MattActionBarFontDB.extraYOffset)
    extraYSlider:SetValueStep(1)
    extraYSlider:SetObeyStepOnDrag(true)
    local extraYName = extraYSlider:GetName()
    _G[extraYName.."Low"]:SetText("-100")
    _G[extraYName.."High"]:SetText("100")
    _G[extraYName.."Text"]:SetText("Extra Ability Font Y Offset: " .. MattActionBarFontDB.extraYOffset)
    StyleSlider(extraYSlider)
    extraYSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.extraYOffset = value
        _G[extraYName.."Text"]:SetText("Extra Ability Font Y Offset: " .. value)
        MABF:UpdateActionBarFontPositions()
    end)

    local countOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countOffsetsLabel:SetPoint("TOPLEFT", extraYSlider, "BOTTOMLEFT", 0, -28)
    countOffsetsLabel:SetText("Count Text Offsets")
    countOffsetsLabel:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    local xOffsetSlider = CreateFrame("Slider", "MABFXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    xOffsetSlider:SetSize(PAGE_WIDTH, 14)
    xOffsetSlider:SetPoint("TOPLEFT", countOffsetsLabel, "BOTTOMLEFT", 0, -18)
    xOffsetSlider:SetMinMaxValues(-100, 100)
    xOffsetSlider:SetValue(MattActionBarFontDB.xOffset)
    xOffsetSlider:SetValueStep(1)
    xOffsetSlider:SetObeyStepOnDrag(true)
    local xSliderName = xOffsetSlider:GetName()
    _G[xSliderName.."Low"]:SetText("-100")
    _G[xSliderName.."High"]:SetText("100")
    _G[xSliderName.."Text"]:SetText("Count Text X Offset: " .. MattActionBarFontDB.xOffset)
    StyleSlider(xOffsetSlider)
    xOffsetSlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value + 0.5)
        MattActionBarFontDB.xOffset = value
        _G[xSliderName.."Text"]:SetText("Count Text X Offset: " .. value)
        MABF:UpdateFontPositions()
    end)

    local yOffsetSlider = CreateFrame("Slider", "MABFYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    yOffsetSlider:SetSize(PAGE_WIDTH, 14)
    yOffsetSlider:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    yOffsetSlider:SetMinMaxValues(-100, 100)
    yOffsetSlider:SetValue(MattActionBarFontDB.yOffset)
    yOffsetSlider:SetValueStep(1)
    yOffsetSlider:SetObeyStepOnDrag(true)
    local ySliderName = yOffsetSlider:GetName()
    _G[ySliderName.."Low"]:SetText("-100")
    _G[ySliderName.."High"]:SetText("100")
    _G[ySliderName.."Text"]:SetText("Count Text Y Offset: " .. MattActionBarFontDB.yOffset)
    StyleSlider(yOffsetSlider)
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

    local themeTitle = CreatePageTitle(pageTheme, "AB Themes")

    -- Theme dropdown
    local themeDropdownTitle = pageTheme:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeDropdownTitle:SetPoint("TOPLEFT", themeTitle, "BOTTOMLEFT", 0, -14)
    themeDropdownTitle:SetText("Action Bar Theme:")
    themeDropdownTitle:SetTextColor(1, 1, 1)

    local themeOptions = {
        { value = "blizzard",           label = "Blizzard Default" },
        { value = "minimalBlack",       label = "Minimal Black" },
        { value = "minimalTranslucent", label = "Minimal Translucent" },
    }

    local themeDropDown = CreateFrame("Frame", "MABFThemeDropDown", pageTheme, "UIDropDownMenuTemplate")
    themeDropDown:SetPoint("TOPLEFT", themeDropdownTitle, "BOTTOMLEFT", -16, -2)
    UIDropDownMenu_SetWidth(themeDropDown, 160)

    local function GetThemeLabel(val)
        for _, opt in ipairs(themeOptions) do
            if opt.value == val then return opt.label end
        end
        return "Blizzard Default"
    end

    -- Background Opacity slider (only visible when a minimal theme is selected)
    local bgOpacitySlider = CreateFrame("Slider", "MABFBgOpacitySlider", pageTheme, "OptionsSliderTemplate")
    bgOpacitySlider:SetSize(PAGE_WIDTH, 14)
    bgOpacitySlider:SetPoint("TOPLEFT", themeDropDown, "BOTTOMLEFT", 16, CONTENT_SPACING)
    bgOpacitySlider:SetMinMaxValues(0, 100)
    bgOpacitySlider:SetValue((MattActionBarFontDB.minimalThemeBgOpacity or 0.35) * 100)
    bgOpacitySlider:SetValueStep(5)
    bgOpacitySlider:SetObeyStepOnDrag(true)
    local bgOpacityName = bgOpacitySlider:GetName()
    _G[bgOpacityName.."Low"]:SetText("0%")
    _G[bgOpacityName.."High"]:SetText("100%")
    _G[bgOpacityName.."Text"]:SetText("Background Opacity: " .. math.floor((MattActionBarFontDB.minimalThemeBgOpacity or 0.35) * 100) .. "%")
    StyleSlider(bgOpacitySlider)
    bgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        MattActionBarFontDB.minimalThemeBgOpacity = value / 100
        _G[self:GetName().."Text"]:SetText("Background Opacity: " .. value .. "%")
        if MattActionBarFontDB.minimalTheme ~= "blizzard" then
            MABF:SkinActionBars()
        end
    end)

    local function UpdateOpacitySliderVisibility()
        if MattActionBarFontDB.minimalTheme ~= "blizzard" then
            bgOpacitySlider:Show()
        else
            bgOpacitySlider:Hide()
        end
    end
    UpdateOpacitySliderVisibility()

    local function InitializeThemeDropDown(self, level)
        for _, opt in ipairs(themeOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.label
            info.value = opt.value
            info.func = function()
                MattActionBarFontDB.minimalTheme = opt.value
                UIDropDownMenu_SetSelectedValue(themeDropDown, opt.value)
                UIDropDownMenu_SetText(themeDropDown, opt.label)
                UpdateOpacitySliderVisibility()
                StaticPopup_Show("MABF_RELOAD_UI")
            end
            info.checked = (opt.value == MattActionBarFontDB.minimalTheme)
            UIDropDownMenu_AddButton(info, level)
        end
    end
    UIDropDownMenu_Initialize(themeDropDown, InitializeThemeDropDown)
    UIDropDownMenu_SetSelectedValue(themeDropDown, MattActionBarFontDB.minimalTheme)
    UIDropDownMenu_SetText(themeDropDown, GetThemeLabel(MattActionBarFontDB.minimalTheme))

    -- Page 4: AB Features
    local pageABFeatures = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageABFeatures:SetAllPoints(rightPanel)
    pages[4] = pageABFeatures

    -- Page 5: UI Features
    local pageUIFeatures = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageUIFeatures:SetAllPoints(rightPanel)
    pages[5] = pageUIFeatures

    -- Page 6: QC Features
    local pageSystem = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageSystem:SetAllPoints(rightPanel)
    pages[6] = pageSystem

    -- Page 7: System (Edit Mode Device Manager)
    local pageEDM = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageEDM:SetAllPoints(rightPanel)
    pages[7] = pageEDM

    -- Page 8: Quests
    local pageQuests = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageQuests:SetAllPoints(rightPanel)
    pages[8] = pageQuests

    -- Page 9: Bags
    local pageBags = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageBags:SetAllPoints(rightPanel)
    pages[9] = pageBags

    -- Page 10: Merchant
    local pageMerchant = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
    pageMerchant:SetAllPoints(rightPanel)
    pages[10] = pageMerchant

    -- Initialize pages: show first page and set tab button colors
    for i, page in ipairs(pages) do
        if i == 1 then page:Show() else page:Hide() end
    end
    for _, b in ipairs(allTabButtons) do
        b:SetBackdropColor(TAB_NORMAL[1], TAB_NORMAL[2], TAB_NORMAL[3], TAB_NORMAL[4])
    end
    if tabButtons[1] then
        tabButtons[1]:SetBackdropColor(TAB_SELECTED[1], TAB_SELECTED[2], TAB_SELECTED[3], TAB_SELECTED[4])
    end

    local checkSpacing = -4

    --------------------------------------------------------------------------
    -- AB Features Page
    --------------------------------------------------------------------------
    local abFeaturesTitle = CreatePageTitle(pageABFeatures, "AB Features")

    -- Mouseover Fade
    local mouseoverFadeCheck = CreateFrame("CheckButton", "MABFMouseoverFadeCheck", pageABFeatures, "InterfaceOptionsCheckButtonTemplate")
    mouseoverFadeCheck:ClearAllPoints()
    mouseoverFadeCheck:SetPoint("TOPLEFT", abFeaturesTitle, "BOTTOMLEFT", 0, -8)
    local mouseoverFadeText = _G[mouseoverFadeCheck:GetName() .. "Text"]
    mouseoverFadeText:SetText("Mouseover Fade (Bars 4 & 5)")
    mouseoverFadeText:SetTextColor(1, 1, 1)
    mouseoverFadeCheck:SetChecked(MattActionBarFontDB.mouseoverFade)
    mouseoverFadeCheck:SetScript("OnClick", function(self)
        local enabled = self:GetChecked() and true or false
        MattActionBarFontDB.mouseoverFade = enabled
        MABF:ApplyActionBarMouseover()
        if enabled then
            MABF:SetBarsMouseoverState(false)
            StaticPopup_Show("MABF_RELOAD_UI")
        end
    end)

    -- Mouseover Fade Pet Bar
    local petBarFadeCheck = CreateFrame("CheckButton", "MABFPetBarFadeCheck", pageABFeatures, "InterfaceOptionsCheckButtonTemplate")
    petBarFadeCheck:ClearAllPoints()
    petBarFadeCheck:SetPoint("TOPLEFT", mouseoverFadeCheck, "BOTTOMLEFT", 0, checkSpacing)
    local petBarFadeText = _G[petBarFadeCheck:GetName() .. "Text"]
    petBarFadeText:SetText("Mouseover Fade (Pet Bar)")
    petBarFadeText:SetTextColor(1, 1, 1)
    petBarFadeCheck:SetChecked(MattActionBarFontDB.petBarMouseoverFade)
    petBarFadeCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.petBarMouseoverFade = self:GetChecked() and true or false
        MABF:ApplyPetBarMouseoverFade()
    end)

    -- Hide Macro Text
    local hideMacroTextCheck = CreateFrame("CheckButton", "MABFHideMacroTextExperimentalCheck", pageABFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideMacroTextCheck:ClearAllPoints()
    hideMacroTextCheck:SetPoint("TOPLEFT", petBarFadeCheck, "BOTTOMLEFT", 0, checkSpacing)
    local hideMacroTextLabel = _G[hideMacroTextCheck:GetName() .. "Text"]
    hideMacroTextLabel:SetText("Hide Macro Text")
    hideMacroTextLabel:SetTextColor(1, 1, 1)
    hideMacroTextCheck:SetChecked(MattActionBarFontDB.hideMacroText)
    hideMacroTextCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideMacroText = self:GetChecked() and true or false
        MABF:UpdateMacroText()
    end)

    -- Reverse Bar Growth
    local reverseBarGrowthCheck = CreateFrame("CheckButton", "MABFReverseBarGrowthCheck", pageABFeatures, "InterfaceOptionsCheckButtonTemplate")
    reverseBarGrowthCheck:ClearAllPoints()
    reverseBarGrowthCheck:SetPoint("TOPLEFT", hideMacroTextCheck, "BOTTOMLEFT", 0, checkSpacing)
    local reverseBarGrowthText = _G[reverseBarGrowthCheck:GetName() .. "Text"]
    reverseBarGrowthText:SetText("Reverse Bar Growth (Bar 1)")
    reverseBarGrowthText:SetTextColor(1, 1, 1)
    reverseBarGrowthCheck:SetChecked(MattActionBarFontDB.reverseBarGrowth)
    reverseBarGrowthCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.reverseBarGrowth = self:GetChecked() and true or false
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    --------------------------------------------------------------------------
    -- UI Features Page
    --------------------------------------------------------------------------
    local uiFeaturesTitle = CreatePageTitle(pageUIFeatures, "UI / QoL")

    -- Scale Objective Tracker
    local objectiveTrackerCheck = CreateFrame("CheckButton", "MABFObjectiveTrackerCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    objectiveTrackerCheck:ClearAllPoints()
    objectiveTrackerCheck:SetPoint("TOPLEFT", uiFeaturesTitle, "BOTTOMLEFT", 0, -8)
    local objCheckText = _G[objectiveTrackerCheck:GetName().."Text"]
    objCheckText:SetText("Scale Objective Tracker (0.7)")
    objCheckText:SetTextColor(1, 1, 1)
    objectiveTrackerCheck:SetChecked(MattActionBarFontDB.scaleObjectiveTracker)
    objectiveTrackerCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleObjectiveTracker = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    -- Scale Status Bar
    local scaleStatusBarCheck = CreateFrame("CheckButton", "MABFScaleStatusBarCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    scaleStatusBarCheck:ClearAllPoints()
    scaleStatusBarCheck:SetPoint("TOPLEFT", objectiveTrackerCheck, "BOTTOMLEFT", 0, checkSpacing)
    local scaleStatusBarText = _G[scaleStatusBarCheck:GetName().."Text"]
    scaleStatusBarText:SetText("Scale Status Bar (0.7)")
    scaleStatusBarText:SetTextColor(1, 1, 1)
    scaleStatusBarCheck:SetChecked(MattActionBarFontDB.scaleStatusBar)
    scaleStatusBarCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleStatusBar = self:GetChecked()
        MABF:ApplyStatusBarScale()
    end)

    -- Scale Talking Head
    local scaleTalkingHeadCheck = CreateFrame("CheckButton", "MABFScaleTalkingHeadCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    scaleTalkingHeadCheck:ClearAllPoints()
    scaleTalkingHeadCheck:SetPoint("TOPLEFT", scaleStatusBarCheck, "BOTTOMLEFT", 0, checkSpacing)
    local scaleTalkingHeadText = _G[scaleTalkingHeadCheck:GetName().."Text"]
    scaleTalkingHeadText:SetText("Scale Talking Head (0.7)")
    scaleTalkingHeadText:SetTextColor(1, 1, 1)
    scaleTalkingHeadCheck:SetChecked(MattActionBarFontDB.scaleTalkingHead)
    scaleTalkingHeadCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleTalkingHead = self:GetChecked()
        MABF:ApplyScaleTalkingHead()
    end)

    -- Hide Micro Menu
    local hideMicroMenuCheck = CreateFrame("CheckButton", "MABFHideMicroMenuCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideMicroMenuCheck:ClearAllPoints()
    hideMicroMenuCheck:SetPoint("TOPLEFT", scaleTalkingHeadCheck, "BOTTOMLEFT", 0, checkSpacing)
    local hideMicroMenuText = _G[hideMicroMenuCheck:GetName().."Text"]
    hideMicroMenuText:SetText("Hide Micro Menu")
    hideMicroMenuText:SetTextColor(1, 1, 1)
    local hideMicroDesc = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hideMicroDesc:SetPoint("TOPLEFT", hideMicroMenuCheck, "BOTTOMLEFT", 26, 2)
    hideMicroDesc:SetText("|cff888888Keeps Dungeon Finder & Housing|r")
    hideMicroDesc:SetScale(0.85)
    hideMicroMenuCheck:SetChecked(MattActionBarFontDB.hideMicroMenu)
    hideMicroMenuCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideMicroMenu = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    -- Hide Bag Bar
    local hideBagBarCheck = CreateFrame("CheckButton", "MABFHideBagBarCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideBagBarCheck:ClearAllPoints()
    hideBagBarCheck:SetPoint("TOPLEFT", hideMicroMenuCheck, "BOTTOMLEFT", 0, checkSpacing)
    local hideBagBarText = _G[hideBagBarCheck:GetName().."Text"]
    hideBagBarText:SetText("Hide Bag Bar")
    hideBagBarText:SetTextColor(1, 1, 1)
    hideBagBarCheck:SetChecked(MattActionBarFontDB.hideBagBar)
    hideBagBarCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideBagBar = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    -- Performance Monitor
    local perfMonitorCheck = CreateFrame("CheckButton", "MABFPerfMonitorCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfMonitorCheck:ClearAllPoints()
    perfMonitorCheck:SetPoint("TOPLEFT", hideBagBarCheck, "BOTTOMLEFT", 0, checkSpacing)
    local perfMonitorText = _G[perfMonitorCheck:GetName().."Text"]
    perfMonitorText:SetText("Performance Monitor (FPS & MS)")
    perfMonitorText:SetTextColor(1, 1, 1)
    perfMonitorCheck:SetChecked(MattActionBarFontDB.enablePerformanceMonitor)
    perfMonitorCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enablePerformanceMonitor = self:GetChecked() and true or false
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    -- Small helper text describing how to move the monitor
    local perfMonitorDesc = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    -- nudge description slightly lower to avoid overlapping the slider
    -- move description up a touch and add spacing
    perfMonitorDesc:SetPoint("TOPLEFT", perfMonitorCheck, "BOTTOMLEFT", 26, -10)
    perfMonitorDesc:SetText("|cff888888Shift+LeftClick to move the monitor|r")
    perfMonitorDesc:SetScale(0.85)

    -- Background Opacity slider (indented, sub-option)
    local perfBgOpacitySlider = CreateFrame("Slider", "MABFPerfBgOpacitySlider", pageUIFeatures, "OptionsSliderTemplate")
    perfBgOpacitySlider:SetWidth(140)
    perfBgOpacitySlider:SetHeight(16)
    -- anchor the slider further below the description to ensure no overlap
    perfBgOpacitySlider:SetPoint("TOPLEFT", perfMonitorDesc, "BOTTOMLEFT", -6, -22)
    perfBgOpacitySlider:SetMinMaxValues(0, 100)
    perfBgOpacitySlider:SetValueStep(5)
    perfBgOpacitySlider:SetObeyStepOnDrag(true)
    _G[perfBgOpacitySlider:GetName().."Low"]:SetText("0%")
    _G[perfBgOpacitySlider:GetName().."High"]:SetText("100%")
    local perfBgOpacityTitle = _G[perfBgOpacitySlider:GetName().."Text"]
    perfBgOpacityTitle:SetText("BG Opacity: " .. math.floor((MattActionBarFontDB.perfMonitorBgOpacity or 0.5) * 100) .. "%")
    StyleSlider(perfBgOpacitySlider)
    perfBgOpacitySlider:SetValue((MattActionBarFontDB.perfMonitorBgOpacity or 0.5) * 100)
    perfBgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        local alpha = value / 100
        MattActionBarFontDB.perfMonitorBgOpacity = alpha
        _G[self:GetName().."Text"]:SetText("BG Opacity: " .. math.floor(value) .. "%")
        MABF:ApplyPerfMonitorStyle()
    end)

    -- Text Color dropdown (indented, sub-option)
    local perfColorLabel = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    perfColorLabel:SetPoint("TOPLEFT", perfBgOpacitySlider, "BOTTOMLEFT", 0, -18)
    perfColorLabel:SetText("Text Color:")
    perfColorLabel:SetTextColor(0.8, 0.8, 0.8)

    local perfColorDropdown = CreateFrame("Frame", "MABFPerfColorDropdown", pageUIFeatures, "UIDropDownMenuTemplate")
    perfColorDropdown:SetPoint("LEFT", perfColorLabel, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(perfColorDropdown, 80)

    local perfColorOptions = {
        {label = "White",  value = "white"},
        {label = "Red",    value = "red"},
        {label = "Green",  value = "green"},
        {label = "Yellow", value = "yellow"},
        {label = "Blue",   value = "blue"},
    }

    local function PerfColorDropdown_Initialize(self, level)
        for _, opt in ipairs(perfColorOptions) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = opt.label
            info.value = opt.value
            info.func = function(btn)
                MattActionBarFontDB.perfMonitorColor = btn.value
                UIDropDownMenu_SetText(perfColorDropdown, opt.label)
                MABF:ApplyPerfMonitorStyle()
            end
            info.checked = (MattActionBarFontDB.perfMonitorColor == opt.value)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    UIDropDownMenu_Initialize(perfColorDropdown, PerfColorDropdown_Initialize)
    -- Set initial display text
    for _, opt in ipairs(perfColorOptions) do
        if opt.value == MattActionBarFontDB.perfMonitorColor then
            UIDropDownMenu_SetText(perfColorDropdown, opt.label)
            break
        end
    end

    -- Vertical / Horizontal layout checkbox
    local perfVerticalCheck = CreateFrame("CheckButton", "MABFPerfVerticalCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfVerticalCheck:ClearAllPoints()
    perfVerticalCheck:SetPoint("TOPLEFT", perfColorLabel, "BOTTOMLEFT", -4, -20)
    local perfVerticalText = _G[perfVerticalCheck:GetName().."Text"]
    perfVerticalText:SetText("Vertical Layout")
    perfVerticalText:SetTextColor(0.8, 0.8, 0.8)
    perfVerticalCheck:SetChecked(MattActionBarFontDB.perfMonitorVertical)
    perfVerticalCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.perfMonitorVertical = self:GetChecked()
        MABF:ApplyPerfMonitorStyle()
    end)

    -- Hide MS checkbox
    local perfHideMSCheck = CreateFrame("CheckButton", "MABFPerfHideMSCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfHideMSCheck:ClearAllPoints()
    perfHideMSCheck:SetPoint("TOPLEFT", perfVerticalCheck, "BOTTOMLEFT", 0, checkSpacing)
    local perfHideMSText = _G[perfHideMSCheck:GetName().."Text"]
    perfHideMSText:SetText("Hide MS")
    perfHideMSText:SetTextColor(0.8, 0.8, 0.8)
    perfHideMSCheck:SetChecked(MattActionBarFontDB.perfMonitorHideMS)
    perfHideMSCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.perfMonitorHideMS = self:GetChecked()
        MABF:ApplyPerfMonitorStyle()
    end)

    --------------------------------------------------------------------------
    -- System Page (Edit Mode Device Manager)
    --------------------------------------------------------------------------
    local edmTitle = CreatePageTitle(pageEDM, "Edit Mode Device Manager")

    local edmDesc = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    edmDesc:SetPoint("TOPLEFT", edmTitle, "BOTTOMLEFT", 0, -6)
    edmDesc:SetText("|cff888888Auto-apply an Edit Mode layout on login|r")
    edmDesc:SetFont("Fonts\\FRIZQT__.TTF", 9)

    -- Enable checkbox
    local edmEnableCheck = CreateFrame("CheckButton", "MABFEDMEnableCheck", pageEDM, "InterfaceOptionsCheckButtonTemplate")
    edmEnableCheck:ClearAllPoints()
    edmEnableCheck:SetPoint("TOPLEFT", edmDesc, "BOTTOMLEFT", -2, -10)
    local edmEnableText = _G[edmEnableCheck:GetName().."Text"]
    edmEnableText:SetText("Enable Device Manager")
    edmEnableText:SetTextColor(1, 1, 1)
    edmEnableCheck:SetChecked(MattActionBarFontDB.editMode and MattActionBarFontDB.editMode.enabled)
    edmEnableCheck:SetScript("OnClick", function(self)
        if not MattActionBarFontDB.editMode then MattActionBarFontDB.editMode = {} end
        MattActionBarFontDB.editMode.enabled = self:GetChecked()
        if MattActionBarFontDB.editMode.enabled then
            MABF:SetupEditModeDeviceManager()
        end
    end)

    -- Layout dropdown label
    local edmLayoutLabel = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    edmLayoutLabel:SetPoint("TOPLEFT", edmEnableCheck, "BOTTOMLEFT", 2, -12)
    edmLayoutLabel:SetText("Layout on Login:")
    edmLayoutLabel:SetTextColor(1, 1, 1)

    -- Layout dropdown
    local edmLayoutDropdown = CreateFrame("Frame", "MABFEDMLayoutDropdown", pageEDM, "UIDropDownMenuTemplate")
    edmLayoutDropdown:SetPoint("LEFT", edmLayoutLabel, "RIGHT", -8, -2)
    UIDropDownMenu_SetWidth(edmLayoutDropdown, 140)

    local function InitializeEDMDropdown(self, level)
        -- Load Blizzard_EditMode if needed
        if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
            C_AddOns.LoadAddOn("Blizzard_EditMode")
        end
        if not EditModeManagerFrame or not EditModeManagerFrame.GetLayouts then return end
        local layouts = EditModeManagerFrame:GetLayouts()
        if not layouts then return end
        local current = MattActionBarFontDB.editMode and MattActionBarFontDB.editMode.presetIndexOnLogin or 1
        for i, l in ipairs(layouts) do
            local info = UIDropDownMenu_CreateInfo()
            info.text = l.layoutName
            info.value = i
            info.func = function(btn)
                if not MattActionBarFontDB.editMode then MattActionBarFontDB.editMode = {} end
                MattActionBarFontDB.editMode.presetIndexOnLogin = i
                EditModeManagerFrame:SelectLayout(i)
                UIDropDownMenu_SetSelectedValue(edmLayoutDropdown, i)
                UIDropDownMenu_SetText(edmLayoutDropdown, l.layoutName)
                if MABFEDMStatusText then
                    MABFEDMStatusText:SetText("Selected: |cff90E4C1" .. l.layoutName .. "|r")
                end
            end
            info.checked = (current == i)
            UIDropDownMenu_AddButton(info, level)
        end
    end

    -- Delayed init (EditMode may not be loaded yet)
    C_Timer.After(1.5, function()
        UIDropDownMenu_Initialize(edmLayoutDropdown, InitializeEDMDropdown)
        if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
            C_AddOns.LoadAddOn("Blizzard_EditMode")
        end
        if EditModeManagerFrame and EditModeManagerFrame.GetLayouts then
            local layouts = EditModeManagerFrame:GetLayouts()
            local idx = MattActionBarFontDB.editMode and MattActionBarFontDB.editMode.presetIndexOnLogin or 1
            if layouts and layouts[idx] then
                UIDropDownMenu_SetText(edmLayoutDropdown, layouts[idx].layoutName)
            end
        end
    end)

    -- Status text
    local edmStatusText = pageEDM:CreateFontString("MABFEDMStatusText", "OVERLAY", "GameFontNormal")
    edmStatusText:SetPoint("TOPLEFT", edmLayoutLabel, "BOTTOMLEFT", 0, -30)
    edmStatusText:SetText("Selected: |cff888888loading...|r")
    edmStatusText:SetTextColor(1, 1, 1)

    -- Divider line
    local edmDivider = pageEDM:CreateTexture(nil, "ARTWORK")
    edmDivider:SetColorTexture(0.35, 0.03, 0.03, 0.7)
    edmDivider:SetSize(260, 1)
    edmDivider:SetPoint("TOPLEFT", edmStatusText, "BOTTOMLEFT", 0, -16)

    -- Minimap button show/hide checkbox (moved to System page)
    local minimapCheck = CreateFrame("CheckButton", "MABFMinimapCheck", pageEDM, "InterfaceOptionsCheckButtonTemplate")
    minimapCheck:ClearAllPoints()
    minimapCheck:SetPoint("TOPLEFT", edmDivider, "BOTTOMLEFT", -2, -10)
    local minimapText = _G[minimapCheck:GetName() .. "Text"]
    minimapText:SetText("Show Minimap Button")
    minimapText:SetTextColor(1, 1, 1)
    minimapCheck:SetChecked(not (MattActionBarFontDB.minimap and MattActionBarFontDB.minimap.hide))
    minimapCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.minimap = MattActionBarFontDB.minimap or {}
        local show = self:GetChecked()
        local ldbIcon = LibStub("LibDBIcon-1.0", true)
        if show then
            MattActionBarFontDB.minimap.hide = nil
            if ldbIcon then ldbIcon:Show("MABF") end
        else
            MattActionBarFontDB.minimap.hide = true
            if ldbIcon then ldbIcon:Hide("MABF") end
        end
    end)

    --------------------------------------------------------------------------

    --------------------------------------------------------------------------
    -- Reset All Settings Section
    --------------------------------------------------------------------------
    -- Section divider
    local resetDivider = pageEDM:CreateTexture(nil, "ARTWORK")
    resetDivider:SetColorTexture(0.8, 0.05, 0.05, 0.8)
    resetDivider:SetSize(260, 2)
    resetDivider:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", -2, -20)

    -- Reset Settings Title (in bold red)
    local resetTitle = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    resetTitle:SetPoint("TOPLEFT", resetDivider, "BOTTOMLEFT", 0, -16)
    resetTitle:SetText("Reset All Settings")
    resetTitle:SetTextColor(1, 0, 0, 1) -- Red color
    resetTitle:SetFont("Fonts\\FRIZQT__.TTF", 11, "THICKOUTLINE") -- Bold/thick outline

    -- Reset Settings Description
    local resetDesc = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetDesc:SetPoint("TOPLEFT", resetTitle, "BOTTOMLEFT", 0, -6)
    resetDesc:SetText("|cffff0000This will restore all settings to default values|r")
    resetDesc:SetFont("Fonts\\FRIZQT__.TTF", 9)

    -- Reset Button
    local resetButton = CreateFrame("Button", "MABFResetButton", pageEDM, "UIPanelButtonTemplate")
    resetButton:SetSize(150, 28)
    resetButton:SetPoint("TOPLEFT", resetDesc, "BOTTOMLEFT", 0, -14)
    resetButton:SetText("Reset to Defaults")
    resetButton:SetNormalFontObject("GameFontRed")
    resetButton:SetScript("OnClick", function(self)
        StaticPopup_Show("MABF_RESET_SETTINGS")
    end)

    --------------------------------------------------------------------------
    -- Quests Page
    --------------------------------------------------------------------------
    local questsTitle = CreatePageTitle(pageQuests, "Quest Tweaks")

    -- Auto Accept Quests
    local autoAcceptCheck = CreateFrame("CheckButton", "MABFAutoAcceptCheck", pageQuests, "InterfaceOptionsCheckButtonTemplate")
    autoAcceptCheck:ClearAllPoints()
    autoAcceptCheck:SetPoint("TOPLEFT", questsTitle, "BOTTOMLEFT", 0, -8)
    local autoAcceptText = _G[autoAcceptCheck:GetName().."Text"]
    autoAcceptText:SetText("Auto Accept Quests")
    autoAcceptText:SetTextColor(1, 1, 1)
    local autoAcceptDesc = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoAcceptDesc:SetPoint("TOPLEFT", autoAcceptCheck, "BOTTOMLEFT", 26, 2)
    autoAcceptDesc:SetText("|cff888888Hold Shift to skip|r")
    autoAcceptDesc:SetScale(0.85)
    autoAcceptCheck:SetChecked(MattActionBarFontDB.autoAcceptQuests)
    autoAcceptCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.autoAcceptQuests = self:GetChecked()
        MABF:SetupQuestTweaks()
    end)

    -- Auto Turn In Quests
    local autoTurnInCheck = CreateFrame("CheckButton", "MABFAutoTurnInCheck", pageQuests, "InterfaceOptionsCheckButtonTemplate")
    autoTurnInCheck:ClearAllPoints()
    autoTurnInCheck:SetPoint("TOPLEFT", autoAcceptCheck, "BOTTOMLEFT", 0, checkSpacing)
    local autoTurnInText = _G[autoTurnInCheck:GetName().."Text"]
    autoTurnInText:SetText("Auto Turn In Quests")
    autoTurnInText:SetTextColor(1, 1, 1)
    local autoTurnInDesc = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoTurnInDesc:SetPoint("TOPLEFT", autoTurnInCheck, "BOTTOMLEFT", 26, 2)
    autoTurnInDesc:SetText("|cff888888Skips quests with reward choices|r")
    autoTurnInDesc:SetScale(0.85)
    autoTurnInCheck:SetChecked(MattActionBarFontDB.autoTurnInQuests)
    autoTurnInCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.autoTurnInQuests = self:GetChecked()
        MABF:SetupQuestTweaks()
    end)

    --------------------------------------------------------------------------
    -- Bags Page
    --------------------------------------------------------------------------
    local bagsTitle = CreatePageTitle(pageBags, "Bag Tweaks")

    -- Bag Item Levels
    local bagIlvlCheck = CreateFrame("CheckButton", "MABFBagIlvlCheck", pageBags, "InterfaceOptionsCheckButtonTemplate")
    bagIlvlCheck:ClearAllPoints()
    bagIlvlCheck:SetPoint("TOPLEFT", bagsTitle, "BOTTOMLEFT", 0, -8)
    local bagIlvlText = _G[bagIlvlCheck:GetName().."Text"]
    bagIlvlText:SetText("Show Item Levels in Bags")
    bagIlvlText:SetTextColor(1, 1, 1)
    local bagIlvlDesc = pageBags:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bagIlvlDesc:SetPoint("TOPLEFT", bagIlvlCheck, "BOTTOMLEFT", 26, 2)
    bagIlvlDesc:SetText("|cff888888Displays ilvl on gear in bags & bank|r")
    bagIlvlDesc:SetScale(0.85)
    bagIlvlCheck:SetChecked(MattActionBarFontDB.enableBagItemLevels)
    bagIlvlCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableBagItemLevels = self:GetChecked()
        if MattActionBarFontDB.enableBagItemLevels then
            MABF:EnableBagItemLevels()
        else
            MABF:DisableBagItemLevels()
        end
    end)

    --------------------------------------------------------------------------
    -- Merchant Page
    --------------------------------------------------------------------------
    local merchantTitle = CreatePageTitle(pageMerchant, "Merchant Tweaks")

    -- Auto Repair
    local autoRepairCheck = CreateFrame("CheckButton", "MABFAutoRepairCheck", pageMerchant, "InterfaceOptionsCheckButtonTemplate")
    autoRepairCheck:ClearAllPoints()
    autoRepairCheck:SetPoint("TOPLEFT", merchantTitle, "BOTTOMLEFT", 0, -8)
    local autoRepairText = _G[autoRepairCheck:GetName().."Text"]
    autoRepairText:SetText("Auto Repair")
    autoRepairText:SetTextColor(1, 1, 1)
    local autoRepairDesc = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoRepairDesc:SetPoint("TOPLEFT", autoRepairCheck, "BOTTOMLEFT", 26, 2)
    autoRepairDesc:SetText("|cff888888Automatically repairs gear at merchants|r")
    autoRepairDesc:SetScale(0.85)
    autoRepairCheck:SetChecked(MattActionBarFontDB.enableAutoRepair)
    autoRepairCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableAutoRepair = self:GetChecked()
        MABF:SetupMerchantTweaks()
    end)

    -- Funding Source (Guild / Player)
    local fundingLabel = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fundingLabel:SetPoint("TOPLEFT", autoRepairDesc, "BOTTOMLEFT", 0, -6)
    fundingLabel:SetText("Repair Funding:")
    fundingLabel:SetTextColor(0.9, 0.9, 0.9)
    fundingLabel:SetFont("Fonts\\FRIZQT__.TTF", 9)

    local fundingGuild = CreateFrame("CheckButton", "MABFFundingGuild", pageMerchant, "UIRadioButtonTemplate")
    fundingGuild:SetPoint("TOPLEFT", fundingLabel, "BOTTOMLEFT", 0, -2)
    local fundingGuildText = fundingGuild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fundingGuildText:SetPoint("LEFT", fundingGuild, "RIGHT", 2, 0)
    fundingGuildText:SetText("|cffffffffGuild first, then personal|r")
    fundingGuildText:SetFont("Fonts\\FRIZQT__.TTF", 9)

    local fundingPlayer = CreateFrame("CheckButton", "MABFFundingPlayer", pageMerchant, "UIRadioButtonTemplate")
    fundingPlayer:SetPoint("TOPLEFT", fundingGuild, "BOTTOMLEFT", 0, -2)
    local fundingPlayerText = fundingPlayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fundingPlayerText:SetPoint("LEFT", fundingPlayer, "RIGHT", 2, 0)
    fundingPlayerText:SetText("|cffffffffPersonal only|r")
    fundingPlayerText:SetFont("Fonts\\FRIZQT__.TTF", 9)

    local function UpdateFundingRadios()
        local src = MattActionBarFontDB.autoRepairFundingSource or "GUILD"
        fundingGuild:SetChecked(src == "GUILD")
        fundingPlayer:SetChecked(src == "PLAYER")
    end
    UpdateFundingRadios()

    fundingGuild:SetScript("OnClick", function()
        MattActionBarFontDB.autoRepairFundingSource = "GUILD"
        UpdateFundingRadios()
    end)
    fundingPlayer:SetScript("OnClick", function()
        MattActionBarFontDB.autoRepairFundingSource = "PLAYER"
        UpdateFundingRadios()
    end)

    -- Auto Sell Junk
    local autoSellCheck = CreateFrame("CheckButton", "MABFAutoSellJunkCheck", pageMerchant, "InterfaceOptionsCheckButtonTemplate")
    autoSellCheck:ClearAllPoints()
    autoSellCheck:SetPoint("TOPLEFT", fundingPlayer, "BOTTOMLEFT", -26, -8)
    local autoSellText = _G[autoSellCheck:GetName().."Text"]
    autoSellText:SetText("Auto Sell Junk")
    autoSellText:SetTextColor(1, 1, 1)
    local autoSellDesc = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoSellDesc:SetPoint("TOPLEFT", autoSellCheck, "BOTTOMLEFT", 26, 2)
    autoSellDesc:SetText("|cff888888Sells grey items when visiting a vendor|r")
    autoSellDesc:SetScale(0.85)
    autoSellCheck:SetChecked(MattActionBarFontDB.enableAutoSellJunk)
    autoSellCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableAutoSellJunk = self:GetChecked()
        MABF:SetupMerchantTweaks()
    end)

    --------------------------------------------------------------------------
    -- QC Features Page (Quick Commands)
    local qcTitle = CreatePageTitle(pageSystem, "Quick Commands")

    -- Keybind Mode (/kb)
    local quickBindCheck = CreateFrame("CheckButton", "MABFQuickBindCheck", pageSystem, "InterfaceOptionsCheckButtonTemplate")
    quickBindCheck:ClearAllPoints()
    quickBindCheck:SetPoint("TOPLEFT", qcTitle, "BOTTOMLEFT", 0, -8)
    local quickBindText = _G[quickBindCheck:GetName().."Text"]
    quickBindText:SetText("Keybind Mode |cffffd100(/kb)|r")
    quickBindText:SetTextColor(1, 1, 1)
    quickBindCheck:SetChecked(MattActionBarFontDB.enableQuickBind)
    quickBindCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableQuickBind = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    -- Reload UI (/rl)
    local reloadAliasCheck = CreateFrame("CheckButton", "MABFReloadAliasCheck", pageSystem, "InterfaceOptionsCheckButtonTemplate")
    reloadAliasCheck:ClearAllPoints()
    reloadAliasCheck:SetPoint("TOPLEFT", quickBindCheck, "BOTTOMLEFT", 0, checkSpacing)
    local reloadAliasText = _G[reloadAliasCheck:GetName().."Text"]
    reloadAliasText:SetText("Reload UI |cffffd100(/rl)|r")
    reloadAliasText:SetTextColor(1, 1, 1)
    reloadAliasCheck:SetChecked(MattActionBarFontDB.enableReloadAlias)
    reloadAliasCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableReloadAlias = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    -- Edit Mode (/edit)
    local editModeAliasCheck = CreateFrame("CheckButton", "MABFEditModeAliasCheck", pageSystem, "InterfaceOptionsCheckButtonTemplate")
    editModeAliasCheck:ClearAllPoints()
    editModeAliasCheck:SetPoint("TOPLEFT", reloadAliasCheck, "BOTTOMLEFT", 0, checkSpacing)
    local editModeAliasText = _G[editModeAliasCheck:GetName().."Text"]
    editModeAliasText:SetText("Edit Mode |cffffd100(/edit)|r")
    editModeAliasText:SetTextColor(1, 1, 1)
    editModeAliasCheck:SetChecked(MattActionBarFontDB.enableEditModeAlias)
    editModeAliasCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableEditModeAlias = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    -- Pull Timer (/pull X)
    local pullAliasCheck = CreateFrame("CheckButton", "MABFPullAliasCheck", pageSystem, "InterfaceOptionsCheckButtonTemplate")
    pullAliasCheck:ClearAllPoints()
    pullAliasCheck:SetPoint("TOPLEFT", editModeAliasCheck, "BOTTOMLEFT", 0, checkSpacing)
    local pullAliasText = _G[pullAliasCheck:GetName().."Text"]
    pullAliasText:SetText("Pull Timer |cffffd100(/pull X)|r")
    pullAliasText:SetTextColor(1, 1, 1)
    pullAliasCheck:SetChecked(MattActionBarFontDB.enablePullAlias)
    pullAliasCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enablePullAlias = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    -- Allow the options window to be closed with Escape.
    tinsert(UISpecialFrames, "MABFOptionsFrame")
end

-----------------------------------------------------------
-- Static Popup Dialog for Reset Settings
-----------------------------------------------------------
StaticPopupDialogs["MABF_RESET_SETTINGS"] = {
    text = "|cffff0000|cff881111WARNING:|r |cffff0000This will reset ALL settings to default values. This action cannot be undone!|r",
    button1 = "Reset All Settings",
    button2 = "Cancel",
    OnAccept = function()
        -- Clear all existing settings
        MattActionBarFontDB = {}
        -- Apply defaults from MABFDefaults.lua
        MABF:ApplyDefaults()
        -- Reload UI to apply changes
        ReloadUI()
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-----------------------------------------------------------
-- Static Popup Dialog for Reload UI
-----------------------------------------------------------
StaticPopupDialogs["MABF_RELOAD_UI"] = {
    text = "A reload is required to apply this change. Reload now?",
    button1 = "Reload UI",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
