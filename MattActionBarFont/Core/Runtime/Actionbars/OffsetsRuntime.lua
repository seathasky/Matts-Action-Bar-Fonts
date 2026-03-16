local addonName, MABF = ...

-- Runtime logic for Action Bars > Offsets.
function MABF:SetActionBarOffset(axis, value)
    if axis == "x" then
        MattActionBarFontDB.abXOffset = value
    elseif axis == "y" then
        MattActionBarFontDB.abYOffset = value
    else
        return
    end
    MABF:UpdateActionBarFontPositions()
end

function MABF:SetExtraAbilityOffset(axis, value)
    if axis == "x" then
        MattActionBarFontDB.extraXOffset = value
    elseif axis == "y" then
        MattActionBarFontDB.extraYOffset = value
    else
        return
    end
    MABF:UpdateActionBarFontPositions()
end

function MABF:SetCountTextOffset(axis, value)
    if axis == "x" then
        MattActionBarFontDB.xOffset = value
    elseif axis == "y" then
        MattActionBarFontDB.yOffset = value
    else
        return
    end
    MABF:UpdateFontPositions()
end

function MABF:ApplyAllActionBarOffsetSettings()
    MABF:UpdateActionBarFontPositions()
    MABF:UpdateFontPositions()
end

function MABF:ResetActionBarOffsetDefaults()
    local db = MattActionBarFontDB or {}
    MattActionBarFontDB = db

    db.abXOffset = (MABF.defaults and MABF.defaults.abXOffset) or 0
    db.abYOffset = (MABF.defaults and MABF.defaults.abYOffset) or 0
    db.extraXOffset = (MABF.defaults and MABF.defaults.extraXOffset) or 0
    db.extraYOffset = (MABF.defaults and MABF.defaults.extraYOffset) or 0
    db.xOffset = (MABF.defaults and MABF.defaults.xOffset) or 0
    db.yOffset = (MABF.defaults and MABF.defaults.yOffset) or 0
end
