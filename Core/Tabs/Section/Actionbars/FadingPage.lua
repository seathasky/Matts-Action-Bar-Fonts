local addonName, MABF = ...

-- Builds the Action Bars > Fading options page UI.
function MABF:BuildActionBarFadingPage(opts)
    if type(opts) ~= "table" then return nil end

    local CreateContentPage = opts.CreateContentPage
    local CreatePageTitle = opts.CreatePageTitle
    local CreateBasicCheckbox = opts.CreateBasicCheckbox
    local StyleSlider = opts.StyleSlider

    if not CreateContentPage or not CreatePageTitle or not CreateBasicCheckbox or not StyleSlider then
        return nil
    end

    local pageABFading = CreateContentPage(4)
    local abFadingTitle = CreatePageTitle(pageABFading, "AB Fading")
    local RefreshMouseoverFadeControls

    local mouseoverFadeCheck = CreateBasicCheckbox(
        pageABFading,
        "MABFMouseoverFadeCheck",
        abFadingTitle,
        "TOPLEFT",
        0,
        -8,
        "Enable Mouseover Fade (Action Bars)",
        MattActionBarFontDB.mouseoverFade,
        function(self)
            local enabled = self:GetChecked() and true or false
            if not enabled and MABF.ResetActionBarMouseoverState then
                MABF:ResetActionBarMouseoverState()
            end
            MattActionBarFontDB.mouseoverFade = enabled
            MABF:ApplyActionBarMouseover()
            if enabled then
                MABF:SetBarsMouseoverState(false)
            end
            if RefreshMouseoverFadeControls then
                RefreshMouseoverFadeControls()
            end
        end
    )

    local mouseoverTargetsTitle = pageABFading:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    mouseoverTargetsTitle:SetPoint("TOPLEFT", mouseoverFadeCheck, "BOTTOMLEFT", 26, -10)
    mouseoverTargetsTitle:SetText("Select Action Bar to fade:")
    mouseoverTargetsTitle:SetTextColor(1, 1, 1)

    local mouseoverBarChecks = {}
    local mouseoverBarDefs = {
        { key = "bar1", label = "Bar 1 (Main)" },
        { key = "bar2", label = "Bar 2" },
        { key = "bar3", label = "Bar 3" },
        { key = "bar4", label = "Bar 4" },
        { key = "bar5", label = "Bar 5" },
        { key = "bar6", label = "Bar 6" },
    }

    local previousAnchor = mouseoverTargetsTitle
    for _, barDef in ipairs(mouseoverBarDefs) do
        local check = CreateFrame("CheckButton", "MABFMouseoverFadeTarget_" .. barDef.key, pageABFading, "InterfaceOptionsCheckButtonTemplate")
        check:ClearAllPoints()
        check:SetPoint("TOPLEFT", previousAnchor, "BOTTOMLEFT", 0, -4)
        local label = _G[check:GetName() .. "Text"]
        label:SetText(barDef.label)
        label:SetTextColor(1, 1, 1)
        check:SetChecked(MattActionBarFontDB.mouseoverFadeBars and MattActionBarFontDB.mouseoverFadeBars[barDef.key] and true or false)
        check:SetScript("OnClick", function(self)
            if type(MattActionBarFontDB.mouseoverFadeBars) ~= "table" then
                MattActionBarFontDB.mouseoverFadeBars = {}
            end
            local enabled = self:GetChecked() and true or false
            MattActionBarFontDB.mouseoverFadeBars[barDef.key] = enabled
            if not enabled and MABF.ResetActionBarMouseoverStateForBar then
                MABF:ResetActionBarMouseoverStateForBar(barDef.key)
            end
            MABF:ApplyActionBarMouseover()
            if RefreshMouseoverFadeControls then
                RefreshMouseoverFadeControls()
            end
        end)
        mouseoverBarChecks[#mouseoverBarChecks + 1] = check
        previousAnchor = check
    end

    local petBarFadeCheck = CreateBasicCheckbox(
        pageABFading,
        "MABFPetBarFadeCheck",
        previousAnchor,
        "TOPLEFT",
        0,
        -4,
        "Pet Bar",
        MattActionBarFontDB.petBarMouseoverFade,
        function(self)
            MattActionBarFontDB.petBarMouseoverFade = self:GetChecked() and true or false
            MABF:ApplyPetBarMouseoverFade()
        end
    )

    local fadeDurationSlider = CreateFrame("Slider", "MABFActionBarFadeDurationSlider", pageABFading, "OptionsSliderTemplate")
    fadeDurationSlider:SetSize(228, 14)
    fadeDurationSlider:SetPoint("TOPLEFT", petBarFadeCheck, "BOTTOMLEFT", 0, -22)
    fadeDurationSlider:SetMinMaxValues(0, 100)
    fadeDurationSlider:SetValue((tonumber(MattActionBarFontDB.actionBarFadeDuration) or 0.15) * 100)
    fadeDurationSlider:SetValueStep(5)
    fadeDurationSlider:SetObeyStepOnDrag(true)
    local fadeDurationName = fadeDurationSlider:GetName()
    _G[fadeDurationName .. "Low"]:SetText("0.00s")
    _G[fadeDurationName .. "High"]:SetText("1.00s")
    _G[fadeDurationName .. "Text"]:SetText(string.format("Fade Duration: %.2fs", tonumber(MattActionBarFontDB.actionBarFadeDuration) or 0.15))
    StyleSlider(fadeDurationSlider)
    fadeDurationSlider:SetScript("OnValueChanged", function(self, value)
        local rounded = math.floor((value or 0) + 0.5)
        local duration = rounded / 100
        MattActionBarFontDB.actionBarFadeDuration = duration
        _G[self:GetName() .. "Text"]:SetText(string.format("Fade Duration: %.2fs", duration))
        MABF:ApplyActionBarMouseover()
        MABF:ApplyPetBarMouseoverFade()
    end)

    RefreshMouseoverFadeControls = function()
        local fadeEnabled = MattActionBarFontDB.mouseoverFade and true or false
        mouseoverTargetsTitle:SetTextColor(fadeEnabled and 1 or 0.6, fadeEnabled and 1 or 0.6, fadeEnabled and 1 or 0.6)
        fadeDurationSlider:EnableMouse(fadeEnabled)
        fadeDurationSlider:SetAlpha(fadeEnabled and 1 or 0.6)

        local customEnabled = fadeEnabled
        for _, cb in ipairs(mouseoverBarChecks) do
            cb:SetEnabled(customEnabled)
            cb:SetAlpha(customEnabled and 1 or 0.6)
        end
    end

    RefreshMouseoverFadeControls()

    return {
        page = pageABFading,
        mouseoverFadeCheck = mouseoverFadeCheck,
        petBarFadeCheck = petBarFadeCheck,
        mouseoverBarChecks = mouseoverBarChecks,
    }
end
