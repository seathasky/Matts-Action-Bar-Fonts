-- MABFSkins.lua (Optimized)
local addonName, MABF = ...

-----------------------------------------------------------
-- Global table to hold all skinned buttons for global update
-----------------------------------------------------------
local skinnedButtons = {}

-----------------------------------------------------------
-- UpdateActionButtonState
-----------------------------------------------------------
local function UpdateActionButtonState(button)
    if not button or not button:IsVisible() then return end
    local icon = button._icon  -- cached during skinning
    if not icon then return end

    local action = button.action or button:GetID()
    if not action or not C_ActionBar.HasAction(action) then
        icon:SetDesaturated(false)
        return
    end

    -- For item actions (consumables, etc.) - never desaturate, always show in color
    if C_ActionBar.IsItemAction(action) then
        icon:SetDesaturated(false)
        return
    end

    -- Skip charge-based actions to avoid secret value taint issues
    -- They are handled by Blizzard's secure code
    local chargeInfo = C_ActionBar.GetActionCharges(action)
    if chargeInfo and chargeInfo.maxCharges then
        -- Don't desaturate charge-based abilities, let Blizzard handle them
        icon:SetDesaturated(false)
        return
    end

    -- For normal cooldowns
    local cooldownInfo = C_ActionBar.GetActionCooldown(action)
    local now = GetTime()
    if cooldownInfo and cooldownInfo.startTime and cooldownInfo.duration and cooldownInfo.startTime > 0 and cooldownInfo.duration > 1.5 and (cooldownInfo.startTime + cooldownInfo.duration) > now then
        icon:SetDesaturated(true)
    else
        icon:SetDesaturated(false)
    end
end

-----------------------------------------------------------
-- HideSpellActivationAlerts
-- Runs once during skinning to hide and hook any SpellActivationAlert children.
-----------------------------------------------------------
local function HideSpellActivationAlerts(button)
    for _, child in ipairs({ button:GetChildren() }) do
        local childName = child:GetName()
        if childName and childName:find("SpellActivationAlert") then
            child:Hide()
            child:SetAlpha(0)
            if not child._forcedHidden then
                child:HookScript("OnShow", function(c)
                    c:Hide()
                    c:SetAlpha(0)
                end)
                child._forcedHidden = true
            end
        end
    end
end

-----------------------------------------------------------
-- SkinButton
-- Applies your custom border, backdrop, etc.
-----------------------------------------------------------
local function SkinButton(button)
    if not button then return end
    
    -- Skip if not an action button (check for icon property or GetNormalTexture method)
    if not button.GetNormalTexture and not button.icon then
        return
    end
    
    -- Skip buttons without an action property (menu bar, bags, etc.)
    if not button.action and not button.GetID then
        return
    end
    
    -- Additional check: skip if button name contains Menu, Bag, or Micro
    local buttonName = button:GetName()
    if buttonName and (buttonName:find("Menu") or buttonName:find("Bag") or buttonName:find("Micro")) then
        return
    end

    -- Hide Blizzard's default border
    if button.GetNormalTexture then
        local normalTexture = button:GetNormalTexture()
        if normalTexture then
            normalTexture:SetTexture(nil)
        end
    end

    -- Set TexCoord for icon and cache it (Dominos uses button.icon, Blizzard uses ButtonNameIcon)
    local icon = button.icon or _G[(button:GetName() or "") .. "Icon"]
    if icon then
        icon:SetTexCoord(0.05, 0.95, 0.05, 0.95)
        button._icon = icon
    end

    -- Create custom border if needed
    if not button.customBorder then
        button.customBorder = button:CreateTexture(nil, "OVERLAY")
        button.customBorder:SetTexture("Interface\\AddOns\\MattActionBarFont\\Textures\\Border")
        button.customBorder:SetAllPoints(button)
        button.customBorder:SetDrawLayer("OVERLAY", 1)
    end

    -- Remove default textures and add custom backdrop
    if not button.backdrop then
        for i, region in ipairs({ button:GetRegions() }) do
            if region and region:IsObjectType("Texture") then
                local texture = region:GetTexture()
                -- Only hide specific default action button textures, not all textures
                if type(texture) == "string" and (
                    texture:find("UI%-Panel%-Button") or 
                    texture:find("ActionBar%-Border") or
                    texture:find("ActionBar%-Background")
                ) then
                    region:SetTexture(nil)
                end
            end
        end
        button.backdrop = button:CreateTexture(nil, "BACKGROUND")
        button.backdrop:SetAllPoints(button)
        button.backdrop:SetDrawLayer("BACKGROUND", -1)
    end
    -- Apply backdrop texture, opacity and color based on theme
    if button.backdrop then
        local bgAlpha = MattActionBarFontDB.minimalThemeBgOpacity or 0.35
        button.backdrop:SetAlpha(bgAlpha)
        if MattActionBarFontDB.minimalTheme == "minimalTranslucent" then
            button.backdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
            button.backdrop:SetVertexColor(0.85, 0.85, 0.85)
        else
            button.backdrop:SetTexture("Interface\\AddOns\\MattActionBarFont\\Textures\\Backdrop")
            button.backdrop:SetVertexColor(1, 1, 1)
        end
    end

    -- Re-anchor cooldown frame
    if button.cooldown then
        button.cooldown:ClearAllPoints()
        button.cooldown:SetAllPoints(button)
    end

    -- Hide SpellActivationAlert children immediately (only once)
    HideSpellActivationAlerts(button)

    -- Instead of setting an individual OnUpdate, add the button to our global list.
    if not button._skinnedForGlobal then
        table.insert(skinnedButtons, button)
        button._skinnedForGlobal = true
    end

    -- Reapply grayscale on mouseover
    if not button._hookedMouseEvents then
        button:HookScript("OnEnter", function(self)
            UpdateActionButtonState(self)
        end)
        button:HookScript("OnLeave", function(self)
            UpdateActionButtonState(self)
        end)
        button._hookedMouseEvents = true
    end

    -- Force-hide Blizzard's default glow
    if button.glow then
        button.glow:Hide()
        button.glow:SetAlpha(0)
        button.glow:HookScript("OnShow", function(self)
            self:Hide()
            self:SetAlpha(0)
        end)
    end
end

-----------------------------------------------------------
-- GetAllActionButtons (for skinning)
-----------------------------------------------------------
local function GetAllActionButtonsForSkinning()
    local buttons = {}
    
    -- Check for Dominos
    if Dominos and Dominos.Frame then
        for _, frame in Dominos.Frame:GetAll() do
            if frame and frame.buttons then
                -- Skip menu bar frames
                local frameName = frame:GetName() or ""
                if not frameName:find("Menu") and not frameName:find("Bag") then
                    for _, button in pairs(frame.buttons) do
                        if button then
                            table.insert(buttons, button)
                        end
                    end
                end
            end
        end
        return buttons
    end
    
    -- Default Blizzard bars
    local buttonSets = {
        { prefix = "ActionButton",             count = 12 },
        { prefix = "MultiBarLeftButton",       count = 12 },
        { prefix = "MultiBarRightButton",      count = 12 },
        { prefix = "MultiBarBottomLeftButton", count = 12 },
        { prefix = "MultiBarBottomRightButton",count = 12 },
        { prefix = "MultiBar5Button",          count = 12 },
        { prefix = "MultiBar6Button",          count = 12 },
        { prefix = "MultiBar7Button",          count = 12 },
        { prefix = "StanceButton",             count = _G.NUM_STANCE_SLOTS or 10 },
        { prefix = "PetActionButton",          count = _G.NUM_PET_ACTION_SLOTS or 10 },
        { prefix = "ExtraActionButton",        count = 1 },
        { prefix = "BonusActionButton",        count = 12 },
    }

    for _, set in ipairs(buttonSets) do
        for i = 1, set.count do
            local button = _G[set.prefix .. i]
            if button then
                table.insert(buttons, button)
            end
        end
    end
    
    return buttons
end

-----------------------------------------------------------
-- SkinActionBars
-- Calls SkinButton on each bar button (Blizzard or Dominos).
-----------------------------------------------------------
function MABF:SkinActionBars()
    local buttons = GetAllActionButtonsForSkinning()
    for _, button in ipairs(buttons) do
        SkinButton(button)
    end
end

-----------------------------------------------------------
-- RemoveCustomSkins
-----------------------------------------------------------
function MABF:RemoveCustomSkins()
    local buttons = GetAllActionButtonsForSkinning()
    for _, button in ipairs(buttons) do
        if button then
            if button.customBorder then
                button.customBorder:Hide()
            end
            if button.backdrop then
                button.backdrop:Hide()
            end
        end
    end
end

-----------------------------------------------------------
-- Global Updater for Skinned Buttons (Throttled)
-- Updates every 0.1 seconds.
-----------------------------------------------------------
local globalSkinUpdater = CreateFrame("Frame")
local throttle = 0
globalSkinUpdater:SetScript("OnUpdate", function(self, elapsed)
    throttle = throttle + elapsed
    if throttle < 0.1 then return end
    throttle = 0
    for _, button in ipairs(skinnedButtons) do
        UpdateActionButtonState(button)
    end
end)

-----------------------------------------------------------
-- "PLAYER_ENTERING_WORLD" Event
-- Applies skins and then crops icons.
-----------------------------------------------------------
local skinFrame = CreateFrame("Frame")
skinFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
skinFrame:SetScript("OnEvent", function()
    if MattActionBarFontDB.minimalTheme ~= "blizzard" then
        MABF:SkinActionBars()
        MABF:CropAllIcons()  -- Defined below
    end
end)

-- Icon cropping
local INSET = 0.015625
local barData = {
    { prefix = "ActionButton",             count = 12 },
    { prefix = "MultiBarLeftButton",       count = 12 },
    { prefix = "MultiBarRightButton",      count = 12 },
    { prefix = "MultiBarBottomLeftButton", count = 12 },
    { prefix = "MultiBarBottomRightButton",count = 12 },
    { prefix = "MultiBar5Button",          count = 12 },
    { prefix = "MultiBar6Button",          count = 12 },
    { prefix = "MultiBar7Button",          count = 12 },
    { prefix = "PetActionButton",          count = 10 },
    { prefix = "StanceButton",             count = 10 },
    { prefix = "ExtraActionButton",        count = 1  },
    { prefix = "BonusActionButton",        count = 12 },
}

local function CropIcon(button)
    if not button then return end
    
    -- Get icon (Dominos uses button.icon, Blizzard uses ButtonNameIcon)
    local icon = button._icon or button.icon
    if not icon and button.GetName then
        local buttonName = button:GetName()
        if buttonName then
            icon = _G[buttonName .. "Icon"]
        end
    end
    
    if icon then
        icon:SetTexCoord(INSET, 1 - INSET, INSET, 1 - INSET)
    end
end

function MABF:CropAllIcons()
    local buttons = GetAllActionButtonsForSkinning()
    for _, button in ipairs(buttons) do
        CropIcon(button)
    end
end

return MABF
