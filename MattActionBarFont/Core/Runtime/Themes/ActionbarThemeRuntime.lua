local addonName, MABF = ...

local ACTIONBAR_THEME_OPTIONS = {
    { value = "blizzard",           label = "Blizzard Default" },
    { value = "minimalBlack",       label = "Minimal Black" },
    { value = "minimalTranslucent", label = "Minimal Translucent" },
    { value = "minimalObsidianRed", label = "Obsidian Red" },
    { value = "minimalFrostMage",   label = "Frost Mage" },
    { value = "minimalArcane",      label = "Arcane" },
    { value = "minimalFelGreen",    label = "Fel Green" },
    { value = "minimalHolyGold",    label = "Holy Gold" },
    { value = "minimalBloodDK",     label = "Blood DK" },
    { value = "minimalStormSteel",  label = "Storm Steel" },
    { value = "minimalEmerald",     label = "Emerald" },
    { value = "minimalVoid",        label = "Void" },
    { value = "minimalMonoLight",   label = "Mono Light" },
}

local function ClampThemeBorderSize(value)
    local size = tonumber(value) or 1
    size = math.floor(size + 0.5)
    if size < 1 then
        size = 1
    elseif size > 4 then
        size = 4
    end
    return size
end

local function ApplyThemeLiveOrFallback()
    if MABF.ApplyActionBarThemeLive then
        MABF:ApplyActionBarThemeLive()
    elseif MattActionBarFontDB.minimalTheme ~= "blizzard" then
        if MABF.SkinActionBars then
            MABF:SkinActionBars()
        end
        if MABF.CropAllIcons then
            MABF:CropAllIcons()
        end
    end
end

function MABF:GetActionBarThemeOptions()
    return ACTIONBAR_THEME_OPTIONS
end

function MABF:NormalizeActionBarThemeSettings()
    MattActionBarFontDB.minimalTheme = MattActionBarFontDB.minimalTheme or "blizzard"
    MattActionBarFontDB.minimalThemeBgOpacity = MattActionBarFontDB.minimalThemeBgOpacity or 0.35
    MattActionBarFontDB.minimalThemeBorderSize = ClampThemeBorderSize(MattActionBarFontDB.minimalThemeBorderSize or 1)
end

function MABF:IsMinimalActionBarThemeSelected()
    return (MattActionBarFontDB.minimalTheme or "blizzard") ~= "blizzard"
end

function MABF:SetActionBarThemeBgOpacityPercent(value)
    local percent = math.floor(tonumber(value) or 0)
    if percent < 0 then percent = 0 end
    if percent > 100 then percent = 100 end
    MattActionBarFontDB.minimalThemeBgOpacity = percent / 100
    ApplyThemeLiveOrFallback()
    return percent
end

function MABF:SetActionBarThemeBorderSize(value)
    local size = ClampThemeBorderSize(value)
    MattActionBarFontDB.minimalThemeBorderSize = size
    ApplyThemeLiveOrFallback()
    return size
end

function MABF:SetActionBarTheme(theme)
    MattActionBarFontDB.minimalTheme = theme or "blizzard"
    if MattActionBarFontDB.minimalTheme == "blizzard" then
        return true
    end
    ApplyThemeLiveOrFallback()
    return false
end
