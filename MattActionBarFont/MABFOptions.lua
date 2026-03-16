-- MABFOptions.lua
local addonName, MABF = ...

-- Builds the options window and wires all option pages.
function MABF:CreateOptionsWindow()
    local shell = MABF:BuildOptionsWindowShell()
    if not shell or not shell.frame then return end

    local f = shell.frame
    local leftPanel = shell.leftPanel
    local rightPanel = shell.rightPanel
    local THEME_ACCENT = shell.themeAccent
    local TAB_BORDER = shell.tabBorder
    local TAB_TEXT_NORMAL = shell.tabTextNormal
    local MABF_FONT = shell.fontPath

    -- Shared options context (page factory + common helper wrappers).
    local ctx = MABF:BuildOptionsContext({
        hostFrame = f,
        rightPanel = rightPanel,
    })
    if not ctx then return end

    local pages = ctx.pages
    local CreatePageTitle = ctx.CreatePageTitle
    local CreateContentPage = ctx.CreateContentPage
    local CreateBasicCheckbox = ctx.CreateBasicCheckbox
    local CreateMinimalDropdown = ctx.CreateMinimalDropdown
    local StyleSlider = ctx.StyleSlider
    local StyleMinimalCheckbox = ctx.StyleMinimalCheckbox
    local StyleMinimalRadio = ctx.StyleMinimalRadio

    -- Sidebar tabs and shortcut button wiring.
    local sectionGap = 6
    local sidebarController = MABF:BuildOptionsSidebarButtonController({
        leftPanel = leftPanel,
        pages = pages,
        sectionGap = sectionGap,
        themeAccent = THEME_ACCENT,
        tabBorder = TAB_BORDER,
        tabTextNormal = TAB_TEXT_NORMAL,
        fontPath = MABF_FONT,
    })
    local tabButtons = sidebarController and sidebarController.tabButtons or {}
    local allTabButtons = sidebarController and sidebarController.allTabButtons or {}

    -- Action Bars pages.
    local textPage = MABF:BuildActionBarTextPage({
        CreateContentPage = CreateContentPage,
        CreatePageTitle = CreatePageTitle,
        StyleSlider = StyleSlider,
        CreateMinimalDropdown = CreateMinimalDropdown,
    })
    local customFontsCheck = textPage and textPage.customFontsCheck

    MABF:BuildActionBarOffsetsPage({
        CreateContentPage = CreateContentPage,
        CreatePageTitle = CreatePageTitle,
        StyleSlider = StyleSlider,
    })

    -- Action Bars > Themes.
    MABF:BuildActionBarThemesPage({
        CreateContentPage = CreateContentPage,
        CreatePageTitle = CreatePageTitle,
        CreateMinimalDropdown = CreateMinimalDropdown,
        StyleSlider = StyleSlider,
    })

    local checkSpacing = -4

    -- Action Bars > Fading.
    local fadingPage = MABF:BuildActionBarFadingPage({
        CreateContentPage = CreateContentPage,
        CreatePageTitle = CreatePageTitle,
        CreateBasicCheckbox = CreateBasicCheckbox,
        StyleSlider = StyleSlider,
    })
    mouseoverFadeCheck = fadingPage and fadingPage.mouseoverFadeCheck
    petBarFadeCheck = fadingPage and fadingPage.petBarFadeCheck
    local mouseoverBarChecks = (fadingPage and fadingPage.mouseoverBarChecks) or {}

    -- Page slot allocation by sidebar index.
    pageUIFeatures = CreateContentPage(5)
    pageSystem = CreateContentPage(6)
    pageEDM = CreateContentPage(7)
    pageQuests = CreateContentPage(8)
    pageBags = CreateContentPage(9)
    pageMerchant = CreateContentPage(10)

    -- Action Bars > Features.
    local featuresPage = MABF:BuildActionBarFeaturesPage({
        CreateContentPage = CreateContentPage,
        CreatePageTitle = CreatePageTitle,
        CreateBasicCheckbox = CreateBasicCheckbox,
    })
    hideMacroTextCheck = featuresPage and featuresPage.hideMacroTextCheck
    reverseBarGrowthCheck = featuresPage and featuresPage.reverseBarGrowthCheck

    -- UI / QoL > Reminders root page.
    pageReminders = CreateContentPage(12)

    -- Default selected page.
    if sidebarController and sidebarController.ShowPage then
        sidebarController.ShowPage(1)
    else
        for i, page in ipairs(pages) do
            if i == 1 then page:Show() else page:Hide() end
        end
        for _, b in ipairs(allTabButtons) do
            MABF:SetTabButtonState(b, false)
        end
        if tabButtons[1] then
            MABF:SetTabButtonState(tabButtons[1], true)
        end
    end

    -- UI / QoL > UI Features shell and controls.
    local uiFeaturesShellPage = MABF:BuildUIFeaturesShellPage({
        pageUIFeatures = pageUIFeatures,
        CreatePageTitle = CreatePageTitle,
        CreateMinimalDropdown = CreateMinimalDropdown,
        StyleSlider = StyleSlider,
    })
    uiFeaturesTitle = uiFeaturesShellPage and uiFeaturesShellPage.uiFeaturesTitle
    objectiveTrackerCheck = uiFeaturesShellPage and uiFeaturesShellPage.objectiveTrackerCheck
    scaleStatusBarCheck = uiFeaturesShellPage and uiFeaturesShellPage.scaleStatusBarCheck
    scaleTalkingHeadCheck = uiFeaturesShellPage and uiFeaturesShellPage.scaleTalkingHeadCheck
    hideMicroMenuCheck = uiFeaturesShellPage and uiFeaturesShellPage.hideMicroMenuCheck
    hideMicroDesc = uiFeaturesShellPage and uiFeaturesShellPage.hideMicroDesc
    hideBagBarCheck = uiFeaturesShellPage and uiFeaturesShellPage.hideBagBarCheck
    cursorCircleCheck = uiFeaturesShellPage and uiFeaturesShellPage.cursorCircleCheck
    cursorCircleColorLabel = uiFeaturesShellPage and uiFeaturesShellPage.cursorCircleColorLabel
    cursorCircleColorDropdown = uiFeaturesShellPage and uiFeaturesShellPage.cursorCircleColorDropdown
    cursorCircleScaleSlider = uiFeaturesShellPage and uiFeaturesShellPage.cursorCircleScaleSlider
    cursorCircleOpacitySlider = uiFeaturesShellPage and uiFeaturesShellPage.cursorCircleOpacitySlider
    perfMonitorCheck = uiFeaturesShellPage and uiFeaturesShellPage.perfMonitorCheck
    perfMonitorDesc = uiFeaturesShellPage and uiFeaturesShellPage.perfMonitorDesc
    perfBgOpacitySlider = uiFeaturesShellPage and uiFeaturesShellPage.perfBgOpacitySlider
    perfColorLabel = uiFeaturesShellPage and uiFeaturesShellPage.perfColorLabel
    perfColorDropdown = uiFeaturesShellPage and uiFeaturesShellPage.perfColorDropdown
    perfVerticalCheck = uiFeaturesShellPage and uiFeaturesShellPage.perfVerticalCheck
    perfHideMSCheck = uiFeaturesShellPage and uiFeaturesShellPage.perfHideMSCheck

    -- System page controls.
    local systemPage = MABF:BuildSystemPage({
        pageEDM = pageEDM,
        CreatePageTitle = CreatePageTitle,
        CreateMinimalDropdown = CreateMinimalDropdown,
    })
    edmEnableCheck = systemPage and systemPage.edmEnableCheck
    minimapCheck = systemPage and systemPage.minimapCheck

    -- UI / QoL > Quests controls.
    local questsPage = MABF:BuildQuestTweaksPage({
        pageQuests = pageQuests,
        CreatePageTitle = CreatePageTitle,
    })
    autoAcceptCheck = questsPage and questsPage.autoAcceptCheck
    autoTurnInCheck = questsPage and questsPage.autoTurnInCheck

    -- UI / QoL > Reminders shell and controls.
    local remindersShellPage = MABF:BuildRemindersShellPage({
        pageReminders = pageReminders,
        CreatePageTitle = CreatePageTitle,
        checkSpacing = checkSpacing,
        StyleSlider = StyleSlider,
    })
    remindersTitle = remindersShellPage and remindersShellPage.remindersTitle
    remindersLockButton = remindersShellPage and remindersShellPage.remindersLockButton
    remindersMoveHint = remindersShellPage and remindersShellPage.remindersMoveHint
    local remindersPages = remindersShellPage and remindersShellPage.remindersPages

    warnMissingPetCheck = remindersShellPage and remindersShellPage.warnMissingPetCheck
    warnPetPassiveCheck = remindersShellPage and remindersShellPage.warnPetPassiveCheck
    warnPetPassiveResetBtn = remindersShellPage and remindersShellPage.warnPetPassiveResetBtn
    warnPetPassiveResetSizeBtn = remindersShellPage and remindersShellPage.warnPetPassiveResetSizeBtn
    petMissingOnlyInstanceCheck = remindersShellPage and remindersShellPage.petMissingOnlyInstanceCheck
    petMissingHideInRestAreaCheck = remindersShellPage and remindersShellPage.petMissingHideInRestAreaCheck
    petHideWhileMountedCheck = remindersShellPage and remindersShellPage.petHideWhileMountedCheck
    petMissingSuppressInMPlusCheck = remindersShellPage and remindersShellPage.petMissingSuppressInMPlusCheck
    petMissingSuppressAfterFirstPullCheck = remindersShellPage and remindersShellPage.petMissingSuppressAfterFirstPullCheck
    petMissingHideWhenLFGCompleteCheck = remindersShellPage and remindersShellPage.petMissingHideWhenLFGCompleteCheck
    warnMissingPetText = remindersShellPage and remindersShellPage.warnMissingPetText

    trackConsumablesCheck = remindersShellPage and remindersShellPage.trackConsumablesCheck
    trackConsumablesText = remindersShellPage and remindersShellPage.trackConsumablesText
    trackConsumablesResetBtn = remindersShellPage and remindersShellPage.trackConsumablesResetBtn
    trackConsumablesResetSizeBtn = remindersShellPage and remindersShellPage.trackConsumablesResetSizeBtn
    consumablesOnlyInstanceCheck = remindersShellPage and remindersShellPage.consumablesOnlyInstanceCheck
    consumablesHideInRestAreaCheck = remindersShellPage and remindersShellPage.consumablesHideInRestAreaCheck
    consumablesHideWhileMountedCheck = remindersShellPage and remindersShellPage.consumablesHideWhileMountedCheck
    consumablesSuppressInMPlusCheck = remindersShellPage and remindersShellPage.consumablesSuppressInMPlusCheck
    consumablesSuppressAfterFirstPullCheck = remindersShellPage and remindersShellPage.consumablesSuppressAfterFirstPullCheck
    consumablesHideWhenLFGCompleteCheck = remindersShellPage and remindersShellPage.consumablesHideWhenLFGCompleteCheck
    consumablesHealthstoneCheck = remindersShellPage and remindersShellPage.consumablesHealthstoneCheck

    warnMissingClassBuffsCheck = remindersShellPage and remindersShellPage.warnMissingClassBuffsCheck
    warnMissingClassBuffsText = remindersShellPage and remindersShellPage.warnMissingClassBuffsText
    warnMissingClassBuffsResetBtn = remindersShellPage and remindersShellPage.warnMissingClassBuffsResetBtn
    warnMissingClassBuffsResetSizeBtn = remindersShellPage and remindersShellPage.warnMissingClassBuffsResetSizeBtn
    buffsOnlyInInstanceCheck = remindersShellPage and remindersShellPage.buffsOnlyInInstanceCheck
    buffsHideInRestAreaCheck = remindersShellPage and remindersShellPage.buffsHideInRestAreaCheck
    buffsHideWhileMountedCheck = remindersShellPage and remindersShellPage.buffsHideWhileMountedCheck
    buffsSuppressInMPlusCheck = remindersShellPage and remindersShellPage.buffsSuppressInMPlusCheck
    buffsSuppressAfterFirstPullCheck = remindersShellPage and remindersShellPage.buffsSuppressAfterFirstPullCheck
    buffsHideWhenLFGCompleteCheck = remindersShellPage and remindersShellPage.buffsHideWhenLFGCompleteCheck

    warnClassSoulstoneCheck = remindersShellPage and remindersShellPage.warnClassSoulstoneCheck
    warnClassShamanShieldsCheck = remindersShellPage and remindersShellPage.warnClassShamanShieldsCheck
    warnClassPaladinBeaconsCheck = remindersShellPage and remindersShellPage.warnClassPaladinBeaconsCheck
    warnClassStuffResetBtn = remindersShellPage and remindersShellPage.warnClassStuffResetBtn
    warnClassStuffResetSizeBtn = remindersShellPage and remindersShellPage.warnClassStuffResetSizeBtn
    classOnlyInInstanceCheck = remindersShellPage and remindersShellPage.classOnlyInInstanceCheck
    classHideInRestAreaCheck = remindersShellPage and remindersShellPage.classHideInRestAreaCheck
    classHideWhileMountedCheck = remindersShellPage and remindersShellPage.classHideWhileMountedCheck
    classSuppressInMPlusCheck = remindersShellPage and remindersShellPage.classSuppressInMPlusCheck
    classSuppressAfterFirstPullCheck = remindersShellPage and remindersShellPage.classSuppressAfterFirstPullCheck
    classHideWhenLFGCompleteCheck = remindersShellPage and remindersShellPage.classHideWhenLFGCompleteCheck

    -- UI / QoL > Bags controls.
    local bagsPage = MABF:BuildBagTweaksPage({
        pageBags = pageBags,
        CreatePageTitle = CreatePageTitle,
    })
    bagIlvlCheck = bagsPage and bagsPage.bagIlvlCheck

    -- UI / QoL > Merchant controls.
    local merchantPage = MABF:BuildMerchantTweaksPage({
        pageMerchant = pageMerchant,
        CreatePageTitle = CreatePageTitle,
        StyleMinimalRadio = StyleMinimalRadio,
    })
    autoRepairCheck = merchantPage and merchantPage.autoRepairCheck
    local autoSellCheck = merchantPage and merchantPage.autoSellCheck

    -- System > Quick Commands controls.
    local quickCommandsPage = MABF:BuildQuickCommandsPage({
        pageSystem = pageSystem,
        CreatePageTitle = CreatePageTitle,
        CreateBasicCheckbox = CreateBasicCheckbox,
        checkSpacing = checkSpacing,
    })
    local quickBindCheck = quickCommandsPage and quickCommandsPage.quickBindCheck
    local reloadAliasCheck = quickCommandsPage and quickCommandsPage.reloadAliasCheck
    local editModeAliasCheck = quickCommandsPage and quickCommandsPage.editModeAliasCheck
    local pullAliasCheck = quickCommandsPage and quickCommandsPage.pullAliasCheck

    -- Final global control styling pass.
    local optionChecks = {
        mouseoverFadeCheck, petBarFadeCheck, hideMacroTextCheck, reverseBarGrowthCheck,
        objectiveTrackerCheck, scaleStatusBarCheck, scaleTalkingHeadCheck,
        hideMicroMenuCheck, hideBagBarCheck, cursorCircleCheck, perfMonitorCheck, perfVerticalCheck,
        perfHideMSCheck, edmEnableCheck, minimapCheck, autoAcceptCheck,
        autoTurnInCheck, bagIlvlCheck, autoRepairCheck, autoSellCheck,
        customFontsCheck,
        warnMissingPetCheck, warnPetPassiveCheck, trackConsumablesCheck,
        petMissingOnlyInstanceCheck, petMissingHideInRestAreaCheck, petHideWhileMountedCheck, petMissingSuppressInMPlusCheck,
        petMissingSuppressAfterFirstPullCheck, petMissingHideWhenLFGCompleteCheck,
        consumablesOnlyInstanceCheck, consumablesHideInRestAreaCheck, consumablesHideWhileMountedCheck, consumablesSuppressInMPlusCheck,
        consumablesSuppressAfterFirstPullCheck, consumablesHideWhenLFGCompleteCheck, consumablesHealthstoneCheck,
        warnMissingClassBuffsCheck, buffsOnlyInInstanceCheck, buffsHideInRestAreaCheck, buffsHideWhileMountedCheck,
        buffsSuppressInMPlusCheck, buffsSuppressAfterFirstPullCheck, buffsHideWhenLFGCompleteCheck,
        warnClassSoulstoneCheck, warnClassShamanShieldsCheck, warnClassPaladinBeaconsCheck,
        classOnlyInInstanceCheck, classHideInRestAreaCheck, classHideWhileMountedCheck, classSuppressInMPlusCheck,
        classSuppressAfterFirstPullCheck, classHideWhenLFGCompleteCheck,
        quickBindCheck, reloadAliasCheck, editModeAliasCheck, pullAliasCheck,
    }
    MABF:ApplyOptionsControlStyling({
        StyleMinimalCheckbox = StyleMinimalCheckbox,
        mouseoverBarChecks = mouseoverBarChecks,
        remindersPages = remindersPages,
        optionChecks = optionChecks,
        trackConsumablesText = trackConsumablesText,
        warnMissingPetText = warnMissingPetText,
        warnMissingClassBuffsText = warnMissingClassBuffsText,
    })

    tinsert(UISpecialFrames, "MABFOptionsFrame")
end
