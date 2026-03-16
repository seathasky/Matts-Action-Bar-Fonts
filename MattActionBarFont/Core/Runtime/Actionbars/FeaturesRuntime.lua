local addonName, MABF = ...

-- Runtime logic for Action Bars > Features.
function MABF:ApplyReverseBarGrowth()
    local mainBar = _G.MainActionBar or _G.MainMenuBar
    if not mainBar then
        if not self._reverseGrowthRetryQueued then
            self._reverseGrowthRetryQueued = true
            C_Timer.After(1, function()
                self._reverseGrowthRetryQueued = false
                MABF:ApplyReverseBarGrowth()
            end)
        end
        return
    end

    if MattActionBarFontDB and MattActionBarFontDB.reverseBarGrowth then
        if not self._reverseGrowthApplied then
            mainBar.addButtonsToTop = not mainBar.addButtonsToTop
            self._reverseGrowthApplied = true
        end
    else
        self._reverseGrowthApplied = false
    end

    if type(mainBar.UpdateGridLayout) == "function" then
        mainBar:UpdateGridLayout()
    end
end

function MABF:ApplyMacroTextVisibility(button)
    if not button or not button.Name then
        return false
    end

    if MattActionBarFontDB and MattActionBarFontDB.hideMacroText then
        button.Name:Hide()
        return true
    end

    button.Name:Show()
    return false
end
