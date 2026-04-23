local addonName, MABF = ...

-----------------------------------------------------------
-- Static Popup Dialog for Reset Settings
-----------------------------------------------------------
StaticPopupDialogs["MABF_RESET_SETTINGS"] = {
    text = "|cffff0000|cff881111WARNING:|r |cffff0000This will reset ALL settings to default values. This action cannot be undone!|r",
    button1 = "Reset All Settings",
    button2 = "Cancel",
    OnAccept = function()
        MattActionBarFontDB = {}
        MABF:ApplyDefaults()
        ReloadUI()
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
