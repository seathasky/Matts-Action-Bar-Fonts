local addonName, MABF = ...

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

    if db.enableQuickBind then
        SLASH_QUICKBIND1 = "/kb"
        SlashCmdList["QUICKBIND"] = function()
            if not QuickKeybindFrame then
                print("|cFF00FF00MABF|r: Quick Keybind Mode is not available.")
                return
            end

            if InCombatLockdown and InCombatLockdown() then
                self._kbOpenAfterCombat = true
                if not self._kbRegenFrame then
                    self._kbRegenFrame = CreateFrame("Frame")
                    self._kbRegenFrame:SetScript("OnEvent", function(frame, event)
                        if event ~= "PLAYER_REGEN_ENABLED" then return end
                        frame:UnregisterEvent("PLAYER_REGEN_ENABLED")
                        if MABF._kbOpenAfterCombat and QuickKeybindFrame and (not InCombatLockdown or not InCombatLockdown()) then
                            MABF._kbOpenAfterCombat = false
                            QuickKeybindFrame:Show()
                            print("|cFF00FF00MABF|r: Entered Keybind Mode after combat.")
                        end
                    end)
                end
                self._kbRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                print("|cFF00FF00MABF|r: Can't open Keybind Mode in combat. It will open when combat ends.")
                return
            end

            QuickKeybindFrame:Show()
        end
    else
        UnregisterSlashCommand("QUICKBIND")
    end

    if db.enableReloadAlias then
        SLASH_RELOADUI1 = "/rl"
        SlashCmdList["RELOADUI"] = function() ReloadUI() end
    else
        UnregisterSlashCommand("RELOADUI")
    end

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
