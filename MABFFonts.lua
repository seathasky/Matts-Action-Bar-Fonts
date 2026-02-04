-- MABFFonts.lua
local addonName, MABF = ...

-- Helper function to handle text conversion
local function FormatText(text)
    if not text then return "" end
    -- Use pcall to safely handle secret values that can't be converted
    local success, result = pcall(string.upper, text)
    if success then
        return result
    else
        return text -- Return original if conversion fails (e.g., secret value)
    end
end

-----------------------------------------------------------
-- Dominos Compatibility
-----------------------------------------------------------
local function GetDominosButtons()
    local buttons = {}
    if not Dominos or not Dominos.Frame then return buttons end
    
    -- Dominos.Frame:GetAll() returns an iterator (pairs(active))
    for _, frame in Dominos.Frame:GetAll() do
        if frame and frame.buttons then
            for _, button in pairs(frame.buttons) do
                if button then
                    table.insert(buttons, button)
                end
            end
        end
    end
    
    return buttons
end

local function GetAllActionButtons()
    local buttons = {}
    
    -- Check for Dominos first
    if Dominos then
        return GetDominosButtons()
    end
    
    -- Default Blizzard bars
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
        "StanceButton", "PetActionButton", "PossessButton", "ExtraActionButton"
    }
    
    for _, bar in pairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i]
            if button then
                table.insert(buttons, button)
            end
        end
    end
    
    return buttons
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
        
        -- Handle hotkey (Blizzard uses HotKey, Dominos uses bind or HotKey)
        local hotKeyFont = button.HotKey or button.bind
        if hotKeyFont then
            SafeSetFont(hotKeyFont, true, button)
            if not hotKeyFont._MABF_Hooked and hotKeyFont.HookScript then
                local success = pcall(function()
                    hotKeyFont:HookScript("OnTextChanged", function(self)
                        local fPath = MABF.availableFonts and MABF.availableFonts[MattActionBarFontDB.fontFamily]
                        if fPath then
                            self:SetFont(fPath, MattActionBarFontDB.fontSize, "OUTLINE")
                            local abXOff = MattActionBarFontDB.abXOffset or 0
                            local abYOff = MattActionBarFontDB.abYOffset or 0
                            self:ClearAllPoints()
                            self:SetPoint("TOPRIGHT", button, "TOPRIGHT", abXOff, abYOff)
                        end
                    end)
                end)
                if success then
                    hotKeyFont._MABF_Hooked = true
                end
            end
        end
        
        -- Handle other font strings
        for _, region in pairs({ button:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                if region ~= hotKeyFont and region ~= button.Count and region ~= button.Name then
                    SafeSetFont(region, false, button)
                end
            end
        end
    end

    -- Use unified button getter (supports Dominos and Blizzard)
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        UpdateActionButton(button)
    end

    self:UpdateMacroText()
end

function MABF:UpdateFontPositions()
    local xOff = MattActionBarFontDB.xOffset or 0
    local yOff = MattActionBarFontDB.yOffset or 0
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button then
            -- Try to find Count fontstring
            local countText = button.Count or _G[(button:GetName() or "") .. "Count"]
            if countText then
                countText:ClearAllPoints()
                countText:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", xOff, yOff)
            end
        end
    end
end

function MABF:UpdateActionBarFontPositions()
    local abXOff = MattActionBarFontDB.abXOffset or 0
    local abYOff = MattActionBarFontDB.abYOffset or 0
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button then
            local hotKeyFont = button.HotKey or button.bind
            if hotKeyFont then
                hotKeyFont:ClearAllPoints()
                hotKeyFont:SetPoint("TOPRIGHT", button, "TOPRIGHT", abXOff, abYOff)
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
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button and button.Name then
            if MattActionBarFontDB.hideMacroText then
                button.Name:Hide()
            else
                button.Name:Show()
                button.Name:ClearAllPoints()
                button.Name:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
                button.Name:SetFont(fontPath, MattActionBarFontDB.macroTextSize, "OUTLINE")
                -- Safely handle text formatting for macro names
                local success, text = pcall(button.Name.GetText, button.Name)
                if success and text and type(text) == "string" then
                    local formatted = FormatText(text)
                    if formatted ~= text then
                        pcall(button.Name.SetText, button.Name, formatted)
                    end
                end
                button.Name:SetTextColor(1, 1, 1, 1)
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
    
    -- Handle Dominos pet bar
    if Dominos and Dominos.Frame then
        local foundPetBar = false
        for _, frame in Dominos.Frame:GetAll() do
            local frameName = frame:GetName()
            if frame and frame.buttons and frameName and frameName:find("Pet") then
                for _, button in pairs(frame.buttons) do
                    local hotKeyFont = button.HotKey or button.bind
                    if button and hotKeyFont then
                        hotKeyFont:SetFont(fontPath, MattActionBarFontDB.petBarFontSize, "OUTLINE")
                        foundPetBar = true
                    end
                end
            end
        end
        if not foundPetBar then
            -- Fallback to default Blizzard pet bar
            for i = 1, 10 do
                local button = _G["PetActionButton" .. i]
                if button and button.HotKey then
                    button.HotKey:SetFont(fontPath, MattActionBarFontDB.petBarFontSize, "OUTLINE")
                end
            end
        end
    else
        -- Handle default Blizzard pet bar
        for i = 1, 10 do
            local button = _G["PetActionButton" .. i]
            if button and button.HotKey then
                button.HotKey:SetFont(fontPath, MattActionBarFontDB.petBarFontSize, "OUTLINE")
            end
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
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button then
            local countText = button.Count or _G[(button:GetName() or "") .. "Count"]
            if countText then
                countText:SetFont(fontPath, MattActionBarFontDB.countFontSize, flags)
                -- Don't modify count text as it can contain secret values
                -- Just apply the font styling
            end
        end
    end
end
