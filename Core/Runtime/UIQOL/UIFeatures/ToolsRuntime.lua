local addonName, MABF = ...

--------------------------------------------------------------------------------
-- Performance Monitor  (FPS & MS display)
--------------------------------------------------------------------------------

local function SavePerfMonitorScreenPosition(frame)
    if not frame or not frame.GetCenter then return end
    local centerX, centerY = frame:GetCenter()
    if not centerX or not centerY then return end

    local parentScale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
    MattActionBarFontDB.perfMonitorPos = {
        mode = "screenCenter",
        x = centerX * parentScale,
        y = centerY * parentScale,
    }
end

local function RestorePerfMonitorPosition(frame)
    frame:ClearAllPoints()
    local pos = MattActionBarFontDB.perfMonitorPos

    if type(pos) == "table" and pos.mode == "screenCenter" and tonumber(pos.x) and tonumber(pos.y) then
        local parentScale = UIParent:GetEffectiveScale() or 1
        frame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / parentScale, pos.y / parentScale)
        return
    end

    if type(pos) == "table" and pos.point then
        local relativeTo = UIParent
        if type(pos.relativeTo) == "string" and _G[pos.relativeTo] then
            relativeTo = _G[pos.relativeTo]
        end
        frame:SetPoint(
            pos.point,
            relativeTo,
            pos.relativePoint or pos.point,
            tonumber(pos.xOfs) or 0,
            tonumber(pos.yOfs) or 0
        )
        return
    end

    frame:SetPoint("TOP", UIParent, "TOP", 0, -4)
end

function MABF:SetupPerformanceMonitor()
    if not MattActionBarFontDB.enablePerformanceMonitor then
        self:DisablePerformanceMonitor()
        return
    end

    local function StopPerfTicker(frame)
        if frame and frame._mabfPerfTicker and frame._mabfPerfTicker.Cancel then
            frame._mabfPerfTicker:Cancel()
            frame._mabfPerfTicker = nil
        end
    end

    local function UpdatePerfText(frame)
        if not frame then
            return
        end
        local fps = math.floor(GetFramerate())
        local _, _, latencyHome, latencyWorld = GetNetStats()
        local showMS = not MattActionBarFontDB.perfMonitorHideMS
        local showWorldMS = showMS and MattActionBarFontDB.perfMonitorShowWorldMS
        if MattActionBarFontDB.perfMonitorVertical then
            frame.text:SetFormattedText("%d FPS", fps)
            if showMS then
                if showWorldMS then
                    frame.text2:SetFormattedText("H:%d W:%d", latencyHome, latencyWorld or 0)
                else
                    frame.text2:SetFormattedText("%dms", latencyHome)
                end
            else
                frame.text2:SetText("")
            end
        else
            if showMS then
                if showWorldMS then
                    frame.text:SetFormattedText("%d FPS  H:%dms W:%dms", fps, latencyHome, latencyWorld or 0)
                else
                    frame.text:SetFormattedText("%d FPS  %dms", fps, latencyHome)
                end
            else
                frame.text:SetFormattedText("%d FPS", fps)
            end
        end
    end

    local function StartPerfTicker(frame)
        if not frame then
            return
        end
        StopPerfTicker(frame)
        if C_Timer and C_Timer.NewTicker then
            frame._mabfPerfTicker = C_Timer.NewTicker(1, function()
                if frame:IsShown() then
                    UpdatePerfText(frame)
                end
            end)
        end
        UpdatePerfText(frame)
    end

    if self.perfFrame then
        self:ApplyPerfMonitorStyle()
        self.perfFrame:Show()
        StartPerfTicker(self.perfFrame)
        return
    end

    local f = CreateFrame("Frame", "MABFPerformanceMonitor", UIParent, "BackdropTemplate")
    f:SetSize(110, 22)
    f:SetFrameStrata("FULLSCREEN_DIALOG")
    f:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    f:SetClampedToScreen(true)
    RestorePerfMonitorPosition(f)

    f.text = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text:SetPoint("CENTER")

    f.text2 = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    f.text2:SetPoint("TOP", f.text, "BOTTOM", 0, -1)
    f.text2:Hide()

    self.perfFrame = f
    self:ApplyPerfMonitorStyle()

    StartPerfTicker(f)

    f:EnableMouse(true)
    f:SetMovable(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self)
        if IsShiftKeyDown() then
            self:StartMoving()
        end
    end)
    f:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        SavePerfMonitorScreenPosition(self)
        RestorePerfMonitorPosition(self)
    end)

    self.perfFrame = f
end

function MABF:DisablePerformanceMonitor()
    if self.perfFrame then
        self.perfFrame:Hide()
        if self.perfFrame._mabfPerfTicker and self.perfFrame._mabfPerfTicker.Cancel then
            self.perfFrame._mabfPerfTicker:Cancel()
            self.perfFrame._mabfPerfTicker = nil
        end
    end
end

local PERF_COLORS = {
    white  = {1, 1, 1},
    red    = {1, 0.2, 0.2},
    green  = {0, 1, 0},
    yellow = {1, 1, 0},
    blue   = {0.3, 0.6, 1},
}

function MABF:ApplyPerfMonitorStyle()
    local f = self.perfFrame
    if not f then return end

    local alpha = MattActionBarFontDB.perfMonitorBgOpacity or 0.5
    f:SetBackdropColor(0, 0, 0, alpha)
    f:SetBackdropBorderColor(0, 0, 0, math.min(alpha + 0.1, 1))

    local c = PERF_COLORS[MattActionBarFontDB.perfMonitorColor] or PERF_COLORS.green
    f.text:SetTextColor(c[1], c[2], c[3])
    if f.text2 then
        f.text2:SetTextColor(c[1], c[2], c[3])
    end

    local showMS = not MattActionBarFontDB.perfMonitorHideMS
    local showWorldMS = showMS and MattActionBarFontDB.perfMonitorShowWorldMS

    if MattActionBarFontDB.perfMonitorVertical then
        local h = showMS and 24 or 14
        local w = showMS and (showWorldMS and 85 or 50) or 50
        f:SetSize(w, h)
        f.text:ClearAllPoints()
        if showMS then
            f.text:SetPoint("TOP", f, "TOP", 0, -2)
            f.text2:ClearAllPoints()
            f.text2:SetPoint("TOP", f.text, "BOTTOM", 0, 0)
            f.text2:Show()
        else
            f.text:SetPoint("CENTER")
            f.text2:Hide()
        end
    else
        local w = showMS and (showWorldMS and 185 or 110) or 60
        f:SetSize(w, 22)
        f.text:ClearAllPoints()
        f.text:SetPoint("CENTER")
        if f.text2 then f.text2:Hide() end
    end
end
