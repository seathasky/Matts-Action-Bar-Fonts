local addonName, MABF = ...

-- Action bar tweaks.
local mouseoverBarDefinitions = {
    { key = "bar1", frameNames = { "MainActionBar", "MainMenuBar" }, buttonPrefix = "ActionButton" },
    { key = "bar2", frameNames = { "MultiBarBottomLeft" }, buttonPrefix = "MultiBarBottomLeftButton" },
    { key = "bar3", frameNames = { "MultiBarBottomRight" }, buttonPrefix = "MultiBarBottomRightButton" },
    { key = "bar4", frameNames = { "MultiBarRight" }, buttonPrefix = "MultiBarRightButton" },
    { key = "bar5", frameNames = { "MultiBarLeft" }, buttonPrefix = "MultiBarLeftButton" },
    { key = "bar6", frameNames = { "MultiBar5" }, buttonPrefix = "MultiBar5Button" },
}

local mouseoverRegenFrame = nil

local function IsInCombatLockdown()
    return InCombatLockdown and InCombatLockdown()
end

local function QueueActionBarMouseoverReapply()
    if mouseoverRegenFrame then
        mouseoverRegenFrame:Show()
        return
    end

    mouseoverRegenFrame = CreateFrame("Frame")
    mouseoverRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    mouseoverRegenFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent("PLAYER_REGEN_ENABLED")
        self:Hide()
        if MABF and MABF.ApplyActionBarMouseover then
            MABF:ApplyActionBarMouseover()
        end
    end)
end

local function GetMouseoverBarFrame(barDef)
    if not barDef or not barDef.frameNames then
        return nil
    end

    for _, frameName in ipairs(barDef.frameNames) do
        local frame = _G[frameName]
        if frame then
            return frame
        end
    end

    return nil
end

local function GetMouseoverBarDefinitionByKey(barKey)
    for _, barDef in ipairs(mouseoverBarDefinitions) do
        if barDef.key == barKey then
            return barDef
        end
    end
    return nil
end

local function IsMouseoverBarManaged(barDef)
    local cfg = MattActionBarFontDB and MattActionBarFontDB.mouseoverFadeBars
    if type(cfg) ~= "table" then
        return (barDef and (barDef.key == "bar4" or barDef.key == "bar5")) and true or false
    end
    return cfg[barDef.key] and true or false
end

local function IsMouseoverBarManagedByKey(barKey)
    local barDef = GetMouseoverBarDefinitionByKey(barKey)
    if not barDef then
        return false
    end
    return IsMouseoverBarManaged(barDef)
end

local function IsMouseOverBarOrButtons(barFrame, buttonPrefix)
    if not barFrame or not buttonPrefix then return false end
    if MouseIsOver(barFrame) then return true end

    for i = 1, 12 do
        local button = _G[buttonPrefix .. i]
        if button and MouseIsOver(button) then
            return true
        end
    end

    return false
end

local function GetMouseoverFadeDuration()
    local duration = 0.15
    if MattActionBarFontDB then
        duration = tonumber(MattActionBarFontDB.actionBarFadeDuration) or 0.15
    end
    if duration < 0 then
        duration = 0
    elseif duration > 1 then
        duration = 1
    end
    return duration
end

local function SetFrameAlphaWithFade(frame, targetAlpha)
    if not frame then return end

    local normalizedAlpha = (targetAlpha and targetAlpha >= 0.5) and 1 or 0
    local currentAlpha = frame:GetAlpha() or normalizedAlpha
    if frame._MABFTargetAlpha == normalizedAlpha and math.abs(currentAlpha - normalizedAlpha) < 0.01 then
        return
    end
    frame._MABFTargetAlpha = normalizedAlpha

    local duration = GetMouseoverFadeDuration()
    if IsInCombatLockdown() then
        -- Avoid UIFrameFade on protected action bars in combat.
        frame:SetAlpha(normalizedAlpha)
        QueueActionBarMouseoverReapply()
        return
    end

    if duration <= 0 then
        frame:SetAlpha(normalizedAlpha)
        return
    end

    if UIFrameFadeRemoveFrame then
        UIFrameFadeRemoveFrame(frame)
    end

    if UIFrameFade then
        local mode = normalizedAlpha == 1 and "IN" or "OUT"
        UIFrameFade(frame, {
            mode = mode,
            timeToFade = duration,
            startAlpha = frame:GetAlpha() or (normalizedAlpha == 1 and 0 or 1),
            endAlpha = normalizedAlpha,
        })
    else
        frame:SetAlpha(normalizedAlpha)
    end
end

local function UpdateManagedBarAlpha(barFrame, buttonPrefix, barKey)
    if not barFrame then return end

    if not MattActionBarFontDB or not MattActionBarFontDB.mouseoverFade then
        return
    end

    if not IsMouseoverBarManagedByKey(barKey) then
        if UIFrameFadeRemoveFrame and not IsInCombatLockdown() then
            UIFrameFadeRemoveFrame(barFrame)
        end
        barFrame._MABFTargetAlpha = 1
        barFrame:SetAlpha(1)
        return
    end

    if MABF._inQuickKeybindMode then
        barFrame._MABFTargetAlpha = 1
        barFrame:SetAlpha(1)
        return
    end

    if IsMouseOverBarOrButtons(barFrame, buttonPrefix) then
        SetFrameAlphaWithFade(barFrame, 1)
    else
        SetFrameAlphaWithFade(barFrame, 0)
    end
end

local function OnQuickKeybindModeEnabled()
    MABF._inQuickKeybindMode = true
    MABF:SetBarsMouseoverState(true)
end

local function OnQuickKeybindModeDisabled()
    MABF._inQuickKeybindMode = false
    MABF:ApplyActionBarMouseover()
end

function MABF:SetBarsMouseoverState(visible)
    if not MattActionBarFontDB or not MattActionBarFontDB.mouseoverFade then
        return
    end

    for _, barDef in ipairs(mouseoverBarDefinitions) do
        if IsMouseoverBarManaged(barDef) then
            local barFrame = GetMouseoverBarFrame(barDef)
            if barFrame then
                SetFrameAlphaWithFade(barFrame, visible and 1 or 0)
            end
        end
    end
end

local function HookMouseoverForBar(barDef, barFrame)
    if not barDef or not barFrame or barFrame._MABFMouseoverHooked then
        return
    end

    local buttonPrefix = barDef.buttonPrefix
    barFrame:HookScript("OnEnter", function()
        UpdateManagedBarAlpha(barFrame, buttonPrefix, barDef.key)
    end)
    barFrame:HookScript("OnLeave", function()
        UpdateManagedBarAlpha(barFrame, buttonPrefix, barDef.key)
    end)

    for i = 1, 12 do
        local button = _G[buttonPrefix .. i]
        if button and not button._MABFMouseoverHooked then
            button:HookScript("OnEnter", function()
                UpdateManagedBarAlpha(barFrame, buttonPrefix, barDef.key)
            end)
            button:HookScript("OnLeave", function()
                UpdateManagedBarAlpha(barFrame, buttonPrefix, barDef.key)
            end)
            button._MABFMouseoverHooked = true
        end
    end

    barFrame._MABFMouseoverHooked = true
end

local function UpdateAllManagedBarAlpha()
    for _, barDef in ipairs(mouseoverBarDefinitions) do
        local barFrame = GetMouseoverBarFrame(barDef)
        if barFrame then
            if IsMouseoverBarManaged(barDef) then
                UpdateManagedBarAlpha(barFrame, barDef.buttonPrefix, barDef.key)
            else
                if UIFrameFadeRemoveFrame and not IsInCombatLockdown() then
                    UIFrameFadeRemoveFrame(barFrame)
                end
                barFrame._MABFTargetAlpha = 1
                barFrame:SetAlpha(1)
            end
        end
    end
end

function MABF:ResetActionBarMouseoverState()
    for _, barDef in ipairs(mouseoverBarDefinitions) do
        local barFrame = GetMouseoverBarFrame(barDef)
        if barFrame then
            barFrame._MABFTargetAlpha = 1
            barFrame:SetAlpha(1)
        end
    end
end

function MABF:ResetActionBarMouseoverStateForBar(barKey)
    local barDef = GetMouseoverBarDefinitionByKey(barKey)
    if not barDef then
        return
    end

    local barFrame = GetMouseoverBarFrame(barDef)
    if barFrame then
        barFrame._MABFTargetAlpha = 1
        barFrame:SetAlpha(1)
    end
end

function MABF:ApplyActionBarMouseover()
    self._inQuickKeybindMode = self._inQuickKeybindMode or false

    if IsInCombatLockdown() then
        QueueActionBarMouseoverReapply()
        return
    end

    for _, barDef in ipairs(mouseoverBarDefinitions) do
        if IsMouseoverBarManaged(barDef) then
            local barFrame = GetMouseoverBarFrame(barDef)
            if barFrame then
                HookMouseoverForBar(barDef, barFrame)
            end
        end
    end

    if EventRegistry then
        if MattActionBarFontDB.mouseoverFade and not self._MABFMouseoverEventsRegistered then
            EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeEnabled", OnQuickKeybindModeEnabled)
            EventRegistry:RegisterCallback("QuickKeybindFrame.QuickKeybindModeDisabled", OnQuickKeybindModeDisabled)
            self._MABFMouseoverEventsRegistered = true
        elseif not MattActionBarFontDB.mouseoverFade and self._MABFMouseoverEventsRegistered then
            EventRegistry:UnregisterCallback("QuickKeybindFrame.QuickKeybindModeEnabled", OnQuickKeybindModeEnabled)
            EventRegistry:UnregisterCallback("QuickKeybindFrame.QuickKeybindModeDisabled", OnQuickKeybindModeDisabled)
            self._MABFMouseoverEventsRegistered = false
            self._inQuickKeybindMode = false
        end
    end

    if not MattActionBarFontDB.mouseoverFade then
        return
    end

    UpdateAllManagedBarAlpha()
end
