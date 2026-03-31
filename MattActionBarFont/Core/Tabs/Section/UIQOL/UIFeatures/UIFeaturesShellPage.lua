local addonName, MABF = ...

-- Builds the UI / QoL > UI Features shell wiring:
-- title, sub-page builders, and sub-tab routing.
function MABF:BuildUIFeaturesShellPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageUIFeatures = opts.pageUIFeatures
    local CreatePageTitle = opts.CreatePageTitle
    local CreateMinimalDropdown = opts.CreateMinimalDropdown
    local StyleSlider = opts.StyleSlider

    if not pageUIFeatures or not CreatePageTitle or not CreateMinimalDropdown or not StyleSlider then
        return nil
    end

    local uiFeaturesTitle = CreatePageTitle(pageUIFeatures, "UI / QoL")

    local uiFeaturesBlizzard = MABF:BuildUIFeaturesBlizzardPage({
        pageUIFeatures = pageUIFeatures,
        uiFeaturesTitle = uiFeaturesTitle,
    })
    local objectiveTrackerCheck = uiFeaturesBlizzard and uiFeaturesBlizzard.objectiveTrackerCheck
    local scaleStatusBarCheck = uiFeaturesBlizzard and uiFeaturesBlizzard.scaleStatusBarCheck
    local scaleTalkingHeadCheck = uiFeaturesBlizzard and uiFeaturesBlizzard.scaleTalkingHeadCheck
    local hideMicroMenuCheck = uiFeaturesBlizzard and uiFeaturesBlizzard.hideMicroMenuCheck
    local hideMicroDesc = uiFeaturesBlizzard and uiFeaturesBlizzard.hideMicroDesc
    local hideBagBarCheck = uiFeaturesBlizzard and uiFeaturesBlizzard.hideBagBarCheck

    local uiFeaturesVisual = MABF:BuildUIFeaturesVisualPage({
        pageUIFeatures = pageUIFeatures,
        anchorControl = hideBagBarCheck,
        CreateMinimalDropdown = CreateMinimalDropdown,
        StyleSlider = StyleSlider,
    })
    local cursorCircleCheck = uiFeaturesVisual and uiFeaturesVisual.cursorCircleCheck
    local cursorCircleColorLabel = uiFeaturesVisual and uiFeaturesVisual.cursorCircleColorLabel
    local cursorCircleColorDropdown = uiFeaturesVisual and uiFeaturesVisual.cursorCircleColorDropdown
    local cursorCircleScaleSlider = uiFeaturesVisual and uiFeaturesVisual.cursorCircleScaleSlider
    local cursorCircleOpacitySlider = uiFeaturesVisual and uiFeaturesVisual.cursorCircleOpacitySlider

    local uiFeaturesTools = MABF:BuildUIFeaturesToolsPage({
        pageUIFeatures = pageUIFeatures,
        anchorControl = cursorCircleOpacitySlider,
        CreateMinimalDropdown = CreateMinimalDropdown,
        StyleSlider = StyleSlider,
    })
    local perfMonitorCheck = uiFeaturesTools and uiFeaturesTools.perfMonitorCheck
    local perfMonitorDesc = uiFeaturesTools and uiFeaturesTools.perfMonitorDesc
    local perfBgOpacitySlider = uiFeaturesTools and uiFeaturesTools.perfBgOpacitySlider
    local perfColorLabel = uiFeaturesTools and uiFeaturesTools.perfColorLabel
    local perfColorDropdown = uiFeaturesTools and uiFeaturesTools.perfColorDropdown
    local perfVerticalCheck = uiFeaturesTools and uiFeaturesTools.perfVerticalCheck
    local perfHideMSCheck = uiFeaturesTools and uiFeaturesTools.perfHideMSCheck
    local perfShowWorldMSCheck = uiFeaturesTools and uiFeaturesTools.perfShowWorldMSCheck

    MABF:SetupUIFeaturesSubTabs({
        pageUIFeatures = pageUIFeatures,
        uiFeaturesTitle = uiFeaturesTitle,
        blizzardControls = {
            objectiveTrackerCheck,
            scaleStatusBarCheck,
            scaleTalkingHeadCheck,
            hideMicroMenuCheck,
            hideMicroDesc,
            hideBagBarCheck,
        },
        visualControls = {
            cursorCircleCheck,
            cursorCircleColorLabel,
            cursorCircleColorDropdown,
            cursorCircleScaleSlider,
            cursorCircleOpacitySlider,
        },
        toolsControls = {
            perfMonitorCheck,
            perfMonitorDesc,
            perfBgOpacitySlider,
            perfColorLabel,
            perfColorDropdown,
            perfVerticalCheck,
            perfHideMSCheck,
            perfShowWorldMSCheck,
        },
    })

    return {
        uiFeaturesTitle = uiFeaturesTitle,
        objectiveTrackerCheck = objectiveTrackerCheck,
        scaleStatusBarCheck = scaleStatusBarCheck,
        scaleTalkingHeadCheck = scaleTalkingHeadCheck,
        hideMicroMenuCheck = hideMicroMenuCheck,
        hideMicroDesc = hideMicroDesc,
        hideBagBarCheck = hideBagBarCheck,
        cursorCircleCheck = cursorCircleCheck,
        cursorCircleColorLabel = cursorCircleColorLabel,
        cursorCircleColorDropdown = cursorCircleColorDropdown,
        cursorCircleScaleSlider = cursorCircleScaleSlider,
        cursorCircleOpacitySlider = cursorCircleOpacitySlider,
        perfMonitorCheck = perfMonitorCheck,
        perfMonitorDesc = perfMonitorDesc,
        perfBgOpacitySlider = perfBgOpacitySlider,
        perfColorLabel = perfColorLabel,
        perfColorDropdown = perfColorDropdown,
        perfVerticalCheck = perfVerticalCheck,
        perfHideMSCheck = perfHideMSCheck,
        perfShowWorldMSCheck = perfShowWorldMSCheck,
    }
end
