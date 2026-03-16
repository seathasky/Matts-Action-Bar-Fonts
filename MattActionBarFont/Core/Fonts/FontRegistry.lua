local addonName, MABF = ...

-- Font media integration and defaults.
local LSM = LibStub and LibStub("LibSharedMedia-3.0", true)
local FONT = LSM and LSM.MediaType and LSM.MediaType.FONT or "font"
local MABF_FONT_DEFAULT = "Naowh"
local MABF_FONT_DEFAULT_PATH = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
local BLIZZARD_FONT_NAME = "Blizzard Default"
local BLIZZARD_FONT_PATH = "Fonts\\FRIZQT__.ttf"
local fontValidationString = nil
local fontApplyToken = 0
local sharedMediaHooked = false
local fontPreloadFrame = nil

-- Clears resolved font caches when registry/selection changes.
local function ResetResolvedFontCaches(self)
    self._fontPathCache = nil
    self._selectedFontPathKey = nil
    self._selectedFontPathValue = nil
end

-- Built-in fallback fonts available to the addon.
MABF.basefonts = {
    ["MORPHEUS"] = "Fonts\\MORPHEUS.ttf",
    ["SKURRI"]   = "Fonts\\SKURRI.ttf",
    ["ARIALN"]   = "Fonts\\ARIALN.ttf",
    ["FRIZQT"]   = "Fonts\\FRIZQT__.ttf"
}

local function NormalizeMediaName(value)
    if type(value) ~= "string" then
        return nil
    end
    local trimmed = value:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return nil
    end
    return trimmed
end

local function MediaNamesEqual(a, b)
    local left = NormalizeMediaName(a)
    local right = NormalizeMediaName(b)
    if not left or not right then
        return false
    end
    return left:lower() == right:lower()
end

local function GetUsableFontPath(path)
    if type(path) ~= "string" then
        return nil
    end
    local trimmed = path:match("^%s*(.-)%s*$")
    if not trimmed or trimmed == "" then
        return nil
    end
    return trimmed
end

local function GetFontValidationString()
    if fontValidationString then
        return fontValidationString
    end
    local parent = UIParent or _G.UIParent
    if not parent then
        return nil
    end
    local probe = parent:CreateFontString(nil, "OVERLAY")
    probe:Hide()
    fontValidationString = probe
    return fontValidationString
end

local function IsUsableFontPath(fontPath)
    if type(fontPath) ~= "string" or fontPath == "" then
        return false
    end
    local probe = GetFontValidationString()
    if not probe then
        return false
    end
    local ok, applied = pcall(probe.SetFont, probe, fontPath, 12, "OUTLINE")
    if ok and applied ~= false then
        return true
    end
    ok, applied = pcall(probe.SetFont, probe, fontPath, 12, "")
    return ok and applied ~= false
end

local function ClearSavedFontPath()
    if type(MattActionBarFontDB) ~= "table" then return end
    MattActionBarFontDB.fontFamilyPath = nil
    MattActionBarFontDB.fontFamilyPathName = nil
end

local function SetSavedFontPath(fontName, fontPath)
    if type(MattActionBarFontDB) ~= "table" then return end
    local normalizedName = NormalizeMediaName(fontName)
    local normalizedPath = GetUsableFontPath(fontPath)
    if not normalizedName or not normalizedPath then
        ClearSavedFontPath()
        return
    end
    MattActionBarFontDB.fontFamilyPath = normalizedPath
    MattActionBarFontDB.fontFamilyPathName = normalizedName
end

local function GetSavedFontPath(fontName)
    if type(MattActionBarFontDB) ~= "table" then return nil end
    local selected = NormalizeMediaName(fontName)
    local savedName = NormalizeMediaName(MattActionBarFontDB.fontFamilyPathName)
    if not selected or not savedName or not MediaNamesEqual(selected, savedName) then
        return nil
    end
    local savedPath = GetUsableFontPath(MattActionBarFontDB.fontFamilyPath)
    if not savedPath or not IsUsableFontPath(savedPath) then
        return nil
    end
    return savedPath
end

local function GetOrCreateFontPreloadFrame()
    if fontPreloadFrame then
        return fontPreloadFrame
    end
    if not UIParent then
        return nil
    end
    local frame = CreateFrame("Frame", "MABFFontPreloadFrame", UIParent)
    frame:Hide()
    fontPreloadFrame = frame
    return fontPreloadFrame
end

local function PreloadFontPath(fontPath)
    local path = GetUsableFontPath(fontPath)
    if not path then
        return
    end
    local frame = GetOrCreateFontPreloadFrame()
    if not frame then
        return
    end
    local fs = frame:CreateFontString(nil, "OVERLAY")
    fs:Hide()
    pcall(fs.SetFont, fs, path, 12, "")
end

-- Builds the combined local font registry (base + user custom).
function MABF:GetLocalFontRegistry()
    local fonts = {}

    for name, path in pairs(MABF.basefonts) do
        local normalizedName = NormalizeMediaName(name)
        if normalizedName and type(path) == "string" and path ~= "" then
            fonts[#fonts + 1] = { name = normalizedName, path = path }
        end
    end

    if AddYourCustomFonts then
        for name, path in pairs(AddYourCustomFonts) do
            local normalizedName = NormalizeMediaName(name)
            if normalizedName and type(path) == "string" and path ~= "" then
                fonts[#fonts + 1] = { name = normalizedName, path = path }
            end
        end
    end

    return fonts
end

-- Scans and returns available font names mapped to usable paths.
function MABF:ScanCustomFonts()
    local fonts = {}

    for _, media in ipairs(self:GetLocalFontRegistry()) do
        fonts[media.name] = media.path
    end

    if LSM then
        local names = LSM:List(FONT) or {}
        for _, name in ipairs(names) do
            local normalizedName = NormalizeMediaName(name)
            if normalizedName then
                local fetched = LSM:Fetch(FONT, normalizedName, true)
                if fetched and IsUsableFontPath(fetched) then
                    fonts[normalizedName] = fetched
                end
            end
        end
    end

    -- Font registry changes can invalidate resolved path caches.
    ResetResolvedFontCaches(self)
    return fonts
end

-- Registers bundled and custom fonts into LibSharedMedia.
function MABF:RegisterFontsWithLSM()
    if not LSM then return end

    for _, media in ipairs(self:GetLocalFontRegistry()) do
        if not LSM:IsValid(FONT, media.name) then
            LSM:Register(FONT, media.name, media.path)
        end
        PreloadFontPath(media.path)
    end

    ResetResolvedFontCaches(self)
end

-- Reapplies the selected font to all supported UI targets.
function MABF:ReapplySelectedFontEverywhere()
    self.availableFonts = self:ScanCustomFonts()
    if self.ApplyFontSettings then self:ApplyFontSettings() end
    if self.UpdateMacroText then self:UpdateMacroText() end
    if self.UpdateFontPositions then self:UpdateFontPositions() end
    if self.UpdateActionBarFontPositions then self:UpdateActionBarFontPositions() end
    if self.UpdateSpecificBars then self:UpdateSpecificBars() end
    if self.UpdatePetBarFontSettings then self:UpdatePetBarFontSettings() end
end

-- Reapplies multiple times to ride out delayed UI/LSM updates.
function MABF:ReapplySelectedFontBurst(fontName, thisToken)
    local selectedName = NormalizeMediaName(fontName)
    local function Run()
        if thisToken and thisToken ~= fontApplyToken then return end
        if selectedName and MattActionBarFontDB and not MediaNamesEqual(MattActionBarFontDB.fontFamily, selectedName) then return end
        self:ReapplySelectedFontEverywhere()
    end

    Run()
    if C_Timer and C_Timer.After then
        C_Timer.After(0.1, Run)
        C_Timer.After(0.5, Run)
    end
end

-- Hooks LSM font registration events for live font updates.
function MABF:HookSharedMediaFontUpdates()
    if sharedMediaHooked or not LSM then return end
    sharedMediaHooked = true

    if self.availableFonts then
        for _, path in pairs(self.availableFonts) do
            PreloadFontPath(path)
        end
    end

    if not hooksecurefunc then return end
    hooksecurefunc(LSM, "Register", function(_, mediaType, mediaKey, mediaData)
        if mediaType ~= FONT then return end
        PreloadFontPath(mediaData)
        if not MattActionBarFontDB then return end

        local selected = NormalizeMediaName(MattActionBarFontDB.fontFamily)
        if selected and MediaNamesEqual(selected, mediaKey) then
            ResetResolvedFontCaches(MABF)
            MABF:ReapplySelectedFontBurst(selected)
        end
    end)
end

-- Returns sorted font options for UI dropdown usage.
function MABF:GetFontOptions()
    if not MattActionBarFontDB or MattActionBarFontDB.enableCustomFontSection == false then
        return { BLIZZARD_FONT_NAME }
    end

    local list = {}
    local seen = {}
    local scanned = self.availableFonts
    if type(scanned) ~= "table" then
        scanned = self:ScanCustomFonts()
        self.availableFonts = scanned
    end

    for name, path in pairs(scanned) do
        local normalizedName = NormalizeMediaName(name)
        if normalizedName and path and IsUsableFontPath(path) then
            local key = normalizedName:lower()
            if not seen[key] then
                seen[key] = true
                list[#list + 1] = normalizedName
            end
        end
    end

    if #list == 0 then
        list[#list + 1] = MABF_FONT_DEFAULT
    elseif not seen[MABF_FONT_DEFAULT:lower()] then
        list[#list + 1] = MABF_FONT_DEFAULT
    end

    table.sort(list, function(a, b) return tostring(a):lower() < tostring(b):lower() end)
    return list
end

-- Ensures DB font selection is valid and synchronized.
function MABF:EnsureFontSelection()
    if not MattActionBarFontDB then
        MattActionBarFontDB = {}
    end

    if MattActionBarFontDB.enableCustomFontSection == false then
        MattActionBarFontDB.fontFamily = BLIZZARD_FONT_NAME
        self._selectedFontPathKey = BLIZZARD_FONT_NAME
        self._selectedFontPathValue = BLIZZARD_FONT_PATH
        return BLIZZARD_FONT_NAME
    end

    local selected = NormalizeMediaName(MattActionBarFontDB.fontFamily) or MABF_FONT_DEFAULT
    local scanned = self.availableFonts
    if type(scanned) == "table" then
        for name in pairs(scanned) do
            if MediaNamesEqual(name, selected) then
                selected = name
                break
            end
        end
    end

    if self._selectedFontPathKey and self._selectedFontPathKey ~= selected then
        self._selectedFontPathKey = nil
        self._selectedFontPathValue = nil
    end

    MattActionBarFontDB.fontFamily = selected
    return selected
end

-- Resolves a font name to a usable path with fallbacks.
function MABF:GetFontPathByName(fontName)
    local selected = NormalizeMediaName(fontName) or MABF_FONT_DEFAULT
    if MediaNamesEqual(selected, BLIZZARD_FONT_NAME) then
        return BLIZZARD_FONT_PATH, BLIZZARD_FONT_NAME, true
    end
    local cacheKey = selected:lower()
    if self._fontPathCache and self._fontPathCache[cacheKey] then
        return self._fontPathCache[cacheKey], selected, true
    end

    local resolvedPath = GetSavedFontPath(selected)
    local matched = resolvedPath ~= nil
    local resolvedName = selected

    local scanned = self.availableFonts
    if type(scanned) ~= "table" then
        scanned = self:ScanCustomFonts()
        self.availableFonts = scanned
    end

    if not resolvedPath then
        for name, path in pairs(scanned) do
            if MediaNamesEqual(name, selected) and IsUsableFontPath(path) then
                resolvedPath = path
                resolvedName = name
                matched = true
                break
            end
        end
    end

    if not resolvedPath and LSM then
        local fetched = LSM:Fetch(FONT, selected, true)
        if fetched and IsUsableFontPath(fetched) then
            resolvedPath = fetched
            matched = true
        end
    end

    if not resolvedPath then
        for name, path in pairs(scanned) do
            if MediaNamesEqual(name, MABF_FONT_DEFAULT) and IsUsableFontPath(path) then
                resolvedPath = path
                resolvedName = name
                matched = false
                break
            end
        end
    end

    if not resolvedPath and LSM then
        local fallback = LSM:Fetch(FONT, MABF_FONT_DEFAULT, true)
        if fallback and IsUsableFontPath(fallback) then
            resolvedPath = fallback
            resolvedName = MABF_FONT_DEFAULT
            matched = false
        end
    end

    if not resolvedPath then
        resolvedPath = MABF_FONT_DEFAULT_PATH
        resolvedName = MABF_FONT_DEFAULT
        matched = MediaNamesEqual(selected, MABF_FONT_DEFAULT)
    end

    if matched then
        SetSavedFontPath(resolvedName, resolvedPath)
    else
        local selectedFetch = nil
        if LSM then
            selectedFetch = LSM:Fetch(FONT, selected, true)
        end
        if selectedFetch and IsUsableFontPath(selectedFetch) then
            SetSavedFontPath(selected, selectedFetch)
        else
            ClearSavedFontPath()
        end
    end

    self._fontPathCache = self._fontPathCache or {}
    self._fontPathCache[cacheKey] = resolvedPath
    return resolvedPath, resolvedName, matched
end

-- Returns currently active font path from DB selection.
function MABF:GetSelectedFontPath()
    if MattActionBarFontDB and MattActionBarFontDB.enableCustomFontSection == false then
        self._selectedFontPathKey = BLIZZARD_FONT_NAME
        self._selectedFontPathValue = BLIZZARD_FONT_PATH
        if MattActionBarFontDB.fontFamily ~= BLIZZARD_FONT_NAME then
            MattActionBarFontDB.fontFamily = BLIZZARD_FONT_NAME
        end
        return BLIZZARD_FONT_PATH
    end

    local selected = self:EnsureFontSelection()
    if self._selectedFontPathKey == selected and self._selectedFontPathValue then
        return self._selectedFontPathValue
    end

    local path, resolvedName = self:GetFontPathByName(selected)
    if resolvedName and not MediaNamesEqual(selected, resolvedName) and MattActionBarFontDB then
        MattActionBarFontDB.fontFamily = resolvedName
        selected = resolvedName
    end
    self._selectedFontPathKey = selected
    self._selectedFontPathValue = path
    return path
end

-- Sets selected font and triggers staged reapplication.
function MABF:SetSelectedFont(fontName)
    if MattActionBarFontDB and MattActionBarFontDB.enableCustomFontSection == false then
        MattActionBarFontDB.fontFamily = BLIZZARD_FONT_NAME
        self._selectedFontPathKey = BLIZZARD_FONT_NAME
        self._selectedFontPathValue = BLIZZARD_FONT_PATH
        self:ReapplySelectedFontEverywhere()
        return
    end

    fontName = NormalizeMediaName(fontName)
    if not fontName then return end
    if not MattActionBarFontDB then MattActionBarFontDB = {} end

    MattActionBarFontDB.fontFamily = fontName
    ResetResolvedFontCaches(self)
    local resolvedPath, resolvedName, matched = self:GetFontPathByName(fontName)
    if resolvedName then
        MattActionBarFontDB.fontFamily = resolvedName
        fontName = resolvedName
    end
    if matched and resolvedPath then
        SetSavedFontPath(fontName, resolvedPath)
    end

    fontApplyToken = fontApplyToken + 1
    local thisToken = fontApplyToken
    self:ReapplySelectedFontBurst(fontName, thisToken)

    if LSM and (not LSM:IsValid(FONT, fontName)) and C_Timer and C_Timer.After then
        local attempts = 0
        local function RetryApply()
            attempts = attempts + 1
            if thisToken ~= fontApplyToken then return end
            if not MattActionBarFontDB or not MediaNamesEqual(MattActionBarFontDB.fontFamily, fontName) then return end

            local retryPath, retryName, retryMatched = self:GetFontPathByName(fontName)
            if retryName then
                MattActionBarFontDB.fontFamily = retryName
                fontName = retryName
            end
            if retryMatched and retryPath then
                SetSavedFontPath(fontName, retryPath)
            end
            self:ReapplySelectedFontEverywhere()

            if (not LSM:IsValid(FONT, fontName)) and attempts < 40 then
                C_Timer.After(0.2, RetryApply)
            end
        end
        C_Timer.After(0.2, RetryApply)
    end
end
