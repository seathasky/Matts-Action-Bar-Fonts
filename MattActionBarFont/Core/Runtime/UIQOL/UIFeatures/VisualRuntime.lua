local addonName, MABF = ...

local CURSOR_CIRCLE_TEXTURE = "Interface\\AddOns\\MattActionBarFont\\Textures\\cursor_circle.tga"
local CURSOR_CIRCLE_SIZE = 28

--------------------------------------------------------------------------------
-- Cursor Circle
--------------------------------------------------------------------------------

local CURSOR_CIRCLE_COLORS = {
    lightBlue = {0.22, 0.66, 0.78},
    white     = {1, 1, 1},
    red       = {1, 0.2, 0.2},
    green     = {0, 1, 0},
    yellow    = {1, 1, 0},
    blue      = {0.2, 0.45, 1},
    purple    = {0.7, 0.45, 1},
}

local function UpdateCursorCirclePosition(frame)
    local parentScale = UIParent:GetEffectiveScale()
    local x, y = GetCursorPosition()
    x = math.floor((x / parentScale) + 0.5)
    y = math.floor((y / parentScale) + 0.5)

    if x ~= frame._lastX or y ~= frame._lastY then
        frame._lastX, frame._lastY = x, y
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", x, y)
    end
end

function MABF:ApplyCursorCircleStyle()
    local f = self.cursorCircleFrame
    if not f or not f.tex then return end

    local colorKey = MattActionBarFontDB.cursorCircleColor or "lightBlue"
    local c = CURSOR_CIRCLE_COLORS[colorKey] or CURSOR_CIRCLE_COLORS.lightBlue
    local alpha = tonumber(MattActionBarFontDB.cursorCircleOpacity)
    if not alpha then
        alpha = 1
    end
    if alpha < 0 then
        alpha = 0
    elseif alpha > 1 then
        alpha = 1
    end
    MattActionBarFontDB.cursorCircleOpacity = alpha
    f.tex:SetVertexColor(c[1], c[2], c[3], alpha)
end

function MABF:ApplyCursorCircleScale()
    local f = self.cursorCircleFrame
    if not f then return end

    local scale = tonumber(MattActionBarFontDB.cursorCircleScale or 1) or 1
    if scale < 0.5 then
        scale = 0.5
    elseif scale > 2.0 then
        scale = 2.0
    end
    MattActionBarFontDB.cursorCircleScale = scale

    local size = math.floor((CURSOR_CIRCLE_SIZE * scale) + 0.5)
    if size < 8 then
        size = 8
    elseif size > 512 then
        size = 512
    end
    f:SetSize(size, size)
end

function MABF:SetupCursorCircle()
    if not MattActionBarFontDB.enableCursorCircle then
        self:DisableCursorCircle()
        return
    end

    if not self.cursorCircleFrame then
        local f = CreateFrame("Frame", "MABFCursorCircleFrame", UIParent)
        f:SetSize(CURSOR_CIRCLE_SIZE, CURSOR_CIRCLE_SIZE)
        f:SetFrameStrata("TOOLTIP")
        f:SetFrameLevel(9999)
        f:SetClampedToScreen(true)
        f:EnableMouse(false)
        f:SetPoint("CENTER", UIParent, "CENTER")

        f.tex = f:CreateTexture(nil, "OVERLAY")
        f.tex:SetAllPoints(f)
        f.tex:SetTexture(CURSOR_CIRCLE_TEXTURE)

        self.cursorCircleFrame = f
    end

    self:ApplyCursorCircleScale()
    self:ApplyCursorCircleStyle()
    self.cursorCircleFrame:SetScript("OnUpdate", UpdateCursorCirclePosition)
    self.cursorCircleFrame:Show()
end

function MABF:DisableCursorCircle()
    if self.cursorCircleFrame then
        self.cursorCircleFrame:SetScript("OnUpdate", nil)
        self.cursorCircleFrame:Hide()
    end
end
