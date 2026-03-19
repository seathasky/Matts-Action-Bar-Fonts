local addonName, MABF = ...

local function RefreshBagOverlayRuntime()
    if MABF and MABF.RefreshBagItemOverlays then
        MABF:RefreshBagItemOverlays()
        return
    end

    if MattActionBarFontDB.enableBagItemLevels or MattActionBarFontDB.enableBagEquipmentLabels then
        MABF:EnableBagItemLevels()
    else
        MABF:DisableBagItemLevels()
    end
end

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
        RefreshBagOverlayRuntime()
    end)

    local bagEquipLabelCheck = CreateFrame("CheckButton", "MABFBagEquipmentLabelCheck", pageBags, "InterfaceOptionsCheckButtonTemplate")
    bagEquipLabelCheck:ClearAllPoints()
    bagEquipLabelCheck:SetPoint("TOPLEFT", bagIlvlDesc, "BOTTOMLEFT", -26, -10)
    local bagEquipLabelText = _G[bagEquipLabelCheck:GetName() .. "Text"]
    bagEquipLabelText:SetText("Show Equipment Set Labels in Bags")
    bagEquipLabelText:SetTextColor(1, 1, 1)
    local bagEquipLabelDesc = pageBags:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bagEquipLabelDesc:SetPoint("TOPLEFT", bagEquipLabelCheck, "BOTTOMLEFT", 26, 2)
    bagEquipLabelDesc:SetText("|cff888888Shows Equipment Manager set names on bag & bank gear|r")
    bagEquipLabelDesc:SetScale(0.85)
    bagEquipLabelCheck:SetChecked(MattActionBarFontDB.enableBagEquipmentLabels)
    bagEquipLabelCheck:SetScript("OnClick", function(self)
        MattActionBarFontDB.enableBagEquipmentLabels = self:GetChecked()
        RefreshBagOverlayRuntime()
    end)

    return {
        page = pageBags,
        bagIlvlCheck = bagIlvlCheck,
        bagEquipLabelCheck = bagEquipLabelCheck,
    }
end
