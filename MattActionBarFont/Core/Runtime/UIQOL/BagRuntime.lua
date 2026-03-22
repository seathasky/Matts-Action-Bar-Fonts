local addonName, MABF = ...

-----------------------------------------------------------
-- Bag Overlays (Item Levels + Equipment Set Labels)
-----------------------------------------------------------
do
    local _SCANNER = "MABF_ScannerTooltip"
    local Scanner = _G[_SCANNER] or CreateFrame("GameTooltip", _SCANNER, WorldFrame, "GameTooltipTemplate")
    local S_ILVL = "^" .. string.gsub(ITEM_LEVEL, "%%d", "(%%d+)")
    local S_SLOTS = "^" .. (string.gsub(string.gsub(CONTAINER_SLOTS, "%%([%d%$]-)d", "(%%d+)"), "%%([%d%$]-)s", "%.+"))
    local Cache = {}
    local colors = {
        [0] = {157/255,157/255,157/255}, [1] = {240/255,240/255,240/255},
        [2] = {30/255,178/255,0/255}, [3] = {0/255,112/255,221/255},
        [4] = {163/255,53/255,238/255}, [5] = {225/255,96/255,0/255},
        [6] = {229/255,204/255,127/255}, [7] = {79/255,196/255,225/255},
        [8] = {79/255,196/255,225/255},
    }
    local C_Container_GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
    local C_Container_GetContainerItemEquipmentSetInfo = C_Container and C_Container.GetContainerItemEquipmentSetInfo
    local C_TooltipInfo = C_TooltipInfo
    local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local hooksApplied = false
    local strtrim = strtrim

    local function ClearItemLevelText(button)
        local cache = Cache[button]
        if cache and cache.ilvl then cache.ilvl:SetText("") end
        if cache and cache.setLabel then cache.setLabel:SetText("") end
        local upgrade = button.UpgradeIcon
        if upgrade and upgrade.mabfMoved then
            upgrade:ClearAllPoints()
            upgrade:SetPoint("TOPLEFT", 0, 0)
            upgrade.mabfMoved = nil
        end
    end

    local function IsAnyBagOverlayEnabled()
        return MattActionBarFontDB
            and (MattActionBarFontDB.enableBagItemLevels or MattActionBarFontDB.enableBagEquipmentLabels)
    end

    local function ClearAllVisible()
        for i = 1, NUM_CONTAINER_FRAMES do
            local frame = _G["ContainerFrame"..i]
            if frame and frame:IsShown() then
                local name = frame:GetName()
                local id = 1
                local button = _G[name.."Item"..id]
                while button do ClearItemLevelText(button); id = id + 1; button = _G[name.."Item"..id] end
            end
        end
        if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
            if _G.ContainerFrameCombinedBags.EnumerateValidItems then
                for _,button in _G.ContainerFrameCombinedBags:EnumerateValidItems() do ClearItemLevelText(button) end
            elseif _G.ContainerFrameCombinedBags.Items then
                for _,button in ipairs(_G.ContainerFrameCombinedBags.Items) do ClearItemLevelText(button) end
            end
        end
        if _G.BankFrame and _G.BankFrame:IsShown() then
            if _G.BankSlotsFrame and NUM_BANKGENERIC_SLOTS then
                for id = 1, NUM_BANKGENERIC_SLOTS do
                    local button = _G.BankSlotsFrame["Item"..id]
                    if button and not button.isBag then ClearItemLevelText(button) end
                end
            elseif _G.BankFrame.BankPanel and _G.BankFrame.BankPanel.EnumerateValidItems then
                for button in _G.BankFrame.BankPanel:EnumerateValidItems() do ClearItemLevelText(button) end
            end
        end
    end

    local function GetPrimarySetLabel(setList)
        -- Keep labels compact on bag buttons: "Frost+" means item is in Frost and at least one other set.
        if type(setList) ~= "string" or setList == "" then return nil end
        local firstName = string.match(setList, "([^,]+)")
        if not firstName then return nil end
        if strtrim then firstName = strtrim(firstName) end
        if firstName == "" then return nil end
        if string.find(setList, ",", 1, true) then
            return firstName .. "+"
        end
        return firstName
    end

    local function UpdateButton(button, bag, slot)
        if not IsAnyBagOverlayEnabled() then
            ClearItemLevelText(button); return
        end
        local message, rarity, itemLink, setLabel
        local r, g, b = 240/255, 240/255, 240/255
        if C_Container_GetContainerItemInfo then
            local ci = C_Container_GetContainerItemInfo(bag, slot)
            if ci then itemLink = ci.hyperlink end
        else
            local _, _, _, _, _, _, il = GetContainerItemInfo(bag, slot)
            itemLink = il
        end
        if itemLink and MattActionBarFontDB.enableBagItemLevels then
            local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
            if itemEquipLoc == "INVTYPE_BAG" then
                if C_TooltipInfo then
                    local td = C_TooltipInfo.GetBagItem(bag, slot)
                    if td and td.lines then
                        for i = 3,4 do
                            local msg = td.lines[i] and td.lines[i].leftText
                            if not msg then break end
                            local ns = string.match(msg, S_SLOTS)
                            if ns then ns = tonumber(ns); if ns and ns > 0 then message = ns end; break end
                        end
                    end
                end
            elseif itemQuality and itemQuality > 0 and itemEquipLoc and _G[itemEquipLoc]
                and itemEquipLoc ~= "INVTYPE_NON_EQUIP" and itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE"
                and itemEquipLoc ~= "INVTYPE_TABARD" and itemEquipLoc ~= "INVTYPE_AMMO" and itemEquipLoc ~= "INVTYPE_QUIVER" then
                local tipLevel
                if C_TooltipInfo then
                    local td = C_TooltipInfo.GetBagItem(bag, slot)
                    if td and td.lines then
                        for i = 2,3 do
                            local msg = td.lines[i] and td.lines[i].leftText
                            if not msg then break end
                            local il = string.match(msg, S_ILVL)
                            if il then il = tonumber(il); if il and il > 0 then tipLevel = il end; break end
                        end
                    end
                end
                tipLevel = tonumber(tipLevel or GetDetailedItemLevelInfo(itemLink) or itemLevel)
                if tipLevel and tipLevel > 1 then message = tipLevel; rarity = itemQuality end
            end
        end

        if MattActionBarFontDB.enableBagEquipmentLabels and C_Container_GetContainerItemEquipmentSetInfo then
            local inSet, setList = C_Container_GetContainerItemEquipmentSetInfo(bag, slot)
            if inSet and setList then
                setLabel = GetPrimarySetLabel(setList)
            end
        end

        local hasILevel = message and message > 1
        local hasSetLabel = setLabel and setLabel ~= ""
        if hasILevel or hasSetLabel then
            local container = Cache[button]
            if not container then
                container = CreateFrame("Frame", nil, button)
                container:SetFrameLevel(button:GetFrameLevel() + 5)
                container:SetAllPoints()
                Cache[button] = container
            end

            if hasILevel then
                if not container.ilvl then
                    container.ilvl = container:CreateFontString(nil, "OVERLAY")
                    container.ilvl:SetDrawLayer("ARTWORK", 1)
                    container.ilvl:SetPoint("TOPLEFT", 2, -2)
                    container.ilvl:SetFontObject(NumberFont_Outline_Med or NumberFontNormal)
                    container.ilvl:SetShadowOffset(1, -1)
                    container.ilvl:SetShadowColor(0, 0, 0, .5)
                end
                local upgrade = button.UpgradeIcon
                if upgrade and not upgrade.mabfMoved then
                    upgrade:ClearAllPoints()
                    upgrade:SetPoint("BOTTOMRIGHT", 2, 0)
                    upgrade.mabfMoved = true
                end
                if rarity and colors[rarity] then
                    local col = colors[rarity]; r, g, b = col[1], col[2], col[3]
                end
                container.ilvl:SetTextColor(r, g, b)
                container.ilvl:SetText(message)
            elseif container.ilvl then
                container.ilvl:SetText("")
                local upgrade = button.UpgradeIcon
                if upgrade and upgrade.mabfMoved then
                    upgrade:ClearAllPoints()
                    upgrade:SetPoint("TOPLEFT", 0, 0)
                    upgrade.mabfMoved = nil
                end
            end

            if hasSetLabel then
                if not container.setLabel then
                    container.setLabel = container:CreateFontString(nil, "OVERLAY")
                    container.setLabel:SetDrawLayer("ARTWORK", 1)
                    container.setLabel:SetPoint("BOTTOMLEFT", 2, 2)
                    container.setLabel:SetFontObject(NumberFontNormalSmall or NumberFontNormal)
                    container.setLabel:SetJustifyH("LEFT")
                    container.setLabel:SetShadowOffset(1, -1)
                    container.setLabel:SetShadowColor(0, 0, 0, .5)
                    container.setLabel:SetMaxLines(1)
                    container.setLabel:SetWordWrap(false)
                end
                container.setLabel:SetWidth((button:GetWidth() or 36) - 4)
                container.setLabel:SetTextColor(110/255, 1, 110/255)
                container.setLabel:SetText(setLabel)
            elseif container.setLabel then
                container.setLabel:SetText("")
            end
        else
            ClearItemLevelText(button)
        end
    end

    local function UpdateContainer(frame)
        local bag = frame:GetID()
        local name = frame:GetName()
        local id = 1
        local button = _G[name.."Item"..id]
        if not IsAnyBagOverlayEnabled() then
            while button do
                ClearItemLevelText(button)
                id = id + 1
                button = _G[name.."Item"..id]
            end
            return
        end
        while button do
            if button.hasItem then UpdateButton(button, bag, button:GetID()) else ClearItemLevelText(button) end
            id = id + 1; button = _G[name.."Item"..id]
        end
    end

    local function UpdateCombinedContainer(frame)
        if not IsAnyBagOverlayEnabled() then
            if frame.EnumerateValidItems then
                for _,button in frame:EnumerateValidItems() do
                    ClearItemLevelText(button)
                end
            elseif frame.Items then
                for _,button in ipairs(frame.Items) do
                    ClearItemLevelText(button)
                end
            end
            return
        end
        if frame.EnumerateValidItems then
            for _,button in frame:EnumerateValidItems() do
                if button.hasItem then UpdateButton(button, button:GetBagID(), button:GetID()) else ClearItemLevelText(button) end
            end
        elseif frame.Items then
            for _,button in ipairs(frame.Items) do
                if button.hasItem then UpdateButton(button, button:GetBagID(), button:GetID()) else ClearItemLevelText(button) end
            end
        end
    end

    local function UpdateBank()
        if _G.BankSlotsFrame and NUM_BANKGENERIC_SLOTS then
            local bag = _G.BankSlotsFrame:GetID()
            for id = 1, NUM_BANKGENERIC_SLOTS do
                local button = _G.BankSlotsFrame["Item"..id]
                if button and not button.isBag then
                    if not IsAnyBagOverlayEnabled() then
                        ClearItemLevelText(button)
                    elseif button.hasItem then
                        UpdateButton(button, bag, button:GetID())
                    else
                        ClearItemLevelText(button)
                    end
                end
            end
        elseif _G.BankFrame and _G.BankFrame.BankPanel and _G.BankFrame.BankPanel.EnumerateValidItems then
            for button in _G.BankFrame.BankPanel:EnumerateValidItems() do
                local bankTabID = button:GetBankTabID()
                local slotID = button:GetContainerSlotID()
                local info = C_Container_GetContainerItemInfo and C_Container_GetContainerItemInfo(bankTabID, slotID)
                if not IsAnyBagOverlayEnabled() then
                    ClearItemLevelText(button)
                elseif info then
                    UpdateButton(button, bankTabID, slotID)
                else
                    ClearItemLevelText(button)
                end
            end
        end
    end

    local function UpdateAllVisible()
        for i = 1, NUM_CONTAINER_FRAMES do
            local frame = _G["ContainerFrame"..i]
            if frame and frame:IsShown() then UpdateContainer(frame) end
        end
        if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
            UpdateCombinedContainer(_G.ContainerFrameCombinedBags)
        end
        if _G.BankFrame and _G.BankFrame:IsShown() then UpdateBank() end
    end

    local bagEventFrame = CreateFrame("Frame")

    function MABF:EnableBagItemLevels()
        if not hooksApplied then
            if _G.ContainerFrame_Update then
                hooksecurefunc("ContainerFrame_Update", UpdateContainer)
            else
                local id = 1
                local frame = _G["ContainerFrame"..id]
                while frame and frame.Update do
                    hooksecurefunc(frame, "Update", UpdateContainer)
                    id = id + 1; frame = _G["ContainerFrame"..id]
                end
            end
            if _G.ContainerFrameCombinedBags then
                hooksecurefunc(_G.ContainerFrameCombinedBags, "Update", UpdateCombinedContainer)
            end
            if _G.BankFrame_UpdateItems then
                hooksecurefunc("BankFrame_UpdateItems", UpdateBank)
            elseif _G.BankFrameItemButton_UpdateLocked then
                hooksecurefunc("BankFrameItemButton_UpdateLocked", function(button)
                    if not IsAnyBagOverlayEnabled() then ClearItemLevelText(button); return end
                    if button and not button.isBag and _G.BankSlotsFrame then
                        UpdateButton(button, _G.BankSlotsFrame:GetID(), button:GetID())
                    else ClearItemLevelText(button) end
                end)
            end
            if BankPanelItemButtonMixin and BankPanelItemButtonMixin.Refresh then
                hooksecurefunc(BankPanelItemButtonMixin, "Refresh", function(button)
                    if not IsAnyBagOverlayEnabled() then ClearItemLevelText(button); return end
                    local bankTabID = button.GetBankTabID and button:GetBankTabID()
                    local slotID = button.GetContainerSlotID and button:GetContainerSlotID()
                    if bankTabID and slotID then UpdateButton(button, bankTabID, slotID) end
                end)
            end
            hooksApplied = true
        end
        bagEventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
        bagEventFrame:RegisterEvent("EQUIPMENT_SETS_CHANGED")
        bagEventFrame:SetScript("OnEvent", function(_, event, slot)
            if not IsAnyBagOverlayEnabled() then return end
            if event == "EQUIPMENT_SETS_CHANGED" then
                UpdateAllVisible()
                return
            end
            if NUM_BANKGENERIC_SLOTS and slot and slot <= NUM_BANKGENERIC_SLOTS and _G.BankSlotsFrame then
                local button = _G.BankSlotsFrame["Item"..slot]
                if button and not button.isBag then UpdateButton(button, _G.BankSlotsFrame:GetID(), button:GetID()) end
            elseif _G.BankFrame and _G.BankFrame:IsShown() then
                UpdateBank()
            end
        end)
        UpdateAllVisible()
    end

    function MABF:RefreshBagItemOverlays()
        if IsAnyBagOverlayEnabled() then
            MABF:EnableBagItemLevels()
        else
            MABF:DisableBagItemLevels()
        end
    end

    function MABF:DisableBagItemLevels()
        bagEventFrame:UnregisterAllEvents()
        bagEventFrame:SetScript("OnEvent", nil)
        ClearAllVisible()
    end
end
