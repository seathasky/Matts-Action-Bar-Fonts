-- MABFCore.lua
local addonName, MABF = ...

local MAX_FONT_SIZE = 50
local MIN_FONT_SIZE = 10

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

local function ApplyNumpadBindingLabels()
    local keyLabelMap = {
        KEY_NUMPAD0 = "N0",
        KEY_NUMPAD1 = "N1",
        KEY_NUMPAD2 = "N2",
        KEY_NUMPAD3 = "N3",
        KEY_NUMPAD4 = "N4",
        KEY_NUMPAD5 = "N5",
        KEY_NUMPAD6 = "N6",
        KEY_NUMPAD7 = "N7",
        KEY_NUMPAD8 = "N8",
        KEY_NUMPAD9 = "N9",
        KEY_NUMPADDECIMAL = "N.",
        KEY_NUMPADDIVIDE = "N/",
        KEY_NUMPADMINUS = "N-",
        KEY_NUMPADMULTIPLY = "N*",
        KEY_NUMPADPLUS = "N+",
    }
    for keyName, label in pairs(keyLabelMap) do
        _G[keyName] = label
    end
end

-- Initialization and font scanning.
function MABF:Init()
    self:ApplyDefaults()
    ApplyNumpadBindingLabels()

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
