local addonName, MABF = ...

-- Shortcuts: Edit Mode button action
function MABF:RunEditModeShortcut()
    if MABFOptionsFrame then
        MABFOptionsFrame:Hide()
    end
    ShowUIPanel(EditModeManagerFrame)
end
