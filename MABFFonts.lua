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
                            -- Decide whether to use the main action bar offsets or the
                            -- extra-ability offsets (covers ExtraActionButton1,
                            -- ExtraAbilityContainer children, and Dominos Extra frames).
                            local bName = button and (button.GetName and button:GetName() or "") or ""
                            local parentName = button and (button.GetParent and (button:GetParent():GetName() or "") or "") or ""
                            local isExtra = false
                            if (bName and bName:find("Extra")) or (parentName and parentName:find("Extra")) or (button == _G["ExtraActionButton1"]) then
                                isExtra = true
                            end
                            local abXOff = isExtra and (MattActionBarFontDB.extraXOffset or 0) or (MattActionBarFontDB.abXOffset or 0)
                            local abYOff = isExtra and (MattActionBarFontDB.extraYOffset or 0) or (MattActionBarFontDB.abYOffset or 0)
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

    local extraBtn = _G["ExtraActionButton1"]
    if extraBtn then
        UpdateActionButton(extraBtn)
    end

    local extraContainer = _G["ExtraAbilityContainer"]
    if extraContainer then
        for _, child in pairs({ extraContainer:GetChildren() }) do
            if child and (child.GetObjectType == nil or child:GetObjectType() == "Button" or child.IsObjectType and child:IsObjectType("Button")) then
                pcall(UpdateActionButton, child)
            end
        end
    end

    -- Also scan Dominos frames for any 'Extra' named frames and update their buttons
    if Dominos and Dominos.Frame then
        for _, frame in Dominos.Frame:GetAll() do
            local fname = frame and frame:GetName()
            if fname and fname:find("Extra") and frame.buttons then
                for _, b in pairs(frame.buttons) do
                    pcall(UpdateActionButton, b)
                end
            end
        end
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
    local extraXOff = MattActionBarFontDB.extraXOffset or 0
    local extraYOff = MattActionBarFontDB.extraYOffset or 0
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button then
            local hotKeyFont = button.HotKey or button.bind
            if hotKeyFont then
                -- Detect if this is an Extra / ExtraAbility button and apply
                -- dedicated offsets when appropriate.
                local bName = (button.GetName and (button:GetName() or "") or "")
                local parentName = (button.GetParent and (button:GetParent():GetName() or "") or "")
                local isExtra = (bName:find("Extra") or parentName:find("Extra") or button == _G["ExtraActionButton1"])
                local xOff = isExtra and extraXOff or abXOff
                local yOff = isExtra and extraYOff or abYOff
                hotKeyFont:ClearAllPoints()
                hotKeyFont:SetPoint("TOPRIGHT", button, "TOPRIGHT", xOff, yOff)
            end
        end
    end

    -- Explicitly position ExtraActionButton1 and ExtraAbilityContainer children
    local extraBtn = _G["ExtraActionButton1"]
    if extraBtn then
        local hk = extraBtn.HotKey or extraBtn.bind
        if hk then
            hk:ClearAllPoints()
            hk:SetPoint("TOPRIGHT", extraBtn, "TOPRIGHT", extraXOff, extraYOff)
        end
    end

    local extraContainer = _G["ExtraAbilityContainer"]
    if extraContainer then
        for _, child in pairs({ extraContainer:GetChildren() }) do
            local hk = child and (child.HotKey or child.bind)
            if hk then
                hk:ClearAllPoints()
                hk:SetPoint("TOPRIGHT", child, "TOPRIGHT", extraXOff, extraYOff)
            end
        end
    end

    -- Dominos Extra frames
    if Dominos and Dominos.Frame then
        for _, frame in Dominos.Frame:GetAll() do
            local fname = frame and (frame.GetName and frame:GetName() or "")
            if fname and fname:find("Extra") and frame.buttons then
                for _, b in pairs(frame.buttons) do
                    local hk = b and (b.HotKey or b.bind)
                    if hk then
                        hk:ClearAllPoints()
                        hk:SetPoint("TOPRIGHT", b, "TOPRIGHT", extraXOff, extraYOff)
                    end
                end
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

-----------------------------------------------------------
-- Hook Pet Action Bar Updates
-- Ensures pet bar font settings persist after UI reload
-----------------------------------------------------------
function MABF:HookPetActionBarUpdates()
    -- Hook Blizzard's PetActionBar_Update function if it exists
    if PetActionBar_Update then
        hooksecurefunc("PetActionBar_Update", function()
            MABF:UpdatePetBarFontSettings()
        end)
    end
    
    -- Also hook individual button updates for Blizzard pet bar
    if PetActionButton_Update then
        hooksecurefunc("PetActionButton_Update", function(self)
            MABF:UpdatePetBarFontSettings()
        end)
    end
    
    -- Hook PetActionBar_OnUpdate to catch any font resets
    local petBar = _G["PetActionBar"]
    if petBar then
        -- Debounced OnUpdate handler to catch any animation-driven resets without
        -- spamming updates every frame.
        local scheduled = false
        hooksecurefunc(petBar, "OnUpdate", function()
            if not scheduled then
                scheduled = true
                C_Timer.After(0.05, function()
                    MABF:UpdatePetBarFontSettings()
                    scheduled = false
                end)
            end
        end)
    end

    -- Register for pet action bar events to reapply font settings
    local petBarEvents = CreateFrame("Frame")
    local petEvents = {
        "PET_BAR_UPDATE",
        "PET_BAR_UPDATE_COOLDOWN",
        "PET_BAR_SHOWGRID",
        "PET_BAR_HIDEGRID",
        "UNIT_PET",
        "PLAYER_CONTROL_CHANGED",
        "PLAYER_FARSIGHT_CHANGED",
    }
    for _, ev in ipairs(petEvents) do
        -- Use pcall to avoid attempting to register unknown events on some clients
        pcall(petBarEvents.RegisterEvent, petBarEvents, ev)
    end
    petBarEvents:SetScript("OnEvent", function()
        C_Timer.After(0.1, function()
            MABF:UpdatePetBarFontSettings()
        end)
    end)

    -- Ensure fonts are applied now and shortly after to guard against other
    -- addons/Blizzard code resetting the fonts during load or reloadui.
    MABF:UpdatePetBarFontSettings()
    C_Timer.After(0.1, function()
        MABF:UpdatePetBarFontSettings()
    end)
    C_Timer.After(0.5, function()
        MABF:UpdatePetBarFontSettings()
    end)
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
