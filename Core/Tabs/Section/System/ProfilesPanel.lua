local addonName, MABF = ...

-- Compact profile controls inside System > System.
function MABF:BuildProfilesPanel(page, anchor, CreateMinimalDropdown)
    local accent = self:GetThemeAccentColor()
    local font = self:GetUIFontPath()
    local panel = CreateFrame("Frame", nil, page)
    panel:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 2, -16)
    panel:SetSize(300, 280)

    local function Label(text, x, y, width)
        local label = panel:CreateFontString(nil, "OVERLAY")
        label:SetFont(font, 10, "")
        label:SetTextColor(0.8, 0.8, 0.8, 1)
        label:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        label:SetWidth(width or 300)
        label:SetJustifyH("LEFT")
        label:SetText(text)
        return label
    end

    local title = Label("Profiles", 0, 0)
    title:SetTextColor(accent[1], accent[2], accent[3], 1)
    title:SetFont(font, 11, "")
    local description = Label("Each character starts with its own profile.\nShared profiles share changes. Applying settings reloads UI.", 0, -20)
    description:SetFont(font, 9, "")
    description:SetHeight(30)

    local currentLabel = Label("Current profile", 0, -54)
    local current = CreateMinimalDropdown(panel, 300, 7)
    current:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -70)

    local nameBox = CreateFrame("EditBox", nil, panel, "BackdropTemplate")
    nameBox:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, -114)
    nameBox:SetSize(194, 22)
    nameBox:SetAutoFocus(false)
    nameBox:SetMaxBytes(80)
    nameBox:SetFont(font, 10, "")
    nameBox:SetTextColor(0.95, 0.95, 0.95, 1)
    nameBox:SetTextInsets(6, 6, 0, 0)
    nameBox:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    nameBox:SetBackdropColor(0.06, 0.06, 0.08, 1)
    nameBox:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    nameBox:SetScript("OnEscapePressed", nameBox.ClearFocus)
    Label("New name (new profiles use shipped defaults)", 0, -98)

    local status = Label("", 0, -248)
    status:SetHeight(28)
    status:SetFont(font, 9, "")
    status:SetTextColor(1, 0.4, 0.4, 1)

    local function Report(ok, err)
        status:SetText(ok and "" or (err or "Profile action failed."))
        if not ok then print("MattActionBarFont: " .. (err or "Profile action failed.")) end
        return ok
    end

    local function Button(text, x, y, width, onClick)
        local button = CreateFrame("Button", nil, panel, "BackdropTemplate")
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
        button:SetSize(width, 22)
        local textLabel = button:CreateFontString(nil, "OVERLAY")
        textLabel:SetPoint("CENTER")
        button:SetFontString(textLabel)
        button:SetText(text)
        MABF:StyleMinimalButton(button)
        button:SetScript("OnClick", onClick)
        return button
    end

    local copyFrom = CreateMinimalDropdown(panel, 224, 7)
    copyFrom:SetPoint("TOPLEFT", panel, "TOPLEFT", 76, -180)
    Label("Copy from", 0, -185, 72)
    local delete = CreateMinimalDropdown(panel, 224, 7)
    delete:SetPoint("TOPLEFT", panel, "TOPLEFT", 76, -214)
    Label("Delete", 0, -219, 72)

    local rename
    local function Refresh()
        local selected = MABF:GetCurrentProfile()
        local existing, copies, deletable = {}, {}, {}
        for _, name in ipairs(MABF:GetProfiles()) do
            local option = { value = name, label = MABF:GetProfileDisplayName(name) }
            existing[#existing + 1] = option
            if name ~= selected then
                copies[#copies + 1] = option
                if name ~= "Default" then deletable[#deletable + 1] = option end
            end
        end
        currentLabel:SetText("Current profile (" .. MABF:GetProfileUsage(selected) .. " character(s))")
        current:SetOptions(existing)
        current:SetSelectedValue(selected)
        copyFrom:SetOptions(copies)
        copyFrom:SetSelectedValue(nil)
        delete:SetOptions(deletable)
        delete:SetSelectedValue(nil)
        if rename then rename:SetEnabled(selected ~= "Default") end
    end

    local function Confirm(action, name, message)
        nameBox:ClearFocus()
        StaticPopup_Show("MABF_PROFILE_ACTION", message, nil, {
            action = action,
            name = name,
            current = MABF:GetCurrentProfile(),
            complete = function(ok, err)
                Report(ok, err)
                Refresh()
            end,
        })
        Refresh()
    end

    current:SetOnSelect(function(name)
        if name == MABF:GetCurrentProfile() then return end
        Confirm("SetProfile", name, "Use profile '" .. MABF:GetProfileDisplayName(name) .. "' for this character?\nCharacters using this profile share changes.\n\nThis will reload the UI.")
    end)
    copyFrom:SetOnSelect(function(name)
        Confirm("CopyProfile", name, "Replace all settings in '" .. MABF:GetProfileDisplayName(MABF:GetCurrentProfile()) .. "' with a copy of '" .. MABF:GetProfileDisplayName(name) .. "'?\nThis affects all characters using the current profile.\n\nThis will reload the UI.")
    end)
    delete:SetOnSelect(function(name)
        Confirm("DeleteProfile", name, "Delete profile '" .. MABF:GetProfileDisplayName(name) .. "'?\n" .. MABF:GetProfileUsage(name) .. " character(s) use it and will get a new personal profile on next login.\n\nThis cannot be undone.")
    end)

    local function Create()
        nameBox:ClearFocus()
        Report(MABF:CreateProfile(nameBox:GetText()))
    end
    Button("Create & use", 202, -114, 98, Create)
    nameBox:SetScript("OnEnterPressed", Create)
    rename = Button("Rename current", 0, -146, 146, function()
        nameBox:ClearFocus()
        if Report(MABF:RenameProfile(nameBox:GetText())) then
            nameBox:SetText("")
            Refresh()
        end
    end)
    Button("Reset current", 154, -146, 146, function()
        Confirm("ResetProfile", nil, "Reset all settings in '" .. MABF:GetProfileDisplayName(MABF:GetCurrentProfile()) .. "' to the shipped defaults?\nThis affects all characters using this profile.\n\nThis will reload the UI.")
    end)
    panel:SetScript("OnShow", Refresh)
    panel:SetScript("OnHide", function() nameBox:ClearFocus() end)
    Refresh()
    return panel
end
