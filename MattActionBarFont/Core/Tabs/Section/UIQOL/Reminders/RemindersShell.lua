local addonName, MABF = ...

-- Builds the Reminders sub-tab shell (Consumables / Pets / Buffs / Class)
-- and returns sub-page frames + page switch function.
function MABF:BuildRemindersSubTabs(opts)
    if type(opts) ~= "table" then return nil end

    local pageReminders = opts.pageReminders
    local remindersTitle = opts.remindersTitle

    if not pageReminders or not remindersTitle then
        return nil
    end

    local accent = (MABF.GetThemeAccentColor and MABF:GetThemeAccentColor()) or { 1.0, 0.25, 0.25 }

    local subTabContainer = CreateFrame("Frame", nil, pageReminders)
    subTabContainer:SetPoint("TOPLEFT", remindersTitle, "BOTTOMLEFT", 0, -8)
    subTabContainer:SetPoint("TOPRIGHT", pageReminders, "TOPRIGHT", -12, -30)
    subTabContainer:SetHeight(24)

    local function CreateReminderSubTab(name, label, anchor, xOff)
        local btn = CreateFrame("Button", name, subTabContainer, "BackdropTemplate")
        btn:SetSize(66, 20)
        if anchor then
            btn:SetPoint("LEFT", anchor, "RIGHT", 4, 0)
        else
            btn:SetPoint("LEFT", subTabContainer, "LEFT", xOff or 0, 0)
        end
        btn:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
            insets = { left = 0, right = 0, top = 0, bottom = 0 },
        })
        btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
        btn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        local fs = btn:CreateFontString(nil, "OVERLAY")
        fs:SetPoint("CENTER", btn, "CENTER", 0, 0)
        fs:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 8, "OUTLINE")
        fs:SetText(label)
        fs:SetTextColor(0.85, 0.85, 0.85, 1)
        btn._mabfText = fs
        return btn
    end

    local remindersSubConsumablesBtn = CreateReminderSubTab("MABFRemindersSubConsumables", "Consumables", nil, 0)
    local remindersSubPetsBtn = CreateReminderSubTab("MABFRemindersSubPets", "Pets", remindersSubConsumablesBtn)
    local remindersSubBuffsBtn = CreateReminderSubTab("MABFRemindersSubBuffs", "Buffs", remindersSubPetsBtn)
    local remindersSubClassStuffBtn = CreateReminderSubTab("MABFRemindersSubClassStuff", "Class", remindersSubBuffsBtn)

    local remindersPages = {
        consumables = CreateFrame("Frame", nil, pageReminders),
        pets = CreateFrame("Frame", nil, pageReminders),
        buffs = CreateFrame("Frame", nil, pageReminders),
        classstuff = CreateFrame("Frame", nil, pageReminders),
    }
    for _, subPage in pairs(remindersPages) do
        -- Reserve vertical space under tabs for the global lock row + helper text.
        subPage:SetPoint("TOPLEFT", subTabContainer, "BOTTOMLEFT", 0, -62)
        subPage:SetPoint("BOTTOMRIGHT", pageReminders, "BOTTOMRIGHT", -8, 8)
    end

    local subTabButtons = {
        consumables = remindersSubConsumablesBtn,
        pets = remindersSubPetsBtn,
        buffs = remindersSubBuffsBtn,
        classstuff = remindersSubClassStuffBtn,
    }

    local function ShowReminderSubPage(key)
        for k, p in pairs(remindersPages) do
            p:SetShown(k == key)
        end
        for k, b in pairs(subTabButtons) do
            local active = (k == key)
            if active then
                b:SetBackdropColor(0.12, 0.12, 0.15, 1)
                b:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.85)
                if b._mabfText then b._mabfText:SetTextColor(1, 1, 1, 1) end
            else
                b:SetBackdropColor(0.06, 0.06, 0.08, 1)
                b:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
                if b._mabfText then b._mabfText:SetTextColor(0.85, 0.85, 0.85, 1) end
            end
        end
    end

    remindersSubConsumablesBtn:SetScript("OnClick", function() ShowReminderSubPage("consumables") end)
    remindersSubPetsBtn:SetScript("OnClick", function() ShowReminderSubPage("pets") end)
    remindersSubBuffsBtn:SetScript("OnClick", function() ShowReminderSubPage("buffs") end)
    remindersSubClassStuffBtn:SetScript("OnClick", function() ShowReminderSubPage("classstuff") end)

    return {
        pages = remindersPages,
        showSubPage = ShowReminderSubPage,
        subTabContainer = subTabContainer,
    }
end
