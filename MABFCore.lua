-- MABFCore.lua
local addonName, MABF = ...

local MAX_FONT_SIZE = 50
local MIN_FONT_SIZE = 10

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-- Initialization and font scanning.
function MABF:Init()
    self:ApplyDefaults()

    MattActionBarFontDB.fontSize = math.min(math.max(MattActionBarFontDB.fontSize, MIN_FONT_SIZE), MAX_FONT_SIZE)
    if type(MattActionBarFontDB.fontFamilyPath) == "string" then
        MattActionBarFontDB.fontFamilyPath = MattActionBarFontDB.fontFamilyPath:match("^%s*(.-)%s*$")
        if MattActionBarFontDB.fontFamilyPath == "" then
            MattActionBarFontDB.fontFamilyPath = nil
        end
    else
        MattActionBarFontDB.fontFamilyPath = nil
    end
    if type(MattActionBarFontDB.fontFamilyPathName) == "string" then
        MattActionBarFontDB.fontFamilyPathName = MattActionBarFontDB.fontFamilyPathName:match("^%s*(.-)%s*$")
        if MattActionBarFontDB.fontFamilyPathName == "" then
            MattActionBarFontDB.fontFamilyPathName = nil
        end
    else
        MattActionBarFontDB.fontFamilyPathName = nil
    end

    MABF:RegisterFontsWithLSM()

    MABF:EnsureFontSelection()
    MABF.availableFonts = MABF:ScanCustomFonts()
    MABF:HookSharedMediaFontUpdates()
end


-- Expose the MABF table globally for access by other modules
_G.MABF = MABF

return MABF
