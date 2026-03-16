local addonName, MABF = ...

-- Builds the UI / QoL > Quests options page UI.
function MABF:BuildQuestTweaksPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageQuests = opts.pageQuests
    local CreatePageTitle = opts.CreatePageTitle

    if not pageQuests or not CreatePageTitle then
        return nil
    end

    local questsTitle = CreatePageTitle(pageQuests, "Quest Tweaks")

    local autoAcceptCheck = CreateFrame("CheckButton", "MABFAutoAcceptCheck", pageQuests, "InterfaceOptionsCheckButtonTemplate")
    autoAcceptCheck:ClearAllPoints()
    autoAcceptCheck:SetPoint("TOPLEFT", questsTitle, "BOTTOMLEFT", 0, -8)
    local autoAcceptText = _G[autoAcceptCheck:GetName() .. "Text"]
    autoAcceptText:SetText("Auto Accept Quests")
    autoAcceptText:SetTextColor(1, 1, 1)
    local autoAcceptDesc = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoAcceptDesc:SetPoint("TOPLEFT", autoAcceptCheck, "BOTTOMLEFT", 26, 2)
    autoAcceptDesc:SetText("|cff888888Hold Shift to skip|r")
    autoAcceptDesc:SetScale(0.85)
    autoAcceptCheck:SetChecked(MattActionBarFontDB.autoAcceptQuests)
    autoAcceptCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.autoAcceptQuests = self:GetChecked()
        MABF:SetupQuestTweaks()
    end)

    local autoTurnInCheck = CreateFrame("CheckButton", "MABFAutoTurnInCheck", pageQuests, "InterfaceOptionsCheckButtonTemplate")
    autoTurnInCheck:ClearAllPoints()
    autoTurnInCheck:SetPoint("TOPLEFT", autoAcceptCheck, "BOTTOMLEFT", 0, -4)
    local autoTurnInText = _G[autoTurnInCheck:GetName() .. "Text"]
    autoTurnInText:SetText("Auto Turn In Quests")
    autoTurnInText:SetTextColor(1, 1, 1)
    local autoTurnInDesc = pageQuests:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoTurnInDesc:SetPoint("TOPLEFT", autoTurnInCheck, "BOTTOMLEFT", 26, 2)
    autoTurnInDesc:SetText("|cff888888Skips quests with reward choices|r")
    autoTurnInDesc:SetScale(0.85)
    autoTurnInCheck:SetChecked(MattActionBarFontDB.autoTurnInQuests)
    autoTurnInCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.autoTurnInQuests = self:GetChecked()
        MABF:SetupQuestTweaks()
    end)

    return {
        page = pageQuests,
        autoAcceptCheck = autoAcceptCheck,
        autoTurnInCheck = autoTurnInCheck,
    }
end
