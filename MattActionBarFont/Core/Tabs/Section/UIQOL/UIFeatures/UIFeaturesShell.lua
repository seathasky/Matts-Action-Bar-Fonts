local addonName, MABF = ...

-- Builds the UI Features sub-tab shell (Blizzard UI / Visual / Tools) and
-- re-parents existing controls into the corresponding sub-pages.
function MABF:SetupUIFeaturesSubTabs(opts)
    if type(opts) ~= "table" then return end

    local pageUIFeatures = opts.pageUIFeatures
    local uiFeaturesTitle = opts.uiFeaturesTitle
    local blizzard = opts.blizzardControls or {}
    local visual = opts.visualControls or {}
    local tools = opts.toolsControls or {}

    if not pageUIFeatures or not uiFeaturesTitle then
        return
    end
    local THEME_ACCENT = MABF:GetThemeAccentColor()

    local uiSubTabContainer = CreateFrame("Frame", nil, pageUIFeatures)
    uiSubTabContainer:SetPoint("TOPLEFT", uiFeaturesTitle, "BOTTOMLEFT", 0, -8)
    uiSubTabContainer:SetPoint("TOPRIGHT", pageUIFeatures, "TOPRIGHT", -20, -30)
    uiSubTabContainer:SetHeight(24)

    local uiSubTabGap = 4
    local uiSubTabWidth = 92
    local uiSubTabCount = 3
    do
        local totalWidth = pageUIFeatures:GetWidth() - 24
        local computed = math.floor((totalWidth - (uiSubTabGap * (uiSubTabCount - 1))) / uiSubTabCount)
        if computed < 76 then computed = 76 end
        if computed > 96 then computed = 96 end
        uiSubTabWidth = computed
    end

    local function CreateUIFeatureSubTab(name, label, anchor)
        local btn = CreateFrame("Button", name, uiSubTabContainer, "BackdropTemplate")
        btn:SetSize(uiSubTabWidth, 20)
        if anchor then
            btn:SetPoint("LEFT", anchor, "RIGHT", uiSubTabGap, 0)
        else
            btn:SetPoint("LEFT", uiSubTabContainer, "LEFT", 0, 0)
        end
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        fs:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 9, "OUTLINE")
        fs:SetText(label)
        fs:SetTextColor(0.85, 0.85, 0.85, 1)
        btn._mabfText = fs
        return btn
    end

    local uiBlizzardBtn = CreateUIFeatureSubTab("MABFUIFeaturesBlizzard", "Blizzard UI", nil)
    local uiVisualBtn = CreateUIFeatureSubTab("MABFUIFeaturesVisual", "Visual", uiBlizzardBtn)
    local uiToolsBtn = CreateUIFeatureSubTab("MABFUIFeaturesTools", "Tools", uiVisualBtn)

    local uiFeaturePages = {
        blizzard = CreateFrame("Frame", nil, pageUIFeatures),
        visual = CreateFrame("Frame", nil, pageUIFeatures),
        tools = CreateFrame("Frame", nil, pageUIFeatures),
    }
    for _, subPage in pairs(uiFeaturePages) do
        subPage:SetPoint("TOPLEFT", uiSubTabContainer, "BOTTOMLEFT", 0, -8)
        subPage:SetPoint("BOTTOMRIGHT", pageUIFeatures, "BOTTOMRIGHT", -8, 8)
    end

    for _, control in ipairs(blizzard) do
        if control and control.SetParent then
            control:SetParent(uiFeaturePages.blizzard)
        end
    end
    for _, control in ipairs(visual) do
        if control and control.SetParent then
            control:SetParent(uiFeaturePages.visual)
        end
    end
    for _, control in ipairs(tools) do
        if control and control.SetParent then
            control:SetParent(uiFeaturePages.tools)
        end
    end

    local firstBlizzard = blizzard[1]
    local firstVisual = visual[1]
    local firstTools = tools[1]
    if firstBlizzard and firstBlizzard.ClearAllPoints then
        firstBlizzard:ClearAllPoints()
        firstBlizzard:SetPoint("TOPLEFT", uiFeaturePages.blizzard, "TOPLEFT", 0, -4)
    end
    if firstVisual and firstVisual.ClearAllPoints then
        firstVisual:ClearAllPoints()
        firstVisual:SetPoint("TOPLEFT", uiFeaturePages.visual, "TOPLEFT", 0, -4)
    end
    if firstTools and firstTools.ClearAllPoints then
        firstTools:ClearAllPoints()
        firstTools:SetPoint("TOPLEFT", uiFeaturePages.tools, "TOPLEFT", 0, -4)
    end

    local uiFeatureTabButtons = {
        blizzard = uiBlizzardBtn,
        visual = uiVisualBtn,
        tools = uiToolsBtn,
    }

    local function ShowUIFeatureSubPage(key)
        for k, p in pairs(uiFeaturePages) do
            p:SetShown(k == key)
        end
        for k, b in pairs(uiFeatureTabButtons) do
            local active = (k == key)
            if active then
                b:SetBackdropColor(0.12, 0.12, 0.15, 1)
                b:SetBackdropBorderColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 0.85)
                if b._mabfText then b._mabfText:SetTextColor(1, 1, 1, 1) end
            else
                b:SetBackdropColor(0.06, 0.06, 0.08, 1)
                b:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                if b._mabfText then b._mabfText:SetTextColor(0.85, 0.85, 0.85, 1) end
            end
        end
    end

    uiBlizzardBtn:SetScript("OnClick", function() ShowUIFeatureSubPage("blizzard") end)
    uiVisualBtn:SetScript("OnClick", function() ShowUIFeatureSubPage("visual") end)
    uiToolsBtn:SetScript("OnClick", function() ShowUIFeatureSubPage("tools") end)
    ShowUIFeatureSubPage("blizzard")
end
