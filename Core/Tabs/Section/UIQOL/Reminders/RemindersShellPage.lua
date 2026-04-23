local addonName, MABF = ...

-- Builds the UI / QoL > Reminders shell wiring:
-- title/hint, sub-tab shell, sub-page builders, and initial refresh/show calls.
function MABF:BuildRemindersShellPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageReminders = opts.pageReminders
    local CreatePageTitle = opts.CreatePageTitle
    local checkSpacing = opts.checkSpacing
    local StyleSlider = opts.StyleSlider

    if not pageReminders or not CreatePageTitle or not checkSpacing or not StyleSlider then
        return nil
    end

    local remindersTitle = CreatePageTitle(pageReminders, "Reminders")

    local remindersShell = MABF:BuildRemindersSubTabs({
        pageReminders = pageReminders,
        remindersTitle = remindersTitle,
    })
    local remindersSubTabContainer = remindersShell and remindersShell.subTabContainer
    local remindersPages = remindersShell and remindersShell.pages or {}
    local ShowReminderSubPage = remindersShell and remindersShell.showSubPage or function() end

    local remindersLockButton = CreateFrame("Button", "MABFRemindersClickthroughLockButton", pageReminders, "BackdropTemplate")
    if remindersSubTabContainer then
        remindersLockButton:SetPoint("TOPLEFT", remindersSubTabContainer, "BOTTOMLEFT", 0, -8)
    else
        remindersLockButton:SetPoint("TOPLEFT", remindersTitle, "BOTTOMLEFT", 0, -34)
    end
    remindersLockButton:SetSize(146, 20)
    remindersLockButton:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    local remindersLockButtonText = remindersLockButton:CreateFontString(nil, "OVERLAY")
    remindersLockButtonText:SetPoint("CENTER", remindersLockButton, "CENTER", 0, 0)
    remindersLockButtonText:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 11, "OUTLINE")

    local remindersHeaderDivider = pageReminders:CreateTexture(nil, "ARTWORK")
    remindersHeaderDivider:SetColorTexture(1, 1, 1, 0.12)
    remindersHeaderDivider:SetPoint("TOPLEFT", remindersLockButton, "BOTTOMLEFT", 0, -2)
    remindersHeaderDivider:SetPoint("TOPRIGHT", pageReminders, "TOPRIGHT", -18, -2)
    remindersHeaderDivider:SetHeight(1)

    local remindersMoveHint = pageReminders:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    remindersMoveHint:SetPoint("TOPLEFT", remindersHeaderDivider, "BOTTOMLEFT", 0, -4)
    remindersMoveHint:SetPoint("RIGHT", pageReminders, "RIGHT", -18, 0)
    remindersMoveHint:SetJustifyH("LEFT")
    remindersMoveHint:SetWordWrap(true)
    remindersMoveHint:SetScale(0.9)

    local function IsRemindersLockEnabled()
        return MattActionBarFontDB and MattActionBarFontDB.remindersClickthroughLock and true or false
    end

    local function RefreshRemindersLockButton()
        if IsRemindersLockEnabled() then
            remindersLockButtonText:SetText("Locked")
            remindersLockButtonText:SetTextColor(0.35, 1.0, 0.35, 1)
            remindersLockButton:SetBackdropColor(0.08, 0.1, 0.08, 1)
            remindersLockButton:SetBackdropBorderColor(0.35, 1.0, 0.35, 0.85)
        else
            remindersLockButtonText:SetText("Unlocked")
            remindersLockButtonText:SetTextColor(1.0, 0.35, 0.35, 1)
            remindersLockButton:SetBackdropColor(0.1, 0.08, 0.08, 1)
            remindersLockButton:SetBackdropBorderColor(1.0, 0.35, 0.35, 0.85)
        end
    end

    local function RefreshRemindersMoveHint()
        if IsRemindersLockEnabled() then
            remindersMoveHint:SetText("|cff55ff55Locked:|r |cff888888reminders are now click-through.|r")
        else
            remindersMoveHint:SetText("|cffff5555Unlocked:|r |cff888888Shift+Left-Drag to move reminders.|r")
        end
    end
    RefreshRemindersLockButton()
    RefreshRemindersMoveHint()

    remindersLockButton:SetScript("OnClick", function()
        MattActionBarFontDB.remindersClickthroughLock = not IsRemindersLockEnabled()
        RefreshRemindersLockButton()
        RefreshRemindersMoveHint()
        if MABF and MABF.ApplyRemindersClickthroughLock then
            MABF:ApplyRemindersClickthroughLock()
        end
    end)

    local function CreateReminderResetButton(name, parent, onClick)
        return MABF:CreateReminderResetButton(name, parent, onClick)
    end

    local function CreateReminderResetSizeButton(name, parent, onClick)
        return MABF:CreateReminderResetSizeButton(name, parent, onClick)
    end

    local petsPage = MABF:BuildRemindersPetsPage({
        page = remindersPages.pets,
        checkSpacing = checkSpacing,
        StyleSlider = StyleSlider,
        CreateReminderResetButton = CreateReminderResetButton,
        CreateReminderResetSizeButton = CreateReminderResetSizeButton,
    })

    local consumablesPage = MABF:BuildRemindersConsumablesPage({
        page = remindersPages.consumables,
        checkSpacing = checkSpacing,
        StyleSlider = StyleSlider,
        CreateReminderResetButton = CreateReminderResetButton,
        CreateReminderResetSizeButton = CreateReminderResetSizeButton,
    })

    local buffsPage = MABF:BuildRemindersBuffsPage({
        page = remindersPages.buffs,
        checkSpacing = checkSpacing,
        StyleSlider = StyleSlider,
        CreateReminderResetButton = CreateReminderResetButton,
        CreateReminderResetSizeButton = CreateReminderResetSizeButton,
    })

    local classPage = MABF:BuildRemindersClassPage({
        page = remindersPages.classstuff,
        checkSpacing = checkSpacing,
        StyleSlider = StyleSlider,
        CreateReminderResetButton = CreateReminderResetButton,
        CreateReminderResetSizeButton = CreateReminderResetSizeButton,
    })

    local RefreshMissingPetSubOptions = petsPage and petsPage.RefreshMissingPetSubOptions
    local RefreshPetReminderScaleControl = petsPage and petsPage.RefreshPetReminderScaleControl
    local RefreshConsumableSubOptions = consumablesPage and consumablesPage.RefreshConsumableSubOptions
    local RefreshBuffSubOptions = buffsPage and buffsPage.RefreshBuffSubOptions
    local RefreshBuffReminderScaleControl = buffsPage and buffsPage.RefreshBuffReminderScaleControl
    local RefreshClassStuffSubOptions = classPage and classPage.RefreshClassStuffSubOptions
    local RefreshClassStuffSubRules = classPage and classPage.RefreshClassStuffSubRules
    local RefreshClassStuffScaleControl = classPage and classPage.RefreshClassStuffScaleControl

    if RefreshMissingPetSubOptions then RefreshMissingPetSubOptions() end
    if RefreshPetReminderScaleControl then RefreshPetReminderScaleControl() end
    if RefreshConsumableSubOptions then RefreshConsumableSubOptions() end
    if RefreshBuffSubOptions then RefreshBuffSubOptions() end
    if RefreshBuffReminderScaleControl then RefreshBuffReminderScaleControl() end
    if RefreshClassStuffSubOptions then RefreshClassStuffSubOptions() end
    if RefreshClassStuffSubRules then RefreshClassStuffSubRules() end
    if RefreshClassStuffScaleControl then RefreshClassStuffScaleControl() end
    ShowReminderSubPage("consumables")

    return {
        remindersTitle = remindersTitle,
        remindersLockButton = remindersLockButton,
        remindersMoveHint = remindersMoveHint,
        remindersPages = remindersPages,

        warnMissingPetCheck = petsPage and petsPage.warnMissingPetCheck,
        warnPetPassiveCheck = petsPage and petsPage.warnPetPassiveCheck,
        warnPetPassiveResetBtn = petsPage and petsPage.warnPetPassiveResetBtn,
        warnPetPassiveResetSizeBtn = petsPage and petsPage.warnPetPassiveResetSizeBtn,

        trackConsumablesCheck = consumablesPage and consumablesPage.trackConsumablesCheck,
        trackConsumablesText = consumablesPage and consumablesPage.trackConsumablesText,
        trackConsumablesResetBtn = consumablesPage and consumablesPage.trackConsumablesResetBtn,
        trackConsumablesResetSizeBtn = consumablesPage and consumablesPage.trackConsumablesResetSizeBtn,
        consumablesOnlyInstanceCheck = consumablesPage and consumablesPage.consumablesOnlyInstanceCheck,
        consumablesHideInRestAreaCheck = consumablesPage and consumablesPage.consumablesHideInRestAreaCheck,
        consumablesHideWhileMountedCheck = consumablesPage and consumablesPage.consumablesHideWhileMountedCheck,
        consumablesSuppressInMPlusCheck = consumablesPage and consumablesPage.consumablesSuppressInMPlusCheck,
        consumablesSuppressAfterFirstPullCheck = consumablesPage and consumablesPage.consumablesSuppressAfterFirstPullCheck,
        consumablesHideWhenLFGCompleteCheck = consumablesPage and consumablesPage.consumablesHideWhenLFGCompleteCheck,
        consumablesHealthstoneCheck = consumablesPage and consumablesPage.consumablesHealthstoneCheck,

        warnMissingClassBuffsCheck = buffsPage and buffsPage.warnMissingClassBuffsCheck,
        warnMissingClassBuffsText = buffsPage and buffsPage.warnMissingClassBuffsText,
        warnMissingClassBuffsResetBtn = buffsPage and buffsPage.warnMissingClassBuffsResetBtn,
        warnMissingClassBuffsResetSizeBtn = buffsPage and buffsPage.warnMissingClassBuffsResetSizeBtn,
        buffsOnlyInInstanceCheck = buffsPage and buffsPage.buffsOnlyInInstanceCheck,
        buffsHideInRestAreaCheck = buffsPage and buffsPage.buffsHideInRestAreaCheck,
        buffsHideWhileMountedCheck = buffsPage and buffsPage.buffsHideWhileMountedCheck,
        buffsSuppressInMPlusCheck = buffsPage and buffsPage.buffsSuppressInMPlusCheck,
        buffsSuppressAfterFirstPullCheck = buffsPage and buffsPage.buffsSuppressAfterFirstPullCheck,
        buffsHideWhenLFGCompleteCheck = buffsPage and buffsPage.buffsHideWhenLFGCompleteCheck,

        warnClassSoulstoneCheck = classPage and classPage.warnClassSoulstoneCheck,
        warnClassShamanShieldsCheck = classPage and classPage.warnClassShamanShieldsCheck,
        warnClassPaladinBeaconsCheck = classPage and classPage.warnClassPaladinBeaconsCheck,
        warnClassStuffResetBtn = classPage and classPage.warnClassStuffResetBtn,
        warnClassStuffResetSizeBtn = classPage and classPage.warnClassStuffResetSizeBtn,
        classOnlyInInstanceCheck = classPage and classPage.classOnlyInInstanceCheck,
        classHideInRestAreaCheck = classPage and classPage.classHideInRestAreaCheck,
        classHideWhileMountedCheck = classPage and classPage.classHideWhileMountedCheck,
        classSuppressInMPlusCheck = classPage and classPage.classSuppressInMPlusCheck,
        classSuppressAfterFirstPullCheck = classPage and classPage.classSuppressAfterFirstPullCheck,
        classHideWhenLFGCompleteCheck = classPage and classPage.classHideWhenLFGCompleteCheck,

        -- These are named checkbuttons created in PetsPage and used by option styling pass.
        petMissingOnlyInstanceCheck = _G.MABFPetMissingOnlyInstanceCheck,
        petMissingHideInRestAreaCheck = _G.MABFPetMissingHideInRestAreaCheck,
        petHideWhileMountedCheck = petsPage and petsPage.petHideWhileMountedCheck,
        petMissingSuppressInMPlusCheck = _G.MABFPetMissingSuppressInMPlusCheck,
        petMissingSuppressAfterFirstPullCheck = _G.MABFPetMissingSuppressAfterFirstPullCheck,
        petMissingHideWhenLFGCompleteCheck = _G.MABFPetMissingHideWhenLFGCompleteCheck,
        warnMissingPetText = _G.MABFWarnMissingPetCheckText,
    }
end
