-- MABFOptions.lua
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

-----------------------------------------------------------
-- Options Window Creation with Vertical Tabs
-----------------------------------------------------------
function MABF:CreateOptionsWindow()
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
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        tileSize = 0,
        edgeSize = 1,
        insets   = { left = 2, right = 2, top = 2, bottom = 2 }
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
    }
    local tagline = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    tagline:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -2)
    tagline:SetText("|cff666666" .. taglines[math.random(#taglines)] .. "|r")
    tagline:SetFont("Fonts\\FRIZQT__.TTF", 8)

    local fullName = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fullName:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -8, 6)
    fullName:SetText("|cffFFFFFFMatt's Action Bar Fonts & UI QoL|r")
    fullName:SetFont("Fonts\\FRIZQT__.TTF", 7)

    ------------------------------------------------------------------------------
    -- Create Left Panel for Tabs
    ------------------------------------------------------------------------------
    local leftPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    leftPanel:SetSize(100, 510)
    leftPanel:SetPoint("TOPLEFT", f, "TOPLEFT", 10, -45)
    leftPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        tileSize = 0,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    leftPanel:SetBackdropColor(0.08, 0.08, 0.1, 1)
    leftPanel:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    ------------------------------------------------------------------------------
    -- Create Right Panel for Content Pages
    ------------------------------------------------------------------------------
    local rightPanel = CreateFrame("Frame", nil, f, "BackdropTemplate")
    rightPanel:SetSize(295, 510)
    rightPanel:SetPoint("TOPLEFT", leftPanel, "TOPRIGHT", 6, 0)
    rightPanel:SetBackdrop({
        bgFile   = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        tile     = false,
        tileSize = 0,
        edgeSize = 1,
        insets   = { left = 1, right = 1, top = 1, bottom = 1 }
    })
    rightPanel:SetBackdropColor(0.08, 0.08, 0.1, 1)
    rightPanel:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

    local THEME_ACCENT = {0.86, 0, 0}
    local TAB_NORMAL = {0.06, 0.06, 0.08, 1}
    local TAB_SELECTED = {0.12, 0.12, 0.15, 1}
    local TAB_BORDER = {0.18, 0.18, 0.22, 1}
    local TAB_TEXT_NORMAL = {0.7, 0.7, 0.7, 1}
    local TAB_TEXT_ACTIVE = {1, 1, 1, 1}
    local CONTENT_SPACING = -22
    local PAGE_WIDTH = 260
    local MABF_FONT = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
    local ROW_GAP_TIGHT = -4
    local ROW_GAP = -8
    local DESC_TEXT_OFFSET_X = 26

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

    --------------------------------------------------------------------------
    -- Declare Pages Table (used by tab buttons)
    --------------------------------------------------------------------------
    local pages = {}

    local function CreatePageTitle(page, text)
        local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
        title:SetText(text)
        title:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
        return title
    end

    local function CreateContentPage(index)
        local page = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
        page:SetAllPoints(rightPanel)
        pages[index] = page
        return page
    end

    local function CreateBasicCheckbox(parent, name, anchorTo, anchorPoint, xOffset, yOffset, labelText, checkedValue, onClick)
        local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
        cb:ClearAllPoints()
        cb:SetPoint(anchorPoint or "TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset or 0, yOffset or 0)
        local label = _G[cb:GetName().."Text"]
        label:SetText(labelText or "")
        label:SetTextColor(1, 1, 1)
        cb:SetChecked(checkedValue and true or false)
        if onClick then
            cb:SetScript("OnClick", onClick)
        end
        return cb, label
    end

    ------------------------------------------------------------------------------
    -- Create Vertical Tab Buttons in Left Panel (with section headers)
    ------------------------------------------------------------------------------
    local tabButtons = {}  -- all page-switching buttons (indices match pages[])
    local allTabButtons = {} -- all buttons for unified deselect
    local tabHeight = 28
    local tabGap = 2
    local sectionGap = 6
    local TAB_FONT = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
    local TAB_FONT_SIZE = 10

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

    local function SetTabButtonState(btn, isActive)
        btn.isActive = isActive and true or false
        if btn.isActive then
            btn:SetBackdropColor(TAB_SELECTED[1], TAB_SELECTED[2], TAB_SELECTED[3], TAB_SELECTED[4])
            btn:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.85)
            if btn.text then
                btn.text:SetTextColor(TAB_TEXT_ACTIVE[1], TAB_TEXT_ACTIVE[2], TAB_TEXT_ACTIVE[3], TAB_TEXT_ACTIVE[4])
            end
        else
            btn:SetBackdropColor(TAB_NORMAL[1], TAB_NORMAL[2], TAB_NORMAL[3], TAB_NORMAL[4])
            btn:SetBackdropBorderColor(TAB_BORDER[1], TAB_BORDER[2], TAB_BORDER[3], TAB_BORDER[4])
            if btn.text then
                btn.text:SetTextColor(TAB_TEXT_NORMAL[1], TAB_TEXT_NORMAL[2], TAB_TEXT_NORMAL[3], TAB_TEXT_NORMAL[4])
            end
        end
    end

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
        SetTabButtonState(btn, false)
        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER")
        btnText:SetText(label)
        btnText:SetFont(TAB_FONT, TAB_FONT_SIZE, "OUTLINE")
        btn.text = btnText
        SetTabButtonState(btn, false)
        btn:SetScript("OnEnter", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.5)
                if self.text then
                    self.text:SetTextColor(0.9, 0.9, 0.9, 1)
                end
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(TAB_BORDER[1], TAB_BORDER[2], TAB_BORDER[3], TAB_BORDER[4])
                if self.text then
                    self.text:SetTextColor(TAB_TEXT_NORMAL[1], TAB_TEXT_NORMAL[2], TAB_TEXT_NORMAL[3], TAB_TEXT_NORMAL[4])
                end
            end
        end)
        table.insert(allTabButtons, btn)
        return btn
    end

    local function TabOnClick(btn, pageIndex)
        for j, page in ipairs(pages) do page:Hide() end
        pages[pageIndex]:Show()
        for _, b in ipairs(allTabButtons) do
            SetTabButtonState(b, false)
        end
        SetTabButtonState(btn, true)
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

    for idx, btn in pairs(tabButtons) do
        local pi = idx
        btn:SetScript("OnClick", function(self) TabOnClick(self, pi) end)
    end

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

    editModeBtn:SetScript("OnClick", function()
        if MABFOptionsFrame then
            MABFOptionsFrame:Hide()
        end
        ShowUIPanel(EditModeManagerFrame)
    end)

    ------------------------------------------------------------------------------
    -- Create Content Pages as Children of Right Panel
    ------------------------------------------------------------------------------
    local SLIDER_FONT = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
    local SLIDER_FONT_SIZE = 9
    local SLIDER_MINMAX_SIZE = 8
    local function StyleMinimalCheckbox(checkButton)
        if not checkButton or checkButton._mabfMinimalStyled then return end
        checkButton._mabfMinimalStyled = true

        local normal = checkButton.GetNormalTexture and checkButton:GetNormalTexture() or nil
        local pushed = checkButton.GetPushedTexture and checkButton:GetPushedTexture() or nil
        local highlight = checkButton.GetHighlightTexture and checkButton:GetHighlightTexture() or nil
        local disabled = checkButton.GetDisabledTexture and checkButton:GetDisabledTexture() or nil
        local checked = checkButton.GetCheckedTexture and checkButton:GetCheckedTexture() or nil
        if normal then normal:SetTexture(nil) normal:SetAlpha(0) normal:Hide() end
        if pushed then pushed:SetTexture(nil) pushed:SetAlpha(0) pushed:Hide() end
        if highlight then highlight:SetTexture(nil) highlight:SetAlpha(0) highlight:Hide() end
        if disabled then disabled:SetTexture(nil) disabled:SetAlpha(0) disabled:Hide() end
        if checked then checked:SetTexture(nil) checked:SetAlpha(0) checked:Hide() end

        if checkButton.SetHitRectInsets then
            checkButton:SetHitRectInsets(0, -220, 0, 0)
        end

        local box = CreateFrame("Frame", nil, checkButton)
        box:SetSize(14, 14)
        box:SetPoint("LEFT", checkButton, "LEFT", 0, 0)
        checkButton._mabfBox = box

        local bg = box:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.1, 1)
        checkButton._mabfBg = bg

        local border = box:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.25, 0.25, 0.3, 1)
        checkButton._mabfBorder = border

        local mark = box:CreateTexture(nil, "ARTWORK")
        mark:SetSize(8, 8)
        mark:SetPoint("CENTER")
        mark:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
        checkButton._mabfCheck = mark

        local function UpdateMark(self)
            if self._mabfCheck then
                self._mabfCheck:SetShown(self:GetChecked() and true or false)
            end
        end

        UpdateMark(checkButton)
        checkButton:HookScript("OnClick", UpdateMark)
        checkButton:HookScript("OnShow", UpdateMark)

        checkButton:HookScript("OnEnter", function(self)
            if self._mabfBorder then
                self._mabfBorder:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
            end
        end)
        checkButton:HookScript("OnLeave", function(self)
            if self._mabfBorder then
                self._mabfBorder:SetColorTexture(0.25, 0.25, 0.3, 1)
            end
        end)

        local textLabel = checkButton.GetName and _G[(checkButton:GetName() or "").."Text"] or nil
        if textLabel then
            textLabel:ClearAllPoints()
            textLabel:SetPoint("LEFT", box, "RIGHT", 6, 0)
            textLabel:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")
            textLabel:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end

    local function StyleMinimalRadio(radioButton, textLabel)
        if not radioButton or radioButton._mabfMinimalRadioStyled then return end
        radioButton._mabfMinimalRadioStyled = true

        local normal = radioButton.GetNormalTexture and radioButton:GetNormalTexture() or nil
        local pushed = radioButton.GetPushedTexture and radioButton:GetPushedTexture() or nil
        local highlight = radioButton.GetHighlightTexture and radioButton:GetHighlightTexture() or nil
        local disabled = radioButton.GetDisabledTexture and radioButton:GetDisabledTexture() or nil
        local checked = radioButton.GetCheckedTexture and radioButton:GetCheckedTexture() or nil
        if normal then normal:SetTexture(nil) normal:SetAlpha(0) normal:Hide() end
        if pushed then pushed:SetTexture(nil) pushed:SetAlpha(0) pushed:Hide() end
        if highlight then highlight:SetTexture(nil) highlight:SetAlpha(0) highlight:Hide() end
        if disabled then disabled:SetTexture(nil) disabled:SetAlpha(0) disabled:Hide() end
        if checked then checked:SetTexture(nil) checked:SetAlpha(0) checked:Hide() end

        radioButton:SetSize(12, 12)
        if radioButton.SetHitRectInsets then
            radioButton:SetHitRectInsets(0, -220, 0, 0)
        end

        local box = CreateFrame("Frame", nil, radioButton)
        box:SetSize(12, 12)
        box:SetPoint("LEFT", radioButton, "LEFT", 0, 0)
        radioButton._mabfRadioBox = box

        local bg = box:CreateTexture(nil, "BACKGROUND")
        bg:SetAllPoints()
        bg:SetColorTexture(0.08, 0.08, 0.1, 1)
        radioButton._mabfRadioBg = bg

        local border = box:CreateTexture(nil, "BORDER")
        border:SetPoint("TOPLEFT", -1, 1)
        border:SetPoint("BOTTOMRIGHT", 1, -1)
        border:SetColorTexture(0.25, 0.25, 0.3, 1)
        radioButton._mabfRadioBorder = border

        local mark = box:CreateTexture(nil, "ARTWORK")
        mark:SetSize(6, 6)
        mark:SetPoint("CENTER")
        mark:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
        radioButton._mabfRadioMark = mark

        local function UpdateMark(self)
            if self and self._mabfRadioMark then
                self._mabfRadioMark:SetShown(self:GetChecked() and true or false)
            end
        end

        radioButton._mabfRefreshMark = function()
            UpdateMark(radioButton)
        end
        UpdateMark(radioButton)
        radioButton:HookScript("OnClick", UpdateMark)
        radioButton:HookScript("OnShow", UpdateMark)

        radioButton:HookScript("OnEnter", function(self)
            if self._mabfRadioBorder then
                self._mabfRadioBorder:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
            end
        end)
        radioButton:HookScript("OnLeave", function(self)
            if self._mabfRadioBorder then
                self._mabfRadioBorder:SetColorTexture(0.25, 0.25, 0.3, 1)
            end
        end)

        if textLabel then
            textLabel:ClearAllPoints()
            textLabel:SetPoint("LEFT", box, "RIGHT", 6, 0)
            textLabel:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")
            textLabel:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end

    local function StyleMinimalDropdown(dropdown)
        if not dropdown or dropdown._mabfMinimalStyled then return end
        dropdown._mabfMinimalStyled = true

        local name = dropdown.GetName and dropdown:GetName() or nil
        if not name then return end

        local left = _G[name.."Left"]
        local middle = _G[name.."Middle"]
        local right = _G[name.."Right"]
        local button = _G[name.."Button"]
        local text = _G[name.."Text"]

        if left then left:SetTexture(nil) left:SetAlpha(0) left:Hide() end
        if middle then middle:SetTexture(nil) middle:SetAlpha(0) middle:Hide() end
        if right then right:SetTexture(nil) right:SetAlpha(0) right:Hide() end

        if not button then return end

        local ntex = button.GetNormalTexture and button:GetNormalTexture() or nil
        local ptex = button.GetPushedTexture and button:GetPushedTexture() or nil
        local htex = button.GetHighlightTexture and button:GetHighlightTexture() or nil
        local dtex = button.GetDisabledTexture and button:GetDisabledTexture() or nil
        if ntex then ntex:SetTexture(nil) ntex:SetAlpha(0) ntex:Hide() end
        if ptex then ptex:SetTexture(nil) ptex:SetAlpha(0) ptex:Hide() end
        if htex then htex:SetTexture(nil) htex:SetAlpha(0) htex:Hide() end
        if dtex then dtex:SetTexture(nil) dtex:SetAlpha(0) dtex:Hide() end

        if not button._mabfBg then
            local bg = CreateFrame("Frame", nil, button, "BackdropTemplate")
            bg:SetPoint("TOPLEFT", button, "TOPLEFT", 16, -1)
            bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -16, 1)
            bg:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            bg:SetBackdropColor(0.06, 0.06, 0.08, 1)
            bg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            button._mabfBg = bg

            local arrowBox = CreateFrame("Frame", nil, bg, "BackdropTemplate")
            arrowBox:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
            arrowBox:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
            arrowBox:SetWidth(20)
            arrowBox:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            arrowBox:SetBackdropColor(0.05, 0.05, 0.06, 1)
            arrowBox:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
            button._mabfArrowBox = arrowBox

            local arrow = arrowBox:CreateFontString(nil, "OVERLAY")
            arrow:SetPoint("CENTER", arrowBox, "CENTER", 0, 0)
            arrow:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 12, "OUTLINE")
            arrow:SetText("v")
            arrow:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.95)
            button._mabfArrow = arrow

            button:HookScript("OnEnter", function(self)
                if self._mabfBg then
                    self._mabfBg:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
                end
            end)
            button:HookScript("OnLeave", function(self)
                if self._mabfBg then
                    self._mabfBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                end
            end)
        end

        if text then
            text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")
            text:SetTextColor(0.9, 0.9, 0.9, 1)
            text:ClearAllPoints()
            text:SetPoint("LEFT", button._mabfBg, "LEFT", 8, 0)
            text:SetPoint("RIGHT", button._mabfBg, "RIGHT", -24, 0)
            text:SetJustifyH("RIGHT")
        end
    end

    local function StyleMinimalButton(btn, isDanger)
        if not btn or btn._mabfMinimalStyled then return end
        btn._mabfMinimalStyled = true

        local ntex = btn.GetNormalTexture and btn:GetNormalTexture() or nil
        local ptex = btn.GetPushedTexture and btn:GetPushedTexture() or nil
        local htex = btn.GetHighlightTexture and btn:GetHighlightTexture() or nil
        local dtex = btn.GetDisabledTexture and btn:GetDisabledTexture() or nil
        if ntex then ntex:SetTexture(nil) ntex:SetAlpha(0) ntex:Hide() end
        if ptex then ptex:SetTexture(nil) ptex:SetAlpha(0) ptex:Hide() end
        if htex then htex:SetTexture(nil) htex:SetAlpha(0) htex:Hide() end
        if dtex then dtex:SetTexture(nil) dtex:SetAlpha(0) dtex:Hide() end

        local bgTarget = btn
        if not btn.SetBackdrop then
            local bgFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
            bgFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
            bgFrame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
            bgFrame:SetFrameLevel(math.max(btn:GetFrameLevel() - 1, 1))
            btn._mabfButtonBg = bgFrame
            bgTarget = bgFrame
        end

        bgTarget:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        if isDanger then
            bgTarget:SetBackdropColor(0.28, 0.02, 0.02, 1)
            bgTarget:SetBackdropBorderColor(0.55, 0.05, 0.05, 1)
        else
            bgTarget:SetBackdropColor(0.08, 0.08, 0.1, 1)
            bgTarget:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
        end

        local fs = btn.GetFontString and btn:GetFontString() or nil
        if fs then
            fs:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 11, "")
            if isDanger then
                fs:SetTextColor(1, 0.2, 0.2, 1)
            else
                fs:SetTextColor(0.9, 0.9, 0.9, 1)
            end
        end

        btn:HookScript("OnEnter", function(self)
            local target = self._mabfButtonBg or self
            if isDanger then
                target:SetBackdropBorderColor(1, 0.15, 0.15, 1)
            else
                target:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.8)
            end
        end)
        btn:HookScript("OnLeave", function(self)
            local target = self._mabfButtonBg or self
            if isDanger then
                target:SetBackdropBorderColor(0.55, 0.05, 0.05, 1)
            else
                target:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
            end
        end)
        btn:HookScript("OnMouseDown", function(self)
            local target = self._mabfButtonBg or self
            if isDanger then
                target:SetBackdropColor(0.22, 0.02, 0.02, 1)
            else
                target:SetBackdropColor(0.06, 0.06, 0.08, 1)
            end
        end)
        btn:HookScript("OnMouseUp", function(self)
            local target = self._mabfButtonBg or self
            if isDanger then
                target:SetBackdropColor(0.28, 0.02, 0.02, 1)
            else
                target:SetBackdropColor(0.08, 0.08, 0.1, 1)
            end
        end)
    end

    local activeMinimalDropdown = nil
    local function CreateMinimalDropdown(parent, width, visibleRows)
        local fontPath = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
        local rowHeight = 20
        visibleRows = math.max(1, visibleRows or 8)

        local dd = CreateFrame("Frame", nil, parent)
        dd:SetSize(width, 20)
        dd.options = {}
        dd.selectedValue = nil
        dd.offset = 0
        dd._updatingScroll = false
        dd.onSelect = nil
        dd.onOpen = nil

        local function NormalizeOptions(raw)
            local out = {}
            for _, opt in ipairs(raw or {}) do
                if type(opt) == "table" and opt.value ~= nil and opt.label ~= nil then
                    out[#out + 1] = { value = opt.value, label = tostring(opt.label) }
                elseif type(opt) == "string" then
                    out[#out + 1] = { value = opt, label = opt }
                end
            end
            return out
        end

        local function FindByValue(value)
            for _, opt in ipairs(dd.options) do
                if opt.value == value then
                    return opt
                end
            end
            return nil
        end

        dd.button = CreateFrame("Button", nil, dd, "BackdropTemplate")
        dd.button:SetAllPoints()
        dd.button:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        dd.button:SetBackdropColor(0.06, 0.06, 0.08, 1)
        dd.button:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

        dd.buttonText = dd.button:CreateFontString(nil, "OVERLAY")
        dd.buttonText:SetFont(fontPath, 10, "")
        dd.buttonText:SetPoint("LEFT", dd.button, "LEFT", 8, 0)
        dd.buttonText:SetPoint("RIGHT", dd.button, "RIGHT", -24, 0)
        dd.buttonText:SetJustifyH("LEFT")
        dd.buttonText:SetTextColor(0.9, 0.9, 0.9, 1)

        dd.arrowText = dd.button:CreateFontString(nil, "OVERLAY")
        dd.arrowText:SetFont(fontPath, 10, "")
        dd.arrowText:SetPoint("RIGHT", dd.button, "RIGHT", -8, 0)
        dd.arrowText:SetText("v")
        dd.arrowText:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.95)

        dd.list = CreateFrame("Frame", nil, f, "BackdropTemplate")
        dd.list:SetSize(width, (visibleRows * rowHeight) + 4)
        dd.list:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        dd.list:SetBackdropColor(0.06, 0.06, 0.08, 1)
        dd.list:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        dd.list:SetFrameStrata("DIALOG")
        dd.list:EnableMouseWheel(true)
        dd.list:Hide()

        dd.scroll = CreateFrame("Slider", nil, dd.list, "BackdropTemplate")
        dd.scroll:SetPoint("TOPRIGHT", dd.list, "TOPRIGHT", -2, -2)
        dd.scroll:SetPoint("BOTTOMRIGHT", dd.list, "BOTTOMRIGHT", -2, 2)
        dd.scroll:SetWidth(10)
        dd.scroll:SetOrientation("VERTICAL")
        dd.scroll:SetMinMaxValues(0, 0)
        dd.scroll:SetValueStep(1)
        dd.scroll:SetObeyStepOnDrag(true)
        dd.scroll:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        dd.scroll:SetBackdropColor(0.03, 0.03, 0.04, 1)
        dd.scroll:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
        local thumb = dd.scroll:CreateTexture(nil, "OVERLAY")
        thumb:SetSize(8, 18)
        thumb:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
        dd.scroll:SetThumbTexture(thumb)

        dd.rows = {}
        for i = 1, visibleRows do
            local row = CreateFrame("Button", nil, dd.list, "BackdropTemplate")
            row:SetSize(width - 14, rowHeight)
            row:SetPoint("TOPLEFT", dd.list, "TOPLEFT", 1, -1 - (i - 1) * rowHeight)
            row.bg = row:CreateTexture(nil, "BACKGROUND")
            row.bg:SetAllPoints()
            row.bg:SetColorTexture(0, 0, 0, 0)
            row.text = row:CreateFontString(nil, "OVERLAY")
            row.text:SetFont(fontPath, 10, "")
            row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
            row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
            row.text:SetJustifyH("LEFT")
            row.text:SetTextColor(0.9, 0.9, 0.9, 1)
            row:SetScript("OnEnter", function(self)
                self.bg:SetColorTexture(THEME_ACCENT[1] * 0.2, THEME_ACCENT[2] * 0.2, THEME_ACCENT[3] * 0.2, 0.6)
                self.text:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
            end)
            row:SetScript("OnLeave", function(self)
                self.bg:SetColorTexture(0, 0, 0, 0)
                self.text:SetTextColor(0.9, 0.9, 0.9, 1)
            end)
            row:SetScript("OnClick", function(self)
                if not self.option then return end
                dd:SetSelectedValue(self.option.value)
                if dd.onSelect then dd.onSelect(self.option.value, self.option) end
                dd:Close()
            end)
            dd.rows[i] = row
        end

        function dd:Refresh()
            local maxOffset = math.max(0, #self.options - visibleRows)
            if self.offset < 0 then self.offset = 0 end
            if self.offset > maxOffset then self.offset = maxOffset end
            self.scroll:SetShown(maxOffset > 0)
            self.scroll:SetMinMaxValues(0, maxOffset)
            self._updatingScroll = true
            self.scroll:SetValue(self.offset)
            self._updatingScroll = false

            for i = 1, visibleRows do
                local opt = self.options[self.offset + i]
                local row = self.rows[i]
                if opt then
                    row.option = opt
                    row.text:SetText(opt.label:gsub("|", "||"))
                    row:Show()
                else
                    row.option = nil
                    row:Hide()
                end
            end
        end

        function dd:SetOptions(opts)
            self.options = NormalizeOptions(opts)
            self:Refresh()
        end

        function dd:SetSelectedValue(value)
            self.selectedValue = value
            opt = FindByValue(value)
            if opt then
                self.buttonText:SetTextColor(0.92, 0.92, 0.92, 1)
                self.buttonText:SetText(opt.label:gsub("|", "||"))
            elseif value ~= nil then
                self.buttonText:SetTextColor(0.75, 0.75, 0.75, 1)
                self.buttonText:SetText(tostring(value):gsub("|", "||"))
            else
                self.buttonText:SetTextColor(0.6, 0.6, 0.6, 1)
                self.buttonText:SetText("Select...")
            end
        end

        function dd:GetSelectedValue()
            return self.selectedValue
        end

        function dd:SetOnSelect(fn)
            self.onSelect = fn
        end

        function dd:SetOnOpen(fn)
            self.onOpen = fn
        end

        function dd:Close()
            self.list:Hide()
            if f._mabfDropdownCatcher then
                f._mabfDropdownCatcher:Hide()
            end
            if activeMinimalDropdown == self then
                activeMinimalDropdown = nil
            end
        end

        function dd:Open()
            if self.onOpen then self.onOpen(self) end
            self:Refresh()
            if #self.options == 0 then return end
            self.list:ClearAllPoints()
            self.list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
            self.list:SetFrameLevel(self:GetFrameLevel() + 20)
            self.list:Show()
            activeMinimalDropdown = self

            if not f._mabfDropdownCatcher then
                catcher = CreateFrame("Button", nil, f)
                catcher:SetAllPoints(f)
                catcher:SetScript("OnClick", function()
                    if activeMinimalDropdown then
                        activeMinimalDropdown:Close()
                    end
                end)
                f._mabfDropdownCatcher = catcher
            end
            f._mabfDropdownCatcher:SetFrameLevel(self.list:GetFrameLevel() - 1)
            f._mabfDropdownCatcher:Show()
        end

        dd.scroll:SetScript("OnValueChanged", function(_, value)
            if dd._updatingScroll then return end
            dd.offset = math.floor((value or 0) + 0.5)
            dd:Refresh()
        end)
        dd.list:SetScript("OnMouseWheel", function(_, delta)
            if delta > 0 then dd.offset = dd.offset - 1 else dd.offset = dd.offset + 1 end
            dd:Refresh()
        end)

        dd.button:SetScript("OnClick", function()
            if dd.list:IsShown() then dd:Close() else dd:Open() end
        end)
        dd.button:SetScript("OnEnter", function(self)
            self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
        end)
        dd.button:SetScript("OnLeave", function(self)
            self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        end)

        return dd
    end

    local function StyleSlider(slider)
        if not slider or not slider.GetName then return end
        name = slider:GetName()
        textLabel = _G[name.."Text"]
        lowLabel = _G[name.."Low"]
        highLabel = _G[name.."High"]

        leftTex = _G[name.."Left"]
        rightTex = _G[name.."Right"]
        middleTex = _G[name.."Middle"]
        if leftTex then leftTex:SetTexture(nil) leftTex:SetAlpha(0) end
        if rightTex then rightTex:SetTexture(nil) rightTex:SetAlpha(0) end
        if middleTex then middleTex:SetTexture(nil) middleTex:SetAlpha(0) end

        if not slider._mabfTrack then
            slider._mabfTrack = CreateFrame("Frame", nil, slider, "BackdropTemplate")
            slider._mabfTrack:SetPoint("LEFT", slider, "LEFT", 0, 0)
            slider._mabfTrack:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
            slider._mabfTrack:SetHeight(8)
            slider._mabfTrack:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
            })
            slider._mabfFill = slider._mabfTrack:CreateTexture(nil, "ARTWORK")
            slider._mabfFill:SetPoint("LEFT", slider._mabfTrack, "LEFT", 0, 0)
            slider._mabfFill:SetHeight(8)

            thumb = slider:CreateTexture(nil, "OVERLAY")
            thumb:SetSize(8, 14)
            thumb:SetColorTexture(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
            slider:SetThumbTexture(thumb)
            slider._mabfThumb = thumb
        end

        slider._mabfTrack:SetBackdropColor(0.06, 0.06, 0.08, 1)
        slider._mabfTrack:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        slider._mabfFill:SetColorTexture(THEME_ACCENT[1] * 0.5, THEME_ACCENT[2] * 0.5, THEME_ACCENT[3] * 0.6, 0.8)

        local function UpdateFill()
            local minV, maxV = slider:GetMinMaxValues()
            val = slider:GetValue()
            pct = 0
            if maxV and minV and maxV > minV then
                pct = (val - minV) / (maxV - minV)
            end
            slider._mabfFill:SetWidth(math.max(1, slider._mabfTrack:GetWidth() * pct))
        end

        UpdateFill()
        if not slider._mabfFillHooked then
            slider:HookScript("OnValueChanged", UpdateFill)
            slider:HookScript("OnEnter", function(self)
                if self._mabfTrack then
                    self._mabfTrack:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.6)
                end
            end)
            slider:HookScript("OnLeave", function(self)
                if self._mabfTrack then
                    self._mabfTrack:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                end
            end)
            slider._mabfFillHooked = true
        end

        if textLabel then
            textLabel:SetFont(SLIDER_FONT, SLIDER_FONT_SIZE, "OUTLINE")
            textLabel:SetTextColor(0.9, 0.9, 0.9)
            textLabel:ClearAllPoints()
            textLabel:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
            textLabel:SetJustifyH("LEFT")
        end
        if lowLabel then
            lowLabel:SetFont(SLIDER_FONT, SLIDER_MINMAX_SIZE, "OUTLINE")
            lowLabel:SetTextColor(0.6, 0.6, 0.6)
            lowLabel:ClearAllPoints()
            lowLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
        end
        if highLabel then
            highLabel:SetFont(SLIDER_FONT, SLIDER_MINMAX_SIZE, "OUTLINE")
            highLabel:SetTextColor(0.6, 0.6, 0.6)
            highLabel:ClearAllPoints()
            highLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
        end
    end

    -- Page 1: General Settings (with Macro slider integrated)
    pageGeneral = CreateContentPage(1)

    genLabel = CreatePageTitle(pageGeneral, "AB Text Sizes")

    mainSlider = CreateFrame("Slider", "MABFMainFontSizeSlider", pageGeneral, "OptionsSliderTemplate")
    mainSlider:SetSize(PAGE_WIDTH, 14)
    mainSlider:SetPoint("TOPLEFT", genLabel, "BOTTOMLEFT", 0, -18)
    mainSlider:SetMinMaxValues(10, 50)
    mainSlider:SetValue(MattActionBarFontDB.fontSize)
    mainSlider:SetValueStep(1)
    mainSlider:SetObeyStepOnDrag(true)
    mainSliderName = mainSlider:GetName()
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

    countSlider = CreateFrame("Slider", "MABFCountSizeSlider", pageGeneral, "OptionsSliderTemplate")
    countSlider:SetSize(PAGE_WIDTH, 14)
    countSlider:SetPoint("TOPLEFT", mainSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    countSlider:SetMinMaxValues(8, 30)
    countSlider:SetValue(MattActionBarFontDB.countFontSize)
    countSlider:SetValueStep(1)
    countSlider:SetObeyStepOnDrag(true)
    countSliderName = countSlider:GetName()
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

    macroSlider = CreateFrame("Slider", "MABFMacroTextSizeSlider", pageGeneral, "OptionsSliderTemplate")
    macroSlider:SetSize(PAGE_WIDTH, 14)
    macroSlider:SetPoint("TOPLEFT", countSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    macroSlider:SetMinMaxValues(8, 30)
    macroSlider:SetValue(MattActionBarFontDB.macroTextSize)
    macroSlider:SetValueStep(1)
    macroSlider:SetObeyStepOnDrag(true)
    macroSliderName = macroSlider:GetName()
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

    petBarSlider = CreateFrame("Slider", "MABFPetBarSizeSlider", pageGeneral, "OptionsSliderTemplate")
    petBarSlider:SetSize(PAGE_WIDTH, 14)
    petBarSlider:SetPoint("TOPLEFT", macroSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    petBarSlider:SetMinMaxValues(10, 50)
    petBarSlider:SetValue(MattActionBarFontDB.petBarFontSize)
    petBarSlider:SetValueStep(1)
    petBarSliderName = petBarSlider:GetName()
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

    dropdownTitle = pageGeneral:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    dropdownTitle:SetPoint("TOPLEFT", petBarSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    dropdownTitle:SetText("Actionbar Font:")
    dropdownTitle:SetTextColor(1, 1, 1)
    fontDropDown = CreateMinimalDropdown(pageGeneral, 150, 10)
    fontDropDown:SetPoint("TOPLEFT", dropdownTitle, "BOTTOMLEFT", 0, -6)
    local function BuildFontOptions()
        local fontsList = MABF:GetFontOptions()
        local opts = {}
        for _, fontName in ipairs(fontsList) do
            opts[#opts + 1] = { value = fontName, label = fontName }
        end
        return opts
    end
    fontDropDown:SetOptions(BuildFontOptions())
    fontDropDown:SetSelectedValue(MattActionBarFontDB.fontFamily)
    fontDropDown:SetOnOpen(function(self)
        self:SetOptions(BuildFontOptions())
        self:SetSelectedValue(MattActionBarFontDB.fontFamily)
    end)
    fontDropDown:SetOnSelect(function(value)
        MABF:SetSelectedFont(value)
        fontDropDown:SetSelectedValue(MattActionBarFontDB.fontFamily)
        print("|cFF00FF00MattActionBarFont:|r Font updated to: " .. tostring(MattActionBarFontDB.fontFamily))
        StaticPopup_Show("MABF_RELOAD_UI")
    end)



    -- Page 2: Offsets
    pageOffsets = CreateContentPage(2)

    abOffsetsLabel = CreatePageTitle(pageOffsets, "AB Offsets")

    abXOffsetSlider = CreateFrame("Slider", "MABFABXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abXOffsetSlider:SetSize(PAGE_WIDTH, 14)
    abXOffsetSlider:SetPoint("TOPLEFT", abOffsetsLabel, "BOTTOMLEFT", 0, -18)
    abXOffsetSlider:SetMinMaxValues(-100, 100)
    abXOffsetSlider:SetValue(MattActionBarFontDB.abXOffset)
    abXOffsetSlider:SetValueStep(1)
    abXOffsetSlider:SetObeyStepOnDrag(true)
    abXSliderName = abXOffsetSlider:GetName()
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

    abYOffsetSlider = CreateFrame("Slider", "MABFABYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    abYOffsetSlider:SetSize(PAGE_WIDTH, 14)
    abYOffsetSlider:SetPoint("TOPLEFT", abXOffsetSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    abYOffsetSlider:SetMinMaxValues(-100, 100)
    abYOffsetSlider:SetValue(MattActionBarFontDB.abYOffset)
    abYOffsetSlider:SetValueStep(1)
    abYOffsetSlider:SetObeyStepOnDrag(true)
    abYSliderName = abYOffsetSlider:GetName()
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
    extraOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    extraOffsetsLabel:SetPoint("TOPLEFT", abYOffsetSlider, "BOTTOMLEFT", 0, -28)
    extraOffsetsLabel:SetText("Extra Ability Offsets")
    extraOffsetsLabel:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    extraXSlider = CreateFrame("Slider", "MABFExtraXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    extraXSlider:SetSize(PAGE_WIDTH, 14)
    extraXSlider:SetPoint("TOPLEFT", extraOffsetsLabel, "BOTTOMLEFT", 0, -18)
    extraXSlider:SetMinMaxValues(-100, 100)
    extraXSlider:SetValue(MattActionBarFontDB.extraXOffset)
    extraXSlider:SetValueStep(1)
    extraXSlider:SetObeyStepOnDrag(true)
    extraXName = extraXSlider:GetName()
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

    extraYSlider = CreateFrame("Slider", "MABFExtraYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    extraYSlider:SetSize(PAGE_WIDTH, 14)
    extraYSlider:SetPoint("TOPLEFT", extraXSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    extraYSlider:SetMinMaxValues(-100, 100)
    extraYSlider:SetValue(MattActionBarFontDB.extraYOffset)
    extraYSlider:SetValueStep(1)
    extraYSlider:SetObeyStepOnDrag(true)
    extraYName = extraYSlider:GetName()
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

    countOffsetsLabel = pageOffsets:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    countOffsetsLabel:SetPoint("TOPLEFT", extraYSlider, "BOTTOMLEFT", 0, -28)
    countOffsetsLabel:SetText("Count Text Offsets")
    countOffsetsLabel:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)

    xOffsetSlider = CreateFrame("Slider", "MABFXOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    xOffsetSlider:SetSize(PAGE_WIDTH, 14)
    xOffsetSlider:SetPoint("TOPLEFT", countOffsetsLabel, "BOTTOMLEFT", 0, -18)
    xOffsetSlider:SetMinMaxValues(-100, 100)
    xOffsetSlider:SetValue(MattActionBarFontDB.xOffset)
    xOffsetSlider:SetValueStep(1)
    xOffsetSlider:SetObeyStepOnDrag(true)
    xSliderName = xOffsetSlider:GetName()
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

    yOffsetSlider = CreateFrame("Slider", "MABFYOffsetSlider", pageOffsets, "OptionsSliderTemplate")
    yOffsetSlider:SetSize(PAGE_WIDTH, 14)
    yOffsetSlider:SetPoint("TOPLEFT", xOffsetSlider, "BOTTOMLEFT", 0, CONTENT_SPACING)
    yOffsetSlider:SetMinMaxValues(-100, 100)
    yOffsetSlider:SetValue(MattActionBarFontDB.yOffset)
    yOffsetSlider:SetValueStep(1)
    yOffsetSlider:SetObeyStepOnDrag(true)
    ySliderName = yOffsetSlider:GetName()
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
    pageTheme = CreateContentPage(3)

    themeTitle = CreatePageTitle(pageTheme, "AB Themes")

    themeDropdownTitle = pageTheme:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    themeDropdownTitle:SetPoint("TOPLEFT", themeTitle, "BOTTOMLEFT", 0, -14)
    themeDropdownTitle:SetText("Action Bar Theme:")
    themeDropdownTitle:SetTextColor(1, 1, 1)

    themeOptions = {
        { value = "blizzard",           label = "Blizzard Default" },
        { value = "minimalBlack",       label = "Minimal Black" },
        { value = "minimalTranslucent", label = "Minimal Translucent" },
        { value = "minimalObsidianRed", label = "Obsidian Red" },
        { value = "minimalFrostMage",   label = "Frost Mage" },
        { value = "minimalArcane",      label = "Arcane" },
        { value = "minimalFelGreen",    label = "Fel Green" },
        { value = "minimalHolyGold",    label = "Holy Gold" },
        { value = "minimalBloodDK",     label = "Blood DK" },
        { value = "minimalStormSteel",  label = "Storm Steel" },
        { value = "minimalEmerald",     label = "Emerald" },
        { value = "minimalVoid",        label = "Void" },
        { value = "minimalMonoLight",   label = "Mono Light" },
    }

    themeDropDown = CreateMinimalDropdown(pageTheme, 170, 12)
    themeDropDown:SetPoint("TOPLEFT", themeDropdownTitle, "BOTTOMLEFT", 0, -6)

    local function ClampThemeBorderSize(value)
        local size = tonumber(value) or 1
        size = math.floor(size + 0.5)
        if size < 1 then
            size = 1
        elseif size > 4 then
            size = 4
        end
        return size
    end

    MattActionBarFontDB.minimalThemeBorderSize = ClampThemeBorderSize(MattActionBarFontDB.minimalThemeBorderSize or 1)

    bgOpacitySlider = CreateFrame("Slider", "MABFBgOpacitySlider", pageTheme, "OptionsSliderTemplate")
    bgOpacitySlider:SetSize(PAGE_WIDTH, 14)
    bgOpacitySlider:SetPoint("TOPLEFT", themeDropDown, "BOTTOMLEFT", 16, CONTENT_SPACING)
    bgOpacitySlider:SetMinMaxValues(0, 100)
    bgOpacitySlider:SetValue((MattActionBarFontDB.minimalThemeBgOpacity or 0.35) * 100)
    bgOpacitySlider:SetValueStep(1)
    bgOpacitySlider:SetObeyStepOnDrag(true)
    bgOpacityName = bgOpacitySlider:GetName()
    _G[bgOpacityName.."Low"]:SetText("0%")
    _G[bgOpacityName.."High"]:SetText("100%")
    _G[bgOpacityName.."Text"]:SetText("Background Opacity: " .. math.floor((MattActionBarFontDB.minimalThemeBgOpacity or 0.35) * 100) .. "%")
    StyleSlider(bgOpacitySlider)
    bgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        value = math.floor(value)
        MattActionBarFontDB.minimalThemeBgOpacity = value / 100
        _G[self:GetName().."Text"]:SetText("Background Opacity: " .. value .. "%")
        if MABF.ApplyActionBarThemeLive then
            MABF:ApplyActionBarThemeLive()
        elseif MattActionBarFontDB.minimalTheme ~= "blizzard" then
            MABF:SkinActionBars()
        end
    end)

    local borderSizeSlider = CreateFrame("Slider", "MABFBorderSizeSlider", pageTheme, "OptionsSliderTemplate")
    borderSizeSlider:SetSize(PAGE_WIDTH, 14)
    borderSizeSlider:SetPoint("TOPLEFT", bgOpacitySlider, "BOTTOMLEFT", 0, CONTENT_SPACING - 4)
    borderSizeSlider:SetMinMaxValues(1, 4)
    borderSizeSlider:SetValue(MattActionBarFontDB.minimalThemeBorderSize)
    borderSizeSlider:SetValueStep(1)
    borderSizeSlider:SetObeyStepOnDrag(true)
    local borderSizeName = borderSizeSlider:GetName()
    _G[borderSizeName.."Low"]:SetText("1")
    _G[borderSizeName.."High"]:SetText("4")
    _G[borderSizeName.."Text"]:SetText("Pixel Border Size: " .. MattActionBarFontDB.minimalThemeBorderSize)
    StyleSlider(borderSizeSlider)
    borderSizeSlider:SetScript("OnValueChanged", function(self, value)
        local size = ClampThemeBorderSize(value)
        MattActionBarFontDB.minimalThemeBorderSize = size
        _G[self:GetName().."Text"]:SetText("Pixel Border Size: " .. size)
        if MABF.ApplyActionBarThemeLive then
            MABF:ApplyActionBarThemeLive()
        elseif MattActionBarFontDB.minimalTheme ~= "blizzard" then
            MABF:SkinActionBars()
        end
    end)

    local function UpdateThemeSlidersVisibility()
        if MattActionBarFontDB.minimalTheme ~= "blizzard" then
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
        MattActionBarFontDB.minimalTheme = value
        themeDropDown:SetSelectedValue(value)
        UpdateThemeSlidersVisibility()

        if value == "blizzard" then
            StaticPopup_Show("MABF_RELOAD_UI")
            return
        end

        if MABF.ApplyActionBarThemeLive then
            MABF:ApplyActionBarThemeLive()
        else
            if MABF.SkinActionBars then
                MABF:SkinActionBars()
            end
            if MABF.CropAllIcons then
                MABF:CropAllIcons()
            end
        end
    end)

    -- Page 4: AB Features
    pageABFeatures = CreateContentPage(4)

    -- Page 5: UI Features
    pageUIFeatures = CreateContentPage(5)

    -- Page 6: QC Features
    pageSystem = CreateContentPage(6)

    -- Page 7: System (Edit Mode Device Manager)
    pageEDM = CreateContentPage(7)

    -- Page 8: Quests
    pageQuests = CreateContentPage(8)

    -- Page 9: Bags
    pageBags = CreateContentPage(9)

    -- Page 10: Merchant
    pageMerchant = CreateContentPage(10)

    -- Initialize pages: show first page and set tab button colors
    for i, page in ipairs(pages) do
        if i == 1 then page:Show() else page:Hide() end
    end
    for _, b in ipairs(allTabButtons) do
        SetTabButtonState(b, false)
    end
    if tabButtons[1] then
        SetTabButtonState(tabButtons[1], true)
    end

    checkSpacing = -4

    --------------------------------------------------------------------------
    -- AB Features Page
    --------------------------------------------------------------------------
    abFeaturesTitle = CreatePageTitle(pageABFeatures, "AB Features")

    mouseoverFadeCheck, mouseoverFadeText = CreateBasicCheckbox(
        pageABFeatures,
        "MABFMouseoverFadeCheck",
        abFeaturesTitle,
        "TOPLEFT",
        0,
        -8,
        "Mouseover Fade (Bars 4 & 5)",
        MattActionBarFontDB.mouseoverFade,
        function(self)
        enabled = self:GetChecked() and true or false
        MattActionBarFontDB.mouseoverFade = enabled
        MABF:ApplyActionBarMouseover()
        if enabled then
            MABF:SetBarsMouseoverState(false)
            StaticPopup_Show("MABF_RELOAD_UI")
        end
    end)

    petBarFadeCheck, petBarFadeText = CreateBasicCheckbox(
        pageABFeatures,
        "MABFPetBarFadeCheck",
        mouseoverFadeCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Mouseover Fade (Pet Bar)",
        MattActionBarFontDB.petBarMouseoverFade,
        function(self)
        MattActionBarFontDB.petBarMouseoverFade = self:GetChecked() and true or false
        MABF:ApplyPetBarMouseoverFade()
    end)

    hideMacroTextCheck, hideMacroTextLabel = CreateBasicCheckbox(
        pageABFeatures,
        "MABFHideMacroTextExperimentalCheck",
        petBarFadeCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Hide Macro Text",
        MattActionBarFontDB.hideMacroText,
        function(self)
        MattActionBarFontDB.hideMacroText = self:GetChecked() and true or false
        MABF:UpdateMacroText()
    end)

    reverseBarGrowthCheck, reverseBarGrowthText = CreateBasicCheckbox(
        pageABFeatures,
        "MABFReverseBarGrowthCheck",
        hideMacroTextCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Reverse Bar Growth (Bar 1)",
        MattActionBarFontDB.reverseBarGrowth,
        function(self)
        MattActionBarFontDB.reverseBarGrowth = self:GetChecked() and true or false
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    --------------------------------------------------------------------------
    -- UI Features Page
    --------------------------------------------------------------------------
    uiFeaturesTitle = CreatePageTitle(pageUIFeatures, "UI / QoL")

    objectiveTrackerCheck = CreateFrame("CheckButton", "MABFObjectiveTrackerCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    objectiveTrackerCheck:ClearAllPoints()
    objectiveTrackerCheck:SetPoint("TOPLEFT", uiFeaturesTitle, "BOTTOMLEFT", 0, -8)
    objCheckText = _G[objectiveTrackerCheck:GetName().."Text"]
    objCheckText:SetText("Scale Objective Tracker (0.7)")
    objCheckText:SetTextColor(1, 1, 1)
    objectiveTrackerCheck:SetChecked(MattActionBarFontDB.scaleObjectiveTracker)
    objectiveTrackerCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleObjectiveTracker = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    scaleStatusBarCheck = CreateFrame("CheckButton", "MABFScaleStatusBarCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    scaleStatusBarCheck:ClearAllPoints()
    scaleStatusBarCheck:SetPoint("TOPLEFT", objectiveTrackerCheck, "BOTTOMLEFT", 0, checkSpacing)
    scaleStatusBarText = _G[scaleStatusBarCheck:GetName().."Text"]
    scaleStatusBarText:SetText("Scale Status Bar (0.7)")
    scaleStatusBarText:SetTextColor(1, 1, 1)
    scaleStatusBarCheck:SetChecked(MattActionBarFontDB.scaleStatusBar)
    scaleStatusBarCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleStatusBar = self:GetChecked()
        MABF:ApplyStatusBarScale()
    end)

    scaleTalkingHeadCheck = CreateFrame("CheckButton", "MABFScaleTalkingHeadCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    scaleTalkingHeadCheck:ClearAllPoints()
    scaleTalkingHeadCheck:SetPoint("TOPLEFT", scaleStatusBarCheck, "BOTTOMLEFT", 0, checkSpacing)
    scaleTalkingHeadText = _G[scaleTalkingHeadCheck:GetName().."Text"]
    scaleTalkingHeadText:SetText("Scale Talking Head (0.7)")
    scaleTalkingHeadText:SetTextColor(1, 1, 1)
    scaleTalkingHeadCheck:SetChecked(MattActionBarFontDB.scaleTalkingHead)
    scaleTalkingHeadCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleTalkingHead = self:GetChecked()
        MABF:ApplyScaleTalkingHead()
    end)

    hideMicroMenuCheck = CreateFrame("CheckButton", "MABFHideMicroMenuCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideMicroMenuCheck:ClearAllPoints()
    hideMicroMenuCheck:SetPoint("TOPLEFT", scaleTalkingHeadCheck, "BOTTOMLEFT", 0, checkSpacing)
    hideMicroMenuText = _G[hideMicroMenuCheck:GetName().."Text"]
    hideMicroMenuText:SetText("Hide Micro Menu")
    hideMicroMenuText:SetTextColor(1, 1, 1)
    hideMicroDesc = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hideMicroDesc:SetPoint("TOPLEFT", hideMicroMenuCheck, "BOTTOMLEFT", 26, 2)
    hideMicroDesc:SetText("|cff888888Keeps Dungeon Finder & Housing|r")
    hideMicroDesc:SetScale(0.85)
    hideMicroMenuCheck:SetChecked(MattActionBarFontDB.hideMicroMenu)
    hideMicroMenuCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideMicroMenu = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    hideBagBarCheck = CreateFrame("CheckButton", "MABFHideBagBarCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideBagBarCheck:ClearAllPoints()
    hideBagBarCheck:SetPoint("TOPLEFT", hideMicroMenuCheck, "BOTTOMLEFT", 0, checkSpacing)
    hideBagBarText = _G[hideBagBarCheck:GetName().."Text"]
    hideBagBarText:SetText("Hide Bag Bar")
    hideBagBarText:SetTextColor(1, 1, 1)
    hideBagBarCheck:SetChecked(MattActionBarFontDB.hideBagBar)
    hideBagBarCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideBagBar = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    cursorCircleCheck = CreateFrame("CheckButton", "MABFCursorCircleCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    cursorCircleCheck:ClearAllPoints()
    cursorCircleCheck:SetPoint("TOPLEFT", hideBagBarCheck, "BOTTOMLEFT", 0, checkSpacing)
    cursorCircleText = _G[cursorCircleCheck:GetName().."Text"]
    cursorCircleText:SetText("Cursor Circle")
    cursorCircleText:SetTextColor(1, 1, 1)
    cursorCircleCheck:SetChecked(MattActionBarFontDB.enableCursorCircle)

    cursorCircleColorLabel = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    cursorCircleColorLabel:SetPoint("TOPLEFT", cursorCircleCheck, "BOTTOMLEFT", 26, -10)
    cursorCircleColorLabel:SetText("Color:")
    cursorCircleColorLabel:SetTextColor(0.8, 0.8, 0.8)

    cursorCircleColorDropdown = CreateMinimalDropdown(pageUIFeatures, 130, 7)
    cursorCircleColorDropdown:SetPoint("LEFT", cursorCircleColorLabel, "RIGHT", 8, 0)

    cursorCircleColorOptions = {
        {label = "Light Blue", value = "lightBlue"},
        {label = "White",     value = "white"},
        {label = "Red",       value = "red"},
        {label = "Green",     value = "green"},
        {label = "Yellow",    value = "yellow"},
        {label = "Blue",      value = "blue"},
        {label = "Purple",    value = "purple"},
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

    cursorCircleScaleSlider = CreateFrame("Slider", "MABFCursorCircleScaleSlider", pageUIFeatures, "OptionsSliderTemplate")
    cursorCircleScaleSlider:SetWidth(140)
    cursorCircleScaleSlider:SetHeight(16)
    cursorCircleScaleSlider:SetPoint("TOPLEFT", cursorCircleColorLabel, "BOTTOMLEFT", -6, -22)
    cursorCircleScaleSlider:SetMinMaxValues(50, 200)
    cursorCircleScaleSlider:SetValueStep(5)
    cursorCircleScaleSlider:SetObeyStepOnDrag(true)
    _G[cursorCircleScaleSlider:GetName().."Low"]:SetText("50%")
    _G[cursorCircleScaleSlider:GetName().."High"]:SetText("200%")
    cursorCircleScaleTitle = _G[cursorCircleScaleSlider:GetName().."Text"]
    cursorCircleScaleTitle:SetText("Size Scale: " .. math.floor((MattActionBarFontDB.cursorCircleScale or 1.0) * 100) .. "%")
    StyleSlider(cursorCircleScaleSlider)
    cursorCircleScaleSlider:SetValue((MattActionBarFontDB.cursorCircleScale or 1.0) * 100)
    cursorCircleScaleSlider:SetScript("OnValueChanged", function(self, value)
        local scale = value / 100
        MattActionBarFontDB.cursorCircleScale = scale
        _G[self:GetName().."Text"]:SetText("Size Scale: " .. math.floor(value) .. "%")
        MABF:ApplyCursorCircleScale()
    end)

    cursorCircleOpacitySlider = CreateFrame("Slider", "MABFCursorCircleOpacitySlider", pageUIFeatures, "OptionsSliderTemplate")
    cursorCircleOpacitySlider:SetWidth(140)
    cursorCircleOpacitySlider:SetHeight(16)
    cursorCircleOpacitySlider:SetPoint("TOPLEFT", cursorCircleScaleSlider, "BOTTOMLEFT", 0, -22)
    cursorCircleOpacitySlider:SetMinMaxValues(0, 100)
    cursorCircleOpacitySlider:SetValueStep(5)
    cursorCircleOpacitySlider:SetObeyStepOnDrag(true)
    _G[cursorCircleOpacitySlider:GetName().."Low"]:SetText("0%")
    _G[cursorCircleOpacitySlider:GetName().."High"]:SetText("100%")
    cursorCircleOpacityTitle = _G[cursorCircleOpacitySlider:GetName().."Text"]
    cursorCircleOpacityTitle:SetText("Opacity: " .. math.floor((MattActionBarFontDB.cursorCircleOpacity or 1.0) * 100) .. "%")
    StyleSlider(cursorCircleOpacitySlider)
    cursorCircleOpacitySlider:SetValue((MattActionBarFontDB.cursorCircleOpacity or 1.0) * 100)
    cursorCircleOpacitySlider:SetScript("OnValueChanged", function(self, value)
        local alpha = value / 100
        MattActionBarFontDB.cursorCircleOpacity = alpha
        _G[self:GetName().."Text"]:SetText("Opacity: " .. math.floor(value) .. "%")
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
            _G[cursorCircleScaleSlider:GetName().."Text"]:SetTextColor(1, 1, 1)
            _G[cursorCircleScaleSlider:GetName().."Low"]:SetTextColor(0.8, 0.8, 0.8)
            _G[cursorCircleScaleSlider:GetName().."High"]:SetTextColor(0.8, 0.8, 0.8)
            cursorCircleOpacitySlider:SetAlpha(1)
            cursorCircleOpacitySlider:EnableMouse(true)
            _G[cursorCircleOpacitySlider:GetName().."Text"]:SetTextColor(1, 1, 1)
            _G[cursorCircleOpacitySlider:GetName().."Low"]:SetTextColor(0.8, 0.8, 0.8)
            _G[cursorCircleOpacitySlider:GetName().."High"]:SetTextColor(0.8, 0.8, 0.8)
        else
            cursorCircleColorLabel:SetTextColor(0.45, 0.45, 0.45)
            cursorCircleColorDropdown:SetAlpha(0.6)
            cursorCircleColorDropdown.button:Disable()
            cursorCircleScaleSlider:SetAlpha(0.6)
            cursorCircleScaleSlider:EnableMouse(false)
            _G[cursorCircleScaleSlider:GetName().."Text"]:SetTextColor(0.6, 0.6, 0.6)
            _G[cursorCircleScaleSlider:GetName().."Low"]:SetTextColor(0.5, 0.5, 0.5)
            _G[cursorCircleScaleSlider:GetName().."High"]:SetTextColor(0.5, 0.5, 0.5)
            cursorCircleOpacitySlider:SetAlpha(0.6)
            cursorCircleOpacitySlider:EnableMouse(false)
            _G[cursorCircleOpacitySlider:GetName().."Text"]:SetTextColor(0.6, 0.6, 0.6)
            _G[cursorCircleOpacitySlider:GetName().."Low"]:SetTextColor(0.5, 0.5, 0.5)
            _G[cursorCircleOpacitySlider:GetName().."High"]:SetTextColor(0.5, 0.5, 0.5)
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

    perfMonitorCheck = CreateFrame("CheckButton", "MABFPerfMonitorCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfMonitorCheck:ClearAllPoints()
    perfMonitorCheck:SetPoint("TOPLEFT", cursorCircleOpacitySlider, "BOTTOMLEFT", -20, -20)
    perfMonitorText = _G[perfMonitorCheck:GetName().."Text"]
    perfMonitorText:SetText("Performance Monitor (FPS & MS)")
    perfMonitorText:SetTextColor(1, 1, 1)
    perfMonitorCheck:SetChecked(MattActionBarFontDB.enablePerformanceMonitor)
    perfMonitorCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enablePerformanceMonitor = self:GetChecked() and true or false
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    perfMonitorDesc = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    perfMonitorDesc:SetPoint("TOPLEFT", perfMonitorCheck, "BOTTOMLEFT", 26, -10)
    perfMonitorDesc:SetText("|cff888888Shift+LeftClick to move the monitor|r")
    perfMonitorDesc:SetScale(0.85)

    perfBgOpacitySlider = CreateFrame("Slider", "MABFPerfBgOpacitySlider", pageUIFeatures, "OptionsSliderTemplate")
    perfBgOpacitySlider:SetWidth(140)
    perfBgOpacitySlider:SetHeight(16)
    perfBgOpacitySlider:SetPoint("TOPLEFT", perfMonitorDesc, "BOTTOMLEFT", -6, -22)
    perfBgOpacitySlider:SetMinMaxValues(0, 100)
    perfBgOpacitySlider:SetValueStep(5)
    perfBgOpacitySlider:SetObeyStepOnDrag(true)
    _G[perfBgOpacitySlider:GetName().."Low"]:SetText("0%")
    _G[perfBgOpacitySlider:GetName().."High"]:SetText("100%")
    perfBgOpacityTitle = _G[perfBgOpacitySlider:GetName().."Text"]
    perfBgOpacityTitle:SetText("BG Opacity: " .. math.floor((MattActionBarFontDB.perfMonitorBgOpacity or 0.5) * 100) .. "%")
    StyleSlider(perfBgOpacitySlider)
    perfBgOpacitySlider:SetValue((MattActionBarFontDB.perfMonitorBgOpacity or 0.5) * 100)
    perfBgOpacitySlider:SetScript("OnValueChanged", function(self, value)
        alpha = value / 100
        MattActionBarFontDB.perfMonitorBgOpacity = alpha
        _G[self:GetName().."Text"]:SetText("BG Opacity: " .. math.floor(value) .. "%")
        MABF:ApplyPerfMonitorStyle()
    end)

    perfColorLabel = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    perfColorLabel:SetPoint("TOPLEFT", perfBgOpacitySlider, "BOTTOMLEFT", 0, -18)
    perfColorLabel:SetText("Text Color:")
    perfColorLabel:SetTextColor(0.8, 0.8, 0.8)

    perfColorDropdown = CreateMinimalDropdown(pageUIFeatures, 110, 6)
    perfColorDropdown:SetPoint("LEFT", perfColorLabel, "RIGHT", 8, 0)

    perfColorOptions = {
        {label = "White",  value = "white"},
        {label = "Red",    value = "red"},
        {label = "Green",  value = "green"},
        {label = "Yellow", value = "yellow"},
        {label = "Blue",   value = "blue"},
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

    perfVerticalCheck = CreateFrame("CheckButton", "MABFPerfVerticalCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfVerticalCheck:ClearAllPoints()
    perfVerticalCheck:SetPoint("TOPLEFT", perfColorLabel, "BOTTOMLEFT", -4, -20)
    perfVerticalText = _G[perfVerticalCheck:GetName().."Text"]
    perfVerticalText:SetText("Vertical Layout")
    perfVerticalText:SetTextColor(0.8, 0.8, 0.8)
    perfVerticalCheck:SetChecked(MattActionBarFontDB.perfMonitorVertical)
    perfVerticalCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.perfMonitorVertical = self:GetChecked()
        MABF:ApplyPerfMonitorStyle()
    end)

    perfHideMSCheck = CreateFrame("CheckButton", "MABFPerfHideMSCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    perfHideMSCheck:ClearAllPoints()
    perfHideMSCheck:SetPoint("TOPLEFT", perfVerticalCheck, "BOTTOMLEFT", 0, checkSpacing)
    perfHideMSText = _G[perfHideMSCheck:GetName().."Text"]
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
    edmTitle = CreatePageTitle(pageEDM, "Edit Mode Device Manager")

    edmDesc = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    edmDesc:SetPoint("TOPLEFT", edmTitle, "BOTTOMLEFT", 0, -6)
    edmDesc:SetText("|cff888888Auto-apply an Edit Mode layout on login|r")
    edmDesc:SetFont("Fonts\\FRIZQT__.TTF", 9)

    edmEnableCheck = CreateFrame("CheckButton", "MABFEDMEnableCheck", pageEDM, "InterfaceOptionsCheckButtonTemplate")
    edmEnableCheck:ClearAllPoints()
    edmEnableCheck:SetPoint("TOPLEFT", edmDesc, "BOTTOMLEFT", -2, -10)
    edmEnableText = _G[edmEnableCheck:GetName().."Text"]
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

    edmLayoutLabel = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    edmLayoutLabel:SetPoint("TOPLEFT", edmEnableCheck, "BOTTOMLEFT", 2, -12)
    edmLayoutLabel:SetText("Layout on Login:")
    edmLayoutLabel:SetTextColor(1, 1, 1)

    edmLayoutDropdown = CreateMinimalDropdown(pageEDM, 170, 8)
    edmLayoutDropdown:SetPoint("LEFT", edmLayoutLabel, "RIGHT", 8, 0)

    local function GetEDMLayoutOptions()
        local opts = {}
        if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
            C_AddOns.LoadAddOn("Blizzard_EditMode")
        end
        if not EditModeManagerFrame or not EditModeManagerFrame.GetLayouts then return opts end
        local layouts = EditModeManagerFrame:GetLayouts()
        if not layouts then return opts end
        for i, l in ipairs(layouts) do
            opts[#opts + 1] = { value = i, label = l.layoutName }
        end
        return opts
    end

    edmLayoutDropdown:SetOnOpen(function(self)
        self:SetOptions(GetEDMLayoutOptions())
        local idx = MattActionBarFontDB.editMode and MattActionBarFontDB.editMode.presetIndexOnLogin or 1
        self:SetSelectedValue(idx)
    end)
    edmLayoutDropdown:SetOnSelect(function(value)
        if not MattActionBarFontDB.editMode then MattActionBarFontDB.editMode = {} end
        MattActionBarFontDB.editMode.presetIndexOnLogin = value
        if EditModeManagerFrame and EditModeManagerFrame.SelectLayout then
            EditModeManagerFrame:SelectLayout(value)
        end
        edmLayoutDropdown:SetSelectedValue(value)
        local opts = GetEDMLayoutOptions()
        for _, opt in ipairs(opts) do
            if opt.value == value and MABFEDMStatusText then
                MABFEDMStatusText:SetText("Selected: |cff90E4C1" .. opt.label .. "|r")
                break
            end
        end
    end)

    C_Timer.After(1.5, function()
        local opts = GetEDMLayoutOptions()
        edmLayoutDropdown:SetOptions(opts)
        local idx = MattActionBarFontDB.editMode and MattActionBarFontDB.editMode.presetIndexOnLogin or 1
        edmLayoutDropdown:SetSelectedValue(idx)
    end)

    edmStatusText = pageEDM:CreateFontString("MABFEDMStatusText", "OVERLAY", "GameFontNormal")
    edmStatusText:SetPoint("TOPLEFT", edmLayoutLabel, "BOTTOMLEFT", 0, -30)
    edmStatusText:SetText("Selected: |cff888888loading...|r")
    edmStatusText:SetTextColor(1, 1, 1)

    edmDivider = pageEDM:CreateTexture(nil, "ARTWORK")
    edmDivider:SetColorTexture(0.35, 0.03, 0.03, 0.7)
    edmDivider:SetSize(260, 1)
    edmDivider:SetPoint("TOPLEFT", edmStatusText, "BOTTOMLEFT", 0, -16)

    minimapCheck = CreateFrame("CheckButton", "MABFMinimapCheck", pageEDM, "InterfaceOptionsCheckButtonTemplate")
    minimapCheck:ClearAllPoints()
    minimapCheck:SetPoint("TOPLEFT", edmDivider, "BOTTOMLEFT", -2, -10)
    minimapText = _G[minimapCheck:GetName() .. "Text"]
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
    resetDivider = pageEDM:CreateTexture(nil, "ARTWORK")
    resetDivider:SetColorTexture(0.18, 0.18, 0.22, 1)
    resetDivider:SetSize(260, 1)
    resetDivider:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", -2, -20)

    resetTitle = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    resetTitle:SetPoint("TOPLEFT", resetDivider, "BOTTOMLEFT", 0, -16)
    resetTitle:SetText("Reset All Settings")
    resetTitle:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
    resetTitle:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 11, "")

    resetDesc = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetDesc:SetPoint("TOPLEFT", resetTitle, "BOTTOMLEFT", 0, -6)
    resetDesc:SetText("This will restore all settings to default values")
    resetDesc:SetTextColor(0.75, 0.75, 0.75, 1)
    resetDesc:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")

    resetButton = CreateFrame("Button", "MABFResetButton", pageEDM, "BackdropTemplate")
    resetButton:SetSize(150, 28)
    resetButton:SetPoint("TOPLEFT", resetDesc, "BOTTOMLEFT", 0, -14)
    resetButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    resetButton:SetBackdropColor(0.08, 0.08, 0.1, 1)
    resetButton:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
    resetButtonText = resetButton:CreateFontString(nil, "OVERLAY")
    resetButtonText:SetPoint("CENTER")
    resetButtonText:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 11, "")
    resetButtonText:SetTextColor(0.9, 0.9, 0.9, 1)
    resetButtonText:SetText("Reset to Defaults")
    resetButton:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.8)
    end)
    resetButton:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
    end)
    resetButton:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)
    resetButton:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.08, 0.08, 0.1, 1)
    end)
    resetButton:SetScript("OnClick", function(self)
        StaticPopup_Show("MABF_RESET_SETTINGS")
    end)

    --------------------------------------------------------------------------
    -- Quests Page
    --------------------------------------------------------------------------
    questsTitle = CreatePageTitle(pageQuests, "Quest Tweaks")

    autoAcceptCheck = CreateFrame("CheckButton", "MABFAutoAcceptCheck", pageQuests, "InterfaceOptionsCheckButtonTemplate")
    autoAcceptCheck:ClearAllPoints()
    autoAcceptCheck:SetPoint("TOPLEFT", questsTitle, "BOTTOMLEFT", 0, -8)
    autoAcceptText = _G[autoAcceptCheck:GetName().."Text"]
    autoAcceptText:SetText("Auto Accept Quests")
    autoAcceptText:SetTextColor(1, 1, 1)
    autoAcceptDesc = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoAcceptDesc:SetPoint("TOPLEFT", autoAcceptCheck, "BOTTOMLEFT", 26, 2)
    autoAcceptDesc:SetText("|cff888888Hold Shift to skip|r")
    autoAcceptDesc:SetScale(0.85)
    autoAcceptCheck:SetChecked(MattActionBarFontDB.autoAcceptQuests)
    autoAcceptCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.autoAcceptQuests = self:GetChecked()
        MABF:SetupQuestTweaks()
    end)

    autoTurnInCheck = CreateFrame("CheckButton", "MABFAutoTurnInCheck", pageQuests, "InterfaceOptionsCheckButtonTemplate")
    autoTurnInCheck:ClearAllPoints()
    autoTurnInCheck:SetPoint("TOPLEFT", autoAcceptCheck, "BOTTOMLEFT", 0, checkSpacing)
    autoTurnInText = _G[autoTurnInCheck:GetName().."Text"]
    autoTurnInText:SetText("Auto Turn In Quests")
    autoTurnInText:SetTextColor(1, 1, 1)
    autoTurnInDesc = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
    bagsTitle = CreatePageTitle(pageBags, "Bag Tweaks")

    bagIlvlCheck = CreateFrame("CheckButton", "MABFBagIlvlCheck", pageBags, "InterfaceOptionsCheckButtonTemplate")
    bagIlvlCheck:ClearAllPoints()
    bagIlvlCheck:SetPoint("TOPLEFT", bagsTitle, "BOTTOMLEFT", 0, -8)
    bagIlvlText = _G[bagIlvlCheck:GetName().."Text"]
    bagIlvlText:SetText("Show Item Levels in Bags")
    bagIlvlText:SetTextColor(1, 1, 1)
    bagIlvlDesc = pageBags:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
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
    merchantTitle = CreatePageTitle(pageMerchant, "Merchant Tweaks")

    autoRepairCheck = CreateFrame("CheckButton", "MABFAutoRepairCheck", pageMerchant, "InterfaceOptionsCheckButtonTemplate")
    autoRepairCheck:ClearAllPoints()
    autoRepairCheck:SetPoint("TOPLEFT", merchantTitle, "BOTTOMLEFT", 0, -8)
    autoRepairText = _G[autoRepairCheck:GetName().."Text"]
    autoRepairText:SetText("Auto Repair")
    autoRepairText:SetTextColor(1, 1, 1)
    autoRepairDesc = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoRepairDesc:SetPoint("TOPLEFT", autoRepairCheck, "BOTTOMLEFT", DESC_TEXT_OFFSET_X, 2)
    autoRepairDesc:SetText("|cff888888Automatically repairs gear at merchants|r")
    autoRepairDesc:SetScale(0.85)
    autoRepairCheck:SetChecked(MattActionBarFontDB.enableAutoRepair)
    autoRepairCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableAutoRepair = self:GetChecked()
        MABF:SetupMerchantTweaks()
    end)

    fundingLabel = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fundingLabel:SetPoint("TOPLEFT", autoRepairDesc, "BOTTOMLEFT", 0, ROW_GAP_TIGHT)
    fundingLabel:SetText("Repair Funding:")
    fundingLabel:SetTextColor(0.9, 0.9, 0.9)
    fundingLabel:SetFont("Fonts\\FRIZQT__.TTF", 9)

    fundingGuild = CreateFrame("CheckButton", "MABFFundingGuild", pageMerchant, "UIRadioButtonTemplate")
    fundingGuild:SetSize(14, 14)
    fundingGuild:SetPoint("TOPLEFT", fundingLabel, "BOTTOMLEFT", 0, ROW_GAP_TIGHT)
    fundingGuildText = fundingGuild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fundingGuildText:SetPoint("LEFT", fundingGuild, "RIGHT", 2, 0)
    fundingGuildText:SetText("|cffffffffGuild first, then personal|r")
    fundingGuildText:SetFont("Fonts\\FRIZQT__.TTF", 9)

    fundingPlayer = CreateFrame("CheckButton", "MABFFundingPlayer", pageMerchant, "UIRadioButtonTemplate")
    fundingPlayer:SetSize(14, 14)
    fundingPlayer:SetPoint("TOPLEFT", fundingGuild, "BOTTOMLEFT", 0, ROW_GAP)
    fundingPlayerText = fundingPlayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fundingPlayerText:SetPoint("LEFT", fundingPlayer, "RIGHT", 2, 0)
    fundingPlayerText:SetText("|cffffffffPersonal only|r")
    fundingPlayerText:SetFont("Fonts\\FRIZQT__.TTF", 9)

    StyleMinimalRadio(fundingGuild, fundingGuildText)
    StyleMinimalRadio(fundingPlayer, fundingPlayerText)

    local function UpdateFundingRadios()
        local src = MattActionBarFontDB.autoRepairFundingSource or "GUILD"
        fundingGuild:SetChecked(src == "GUILD")
        fundingPlayer:SetChecked(src == "PLAYER")
        if fundingGuild._mabfRefreshMark then fundingGuild._mabfRefreshMark() end
        if fundingPlayer._mabfRefreshMark then fundingPlayer._mabfRefreshMark() end
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

    local autoSellCheck = CreateFrame("CheckButton", "MABFAutoSellJunkCheck", pageMerchant, "InterfaceOptionsCheckButtonTemplate")
    autoSellCheck:ClearAllPoints()
    autoSellCheck:SetPoint("TOPLEFT", fundingPlayer, "BOTTOMLEFT", 0, ROW_GAP)
    local autoSellText = _G[autoSellCheck:GetName().."Text"]
    autoSellText:SetText("Auto Sell Junk")
    autoSellText:SetTextColor(1, 1, 1)
    local autoSellDesc = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoSellDesc:SetPoint("TOPLEFT", autoSellCheck, "BOTTOMLEFT", DESC_TEXT_OFFSET_X, 2)
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

    local quickBindCheck, quickBindText = CreateBasicCheckbox(
        pageSystem,
        "MABFQuickBindCheck",
        qcTitle,
        "TOPLEFT",
        0,
        -8,
        "Keybind Mode |cffffd100(/kb)|r",
        MattActionBarFontDB.enableQuickBind,
        function(self)
        MattActionBarFontDB.enableQuickBind = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    local reloadAliasCheck, reloadAliasText = CreateBasicCheckbox(
        pageSystem,
        "MABFReloadAliasCheck",
        quickBindCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Reload UI |cffffd100(/rl)|r",
        MattActionBarFontDB.enableReloadAlias,
        function(self)
        MattActionBarFontDB.enableReloadAlias = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    local editModeAliasCheck, editModeAliasText = CreateBasicCheckbox(
        pageSystem,
        "MABFEditModeAliasCheck",
        reloadAliasCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Edit Mode |cffffd100(/edit)|r",
        MattActionBarFontDB.enableEditModeAlias,
        function(self)
        MattActionBarFontDB.enableEditModeAlias = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    local pullAliasCheck, pullAliasText = CreateBasicCheckbox(
        pageSystem,
        "MABFPullAliasCheck",
        editModeAliasCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Pull Timer |cffffd100(/pull X)|r",
        MattActionBarFontDB.enablePullAlias,
        function(self)
        MattActionBarFontDB.enablePullAlias = self:GetChecked()
        MABF:SetupSlashCommands()
    end)

    local optionChecks = {
        mouseoverFadeCheck, petBarFadeCheck, hideMacroTextCheck, reverseBarGrowthCheck,
        objectiveTrackerCheck, scaleStatusBarCheck, scaleTalkingHeadCheck,
        hideMicroMenuCheck, hideBagBarCheck, cursorCircleCheck, perfMonitorCheck, perfVerticalCheck,
        perfHideMSCheck, edmEnableCheck, minimapCheck, autoAcceptCheck,
        autoTurnInCheck, bagIlvlCheck, autoRepairCheck, autoSellCheck,
        quickBindCheck, reloadAliasCheck, editModeAliasCheck, pullAliasCheck,
    }
    for _, cb in ipairs(optionChecks) do
        StyleMinimalCheckbox(cb)
    end

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
        MattActionBarFontDB = {}
        MABF:ApplyDefaults()
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
