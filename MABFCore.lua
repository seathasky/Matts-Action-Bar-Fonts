-- MABFCore.lua
local addonName, MABF = ...

-- Constants for font size limits
local MAX_FONT_SIZE = 50   -- Maximum allowed font size for main fonts
local MIN_FONT_SIZE = 10   -- Minimum allowed font size for main fonts

-----------------------------------------------------------
-- Initialization & Font Scanning
-----------------------------------------------------------
function MABF:Init()
    -- Apply defaults (handles both fresh installs and missing keys on upgrade)
    self:ApplyDefaults()

    -- Clamp the main font size.
    MattActionBarFontDB.fontSize = math.min(math.max(MattActionBarFontDB.fontSize, MIN_FONT_SIZE), MAX_FONT_SIZE)

    -- Initialize available fonts.
    MABF.availableFonts = MABF:ScanCustomFonts()

    -- Register all fonts with LibSharedMedia so other addons can use them
    MABF:RegisterFontsWithLSM()
end

-- Base fonts provided by WoW.
MABF.basefonts = {
    ["MORPHEUS"] = "Fonts\\MORPHEUS.ttf",
    ["SKURRI"]   = "Fonts\\SKURRI.ttf",
    ["ARIALN"]   = "Fonts\\ARIALN.ttf",
    ["FRIZQT"]   = "Fonts\\FRIZQT__.ttf"
}

function MABF:ScanCustomFonts()
    local fonts = {}
    -- Add base fonts.
    for name, path in pairs(MABF.basefonts) do
        fonts[name] = path
    end

    -- Merge user-defined custom fonts if provided.
    if AddYourCustomFonts then
        for name, path in pairs(AddYourCustomFonts) do
            fonts[name] = path
        end
    end

    -- Pull in fonts registered by other addons via LibSharedMedia
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if LSM then
        local lsmFonts = LSM:HashTable(LSM.MediaType.FONT)
        if lsmFonts then
            for name, path in pairs(lsmFonts) do
                if not fonts[name] then
                    fonts[name] = path
                end
            end
        end
    end

    return fonts
end

-----------------------------------------------------------
-- RegisterFontsWithLSM
-- Registers all available fonts with LibSharedMedia-3.0
-- so other addons (ElvUI, WeakAuras, etc.) can use them.
-----------------------------------------------------------
function MABF:RegisterFontsWithLSM()
    local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
    if not LSM then return end

    for name, path in pairs(self.availableFonts) do
        LSM:Register(LSM.MediaType.FONT, "MABF: " .. name, path)
    end
end

-----------------------------------------------------------
-- ApplyStatusBarScale
-----------------------------------------------------------
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

-----------------------------------------------------------
-- ApplyHideMicroMenu
-----------------------------------------------------------
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

-----------------------------------------------------------
-- Pet Bar Mouseover Fade
-----------------------------------------------------------
do
    local petBarHooked = false

    local function IsPetBarMouseOver()
        local bar = _G["PetActionBar"]
        if bar and MouseIsOver(bar) then return true end
        for i = 1, 10 do
            local btn = _G["PetActionButton" .. i]
            if btn and MouseIsOver(btn) then return true end
        end
        return false
    end

    local function UpdatePetBarAlpha()
        local bar = _G["PetActionBar"]
        if not bar then return end
        if not MattActionBarFontDB or not MattActionBarFontDB.petBarMouseoverFade then
            bar:SetAlpha(1)
            return
        end
        if MABF._inQuickKeybindMode then
            bar:SetAlpha(1)
            return
        end
        bar:SetAlpha(IsPetBarMouseOver() and 1 or 0)
    end

    function MABF:ApplyPetBarMouseoverFade()
        if not MattActionBarFontDB.petBarMouseoverFade then
            local bar = _G["PetActionBar"]
            if bar then bar:SetAlpha(1) end
            return
        end

        local bar = _G["PetActionBar"]
        if not bar then return end

        if not petBarHooked then
            bar:EnableMouse(true)
            bar:HookScript("OnEnter", UpdatePetBarAlpha)
            bar:HookScript("OnLeave", UpdatePetBarAlpha)
            for i = 1, 10 do
                local btn = _G["PetActionButton" .. i]
                if btn then
                    btn:HookScript("OnEnter", UpdatePetBarAlpha)
                    btn:HookScript("OnLeave", UpdatePetBarAlpha)
                end
            end
            petBarHooked = true
        end

        UpdatePetBarAlpha()
    end
end

-----------------------------------------------------------
-- ApplyHideBagBar
-----------------------------------------------------------
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

-----------------------------------------------------------
-- ApplyScaleTalkingHead
-----------------------------------------------------------
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

    -- TalkingHeadFrame is load-on-demand, hook it when it loads
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

-----------------------------------------------------------
-- ApplyFontSettings
-- Reapplies font settings by calling various update functions.
-----------------------------------------------------------
function MABF:ApplyFontSettings()
    if self.UpdateActionBarFontPositions then
        self:UpdateActionBarFontPositions()
    end
    if self.UpdateMacroText then
        self:UpdateMacroText()
    end
    if self.UpdateSpecificBars then
        self:UpdateSpecificBars()
    end
    if self.UpdatePetBarFontSettings then
        self:UpdatePetBarFontSettings()
    end
    if self.ApplyObjectiveTrackerScale then
        self:ApplyObjectiveTrackerScale()
    end
    if self.ApplyMinimapScale then
        self:ApplyMinimapScale()
    end
    if self.ApplyActionBarMouseover then
        self:ApplyActionBarMouseover()
    end
end

-----------------------------------------------------------
-- ApplyObjectiveTrackerScale
-- Scales the objective tracker to 0.7 if enabled
-----------------------------------------------------------
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

-----------------------------------------------------------
-- ApplyMinimapScale
-- Scales the minimap based on user preference
-----------------------------------------------------------
function MABF:ApplyMinimapScale()
    if Minimap then
        if MattActionBarFontDB.smallerMinimap then
            Minimap:SetScale(0.7)
        elseif MattActionBarFontDB.biggerMinimap then
            Minimap:SetScale(1.3)
        else
            Minimap:SetScale(1.0)
        end
    end
end

-----------------------------------------------------------
-- Action Bar Tweaks
-----------------------------------------------------------
local mouseoverManagedBars = {
    "MultiBarRight", -- Action Bar 4
    "MultiBarLeft",  -- Action Bar 5
}

local function IsMouseOverBarOrButtons(barFrame, barName)
    if not barFrame or not barName then return false end
    if MouseIsOver(barFrame) then return true end

    for i = 1, 12 do
        local button = _G[barName .. "Button" .. i]
        if button and MouseIsOver(button) then
            return true
        end
    end

    return false
end

local function UpdateManagedBarAlpha(barFrame, barName)
    if not barFrame then return end

    if not MattActionBarFontDB or not MattActionBarFontDB.mouseoverFade then
        barFrame:SetAlpha(1)
        return
    end

    if MABF._inQuickKeybindMode then
        barFrame:SetAlpha(1)
        return
    end

    if IsMouseOverBarOrButtons(barFrame, barName) then
        barFrame:SetAlpha(1)
    else
        barFrame:SetAlpha(0)
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
    for _, barName in ipairs(mouseoverManagedBars) do
        local barFrame = _G[barName]
        if barFrame then
            barFrame:SetAlpha(visible and 1 or 0)
        end
    end
end

function MABF:ApplyActionBarMouseover()
    self._inQuickKeybindMode = self._inQuickKeybindMode or false

    for _, barName in ipairs(mouseoverManagedBars) do
        local barFrame = _G[barName]
        if barFrame and not barFrame._MABFMouseoverHooked then
            barFrame:EnableMouse(true)

            barFrame:HookScript("OnEnter", function()
                UpdateManagedBarAlpha(barFrame, barName)
            end)
            barFrame:HookScript("OnLeave", function()
                UpdateManagedBarAlpha(barFrame, barName)
            end)

            for i = 1, 12 do
                local button = _G[barName .. "Button" .. i]
                if button and not button._MABFMouseoverHooked then
                    button:EnableMouse(true)
                    button:HookScript("OnEnter", function()
                        UpdateManagedBarAlpha(barFrame, barName)
                    end)
                    button:HookScript("OnLeave", function()
                        UpdateManagedBarAlpha(barFrame, barName)
                    end)
                    button._MABFMouseoverHooked = true
                end
            end

            barFrame._MABFMouseoverHooked = true
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

    for _, barName in ipairs(mouseoverManagedBars) do
        local barFrame = _G[barName]
        if barFrame then
            UpdateManagedBarAlpha(barFrame, barName)
        end
    end
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

    -- Mirror MattSimpleTweaks behavior: when enabled, invert the bar growth
    -- direction once per session/login.
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

--------------------------------------------------------------------------------
-- Slash Commands  (/kb, /rl, /edit, /pull)
--------------------------------------------------------------------------------

local function UnregisterSlashCommand(name)
    local i = 1
    while _G["SLASH_" .. name .. i] do
        _G["SLASH_" .. name .. i] = nil
        i = i + 1
    end
    hash_SlashCmdList["/" .. name] = nil
    SlashCmdList[name] = nil
end

function MABF:SetupSlashCommands()
    local db = MattActionBarFontDB

    -- Keybind Mode (/kb)
    if db.enableQuickBind then
        SLASH_QUICKBIND1 = "/kb"
        SlashCmdList["QUICKBIND"] = function()
            if QuickKeybindFrame then
                QuickKeybindFrame:Show()
            end
        end
    else
        UnregisterSlashCommand("QUICKBIND")
    end

    -- Reload UI (/rl)
    if db.enableReloadAlias then
        SLASH_RELOADUI1 = "/rl"
        SlashCmdList["RELOADUI"] = function() ReloadUI() end
    else
        UnregisterSlashCommand("RELOADUI")
    end

    -- Edit Mode (/edit)
    if db.enableEditModeAlias then
        SLASH_EDITMODE1 = "/edit"
        SlashCmdList["EDITMODE"] = function()
            if EditModeManagerFrame then
                EditModeManagerFrame:Show()
            end
        end
    else
        UnregisterSlashCommand("EDITMODE")
    end

    -- Pull Timer (/pull X)
    if db.enablePullAlias then
        SLASH_PULLCOUNTDOWN1 = "/pull"
        SlashCmdList["PULLCOUNTDOWN"] = function(msg)
            local seconds = tonumber(msg)
            if not seconds or seconds < 1 or seconds > 60 then
                seconds = 10
            end
            C_PartyInfo.DoCountdown(seconds)
        end
    else
        UnregisterSlashCommand("PULLCOUNTDOWN")
    end
end

--------------------------------------------------------------------------------
-- Performance Monitor  (FPS & MS display)
--------------------------------------------------------------------------------

function MABF:SetupPerformanceMonitor()
    if not MattActionBarFontDB.enablePerformanceMonitor then
        self:DisablePerformanceMonitor()
        return
    end

    if self.perfFrame then
        self:ApplyPerfMonitorStyle()
        self.perfFrame:Show()
        return
    end

    local f = CreateFrame("Frame", "MABFPerformanceMonitor", UIParent, "BackdropTemplate")
    f:SetSize(110, 22)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })

    -- Restore saved position or default to top-center
    local pos = MattActionBarFontDB.perfMonitorPos
    if pos then
        f:SetPoint(pos.point, UIParent, pos.relativePoint, pos.xOfs, pos.yOfs)
    else
        f:SetPoint("TOP", UIParent, "TOP", 0, -4)
    end

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER")

    f.text2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text2:SetPoint("TOP", f.text, "BOTTOM", 0, -1)
    f.text2:Hide()

    self.perfFrame = f
    self:ApplyPerfMonitorStyle()

    -- Update every 1 second
    f.elapsed = 0
    f:SetScript("OnUpdate", function(self, dt)
        self.elapsed = self.elapsed + dt
        if self.elapsed >= 1 then
            self.elapsed = 0
            local fps = math.floor(GetFramerate())
            local _, _, latencyHome = GetNetStats()
            local showMS = not MattActionBarFontDB.perfMonitorHideMS
            if MattActionBarFontDB.perfMonitorVertical then
                self.text:SetFormattedText("%d FPS", fps)
                self.text2:SetText(showMS and string.format("%dms", latencyHome) or "")
            else
                if showMS then
                    self.text:SetFormattedText("%d FPS  %dms", fps, latencyHome)
                else
                    self.text:SetFormattedText("%d FPS", fps)
                end
            end
        end
    end)

    -- Shift+LeftClick to drag/move
    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        local point, _, relativePoint, xOfs, yOfs = self:GetPoint()
        MattActionBarFontDB.perfMonitorPos = {
            point = point,
            relativePoint = relativePoint,
            xOfs = xOfs,
            yOfs = yOfs,
        }
    end)

    self.perfFrame = f
end

function MABF:DisablePerformanceMonitor()
    if self.perfFrame then
        self.perfFrame:Hide()
        self.perfFrame:SetScript("OnUpdate", nil)
    end
end

local PERF_COLORS = {
    white  = {1, 1, 1},
    red    = {1, 0.2, 0.2},
    green  = {0, 1, 0},
    yellow = {1, 1, 0},
    blue   = {0.3, 0.6, 1},
}

function MABF:ApplyPerfMonitorStyle()
    local f = self.perfFrame
    if not f then return end

    -- Background opacity
    local alpha = MattActionBarFontDB.perfMonitorBgOpacity or 0.5
    f:SetBackdropColor(0, 0, 0, alpha)
    f:SetBackdropBorderColor(0, 0, 0, math.min(alpha + 0.1, 1))

    -- Text color
    local c = PERF_COLORS[MattActionBarFontDB.perfMonitorColor] or PERF_COLORS.green
    f.text:SetTextColor(c[1], c[2], c[3])
    if f.text2 then
        f.text2:SetTextColor(c[1], c[2], c[3])
    end

    -- Layout: vertical vs horizontal
    local showMS = not MattActionBarFontDB.perfMonitorHideMS

    if MattActionBarFontDB.perfMonitorVertical then
        local h = showMS and 24 or 14
        f:SetSize(50, h)
        f.text:ClearAllPoints()
        if showMS then
            f.text:SetPoint("TOP", f, "TOP", 0, -2)
            f.text2:ClearAllPoints()
            f.text2:SetPoint("TOP", f.text, "BOTTOM", 0, 0)
            f.text2:Show()
        else
            f.text:SetPoint("CENTER")
            f.text2:Hide()
        end
    else
        local w = showMS and 110 or 60
        f:SetSize(w, 22)
        f.text:ClearAllPoints()
        f.text:SetPoint("CENTER")
        if f.text2 then f.text2:Hide() end
    end
end

--------------------------------------------------------------------------------
-- Edit Mode Device Manager
--------------------------------------------------------------------------------

function MABF:SetupEditModeDeviceManager()
    local db = MattActionBarFontDB
    if not db.editMode or not db.editMode.enabled then return end

    -- Load Blizzard_EditMode if needed
    if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        C_AddOns.LoadAddOn("Blizzard_EditMode")
    end

    local function ApplyEDMLayout()
        if not EditModeManagerFrame or not EditModeManagerFrame.GetLayouts then
            C_Timer.After(0.5, ApplyEDMLayout)
            return
        end
        local layouts = EditModeManagerFrame:GetLayouts()
        if not layouts then
            C_Timer.After(0.5, ApplyEDMLayout)
            return
        end
        local desired = db.editMode.presetIndexOnLogin
        if desired and desired > 0 and desired <= #layouts then
            EditModeManagerFrame:SelectLayout(desired, true)
            -- Update status text if visible
            if MABFEDMStatusText then
                MABFEDMStatusText:SetText("Selected: |cff90E4C1" .. layouts[desired].layoutName .. "|r")
            end
            if MABFEDMLayoutDropdown then
                UIDropDownMenu_SetSelectedValue(MABFEDMLayoutDropdown, desired)
                UIDropDownMenu_SetText(MABFEDMLayoutDropdown, layouts[desired].layoutName)
            end
        end
    end

    -- Apply on login
    C_Timer.After(1, ApplyEDMLayout)

    -- Register for layout updates
    if not self._edmEventsRegistered then
        local edmEvents = CreateFrame("Frame")
        edmEvents:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
        edmEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        edmEvents:SetScript("OnEvent", function(_, event)
            if db.editMode and db.editMode.enabled then
                C_Timer.After(0.5, ApplyEDMLayout)
            end
        end)
        self._edmEventsRegistered = true
    end
end

-----------------------------------------------------------
-- Quest Tweaks (Auto Accept / Auto Turn In)
-----------------------------------------------------------
function MABF:SetupQuestTweaks()
    local db = MattActionBarFontDB
    if not db then return end

    if not self._questFrame then
        self._questFrame = CreateFrame("Frame")
    end
    local qf = self._questFrame

    -- Unregister all first, then re-register based on settings
    qf:UnregisterAllEvents()
    qf:SetScript("OnEvent", nil)

    if not db.autoAcceptQuests and not db.autoTurnInQuests then
        return
    end

    local function CanAutoAccept()
        return db.autoAcceptQuests and not IsShiftKeyDown()
    end
    local function CanAutoTurnIn()
        return db.autoTurnInQuests and not IsShiftKeyDown()
    end

    qf:RegisterEvent("QUEST_DETAIL")
    qf:RegisterEvent("QUEST_PROGRESS")
    qf:RegisterEvent("QUEST_COMPLETE")
    qf:RegisterEvent("QUEST_GREETING")
    qf:RegisterEvent("GOSSIP_SHOW")

    qf:SetScript("OnEvent", function(_, event)
        if event == "QUEST_DETAIL" then
            if CanAutoAccept() then AcceptQuest() end
        elseif event == "QUEST_PROGRESS" then
            if CanAutoTurnIn() and IsQuestCompletable() then CompleteQuest() end
        elseif event == "QUEST_COMPLETE" then
            if CanAutoTurnIn() then
                local numChoices = GetNumQuestChoices() or 0
                if numChoices == 0 then GetQuestReward(1) end
            end
        elseif event == "QUEST_GREETING" then
            if CanAutoTurnIn() then
                local activeQuests = GetNumActiveQuests() or 0
                for index = 1, activeQuests do
                    local _, isComplete = GetActiveTitle(index)
                    if isComplete then SelectActiveQuest(index) return end
                end
            end
            if CanAutoAccept() then
                local availableQuests = GetNumAvailableQuests() or 0
                if availableQuests > 0 then SelectAvailableQuest(1) end
            end
        elseif event == "GOSSIP_SHOW" then
            if not C_GossipInfo then return end
            if CanAutoTurnIn() then
                local activeQuests = C_GossipInfo.GetActiveQuests and C_GossipInfo.GetActiveQuests() or nil
                if activeQuests then
                    for _, qi in ipairs(activeQuests) do
                        if qi.isComplete and qi.questID then
                            C_GossipInfo.SelectActiveQuest(qi.questID) return
                        end
                    end
                end
            end
            if CanAutoAccept() then
                local availableQuests = C_GossipInfo.GetAvailableQuests and C_GossipInfo.GetAvailableQuests() or nil
                if availableQuests then
                    for _, qi in ipairs(availableQuests) do
                        if qi.questID then C_GossipInfo.SelectAvailableQuest(qi.questID) return end
                    end
                end
            end
        end
    end)
end

-----------------------------------------------------------
-- Merchant Tweaks (Auto Repair + Auto Sell Junk)
-----------------------------------------------------------
do
    local merchantFrame

    local function FormatMoney(amount)
        if amount and amount > 0 and GetCoinTextureString then
            return GetCoinTextureString(amount)
        end
        return "0"
    end

    local function TryAutoRepair()
        local db = MattActionBarFontDB
        if not db or not db.enableAutoRepair then return end
        if not CanMerchantRepair or not CanMerchantRepair() then return end

        local repairCost, canRepair = GetRepairAllCost()
        if not canRepair or not repairCost or repairCost <= 0 then return end

        local fundingSource = db.autoRepairFundingSource or "GUILD"

        if fundingSource == "GUILD" then
            if IsInGuild and IsInGuild() and CanGuildBankRepair and CanGuildBankRepair() then
                local guildMoney = GetGuildBankMoney and GetGuildBankMoney() or 0
                local withdrawLimit = GetGuildBankWithdrawMoney and GetGuildBankWithdrawMoney() or 0
                if withdrawLimit == -1 then withdrawLimit = guildMoney end
                local usableGuildMoney = math.min(guildMoney or 0, withdrawLimit or 0)
                if usableGuildMoney >= repairCost then
                    RepairAllItems(true)
                    print("|cFF00FF00MABF|r: Repaired using guild funds (" .. FormatMoney(repairCost) .. ").")
                    return
                end
            end
        end

        local playerMoney = GetMoney and GetMoney() or 0
        if playerMoney >= repairCost then
            RepairAllItems(false)
            print("|cFF00FF00MABF|r: Repaired all items (" .. FormatMoney(repairCost) .. ").")
        else
            print("|cFF00FF00MABF|r: Not enough gold to repair (need " .. FormatMoney(repairCost) .. ").")
        end
    end

    local function TryAutoSellJunk()
        local db = MattActionBarFontDB
        if not db or not db.enableAutoSellJunk then return end
        if not C_Container or not C_Container.GetContainerNumSlots or not C_Container.GetContainerItemInfo then return end

        local totalValue = 0
        local soldCount = 0
        local maxBag = NUM_TOTAL_EQUIPPED_BAG_SLOTS or 4

        for bag = 0, maxBag do
            local numSlots = C_Container.GetContainerNumSlots(bag)
            for slot = numSlots, 1, -1 do
                local itemInfo = C_Container.GetContainerItemInfo(bag, slot)
                if itemInfo and itemInfo.quality == Enum.ItemQuality.Poor and not itemInfo.isLocked then
                    local _, _, _, _, _, _, _, _, _, _, sellPrice = C_Item.GetItemInfo(itemInfo.hyperlink)
                    if sellPrice and sellPrice > 0 then
                        local stackCount = itemInfo.stackCount or 1
                        totalValue = totalValue + (sellPrice * stackCount)
                        soldCount = soldCount + 1
                        C_Container.UseContainerItem(bag, slot)
                    end
                end
            end
        end

        if soldCount > 0 then
            print("|cFF00FF00MABF|r: Sold " .. soldCount .. " junk item(s) for " .. FormatMoney(totalValue) .. ".")
        end
    end

    function MABF:SetupMerchantTweaks()
        if merchantFrame then
            merchantFrame:UnregisterAllEvents()
            merchantFrame:SetScript("OnEvent", nil)
        end

        local db = MattActionBarFontDB
        if not db then return end
        if not db.enableAutoRepair and not db.enableAutoSellJunk then return end

        if not merchantFrame then
            merchantFrame = CreateFrame("Frame")
        end
        merchantFrame:RegisterEvent("MERCHANT_SHOW")
        merchantFrame:SetScript("OnEvent", function()
            TryAutoRepair()
            TryAutoSellJunk()
        end)
    end
end

-----------------------------------------------------------
-- Bag Item Levels
-----------------------------------------------------------
do
    local _SCANNER = "MABF_ScannerTooltip"
    local Scanner = _G[_SCANNER] or CreateFrame("GameTooltip", _SCANNER, WorldFrame, "GameTooltipTemplate")
    local S_ILVL = "^" .. string.gsub(ITEM_LEVEL, "%%d", "(%%d+)")
    local S_SLOTS = "^" .. (string.gsub(string.gsub(CONTAINER_SLOTS, "%%([%d%$]-)d", "(%%d+)"), "%%([%d%$]-)s", "%.+"))
    local Cache = {}
    local colors = {
        [0] = {157/255,157/255,157/255}, [1] = {240/255,240/255,240/255},
        [2] = {30/255,178/255,0/255}, [3] = {0/255,112/255,221/255},
        [4] = {163/255,53/255,238/255}, [5] = {225/255,96/255,0/255},
        [6] = {229/255,204/255,127/255}, [7] = {79/255,196/255,225/255},
        [8] = {79/255,196/255,225/255},
    }
    local C_Container_GetContainerItemInfo = C_Container and C_Container.GetContainerItemInfo
    local C_TooltipInfo = C_TooltipInfo
    local GetItemInfo = C_Item and C_Item.GetItemInfo or GetItemInfo
    local hooksApplied = false

    local function ClearItemLevelText(button)
        local cache = Cache[button]
        if cache and cache.ilvl then cache.ilvl:SetText("") end
        local upgrade = button.UpgradeIcon
        if upgrade and upgrade.mabfMoved then
            upgrade:ClearAllPoints()
            upgrade:SetPoint("TOPLEFT", 0, 0)
            upgrade.mabfMoved = nil
        end
    end

    local function ClearAllVisible()
        for i = 1, NUM_CONTAINER_FRAMES do
            local frame = _G["ContainerFrame"..i]
            if frame and frame:IsShown() then
                local name = frame:GetName()
                local id = 1
                local button = _G[name.."Item"..id]
                while button do ClearItemLevelText(button); id = id + 1; button = _G[name.."Item"..id] end
            end
        end
        if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
            if _G.ContainerFrameCombinedBags.EnumerateValidItems then
                for _,button in _G.ContainerFrameCombinedBags:EnumerateValidItems() do ClearItemLevelText(button) end
            elseif _G.ContainerFrameCombinedBags.Items then
                for _,button in ipairs(_G.ContainerFrameCombinedBags.Items) do ClearItemLevelText(button) end
            end
        end
        if _G.BankFrame and _G.BankFrame:IsShown() then
            if _G.BankSlotsFrame and NUM_BANKGENERIC_SLOTS then
                for id = 1, NUM_BANKGENERIC_SLOTS do
                    local button = _G.BankSlotsFrame["Item"..id]
                    if button and not button.isBag then ClearItemLevelText(button) end
                end
            elseif _G.BankFrame.BankPanel and _G.BankFrame.BankPanel.EnumerateValidItems then
                for button in _G.BankFrame.BankPanel:EnumerateValidItems() do ClearItemLevelText(button) end
            end
        end
    end

    local function UpdateButton(button, bag, slot)
        if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then
            ClearItemLevelText(button); return
        end
        local message, rarity, itemLink
        local r, g, b = 240/255, 240/255, 240/255
        if C_Container_GetContainerItemInfo then
            local ci = C_Container_GetContainerItemInfo(bag, slot)
            if ci then itemLink = ci.hyperlink end
        else
            local _, _, _, _, _, _, il = GetContainerItemInfo(bag, slot)
            itemLink = il
        end
        if itemLink then
            local _, _, itemQuality, itemLevel, _, _, _, _, itemEquipLoc = GetItemInfo(itemLink)
            if itemEquipLoc == "INVTYPE_BAG" then
                if C_TooltipInfo then
                    local td = C_TooltipInfo.GetBagItem(bag, slot)
                    if td and td.lines then
                        for i = 3,4 do
                            local msg = td.lines[i] and td.lines[i].leftText
                            if not msg then break end
                            local ns = string.match(msg, S_SLOTS)
                            if ns then ns = tonumber(ns); if ns and ns > 0 then message = ns end; break end
                        end
                    end
                end
            elseif itemQuality and itemQuality > 0 and itemEquipLoc and _G[itemEquipLoc]
                and itemEquipLoc ~= "INVTYPE_NON_EQUIP" and itemEquipLoc ~= "INVTYPE_NON_EQUIP_IGNORE"
                and itemEquipLoc ~= "INVTYPE_TABARD" and itemEquipLoc ~= "INVTYPE_AMMO" and itemEquipLoc ~= "INVTYPE_QUIVER" then
                local tipLevel
                if C_TooltipInfo then
                    local td = C_TooltipInfo.GetBagItem(bag, slot)
                    if td and td.lines then
                        for i = 2,3 do
                            local msg = td.lines[i] and td.lines[i].leftText
                            if not msg then break end
                            local il = string.match(msg, S_ILVL)
                            if il then il = tonumber(il); if il and il > 0 then tipLevel = il end; break end
                        end
                    end
                end
                tipLevel = tonumber(tipLevel or GetDetailedItemLevelInfo(itemLink) or itemLevel)
                if tipLevel and tipLevel > 1 then message = tipLevel; rarity = itemQuality end
            end
        end
        if message and message > 1 then
            local container = Cache[button]
            if not container then
                container = CreateFrame("Frame", nil, button)
                container:SetFrameLevel(button:GetFrameLevel() + 5)
                container:SetAllPoints()
                Cache[button] = container
            end
            if not container.ilvl then
                container.ilvl = container:CreateFontString(nil, "OVERLAY")
                container.ilvl:SetDrawLayer("ARTWORK", 1)
                container.ilvl:SetPoint("TOPLEFT", 2, -2)
                container.ilvl:SetFontObject(NumberFont_Outline_Med or NumberFontNormal)
                container.ilvl:SetShadowOffset(1, -1)
                container.ilvl:SetShadowColor(0, 0, 0, .5)
            end
            local upgrade = button.UpgradeIcon
            if upgrade and not upgrade.mabfMoved then
                upgrade:ClearAllPoints()
                upgrade:SetPoint("BOTTOMRIGHT", 2, 0)
                upgrade.mabfMoved = true
            end
            if rarity and colors[rarity] then
                local col = colors[rarity]; r, g, b = col[1], col[2], col[3]
            end
            container.ilvl:SetTextColor(r, g, b)
            container.ilvl:SetText(message)
        else
            ClearItemLevelText(button)
        end
    end

    local function UpdateContainer(frame)
        if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then return end
        local bag = frame:GetID()
        local name = frame:GetName()
        local id = 1
        local button = _G[name.."Item"..id]
        while button do
            if button.hasItem then UpdateButton(button, bag, button:GetID()) else ClearItemLevelText(button) end
            id = id + 1; button = _G[name.."Item"..id]
        end
    end

    local function UpdateCombinedContainer(frame)
        if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then return end
        if frame.EnumerateValidItems then
            for _,button in frame:EnumerateValidItems() do
                if button.hasItem then UpdateButton(button, button:GetBagID(), button:GetID()) else ClearItemLevelText(button) end
            end
        elseif frame.Items then
            for _,button in ipairs(frame.Items) do
                if button.hasItem then UpdateButton(button, button:GetBagID(), button:GetID()) else ClearItemLevelText(button) end
            end
        end
    end

    local function UpdateBank()
        if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then return end
        if _G.BankSlotsFrame and NUM_BANKGENERIC_SLOTS then
            local bag = _G.BankSlotsFrame:GetID()
            for id = 1, NUM_BANKGENERIC_SLOTS do
                local button = _G.BankSlotsFrame["Item"..id]
                if button and not button.isBag then
                    if button.hasItem then UpdateButton(button, bag, button:GetID()) else ClearItemLevelText(button) end
                end
            end
        elseif _G.BankFrame and _G.BankFrame.BankPanel and _G.BankFrame.BankPanel.EnumerateValidItems then
            for button in _G.BankFrame.BankPanel:EnumerateValidItems() do
                local bankTabID = button:GetBankTabID()
                local slotID = button:GetContainerSlotID()
                local info = C_Container_GetContainerItemInfo and C_Container_GetContainerItemInfo(bankTabID, slotID)
                if info then UpdateButton(button, bankTabID, slotID) else ClearItemLevelText(button) end
            end
        end
    end

    local function UpdateAllVisible()
        for i = 1, NUM_CONTAINER_FRAMES do
            local frame = _G["ContainerFrame"..i]
            if frame and frame:IsShown() then UpdateContainer(frame) end
        end
        if _G.ContainerFrameCombinedBags and _G.ContainerFrameCombinedBags:IsShown() then
            UpdateCombinedContainer(_G.ContainerFrameCombinedBags)
        end
        if _G.BankFrame and _G.BankFrame:IsShown() then UpdateBank() end
    end

    local bagEventFrame = CreateFrame("Frame")

    function MABF:EnableBagItemLevels()
        if not hooksApplied then
            if _G.ContainerFrame_Update then
                hooksecurefunc("ContainerFrame_Update", UpdateContainer)
            else
                local id = 1
                local frame = _G["ContainerFrame"..id]
                while frame and frame.Update do
                    hooksecurefunc(frame, "Update", UpdateContainer)
                    id = id + 1; frame = _G["ContainerFrame"..id]
                end
            end
            if _G.ContainerFrameCombinedBags then
                hooksecurefunc(_G.ContainerFrameCombinedBags, "Update", UpdateCombinedContainer)
            end
            if _G.BankFrame_UpdateItems then
                hooksecurefunc("BankFrame_UpdateItems", UpdateBank)
            elseif _G.BankFrameItemButton_UpdateLocked then
                hooksecurefunc("BankFrameItemButton_UpdateLocked", function(button)
                    if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then ClearItemLevelText(button); return end
                    if button and not button.isBag and _G.BankSlotsFrame then
                        UpdateButton(button, _G.BankSlotsFrame:GetID(), button:GetID())
                    else ClearItemLevelText(button) end
                end)
            end
            if BankPanelItemButtonMixin and BankPanelItemButtonMixin.Refresh then
                hooksecurefunc(BankPanelItemButtonMixin, "Refresh", function(button)
                    if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then ClearItemLevelText(button); return end
                    local bankTabID = button.GetBankTabID and button:GetBankTabID()
                    local slotID = button.GetContainerSlotID and button:GetContainerSlotID()
                    if bankTabID and slotID then UpdateButton(button, bankTabID, slotID) end
                end)
            end
            hooksApplied = true
        end
        bagEventFrame:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
        bagEventFrame:SetScript("OnEvent", function(_, _, slot)
            if not MattActionBarFontDB or not MattActionBarFontDB.enableBagItemLevels then return end
            if NUM_BANKGENERIC_SLOTS and slot and slot <= NUM_BANKGENERIC_SLOTS and _G.BankSlotsFrame then
                local button = _G.BankSlotsFrame["Item"..slot]
                if button and not button.isBag then UpdateButton(button, _G.BankSlotsFrame:GetID(), button:GetID()) end
            elseif _G.BankFrame and _G.BankFrame:IsShown() then
                UpdateBank()
            end
        end)
        UpdateAllVisible()
    end

    function MABF:DisableBagItemLevels()
        bagEventFrame:UnregisterAllEvents()
        bagEventFrame:SetScript("OnEvent", nil)
        ClearAllVisible()
    end
end

-- Expose the MABF table globally for access by other modules
_G.MABF = MABF

return MABF