-- MABFFonts.lua
local addonName, MABF = ...
local DEFAULT_FONT_PATH = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"

local function FormatText(text)
    if not text then return "" end
    local success, result = pcall(string.upper, text)
    if success then
        return result
    else
        return text
    end
end

local function NormalizeHotKeyText(text)
    local hotKeyText = FormatText(text or "")
    if hotKeyText == "-" then
        return hotKeyText
    elseif #hotKeyText == 2 and (hotKeyText:sub(1,1) == "A" or hotKeyText:sub(1,1) == "S" or hotKeyText:sub(1,1) == "C") and hotKeyText:sub(2,2) == "-" then
        return hotKeyText
    elseif #hotKeyText == 3 and (hotKeyText:sub(1,1) == "A" or hotKeyText:sub(1,1) == "S" or hotKeyText:sub(1,1) == "C") and hotKeyText:sub(2,2) == "-" then
        return hotKeyText:sub(1,1) .. hotKeyText:sub(3,3)
    elseif #hotKeyText > 3 then
        return hotKeyText:sub(1,3)
    end
    return hotKeyText
end

-----------------------------------------------------------
-- Dominos Compatibility
-----------------------------------------------------------
local function GetDominosButtons()
    local buttons = {}
    if not Dominos or not Dominos.Frame then return buttons end
    
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
    
    if Dominos then
        return GetDominosButtons()
    end
    
    local bars = {
        "ActionButton", "MultiBarBottomLeftButton", "MultiBarBottomRightButton",
        "MultiBarRightButton", "MultiBarLeftButton", "MultiBar5Button", "MultiBar6Button",
        "StanceButton", "PetActionButton", "PossessButton", "ExtraActionButton"
    }
    
    for _, bar in ipairs(bars) do
        for i = 1, 12 do
            local button = _G[bar .. i]
            if button then
                table.insert(buttons, button)
            end
        end
    end
    
    return buttons
end

local function AnchorFontString(fontString, point, relativeTo, relativePoint, xOfs, yOfs)
    if not fontString then return end
    fontString:ClearAllPoints()
    fontString:SetPoint(point, relativeTo, relativePoint, xOfs or 0, yOfs or 0)
end

local function SetFontIfChanged(fontString, fontPath, fontSize, flags)
    if not (fontString and fontString.SetFont) then return false end
    local requestedPath = (type(fontPath) == "string" and fontPath ~= "") and fontPath or DEFAULT_FONT_PATH
    local requestedSize = tonumber(fontSize) or 12
    local requestedFlags = type(flags) == "string" and flags or ""
    local appliedFlags = requestedFlags
    if fontString._mabfFontPath == requestedPath and fontString._mabfFontSize == requestedSize and fontString._mabfFontFlags == requestedFlags then
        return true
    end

    local function TrySet(path, setFlags)
        local ok, applied = pcall(fontString.SetFont, fontString, path, requestedSize, setFlags)
        return ok and applied ~= false
    end

    local applied = TrySet(requestedPath, requestedFlags)
    if not applied and requestedFlags ~= "" then
        appliedFlags = ""
        applied = TrySet(requestedPath, "")
    end
    if not applied and requestedPath ~= DEFAULT_FONT_PATH then
        appliedFlags = requestedFlags
        applied = TrySet(DEFAULT_FONT_PATH, requestedFlags)
        if not applied and requestedFlags ~= "" then
            appliedFlags = ""
            applied = TrySet(DEFAULT_FONT_PATH, "")
        end
        if applied then
            requestedPath = DEFAULT_FONT_PATH
        end
    end

    if not applied then
        return false
    end

    fontString._mabfFontPath = requestedPath
    fontString._mabfFontSize = requestedSize
    fontString._mabfFontFlags = appliedFlags
    return true
end

local petFontUpdateQueued = false
local function QueuePetBarFontSettingsUpdate(delay)
    if petFontUpdateQueued then
        return
    end
    petFontUpdateQueued = true

    local function RunUpdate()
        petFontUpdateQueued = false
        if MABF and MABF.UpdatePetBarFontSettings then
            MABF:UpdatePetBarFontSettings()
        end
    end

    if C_Timer and C_Timer.After then
        C_Timer.After(delay or 0, RunUpdate)
    else
        RunUpdate()
    end
end

-----------------------------------------------------------
-- Font Application & Position Updates
-----------------------------------------------------------
function MABF:ApplyFontSettings()
    if not self.availableFonts then
        self.availableFonts = self:ScanCustomFonts()
    end
    self:EnsureFontSelection()
    local fontPath = self:GetSelectedFontPath()
    if not fontPath then
        return
    end

    local function GetHotKeyOffsets(button)
        local bName = (button and button.GetName and (button:GetName() or "")) or ""
        local parentName = (button and button.GetParent and (button:GetParent():GetName() or "")) or ""
        local isExtra = (bName:find("Extra") or parentName:find("Extra") or button == _G["ExtraActionButton1"])
        local xOff = isExtra and (MattActionBarFontDB.extraXOffset or 0) or (MattActionBarFontDB.abXOffset or 0)
        local yOff = isExtra and (MattActionBarFontDB.extraYOffset or 0) or (MattActionBarFontDB.abYOffset or 0)
        return xOff, yOff
    end

    local function ApplyHotKeyOverrides(button)
        if not button then return end
        local hotKeyFont = button.HotKey or button.bind
        if not hotKeyFont then return end

        local fPath = fontPath
        if not fPath then return end

        local currentText = hotKeyFont:GetText() or ""
        local normalizedText = NormalizeHotKeyText(currentText)
        if not hotKeyFont._MABF_FormattingText and normalizedText ~= currentText and hotKeyFont.SetText then
            hotKeyFont._MABF_FormattingText = true
            hotKeyFont:SetText(normalizedText)
            hotKeyFont._MABF_FormattingText = nil
        end

        SetFontIfChanged(hotKeyFont, fPath, MattActionBarFontDB.fontSize, "OUTLINE")
        hotKeyFont:SetTextColor(1, 1, 1, 1)

        local xOff, yOff = GetHotKeyOffsets(button)
        AnchorFontString(hotKeyFont, "TOPRIGHT", button, "TOPRIGHT", xOff, yOff)
        hotKeyFont:SetWidth(0)
        hotKeyFont:SetHeight(0)
    end

    if not self._MABF_GlobalHotkeyHooksRegistered then
        if ActionBarActionButtonMixin and ActionBarActionButtonMixin.UpdateHotkeys then
            hooksecurefunc(ActionBarActionButtonMixin, "UpdateHotkeys", function(button)
                ApplyHotKeyOverrides(button)
            end)
        end
        if type(_G.ActionButton_UpdateHotkeys) == "function" then
            hooksecurefunc("ActionButton_UpdateHotkeys", function(button)
                ApplyHotKeyOverrides(button)
            end)
        end
        if PetActionButtonMixin and PetActionButtonMixin.SetHotkeys then
            hooksecurefunc(PetActionButtonMixin, "SetHotkeys", function(button)
                ApplyHotKeyOverrides(button)
            end)
        end
        if type(_G.PetActionButton_UpdateHotkeys) == "function" then
            hooksecurefunc("PetActionButton_UpdateHotkeys", function(button)
                ApplyHotKeyOverrides(button)
            end)
        end
        self._MABF_GlobalHotkeyHooksRegistered = true
    end

    local function SafeSetFont(fontString, isHotKey, button)
        if fontString and fontString.SetFont then
            if isHotKey then
                ApplyHotKeyOverrides(button)
            else
                SetFontIfChanged(fontString, fontPath, MattActionBarFontDB.fontSize * 0.5, "OUTLINE")
                fontString:SetTextColor(1, 1, 1, 1)
            end
            if not isHotKey then
                fontString:SetWidth(0)
                fontString:SetHeight(0)
            end
        end
    end

    local function UpdateActionButton(button)
        if not button then return end
        
        local hotKeyFont = button.HotKey or button.bind
        if hotKeyFont then
            -- Keep this passive: avoid FontString method hooks here to reduce taint risk.
            SafeSetFont(hotKeyFont, true, button)
        end
        
        for _, region in ipairs({ button:GetRegions() }) do
            if region:GetObjectType() == "FontString" then
                if region ~= hotKeyFont and region ~= button.Count and region ~= button.Name then
                    SafeSetFont(region, false, button)
                end
            end
        end
    end

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
        for _, child in ipairs({ extraContainer:GetChildren() }) do
            if child and (child.GetObjectType == nil or child:GetObjectType() == "Button" or child.IsObjectType and child:IsObjectType("Button")) then
                pcall(UpdateActionButton, child)
            end
        end
    end

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
            local countText = button.Count or _G[(button:GetName() or "") .. "Count"]
            if countText then
                AnchorFontString(countText, "BOTTOMRIGHT", button, "BOTTOMRIGHT", xOff, yOff)
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
                local bName = (button.GetName and (button:GetName() or "") or "")
                local parentName = (button.GetParent and (button:GetParent():GetName() or "") or "")
                local isExtra = (bName:find("Extra") or parentName:find("Extra") or button == _G["ExtraActionButton1"])
                local xOff = isExtra and extraXOff or abXOff
                local yOff = isExtra and extraYOff or abYOff
                AnchorFontString(hotKeyFont, "TOPRIGHT", button, "TOPRIGHT", xOff, yOff)
            end
        end
    end

    local extraBtn = _G["ExtraActionButton1"]
    if extraBtn then
        local hk = extraBtn.HotKey or extraBtn.bind
        if hk then
            AnchorFontString(hk, "TOPRIGHT", extraBtn, "TOPRIGHT", extraXOff, extraYOff)
        end
    end

    local extraContainer = _G["ExtraAbilityContainer"]
    if extraContainer then
        for _, child in ipairs({ extraContainer:GetChildren() }) do
            local hk = child and (child.HotKey or child.bind)
            if hk then
                AnchorFontString(hk, "TOPRIGHT", child, "TOPRIGHT", extraXOff, extraYOff)
            end
        end
    end

    if Dominos and Dominos.Frame then
        for _, frame in Dominos.Frame:GetAll() do
            local fname = frame and (frame.GetName and frame:GetName() or "")
            if fname and fname:find("Extra") and frame.buttons then
                for _, b in pairs(frame.buttons) do
                    local hk = b and (b.HotKey or b.bind)
                    if hk then
                        AnchorFontString(hk, "TOPRIGHT", b, "TOPRIGHT", extraXOff, extraYOff)
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
    self:EnsureFontSelection()
    local fontPath = self:GetSelectedFontPath()
    if not fontPath then return end
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button and button.Name then
            if MattActionBarFontDB.hideMacroText then
                button.Name:Hide()
            else
                button.Name:Show()
                AnchorFontString(button.Name, "BOTTOM", button, "BOTTOM", 0, 2)
                SetFontIfChanged(button.Name, fontPath, MattActionBarFontDB.macroTextSize, "OUTLINE")
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
    self:EnsureFontSelection()
    local fontPath = self:GetSelectedFontPath()
    if not fontPath then return end
    local fontSize = MattActionBarFontDB.petBarFontSize
    local flags = "OUTLINE"
    
    if Dominos and Dominos.Frame then
        local foundPetBar = false
        for _, frame in Dominos.Frame:GetAll() do
            local frameName = frame and frame.GetName and frame:GetName()
            if frame and frame.buttons and frameName and frameName:find("Pet") then
                for _, button in pairs(frame.buttons) do
                    local hotKeyFont = button.HotKey or button.bind
                    if button and hotKeyFont then
                        SetFontIfChanged(hotKeyFont, fontPath, fontSize, flags)
                        foundPetBar = true
                    end
                end
            end
        end
        if not foundPetBar then
            for i = 1, 10 do
                local button = _G["PetActionButton" .. i]
                if button and button.HotKey then
                    SetFontIfChanged(button.HotKey, fontPath, fontSize, flags)
                end
            end
        end
    else
        for i = 1, 10 do
            local button = _G["PetActionButton" .. i]
            if button and button.HotKey then
                SetFontIfChanged(button.HotKey, fontPath, fontSize, flags)
            end
        end
    end
end

-----------------------------------------------------------
-- Hook Pet Action Bar Updates
-- Ensures pet bar font settings persist after UI reload
-----------------------------------------------------------
function MABF:HookPetActionBarUpdates()
    if self._MABF_PetHooksRegistered then
        return
    end
    self._MABF_PetHooksRegistered = true

    if PetActionBar_Update then
        hooksecurefunc("PetActionBar_Update", function()
            QueuePetBarFontSettingsUpdate(0)
        end)
    end
    
    if PetActionButton_Update then
        hooksecurefunc("PetActionButton_Update", function(self)
            QueuePetBarFontSettingsUpdate(0)
        end)
    end
    
    local petBar = _G["PetActionBar"]
    if petBar then
        local elapsedSinceRefresh = 0
        petBar:HookScript("OnUpdate", function(_, elapsed)
            elapsedSinceRefresh = elapsedSinceRefresh + elapsed
            if elapsedSinceRefresh < 0.25 then
                return
            end
            elapsedSinceRefresh = 0
            QueuePetBarFontSettingsUpdate(0)
        end)
    end

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
        pcall(petBarEvents.RegisterEvent, petBarEvents, ev)
    end
    petBarEvents:SetScript("OnEvent", function()
        QueuePetBarFontSettingsUpdate(0.05)
    end)

    QueuePetBarFontSettingsUpdate(0)
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, function()
            QueuePetBarFontSettingsUpdate(0)
        end)
        C_Timer.After(0.5, function()
            QueuePetBarFontSettingsUpdate(0)
        end)
    else
        QueuePetBarFontSettingsUpdate(0)
    end
end

-- This function (formerly a local UpdateSpecificBars) is now part of MABF.
function MABF:UpdateSpecificBars()
    if not self.availableFonts then
        self.availableFonts = self:ScanCustomFonts()
    end
    self:EnsureFontSelection()
    local fontPath = self:GetSelectedFontPath()
    if not fontPath then return end
    local flags = "OUTLINE"
    
    local allButtons = GetAllActionButtons()
    for _, button in ipairs(allButtons) do
        if button then
            local countText = button.Count or _G[(button:GetName() or "") .. "Count"]
            if countText then
                SetFontIfChanged(countText, fontPath, MattActionBarFontDB.countFontSize, flags)
            end
        end
    end
end
