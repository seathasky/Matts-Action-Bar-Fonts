-- MABFEvents.lua
local addonName, MABF = ...

-----------------------------------------------------------
-- Event Handling and Slash Command
-----------------------------------------------------------
local HookQuickKeybindFrame
local events = CreateFrame("Frame")
local quickbindReanchorQueued = false

local function QueueQuickbindReanchor()
    if quickbindReanchorQueued then
        return
    end
    quickbindReanchorQueued = true

    local function ReanchorNow()
        if MABF and MABF.UpdateActionBarFontPositions then
            MABF:UpdateActionBarFontPositions()
        end
    end

    C_Timer.After(0, ReanchorNow)
    C_Timer.After(0.05, function()
        ReanchorNow()
        quickbindReanchorQueued = false
    end)
end

events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("UPDATE_BINDINGS")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        MABF:Init()
        MABF:HookPetActionBarUpdates()
    elseif event == "ADDON_LOADED" and arg1 == "Dominos" then
        if Dominos then
            C_Timer.After(1, function()
                MABF:ApplyFontSettings()
                MABF:UpdateFontPositions()
                MABF:UpdateActionBarFontPositions()
                MABF:UpdateMacroText()
                MABF:UpdateSpecificBars()
                MABF:UpdatePetBarFontSettings()
                if MattActionBarFontDB.minimalTheme ~= "blizzard" then
                    MABF:SkinActionBars()
                    MABF:CropAllIcons()
                end
            end)
        end
    elseif event == "PLAYER_LOGIN" then
        HookQuickKeybindFrame()
        MABF:CreateOptionsWindow()
        MABF:ApplyFontSettings()
        MABF:ApplyReverseBarGrowth()
        C_Timer.After(0.5, function()
            MABF:ApplyReverseBarGrowth()
        end)
        MABF:UpdateFontPositions()
        MABF:UpdateActionBarFontPositions()
        MABF:UpdateMacroText()
        MABF:UpdateSpecificBars()
        MABF:UpdatePetBarFontSettings()
        MABF:ApplyObjectiveTrackerScale()
        MABF:ApplyMinimapScale()
        MABF:ApplyStatusBarScale()
        MABF:ApplyHideMicroMenu()
        MABF:ApplyHideBagBar()
        MABF:ApplyPetBarMouseoverFade()
        MABF:ApplyScaleTalkingHead()
        MABF:SetupCursorCircle()
        MABF:SetupSlashCommands()
        MABF:SetupPerformanceMonitor()
        MABF:SetupEditModeDeviceManager()
        MABF:SetupQuestTweaks()
        MABF:SetupMerchantTweaks()
        if MattActionBarFontDB.enableBagItemLevels then
            MABF:EnableBagItemLevels()
        end

        C_Timer.After(0.2, function()
            MABF:ApplyActionBarMouseover()
            if MattActionBarFontDB.mouseoverFade then
                MABF:SetBarsMouseoverState(false)
            end
        end)
        C_Timer.After(1.0, function()
            MABF:ApplyActionBarMouseover()
            if MattActionBarFontDB.mouseoverFade then
                MABF:SetBarsMouseoverState(false)
            end
        end)

        if Dominos then
            print("|cFF00FF00MattActionBarFont|r loaded with |cFFFF8000Dominos|r support! Type /mabf to open options.")
        else
            print("|cFF00FF00MattActionBarFont|r loaded! Type /mabf to open options.")
        end
    elseif event == "UPDATE_BINDINGS" then
        if QuickKeybindFrame and QuickKeybindFrame:IsShown() then

            QueueQuickbindReanchor()
            return
        end
        MABF:ApplyFontSettings()
        MABF:UpdateActionBarFontPositions()
        MABF:UpdateMacroText()
    end
end)


local escBlockFrame = CreateFrame("Frame", "QuickKeybindESCBlock", UIParent)
escBlockFrame:EnableKeyboard(true)
escBlockFrame:SetPropagateKeyboardInput(false)
escBlockFrame:Hide()
escBlockFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        if QuickKeybindFrame and QuickKeybindFrame:IsShown() then
            QuickKeybindFrame:Hide()
        end

        return
    end
end)

-- Shared state for keybind/options interactions.
local blockWoWSettings = false
local lastKBClosedTime = 0
local autoOpenThreshold = 0.2 

HookQuickKeybindFrame = function()
    if not QuickKeybindFrame or QuickKeybindFrame.__MABFEventsHooked then
        return
    end
    QuickKeybindFrame.__MABFEventsHooked = true

    QuickKeybindFrame:HookScript("OnShow", function()
        blockWoWSettings = true
        escBlockFrame:Show()
    end)

    QuickKeybindFrame:HookScript("OnHide", function()
        lastKBClosedTime = GetTime()
        blockWoWSettings = false
        escBlockFrame:Hide()
        MABF:ApplyFontSettings()
        MABF:UpdateActionBarFontPositions()
        MABF:UpdateMacroText()
    end)
end


local function BlockWoWOptionsIfNeeded(self)
    if blockWoWSettings or (GetTime() - lastKBClosedTime < autoOpenThreshold) then
        HideUIPanel(self)
    end
end

if InterfaceOptionsFrame then
    InterfaceOptionsFrame:HookScript("OnShow", BlockWoWOptionsIfNeeded)
end
if SettingsPanel then
    SettingsPanel:HookScript("OnShow", BlockWoWOptionsIfNeeded)
end

HookQuickKeybindFrame()


-- Slash Command registration
SLASH_MABF1 = "/mabf"
SlashCmdList["MABF"] = function(msg)
    local command, param = msg:match("^(%S*)%s*(.*)$")
    if not command or command == "" then
        if MABF.optionsFrame and MABF.optionsFrame:IsShown() then
            MABF.optionsFrame:Hide()
        else
            if MABF.optionsFrame then MABF.optionsFrame:Show() end
        end
    elseif command:lower() == "countsize" then
        local newSize = tonumber(param)
        if newSize then
            if newSize < 8 or newSize > 30 then
                print("Please choose a count font size between 8 and 30")
                return
            end
            MattActionBarFontDB.countFontSize = newSize
            MABF:UpdateSpecificBars()
            MABF:UpdateFontPositions()
            print("MattActionBarFont: All action bar count font sizes set to " .. newSize)
            if MABF.optionsFrame and MABF.optionsFrame:IsShown() then
                local sliderName = MABFCountSizeSlider:GetName()
                _G[sliderName .. "Text"]:SetText("Count Font Size: " .. newSize)
                MABFCountSizeSlider:SetValue(newSize)
            end
        end
    end
end

-- Additional alias for /mabf
SLASH_MST1 = "/mst"
SlashCmdList["MST"] = SlashCmdList["MABF"]
