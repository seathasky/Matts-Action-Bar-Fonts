local addonName, MABF = ...

-- Builds the Action Bars > Features options page UI.
function MABF:BuildActionBarFeaturesPage(opts)
    if type(opts) ~= "table" then return nil end

    local CreateContentPage = opts.CreateContentPage
    local CreatePageTitle = opts.CreatePageTitle
    local CreateBasicCheckbox = opts.CreateBasicCheckbox

    if not CreateContentPage or not CreatePageTitle or not CreateBasicCheckbox then
        return nil
    end

    local pageABFeatures = CreateContentPage(11)
    local abFeaturesTitle = CreatePageTitle(pageABFeatures, "AB Features")

    local hideMacroTextCheck = CreateBasicCheckbox(
        pageABFeatures,
        "MABFHideMacroTextExperimentalCheck",
        abFeaturesTitle,
        "TOPLEFT",
        0,
        -8,
        "Hide Macro Text",
        MattActionBarFontDB.hideMacroText,
        function(self)
            MattActionBarFontDB.hideMacroText = self:GetChecked() and true or false
            MABF:UpdateMacroText()
        end
    )

    local reverseBarGrowthCheck = CreateBasicCheckbox(
        pageABFeatures,
        "MABFReverseBarGrowthCheck",
        hideMacroTextCheck,
        "TOPLEFT",
        0,
        -4,
        "Reverse Bar Growth (Bar 1)",
        MattActionBarFontDB.reverseBarGrowth,
        function(self)
            MattActionBarFontDB.reverseBarGrowth = self:GetChecked() and true or false
            StaticPopup_Show("MABF_RELOAD_UI")
        end
    )

    return {
        page = pageABFeatures,
        hideMacroTextCheck = hideMacroTextCheck,
        reverseBarGrowthCheck = reverseBarGrowthCheck,
    }
end
