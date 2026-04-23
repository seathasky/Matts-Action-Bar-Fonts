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

local function GetMainBarFrame()
    return _G.MainActionBar or _G.MainMenuBar
end

local function ApplyMainBarEndCapsVisibility(mainBar, overrideHideEndCaps)
    if not (mainBar and mainBar.EndCaps) then
        return
    end

    local shouldHide = (overrideHideEndCaps and true) or (mainBar.hideBarArt and true) or false
    if shouldHide then
        mainBar.EndCaps:SetAlpha(0)
        mainBar.EndCaps:Hide()
    else
        mainBar.EndCaps:SetAlpha(1)
    end
end

function MABF:SetupMainActionBarEndCapsFix()
    if self._mainBarEndCapsFixInstalled then
        return
    end

    local mainBar = GetMainBarFrame()
    if not (mainBar and type(mainBar.UpdateEndCaps) == "function") then
        if not self._mainBarEndCapsFixRetryQueued then
            self._mainBarEndCapsFixRetryQueued = true
            C_Timer.After(0.5, function()
                self._mainBarEndCapsFixRetryQueued = false
                MABF:SetupMainActionBarEndCapsFix()
            end)
        end
        return
    end

    hooksecurefunc(mainBar, "UpdateEndCaps", function(bar, overrideHideEndCaps)
        ApplyMainBarEndCapsVisibility(bar, overrideHideEndCaps)
    end)

    self._mainBarEndCapsFixInstalled = true
    ApplyMainBarEndCapsVisibility(mainBar)
end

function MABF:ApplyReverseBarGrowth()
    local mainBar = GetMainBarFrame()
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
    local petBarFaded = IsPetButton(button)
        and self
        and self.IsPetBarFadedOut
        and self:IsPetBarFadedOut()
    local shouldHide = db and (
        (db.hideStanceBarText and IsStanceButton(button))
        or (db.hidePetBarText and IsPetButton(button))
    )
    shouldHide = shouldHide or petBarFaded

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
