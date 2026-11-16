local addonName, MABF = ...
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)
local isWoWForever = select(4, GetBuildInfo()) == 16001

-----------------------------------------------------------
-- Reminders (Missing Class Buffs)
-----------------------------------------------------------
do
    local BUFFS_DEFAULT_ANCHOR_Y = -230
    local BUFFS_DEFAULT_ANCHOR_X = 0
    local WELL_RESTED_SPELL_ID = 429959
    local WELL_RESTED_ICON_ID = 133662
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
            castSpellIDs = { 1459, 23028 },
            -- Retail Arcane Intellect plus every Classic Era rank and Arcane Brilliance.
            buffSpellIDs = { 1459, 1460, 1461, 10156, 10157, 23028, 432778 },
            label = "Arcane Intellect",
        },
        PRIEST = {
            castSpellID = 21562,
            castSpellIDs = { 21562, 1243, 1244, 1245, 2791, 10937, 10938 },
            -- Retail Power Word: Fortitude plus Classic Era ranks and Prayer of Fortitude.
            buffSpellIDs = { 21562, 1243, 1244, 1245, 2791, 10937, 10938, 21564 },
            label = "Power Word: Fortitude",
        },
        WARRIOR = {
            castSpellID = 6673,
            castSpellIDs = { 6673, 5242, 6192, 11549, 11550 },
            -- Retail Battle Shout plus every Classic Era rank.
            buffSpellIDs = { 6673, 5242, 6192, 11549, 11550 },
            label = "Battle Shout",
        },
        DRUID = {
            castSpellID = 1126,
            castSpellIDs = { 1126, 5232, 6756, 8907, 9884, 9885, 21849, 21850, 26990 },
            -- Retail Mark of the Wild plus Classic Era ranks and Gift of the Wild.
            buffSpellIDs = { 1126, 5232, 6756, 8907, 9884, 9885, 21849, 21850, 26990, 432661 },
            label = "Mark of the Wild",
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

    if isWoWForever then
        -- All Forever ranks of Might, Wisdom and Kings, including Greater Blessings.
        local blessings = {
            19740, 19834, 19835, 19836, 19837, 19838, 25291, 25782, 25916,
            19742, 19850, 19852, 19853, 19854, 25290, 25894, 25918,
            20217, 25898,
        }
        classBuffs.PALADIN = {
            castSpellID = 19740,
            castSpellIDs = blessings,
            buffSpellIDs = blessings,
            iconSpellIDs = { 19740, 19742, 20217 },
            label = "Paladin Blessing",
        }
        -- Any one major class buff cast by the player on themselves counts.
        for _, buffInfo in pairs(classBuffs) do
            buffInfo.requiresOwnBuff = true
        end
        classBuffs.WARRIOR.castSpellIDs = { 6673, 5242, 6192, 11549, 11550, 11551, 25289 }
        classBuffs.WARRIOR.buffSpellIDs = { 6673, 5242, 6192, 11549, 11550, 11551, 25289 }
    end

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

    local function IsPlayerMounted()
        if IsMounted and IsMounted() then
            return true
        end
        if UnitOnTaxi and UnitOnTaxi("player") then
            return true
        end
        return false
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

    local cachedClassToken = nil
    local function GetCurrentClassToken()
        if cachedClassToken then
            return cachedClassToken
        end
        if UnitClass then
            local _, classToken = UnitClass("player")
            cachedClassToken = classToken
        end
        return cachedClassToken
    end

    local function GetCurrentClassBuff()
        local classToken = GetCurrentClassToken()
        return classToken and classBuffs[classToken] or nil
    end

    local function PlayerCanCastSpell(spellID)
        if type(spellID) == "table" then
            for _, candidateSpellID in ipairs(spellID) do
                if PlayerCanCastSpell(candidateSpellID) then
                    return true
                end
            end
            return false
        end
        if not spellID or not IsSpellKnown then
            return false
        end
        return IsSpellKnown(spellID) or (IsPlayerSpell and IsPlayerSpell(spellID)) or false
    end

    local buffSpellNames = {}
    local function GetBuffSpellName(spellID)
        if buffSpellNames[spellID] then return buffSpellNames[spellID] end
        local name
        if C_Spell and C_Spell.GetSpellName then
            name = C_Spell.GetSpellName(spellID)
        elseif C_Spell and C_Spell.GetSpellInfo then
            local info = C_Spell.GetSpellInfo(spellID)
            name = info and info.name
        elseif GetSpellInfo then
            name = GetSpellInfo(spellID)
        end
        -- Retry unresolved names on the next update (spell data may still be loading).
        if name then buffSpellNames[spellID] = name end
        return name
    end

    local function IsOwnAura(source, auraInstanceID)
        if issecretvalue and issecretvalue(source) then return nil end
        if source == "player" then return true end
        if source and UnitIsUnit then
            local ok, same = pcall(UnitIsUnit, source, "player")
            if ok and not (issecretvalue and issecretvalue(same)) and same then return true end
        end
        -- sourceUnit can be absent when the caster has no usable unit token.
        -- A caster GUID, when available, provides an exact ownership check.
        if not (issecretvalue and issecretvalue(auraInstanceID)) and auraInstanceID
            and C_UnitAuras and C_UnitAuras.GetAuraCasterGUID and UnitGUID then
            local ok, casterGUID = pcall(C_UnitAuras.GetAuraCasterGUID, "player", auraInstanceID)
            local playerGUID = UnitGUID("player")
            if ok and not (issecretvalue and (issecretvalue(casterGUID) or issecretvalue(playerGUID)))
                and casterGUID and playerGUID then
                return casterGUID == playerGUID
            end
        end
        if source then return false end
        return nil -- A present blessing with unknown ownership is not proof it is missing.
    end

    local function PlayerHasTrackedBuff(spellIDs, requiresOwnBuff)
        local tracked = {}
        local trackedNames = {}
        for _, spellID in ipairs(spellIDs) do
            tracked[spellID] = true
            local name = GetBuffSpellName(spellID)
            if name then trackedNames[name] = true end
        end

        -- Inspect the caster explicitly rather than relying on PLAYER filtering.
        -- Only the player's character is scanned, never party members or targets.
        local filter = "HELPFUL"
        local ownershipUnknown = false
        for index = 1, 255 do
            if C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret
                and C_Secrets.ShouldUnitAuraIndexBeSecret("player", index, filter) then
                return nil -- Unknown until this aura becomes readable.
            end
            local name, spellID, source, auraInstanceID
            if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
                local aura = C_UnitAuras.GetBuffDataByIndex("player", index, filter)
                if issecretvalue and issecretvalue(aura) then return nil end
                if not aura then break end
                name, spellID = aura.name, aura.spellId
                source, auraInstanceID = aura.sourceUnit, aura.auraInstanceID
            elseif C_UnitAuras and C_UnitAuras.GetAuraDataByIndex then
                local aura = C_UnitAuras.GetAuraDataByIndex("player", index, filter)
                if issecretvalue and issecretvalue(aura) then return nil end
                if not aura then break end
                name, spellID = aura.name, aura.spellId
                source, auraInstanceID = aura.sourceUnit, aura.auraInstanceID
            elseif UnitBuff then
                local auraName, _, _, _, _, _, caster, _, _, id = UnitBuff("player", index, filter)
                name, spellID, source = auraName, id, caster
            else
                return nil
            end
            if issecretvalue and (issecretvalue(name) or issecretvalue(spellID)) then
                return nil
            end
            if not name then break end
            -- Forever can use a different aura ID from the original cast/rank ID.
            if tracked[spellID] or trackedNames[name] then
                if not requiresOwnBuff then return true end
                local own = IsOwnAura(source, auraInstanceID)
                if own == true then return true end
                if own == nil then ownershipUnknown = true end
            end
        end
        if ownershipUnknown then return nil end
        return false
    end

    -- Read-only diagnostics for checking the actual Forever payload rather than
    -- inferring spell IDs or caster behavior from buff icons.
    SLASH_MABFBUFFDEBUG1 = "/mabfbuffs"
    SlashCmdList["MABFBUFFDEBUG"] = function()
        local function readable(value)
            if issecretvalue and issecretvalue(value) then return "<secret>" end
            return tostring(value)
        end
        local function out(message) print("|cff00ff00MABF buffs:|r " .. message) end
        if IsPlayerInCombat() or (C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret()) then
            out("Run this out of combat when auras are readable.")
            return
        end
        local version, build, _, interface = GetBuildInfo()
        out("self-cast check; client=" .. readable(version) .. " build=" .. readable(build) .. " interface=" .. readable(interface))
        local buffInfo = GetCurrentClassBuff()
        if buffInfo then
            local ok, result = pcall(PlayerHasTrackedBuff, buffInfo.buffSpellIDs, true)
            out("own buff result=" .. (ok and readable(result) or "unreadable"))
        end
        local reader = C_UnitAuras and (C_UnitAuras.GetBuffDataByIndex or C_UnitAuras.GetAuraDataByIndex)
        if not reader then out("Modern aura reader unavailable."); return end
        for index = 1, 255 do
            local ok, aura = pcall(reader, "player", index, "HELPFUL")
            if not ok then out("Aura " .. index .. " unreadable."); break end
            if issecretvalue and issecretvalue(aura) then out("Aura " .. index .. " secret."); break end
            if not aura then break end
            out(index .. ": " .. readable(aura.name) .. " id=" .. readable(aura.spellId)
                .. " source=" .. readable(aura.sourceUnit)
                .. " own=" .. readable(IsOwnAura(aura.sourceUnit, aura.auraInstanceID)))
        end
    end

    local function PlayerHasBuff(spellIDs, buffNames, requiresOwnBuff)
        -- Forever class entries explicitly choose whether the caster matters.
        if requiresOwnBuff ~= nil then
            return PlayerHasTrackedBuff(spellIDs, requiresOwnBuff)
        end
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

    local function SetMissingBuffIcon(reminderFrame, buffInfo)
        local segments = reminderFrame.blessingIconSegments
        if buffInfo.iconSpellIDs then
            -- One compact badge with three readable icons and dark separators.
            reminderFrame.iconWidth = 56
            reminderFrame.icon:SetSize(56, 18)
            if reminderFrame.iconFrame then reminderFrame.iconFrame:SetSize(58, 20) end
            if not segments then
                segments = {}
                for i = 1, 3 do
                    local segment = reminderFrame:CreateTexture(nil, "OVERLAY")
                    segment:SetSize(18, 18)
                    segment:SetPoint("TOPLEFT", reminderFrame.icon, "TOPLEFT", (i - 1) * 19, 0)
                    segment:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    segments[i] = segment
                end
                reminderFrame.blessingIconSegments = segments
            end
            reminderFrame.icon:SetTexture(nil)
            for i, spellID in ipairs(buffInfo.iconSpellIDs) do
                segments[i]:SetTexture(GetBuffSpellIcon(spellID) or 134400)
                segments[i]:Show()
            end
        else
            reminderFrame.iconWidth = 18
            reminderFrame.icon:SetSize(18, 18)
            if reminderFrame.iconFrame then reminderFrame.iconFrame:SetSize(20, 20) end
            if segments then
                for _, segment in ipairs(segments) do segment:Hide() end
            end
            reminderFrame.icon:SetTexture(GetBuffSpellIcon(buffInfo.castSpellID) or 134400)
        end
    end

    local function ShouldEvaluateMissingBuffReminder()
        local db = MattActionBarFontDB
        if not db or not (db.warnMissingClassBuffs or (isWoWForever and db.warnWellRested)) then
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
        if db.buffsHideWhileMounted and IsPlayerMounted() then
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
        -- Aura restrictions can outlast combat; do not call aura readers while
        -- the client forbids access, even if the player is already out of combat.
        if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
            return false
        end
        return true
    end

    local function LayoutMissingBuffReminder(reminderFrame)
        if not reminderFrame or not reminderFrame.icon or not reminderFrame.text then
            return
        end
        local textWidth = reminderFrame.text:GetStringWidth() or 0
        local iconWidth = reminderFrame.iconWidth or 18
        local totalWidth = iconWidth + 6 + textWidth
        local iconCenterX = -math.floor((totalWidth * 0.5) - iconWidth * 0.5 + 0.5)
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
            SetMissingBuffGlow(reminderFrame.wellRestedFrame, false)
            reminderFrame:Hide()
            return
        end

        local db = MattActionBarFontDB
        local buffInfo = GetCurrentClassBuff()
        local classMissing = db.warnMissingClassBuffs and buffInfo
            and PlayerCanCastSpell(buffInfo.castSpellIDs or buffInfo.castSpellID)
            and PlayerHasBuff(buffInfo.buffSpellIDs, buffInfo.buffNames, buffInfo.requiresOwnBuff) == false
            or false

        if classMissing then
            SetMissingBuffIcon(reminderFrame, buffInfo)
            reminderFrame.text:SetText("Missing: " .. (buffInfo.label or "Class Buff"))
            LayoutMissingBuffReminder(reminderFrame)
        end
        reminderFrame.iconFrame:SetShown(classMissing)
        reminderFrame.icon:SetShown(classMissing)
        reminderFrame.text:SetShown(classMissing)
        if reminderFrame.blessingIconSegments then
            for _, segment in ipairs(reminderFrame.blessingIconSegments) do
                segment:SetShown(classMissing and buffInfo.iconSpellIDs ~= nil)
            end
        end
        SetMissingBuffGlow(reminderFrame, classMissing)

        local wellRestedFrame = reminderFrame.wellRestedFrame
        local wellRestedMissing = isWoWForever and db.warnWellRested
            and PlayerHasBuff({ WELL_RESTED_SPELL_ID }) == false or false
        if wellRestedFrame then
            wellRestedFrame:ClearAllPoints()
            wellRestedFrame:SetPoint("CENTER", reminderFrame, "CENTER", 0, classMissing and -30 or 0)
            wellRestedFrame:SetShown(wellRestedMissing)
            SetMissingBuffGlow(wellRestedFrame, wellRestedMissing)
        end
        reminderFrame:SetShown(classMissing or wellRestedMissing)
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

            if isWoWForever then
                local row = CreateFrame("Frame", nil, reminderFrame)
                row:SetSize(360, 26)
                row:SetPoint("CENTER", reminderFrame, "CENTER", 0, 0)
                local border = CreateFrame("Frame", nil, row, "BackdropTemplate")
                border:SetSize(20, 20)
                border:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                })
                border:SetBackdropColor(0, 0, 0, 0.15)
                border:SetBackdropBorderColor(0, 0, 0, 1)
                row.iconFrame = border
                row.icon = row:CreateTexture(nil, "OVERLAY")
                row.icon:SetSize(18, 18)
                row.icon:SetPoint("CENTER", border, "CENTER", 0, 0)
                row.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                row.icon:SetTexture(WELL_RESTED_ICON_ID)
                row.text = row:CreateFontString(nil, "OVERLAY")
                row.text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 16, "OUTLINE")
                row.text:SetTextColor(1, 1, 1, 1)
                row.text:SetText("Missing: Well-Rested")
                LayoutMissingBuffReminder(row)
                row:Hide()
                reminderFrame.wellRestedFrame = row
            end

            RestorePosition()
            reminderFrame:Hide()
            self._missingBuffReminderFrame = reminderFrame
        end

        self:ApplyMissingBuffReminderScale()
        if self.ApplyRemindersClickthroughLock then
            self:ApplyRemindersClickthroughLock()
        end

        if not self._missingBuffReminderEvents then
            self._missingBuffReminderEvents = CreateFrame("Frame")
        end
        local evf = self._missingBuffReminderEvents
        evf:UnregisterAllEvents()
        evf:SetScript("OnEvent", nil)
        evf:SetScript("OnUpdate", nil)
        if self._missingBuffReminderTicker and self._missingBuffReminderTicker.Cancel then
            self._missingBuffReminderTicker:Cancel()
            self._missingBuffReminderTicker = nil
        end

        local db = MattActionBarFontDB
        if not (db and (db.warnMissingClassBuffs or (isWoWForever and db.warnWellRested))) then
            self:UpdateMissingBuffReminder()
            return
        end

        evf:RegisterEvent("PLAYER_ENTERING_WORLD")
        evf:RegisterEvent("PLAYER_REGEN_DISABLED")
        evf:RegisterEvent("PLAYER_REGEN_ENABLED")
        evf:RegisterEvent("PLAYER_UPDATE_RESTING")
        evf:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
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

        if C_Timer and C_Timer.NewTicker then
            self._missingBuffReminderTicker = C_Timer.NewTicker(1.0, function()
                SyncDungeonCombatStarted()
                if MABF and MABF.UpdateMissingBuffReminder then
                    MABF:UpdateMissingBuffReminder()
                end
            end)
        end

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
