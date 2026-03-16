local addonName, MABF = ...

-- Builds the System > System options page UI.
function MABF:BuildSystemPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageEDM = opts.pageEDM
    local CreatePageTitle = opts.CreatePageTitle
    local CreateMinimalDropdown = opts.CreateMinimalDropdown

    if not pageEDM or not CreatePageTitle or not CreateMinimalDropdown then
        return nil
    end

    local THEME_ACCENT = MABF:GetThemeAccentColor()

    local edmTitle = CreatePageTitle(pageEDM, "Edit Mode Device Manager")

    local edmDesc = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    edmDesc:SetPoint("TOPLEFT", edmTitle, "BOTTOMLEFT", 0, -6)
    edmDesc:SetText("|cff888888Auto-apply an Edit Mode layout on login|r")
    edmDesc:SetFont("Fonts\\FRIZQT__.TTF", 9)

    local edmEnableCheck = CreateFrame("CheckButton", "MABFEDMEnableCheck", pageEDM, "InterfaceOptionsCheckButtonTemplate")
    edmEnableCheck:ClearAllPoints()
    edmEnableCheck:SetPoint("TOPLEFT", edmDesc, "BOTTOMLEFT", -2, -10)
    local edmEnableText = _G[edmEnableCheck:GetName() .. "Text"]
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

    local edmLayoutLabel = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    edmLayoutLabel:SetPoint("TOPLEFT", edmEnableCheck, "BOTTOMLEFT", 2, -12)
    edmLayoutLabel:SetText("Layout on Login:")
    edmLayoutLabel:SetTextColor(1, 1, 1)

    local edmLayoutDropdown = CreateMinimalDropdown(pageEDM, 170, 8)
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
        local options = GetEDMLayoutOptions()
        for _, opt in ipairs(options) do
            if opt.value == value and MABFEDMStatusText then
                MABFEDMStatusText:SetText("Selected: |cff90E4C1" .. opt.label .. "|r")
                break
            end
        end
    end)

    C_Timer.After(1.5, function()
        local options = GetEDMLayoutOptions()
        edmLayoutDropdown:SetOptions(options)
        local idx = MattActionBarFontDB.editMode and MattActionBarFontDB.editMode.presetIndexOnLogin or 1
        edmLayoutDropdown:SetSelectedValue(idx)
    end)

    local edmStatusText = pageEDM:CreateFontString("MABFEDMStatusText", "OVERLAY", "GameFontNormal")
    edmStatusText:SetPoint("TOPLEFT", edmLayoutLabel, "BOTTOMLEFT", 0, -30)
    edmStatusText:SetText("Selected: |cff888888loading...|r")
    edmStatusText:SetTextColor(1, 1, 1)

    local edmDivider = pageEDM:CreateTexture(nil, "ARTWORK")
    edmDivider:SetColorTexture(0.35, 0.03, 0.03, 0.7)
    edmDivider:SetSize(260, 1)
    edmDivider:SetPoint("TOPLEFT", edmStatusText, "BOTTOMLEFT", 0, -16)

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

    local resetDivider = pageEDM:CreateTexture(nil, "ARTWORK")
    resetDivider:SetColorTexture(0.18, 0.18, 0.22, 1)
    resetDivider:SetSize(260, 1)
    resetDivider:SetPoint("TOPLEFT", minimapCheck, "BOTTOMLEFT", -2, -20)

    local resetTitle = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    resetTitle:SetPoint("TOPLEFT", resetDivider, "BOTTOMLEFT", 0, -16)
    resetTitle:SetText("Reset All Settings")
    resetTitle:SetTextColor(THEME_ACCENT[1], THEME_ACCENT[2], THEME_ACCENT[3], 1)
    resetTitle:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 11, "")

    local resetDesc = pageEDM:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    resetDesc:SetPoint("TOPLEFT", resetTitle, "BOTTOMLEFT", 0, -6)
    resetDesc:SetText("This will restore all settings to default values")
    resetDesc:SetTextColor(0.75, 0.75, 0.75, 1)
    resetDesc:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")

    local resetButton = CreateFrame("Button", "MABFResetButton", pageEDM, "BackdropTemplate")
    resetButton:SetSize(150, 28)
    resetButton:SetPoint("TOPLEFT", resetDesc, "BOTTOMLEFT", 0, -14)
    resetButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    resetButton:SetBackdropColor(0.08, 0.08, 0.1, 1)
    resetButton:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
    local resetButtonText = resetButton:CreateFontString(nil, "OVERLAY")
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
    resetButton:SetScript("OnClick", function()
        StaticPopup_Show("MABF_RESET_SETTINGS")
    end)

    return {
        page = pageEDM,
        edmEnableCheck = edmEnableCheck,
        minimapCheck = minimapCheck,
    }
end
