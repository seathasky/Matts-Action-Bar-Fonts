local addonName, MABF = ...

-- Builds the UI / QoL > Merchant options page UI.
function MABF:BuildMerchantTweaksPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageMerchant = opts.pageMerchant
    local CreatePageTitle = opts.CreatePageTitle
    local StyleMinimalRadio = opts.StyleMinimalRadio

    if not pageMerchant or not CreatePageTitle or not StyleMinimalRadio then
        return nil
    end

    local layout = (MABF.GetOptionsLayoutMetrics and MABF:GetOptionsLayoutMetrics()) or {
        rowGapTight = -4,
        rowGap = -8,
        descTextOffsetX = 26,
    }

    local merchantTitle = CreatePageTitle(pageMerchant, "Merchant Tweaks")

    local autoRepairCheck = CreateFrame("CheckButton", "MABFAutoRepairCheck", pageMerchant, "InterfaceOptionsCheckButtonTemplate")
    autoRepairCheck:ClearAllPoints()
    autoRepairCheck:SetPoint("TOPLEFT", merchantTitle, "BOTTOMLEFT", 0, -8)
    local autoRepairText = _G[autoRepairCheck:GetName() .. "Text"]
    autoRepairText:SetText("Auto Repair")
    autoRepairText:SetTextColor(1, 1, 1)
    local autoRepairDesc = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoRepairDesc:SetPoint("TOPLEFT", autoRepairCheck, "BOTTOMLEFT", layout.descTextOffsetX, 2)
    autoRepairDesc:SetText("|cff888888Automatically repairs gear at merchants|r")
    autoRepairDesc:SetScale(0.85)
    autoRepairCheck:SetChecked(MattActionBarFontDB.enableAutoRepair)
    autoRepairCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableAutoRepair = self:GetChecked()
        MABF:SetupMerchantTweaks()
    end)

    local fundingLabel = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    fundingLabel:SetPoint("TOPLEFT", autoRepairDesc, "BOTTOMLEFT", 0, layout.rowGapTight)
    fundingLabel:SetText("Repair Funding:")
    fundingLabel:SetTextColor(0.9, 0.9, 0.9)
    fundingLabel:SetFont("Fonts\\FRIZQT__.TTF", 9)

    local fundingGuild = CreateFrame("CheckButton", "MABFFundingGuild", pageMerchant, "UIRadioButtonTemplate")
    fundingGuild:SetSize(14, 14)
    fundingGuild:SetPoint("TOPLEFT", fundingLabel, "BOTTOMLEFT", 0, layout.rowGapTight)
    local fundingGuildText = fundingGuild:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fundingGuildText:SetPoint("LEFT", fundingGuild, "RIGHT", 2, 0)
    fundingGuildText:SetText("|cffffffffGuild first, then personal|r")
    fundingGuildText:SetFont("Fonts\\FRIZQT__.TTF", 9)

    local fundingPlayer = CreateFrame("CheckButton", "MABFFundingPlayer", pageMerchant, "UIRadioButtonTemplate")
    fundingPlayer:SetSize(14, 14)
    fundingPlayer:SetPoint("TOPLEFT", fundingGuild, "BOTTOMLEFT", 0, layout.rowGap)
    local fundingPlayerText = fundingPlayer:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    fundingPlayerText:SetPoint("LEFT", fundingPlayer, "RIGHT", 2, 0)
    fundingPlayerText:SetText("|cffffffffPersonal only|r")
    fundingPlayerText:SetFont("Fonts\\FRIZQT__.TTF", 9)

    StyleMinimalRadio(fundingGuild, fundingGuildText)
    StyleMinimalRadio(fundingPlayer, fundingPlayerText)

    local function UpdateFundingRadios()
        local src = MattActionBarFontDB.autoRepairFundingSource or "GUILD"
        fundingGuild:SetChecked(src == "GUILD")
        fundingPlayer:SetChecked(src == "PLAYER")
        if fundingGuild._mabfRefreshMark then fundingGuild._mabfRefreshMark() end
        if fundingPlayer._mabfRefreshMark then fundingPlayer._mabfRefreshMark() end
    end
    UpdateFundingRadios()

    fundingGuild:SetScript("OnClick", function()
        MattActionBarFontDB.autoRepairFundingSource = "GUILD"
        UpdateFundingRadios()
    end)
    fundingPlayer:SetScript("OnClick", function()
        MattActionBarFontDB.autoRepairFundingSource = "PLAYER"
        UpdateFundingRadios()
    end)

    local autoSellCheck = CreateFrame("CheckButton", "MABFAutoSellJunkCheck", pageMerchant, "InterfaceOptionsCheckButtonTemplate")
    autoSellCheck:ClearAllPoints()
    autoSellCheck:SetPoint("TOPLEFT", fundingPlayer, "BOTTOMLEFT", 0, layout.rowGap)
    local autoSellText = _G[autoSellCheck:GetName() .. "Text"]
    autoSellText:SetText("Auto Sell Junk")
    autoSellText:SetTextColor(1, 1, 1)
    local autoSellDesc = pageMerchant:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    autoSellDesc:SetPoint("TOPLEFT", autoSellCheck, "BOTTOMLEFT", layout.descTextOffsetX, 2)
    autoSellDesc:SetText("|cff888888Sells grey items when visiting a vendor|r")
    autoSellDesc:SetScale(0.85)
    autoSellCheck:SetChecked(MattActionBarFontDB.enableAutoSellJunk)
    autoSellCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableAutoSellJunk = self:GetChecked()
        MABF:SetupMerchantTweaks()
    end)

    return {
        page = pageMerchant,
        autoRepairCheck = autoRepairCheck,
        autoSellCheck = autoSellCheck,
    }
end
