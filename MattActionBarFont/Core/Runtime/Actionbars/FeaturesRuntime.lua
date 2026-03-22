local addonName, MABF = ...

-- Runtime logic for Action Bars > Features.
local function GetButtonName(button)
    if not (button and button.GetName) then
        return ""
    end
    return button:GetName() or ""
end

local function IsStanceButton(button)
    return GetButtonName(button):find("StanceButton", 1, true) ~= nil
end

local function IsPetButton(button)
    return GetButtonName(button):find("PetActionButton", 1, true) ~= nil
end

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

    local db = MattActionBarFontDB
    if db and (
        db.hideMacroText
        or (db.hideStanceBarText and IsStanceButton(button))
        or (db.hidePetBarText and IsPetButton(button))
    ) then
        button.Name:Hide()
        return true
    end

    button.Name:Show()
    return false
end

function MABF:ApplySpecialBarHotKeyVisibility(button)
    if not button then
        return false
    end

    local hotKeyFont = button.HotKey or button.bind
    if not hotKeyFont then
        return false
    end

    local db = MattActionBarFontDB
    local shouldHide = db and (
        (db.hideStanceBarText and IsStanceButton(button))
        or (db.hidePetBarText and IsPetButton(button))
    )

    if shouldHide then
        hotKeyFont._MABFBypassColorLock = true
        hotKeyFont:SetAlpha(0)
        hotKeyFont:Hide()
        hotKeyFont._MABFBypassColorLock = nil
        return true
    end

    hotKeyFont._MABFBypassColorLock = nil
    hotKeyFont:SetAlpha(1)
    hotKeyFont:Show()
    return false
end
