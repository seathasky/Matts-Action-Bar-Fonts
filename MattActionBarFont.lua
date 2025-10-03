function MABF:UpdateMacroText()
    local buttons = self:GetAllActionButtons()
    for _, button in pairs(buttons) do
        -- Get the actual macro name object
        local macroName = button:GetName() and _G[button:GetName() .. "Name"]
        if macroName then
            -- Always hide the default macro text
            macroName:Hide()
            
            -- Create our custom macro text if it doesn't exist
            if not button.MFText then
                button.MFText = button:CreateFontString(nil, "ARTWORK")
                button.MFText:SetPoint("BOTTOM", button, "BOTTOM", 0, 2)
            end

            -- Get the actual macro text
            local text = macroName:GetText()
            
            -- Handle visibility
            if MattActionBarFontDB.macroTextVisible and text and text ~= "" then
                button.MFText:SetFont(LSM:Fetch("font", MattActionBarFontDB.fontFamily), MattActionBarFontDB.macroTextSize, "OUTLINE")
                button.MFText:SetText(text)
                button.MFText:Show()
            else
                button.MFText:Hide()
            end
        end
    end
end

local function InitializeDefaults()
    -- Initialize macro text settings
    if MattActionBarFontDB.hideMacroText == nil then 
        MattActionBarFontDB.hideMacroText = false
    end
    
    if MattActionBarFontDB.macroTextSize == nil then
        MattActionBarFontDB.macroTextSize = 8
    end
end
