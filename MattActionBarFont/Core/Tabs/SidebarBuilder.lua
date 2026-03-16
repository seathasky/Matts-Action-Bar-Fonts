local addonName, MABF = ...

-- Builds sidebar buttons and click behavior for page tabs + shortcut actions.
function MABF:BuildOptionsSidebarButtonController(opts)
    if type(opts) ~= "table" then return nil end

    local leftPanel = opts.leftPanel
    local pages = opts.pages
    local sectionGap = opts.sectionGap or 6
    local themeAccent = opts.themeAccent or { 1.0, 0.25, 0.25 }
    local tabBorder = opts.tabBorder or { 0.18, 0.18, 0.22, 1 }
    local tabTextNormal = opts.tabTextNormal or { 0.7, 0.7, 0.7, 1 }
    local fontPath = opts.fontPath or "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"

    if not leftPanel or type(pages) ~= "table" then
        return nil
    end

    local tabButtons = {}
    local allTabButtons = {}
    local tabHeight = 28
    local tabGap = 2
    local TAB_TYPO = (MABF.GetTabTypography and MABF:GetTabTypography()) or {
        fontPath = fontPath,
        tabSize = 10,
        headerSize = 7,
    }
    local TAB_FONT = TAB_TYPO.fontPath or fontPath
    local TAB_FONT_SIZE = TAB_TYPO.tabSize or 10

    local function CreateSectionHeader(parent, text, anchorFrame, anchorPoint, yOffset)
        return MABF:CreateSectionHeader(parent, text, anchorFrame, anchorPoint, yOffset, sectionGap)
    end

    local function SetTabButtonState(btn, isActive)
        MABF:SetTabButtonState(btn, isActive)
    end

    local function CreateTabButton(parent, label, pageIndex, anchorFrame, anchorPoint, yOffset)
        local btn = CreateFrame("Button", nil, parent, "BackdropTemplate")
        btn:SetSize(86, tabHeight)
        btn:SetPoint("TOP", anchorFrame, anchorPoint or "BOTTOM", 0, yOffset or -tabGap)
        btn:SetID(pageIndex or 0)
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            tile = false,
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 }
        })
        SetTabButtonState(btn, false)

        local btnText = btn:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        btnText:SetPoint("CENTER")
        btnText:SetText(label)
        btnText:SetFont(TAB_FONT, TAB_FONT_SIZE, "OUTLINE")
        btn.text = btnText

        btn:SetScript("OnEnter", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(themeAccent[1], themeAccent[2], themeAccent[3], 0.5)
                if self.text then
                    self.text:SetTextColor(0.9, 0.9, 0.9, 1)
                end
            end
        end)
        btn:SetScript("OnLeave", function(self)
            if not self.isActive then
                self:SetBackdropBorderColor(tabBorder[1], tabBorder[2], tabBorder[3], tabBorder[4])
                if self.text then
                    self.text:SetTextColor(tabTextNormal[1], tabTextNormal[2], tabTextNormal[3], tabTextNormal[4])
                end
            end
        end)

        table.insert(allTabButtons, btn)
        return btn
    end

    local function ShowPage(pageIndex, clickedButton)
        for _, page in ipairs(pages) do
            page:Hide()
        end
        if pages[pageIndex] then
            pages[pageIndex]:Show()
        end
        for _, b in ipairs(allTabButtons) do
            SetTabButtonState(b, false)
        end
        if clickedButton then
            SetTabButtonState(clickedButton, true)
        elseif tabButtons[pageIndex] then
            SetTabButtonState(tabButtons[pageIndex], true)
        end
    end

    local sidebar = MABF:BuildOptionsSidebarTabs({
        leftPanel = leftPanel,
        sectionGap = sectionGap,
        CreateSectionHeader = CreateSectionHeader,
        CreateTabButton = CreateTabButton,
        tabButtons = tabButtons,
    })

    for idx, btn in pairs(tabButtons) do
        local pageIndex = idx
        btn:SetScript("OnClick", function(self)
            ShowPage(pageIndex, self)
        end)
    end

    if sidebar and sidebar.keybindBtn then
        sidebar.keybindBtn:SetScript("OnClick", function()
            MABF:RunKeybindShortcut()
        end)
    end
    if sidebar and sidebar.editModeBtn then
        sidebar.editModeBtn:SetScript("OnClick", function()
            MABF:RunEditModeShortcut()
        end)
    end

    return {
        tabButtons = tabButtons,
        allTabButtons = allTabButtons,
        ShowPage = ShowPage,
    }
end
