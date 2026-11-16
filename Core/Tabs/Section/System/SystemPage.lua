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

    local profilesPanel = MABF:BuildProfilesPanel(pageEDM, minimapCheck, CreateMinimalDropdown)

    return {
        page = pageEDM,
        edmEnableCheck = edmEnableCheck,
        minimapCheck = minimapCheck,
        profilesPanel = profilesPanel,
    }
end
