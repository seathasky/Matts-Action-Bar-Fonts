local addonName, MABF = ...

-- Runtime logic for Action Bars > Text.
function MABF:SetMainFontSize(value)
    MattActionBarFontDB.fontSize = value
    MABF:ApplyFontSettings()
    MABF:UpdatePetBarFontSettings()
end

function MABF:SetCountFontSize(value)
    MattActionBarFontDB.countFontSize = value
    MABF:UpdateSpecificBars()
    MABF:UpdateFontPositions()
end

function MABF:SetMacroTextSize(value)
    MattActionBarFontDB.macroTextSize = value
    MABF:UpdateMacroText()
end

function MABF:SetPetBarFontSize(value)
    MattActionBarFontDB.petBarFontSize = value
    MABF:UpdatePetBarFontSettings()
end

function MABF:ApplyAllActionBarTextSettings()
    if MABF and MABF.ApplyFontSettings then
        MABF:ApplyFontSettings()
        MABF:UpdateMacroText()
        MABF:UpdateSpecificBars()
        MABF:UpdatePetBarFontSettings()
        MABF:UpdateFontPositions()
        MABF:UpdateActionBarFontPositions()
    end
end

function MABF:ResetActionBarTextSizeDefaults(customEnabled)
    local db = MattActionBarFontDB or {}
    MattActionBarFontDB = db

    db.fontSize = (MABF.defaults and MABF.defaults.fontSize) or 12
    db.countFontSize = (MABF.defaults and MABF.defaults.countFontSize) or 14
    db.macroTextSize = (MABF.defaults and MABF.defaults.macroTextSize) or 12
    db.petBarFontSize = (MABF.defaults and MABF.defaults.petBarFontSize) or 12

    if customEnabled then
        db.enableCustomFontSection = true
        db.fontFamily = "Naowh"
        db.fontFamilyPath = nil
        db.fontFamilyPathName = nil
    else
        db.enableCustomFontSection = false
        db.fontFamily = "Blizzard Default"
    end

    if customEnabled and MABF and MABF.SetSelectedFont then
        MABF:SetSelectedFont("Naowh")
    end
end
