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
local foreverRangeBarEnabled = false
local foreverRangeBar
local foreverRangeBarAlpha

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

local function GetRangeBarSetting(frame, setting, fallback)
    local settings = Enum and Enum.EditModeSwingTimerSetting
    local id = settings and settings[setting]
    if id and frame.IsInitialized and frame:IsInitialized() and frame.HasSetting and frame:HasSetting(id) then
        return frame:GetSettingValue(id)
    end
    return fallback
end

local function UpdateWandRangeBarLayout(frame)
    -- Read the saved layout without running Blizzard's setting mutators or
    -- frame-position manager from addon execution.
    local scale = GetRangeBarSetting(frame, "Scale", frame:GetScale() * 100) / 100
    local parentScale = frame:GetParent():GetEffectiveScale() / UIParent:GetEffectiveScale()
    foreverRangeBar:SetScale(scale * parentScale)
    foreverRangeBar:ClearAllPoints()
    foreverRangeBar:SetPoint("CENTER", frame, "CENTER")
    foreverRangeBar:SetSize(GetRangeBarSetting(frame, "Width", frame:GetWidth()),
        GetRangeBarSetting(frame, "Height", frame:GetHeight()))
    foreverRangeBar:SetFrameStrata(frame:GetFrameStrata())
    foreverRangeBar:SetFrameLevel(frame:GetFrameLevel() + 1)
    foreverRangeBar:SetAlpha(GetRangeBarSetting(frame, "Opacity", foreverRangeBarAlpha * 100) / 100)
    local showTitle = GetRangeBarSetting(frame, "ShowBarTitle", 1) == 1
    foreverRangeBar.TypeLabel:SetShown(showTitle)
    foreverRangeBar.TypeLabelShadow:SetShown(showTitle)
    foreverRangeBar.TimeLabel:SetShown(GetRangeBarSetting(frame, "ShowTime", 1) == 1)
end

local function UpdateWandRangeBarVisibility()
    local frame = SwingTimerRangedFrame
    if not frame or not foreverRangeBar then
        return
    end
    -- SetAlpha has no OnHide side effects. Hide/Show and ResetSwingTimer
    -- execute Blizzard handlers which write shared timer state; that taint
    -- reaches HasRangedWeapon's comparison of secret attack-speed values.
    local alpha = GetRangeBarSetting(frame, "Opacity", foreverRangeBarAlpha * 100) / 100
    frame:SetAlpha(foreverRangeBarEnabled and not frame.isInEditMode and 0 or alpha)
    local show = foreverRangeBarEnabled and foreverWandAutoRepeatActive and not frame.isInEditMode
    if show then
        UpdateWandRangeBarLayout(frame)
    end
    foreverRangeBar:SetShown(show)
end

local function CreateWandRangeBar()
    -- Do not inherit SwingTimerFrameTemplate: its OnLoad registers the frame
    -- with Blizzard's manager. All countdown state belongs to this addon.
    local bar = CreateFrame("Frame", nil, UIParent)
    bar:Hide()
    local background = bar:CreateTexture(nil, "BACKGROUND")
    background:SetAtlas("ui-swingtimerbar-background")
    background:SetAllPoints()
    local border = bar:CreateTexture(nil, "BACKGROUND")
    border:SetAtlas("ui-swingtimerbar-frame")
    border:SetAllPoints()
    local status = CreateFrame("StatusBar", nil, bar)
    status:SetPoint("TOPLEFT", 5, -4)
    status:SetPoint("BOTTOMRIGHT", -5, 4)
    status:SetMinMaxValues(0, 1)
    status:SetStatusBarTexture("ui-swingtimerbar-filling-ranged")
    status:SetValue(0)
    bar.StatusBar = status
    local pip = status:CreateTexture(nil, "OVERLAY")
    pip:SetAtlas("ui-swingtimerbar-pip", true)
    pip:SetPoint("RIGHT", status:GetStatusBarTexture(), "RIGHT")
    pip:Hide()
    bar.Pip = pip
    local shadow = status:CreateTexture(nil, "OVERLAY")
    shadow:SetAtlas("ui-swingtimerbar-textshadow-left")
    shadow:SetWidth(171)
    shadow:SetPoint("TOPLEFT")
    shadow:SetPoint("BOTTOMLEFT")
    bar.TypeLabelShadow = shadow
    local title = status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("LEFT", 10, 0)
    title:SetText(SWING_TIMER_RANGED or "Ranged")
    bar.TypeLabel = title
    local time = status:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    time:SetPoint("RIGHT", -10, 0)
    time:SetText("0.0")
    bar.TimeLabel = time
    bar:SetScript("OnHide", function(self)
        self.swingDuration = nil
        self.swingEndTime = nil
        self.StatusBar:SetValue(0)
        self.Pip:Hide()
        self.TimeLabel:SetText("0.0")
    end)
    bar:SetScript("OnUpdate", function(self)
        if not self.swingDuration then return end
        local remaining = self.swingEndTime - GetTime()
        if remaining <= 0 then
            self.swingDuration = nil
            self.swingEndTime = nil
            self.StatusBar:SetValue(0)
            self.Pip:Hide()
            self.TimeLabel:SetText("0.0")
        else
            self.StatusBar:SetValue(1 - remaining / self.swingDuration)
            self.TimeLabel:SetFormattedText("%.1f", remaining)
        end
    end)
    return bar
end

function MABF:ApplyRangeBarWandVisibility()
    if select(4, GetBuildInfo()) ~= 16001 then
        return
    end

    if not MattActionBarFontDB or not MattActionBarFontDB.showRangeBarOnlyWhileWandShooting then
        foreverWandAutoRepeatActive = false
        if foreverRangeBarEvents then
            foreverRangeBarEvents:UnregisterAllEvents()
        end
        if foreverRangeBarEnabled then
            foreverRangeBarEnabled = false
            UpdateWandRangeBarVisibility()
        end
        return
    end

    if not foreverRangeBarEvents then
        foreverRangeBarEvents = CreateFrame("Frame")
        foreverRangeBarEvents:SetScript("OnEvent", function(_, event, ...)
            local frame = SwingTimerRangedFrame
            if not frame or not MattActionBarFontDB or not MattActionBarFontDB.showRangeBarOnlyWhileWandShooting then
                return
            end
            if not foreverRangeBar then
                MABF:ApplyRangeBarWandVisibility()
            end

            if event == "PLAYER_SWING" then
                local swingDuration, swingType = ...
                if issecretvalue and (issecretvalue(swingDuration) or issecretvalue(swingType)) then
                    return
                end
                local rangedType = Enum and Enum.PlayerSwingType and Enum.PlayerSwingType.Ranged or 2
                if swingType == rangedType and IsWandEquipped() and type(swingDuration) == "number" and swingDuration > 0 then
                    foreverWandAutoRepeatActive = true
                    UpdateWandRangeBarVisibility()
                    foreverRangeBar.swingDuration = swingDuration
                    foreverRangeBar.swingEndTime = GetTime() + swingDuration
                    foreverRangeBar.StatusBar:SetValue(0)
                    foreverRangeBar.Pip:Show()
                    foreverRangeBar.TimeLabel:SetFormattedText("%.1f", swingDuration)
                end
            elseif event == "START_AUTOREPEAT_SPELL" then
                foreverWandAutoRepeatActive = IsWandEquipped()
                UpdateWandRangeBarVisibility()
            elseif event == "STOP_AUTOREPEAT_SPELL" then
                foreverWandAutoRepeatActive = false
                UpdateWandRangeBarVisibility()
            else
                foreverWandAutoRepeatActive = false
                MABF:ApplyRangeBarWandVisibility()
            end
        end)
    end
    foreverRangeBarEvents:RegisterEvent("START_AUTOREPEAT_SPELL")
    foreverRangeBarEvents:RegisterEvent("STOP_AUTOREPEAT_SPELL")
    foreverRangeBarEvents:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
    foreverRangeBarEvents:RegisterEvent("PLAYER_ENTERING_WORLD")
    foreverRangeBarEvents:RegisterEvent("SPELLS_CHANGED")
    foreverRangeBarEvents:RegisterEvent("PLAYER_SWING")

    local frame = SwingTimerRangedFrame
    if not frame then
        return
    end

    if not foreverRangeBarHooked then
        foreverRangeBarAlpha = frame:GetAlpha()
        foreverRangeBar = CreateWandRangeBar()
        local function RefreshVisibility()
            if foreverRangeBarEnabled then
                UpdateWandRangeBarVisibility()
            end
        end
        frame:HookScript("OnShow", RefreshVisibility)
        if frame.SetIsInEditMode then
            hooksecurefunc(frame, "SetIsInEditMode", RefreshVisibility)
        end
        if frame.UpdateSystemSetting then
            hooksecurefunc(frame, "UpdateSystemSetting", RefreshVisibility)
        end
        foreverRangeBarHooked = true
    end

    foreverRangeBarEnabled = true
    foreverWandAutoRepeatActive = false
    UpdateWandRangeBarVisibility()
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
