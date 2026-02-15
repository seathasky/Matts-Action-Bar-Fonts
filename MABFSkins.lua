-- MABFSkins.lua (Optimized)
local addonName, MABF = ...
local LPP = LibStub and LibStub("LibPixelPerfect-1.0", true)

-----------------------------------------------------------
-- Global table to hold all skinned buttons for global update
-----------------------------------------------------------
local skinnedButtons = {}

local MINIMAL_THEME_STYLES = {
    minimalTranslucent = {
        border = { 0.62, 0.62, 0.68, 0.9 },
        fill = { 0.85, 0.85, 0.9 },
    },
    minimalObsidianRed = {
        border = { 0.78, 0.08, 0.08, 1.0 },
        fill = { 0.00, 0.00, 0.00 },
    },
    minimalFrostMage = {
        border = { 0.40, 0.80, 1.00, 1.0 },
        fill = { 0.96, 0.99, 1.00 },
    },
    minimalArcane = {
        border = { 0.60, 0.42, 1.00, 1.0 },
        fill = { 0.05, 0.03, 0.10 },
    },
    minimalFelGreen = {
        border = { 0.21, 0.88, 0.42, 1.0 },
        fill = { 0.00, 0.07, 0.04 },
    },
    minimalHolyGold = {
        border = { 0.95, 0.76, 0.31, 1.0 },
        fill = { 0.10, 0.08, 0.02 },
    },
    minimalBloodDK = {
        border = { 0.70, 0.07, 0.18, 1.0 },
        fill = { 0.07, 0.01, 0.03 },
    },
    minimalStormSteel = {
        border = { 0.56, 0.64, 0.71, 1.0 },
        fill = { 0.04, 0.06, 0.08 },
    },
    minimalEmerald = {
        border = { 0.16, 0.80, 0.48, 1.0 },
        fill = { 0.02, 0.07, 0.04 },
    },
    minimalVoid = {
        border = { 0.35, 0.37, 0.56, 1.0 },
        fill = { 0.02, 0.02, 0.05 },
    },
    minimalMonoLight = {
        border = { 0.85, 0.85, 0.85, 1.0 },
        fill = { 1.00, 1.00, 1.00 },
    },
}

local function Clamp01(v)
    return math.max(0, math.min(1, v or 0))
end

local function ClampBorderPixelSize(v)
    local size = tonumber(v) or 1
    size = math.floor(size + 0.5)
    if size < 1 then
        return 1
    elseif size > 4 then
        return 4
    end
    return size
end

local function GetMinimalThemeStyle(theme, bgAlpha)
    local alpha = Clamp01(bgAlpha or 0.35)

    if theme == "minimalBlack" then
        -- Keep existing black behavior where lower slider values get darker.
        local shade = 0.02 + (alpha * 0.08)
        return {
            border = { 0.0, 0.0, 0.0, 1.0 },
            fill = { shade, shade, shade + 0.01 },
            alpha = alpha,
        }
    end

    local style = MINIMAL_THEME_STYLES[theme]
    if style then
        return {
            border = style.border,
            fill = style.fill,
            alpha = alpha,
        }
    end

    return {
        border = { 0.28, 0.28, 0.34, 1.0 },
        fill = { 0.08, 0.08, 0.10 },
        alpha = alpha,
    }
end

local function IsMinimalThemeActive()
    return MattActionBarFontDB and MattActionBarFontDB.minimalTheme and MattActionBarFontDB.minimalTheme ~= "blizzard"
end

local function PixelSizeForFrame(frame, pixels)
    local px = pixels or 1

    if LPP and LPP.SetParentFrame and LPP.PScale and frame then
        LPP.SetParentFrame(frame)
        local scaled = LPP.PScale(px)
        if UIParent and LPP.SetParentFrame then
            LPP.SetParentFrame(UIParent)
        end
        if type(scaled) == "number" and scaled > 0 then
            return scaled
        end
    end

    if PixelUtil and PixelUtil.GetNearestPixelSize then
        local effectiveScale = (frame and frame.GetEffectiveScale and frame:GetEffectiveScale()) or
            (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
        return PixelUtil.GetNearestPixelSize(px, effectiveScale)
    end

    return px
end

local function HideTex(tex)
    if not tex then return end
    tex:SetAlpha(0)
    tex:Hide()
end

local function ShowTex(tex)
    if not tex then return end
    tex:SetAlpha(1)
    tex:Show()
end

local function IsActionButtonBaseTexture(texturePath)
    if type(texturePath) ~= "string" then
        return false
    end
    return texturePath:find("UI%-Panel%-Button")
        or texturePath:find("ActionBar%-Border")
        or texturePath:find("ActionBar%-Background")
        or texturePath:find("Quickslot")
        or texturePath:find("UI%-Quickslot")
        or texturePath:find("ActionButton")
end

local function CacheButtonBaseRegions(button)
    if button._mabfBaseRegionsCached then
        return
    end
    button._mabfBaseRegionsCached = true
    button._mabfBaseRegions = {}

    for _, region in ipairs({ button:GetRegions() }) do
        if region and region:IsObjectType("Texture") then
            local texture = region:GetTexture()
            if IsActionButtonBaseTexture(texture) then
                table.insert(button._mabfBaseRegions, region)
            end
        end
    end
end

local function SetButtonBaseRegionsVisible(button, visible)
    CacheButtonBaseRegions(button)
    if not button._mabfBaseRegions then
        return
    end
    for _, region in ipairs(button._mabfBaseRegions) do
        if visible then
            region:SetAlpha(1)
            region:Show()
        else
            region:SetAlpha(0)
            region:Hide()
        end
    end
end

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

    -- Hide Blizzard's default button frame textures.
    if button.GetNormalTexture then HideTex(button:GetNormalTexture()) end
    if button.GetPushedTexture then HideTex(button:GetPushedTexture()) end
    if button.GetHighlightTexture then HideTex(button:GetHighlightTexture()) end
    if button.GetCheckedTexture then HideTex(button:GetCheckedTexture()) end

    -- Dragonflight/12.x slot-art atlases that create the inner bevel.
    HideTex(button.SlotBackground)
    HideTex(button.SlotArt)
    HideTex(button.NewActionTexture)
    HideTex(button.SpellHighlightTexture)
    HideTex(button.Border)
    HideTex(button.QuickKeybindHighlightTexture)
    if button.HookScript and not button._mabfHideSlotArtHooked then
        button:HookScript("OnShow", function(self)
            if IsMinimalThemeActive() then
                HideTex(self.SlotBackground)
                HideTex(self.SlotArt)
                HideTex(self.NewActionTexture)
                HideTex(self.SpellHighlightTexture)
                HideTex(self.Border)
                HideTex(self.QuickKeybindHighlightTexture)
            end
        end)
        button._mabfHideSlotArtHooked = true
    end

    -- Set TexCoord for icon and cache it (Dominos uses button.icon, Blizzard uses ButtonNameIcon)
    local icon = button.icon or _G[(button:GetName() or "") .. "Icon"]
    if icon then
        -- Remove Blizzard rounded mask so icons stay perfectly square in minimal theme.
        local iconMask = button.IconMask or _G[(button:GetName() or "") .. "IconMask"]
        if iconMask then
            if icon.RemoveMaskTexture and not button._mabfMaskRemoved then
                pcall(icon.RemoveMaskTexture, icon, iconMask)
                button._mabfMaskRemoved = true
            end
            iconMask:Hide()
        end
        -- Slight crop keeps icon edges clean while preserving square corners.
        icon:SetTexCoord(0.06, 0.94, 0.06, 0.94)
        button._icon = icon
    end

    -- Create/upgrade to explicit edge lines so icons are never overdrawn.
    if not button.customBorder then
        if button.customBorder and button.customBorder.Hide then
            button.customBorder:Hide()
        end
        button.customBorder = CreateFrame("Frame", nil, button)
        button.customBorder:SetAllPoints(button)
        button.customBorder:SetFrameStrata(button:GetFrameStrata())
        button.customBorder:SetFrameLevel(button:GetFrameLevel() + 10)

        local lines = {}
        lines.top = button.customBorder:CreateTexture(nil, "OVERLAY")
        lines.bottom = button.customBorder:CreateTexture(nil, "OVERLAY")
        lines.left = button.customBorder:CreateTexture(nil, "OVERLAY")
        lines.right = button.customBorder:CreateTexture(nil, "OVERLAY")
        for _, line in pairs(lines) do
            line:SetTexture("Interface\\Buttons\\WHITE8X8")
            if line.SetSnapToPixelGrid then
                pcall(line.SetSnapToPixelGrid, line, true)
            end
            if line.SetTexelSnappingBias then
                pcall(line.SetTexelSnappingBias, line, 0)
            end
        end
        button.customBorder._mabfLines = lines
    else
        button.customBorder:SetAllPoints(button)
        button.customBorder:SetFrameStrata(button:GetFrameStrata())
        button.customBorder:SetFrameLevel(button:GetFrameLevel() + 10)
    end
    -- Derive a rendered border thickness at this button's scale.
    local borderPixels = ClampBorderPixelSize(MattActionBarFontDB and MattActionBarFontDB.minimalThemeBorderSize or 1)
    local borderSize = PixelSizeForFrame(button, borderPixels)
    if type(borderSize) ~= "number" or borderSize <= 0 then
        borderSize = borderPixels
    end
    button._mabfBorderSize = borderSize

    if button.customBorder and button.customBorder._mabfLines then
        local lines = button.customBorder._mabfLines
        lines.top:ClearAllPoints()
        lines.top:SetPoint("TOPLEFT", button.customBorder, "TOPLEFT", 0, 0)
        lines.top:SetPoint("TOPRIGHT", button.customBorder, "TOPRIGHT", 0, 0)
        lines.top:SetHeight(borderSize)

        lines.bottom:ClearAllPoints()
        lines.bottom:SetPoint("BOTTOMLEFT", button.customBorder, "BOTTOMLEFT", 0, 0)
        lines.bottom:SetPoint("BOTTOMRIGHT", button.customBorder, "BOTTOMRIGHT", 0, 0)
        lines.bottom:SetHeight(borderSize)

        lines.left:ClearAllPoints()
        lines.left:SetPoint("TOPLEFT", button.customBorder, "TOPLEFT", 0, 0)
        lines.left:SetPoint("BOTTOMLEFT", button.customBorder, "BOTTOMLEFT", 0, 0)
        lines.left:SetWidth(borderSize)

        lines.right:ClearAllPoints()
        lines.right:SetPoint("TOPRIGHT", button.customBorder, "TOPRIGHT", 0, 0)
        lines.right:SetPoint("BOTTOMRIGHT", button.customBorder, "BOTTOMRIGHT", 0, 0)
        lines.right:SetWidth(borderSize)
    end
    button.customBorder:Show()
    local theme = MattActionBarFontDB and MattActionBarFontDB.minimalTheme or "blizzard"
    local bgAlpha = MattActionBarFontDB and MattActionBarFontDB.minimalThemeBgOpacity or 0.35
    local style = GetMinimalThemeStyle(theme, bgAlpha)

    if button.customBorder and button.customBorder._mabfLines then
        for _, line in pairs(button.customBorder._mabfLines) do
            line:SetVertexColor(style.border[1], style.border[2], style.border[3], style.border[4])
        end
    end

    -- Hide default base regions and add custom backdrop
    if not button.backdrop then
        button.backdrop = button:CreateTexture(nil, "BACKGROUND")
        button.backdrop:SetDrawLayer("BACKGROUND", -1)
    end
    local inset = button._mabfBorderSize or 1
    button.backdrop:ClearAllPoints()
    -- Fill only the inside of the border for a flush, non-beveled slot.
    button.backdrop:SetPoint("TOPLEFT", button, "TOPLEFT", inset, -inset)
    button.backdrop:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -inset, inset)
    SetButtonBaseRegionsVisible(button, false)
    -- Apply backdrop texture, opacity and color based on theme
    if button.backdrop then
        button.backdrop:SetTexture("Interface\\Buttons\\WHITE8X8")
        button.backdrop:SetVertexColor(style.fill[1], style.fill[2], style.fill[3])
        button.backdrop:SetAlpha(style.alpha)
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
    local seen = {}

    local function AddButton(button)
        if button and not seen[button] then
            seen[button] = true
            table.insert(buttons, button)
        end
    end

    local function AddPrefix(prefix, count)
        for i = 1, count do
            AddButton(_G[prefix .. i])
        end
    end
    
    -- Check for Dominos
    if Dominos and Dominos.Frame then
        for _, frame in Dominos.Frame:GetAll() do
            if frame and frame.buttons then
                -- Skip menu bar frames
                local frameName = frame:GetName() or ""
                if not frameName:find("Menu") and not frameName:find("Bag") then
                    for _, button in pairs(frame.buttons) do
                        AddButton(button)
                    end
                end
            end
        end
        return buttons
    end
    
    -- Default Blizzard bars
    AddPrefix("ActionButton", 12)
    AddPrefix("MultiBarLeftButton", 12)
    AddPrefix("MultiBarRightButton", 12)
    AddPrefix("MultiBarBottomLeftButton", 12)
    AddPrefix("MultiBarBottomRightButton", 12)

    -- Numeric MultiBars (retail 12.x can expose additional bars here)
    for barIndex = 5, 12 do
        AddPrefix("MultiBar" .. barIndex .. "Button", 12)
    end

    AddPrefix("StanceButton", _G.NUM_STANCE_SLOTS or 10)
    AddPrefix("PetActionButton", _G.NUM_PET_ACTION_SLOTS or 10)
    AddPrefix("ExtraActionButton", 1)
    AddPrefix("BonusActionButton", 12)
    
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

local function RestoreButtonDefaultLook(button)
    if not button then return end

    SetButtonBaseRegionsVisible(button, true)

    if button.GetNormalTexture then ShowTex(button:GetNormalTexture()) end
    if button.GetPushedTexture then ShowTex(button:GetPushedTexture()) end
    if button.GetHighlightTexture then ShowTex(button:GetHighlightTexture()) end
    if button.GetCheckedTexture then ShowTex(button:GetCheckedTexture()) end

    ShowTex(button.SlotBackground)
    ShowTex(button.SlotArt)
    ShowTex(button.NewActionTexture)
    ShowTex(button.SpellHighlightTexture)
    ShowTex(button.Border)
    ShowTex(button.QuickKeybindHighlightTexture)

    local icon = button._icon or button.icon or _G[(button:GetName() or "") .. "Icon"]
    if icon then
        icon:SetTexCoord(0, 1, 0, 1)
        icon:SetDesaturated(false)

        local iconMask = button.IconMask or _G[(button:GetName() or "") .. "IconMask"]
        if iconMask then
            if button._mabfMaskRemoved and icon.AddMaskTexture then
                pcall(icon.AddMaskTexture, icon, iconMask)
                button._mabfMaskRemoved = false
            end
            iconMask:SetAlpha(1)
            iconMask:Show()
        end
    end

    if button.customBorder then
        button.customBorder:Hide()
    end
    if button.backdrop then
        button.backdrop:Hide()
    end
end

-----------------------------------------------------------
-- RemoveCustomSkins
-----------------------------------------------------------
function MABF:RemoveCustomSkins()
    local buttons = GetAllActionButtonsForSkinning()
    for _, button in ipairs(buttons) do
        RestoreButtonDefaultLook(button)
    end
end

function MABF:ApplyActionBarThemeLive()
    local theme = MattActionBarFontDB and MattActionBarFontDB.minimalTheme or "blizzard"
    if theme == "blizzard" then
        return
    end
    self:SkinActionBars()
    self:CropAllIcons()
end

-----------------------------------------------------------
-- Global Updater for Skinned Buttons (Throttled)
-- Updates every 0.1 seconds.
-----------------------------------------------------------
local globalSkinUpdater = CreateFrame("Frame")
local throttle = 0
globalSkinUpdater:SetScript("OnUpdate", function(self, elapsed)
    if not IsMinimalThemeActive() then
        return
    end
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
    if MattActionBarFontDB and MattActionBarFontDB.minimalTheme ~= "blizzard" then
        MABF:ApplyActionBarThemeLive()
    end
end)

-- Icon cropping
local INSET = 0.06
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
        local iconMask = button.IconMask or (button.GetName and _G[(button:GetName() or "") .. "IconMask"] or nil)
        if iconMask then
            if icon.RemoveMaskTexture and not button._mabfMaskRemoved then
                pcall(icon.RemoveMaskTexture, icon, iconMask)
                button._mabfMaskRemoved = true
            end
            iconMask:Hide()
        end
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
