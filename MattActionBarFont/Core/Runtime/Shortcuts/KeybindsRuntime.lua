local addonName, MABF = ...

local function BlockWoWOptionsIfNeeded(frame)
    if MABF._blockWoWSettings then
        HideUIPanel(frame)
    end
end

local function EnsureKeybindSettingsHooks()
    if MABF._kbOptionsHooksInstalled then return end

    if InterfaceOptionsFrame then
        InterfaceOptionsFrame:HookScript("OnShow", BlockWoWOptionsIfNeeded)
    end
    if SettingsPanel then
        SettingsPanel:HookScript("OnShow", BlockWoWOptionsIfNeeded)
    end

    MABF._kbOptionsHooksInstalled = true
end

function MABF:RunKeybindShortcut()
    EnsureKeybindSettingsHooks()

    local wasOptionsOpen = MABFOptionsFrame and MABFOptionsFrame:IsShown()
    if wasOptionsOpen then
        MABFOptionsFrame:Hide()
    end

    ChatFrame1EditBox:SetText("/kb")
    ChatEdit_SendText(ChatFrame1EditBox)
    MABF._blockWoWSettings = true

    local watcherFrame = CreateFrame("Frame")
    watcherFrame:SetScript("OnUpdate", function(self)
        if QuickKeybindFrame and not QuickKeybindFrame:IsShown() then
            self:SetScript("OnUpdate", nil)
            self:Hide()
            if InterfaceOptionsFrame then HideUIPanel(InterfaceOptionsFrame) end
            if SettingsPanel then SettingsPanel:Hide() end
            if wasOptionsOpen then
                MABFOptionsFrame:Show()
            end
            C_Timer.After(0.5, function()
                MABF._blockWoWSettings = false
            end)
        end
    end)
end
