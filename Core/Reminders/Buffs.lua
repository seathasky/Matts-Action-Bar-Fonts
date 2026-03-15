local addonName, MABF = ...
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-----------------------------------------------------------
-- Reminders (Missing Class Buffs)
-----------------------------------------------------------
do
    local BUFFS_DEFAULT_ANCHOR_Y = -230
    local BUFFS_DEFAULT_ANCHOR_X = 0
    local buffsDungeonCombatStarted = false
    local BUFF_GLOW_KEY = "mabf_missing_buff_glow"
    local BUFF_GLOW_COLOR = {1.0, 0.85, 0.2, 1.0}

    local function ClampMissingBuffReminderScale(value)
        local n = tonumber(value) or 1
        if n < 0.5 then
            n = 0.5
        elseif n > 2.0 then
            n = 2.0
        end
        return math.floor(n * 100 + 0.5) / 100
    end

    local classBuffs = {
        MAGE = {
            castSpellID = 1459,
            buffSpellIDs = { 1459, 432778 },
            label = "Arcane Intellect",
        },
        PRIEST = {
            castSpellID = 21562,
            buffSpellIDs = { 21562 },
            label = "Power Word: Fortitude",
        },
        WARRIOR = {
            castSpellID = 6673,
            buffSpellIDs = { 6673 },
            label = "Battle Shout",
        },
        DRUID = {
            castSpellID = 1126,
            buffSpellIDs = { 1126, 432661 },
            label = "Mark of the Wild",
        },
        PALADIN = {
            castSpellID = 465,
            buffSpellIDs = { 465 },
            buffNames = { "Devotion Aura", "Devotion" },
            label = "Devotion Aura",
        },
        EVOKER = {
            castSpellID = 364342, -- Blessing of the Bronze cast spell
            buffSpellIDs = { 381732, 381741, 381746, 381748, 381749, 381750, 381751, 381752, 381753, 381754, 381756, 381757, 381758 },
            label = "Blessing of the Bronze",
        },
        SHAMAN = {
            castSpellID = 462854,
            buffSpellIDs = { 462854, 204330 },
            buffNames = { "Skyfury" },
            label = "Skyfury",
        },
    }

    local function IsInSupportedInstanceContent()
        if not IsInInstance then
            return false
        end
        local inInstance, instanceType = IsInInstance()
        if not inInstance then
            return false
        end
        if not (instanceType == "party" or instanceType == "raid" or instanceType == "scenario") then
            return false
        end
        if GetInstanceInfo then
            local _, _, difficultyID = GetInstanceInfo()
            if (difficultyID or 0) <= 0 then
                return false
            end
        end
        return true
    end

    local function IsKeystoneChallengeActive()
        if C_ChallengeMode and C_ChallengeMode.IsChallengeModeActive and C_ChallengeMode.IsChallengeModeActive() then
            return true
        end
        if C_ChallengeMode and C_ChallengeMode.GetActiveKeystoneInfo then
            local _, level = C_ChallengeMode.GetActiveKeystoneInfo()
            if type(level) == "number" and level > 0 then
                return true
            end
        end
        return false
    end

    local function IsPlayerInCombat()
        return (InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player")) or false
    end

    local function SyncDungeonCombatStarted()
        if not IsInSupportedInstanceContent() then
            buffsDungeonCombatStarted = false
            return
        end
        if IsPlayerInCombat() then
            buffsDungeonCombatStarted = true
        end
    end

    local function GetCurrentClassBuff()
        local _, classToken = UnitClass("player")
        return classToken and classBuffs[classToken] or nil
    end

    local function PlayerCanCastSpell(spellID)
        if not spellID or not IsSpellKnown then
            return false
        end
        return IsSpellKnown(spellID) or (IsPlayerSpell and IsPlayerSpell(spellID)) or false
    end

    local function PlayerHasBuff(spellIDs, buffNames)
        local hasSpellIDs = type(spellIDs) == "table"
        local hasNames = type(buffNames) == "table"
        if not hasSpellIDs and not hasNames then
            return true
        end

        if hasSpellIDs then
            for _, spellID in ipairs(spellIDs) do
                if C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
                    return true
                end
                if AuraUtil and AuraUtil.FindAuraBySpellID and AuraUtil.FindAuraBySpellID(spellID, "player", "HELPFUL") then
                    return true
                end
            end
        end

        if hasNames then
            for _, auraName in ipairs(buffNames) do
                if type(auraName) == "string" and auraName ~= "" then
                    if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName and C_UnitAuras.GetAuraDataBySpellName("player", auraName, "HELPFUL") then
                        return true
                    end
                    if AuraUtil and AuraUtil.FindAuraByName and AuraUtil.FindAuraByName(auraName, "player", "HELPFUL") then
                        return true
                    end
                end
            end
        end

        return false
    end

    local function GetBuffSpellIcon(spellID)
        if not spellID then
            return nil
        end
        if C_Spell and C_Spell.GetSpellTexture then
            local tex = C_Spell.GetSpellTexture(spellID)
            if tex then
                return tex
            end
        end
        if GetSpellTexture then
            local tex = GetSpellTexture(spellID)
            if tex then
                return tex
            end
        end
        if C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            if info and info.iconID then
                return info.iconID
            end
        end
        if GetSpellInfo then
            local _, _, icon = GetSpellInfo(spellID)
            if icon then
                return icon
            end
        end
        return nil
    end

    local function ShouldEvaluateMissingBuffReminder()
        local db = MattActionBarFontDB
        if not db or not db.warnMissingClassBuffs then
            return false
        end
        if db.buffsOnlyInInstance ~= false and not IsInSupportedInstanceContent() then
            return false
        end
        if db.buffsSuppressInMPlus ~= false and IsKeystoneChallengeActive() then
            return false
        end
        if db.buffsHideInRestArea ~= false and IsResting and IsResting() then
            return false
        end
        if db.buffsSuppressAfterFirstPull and buffsDungeonCombatStarted and IsInSupportedInstanceContent() then
            return false
        end
        if db.buffsHideWhenLFGComplete ~= false and IsLFGComplete and IsLFGComplete() then
            return false
        end
        if IsPlayerInCombat() then
            return false
        end
        return true
    end

    local function LayoutMissingBuffReminder(reminderFrame)
        if not reminderFrame or not reminderFrame.icon or not reminderFrame.text then
            return
        end
        local textWidth = reminderFrame.text:GetStringWidth() or 0
        local totalWidth = 18 + 6 + textWidth
        local iconCenterX = -math.floor((totalWidth * 0.5) - 9 + 0.5)
        if reminderFrame.iconFrame then
            reminderFrame.iconFrame:ClearAllPoints()
            reminderFrame.iconFrame:SetPoint("CENTER", reminderFrame, "CENTER", iconCenterX, 0)
        else
            reminderFrame.icon:ClearAllPoints()
            reminderFrame.icon:SetPoint("CENTER", reminderFrame, "CENTER", iconCenterX, 0)
        end
        reminderFrame.text:ClearAllPoints()
        if reminderFrame.iconFrame then
            reminderFrame.text:SetPoint("LEFT", reminderFrame.iconFrame, "RIGHT", 6, 0)
        else
            reminderFrame.text:SetPoint("LEFT", reminderFrame.icon, "RIGHT", 6, 0)
        end
    end

    local function SetMissingBuffGlow(reminderFrame, shouldGlow)
        if not reminderFrame or not reminderFrame.iconFrame or not LCG then
            return
        end
        if shouldGlow then
            if reminderFrame._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Start(reminderFrame.iconFrame, BUFF_GLOW_COLOR, 8, 0.25, 6, 2, 0, 0, false, BUFF_GLOW_KEY, reminderFrame.iconFrame:GetFrameLevel() + 6)
            reminderFrame._mabfGlowActive = true
        else
            if not reminderFrame._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Stop(reminderFrame.iconFrame, BUFF_GLOW_KEY)
            reminderFrame._mabfGlowActive = false
        end
    end

    function MABF:UpdateMissingBuffReminder()
        local reminderFrame = self._missingBuffReminderFrame
        if not reminderFrame or not reminderFrame.text or not reminderFrame.icon then
            return
        end

        if not ShouldEvaluateMissingBuffReminder() then
            SetMissingBuffGlow(reminderFrame, false)
            reminderFrame:Hide()
            return
        end

        local buffInfo = GetCurrentClassBuff()
        if not buffInfo or not PlayerCanCastSpell(buffInfo.castSpellID) then
            SetMissingBuffGlow(reminderFrame, false)
            reminderFrame:Hide()
            return
        end

        if PlayerHasBuff(buffInfo.buffSpellIDs, buffInfo.buffNames) then
            SetMissingBuffGlow(reminderFrame, false)
            reminderFrame:Hide()
            return
        end

        local icon = GetBuffSpellIcon(buffInfo.castSpellID)
        reminderFrame.icon:SetTexture(icon or 134400)
        reminderFrame.text:SetText("Missing: " .. (buffInfo.label or "Class Buff"))
        LayoutMissingBuffReminder(reminderFrame)
        SetMissingBuffGlow(reminderFrame, true)
        reminderFrame:Show()
    end

    function MABF:SetupMissingBuffReminder()
        if not self._missingBuffReminderFrame then
            local reminderFrame = CreateFrame("Frame", "MABFMissingBuffReminderFrame", UIParent)
            reminderFrame:SetSize(360, 26)
            reminderFrame:SetPoint("TOP", UIParent, "TOP", BUFFS_DEFAULT_ANCHOR_X, BUFFS_DEFAULT_ANCHOR_Y)
            reminderFrame:SetFrameStrata("HIGH")
            reminderFrame:SetMovable(true)
            reminderFrame:EnableMouse(true)
            reminderFrame:RegisterForDrag("LeftButton")

            local function SavePosition()
                local db = MattActionBarFontDB
                if not db then return end
                local x, y = reminderFrame:GetCenter()
                if not x or not y then return end
                local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                db.missingBuffReminderPos = { mode = "screenCenter", x = x * scale, y = y * scale }
            end

            local function RestorePosition()
                reminderFrame:ClearAllPoints()
                local pos = MattActionBarFontDB and MattActionBarFontDB.missingBuffReminderPos
                if type(pos) == "table" and pos.mode == "screenCenter" and tonumber(pos.x) and tonumber(pos.y) then
                    local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                    reminderFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / scale, pos.y / scale)
                else
                    reminderFrame:SetPoint("TOP", UIParent, "TOP", BUFFS_DEFAULT_ANCHOR_X, BUFFS_DEFAULT_ANCHOR_Y)
                end
            end

            reminderFrame:SetScript("OnDragStart", function(self)
                if not (IsShiftKeyDown and IsShiftKeyDown()) then return end
                self:StartMoving()
            end)
            reminderFrame:SetScript("OnDragStop", function(self)
                self:StopMovingOrSizing()
                SavePosition()
                RestorePosition()
            end)

            local iconFrame = CreateFrame("Frame", nil, reminderFrame, "BackdropTemplate")
            iconFrame:SetSize(20, 20)
            iconFrame:SetPoint("CENTER", reminderFrame, "CENTER", -84, 0)
            iconFrame:SetBackdrop({
                bgFile = "Interface\\Buttons\\WHITE8X8",
                edgeFile = "Interface\\Buttons\\WHITE8X8",
                edgeSize = 1,
                insets = { left = 0, right = 0, top = 0, bottom = 0 },
            })
            iconFrame:SetBackdropColor(0, 0, 0, 0.15)
            iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
            reminderFrame.iconFrame = iconFrame

            local icon = reminderFrame:CreateTexture(nil, "OVERLAY")
            icon:SetSize(18, 18)
            icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            reminderFrame.icon = icon

            local text = reminderFrame:CreateFontString(nil, "OVERLAY")
            text:SetPoint("LEFT", icon, "RIGHT", 6, 0)
            text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 16, "OUTLINE")
            text:SetTextColor(1, 1, 1, 1)
            text:SetText("Missing: Class Buff")
            reminderFrame.text = text
            LayoutMissingBuffReminder(reminderFrame)

            RestorePosition()
            reminderFrame:Hide()
            self._missingBuffReminderFrame = reminderFrame
        end

        self:ApplyMissingBuffReminderScale()

        if not self._missingBuffReminderEvents then
            self._missingBuffReminderEvents = CreateFrame("Frame")
        end
        local evf = self._missingBuffReminderEvents
        evf:UnregisterAllEvents()
        evf:SetScript("OnEvent", nil)
        evf:SetScript("OnUpdate", nil)

        local db = MattActionBarFontDB
        if not (db and db.warnMissingClassBuffs) then
            self:UpdateMissingBuffReminder()
            return
        end

        evf:RegisterEvent("PLAYER_ENTERING_WORLD")
        evf:RegisterEvent("PLAYER_REGEN_DISABLED")
        evf:RegisterEvent("PLAYER_REGEN_ENABLED")
        evf:RegisterEvent("PLAYER_UPDATE_RESTING")
        evf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        evf:RegisterEvent("UNIT_AURA")
        evf:RegisterEvent("SPELLS_CHANGED")

        evf:SetScript("OnEvent", function(_, event, unit)
            if event == "UNIT_AURA" and unit and unit ~= "player" then
                return
            end
            if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
                SyncDungeonCombatStarted()
            elseif event == "PLAYER_REGEN_DISABLED" then
                if IsInSupportedInstanceContent() then
                    buffsDungeonCombatStarted = true
                end
            elseif event == "PLAYER_REGEN_ENABLED" and not IsInSupportedInstanceContent() then
                buffsDungeonCombatStarted = false
            end
            if MABF and MABF.UpdateMissingBuffReminder then
                MABF:UpdateMissingBuffReminder()
            end
        end)

        local elapsedSinceCheck = 0
        evf:SetScript("OnUpdate", function(_, elapsed)
            elapsedSinceCheck = elapsedSinceCheck + (elapsed or 0)
            if elapsedSinceCheck < 0.5 then
                return
            end
            elapsedSinceCheck = 0
            SyncDungeonCombatStarted()
            if MABF and MABF.UpdateMissingBuffReminder then
                MABF:UpdateMissingBuffReminder()
            end
        end)

        SyncDungeonCombatStarted()
        self:UpdateMissingBuffReminder()
    end

    function MABF:ApplyMissingBuffReminderScale()
        local frame = self._missingBuffReminderFrame
        if not frame then
            return
        end
        local db = MattActionBarFontDB
        local scale = ClampMissingBuffReminderScale(db and db.missingBuffReminderScale or 1.0)
        if db then
            db.missingBuffReminderScale = scale
        end
        frame:SetScale(scale)
    end

    function MABF:ResetMissingBuffReminderPosition()
        local db = MattActionBarFontDB
        if db then
            db.missingBuffReminderPos = nil
        end

        local reminderFrame = self._missingBuffReminderFrame
        if reminderFrame then
            reminderFrame:ClearAllPoints()
            reminderFrame:SetPoint("TOP", UIParent, "TOP", BUFFS_DEFAULT_ANCHOR_X, BUFFS_DEFAULT_ANCHOR_Y)
        end
    end
end
