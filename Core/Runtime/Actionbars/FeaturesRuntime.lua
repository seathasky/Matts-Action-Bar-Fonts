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

local function ShouldHideMainBarEndCaps(mainBar, overrideHideEndCaps)
    if overrideHideEndCaps then
        return true
    end

    if mainBar and mainBar.hideBarArt then
        return true
    end

    if MABF and MABF.IsMinimalActionBarThemeSelected and MABF:IsMinimalActionBarThemeSelected() then
        return true
    end

    return false
end

local function ApplyMainBarEndCapsVisibility(mainBar, overrideHideEndCaps)
    if not (mainBar and mainBar.EndCaps) then
        return
    end

    local shouldHide = ShouldHideMainBarEndCaps(mainBar, overrideHideEndCaps)
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
    if mainBar.EndCaps and mainBar.EndCaps.HookScript then
        mainBar.EndCaps:HookScript("OnShow", function(endCaps)
            ApplyMainBarEndCapsVisibility(endCaps:GetParent())
        end)
    end

    self._mainBarEndCapsFixInstalled = true
    ApplyMainBarEndCapsVisibility(mainBar)

    if not self._mainBarEndCapsFixEventFrame then
        local f = CreateFrame("Frame")
        f:RegisterEvent("PLAYER_ENTERING_WORLD")
        f:RegisterEvent("ACTIONBAR_PAGE_CHANGED")
        f:RegisterEvent("UPDATE_BONUS_ACTIONBAR")
        f:RegisterEvent("UPDATE_OVERRIDE_ACTIONBAR")
        f:RegisterEvent("UPDATE_VEHICLE_ACTIONBAR")
        f:RegisterEvent("UNIT_ENTERED_VEHICLE")
        f:RegisterEvent("UNIT_EXITED_VEHICLE")
        f:RegisterEvent("CINEMATIC_START")
        f:RegisterEvent("CINEMATIC_STOP")
        f:SetScript("OnEvent", function(_, _, unit)
            if unit and unit ~= "player" then
                return
            end
            C_Timer.After(0, function()
                ApplyMainBarEndCapsVisibility(GetMainBarFrame())
            end)
        end)
        self._mainBarEndCapsFixEventFrame = f
    end
end

local reverseGrowthBars = {}

local function ApplyMainBarGrowthLayout(mainBar)
    local state = reverseGrowthBars[mainBar]
    if not state or state.applying then return end

    local reverse = MattActionBarFontDB and MattActionBarFontDB.reverseBarGrowth
    if not reverse and not state.applied then return end
    if InCombatLockdown() then
        MABF._reverseGrowthPending = true
        return
    end

    local containers = mainBar.shownButtonContainers
    if not containers or #containers == 0 or not mainBar.numRows or mainBar.numRows < 1
        or not GridLayoutUtil or not AnchorUtil then
        return
    end

    -- Edit Mode owns addButtonsToTop and resets it when applying orientation.
    -- Reverse only our layout parameters; leave Blizzard's flag and cache intact.
    local growUp = mainBar.addButtonsToTop
    if reverse then growUp = not growUp end
    local stride = math.ceil(#containers / mainBar.numRows)
    local padding = math.max(mainBar.minButtonPadding or 0, mainBar.buttonPadding or 0)
    local xMultiplier = mainBar.addButtonsToRight and 1 or -1
    local yMultiplier = growUp and 1 or -1
    local createLayout = mainBar.isHorizontal and GridLayoutUtil.CreateStandardGridLayout
        or GridLayoutUtil.CreateVerticalGridLayout
    local layout = createLayout(stride, padding, padding, xMultiplier, yMultiplier)
    local anchorPoint
    if mainBar.addButtonsToLeft then
        anchorPoint = "LEFT"
    elseif growUp then
        anchorPoint = mainBar.addButtonsToRight and "BOTTOMLEFT" or "BOTTOMRIGHT"
    else
        anchorPoint = mainBar.addButtonsToRight and "TOPLEFT" or "TOPRIGHT"
    end

    state.applying = true
    GridLayoutUtil.ApplyGridLayout(containers, AnchorUtil.CreateAnchor(anchorPoint, mainBar, anchorPoint), layout)
    mainBar:Layout()
    mainBar:UpdateSpellFlyoutDirection()
    state.applied = reverse and true or false
    state.applying = false
end

function MABF:ApplyReverseBarGrowth()
    if InCombatLockdown() then
        self._reverseGrowthPending = true
        return
    end
    self._reverseGrowthPending = false

    local mainBar = GetMainBarFrame()
    if not mainBar or type(mainBar.UpdateGridLayout) ~= "function" then
        if not self._reverseGrowthRetryQueued then
            self._reverseGrowthRetryQueued = true
            C_Timer.After(1, function()
                self._reverseGrowthRetryQueued = false
                MABF:ApplyReverseBarGrowth()
            end)
        end
        return
    end

    if not reverseGrowthBars[mainBar] then
        reverseGrowthBars[mainBar] = {}
        hooksecurefunc(mainBar, "UpdateGridLayout", ApplyMainBarGrowthLayout)
    end
    ApplyMainBarGrowthLayout(mainBar)
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
