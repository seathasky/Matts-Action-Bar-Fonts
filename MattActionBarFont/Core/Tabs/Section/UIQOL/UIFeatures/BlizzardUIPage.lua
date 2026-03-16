local addonName, MABF = ...

-- Builds UI / QoL > UI Features > Blizzard UI controls.
function MABF:BuildUIFeaturesBlizzardPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageUIFeatures = opts.pageUIFeatures
    local uiFeaturesTitle = opts.uiFeaturesTitle
    if not pageUIFeatures or not uiFeaturesTitle then
        return nil
    end

    local objectiveTrackerCheck = CreateFrame("CheckButton", "MABFObjectiveTrackerCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    objectiveTrackerCheck:ClearAllPoints()
    objectiveTrackerCheck:SetPoint("TOPLEFT", uiFeaturesTitle, "BOTTOMLEFT", 0, -8)
    local objCheckText = _G[objectiveTrackerCheck:GetName() .. "Text"]
    objCheckText:SetText("Scale Objective Tracker (0.7)")
    objCheckText:SetTextColor(1, 1, 1)
    objectiveTrackerCheck:SetChecked(MattActionBarFontDB.scaleObjectiveTracker)
    objectiveTrackerCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleObjectiveTracker = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    local scaleStatusBarCheck = CreateFrame("CheckButton", "MABFScaleStatusBarCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    scaleStatusBarCheck:ClearAllPoints()
    scaleStatusBarCheck:SetPoint("TOPLEFT", objectiveTrackerCheck, "BOTTOMLEFT", 0, -4)
    local scaleStatusBarText = _G[scaleStatusBarCheck:GetName() .. "Text"]
    scaleStatusBarText:SetText("Scale Status Bar (0.7)")
    scaleStatusBarText:SetTextColor(1, 1, 1)
    scaleStatusBarCheck:SetChecked(MattActionBarFontDB.scaleStatusBar)
    scaleStatusBarCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleStatusBar = self:GetChecked()
        MABF:ApplyStatusBarScale()
    end)

    local scaleTalkingHeadCheck = CreateFrame("CheckButton", "MABFScaleTalkingHeadCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    scaleTalkingHeadCheck:ClearAllPoints()
    scaleTalkingHeadCheck:SetPoint("TOPLEFT", scaleStatusBarCheck, "BOTTOMLEFT", 0, -4)
    local scaleTalkingHeadText = _G[scaleTalkingHeadCheck:GetName() .. "Text"]
    scaleTalkingHeadText:SetText("Scale Talking Head (0.7)")
    scaleTalkingHeadText:SetTextColor(1, 1, 1)
    scaleTalkingHeadCheck:SetChecked(MattActionBarFontDB.scaleTalkingHead)
    scaleTalkingHeadCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.scaleTalkingHead = self:GetChecked()
        MABF:ApplyScaleTalkingHead()
    end)

    local hideMicroMenuCheck = CreateFrame("CheckButton", "MABFHideMicroMenuCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideMicroMenuCheck:ClearAllPoints()
    hideMicroMenuCheck:SetPoint("TOPLEFT", scaleTalkingHeadCheck, "BOTTOMLEFT", 0, -4)
    local hideMicroMenuText = _G[hideMicroMenuCheck:GetName() .. "Text"]
    hideMicroMenuText:SetText("Hide Micro Menu")
    hideMicroMenuText:SetTextColor(1, 1, 1)
    local hideMicroDesc = pageUIFeatures:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    hideMicroDesc:SetPoint("TOPLEFT", hideMicroMenuCheck, "BOTTOMLEFT", 26, 2)
    hideMicroDesc:SetText("|cff888888Keeps Dungeon Finder & Housing|r")
    hideMicroDesc:SetScale(0.85)
    hideMicroMenuCheck:SetChecked(MattActionBarFontDB.hideMicroMenu)
    hideMicroMenuCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideMicroMenu = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    local hideBagBarCheck = CreateFrame("CheckButton", "MABFHideBagBarCheck", pageUIFeatures, "InterfaceOptionsCheckButtonTemplate")
    hideBagBarCheck:ClearAllPoints()
    hideBagBarCheck:SetPoint("TOPLEFT", hideMicroMenuCheck, "BOTTOMLEFT", 0, -4)
    local hideBagBarText = _G[hideBagBarCheck:GetName() .. "Text"]
    hideBagBarText:SetText("Hide Bag Bar")
    hideBagBarText:SetTextColor(1, 1, 1)
    hideBagBarCheck:SetChecked(MattActionBarFontDB.hideBagBar)
    hideBagBarCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.hideBagBar = self:GetChecked()
        StaticPopup_Show("MABF_RELOAD_UI")
    end)

    return {
        objectiveTrackerCheck = objectiveTrackerCheck,
        scaleStatusBarCheck = scaleStatusBarCheck,
        scaleTalkingHeadCheck = scaleTalkingHeadCheck,
        hideMicroMenuCheck = hideMicroMenuCheck,
        hideMicroDesc = hideMicroDesc,
        hideBagBarCheck = hideBagBarCheck,
    }
end
