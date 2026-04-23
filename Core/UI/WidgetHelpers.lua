local addonName, MABF = ...

local function GetAccent()
    if MABF.GetThemeAccentColor then
        return MABF:GetThemeAccentColor()
    end
    return { 1.0, 0.25, 0.25 }
end

local function GetPalette()
    if MABF.GetTabPalette then
        return MABF:GetTabPalette()
    end
    return {
        normal = { 0.06, 0.06, 0.08, 1 },
        selected = { 0.12, 0.12, 0.15, 1 },
        border = { 0.18, 0.18, 0.22, 1 },
        textNormal = { 0.7, 0.7, 0.7, 1 },
        textActive = { 1, 1, 1, 1 },
    }
end

local function GetTypography()
    if MABF.GetTabTypography then
        return MABF:GetTabTypography()
    end
    return {
        fontPath = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf",
        tabSize = 10,
        headerSize = 7,
    }
end

function MABF:CreatePageTitle(page, text)
    local accent = GetAccent()
    local title = page:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", page, "TOPLEFT", 12, -10)
    title:SetText(text)
    title:SetTextColor(accent[1], accent[2], accent[3], 1)
    return title
end

function MABF:CreateBasicCheckbox(parent, name, anchorTo, anchorPoint, xOffset, yOffset, labelText, checkedValue, onClick)
    local cb = CreateFrame("CheckButton", name, parent, "InterfaceOptionsCheckButtonTemplate")
    cb:ClearAllPoints()
    cb:SetPoint(anchorPoint or "TOPLEFT", anchorTo, "BOTTOMLEFT", xOffset or 0, yOffset or 0)
    local label = _G[cb:GetName() .. "Text"]
    label:SetText(labelText or "")
    label:SetTextColor(1, 1, 1)
    cb:SetChecked(checkedValue and true or false)
    if onClick then
        cb:SetScript("OnClick", onClick)
    end
    return cb, label
end

function MABF:SetTabButtonState(btn, isActive)
    local accent = GetAccent()
    local palette = GetPalette()
    btn.isActive = isActive and true or false
    if btn.isActive then
        btn:SetBackdropColor(palette.selected[1], palette.selected[2], palette.selected[3], palette.selected[4])
        btn:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.85)
        if btn.text then
            btn.text:SetTextColor(palette.textActive[1], palette.textActive[2], palette.textActive[3], palette.textActive[4])
        end
    else
        btn:SetBackdropColor(palette.normal[1], palette.normal[2], palette.normal[3], palette.normal[4])
        btn:SetBackdropBorderColor(palette.border[1], palette.border[2], palette.border[3], palette.border[4])
        if btn.text then
            btn.text:SetTextColor(palette.textNormal[1], palette.textNormal[2], palette.textNormal[3], palette.textNormal[4])
        end
    end
end

function MABF:CreateSectionHeader(parent, text, anchorFrame, anchorPoint, yOffset, sectionGap)
    local accent = GetAccent()
    local typo = GetTypography()
    local header = parent:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    if anchorFrame then
        header:SetPoint("TOPLEFT", anchorFrame, anchorPoint or "BOTTOMLEFT", 0, yOffset or -(sectionGap or 6))
    else
        header:SetPoint("TOPLEFT", parent, "TOPLEFT", 8, yOffset or -6)
    end
    header:SetText("|cff" .. string.format("%02x%02x%02x", accent[1] * 255, accent[2] * 255, accent[3] * 255) .. text .. "|r")
    header:SetFont(typo.fontPath, typo.headerSize, "OUTLINE")
    return header
end

function MABF:CreateMinimalDropdown(parent, width, visibleRows, hostFrame)
    local accent = GetAccent()
    local fontPath = (MABF.GetUIFontPath and MABF:GetUIFontPath()) or "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf"
    local rowHeight = 20
    visibleRows = math.max(1, visibleRows or 8)
    hostFrame = hostFrame or UIParent

    local dd = CreateFrame("Frame", nil, parent)
    dd:SetSize(width, 20)
    dd.options = {}
    dd.selectedValue = nil
    dd.offset = 0
    dd._updatingScroll = false
    dd.onSelect = nil
    dd.onOpen = nil

    local function NormalizeOptions(raw)
        local out = {}
        for _, opt in ipairs(raw or {}) do
            if type(opt) == "table" and opt.value ~= nil and opt.label ~= nil then
                out[#out + 1] = { value = opt.value, label = tostring(opt.label) }
            elseif type(opt) == "string" then
                out[#out + 1] = { value = opt, label = opt }
            end
        end
        return out
    end

    local function FindByValue(value)
        for _, opt in ipairs(dd.options) do
            if opt.value == value then
                return opt
            end
        end
        return nil
    end

    dd.button = CreateFrame("Button", nil, dd, "BackdropTemplate")
    dd.button:SetAllPoints()
    dd.button:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dd.button:SetBackdropColor(0.06, 0.06, 0.08, 1)
    dd.button:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)

    dd.buttonText = dd.button:CreateFontString(nil, "OVERLAY")
    dd.buttonText:SetFont(fontPath, 10, "")
    dd.buttonText:SetPoint("LEFT", dd.button, "LEFT", 8, 0)
    dd.buttonText:SetPoint("RIGHT", dd.button, "RIGHT", -24, 0)
    dd.buttonText:SetJustifyH("LEFT")
    dd.buttonText:SetTextColor(0.9, 0.9, 0.9, 1)

    dd.arrowText = dd.button:CreateFontString(nil, "OVERLAY")
    dd.arrowText:SetFont(fontPath, 10, "")
    dd.arrowText:SetPoint("RIGHT", dd.button, "RIGHT", -8, 0)
    dd.arrowText:SetText("v")
    dd.arrowText:SetTextColor(accent[1], accent[2], accent[3], 0.95)

    dd.list = CreateFrame("Frame", nil, hostFrame, "BackdropTemplate")
    dd.list:SetSize(width, (visibleRows * rowHeight) + 4)
    dd.list:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dd.list:SetBackdropColor(0.06, 0.06, 0.08, 1)
    dd.list:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    dd.list:SetFrameStrata("DIALOG")
    dd.list:EnableMouseWheel(true)
    dd.list:Hide()

    dd.scroll = CreateFrame("Slider", nil, dd.list, "BackdropTemplate")
    dd.scroll:SetPoint("TOPRIGHT", dd.list, "TOPRIGHT", -2, -2)
    dd.scroll:SetPoint("BOTTOMRIGHT", dd.list, "BOTTOMRIGHT", -2, 2)
    dd.scroll:SetWidth(10)
    dd.scroll:SetOrientation("VERTICAL")
    dd.scroll:SetMinMaxValues(0, 0)
    dd.scroll:SetValueStep(1)
    dd.scroll:SetObeyStepOnDrag(true)
    dd.scroll:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    dd.scroll:SetBackdropColor(0.03, 0.03, 0.04, 1)
    dd.scroll:SetBackdropBorderColor(0.15, 0.15, 0.18, 1)
    local thumb = dd.scroll:CreateTexture(nil, "OVERLAY")
    thumb:SetSize(8, 18)
    thumb:SetColorTexture(accent[1], accent[2], accent[3], 1)
    dd.scroll:SetThumbTexture(thumb)

    dd.rows = {}
    for i = 1, visibleRows do
        local row = CreateFrame("Button", nil, dd.list, "BackdropTemplate")
        row:SetSize(width - 14, rowHeight)
        row:SetPoint("TOPLEFT", dd.list, "TOPLEFT", 1, -1 - (i - 1) * rowHeight)
        row.bg = row:CreateTexture(nil, "BACKGROUND")
        row.bg:SetAllPoints()
        row.bg:SetColorTexture(0, 0, 0, 0)
        row.text = row:CreateFontString(nil, "OVERLAY")
        row.text:SetFont(fontPath, 10, "")
        row.text:SetPoint("LEFT", row, "LEFT", 6, 0)
        row.text:SetPoint("RIGHT", row, "RIGHT", -6, 0)
        row.text:SetJustifyH("LEFT")
        row.text:SetTextColor(0.9, 0.9, 0.9, 1)
        row:SetScript("OnEnter", function(self)
            self.bg:SetColorTexture(accent[1] * 0.2, accent[2] * 0.2, accent[3] * 0.2, 0.6)
            self.text:SetTextColor(accent[1], accent[2], accent[3], 1)
        end)
        row:SetScript("OnLeave", function(self)
            self.bg:SetColorTexture(0, 0, 0, 0)
            self.text:SetTextColor(0.9, 0.9, 0.9, 1)
        end)
        row:SetScript("OnClick", function(self)
            if not self.option then return end
            dd:SetSelectedValue(self.option.value)
            if dd.onSelect then dd.onSelect(self.option.value, self.option) end
            dd:Close()
        end)
        dd.rows[i] = row
    end

    function dd:Refresh()
        local maxOffset = math.max(0, #self.options - visibleRows)
        if self.offset < 0 then self.offset = 0 end
        if self.offset > maxOffset then self.offset = maxOffset end
        self.scroll:SetShown(maxOffset > 0)
        self.scroll:SetMinMaxValues(0, maxOffset)
        self._updatingScroll = true
        self.scroll:SetValue(self.offset)
        self._updatingScroll = false

        for i = 1, visibleRows do
            local opt = self.options[self.offset + i]
            local row = self.rows[i]
            if opt then
                row.option = opt
                row.text:SetText(opt.label:gsub("|", "||"))
                row:Show()
            else
                row.option = nil
                row:Hide()
            end
        end
    end

    function dd:SetOptions(opts)
        self.options = NormalizeOptions(opts)
        self:Refresh()
    end

    function dd:SetSelectedValue(value)
        self.selectedValue = value
        local opt = FindByValue(value)
        if opt then
            self.buttonText:SetTextColor(0.92, 0.92, 0.92, 1)
            self.buttonText:SetText(opt.label:gsub("|", "||"))
        elseif value ~= nil then
            self.buttonText:SetTextColor(0.75, 0.75, 0.75, 1)
            self.buttonText:SetText(tostring(value):gsub("|", "||"))
        else
            self.buttonText:SetTextColor(0.6, 0.6, 0.6, 1)
            self.buttonText:SetText("Select...")
        end
    end

    function dd:GetSelectedValue()
        return self.selectedValue
    end

    function dd:SetOnSelect(fn)
        self.onSelect = fn
    end

    function dd:SetOnOpen(fn)
        self.onOpen = fn
    end

    function dd:Close()
        self.list:Hide()
        if hostFrame._mabfDropdownCatcher then
            hostFrame._mabfDropdownCatcher:Hide()
        end
        if MABF._activeMinimalDropdown == self then
            MABF._activeMinimalDropdown = nil
        end
    end

    function dd:Open()
        if self.onOpen then self.onOpen(self) end
        self:Refresh()
        if #self.options == 0 then return end
        self.list:ClearAllPoints()
        self.list:SetPoint("TOPLEFT", self, "BOTTOMLEFT", 0, -2)
        self.list:SetFrameLevel(self:GetFrameLevel() + 20)
        self.list:Show()
        MABF._activeMinimalDropdown = self

        if not hostFrame._mabfDropdownCatcher then
            local catcher = CreateFrame("Button", nil, hostFrame)
            catcher:SetAllPoints(hostFrame)
            catcher:SetScript("OnClick", function()
                if MABF._activeMinimalDropdown then
                    MABF._activeMinimalDropdown:Close()
                end
            end)
            hostFrame._mabfDropdownCatcher = catcher
        end
        hostFrame._mabfDropdownCatcher:SetFrameLevel(self.list:GetFrameLevel() - 1)
        hostFrame._mabfDropdownCatcher:Show()
    end

    dd.scroll:SetScript("OnValueChanged", function(_, value)
        if dd._updatingScroll then return end
        dd.offset = math.floor((value or 0) + 0.5)
        dd:Refresh()
    end)
    dd.list:SetScript("OnMouseWheel", function(_, delta)
        if delta > 0 then dd.offset = dd.offset - 1 else dd.offset = dd.offset + 1 end
        dd:Refresh()
    end)

    dd.button:SetScript("OnClick", function()
        if dd.list:IsShown() then dd:Close() else dd:Open() end
    end)
    dd.button:SetScript("OnEnter", function(self)
        self:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
    end)
    dd.button:SetScript("OnLeave", function(self)
        self:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    end)

    return dd
end

function MABF:StyleSlider(slider)
    if not slider or not slider.GetName then return end
    local accent = GetAccent()
    local typo = (MABF.GetSliderTypography and MABF:GetSliderTypography()) or {
        fontPath = "Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf",
        labelSize = 9,
        minMaxSize = 8,
    }

    local name = slider:GetName()
    local textLabel = _G[name .. "Text"]
    local lowLabel = _G[name .. "Low"]
    local highLabel = _G[name .. "High"]

    local leftTex = _G[name .. "Left"]
    local rightTex = _G[name .. "Right"]
    local middleTex = _G[name .. "Middle"]
    if leftTex then leftTex:SetTexture(nil) leftTex:SetAlpha(0) end
    if rightTex then rightTex:SetTexture(nil) rightTex:SetAlpha(0) end
    if middleTex then middleTex:SetTexture(nil) middleTex:SetAlpha(0) end

    if not slider._mabfTrack then
        slider._mabfTrack = CreateFrame("Frame", nil, slider, "BackdropTemplate")
        slider._mabfTrack:SetPoint("LEFT", slider, "LEFT", 0, 0)
        slider._mabfTrack:SetPoint("RIGHT", slider, "RIGHT", 0, 0)
        slider._mabfTrack:SetHeight(8)
        slider._mabfTrack:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        slider._mabfFill = slider._mabfTrack:CreateTexture(nil, "ARTWORK")
        slider._mabfFill:SetPoint("LEFT", slider._mabfTrack, "LEFT", 0, 0)
        slider._mabfFill:SetHeight(8)

        local thumb = slider:CreateTexture(nil, "OVERLAY")
        thumb:SetSize(8, 14)
        thumb:SetColorTexture(accent[1], accent[2], accent[3], 1)
        slider:SetThumbTexture(thumb)
        slider._mabfThumb = thumb
    end

    slider._mabfTrack:SetBackdropColor(0.06, 0.06, 0.08, 1)
    slider._mabfTrack:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
    slider._mabfFill:SetColorTexture(accent[1] * 0.5, accent[2] * 0.5, accent[3] * 0.6, 0.8)

    local function UpdateFill()
        local minV, maxV = slider:GetMinMaxValues()
        local val = slider:GetValue()
        local pct = 0
        if maxV and minV and maxV > minV then
            pct = (val - minV) / (maxV - minV)
        end
        slider._mabfFill:SetWidth(math.max(1, slider._mabfTrack:GetWidth() * pct))
    end

    UpdateFill()
    if not slider._mabfFillHooked then
        slider:HookScript("OnValueChanged", UpdateFill)
        slider:HookScript("OnEnter", function(self)
            if self._mabfTrack then
                self._mabfTrack:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
            end
        end)
        slider:HookScript("OnLeave", function(self)
            if self._mabfTrack then
                self._mabfTrack:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            end
        end)
        slider._mabfFillHooked = true
    end

    if textLabel then
        textLabel:SetFont(typo.fontPath, typo.labelSize, "OUTLINE")
        textLabel:SetTextColor(0.9, 0.9, 0.9)
        textLabel:ClearAllPoints()
        textLabel:SetPoint("BOTTOMLEFT", slider, "TOPLEFT", 0, 4)
        textLabel:SetJustifyH("LEFT")
    end
    if lowLabel then
        lowLabel:SetFont(typo.fontPath, typo.minMaxSize, "OUTLINE")
        lowLabel:SetTextColor(0.6, 0.6, 0.6)
        lowLabel:ClearAllPoints()
        lowLabel:SetPoint("TOPLEFT", slider, "BOTTOMLEFT", 0, -1)
    end
    if highLabel then
        highLabel:SetFont(typo.fontPath, typo.minMaxSize, "OUTLINE")
        highLabel:SetTextColor(0.6, 0.6, 0.6)
        highLabel:ClearAllPoints()
        highLabel:SetPoint("TOPRIGHT", slider, "BOTTOMRIGHT", 0, -1)
    end
end

function MABF:StyleMinimalCheckbox(checkButton)
    if not checkButton or checkButton._mabfMinimalStyled then return end
    checkButton._mabfMinimalStyled = true
    local accent = GetAccent()

    local normal = checkButton.GetNormalTexture and checkButton:GetNormalTexture() or nil
    local pushed = checkButton.GetPushedTexture and checkButton:GetPushedTexture() or nil
    local highlight = checkButton.GetHighlightTexture and checkButton:GetHighlightTexture() or nil
    local disabled = checkButton.GetDisabledTexture and checkButton:GetDisabledTexture() or nil
    local checked = checkButton.GetCheckedTexture and checkButton:GetCheckedTexture() or nil
    local disabledChecked = checkButton.GetDisabledCheckedTexture and checkButton:GetDisabledCheckedTexture() or nil
    if normal then normal:SetTexture(nil) normal:SetAlpha(0) normal:Hide() end
    if pushed then pushed:SetTexture(nil) pushed:SetAlpha(0) pushed:Hide() end
    if highlight then highlight:SetTexture(nil) highlight:SetAlpha(0) highlight:Hide() end
    if disabled then disabled:SetTexture(nil) disabled:SetAlpha(0) disabled:Hide() end
    if checked then checked:SetTexture(nil) checked:SetAlpha(0) checked:Hide() end
    if disabledChecked then disabledChecked:SetTexture(nil) disabledChecked:SetAlpha(0) disabledChecked:Hide() end

    if checkButton.SetHitRectInsets then
        checkButton:SetHitRectInsets(0, -220, 0, 0)
    end

    local box = CreateFrame("Frame", nil, checkButton)
    box:SetSize(14, 14)
    box:SetPoint("LEFT", checkButton, "LEFT", 0, 0)
    checkButton._mabfBox = box

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.1, 1)
    checkButton._mabfBg = bg

    local border = box:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.25, 0.25, 0.3, 1)
    checkButton._mabfBorder = border

    local mark = box:CreateTexture(nil, "ARTWORK")
    mark:SetSize(8, 8)
    mark:SetPoint("CENTER")
    mark:SetColorTexture(accent[1], accent[2], accent[3], 1)
    checkButton._mabfCheck = mark

    local function UpdateMark(self)
        if self._mabfCheck then
            self._mabfCheck:SetShown(self:GetChecked() and true or false)
        end
    end

    UpdateMark(checkButton)
    checkButton:HookScript("OnClick", UpdateMark)
    checkButton:HookScript("OnShow", UpdateMark)

    checkButton:HookScript("OnEnter", function(self)
        if self._mabfBorder then
            self._mabfBorder:SetColorTexture(accent[1], accent[2], accent[3], 0.6)
        end
    end)
    checkButton:HookScript("OnLeave", function(self)
        if self._mabfBorder then
            self._mabfBorder:SetColorTexture(0.25, 0.25, 0.3, 1)
        end
    end)

    local textLabel = checkButton.GetName and _G[(checkButton:GetName() or "") .. "Text"] or nil
    if textLabel then
        textLabel:ClearAllPoints()
        textLabel:SetPoint("LEFT", box, "RIGHT", 6, 0)
        textLabel:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")
        textLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    end
end

function MABF:StyleMinimalRadio(radioButton, textLabel)
    if not radioButton or radioButton._mabfMinimalRadioStyled then return end
    radioButton._mabfMinimalRadioStyled = true
    local accent = GetAccent()

    local normal = radioButton.GetNormalTexture and radioButton:GetNormalTexture() or nil
    local pushed = radioButton.GetPushedTexture and radioButton:GetPushedTexture() or nil
    local highlight = radioButton.GetHighlightTexture and radioButton:GetHighlightTexture() or nil
    local disabled = radioButton.GetDisabledTexture and radioButton:GetDisabledTexture() or nil
    local checked = radioButton.GetCheckedTexture and radioButton:GetCheckedTexture() or nil
    if normal then normal:SetTexture(nil) normal:SetAlpha(0) normal:Hide() end
    if pushed then pushed:SetTexture(nil) pushed:SetAlpha(0) pushed:Hide() end
    if highlight then highlight:SetTexture(nil) highlight:SetAlpha(0) highlight:Hide() end
    if disabled then disabled:SetTexture(nil) disabled:SetAlpha(0) disabled:Hide() end
    if checked then checked:SetTexture(nil) checked:SetAlpha(0) checked:Hide() end

    radioButton:SetSize(12, 12)
    if radioButton.SetHitRectInsets then
        radioButton:SetHitRectInsets(0, -220, 0, 0)
    end

    local box = CreateFrame("Frame", nil, radioButton)
    box:SetSize(12, 12)
    box:SetPoint("LEFT", radioButton, "LEFT", 0, 0)
    radioButton._mabfRadioBox = box

    local bg = box:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.08, 0.08, 0.1, 1)
    radioButton._mabfRadioBg = bg

    local border = box:CreateTexture(nil, "BORDER")
    border:SetPoint("TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", 1, -1)
    border:SetColorTexture(0.25, 0.25, 0.3, 1)
    radioButton._mabfRadioBorder = border

    local mark = box:CreateTexture(nil, "ARTWORK")
    mark:SetSize(6, 6)
    mark:SetPoint("CENTER")
    mark:SetColorTexture(accent[1], accent[2], accent[3], 1)
    radioButton._mabfRadioMark = mark

    local function UpdateMark(self)
        if self and self._mabfRadioMark then
            self._mabfRadioMark:SetShown(self:GetChecked() and true or false)
        end
    end

    radioButton._mabfRefreshMark = function()
        UpdateMark(radioButton)
    end
    UpdateMark(radioButton)
    radioButton:HookScript("OnClick", UpdateMark)
    radioButton:HookScript("OnShow", UpdateMark)

    radioButton:HookScript("OnEnter", function(self)
        if self._mabfRadioBorder then
            self._mabfRadioBorder:SetColorTexture(accent[1], accent[2], accent[3], 0.6)
        end
    end)
    radioButton:HookScript("OnLeave", function(self)
        if self._mabfRadioBorder then
            self._mabfRadioBorder:SetColorTexture(0.25, 0.25, 0.3, 1)
        end
    end)

    if textLabel then
        textLabel:ClearAllPoints()
        textLabel:SetPoint("LEFT", box, "RIGHT", 6, 0)
        textLabel:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")
        textLabel:SetTextColor(0.9, 0.9, 0.9, 1)
    end
end

function MABF:StyleMinimalButton(btn, isDanger)
    if not btn or btn._mabfMinimalStyled then return end
    btn._mabfMinimalStyled = true
    local accent = GetAccent()

    local ntex = btn.GetNormalTexture and btn:GetNormalTexture() or nil
    local ptex = btn.GetPushedTexture and btn:GetPushedTexture() or nil
    local htex = btn.GetHighlightTexture and btn:GetHighlightTexture() or nil
    local dtex = btn.GetDisabledTexture and btn:GetDisabledTexture() or nil
    if ntex then ntex:SetTexture(nil) ntex:SetAlpha(0) ntex:Hide() end
    if ptex then ptex:SetTexture(nil) ptex:SetAlpha(0) ptex:Hide() end
    if htex then htex:SetTexture(nil) htex:SetAlpha(0) htex:Hide() end
    if dtex then dtex:SetTexture(nil) dtex:SetAlpha(0) dtex:Hide() end

    local bgTarget = btn
    if not btn.SetBackdrop then
        local bgFrame = CreateFrame("Frame", nil, btn, "BackdropTemplate")
        bgFrame:SetPoint("TOPLEFT", btn, "TOPLEFT", 0, 0)
        bgFrame:SetPoint("BOTTOMRIGHT", btn, "BOTTOMRIGHT", 0, 0)
        bgFrame:SetFrameLevel(math.max(btn:GetFrameLevel() - 1, 1))
        btn._mabfButtonBg = bgFrame
        bgTarget = bgFrame
    end

    bgTarget:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Buttons\\WHITE8X8",
        edgeSize = 1,
    })
    if isDanger then
        bgTarget:SetBackdropColor(0.28, 0.02, 0.02, 1)
        bgTarget:SetBackdropBorderColor(0.55, 0.05, 0.05, 1)
    else
        bgTarget:SetBackdropColor(0.08, 0.08, 0.1, 1)
        bgTarget:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
    end

    local fs = btn.GetFontString and btn:GetFontString() or nil
    if fs then
        fs:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 11, "")
        if isDanger then
            fs:SetTextColor(1, 0.2, 0.2, 1)
        else
            fs:SetTextColor(0.9, 0.9, 0.9, 1)
        end
    end

    btn:HookScript("OnEnter", function(self)
        local target = self._mabfButtonBg or self
        if isDanger then
            target:SetBackdropBorderColor(1, 0.15, 0.15, 1)
        else
            target:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.8)
        end
    end)
    btn:HookScript("OnLeave", function(self)
        local target = self._mabfButtonBg or self
        if isDanger then
            target:SetBackdropBorderColor(0.55, 0.05, 0.05, 1)
        else
            target:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
        end
    end)
    btn:HookScript("OnMouseDown", function(self)
        local target = self._mabfButtonBg or self
        if isDanger then
            target:SetBackdropColor(0.22, 0.02, 0.02, 1)
        else
            target:SetBackdropColor(0.06, 0.06, 0.08, 1)
        end
    end)
    btn:HookScript("OnMouseUp", function(self)
        local target = self._mabfButtonBg or self
        if isDanger then
            target:SetBackdropColor(0.28, 0.02, 0.02, 1)
        else
            target:SetBackdropColor(0.08, 0.08, 0.1, 1)
        end
    end)
end

function MABF:StyleMinimalDropdown(dropdown)
    if not dropdown or dropdown._mabfMinimalStyled then return end
    dropdown._mabfMinimalStyled = true
    local accent = GetAccent()

    local name = dropdown.GetName and dropdown:GetName() or nil
    if not name then return end

    local left = _G[name .. "Left"]
    local middle = _G[name .. "Middle"]
    local right = _G[name .. "Right"]
    local button = _G[name .. "Button"]
    local text = _G[name .. "Text"]

    if left then left:SetTexture(nil) left:SetAlpha(0) left:Hide() end
    if middle then middle:SetTexture(nil) middle:SetAlpha(0) middle:Hide() end
    if right then right:SetTexture(nil) right:SetAlpha(0) right:Hide() end

    if not button then return end

    local ntex = button.GetNormalTexture and button:GetNormalTexture() or nil
    local ptex = button.GetPushedTexture and button:GetPushedTexture() or nil
    local htex = button.GetHighlightTexture and button:GetHighlightTexture() or nil
    local dtex = button.GetDisabledTexture and button:GetDisabledTexture() or nil
    if ntex then ntex:SetTexture(nil) ntex:SetAlpha(0) ntex:Hide() end
    if ptex then ptex:SetTexture(nil) ptex:SetAlpha(0) ptex:Hide() end
    if htex then htex:SetTexture(nil) htex:SetAlpha(0) htex:Hide() end
    if dtex then dtex:SetTexture(nil) dtex:SetAlpha(0) dtex:Hide() end

    if not button._mabfBg then
        local bg = CreateFrame("Frame", nil, button, "BackdropTemplate")
        bg:SetPoint("TOPLEFT", button, "TOPLEFT", 16, -1)
        bg:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -16, 1)
        bg:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        bg:SetBackdropColor(0.06, 0.06, 0.08, 1)
        bg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
        button._mabfBg = bg

        local arrowBox = CreateFrame("Frame", nil, bg, "BackdropTemplate")
        arrowBox:SetPoint("TOPRIGHT", bg, "TOPRIGHT", 0, 0)
        arrowBox:SetPoint("BOTTOMRIGHT", bg, "BOTTOMRIGHT", 0, 0)
        arrowBox:SetWidth(20)
        arrowBox:SetBackdrop({
            bgFile = "Interface\\Buttons\\WHITE8X8",
            edgeFile = "Interface\\Buttons\\WHITE8X8",
            edgeSize = 1,
        })
        arrowBox:SetBackdropColor(0.05, 0.05, 0.06, 1)
        arrowBox:SetBackdropBorderColor(0.2, 0.2, 0.24, 1)
        button._mabfArrowBox = arrowBox

        local arrow = arrowBox:CreateFontString(nil, "OVERLAY")
        arrow:SetPoint("CENTER", arrowBox, "CENTER", 0, 0)
        arrow:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 12, "OUTLINE")
        arrow:SetText("v")
        arrow:SetTextColor(accent[1], accent[2], accent[3], 0.95)
        button._mabfArrow = arrow

        button:HookScript("OnEnter", function(self)
            if self._mabfBg then
                self._mabfBg:SetBackdropBorderColor(accent[1], accent[2], accent[3], 0.6)
            end
        end)
        button:HookScript("OnLeave", function(self)
            if self._mabfBg then
                self._mabfBg:SetBackdropBorderColor(0.25, 0.25, 0.3, 1)
            end
        end)
    end

    if text then
        text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 10, "")
        text:SetTextColor(0.9, 0.9, 0.9, 1)
        text:ClearAllPoints()
        text:SetPoint("LEFT", button._mabfBg, "LEFT", 8, 0)
        text:SetPoint("RIGHT", button._mabfBg, "RIGHT", -24, 0)
        text:SetJustifyH("RIGHT")
    end
end
