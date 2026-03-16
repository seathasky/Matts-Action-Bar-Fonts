local addonName, MABF = ...

local function CreateReminderResetBaseButton(name, parent, labelText, bottomOffset)
    local accent = (MABF.GetThemeAccentColor and MABF:GetThemeAccentColor()) or { 1.0, 0.25, 0.25 }

    local btn = CreateFrame("Button", name, parent, "BackdropTemplate")
    btn:SetSize(176, 22)
    btn:SetPoint("BOTTOM", parent, "BOTTOM", 0, bottomOffset)
    btn:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    btn:SetBackdropColor(0.06, 0.06, 0.08, 1)
    btn:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    local txt = btn:CreateFontString(nil, "OVERLAY")
    txt:SetPoint("CENTER", btn, "CENTER", 0, 0)
    txt:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "OUTLINE")
    txt:SetText(labelText)
    txt:SetTextColor(0.9, 0.9, 0.9, 1)

    btn:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.8)
    end)
    btn:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)
    btn:SetScript("OnMouseDown", function(self)
        self:SetBackdropColor(0.04, 0.04, 0.06, 1)
    end)
    btn:SetScript("OnMouseUp", function(self)
        self:SetBackdropColor(0.06, 0.06, 0.08, 1)
    end)

    return btn
end

function MABF:CreateReminderResetButton(name, parent, onClick)
    local btn = CreateReminderResetBaseButton(name, parent, "Reset Position", 12)
    btn:SetScript("OnClick", onClick)
    return btn
end

function MABF:CreateReminderResetSizeButton(name, parent, onClick)
    local btn = CreateReminderResetBaseButton(name, parent, "Reset Size", 38)
    btn:SetScript("OnClick", onClick)
    return btn
end
