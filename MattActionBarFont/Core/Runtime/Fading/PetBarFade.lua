local addonName, MABF = ...

-- Runtime logic for pet action bar mouseover fading.
do
    local petBarHooked = false
    local petBarRegenFrame = nil

    local function SetPetHotKeyFadeState(isFaded)
        local alpha = isFaded and 0 or 1
        for i = 1, 10 do
            local btn = _G["PetActionButton" .. i]
            local hotKeyFont = btn and (btn.HotKey or btn.bind)
            if hotKeyFont then
                hotKeyFont._MABFBypassColorLock = true
                if hotKeyFont.SetAlpha then
                    hotKeyFont:SetAlpha(alpha)
                end
                if isFaded then
                    if hotKeyFont.Hide then
                        hotKeyFont:Hide()
                    end
                else
                    if hotKeyFont.Show then
                        hotKeyFont:Show()
                    end
                end
                hotKeyFont._MABFBypassColorLock = nil
            end
        end
    end

    function MABF:IsPetBarFadedOut()
        local bar = _G["PetActionBar"]
        if not bar then
            return false
        end
        return (bar._MABFPetTargetAlpha == 0)
            and MattActionBarFontDB
            and MattActionBarFontDB.petBarMouseoverFade
            and not self._inQuickKeybindMode
    end

    local function SetPetBarAlpha(targetAlpha)
        local bar = _G["PetActionBar"]
        if not bar then return end

        local normalizedAlpha = (targetAlpha and targetAlpha >= 0.5) and 1 or 0
        local currentAlpha = bar:GetAlpha() or normalizedAlpha
        if bar._MABFPetTargetAlpha == normalizedAlpha and math.abs(currentAlpha - normalizedAlpha) < 0.01 then
            return
        end
        bar._MABFPetTargetAlpha = normalizedAlpha

        local duration = tonumber(MattActionBarFontDB and MattActionBarFontDB.actionBarFadeDuration or 0.15) or 0.15
        if duration < 0 then
            duration = 0
        elseif duration > 1 then
            duration = 1
        end

        if duration <= 0 then
            bar:SetAlpha(normalizedAlpha)
            SetPetHotKeyFadeState(normalizedAlpha == 0)
            return
        end

        if UIFrameFadeRemoveFrame then
            UIFrameFadeRemoveFrame(bar)
        end

        if UIFrameFade then
            local mode = normalizedAlpha == 1 and "IN" or "OUT"
            UIFrameFade(bar, {
                mode = mode,
                timeToFade = duration,
                startAlpha = bar:GetAlpha() or (normalizedAlpha == 1 and 0 or 1),
                endAlpha = normalizedAlpha,
            })
        else
            bar:SetAlpha(normalizedAlpha)
        end
        SetPetHotKeyFadeState(normalizedAlpha == 0)
    end

    local function IsPetBarMouseOver()
        local bar = _G["PetActionBar"]
        if bar and MouseIsOver(bar) then return true end
        for i = 1, 10 do
            local btn = _G["PetActionButton" .. i]
            if btn and MouseIsOver(btn) then return true end
        end
        return false
    end

    local function UpdatePetBarAlpha()
        local bar = _G["PetActionBar"]
        if not bar then return end
        if not MattActionBarFontDB or not MattActionBarFontDB.petBarMouseoverFade then
            bar._MABFPetTargetAlpha = 1
            bar:SetAlpha(1)
            SetPetHotKeyFadeState(false)
            return
        end
        if MABF._inQuickKeybindMode then
            bar._MABFPetTargetAlpha = 1
            bar:SetAlpha(1)
            SetPetHotKeyFadeState(false)
            return
        end
        SetPetBarAlpha(IsPetBarMouseOver() and 1 or 0)
    end

    function MABF:ApplyPetBarMouseoverFade()
        if InCombatLockdown and InCombatLockdown() then
            if not petBarRegenFrame then
                petBarRegenFrame = CreateFrame("Frame")
                petBarRegenFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
                petBarRegenFrame:SetScript("OnEvent", function(self)
                    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
                    self:Hide()
                    if MABF and MABF.ApplyPetBarMouseoverFade then
                        MABF:ApplyPetBarMouseoverFade()
                    end
                end)
            end
            petBarRegenFrame:Show()
            return
        end

        if not MattActionBarFontDB.petBarMouseoverFade then
            local bar = _G["PetActionBar"]
            if bar then
                bar._MABFPetTargetAlpha = 1
                bar:SetAlpha(1)
            end
            SetPetHotKeyFadeState(false)
            return
        end

        local bar = _G["PetActionBar"]
        if not bar then return end

        if not petBarHooked then
            bar:HookScript("OnEnter", UpdatePetBarAlpha)
            bar:HookScript("OnLeave", UpdatePetBarAlpha)
            for i = 1, 10 do
                local btn = _G["PetActionButton" .. i]
                if btn then
                    btn:HookScript("OnEnter", UpdatePetBarAlpha)
                    btn:HookScript("OnLeave", UpdatePetBarAlpha)
                end
            end
            petBarHooked = true
        end

        UpdatePetBarAlpha()
    end
end
