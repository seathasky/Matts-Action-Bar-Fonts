local addonName, MABF = ...

-- Builds the UI / QoL > Bags options page UI.
function MABF:BuildBagTweaksPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageBags = opts.pageBags
    local CreatePageTitle = opts.CreatePageTitle

    if not pageBags or not CreatePageTitle then
        return nil
    end

    local bagsTitle = CreatePageTitle(pageBags, "Bag Tweaks")

    local bagIlvlCheck = CreateFrame("CheckButton", "MABFBagIlvlCheck", pageBags, "InterfaceOptionsCheckButtonTemplate")
    bagIlvlCheck:ClearAllPoints()
    bagIlvlCheck:SetPoint("TOPLEFT", bagsTitle, "BOTTOMLEFT", 0, -8)
    local bagIlvlText = _G[bagIlvlCheck:GetName() .. "Text"]
    bagIlvlText:SetText("Show Item Levels in Bags")
    bagIlvlText:SetTextColor(1, 1, 1)
    local bagIlvlDesc = pageBags:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bagIlvlDesc:SetPoint("TOPLEFT", bagIlvlCheck, "BOTTOMLEFT", 26, 2)
    bagIlvlDesc:SetText("|cff888888Displays ilvl on gear in bags & bank|r")
    bagIlvlDesc:SetScale(0.85)
    bagIlvlCheck:SetChecked(MattActionBarFontDB.enableBagItemLevels)
    bagIlvlCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableBagItemLevels = self:GetChecked()
        if MattActionBarFontDB.enableBagItemLevels then
            MABF:EnableBagItemLevels()
        else
            MABF:DisableBagItemLevels()
        end
    end)

    return {
        page = pageBags,
        bagIlvlCheck = bagIlvlCheck,
    }
end
