local addonName, MABF = ...

-- Builds the Reminders > Buffs sub-page controls and returns refresh hooks.
function MABF:BuildRemindersBuffsPage(opts)
    if type(opts) ~= "table" then return nil end

    local page = opts.page
    local checkSpacing = opts.checkSpacing
    local StyleSlider = opts.StyleSlider
    local CreateReminderResetButton = opts.CreateReminderResetButton
    local CreateReminderResetSizeButton = opts.CreateReminderResetSizeButton

    if not page or not checkSpacing or not StyleSlider or not CreateReminderResetButton or not CreateReminderResetSizeButton then
        return nil
    end

    local warnMissingClassBuffsCheck = CreateFrame("CheckButton", "MABFWarnMissingClassBuffsCheck", page, "InterfaceOptionsCheckButtonTemplate")
    warnMissingClassBuffsCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 10)
    local warnMissingClassBuffsText = _G[warnMissingClassBuffsCheck:GetName() .. "Text"]
    warnMissingClassBuffsText:SetText("Warn when class buff is missing")
    warnMissingClassBuffsText:SetTextColor(1, 1, 1)
    local warnMissingClassBuffsDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    warnMissingClassBuffsDesc:SetPoint("TOPLEFT", warnMissingClassBuffsCheck, "BOTTOMLEFT", 26, 2)
    warnMissingClassBuffsDesc:SetText("|cff888888Tracks major class buffs for supported classes|r")
    warnMissingClassBuffsDesc:SetScale(0.85)
    warnMissingClassBuffsCheck:SetChecked(MattActionBarFontDB.warnMissingClassBuffs)

    local buffReminderScaleSlider = CreateFrame("Slider", "MABFBuffReminderScaleSlider", page, "OptionsSliderTemplate")
    buffReminderScaleSlider:SetSize(180, 14)
    buffReminderScaleSlider:SetPoint("TOPLEFT", warnMissingClassBuffsDesc, "BOTTOMLEFT", 0, -18)
    buffReminderScaleSlider:SetMinMaxValues(50, 200)
    buffReminderScaleSlider:SetValue((MattActionBarFontDB.missingBuffReminderScale or 1.0) * 100)
    buffReminderScaleSlider:SetValueStep(1)
    buffReminderScaleSlider:SetObeyStepOnDrag(true)
    local buffReminderScaleSliderName = buffReminderScaleSlider:GetName()
    _G[buffReminderScaleSliderName .. "Low"]:SetText("50%")
    _G[buffReminderScaleSliderName .. "High"]:SetText("200%")
    _G[buffReminderScaleSliderName .. "Text"]:SetText("Buff Reminder Size: " .. math.floor((MattActionBarFontDB.missingBuffReminderScale or 1.0) * 100) .. "%")
    StyleSlider(buffReminderScaleSlider)
    buffReminderScaleSlider:SetScript("OnValueChanged", function(self, value)
        local pct = math.floor((value or 100) + 0.5)
        if pct < 50 then pct = 50 end
        if pct > 200 then pct = 200 end
        MattActionBarFontDB.missingBuffReminderScale = pct / 100
        _G[buffReminderScaleSliderName .. "Text"]:SetText("Buff Reminder Size: " .. pct .. "%")
        if MABF and MABF.ApplyMissingBuffReminderScale then
            MABF:ApplyMissingBuffReminderScale()
        end
    end)

    local warnMissingClassBuffsResetBtn = CreateReminderResetButton("MABFWarnMissingClassBuffsResetBtn", page, function()
        if MABF and MABF.ResetMissingBuffReminderPosition then
            MABF:ResetMissingBuffReminderPosition()
            if MABF.SetupMissingBuffReminder then
                MABF:SetupMissingBuffReminder()
            end
        end
    end)
    local warnMissingClassBuffsResetSizeBtn = CreateReminderResetSizeButton("MABFWarnMissingClassBuffsResetSizeBtn", page, function()
        if buffReminderScaleSlider then
            buffReminderScaleSlider:SetValue(100)
        end
        MattActionBarFontDB.missingBuffReminderScale = 1.0
        if MABF and MABF.ApplyMissingBuffReminderScale then
            MABF:ApplyMissingBuffReminderScale()
        end
    end)

    local function CreateBuffSubCheckbox(name, anchorTo, xOffset, labelText, checkedValue, onClick)
        local cb = CreateFrame("CheckButton", name, page, "InterfaceOptionsCheckButtonTemplate")
        cb:SetPoint("TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset or 0, checkSpacing)
        local label = _G[cb:GetName() .. "Text"]
        label:SetText(labelText)
        label:SetTextColor(1, 1, 1)
        cb:SetChecked(checkedValue and true or false)
        cb:SetScript("OnClick", onClick)
        return cb
    end

    local buffsOnlyInInstanceCheck = CreateBuffSubCheckbox("MABFBuffsOnlyInInstanceCheck", warnMissingClassBuffsDesc, 26, "Only in dungeons/raids/scenarios", MattActionBarFontDB.buffsOnlyInInstance, function(self)
        MattActionBarFontDB.buffsOnlyInInstance = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
    end)
    local buffsHideInRestAreaCheck = CreateBuffSubCheckbox("MABFBuffsHideInRestAreaCheck", buffsOnlyInInstanceCheck, 0, "Hide while resting", MattActionBarFontDB.buffsHideInRestArea, function(self)
        MattActionBarFontDB.buffsHideInRestArea = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
    end)
    local buffsHideWhileMountedCheck = CreateBuffSubCheckbox("MABFBuffsHideWhileMountedCheck", buffsHideInRestAreaCheck, 0, "Hide while mounted", MattActionBarFontDB.buffsHideWhileMounted, function(self)
        MattActionBarFontDB.buffsHideWhileMounted = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
    end)
    local buffsSuppressInMPlusCheck = CreateBuffSubCheckbox("MABFBuffsSuppressInMPlusCheck", buffsHideWhileMountedCheck, 0, "Hide during active Mythic+", MattActionBarFontDB.buffsSuppressInMPlus, function(self)
        MattActionBarFontDB.buffsSuppressInMPlus = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
    end)
    local buffsSuppressAfterFirstPullCheck = CreateBuffSubCheckbox("MABFBuffsSuppressAfterFirstPullCheck", buffsSuppressInMPlusCheck, 0, "Hide after first pull", MattActionBarFontDB.buffsSuppressAfterFirstPull, function(self)
        MattActionBarFontDB.buffsSuppressAfterFirstPull = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
    end)
    local buffsHideWhenLFGCompleteCheck = CreateBuffSubCheckbox("MABFBuffsHideWhenLFGCompleteCheck", buffsSuppressAfterFirstPullCheck, 0, "Hide when LFG run is complete", MattActionBarFontDB.buffsHideWhenLFGComplete, function(self)
        MattActionBarFontDB.buffsHideWhenLFGComplete = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
    end)

    buffReminderScaleSlider:ClearAllPoints()
    buffReminderScaleSlider:SetPoint("BOTTOM", page, "BOTTOM", 0, 74)

    local function RefreshBuffSubOptions()
        local enabled = warnMissingClassBuffsCheck:GetChecked() and true or false
        local subChecks = {
            buffsOnlyInInstanceCheck,
            buffsHideInRestAreaCheck,
            buffsHideWhileMountedCheck,
            buffsSuppressInMPlusCheck,
            buffsSuppressAfterFirstPullCheck,
            buffsHideWhenLFGCompleteCheck,
        }
        for _, cb in ipairs(subChecks) do
            cb:SetEnabled(enabled)
            local t = _G[cb:GetName() .. "Text"]
            if t then t:SetTextColor(enabled and 1 or 0.55, enabled and 1 or 0.55, enabled and 1 or 0.55) end
        end
    end

    local function RefreshBuffReminderScaleControl()
        local enabled = warnMissingClassBuffsCheck:GetChecked() and true or false
        if buffReminderScaleSlider then
            buffReminderScaleSlider:SetEnabled(enabled)
            buffReminderScaleSlider:SetAlpha(enabled and 1 or 0.6)
        end
    end

    warnMissingClassBuffsCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.warnMissingClassBuffs = self:GetChecked() and true or false
        MABF:SetupMissingBuffReminder()
        RefreshBuffSubOptions()
        RefreshBuffReminderScaleControl()
    end)

    return {
        warnMissingClassBuffsCheck = warnMissingClassBuffsCheck,
        warnMissingClassBuffsText = warnMissingClassBuffsText,
        warnMissingClassBuffsResetBtn = warnMissingClassBuffsResetBtn,
        warnMissingClassBuffsResetSizeBtn = warnMissingClassBuffsResetSizeBtn,
        buffsOnlyInInstanceCheck = buffsOnlyInInstanceCheck,
        buffsHideInRestAreaCheck = buffsHideInRestAreaCheck,
        buffsHideWhileMountedCheck = buffsHideWhileMountedCheck,
        buffsSuppressInMPlusCheck = buffsSuppressInMPlusCheck,
        buffsSuppressAfterFirstPullCheck = buffsSuppressAfterFirstPullCheck,
        buffsHideWhenLFGCompleteCheck = buffsHideWhenLFGCompleteCheck,
        RefreshBuffSubOptions = RefreshBuffSubOptions,
        RefreshBuffReminderScaleControl = RefreshBuffReminderScaleControl,
    }
end
