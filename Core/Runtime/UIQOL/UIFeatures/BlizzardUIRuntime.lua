local addonName, MABF = ...

-----------------------------------------------------------
-- UIFeatures (Blizzard UI)
-----------------------------------------------------------
local auraClickthroughHooksInstalled = false
local auraClickthroughDeferred = false
local auraModifierWatcherInstalled = false
local foreverMicroMenuHooked = false
local foreverBagsBarHooked = false
local foreverRangeBarHooked = false
local foreverRangeBarEvents
local foreverWandAutoRepeatActive = false

local function IsCtrlRightClickBypassActive()
    return IsControlKeyDown and IsControlKeyDown()
end

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

local function ApplyAuraButtonMouseBehavior(button, enabled, allowRightClick)
    if not button then
        return
    end

    if button.SetMouseMotionEnabled then
        button:SetMouseMotionEnabled(true)
    end
    if button.SetPropagateMouseMotion then
        button:SetPropagateMouseMotion(enabled and true or false)
    end

    if enabled and not allowRightClick then
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
    local ctrlBypass = enabled and IsCtrlRightClickBypassActive() or false

    if BuffFrame and type(BuffFrame.auraFrames) == "table" then
        ApplyAuraOwnerMouseBehavior(BuffFrame, enabled)
        ApplyAuraOwnerMouseBehavior(BuffFrame.AuraContainer, enabled)
        for _, button in ipairs(BuffFrame.auraFrames) do
            ApplyAuraButtonMouseBehavior(button, enabled, ctrlBypass)
        end
    end

    if DebuffFrame and type(DebuffFrame.auraFrames) == "table" then
        ApplyAuraOwnerMouseBehavior(DebuffFrame, enabled)
        ApplyAuraOwnerMouseBehavior(DebuffFrame.AuraContainer, enabled)
        for _, button in ipairs(DebuffFrame.auraFrames) do
            ApplyAuraButtonMouseBehavior(button, enabled, ctrlBypass)
        end
    end

    if DeadlyDebuffFrame and DeadlyDebuffFrame.Debuff then
        ApplyAuraOwnerMouseBehavior(DeadlyDebuffFrame, enabled)
        ApplyAuraButtonMouseBehavior(DeadlyDebuffFrame.Debuff, enabled, ctrlBypass)
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

    if not auraModifierWatcherInstalled then
        auraModifierWatcherInstalled = true
        local watcher = CreateFrame("Frame")
        watcher:RegisterEvent("MODIFIER_STATE_CHANGED")
        watcher:SetScript("OnEvent", function(_, _, key)
            if key == "LCTRL" or key == "RCTRL" then
                MABF:ApplyBuffDebuffRightClickCamera()
            end
        end)
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

    -- WoW Forever 16001 uses a top-level MicroMenu frame. Keep the
    -- existing button handling below for clients that expose the legacy
    -- micro-button globals.
    if MicroMenu then
        MicroMenu:Hide()
        if not foreverMicroMenuHooked then
            hooksecurefunc(MicroMenu, "Show", function(self)
                if MattActionBarFontDB and MattActionBarFontDB.hideMicroMenu then
                    self:Hide()
                end
            end)
            foreverMicroMenuHooked = true
        end
    end

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

    -- WoW Forever 16001 moved the bag controls under the BagsBar frame.
    -- Keep the legacy individual-button handling below as-is for other
    -- clients and UI layouts.
    if BagsBar then
        BagsBar:Hide()
        if not foreverBagsBarHooked then
            hooksecurefunc(BagsBar, "Show", function(self)
                if MattActionBarFontDB and MattActionBarFontDB.hideBagBar then
                    self:Hide()
                end
            end)
            foreverBagsBarHooked = true
        end
    end

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

local function IsWandEquipped()
    if not GetInventoryItemLink then
        return false
    end

    local link = GetInventoryItemLink("player", 18)
    if not link then
        return false
    end

    local getInstant = C_Item and C_Item.GetItemInfoInstant or GetItemInfoInstant
    if not getInstant then
        return false
    end

    local _, itemType, itemSubType, _, _, classID, subclassID = getInstant(link)
    local wandSubclass = Enum and Enum.ItemWeaponSubclass and Enum.ItemWeaponSubclass.Wand or 19
    local weaponClass = Enum and Enum.ItemClass and Enum.ItemClass.Weapon or 2
    if classID == weaponClass and subclassID == wandSubclass then
        return true
    end

    -- Fallback for clients exposing the legacy subtype string.
    return itemType == "Weapon" and itemSubType == "Wand"
end

function MABF:ApplyRangeBarWandVisibility()
    if select(4, GetBuildInfo()) ~= 16001 then
        return
    end

    if not foreverRangeBarEvents then
        foreverRangeBarEvents = CreateFrame("Frame")
        foreverRangeBarEvents:RegisterEvent("START_AUTOREPEAT_SPELL")
        foreverRangeBarEvents:RegisterEvent("STOP_AUTOREPEAT_SPELL")
        foreverRangeBarEvents:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        foreverRangeBarEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
        foreverRangeBarEvents:RegisterEvent("SPELLS_CHANGED")
        foreverRangeBarEvents:SetScript("OnEvent", function(_, event)
            local frame = SwingTimerRangedFrame
            if not frame or not MattActionBarFontDB.showRangeBarOnlyWhileWandShooting then
                return
            end

            if event == "START_AUTOREPEAT_SPELL" then
                if IsWandEquipped() then
                    foreverWandAutoRepeatActive = true
                    frame:Show()
                else
                    foreverWandAutoRepeatActive = false
                    frame:Hide()
                end
            elseif event == "STOP_AUTOREPEAT_SPELL" then
                foreverWandAutoRepeatActive = false
                frame:Hide()
            else
                foreverWandAutoRepeatActive = false
                MABF:ApplyRangeBarWandVisibility()
            end
        end)
    end

    local frame = SwingTimerRangedFrame
    if not frame then
        return
    end

    if not foreverRangeBarHooked then
        frame:HookScript("OnShow", function(self)
            -- Blizzard owns the ranged-swing timing, but the frame can also
            -- appear during combat or Edit Mode. Require an active wand
            -- auto-repeat state before allowing it to remain visible.
            if MattActionBarFontDB.showRangeBarOnlyWhileWandShooting
                and (not foreverWandAutoRepeatActive or not IsWandEquipped()) then
                self:Hide()
            end
        end)
        foreverRangeBarHooked = true
    end

    if MattActionBarFontDB.showRangeBarOnlyWhileWandShooting then
        -- Start hidden; Blizzard's show path and START_AUTOREPEAT_SPELL
        -- will reveal it only for an active wand swing.
        foreverWandAutoRepeatActive = false
        frame:Hide()
    else
        foreverWandAutoRepeatActive = false
        frame:Show()
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
