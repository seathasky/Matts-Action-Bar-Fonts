local addonName, MABF = ...

-- Builds the Reminders > Class sub-page controls and returns refresh hooks.
function MABF:BuildRemindersClassPage(opts)
    if type(opts) ~= "table" then return nil end

    local page = opts.page
    local checkSpacing = opts.checkSpacing
    local StyleSlider = opts.StyleSlider
    local CreateReminderResetButton = opts.CreateReminderResetButton
    local CreateReminderResetSizeButton = opts.CreateReminderResetSizeButton

    if not page or not checkSpacing or not StyleSlider or not CreateReminderResetButton or not CreateReminderResetSizeButton then
        return nil
    end

    local warnClassSoulstoneCheck = CreateFrame("CheckButton", "MABFWarnClassSoulstoneCheck", page, "InterfaceOptionsCheckButtonTemplate")
    warnClassSoulstoneCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    local warnClassSoulstoneText = _G[warnClassSoulstoneCheck:GetName() .. "Text"]
    warnClassSoulstoneText:SetText("Warlock: Soulstone someone")
    warnClassSoulstoneText:SetTextColor(1, 1, 1)
    local warnClassSoulstoneDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnClassSoulstoneDesc:SetPoint("TOPLEFT", warnClassSoulstoneCheck, "BOTTOMLEFT", 26, 2)
    warnClassSoulstoneDesc:SetText("|cff888888Warn when no one has Soulstone|r")
    warnClassSoulstoneDesc:SetScale(0.85)
    warnClassSoulstoneCheck:SetChecked(MattActionBarFontDB.warnClassSoulstone)

    local warnClassShamanShieldsCheck = CreateFrame("CheckButton", "MABFWarnClassShamanShieldsCheck", page, "InterfaceOptionsCheckButtonTemplate")
    warnClassShamanShieldsCheck:SetPoint("TOPLEFT", warnClassSoulstoneCheck, "TOPLEFT", 0, -44)
    local warnClassShamanShieldsText = _G[warnClassShamanShieldsCheck:GetName() .. "Text"]
    warnClassShamanShieldsText:SetText("Shaman: Missing shields")
    warnClassShamanShieldsText:SetTextColor(1, 1, 1)
    local warnClassShamanShieldsDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnClassShamanShieldsDesc:SetPoint("TOPLEFT", warnClassShamanShieldsCheck, "BOTTOMLEFT", 26, 2)
    warnClassShamanShieldsDesc:SetText("|cff888888Warn when shields are missing|r")
    warnClassShamanShieldsDesc:SetScale(0.85)
    warnClassShamanShieldsCheck:SetChecked(MattActionBarFontDB.warnClassShamanShields)

    local warnClassPaladinBeaconsCheck = CreateFrame("CheckButton", "MABFWarnClassPaladinBeaconsCheck", page, "InterfaceOptionsCheckButtonTemplate")
    warnClassPaladinBeaconsCheck:SetPoint("TOPLEFT", warnClassShamanShieldsCheck, "TOPLEFT", 0, -44)
    local warnClassPaladinBeaconsText = _G[warnClassPaladinBeaconsCheck:GetName() .. "Text"]
    warnClassPaladinBeaconsText:SetText("Paladin: Missing beacons")
    warnClassPaladinBeaconsText:SetTextColor(1, 1, 1)
    local warnClassPaladinBeaconsDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnClassPaladinBeaconsDesc:SetPoint("TOPLEFT", warnClassPaladinBeaconsCheck, "BOTTOMLEFT", 26, 2)
    warnClassPaladinBeaconsDesc:SetText("|cff888888Holy only; hidden with Beacon of Virtue|r")
    warnClassPaladinBeaconsDesc:SetScale(0.85)
    warnClassPaladinBeaconsCheck:SetChecked(MattActionBarFontDB.warnClassPaladinBeacons)

    local function CreateClassSubCheckbox(name, anchorTo, xOffset, labelText, checkedValue, onClick)
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

    local classOnlyInInstanceCheck = CreateClassSubCheckbox("MABFClassOnlyInInstanceCheck", warnClassPaladinBeaconsDesc, 26, "Only in dungeons/raids/scenarios", MattActionBarFontDB.classOnlyInInstance, function(self)
        MattActionBarFontDB.classOnlyInInstance = self:GetChecked() and true or false
        MABF:SetupClassStuffReminder()
    end)
    local classHideInRestAreaCheck = CreateClassSubCheckbox("MABFClassHideInRestAreaCheck", classOnlyInInstanceCheck, 0, "Hide while resting", MattActionBarFontDB.classHideInRestArea, function(self)
        MattActionBarFontDB.classHideInRestArea = self:GetChecked() and true or false
        MABF:SetupClassStuffReminder()
    end)
    local classSuppressInMPlusCheck = CreateClassSubCheckbox("MABFClassSuppressInMPlusCheck", classHideInRestAreaCheck, 0, "Hide during active Mythic+", MattActionBarFontDB.classSuppressInMPlus, function(self)
        MattActionBarFontDB.classSuppressInMPlus = self:GetChecked() and true or false
        MABF:SetupClassStuffReminder()
    end)
    local classSuppressAfterFirstPullCheck = CreateClassSubCheckbox("MABFClassSuppressAfterFirstPullCheck", classSuppressInMPlusCheck, 0, "Hide after first pull", MattActionBarFontDB.classSuppressAfterFirstPull, function(self)
        MattActionBarFontDB.classSuppressAfterFirstPull = self:GetChecked() and true or false
        MABF:SetupClassStuffReminder()
    end)
    local classHideWhenLFGCompleteCheck = CreateClassSubCheckbox("MABFClassHideWhenLFGCompleteCheck", classSuppressAfterFirstPullCheck, 0, "Hide when LFG run is complete", MattActionBarFontDB.classHideWhenLFGComplete, function(self)
        MattActionBarFontDB.classHideWhenLFGComplete = self:GetChecked() and true or false
        MABF:SetupClassStuffReminder()
    end)

    local classStuffScaleSlider = CreateFrame("Slider", "MABFClassStuffScaleSlider", page, "OptionsSliderTemplate")
    classStuffScaleSlider:SetSize(180, 14)
    classStuffScaleSlider:SetPoint("BOTTOM", page, "BOTTOM", 0, 74)
    classStuffScaleSlider:SetMinMaxValues(50, 200)
    classStuffScaleSlider:SetValue((MattActionBarFontDB.classStuffReminderScale or 1.0) * 100)
    classStuffScaleSlider:SetValueStep(1)
    classStuffScaleSlider:SetObeyStepOnDrag(true)
    local classStuffScaleSliderName = classStuffScaleSlider:GetName()
    _G[classStuffScaleSliderName .. "Low"]:SetText("50%")
    _G[classStuffScaleSliderName .. "High"]:SetText("200%")
    _G[classStuffScaleSliderName .. "Text"]:SetText("Class Reminder Size: " .. math.floor((MattActionBarFontDB.classStuffReminderScale or 1.0) * 100) .. "%")
    StyleSlider(classStuffScaleSlider)
    classStuffScaleSlider:SetScript("OnValueChanged", function(self, value)
        local pct = math.floor((value or 100) + 0.5)
        if pct < 50 then pct = 50 end
        if pct > 200 then pct = 200 end
        MattActionBarFontDB.classStuffReminderScale = pct / 100
        _G[classStuffScaleSliderName .. "Text"]:SetText("Class Reminder Size: " .. pct .. "%")
        if MABF and MABF.ApplyClassStuffReminderScale then
            MABF:ApplyClassStuffReminderScale()
        end
    end)

    local warnClassStuffResetBtn = CreateReminderResetButton("MABFWarnClassStuffResetBtn", page, function()
        if MABF and MABF.ResetClassStuffReminderPosition then
            MABF:ResetClassStuffReminderPosition()
            if MABF.SetupClassStuffReminder then
                MABF:SetupClassStuffReminder()
            end
        end
    end)
    local warnClassStuffResetSizeBtn = CreateReminderResetSizeButton("MABFWarnClassStuffResetSizeBtn", page, function()
        if classStuffScaleSlider then
            classStuffScaleSlider:SetValue(100)
        end
        MattActionBarFontDB.classStuffReminderScale = 1.0
        if MABF and MABF.ApplyClassStuffReminderScale then
            MABF:ApplyClassStuffReminderScale()
        end
    end)

    local function RefreshClassStuffSubOptions()
        local enabled = (warnClassSoulstoneCheck:GetChecked() or warnClassShamanShieldsCheck:GetChecked() or warnClassPaladinBeaconsCheck:GetChecked()) and true or false
        local labels = {
            _G[warnClassSoulstoneCheck:GetName() .. "Text"],
            _G[warnClassShamanShieldsCheck:GetName() .. "Text"],
            _G[warnClassPaladinBeaconsCheck:GetName() .. "Text"],
        }
        for _, label in ipairs(labels) do
            if label then
                label:SetTextColor(enabled and 1 or 0.9, enabled and 1 or 0.9, enabled and 1 or 0.9)
            end
        end
    end

    local function RefreshClassStuffSubRules()
        local enabled = (warnClassSoulstoneCheck:GetChecked() or warnClassShamanShieldsCheck:GetChecked() or warnClassPaladinBeaconsCheck:GetChecked()) and true or false
        local subChecks = {
            classOnlyInInstanceCheck,
            classHideInRestAreaCheck,
            classSuppressInMPlusCheck,
            classSuppressAfterFirstPullCheck,
            classHideWhenLFGCompleteCheck,
        }
        for _, cb in ipairs(subChecks) do
            cb:SetEnabled(enabled)
            local t = _G[cb:GetName() .. "Text"]
            if t then t:SetTextColor(enabled and 1 or 0.55, enabled and 1 or 0.55, enabled and 1 or 0.55) end
        end
    end

    local function RefreshClassStuffScaleControl()
        local enabled = (warnClassSoulstoneCheck:GetChecked() or warnClassShamanShieldsCheck:GetChecked() or warnClassPaladinBeaconsCheck:GetChecked()) and true or false
        if classStuffScaleSlider then
            classStuffScaleSlider:SetEnabled(enabled)
            classStuffScaleSlider:SetAlpha(enabled and 1 or 0.6)
        end
    end

    local function OnAnyPrimaryClassToggle(setter, value)
        setter(value)
        MABF:SetupClassStuffReminder()
        RefreshClassStuffSubOptions()
        RefreshClassStuffSubRules()
        RefreshClassStuffScaleControl()
    end

    warnClassSoulstoneCheck:SetScript("OnClick", function(self)
        OnAnyPrimaryClassToggle(function(v) MattActionBarFontDB.warnClassSoulstone = v end, self:GetChecked() and true or false)
    end)
    warnClassShamanShieldsCheck:SetScript("OnClick", function(self)
        OnAnyPrimaryClassToggle(function(v) MattActionBarFontDB.warnClassShamanShields = v end, self:GetChecked() and true or false)
    end)
    warnClassPaladinBeaconsCheck:SetScript("OnClick", function(self)
        OnAnyPrimaryClassToggle(function(v) MattActionBarFontDB.warnClassPaladinBeacons = v end, self:GetChecked() and true or false)
    end)

    return {
        warnClassSoulstoneCheck = warnClassSoulstoneCheck,
        warnClassShamanShieldsCheck = warnClassShamanShieldsCheck,
        warnClassPaladinBeaconsCheck = warnClassPaladinBeaconsCheck,
        warnClassStuffResetBtn = warnClassStuffResetBtn,
        warnClassStuffResetSizeBtn = warnClassStuffResetSizeBtn,
        classOnlyInInstanceCheck = classOnlyInInstanceCheck,
        classHideInRestAreaCheck = classHideInRestAreaCheck,
        classSuppressInMPlusCheck = classSuppressInMPlusCheck,
        classSuppressAfterFirstPullCheck = classSuppressAfterFirstPullCheck,
        classHideWhenLFGCompleteCheck = classHideWhenLFGCompleteCheck,
        RefreshClassStuffSubOptions = RefreshClassStuffSubOptions,
        RefreshClassStuffSubRules = RefreshClassStuffSubRules,
        RefreshClassStuffScaleControl = RefreshClassStuffScaleControl,
    }
end
