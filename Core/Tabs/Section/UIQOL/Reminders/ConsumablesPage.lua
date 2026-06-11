local addonName, MABF = ...

-- Builds the Reminders > Consumables sub-page controls and returns refresh hooks.
function MABF:BuildRemindersConsumablesPage(opts)
    if type(opts) ~= "table" then return nil end

    local page = opts.page
    local checkSpacing = opts.checkSpacing
    local StyleSlider = opts.StyleSlider
    local CreateReminderResetButton = opts.CreateReminderResetButton
    local CreateReminderResetSizeButton = opts.CreateReminderResetSizeButton

    if not page or not checkSpacing or not StyleSlider or not CreateReminderResetButton or not CreateReminderResetSizeButton then
        return nil
    end

    local scrollFrame = CreateFrame("ScrollFrame", "MABFConsumablesScrollFrame", page, "UIPanelScrollFrameTemplate")
    scrollFrame:SetPoint("TOPLEFT", page, "TOPLEFT", 0, 0)
    scrollFrame:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", 0, 0)
    scrollFrame:EnableMouseWheel(true)

    local scrollContent = CreateFrame("Frame", nil, scrollFrame)
    scrollContent:SetSize(1, 680)
    scrollFrame:SetScrollChild(scrollContent)
    scrollFrame:SetScript("OnSizeChanged", function(_, width)
        scrollContent:SetWidth(math.max(width, 1))
    end)
    scrollFrame:HookScript("OnShow", function(self)
        scrollContent:SetWidth(math.max(self:GetWidth(), 1))
    end)
    scrollFrame:SetScript("OnMouseWheel", function(self, delta)
        local scrollBar = _G[self:GetName() .. "ScrollBar"]
        if not scrollBar then return end
        local minValue, maxValue = scrollBar:GetMinMaxValues()
        local nextValue = math.max(minValue, math.min(maxValue, scrollBar:GetValue() - (delta * 36)))
        scrollBar:SetValue(nextValue)
    end)
    scrollContent:SetWidth(math.max(scrollFrame:GetWidth(), page:GetWidth(), 1))
    page = scrollContent

    local trackConsumablesCheck = CreateFrame("CheckButton", "MABFTrackConsumablesCheck", page, "InterfaceOptionsCheckButtonTemplate")
    trackConsumablesCheck:ClearAllPoints()
    trackConsumablesCheck:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -4)
    local trackConsumablesText = _G[trackConsumablesCheck:GetName() .. "Text"]
    trackConsumablesText:SetText("Track consumables")
    trackConsumablesText:SetTextColor(1, 1, 1)
    local trackConsumablesDesc = page:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    trackConsumablesDesc:SetPoint("TOPLEFT", trackConsumablesCheck, "BOTTOMLEFT", 26, 2)
    trackConsumablesDesc:SetText("|cff888888Warns when selected consumables are missing|r")
    trackConsumablesDesc:SetScale(0.85)
    trackConsumablesCheck:SetChecked(MattActionBarFontDB.trackConsumables)

    local function CreateConsumablesSubCheckbox(name, anchorTo, xOffset, labelText, checkedValue, onClick)
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

    local consumablesFoodCheck = CreateConsumablesSubCheckbox("MABFConsumablesFoodCheck", trackConsumablesDesc, 26, "Track Food", MattActionBarFontDB.warnConsumableFood ~= false, function(self)
        MattActionBarFontDB.warnConsumableFood = self:GetChecked() and true or false
        MABF:UpdateConsumableReminder()
    end)
    local consumablesFlaskCheck = CreateConsumablesSubCheckbox("MABFConsumablesFlaskCheck", consumablesFoodCheck, 0, "Track Flask/Phial", MattActionBarFontDB.warnConsumableFlask ~= false, function(self)
        MattActionBarFontDB.warnConsumableFlask = self:GetChecked() and true or false
        MABF:UpdateConsumableReminder()
    end)
    local consumablesOilCheck = CreateConsumablesSubCheckbox("MABFConsumablesOilCheck", consumablesFlaskCheck, 0, "Track Weapon Oil", MattActionBarFontDB.warnConsumableOil ~= false, function(self)
        MattActionBarFontDB.warnConsumableOil = self:GetChecked() and true or false
        MABF:UpdateConsumableReminder()
    end)
    local consumablesAugmentRuneCheck = CreateConsumablesSubCheckbox("MABFConsumablesAugmentRuneCheck", consumablesOilCheck, 0, "Track Augment Rune", MattActionBarFontDB.warnConsumableAugmentRune ~= false, function(self)
        MattActionBarFontDB.warnConsumableAugmentRune = self:GetChecked() and true or false
        MABF:UpdateConsumableReminder()
    end)
    local consumablesHealthstoneCheck = CreateConsumablesSubCheckbox("MABFConsumablesHealthstoneCheck", consumablesAugmentRuneCheck, 0, "Track Healthstone (warlock in group)", MattActionBarFontDB.warnConsumableHealthstone, function(self)
        MattActionBarFontDB.warnConsumableHealthstone = self:GetChecked() and true or false
        MABF:UpdateConsumableReminder()
    end)

    local consumablesOnlyInstanceCheck = CreateConsumablesSubCheckbox("MABFConsumablesOnlyInstanceCheck", consumablesHealthstoneCheck, 0, "Only in dungeons/raids/scenarios", MattActionBarFontDB.consumablesOnlyInInstance, function(self)
        MattActionBarFontDB.consumablesOnlyInInstance = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
    end)
    local consumablesHideInRestAreaCheck = CreateConsumablesSubCheckbox("MABFConsumablesHideInRestAreaCheck", consumablesOnlyInstanceCheck, 0, "Hide while resting", MattActionBarFontDB.consumablesHideInRestArea, function(self)
        MattActionBarFontDB.consumablesHideInRestArea = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
    end)
    local consumablesHideWhileMountedCheck = CreateConsumablesSubCheckbox("MABFConsumablesHideWhileMountedCheck", consumablesHideInRestAreaCheck, 0, "Hide while mounted", MattActionBarFontDB.consumablesHideWhileMounted, function(self)
        MattActionBarFontDB.consumablesHideWhileMounted = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
    end)
    local consumablesSuppressInMPlusCheck = CreateConsumablesSubCheckbox("MABFConsumablesSuppressInMPlusCheck", consumablesHideWhileMountedCheck, 0, "Hide during active Mythic+", MattActionBarFontDB.consumablesSuppressInMPlus, function(self)
        MattActionBarFontDB.consumablesSuppressInMPlus = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
    end)
    local consumablesSuppressAfterFirstPullCheck = CreateConsumablesSubCheckbox("MABFConsumablesSuppressAfterFirstPullCheck", consumablesSuppressInMPlusCheck, 0, "Hide after first pull", MattActionBarFontDB.consumablesSuppressAfterFirstPull, function(self)
        MattActionBarFontDB.consumablesSuppressAfterFirstPull = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
    end)
    local consumablesHideWhenLFGCompleteCheck = CreateConsumablesSubCheckbox("MABFConsumablesHideWhenLFGCompleteCheck", consumablesSuppressAfterFirstPullCheck, 0, "Hide when LFG run is complete", MattActionBarFontDB.consumablesHideWhenLFGComplete, function(self)
        MattActionBarFontDB.consumablesHideWhenLFGComplete = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
    end)
    local consumableScaleSlider = CreateFrame("Slider", "MABFConsumableScaleSlider", page, "OptionsSliderTemplate")
    consumableScaleSlider:SetSize(180, 14)
    consumableScaleSlider:SetPoint("BOTTOM", page, "BOTTOM", 0, 74)
    consumableScaleSlider:SetMinMaxValues(50, 200)
    consumableScaleSlider:SetValue((MattActionBarFontDB.consumableReminderScale or 1.0) * 100)
    consumableScaleSlider:SetValueStep(1)
    consumableScaleSlider:SetObeyStepOnDrag(true)
    local consumableScaleSliderName = consumableScaleSlider:GetName()
    _G[consumableScaleSliderName .. "Low"]:SetText("50%")
    _G[consumableScaleSliderName .. "High"]:SetText("200%")
    _G[consumableScaleSliderName .. "Text"]:SetText("Consumables Size: " .. math.floor((MattActionBarFontDB.consumableReminderScale or 1.0) * 100) .. "%")
    StyleSlider(consumableScaleSlider)
    consumableScaleSlider:SetScript("OnValueChanged", function(self, value)
        local pct = math.floor((value or 100) + 0.5)
        if pct < 50 then pct = 50 end
        if pct > 200 then pct = 200 end
        MattActionBarFontDB.consumableReminderScale = pct / 100
        _G[consumableScaleSliderName .. "Text"]:SetText("Consumables Size: " .. pct .. "%")
        if MABF and MABF.ApplyConsumableReminderScale then
            MABF:ApplyConsumableReminderScale()
        end
    end)

    local trackConsumablesResetBtn = CreateReminderResetButton("MABFTrackConsumablesResetBtn", page, function()
        if MABF and MABF.ResetConsumableReminderPosition then
            MABF:ResetConsumableReminderPosition()
            if MABF.SetupConsumableReminder then
                MABF:SetupConsumableReminder()
            end
        end
    end)
    local trackConsumablesResetSizeBtn = CreateReminderResetSizeButton("MABFTrackConsumablesResetSizeBtn", page, function()
        if consumableScaleSlider then
            consumableScaleSlider:SetValue(100)
        end
        MattActionBarFontDB.consumableReminderScale = 1.0
        if MABF and MABF.ApplyConsumableReminderScale then
            MABF:ApplyConsumableReminderScale()
        end
    end)

    local function RefreshConsumableSubOptions()
        local enabled = trackConsumablesCheck:GetChecked() and true or false
        local subChecks = {
            consumablesFoodCheck,
            consumablesFlaskCheck,
            consumablesOilCheck,
            consumablesAugmentRuneCheck,
            consumablesHealthstoneCheck,
            consumablesOnlyInstanceCheck,
            consumablesHideInRestAreaCheck,
            consumablesHideWhileMountedCheck,
            consumablesSuppressInMPlusCheck,
            consumablesSuppressAfterFirstPullCheck,
            consumablesHideWhenLFGCompleteCheck,
        }
        for _, cb in ipairs(subChecks) do
            cb:SetEnabled(enabled)
            local t = _G[cb:GetName() .. "Text"]
            if t then t:SetTextColor(enabled and 1 or 0.55, enabled and 1 or 0.55, enabled and 1 or 0.55) end
        end
        if consumableScaleSlider then
            consumableScaleSlider:SetEnabled(enabled)
        end
    end

    trackConsumablesCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.trackConsumables = self:GetChecked() and true or false
        MABF:SetupConsumableReminder()
        RefreshConsumableSubOptions()
    end)

    return {
        trackConsumablesCheck = trackConsumablesCheck,
        trackConsumablesText = trackConsumablesText,
        trackConsumablesResetBtn = trackConsumablesResetBtn,
        trackConsumablesResetSizeBtn = trackConsumablesResetSizeBtn,
        consumablesFoodCheck = consumablesFoodCheck,
        consumablesFlaskCheck = consumablesFlaskCheck,
        consumablesOilCheck = consumablesOilCheck,
        consumablesAugmentRuneCheck = consumablesAugmentRuneCheck,
        consumablesOnlyInstanceCheck = consumablesOnlyInstanceCheck,
        consumablesHideInRestAreaCheck = consumablesHideInRestAreaCheck,
        consumablesHideWhileMountedCheck = consumablesHideWhileMountedCheck,
        consumablesSuppressInMPlusCheck = consumablesSuppressInMPlusCheck,
        consumablesSuppressAfterFirstPullCheck = consumablesSuppressAfterFirstPullCheck,
        consumablesHideWhenLFGCompleteCheck = consumablesHideWhenLFGCompleteCheck,
        consumablesHealthstoneCheck = consumablesHealthstoneCheck,
        RefreshConsumableSubOptions = RefreshConsumableSubOptions,
    }
end
