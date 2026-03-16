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
    local remindersMoveHint = pageReminders:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    remindersMoveHint:SetPoint("LEFT", remindersTitle, "RIGHT", 10, 0)
    remindersMoveHint:SetText("|cff888888Shift+Drag reminders to move|r")
    remindersMoveHint:SetScale(0.9)

    local remindersShell = MABF:BuildRemindersSubTabs({
        pageReminders = pageReminders,
        remindersTitle = remindersTitle,
    })
    local remindersPages = remindersShell and remindersShell.pages or {}
    local ShowReminderSubPage = remindersShell and remindersShell.showSubPage or function() end

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
        classSuppressInMPlusCheck = classPage and classPage.classSuppressInMPlusCheck,
        classSuppressAfterFirstPullCheck = classPage and classPage.classSuppressAfterFirstPullCheck,
        classHideWhenLFGCompleteCheck = classPage and classPage.classHideWhenLFGCompleteCheck,

        -- These are named checkbuttons created in PetsPage and used by option styling pass.
        petMissingOnlyInstanceCheck = _G.MABFPetMissingOnlyInstanceCheck,
        petMissingHideInRestAreaCheck = _G.MABFPetMissingHideInRestAreaCheck,
        petMissingSuppressInMPlusCheck = _G.MABFPetMissingSuppressInMPlusCheck,
        petMissingSuppressAfterFirstPullCheck = _G.MABFPetMissingSuppressAfterFirstPullCheck,
        petMissingHideWhenLFGCompleteCheck = _G.MABFPetMissingHideWhenLFGCompleteCheck,
        warnMissingPetText = _G.MABFWarnMissingPetCheckText,
    }
end
