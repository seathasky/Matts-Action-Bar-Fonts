-- MABFCDText.lua
-- This module adds cooldown text overlays to action buttons (similar to OmniCC).

local MABFCDText = {}
MABFCDText.buttons = {}  -- Table to hold all attached buttons

-- Customize font path and style constants:
local FONT_PATH = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
local NORMAL_FONT_SIZE = 24
local URGENT_FONT_SIZE = 30      -- Bigger red text when less than 5 seconds remain.
local ONE_STACK_FONT_SIZE = 14   -- Much smaller for abilities with 1 charge.

local NORMAL_COLOR = {1, 1, 0}   -- Yellow
local URGENT_COLOR = {1, 0, 0}   -- Red
local ONE_STACK_COLOR = {1, 1, 1} -- White (for one stack)

local MIN_DURATION = 1.5  -- Minimum cooldown duration to show text (to filter out the GCD)

----------------------------------------------------------------------
-- Function: UpdateCooldownText
-- Description: Updates the cooldown text overlay for a given action button.
----------------------------------------------------------------------
function MABFCDText:UpdateCooldownText(button)
    local slot = button.actionSlot
    if not slot then
        if button.cdText:GetText() ~= "" then
            button.cdText:SetText("")
            button._lastCD = ""
        end
        return
    end

    local newText, fontSize, color

    if button.isPet then
        -- Use pet cooldown API for pet action buttons.
        local start, duration, enable = GetPetActionCooldown(slot)
        if not start or duration <= 0 or enable == 0 then
            if button.cdText:GetText() ~= "" then
                button.cdText:SetText("")
                button._lastCD = ""
            end
            return
        end

        local remaining = start + duration - GetTime()
        if remaining <= 0 or duration < MIN_DURATION then
            if button.cdText:GetText() ~= "" then
                button.cdText:SetText("")
                button._lastCD = ""
            end
            return
        end

        newText = (remaining < 60) and format("%.0f", remaining) or format("%.0fm", remaining/60)
        if remaining < 5 then
            fontSize = URGENT_FONT_SIZE
            color = URGENT_COLOR
        else
            fontSize = NORMAL_FONT_SIZE
            color = NORMAL_COLOR
        end
    else
        -- Non‑pet buttons.
        -- Check for charge‑based abilities.
        local charges, maxCharges, chargeStart, chargeDuration = GetActionCharges(slot)
        local isCharge = (charges and maxCharges and maxCharges > 0)

        if isCharge then
            if charges >= maxCharges then
                if button.cdText:GetText() ~= "" then
                    button.cdText:SetText("")
                    button._lastCD = ""
                end
                return
            end

            local remaining = 0
            if chargeStart and chargeDuration and chargeDuration > 0 then
                remaining = chargeStart + chargeDuration - GetTime()
                if remaining < 0 then
                    remaining = 0  -- Clamp negative values.
                end
            else
                if button.cdText:GetText() ~= "" then
                    button.cdText:SetText("")
                    button._lastCD = ""
                end
                return
            end

            newText = (remaining < 60) and format("%.0f", remaining) or format("%.0fm", remaining/60)
            if charges == 1 then
                fontSize = ONE_STACK_FONT_SIZE
                color = ONE_STACK_COLOR
            else
                fontSize = NORMAL_FONT_SIZE
                color = NORMAL_COLOR
            end
        else
            local start, duration, enable = GetActionCooldown(slot)
            if not start or duration <= 0 or enable == 0 then
                if button.cdText:GetText() ~= "" then
                    button.cdText:SetText("")
                    button._lastCD = ""
                end
                return
            end

            local remaining = start + duration - GetTime()
            if remaining <= 0 then
                if button.cdText:GetText() ~= "" then
                    button.cdText:SetText("")
                    button._lastCD = ""
                end
                return
            end

            if duration < MIN_DURATION then
                if button.cdText:GetText() ~= "" then
                    button.cdText:SetText("")
                    button._lastCD = ""
                end
                return
            end

            newText = (remaining < 60) and format("%.0f", remaining) or format("%.0fm", remaining/60)
            if remaining < 5 then
                fontSize = URGENT_FONT_SIZE
                color = URGENT_COLOR
            else
                fontSize = NORMAL_FONT_SIZE
                color = NORMAL_COLOR
            end
        end
    end

    if button._lastCD == newText and button._lastFontSize == fontSize then
        return
    end

    button.cdText:SetFont(FONT_PATH, fontSize, "OUTLINE")
    button.cdText:SetTextColor(unpack(color))
    button.cdText:SetText(newText)
    button._lastCD = newText
    button._lastFontSize = fontSize
end

----------------------------------------------------------------------
-- Function: AttachCooldownText
-- Description: Attaches cooldown text functionality to an action button.
-- Parameters:
--   button      - The action button frame.
--   defaultSlot - Fallback value for the action slot.
----------------------------------------------------------------------
function MABFCDText:AttachCooldownText(button, defaultSlot)
    button.actionSlot = button.action or ((button.GetID and button:GetID()) or defaultSlot)

    if not button.cdText then
        button.cdText = button:CreateFontString(nil, "OVERLAY")
        button.cdText:SetPoint("CENTER", button, "CENTER")
        button.cdText:SetFont(FONT_PATH, NORMAL_FONT_SIZE, "OUTLINE")
        button.cdText:SetTextColor(unpack(NORMAL_COLOR))
        -- Force the cooldown text to always be on top by setting its draw layer to OVERLAY with a high sublevel.
        button.cdText:SetDrawLayer("OVERLAY", 99)
    end

    -- Initialize cache values.
    button._lastCD = button.cdText:GetText() or ""
    button._lastFontSize = NORMAL_FONT_SIZE

    table.insert(MABFCDText.buttons, button)
end

----------------------------------------------------------------------
-- Function: AttachToDefaultBars
-- Description: Iterates over default action bars and attaches cooldown text to each button.
----------------------------------------------------------------------
function MABFCDText:AttachToDefaultBars()
    local bars = {
        { prefix = "ActionButton",              count = 12 },
        { prefix = "MultiBarLeftButton",          count = 12 },
        { prefix = "MultiBarRightButton",         count = 12 },
        { prefix = "MultiBarBottomLeftButton",    count = 12 },
        { prefix = "MultiBarBottomRightButton",   count = 12 },
        { prefix = "MultiBar5Button",             count = 12 },
        { prefix = "MultiBar6Button",             count = 12 },
        { prefix = "MultiBar7Button",             count = 12 },
        { prefix = "StanceButton",                count = _G.NUM_STANCE_SLOTS or 10 },
        { prefix = "PetActionButton",             count = _G.NUM_PET_ACTION_SLOTS or 10 },
        { prefix = "ExtraActionButton",           count = 1 },
        { prefix = "BonusActionButton",           count = 12 },
    }
    for _, bar in ipairs(bars) do
        for i = 1, bar.count do
            local btnName = bar.prefix .. i
            local btn = _G[btnName]
            if btn then
                local slot = btn.action or ((btn.GetID and btn:GetID()) or i)
                self:AttachCooldownText(btn, slot)
                if bar.prefix == "PetActionButton" then
                    btn.isPet = true
                end
            end
        end
    end
end

----------------------------------------------------------------------
-- Global Updater: Update all attached buttons every updateInterval seconds.
----------------------------------------------------------------------
local updaterFrame = CreateFrame("Frame")
local globalElapsed = 0
local updateInterval = 0.1
updaterFrame:SetScript("OnUpdate", function(self, delta)
    globalElapsed = globalElapsed + delta
    if globalElapsed >= updateInterval then
        for _, button in ipairs(MABFCDText.buttons) do
            MABFCDText:UpdateCooldownText(button)
        end
        globalElapsed = 0
    end
end)

----------------------------------------------------------------------
-- Auto-attach: Attach to default bars on PLAYER_ENTERING_WORLD.
----------------------------------------------------------------------
local autoAttachFrame = CreateFrame("Frame")
autoAttachFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
autoAttachFrame:SetScript("OnEvent", function(self, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        if not (MattActionBarFontDB and MattActionBarFontDB.cdTextEnabled) then
            return
        end
        MABFCDText:AttachToDefaultBars()
    end
end)

----------------------------------------------------------------------
-- Expose the module globally.
----------------------------------------------------------------------
_G.MABFCDText = MABFCDText
return MABFCDText
