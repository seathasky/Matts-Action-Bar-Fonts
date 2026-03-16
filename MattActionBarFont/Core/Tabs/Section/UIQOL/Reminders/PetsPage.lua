local addonName, MABF = ...

-- Builds the Reminders > Pets sub-page controls and returns refresh hooks.
function MABF:BuildRemindersPetsPage(opts)
    if type(opts) ~= "table" then return nil end

    local page = opts.page
    local checkSpacing = opts.checkSpacing
    local StyleSlider = opts.StyleSlider
    local CreateReminderResetButton = opts.CreateReminderResetButton
    local CreateReminderResetSizeButton = opts.CreateReminderResetSizeButton

    if not page or not checkSpacing or not StyleSlider or not CreateReminderResetButton or not CreateReminderResetSizeButton then
        return nil
    end

    local warnMissingPetCheck = CreateFrame("CheckButton", "MABFWarnMissingPetCheck", page, "InterfaceOptionsCheckButtonTemplate")
    warnMissingPetCheck:ClearAllPoints()
    warnMissingPetCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    local warnMissingPetText = _G[warnMissingPetCheck:GetName() .. "Text"]
    warnMissingPetText:SetText("Warn when pet is missing")
    warnMissingPetText:SetTextColor(1, 1, 1)
    local warnMissingPetDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnMissingPetDesc:SetPoint("TOPLEFT", warnMissingPetCheck, "BOTTOMLEFT", 26, 2)
    warnMissingPetDesc:SetText("|cff888888Shows summon warning for tracked pet classes|r")
    warnMissingPetDesc:SetScale(0.85)
    warnMissingPetCheck:SetChecked(MattActionBarFontDB.warnMissingPet)

    local function CreateMissingPetSubCheckbox(name, anchorTo, xOffset, labelText, checkedValue, onClick)
        local cb = CreateFrame("CheckButton", name, page, "InterfaceOptionsCheckButtonTemplate")
        cb:ClearAllPoints()
        cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset or 0, checkSpacing)
        local label = _G[cb:GetName() .. "Text"]
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1)
        cb:SetChecked(checkedValue and true or false)
        cb:SetScript("OnClick", onClick)
        return cb
    end

    local petMissingOnlyInstanceCheck = CreateMissingPetSubCheckbox("MABFPetMissingOnlyInstanceCheck", warnMissingPetDesc, 26, "Only in dungeons/raids/scenarios", MattActionBarFontDB.petMissingOnlyInInstance, function(self)
        MattActionBarFontDB.petMissingOnlyInInstance = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
    end)
    local petMissingHideInRestAreaCheck = CreateMissingPetSubCheckbox("MABFPetMissingHideInRestAreaCheck", petMissingOnlyInstanceCheck, 0, "Hide while resting", MattActionBarFontDB.petMissingHideInRestArea, function(self)
        MattActionBarFontDB.petMissingHideInRestArea = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
    end)
    local petMissingSuppressInMPlusCheck = CreateMissingPetSubCheckbox("MABFPetMissingSuppressInMPlusCheck", petMissingHideInRestAreaCheck, 0, "Hide during active Mythic+", MattActionBarFontDB.petMissingSuppressInMPlus, function(self)
        MattActionBarFontDB.petMissingSuppressInMPlus = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
    end)
    local petMissingSuppressAfterFirstPullCheck = CreateMissingPetSubCheckbox("MABFPetMissingSuppressAfterFirstPullCheck", petMissingSuppressInMPlusCheck, 0, "Hide after first pull", MattActionBarFontDB.petMissingSuppressAfterFirstPull, function(self)
        MattActionBarFontDB.petMissingSuppressAfterFirstPull = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
    end)
    local petMissingHideWhenLFGCompleteCheck = CreateMissingPetSubCheckbox("MABFPetMissingHideWhenLFGCompleteCheck", petMissingSuppressAfterFirstPullCheck, 0, "Hide when LFG run is complete", MattActionBarFontDB.petMissingHideWhenLFGComplete, function(self)
        MattActionBarFontDB.petMissingHideWhenLFGComplete = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
    end)

    local warnPetPassiveCheck = CreateFrame("CheckButton", "MABFWarnPetPassiveCheck", page, "InterfaceOptionsCheckButtonTemplate")
    warnPetPassiveCheck:ClearAllPoints()
    warnPetPassiveCheck:SetPoint("TOPLEFT", petMissingHideWhenLFGCompleteCheck, "BOTTOMLEFT", 0, -8)
    local warnPetPassiveText = _G[warnPetPassiveCheck:GetName() .. "Text"]
    warnPetPassiveText:SetText("Warn when pet is on passive")
    warnPetPassiveText:SetTextColor(1, 1, 1)
    local warnPetPassiveDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnPetPassiveDesc:SetPoint("TOPLEFT", warnPetPassiveCheck, "BOTTOMLEFT", 26, 2)
    warnPetPassiveDesc:SetText("|cff888888Shows in-combat text for tracked pet classes|r")
    warnPetPassiveDesc:SetScale(0.85)
    warnPetPassiveCheck:SetChecked(MattActionBarFontDB.warnPetPassive)

    local petReminderScaleSlider = CreateFrame("Slider", "MABFPetReminderScaleSlider", page, "OptionsSliderTemplate")
    petReminderScaleSlider:SetSize(180, 14)
    petReminderScaleSlider:SetPoint("BOTTOM", page, "BOTTOM", 0, 74)
    petReminderScaleSlider:SetMinMaxValues(50, 200)
    petReminderScaleSlider:SetValue((MattActionBarFontDB.petReminderScale or 1.0) * 100)
    petReminderScaleSlider:SetValueStep(1)
    petReminderScaleSlider:SetObeyStepOnDrag(true)
    local petReminderScaleSliderName = petReminderScaleSlider:GetName()
    _G[petReminderScaleSliderName .. "Low"]:SetText("50%")
    _G[petReminderScaleSliderName .. "High"]:SetText("200%")
    _G[petReminderScaleSliderName .. "Text"]:SetText("Pet Reminder Size: " .. math.floor((MattActionBarFontDB.petReminderScale or 1.0) * 100) .. "%")
    StyleSlider(petReminderScaleSlider)
    petReminderScaleSlider:SetScript("OnValueChanged", function(self, value)
        local pct = math.floor((value or 100) + 0.5)
        if pct < 50 then pct = 50 end
        if pct > 200 then pct = 200 end
        MattActionBarFontDB.petReminderScale = pct / 100
        _G[petReminderScaleSliderName .. "Text"]:SetText("Pet Reminder Size: " .. pct .. "%")
        if MABF and MABF.ApplyPetReminderScale then
            MABF:ApplyPetReminderScale()
        end
    end)

    local warnPetPassiveResetBtn = CreateReminderResetButton("MABFWarnPetPassiveResetBtn", page, function()
        if MABF and MABF.ResetPetPassiveReminderPosition then
            MABF:ResetPetPassiveReminderPosition()
            if MABF.SetupPetPassiveReminder then
                MABF:SetupPetPassiveReminder()
            end
        end
    end)
    local warnPetPassiveResetSizeBtn = CreateReminderResetSizeButton("MABFWarnPetPassiveResetSizeBtn", page, function()
        if petReminderScaleSlider then
            petReminderScaleSlider:SetValue(100)
        end
        MattActionBarFontDB.petReminderScale = 1.0
        if MABF and MABF.ApplyPetReminderScale then
            MABF:ApplyPetReminderScale()
        end
    end)

    local function RefreshMissingPetSubOptions()
        local enabled = warnMissingPetCheck:GetChecked() and true or false
        local subChecks = {
            petMissingOnlyInstanceCheck,
            petMissingHideInRestAreaCheck,
            petMissingSuppressInMPlusCheck,
            petMissingSuppressAfterFirstPullCheck,
            petMissingHideWhenLFGCompleteCheck,
        }
        for _, cb in ipairs(subChecks) do
            cb:SetEnabled(enabled)
            local t = _G[cb:GetName() .. "Text"]
            if t then t:SetTextColor(enabled and 1 or 0.55, enabled and 1 or 0.55, enabled and 1 or 0.55) end
        end
    end

    local function RefreshPetReminderScaleControl()
        local enabled = (warnMissingPetCheck:GetChecked() or warnPetPassiveCheck:GetChecked()) and true or false
        if petReminderScaleSlider then
            petReminderScaleSlider:SetEnabled(enabled)
            petReminderScaleSlider:SetAlpha(enabled and 1 or 0.6)
        end
    end

    warnMissingPetCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.warnMissingPet = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
        RefreshMissingPetSubOptions()
        RefreshPetReminderScaleControl()
    end)

    warnPetPassiveCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.warnPetPassive = self:GetChecked() and true or false
        MABF:SetupPetPassiveReminder()
        RefreshPetReminderScaleControl()
    end)

    return {
        warnMissingPetCheck = warnMissingPetCheck,
        warnPetPassiveCheck = warnPetPassiveCheck,
        warnPetPassiveResetBtn = warnPetPassiveResetBtn,
        warnPetPassiveResetSizeBtn = warnPetPassiveResetSizeBtn,
        RefreshMissingPetSubOptions = RefreshMissingPetSubOptions,
        RefreshPetReminderScaleControl = RefreshPetReminderScaleControl,
    }
end
