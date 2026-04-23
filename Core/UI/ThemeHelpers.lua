local addonName, MABF = ...

local THEME_ACCENT = { 1.0, 0.25, 0.25 }
local TAB_NORMAL = { 0.06, 0.06, 0.08, 1 }
local TAB_SELECTED = { 0.12, 0.12, 0.15, 1 }
local TAB_BORDER = { 0.18, 0.18, 0.22, 1 }
local TAB_TEXT_NORMAL = { 0.7, 0.7, 0.7, 1 }
local TAB_TEXT_ACTIVE = { 1, 1, 1, 1 }
local UI_FONT_PATH = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
local ROW_GAP_TIGHT = -4
local ROW_GAP = -8
local DESC_TEXT_OFFSET_X = 26

local function CloneColor(color)
    return { color[1], color[2], color[3], color[4] }
end

function MABF:GetThemeAccentColor()
    return CloneColor(THEME_ACCENT)
end

function MABF:GetTabPalette()
    return {
        normal = CloneColor(TAB_NORMAL),
        selected = CloneColor(TAB_SELECTED),
        border = CloneColor(TAB_BORDER),
        textNormal = CloneColor(TAB_TEXT_NORMAL),
        textActive = CloneColor(TAB_TEXT_ACTIVE),
    }
end

function MABF:GetUIFontPath()
    return UI_FONT_PATH
end

function MABF:GetOptionsLayoutMetrics()
    return {
        rowGapTight = ROW_GAP_TIGHT,
        rowGap = ROW_GAP,
        descTextOffsetX = DESC_TEXT_OFFSET_X,
    }
end

function MABF:GetTabTypography()
    return {
        fontPath = UI_FONT_PATH,
        tabSize = 10,
        headerSize = 7,
    }
end

function MABF:GetSliderTypography()
    return {
        fontPath = UI_FONT_PATH,
        labelSize = 9,
        minMaxSize = 8,
    }
end
