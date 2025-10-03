-- MABFCore.lua
local addonName, MABF = ...

-- Constants for font size limits
local MAX_FONT_SIZE = 50   -- Maximum allowed font size for main fonts
local MIN_FONT_SIZE = 10   -- Minimum allowed font size for main fonts

-----------------------------------------------------------
-- Initialization & Font Scanning
-----------------------------------------------------------
function MABF:Init()
    if not MattActionBarFontDB then
        -- No saved variables – create defaults
        MattActionBarFontDB = {
            fontSize      = 12,
            fontFamily    = "MORPHEUS", -- Default font family (uses WoW's built-in MORPHEUS font)
            countFontSize = 14,  -- Default count font size
            xOffset       = 0,   -- Default count text X offset
            yOffset       = 0,   -- Default count text Y offset
            abXOffset     = 0,   -- Default action bar (non-count) font X offset
            abYOffset     = 0,   -- Default action bar (non-count) font Y offset
            macroTextSize = 12,  -- Default macro text size
            petBarFontSize = 12, -- Default pet bar font size
            hideMacroText = false, -- Default: show macro text
            minimalTheme  = false, -- Default: use Blizzard's default skins
        }
    else
        -- Preserve existing saved variables, set defaults for missing keys
        MattActionBarFontDB.fontSize   = MattActionBarFontDB.fontSize or 12
        MattActionBarFontDB.fontFamily = MattActionBarFontDB.fontFamily or "MORPHEUS"
        MattActionBarFontDB.countFontSize = MattActionBarFontDB.countFontSize or 14
        MattActionBarFontDB.xOffset       = MattActionBarFontDB.xOffset or 0
        MattActionBarFontDB.yOffset       = MattActionBarFontDB.yOffset or 0
        MattActionBarFontDB.abXOffset     = MattActionBarFontDB.abXOffset or 0
        MattActionBarFontDB.abYOffset     = MattActionBarFontDB.abYOffset or 0
        MattActionBarFontDB.macroTextSize = MattActionBarFontDB.macroTextSize or 12
        MattActionBarFontDB.petBarFontSize = MattActionBarFontDB.petBarFontSize or 12
        MattActionBarFontDB.hideMacroText  = MattActionBarFontDB.hideMacroText or false
        MattActionBarFontDB.minimalTheme   = MattActionBarFontDB.minimalTheme or false
    end

    -- Clamp the main font size.
    MattActionBarFontDB.fontSize = math.min(math.max(MattActionBarFontDB.fontSize, MIN_FONT_SIZE), MAX_FONT_SIZE)

    -- Initialize available fonts.
    MABF.availableFonts = MABF:ScanCustomFonts()
end

-- Base fonts provided by WoW.
MABF.basefonts = {
    ["MORPHEUS"] = "Fonts\\MORPHEUS.ttf",
    ["SKURRI"]   = "Fonts\\SKURRI.ttf",
    ["ARIALN"]   = "Fonts\\ARIALN.ttf",
    ["FRIZQT"]   = "Fonts\\FRIZQT__.ttf"
}

function MABF:ScanCustomFonts()
    local fonts = {}
    -- Add base fonts.
    for name, path in pairs(MABF.basefonts) do
        fonts[name] = path
    end

    -- Merge user-defined custom fonts if provided.
    if AddYourCustomFonts then
        for name, path in pairs(AddYourCustomFonts) do
            fonts[name] = path
        end
    end

    return fonts
end

-----------------------------------------------------------
-- ApplyFontSettings
-- Reapplies font settings by calling various update functions.
-----------------------------------------------------------
function MABF:ApplyFontSettings()
    if self.UpdateActionBarFontPositions then
        self:UpdateActionBarFontPositions()
    end
    if self.UpdateMacroText then
        self:UpdateMacroText()
    end
    if self.UpdateSpecificBars then
        self:UpdateSpecificBars()
    end
    if self.UpdatePetBarFontSettings then
        self:UpdatePetBarFontSettings()
    end
end

-- Expose the MABF table globally for access by other modules
_G.MABF = MABF

return MABF
