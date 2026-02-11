-- MABFEvents.lua
local addonName, MABF = ...

-----------------------------------------------------------
-- Event Handling and Slash Command
-----------------------------------------------------------
local events = CreateFrame("Frame")
events:RegisterEvent("ADDON_LOADED")
events:RegisterEvent("PLAYER_LOGIN")
events:RegisterEvent("ACTIONBAR_SLOT_CHANGED")
events:RegisterEvent("UPDATE_BINDINGS")
events:SetScript("OnEvent", function(self, event, arg1)
    if event == "ADDON_LOADED" and arg1 == addonName then
        MABF:Init()
    elseif event == "ADDON_LOADED" and arg1 == "Dominos" then
        -- Dominos loaded, hook into its callbacks for bar updates
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
        MABF:SetupSlashCommands()
        MABF:SetupPerformanceMonitor()
        MABF:SetupEditModeDeviceManager()
        MABF:SetupQuestTweaks()
        MABF:SetupMerchantTweaks()
        if MattActionBarFontDB.enableBagItemLevels then
            MABF:EnableBagItemLevels()
        end

        -- Ensure mouseover hooks & initial alpha are applied after a short delay
        -- (some bar frames may not be available immediately on PLAYER_LOGIN)
        C_Timer.After(0.2, function()
            MABF:ApplyActionBarMouseover()
            if MattActionBarFontDB.mouseoverFade then
                MABF:SetBarsMouseoverState(false)
            end
        end)
        -- Retry once after 1s to handle late-initialized bar frames
        C_Timer.After(1.0, function()
            MABF:ApplyActionBarMouseover()
            if MattActionBarFontDB.mouseoverFade then
                MABF:SetBarsMouseoverState(false)
            end
        end)

        -- Detect Dominos and notify user
        if Dominos then
            print("|cFF00FF00MattActionBarFont|r loaded with |cFFFF8000Dominos|r support! Type /mabf to open options.")
        else
            print("|cFF00FF00MattActionBarFont|r loaded! Type /mabf to open options.")
        end
    elseif event == "ACTIONBAR_SLOT_CHANGED" then
        -- No action needed to preserve settings.
    elseif event == "UPDATE_BINDINGS" then
        C_Timer.After(0.2, function()
            MABF:ApplyFontSettings()
            MABF:UpdateActionBarFontPositions()
            MABF:UpdateMacroText()
        end)
    end
end)

-- Hook QuickKeybindFrame OnHide to reapply settings when keybind mode closes
if QuickKeybindFrame then
    QuickKeybindFrame:HookScript("OnHide", function()
        MABF:ApplyFontSettings()
        MABF:UpdateActionBarFontPositions()
        MABF:UpdateMacroText()
    end)
end

-- Hook QuickKeybindFrame OnShow to reapply custom positions
if QuickKeybindFrame then
    QuickKeybindFrame:HookScript("OnShow", function()
        for i = 1, 5 do
            C_Timer.After(i * 0.1, function()
                MABF:UpdateActionBarFontPositions()
            end)
        end
    end)
end

-- Ensure blockWoWSettings is declared in a shared scope
blockWoWSettings = false

-- Create a temporary frame to intercept the ESC key while keybind mode is active.
local escBlockFrame = CreateFrame("Frame", "QuickKeybindESCBlock", UIParent)
escBlockFrame:EnableKeyboard(true)
escBlockFrame:SetPropagateKeyboardInput(false)
escBlockFrame:Hide()
escBlockFrame:SetScript("OnKeyDown", function(self, key)
    if key == "ESCAPE" then
        if QuickKeybindFrame and QuickKeybindFrame:IsShown() then
            QuickKeybindFrame:Hide()
        end
        -- Consume the key press so it doesn't propagate further.
        return
    end
end)

-- Global/shared variables
blockWoWSettings = false
lastKBClosedTime = 0
local autoOpenThreshold = 0.2  -- in seconds; adjust if needed

-- Modified hook to block options if we're in keybind mode
-- or if keybind mode was closed very recently.
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

-- Slash command for /kb
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        SLASH_QUICKBIND1 = "/kb"
        SlashCmdList.QUICKBIND = function()
            if QuickKeybindFrame then
                blockWoWSettings = true
                QuickKeybindFrame:Show()
                
                -- Hook the OnHide event to record the closing time and clear the block flag.
                if not QuickKeybindFrame.__KBOnHideHooked then
                    QuickKeybindFrame:HookScript("OnHide", function(self)
                        lastKBClosedTime = GetTime()
                        blockWoWSettings = false
                    end)
                    QuickKeybindFrame.__KBOnHideHooked = true
                end
            else
                print("Quick Keybind Mode is not available.")
            end
        end
    end
end)



-- Reload UI w/ /rl
local frame = CreateFrame("Frame")
frame:RegisterEvent("PLAYER_LOGIN")

frame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_LOGIN" then
        SLASH_RELOADUI1 = "/rl"
        SlashCmdList.RELOADUI = function()
            ReloadUI()
        end
    end
end)


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
        else
        end
    else
    end
end

-- Secret alias for /mabf
SLASH_MST1 = "/mst"
SlashCmdList["MST"] = SlashCmdList["MABF"]

--[[
---
--Game Nenu Button (DISABLED)
---
local function CreateMyMabfButton()
    if not GameMenuFrame then return end

    if not GameMenuButtonMyMabf then
        local btn = CreateFrame("Button", "GameMenuButtonMyMabf", GameMenuFrame, "GameMenuButtonTemplate")
        btn:SetText("MABF Settings")
        btn:SetScript("OnClick", function()
            if SlashCmdList and SlashCmdList["MABF"] then
                SlashCmdList["MABF"]("")
            else
                print("No /mabf slash command found!")
            end
            HideUIPanel(GameMenuFrame)
        end)
        btn:SetWidth(192)
        btn:Show()
        btn:ClearAllPoints()
        btn:SetPoint("TOP", GameMenuFrame, "TOP", 0, -119)

        -- Create a border overlay frame on top of the button.
        local overlay = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        overlay:SetAllPoints(btn)
        overlay:SetFrameLevel(btn:GetFrameLevel() + 1)  -- Make sure it's on top of the button textures.
        overlay:SetBackdrop({
            edgeFile = "Interface\\Buttons\\WHITE8X8",  -- A simple white square texture.
            edgeSize = 2,
            bgFile = nil,  -- No background, just a border.
        })
        overlay:SetBackdropBorderColor(0, 1, 0, 1)  -- Full green border.

        -- Optional: if you want the border to be persistent and not affect mouse events:
        overlay:EnableMouse(false)
    end
end

local f = CreateFrame("Frame")
f:RegisterEvent("PLAYER_LOGIN")
f:SetScript("OnEvent", function(self, event)
    if event == "PLAYER_LOGIN" then
        CreateMyMabfButton()
    end
end)
]]



