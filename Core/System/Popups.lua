local addonName, MABF = ...

-----------------------------------------------------------
-- Static Popup Dialog for Reset Settings
-----------------------------------------------------------
StaticPopupDialogs["MABF_RESET_SETTINGS"] = {
    text = "Reset the current profile to the shipped defaults? All characters using this profile are affected. This will reload the UI.",
    button1 = "Reset Profile",
    button2 = "Cancel",
    OnAccept = function()
        local ok, err = MABF:ResetProfile()
        if not ok then print("MattActionBarFont: " .. err) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

StaticPopupDialogs["MABF_PROFILE_ACTION"] = {
    text = "%s",
    button1 = "Confirm",
    button2 = "Cancel",
    OnAccept = function(self, data)
        if not data then return end
        if data.current ~= MABF:GetCurrentProfile() then
            data.complete(false, "The current profile changed. Please try again.")
            return
        end
        local actions = {
            SetProfile = MABF.SetProfile,
            CopyProfile = MABF.CopyProfile,
            ResetProfile = MABF.ResetProfile,
            DeleteProfile = MABF.DeleteProfile,
        }
        local action = actions[data.action]
        if action then data.complete(action(MABF, data.name)) end
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-----------------------------------------------------------
-- Static Popup Dialog for Reload UI
-----------------------------------------------------------
StaticPopupDialogs["MABF_RELOAD_UI"] = {
    text = "A reload is required to apply this change. Reload now?",
    button1 = "Reload UI",
    button2 = "Later",
    OnAccept = function() ReloadUI() end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}
