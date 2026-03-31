local addonName, MABF = ...

-----------------------------------------------------------
-- UIFeatures (Blizzard UI)
-----------------------------------------------------------
local auraClickthroughHooksInstalled = false
local auraClickthroughDeferred = false

local function ApplyAuraOwnerMouseBehavior(frame, enabled)
    if not frame then
        return
    end

    if frame.SetMouseMotionEnabled then
        frame:SetMouseMotionEnabled(true)
    end
    if frame.SetPropagateMouseMotion then
        frame:SetPropagateMouseMotion(enabled and true or false)
    end
    if frame.SetPropagateMouseClicks then
        frame:SetPropagateMouseClicks(enabled and true or false)
    end
end

local function ApplyAuraButtonMouseBehavior(button, enabled)
    if not button then
        return
    end

    if button.SetMouseMotionEnabled then
        button:SetMouseMotionEnabled(true)
    end
    if button.SetPropagateMouseMotion then
        button:SetPropagateMouseMotion(enabled and true or false)
    end

    if enabled then
        if button.RegisterForClicks then
            button:RegisterForClicks("LeftButtonUp")
        end
        if button.SetPassThroughButtons then
            button:SetPassThroughButtons("RightButton")
        end
        if button.SetPropagateMouseClicks then
            button:SetPropagateMouseClicks(true)
        end
        if button.SetMouseClickEnabled then
            button:SetMouseClickEnabled(true)
        end
    else
        if button.RegisterForClicks then
            button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        end
        if button.SetPassThroughButtons then
            button:SetPassThroughButtons()
        end
        if button.SetPropagateMouseClicks then
            button:SetPropagateMouseClicks(false)
        end
        if button.SetMouseClickEnabled then
            button:SetMouseClickEnabled(true)
        end
    end
end

function MABF:ApplyBuffDebuffRightClickCamera()
    if not MattActionBarFontDB then
        return false
    end

    if InCombatLockdown and InCombatLockdown() then
        auraClickthroughDeferred = true
        return false
    end

    local enabled = MattActionBarFontDB.buffDebuffRightClickCamera and true or false

    if BuffFrame and type(BuffFrame.auraFrames) == "table" then
        ApplyAuraOwnerMouseBehavior(BuffFrame, enabled)
        ApplyAuraOwnerMouseBehavior(BuffFrame.AuraContainer, enabled)
        for _, button in ipairs(BuffFrame.auraFrames) do
            ApplyAuraButtonMouseBehavior(button, enabled)
        end
    end

    if DebuffFrame and type(DebuffFrame.auraFrames) == "table" then
        ApplyAuraOwnerMouseBehavior(DebuffFrame, enabled)
        ApplyAuraOwnerMouseBehavior(DebuffFrame.AuraContainer, enabled)
        for _, button in ipairs(DebuffFrame.auraFrames) do
            ApplyAuraButtonMouseBehavior(button, enabled)
        end
    end

    if DeadlyDebuffFrame and DeadlyDebuffFrame.Debuff then
        ApplyAuraOwnerMouseBehavior(DeadlyDebuffFrame, enabled)
        ApplyAuraButtonMouseBehavior(DeadlyDebuffFrame.Debuff, enabled)
    end

    if not auraClickthroughHooksInstalled then
        auraClickthroughHooksInstalled = true

        if BuffFrame and BuffFrame.UpdateAuraButtons then
            hooksecurefunc(BuffFrame, "UpdateAuraButtons", function()
                MABF:ApplyBuffDebuffRightClickCamera()
            end)
        end

        if DebuffFrame and DebuffFrame.UpdateAuraButtons then
            hooksecurefunc(DebuffFrame, "UpdateAuraButtons", function()
                MABF:ApplyBuffDebuffRightClickCamera()
            end)
        end
    end

    auraClickthroughDeferred = false
    return true
end

function MABF:ApplyDeferredBuffDebuffRightClickCamera()
    if auraClickthroughDeferred then
        self:ApplyBuffDebuffRightClickCamera()
    end
end

function MABF:ApplyStatusBarScale()
    if MattActionBarFontDB.scaleStatusBar then
        if StatusTrackingBarManager then
            StatusTrackingBarManager:SetScale(0.7)
        end
    else
        if StatusTrackingBarManager then
            StatusTrackingBarManager:SetScale(1.0)
        end
    end
end

function MABF:ApplyHideMicroMenu()
    if not MattActionBarFontDB.hideMicroMenu then return end
    local buttonsToHide = {
        "CharacterMicroButton", "PlayerSpellsMicroButton", "ProfessionMicroButton",
        "AchievementMicroButton", "QuestLogMicroButton", "GuildMicroButton",
        "CollectionsMicroButton", "EJMicroButton",
        "MainMenuMicroButton", "QuickJoinToastButton", "StoreMicroButton"
    }
    for _, buttonName in ipairs(buttonsToHide) do
        local button = _G[buttonName]
        if button then
            button:Hide()
            if buttonName == "StoreMicroButton" then
                hooksecurefunc(button, "Show", function(self) self:Hide() end)
            end
        end
    end
end

function MABF:ApplyHideBagBar()
    if not MattActionBarFontDB.hideBagBar then return end
    if MainMenuBarBackpackButton then MainMenuBarBackpackButton:Hide() end
    if BagBarExpandToggle then BagBarExpandToggle:Hide() end
    if CharacterReagentBag0Slot then CharacterReagentBag0Slot:Hide() end

    for i = 0, 3 do
        local slot = _G["CharacterBag" .. i .. "Slot"]
        if slot then
            slot:Hide()
            slot:SetScript("OnShow", slot.Hide)
        end
    end

    if MainMenuBarBackpackButton then
        MainMenuBarBackpackButton:SetScript("OnShow", MainMenuBarBackpackButton.Hide)
    end
    if CharacterReagentBag0Slot then
        CharacterReagentBag0Slot:SetScript("OnShow", CharacterReagentBag0Slot.Hide)
    end
end

function MABF:ApplyScaleTalkingHead()
    local function ScaleHead()
        local frame = TalkingHeadFrame
        if not frame then return end
        if MattActionBarFontDB.scaleTalkingHead then
            frame:SetScale(0.7)
        else
            frame:SetScale(1.0)
        end
    end

    if TalkingHeadFrame then
        ScaleHead()
    else
        local loader = CreateFrame("Frame")
        loader:RegisterEvent("ADDON_LOADED")
        loader:SetScript("OnEvent", function(self, event, addon)
            if addon == "Blizzard_TalkingHeadUI" then
                ScaleHead()
                self:UnregisterAllEvents()
            end
        end)
    end
end

function MABF:ApplyObjectiveTrackerScale()
    if MattActionBarFontDB.scaleObjectiveTracker then
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:SetScale(0.7)
        end
    else
        if ObjectiveTrackerFrame then
            ObjectiveTrackerFrame:SetScale(1.0)
        end
    end
end
