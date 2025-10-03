-- MABFFonts.lua
local addonName, MABF = ...

-- Helper function to handle text conversion
local function FormatText(text)
    if not text then return "" end
    return string.upper(text)
end

-----------------------------------------------------------
-- Font Application & Position Updates
-----------------------------------------------------------
function MABF:ApplyFontSettings()
    if not self.availableFonts then
        self.availableFonts = self:ScanCustomFonts()
    end
    local fontPath = self.availableFonts[MattActionBarFontDB.fontFamily]
    if not fontPath then
        return
    end

    local function SafeSetFont(fontString, isHotKey, button)
        if fontString and fontString.SetFont then
            if isHotKey then
                local hotKeyText = FormatText(fontString:GetText() or "") -- Convert to uppercase
                if hotKeyText == "-" then
                    -- do nothing
                elseif #hotKeyText == 2 and (hotKeyText:sub(1,1) == "A" or hotKeyText:sub(1,1) == "S" or hotKeyText:sub(1,1) == "C") and hotKeyText:sub(2,2) == "-" then
                    -- do nothing
                elseif #hotKeyText == 3 and (hotKeyText:sub(1,1) == "A" or hotKeyText:sub(1,1) == "S" or hotKeyText:sub(1,1) == "C") and hotKeyText:sub(2,2) == "-" then
                    hotKeyText = hotKeyText:sub(1,1) .. hotKeyText:sub(3,3)
                elseif #hotKeyText > 3 then
                    hotKeyText = hotKeyText:sub(1,3)
                end
                fontString:SetText(FormatText(hotKeyText))
                fontString:SetFont(fontPath, MattActionBarFontDB.fontSize, "OUTLINE")
                fontString:SetTextColor(1, 1, 1, 1)
            else
                fontString:SetFont(fontPath, MattActionBarFontDB.fontSize * 0.5, "OUTLINE")
                fontString:SetTextColor(1, 1, 1, 1)
            end
            fontString:SetWidth(0)
            fontString:SetHeight(0)
        end
    end

    local function UpdateActionButton(button)
        if not button then return end
        for _, region in pairs({ button:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                if region == button.HotKey then
                    SafeSetFont(region, true, button)
                    if not region._MABF_Hooked then
                        region:HookScript("OnTextChanged", function(self)
                            local fPath = MABF.availableFonts and MABF.availableFonts[MattActionBarFontDB.fontFamily]
                            if fPath then
                                self:SetFont(fPath, MattActionBarFontDB.fontSize, "OUTLINE")
                                local abXOff = MattActionBarFontDB.abXOffset or 0
                                local abYOff = MattActionBarFontDB.abYOffset or 0
                                self:ClearAllPoints()
                                self:SetPoint("TOPRIGHT", button, "TOPRIGHT", abXOff, abYOff)
                            end
                        end)
                        region._MABF_Hooked = true
                    end
                else
                    SafeSetFont(region, false, button)
                end
            end
        end
        if button.HotKey then
            SafeSetFont(button.HotKey, true, button)
        end
    end

    for i = 1, 12 do
        UpdateActionButton(_G["ActionButton" .. i])
        UpdateActionButton(_G["MultiBarBottomLeftButton" .. i])
        UpdateActionButton(_G["MultiBarBottomRightButton" .. i])
        UpdateActionButton(_G["MultiBarRightButton" .. i])
        UpdateActionButton(_G["MultiBarLeftButton" .. i])
    end

    for i = 1, 10 do
        UpdateActionButton(_G["StanceButton" .. i])
    end

    self:UpdateMacroText()
end

function MABF:UpdateFontPositions()
    local xOff = MattActionBarFontDB.xOffset or 0
    local yOff = MattActionBarFontDB.yOffset or 0
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
        "StanceButton", "PetActionButton", "PossessButton", "ExtraActionButton"
    }
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local countText = _G[bar .. i .. "Count"]
            if countText then
                countText:ClearAllPoints()
                countText:SetPoint("BOTTOMRIGHT", countText:GetParent(), "BOTTOMRIGHT", xOff, yOff)
            end
        end
    end
end

function MABF:UpdateActionBarFontPositions()
    local abXOff = MattActionBarFontDB.abXOffset or 0
    local abYOff = MattActionBarFontDB.abYOffset or 0
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
        "StanceButton", "PetActionButton", "PossessButton", "ExtraActionButton"
    }
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i]
            if button and button.HotKey then
                button.HotKey:ClearAllPoints()
                button.HotKey:SetPoint("TOPRIGHT", button, "TOPRIGHT", MattActionBarFontDB.abXOffset or 0, MattActionBarFontDB.abYOffset or 0)
            end
        end
    end
end

function MABF:UpdateMacroText()
    if not self.availableFonts then
        self.availableFonts = self:ScanCustomFonts()
    end
    local fontPath = self.availableFonts[MattActionBarFontDB.fontFamily]
    if not fontPath then return end
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
        "StanceButton", "PetActionButton", "PossessButton", "ExtraActionButton"
    }
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i]
            if button and button.Name then
                if MattActionBarFontDB.hideMacroText then
                    button.Name:Hide()
                else
                    button.Name:Show()
                    button.Name:ClearAllPoints()
                    button.Name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
                    button.Name:SetFont(fontPath, MattActionBarFontDB.macroTextSize, "OUTLINE")
                    local text = button.Name:GetText()
                    if text then
                        button.Name:SetText(FormatText(text)) -- Convert macro text to uppercase
                    end
                    button.Name:SetTextColor(1, 1, 1, 1)
                end
            end
        end
    end
end

function MABF:UpdatePetBarFontSettings()
    if not self.availableFonts then
        self.availableFonts = self:ScanCustomFonts()
    end
    local fontPath = self.availableFonts[MattActionBarFontDB.fontFamily]
    if not fontPath then return end
    for i = 1, 10 do
        local button = _G["PetActionButton" .. i]
        if button and button.HotKey then
            button.HotKey:SetFont(fontPath, MattActionBarFontDB.petBarFontSize, "OUTLINE")
        end
    end
end

-- This function (formerly a local UpdateSpecificBars) is now part of MABF.
function MABF:UpdateSpecificBars()
    if not self.availableFonts then
        self.availableFonts = self:ScanCustomFonts()
    end
    local fontPath = self.availableFonts[MattActionBarFontDB.fontFamily]
    if not fontPath then return end
    local flags = "OUTLINE"
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
        "StanceButton", "PetActionButton", "PossessButton", "ExtraActionButton"
    }
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i .. "Count"]
            if button then
                button:SetFont(fontPath, MattActionBarFontDB.countFontSize, flags)
                button:SetText(FormatText(button:GetText()))
            end
        end
    end
end
