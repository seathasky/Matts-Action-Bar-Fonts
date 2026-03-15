local addonName, MABF = ...
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-----------------------------------------------------------
-- Reminders (Class Stuff: Soulstone + Shaman Shields)
-----------------------------------------------------------
do
    local CLASS_STUFF_DEFAULT_ANCHOR_Y = -280
    local CLASS_STUFF_DEFAULT_ANCHOR_X = 0
    local classDungeonCombatStarted = false
    local CLASS_STUFF_GLOW_KEY = "mabf_class_stuff_glow"
    local CLASS_STUFF_GLOW_COLOR = {1.0, 0.85, 0.2, 1.0}

    local SOULSTONE_SPELL_ID = 20707
    local SOULSTONE_BUFF_IDS = { 20707, 160930 }

    local EARTH_SHIELD_SPELL_ID = 974
    local EARTH_SHIELD_BUFF_IDS = { 974, 383648 }
    local LIGHTNING_SHIELD_SPELL_ID = 192106
    local LIGHTNING_SHIELD_BUFF_IDS = { 192106 }
    local WATER_SHIELD_SPELL_ID = 52127
    local WATER_SHIELD_BUFF_IDS = { 52127 }
    local ELEMENTAL_ORBIT_TALENT_SPELL_ID = 383010
    local PALADIN_HOLY_SPEC_ID = 65
    local BEACON_OF_LIGHT_SPELL_ID = 53563
    local BEACON_OF_LIGHT_BUFF_IDS = { 53563 }
    local BEACON_OF_FAITH_SPELL_ID = 156910
    local BEACON_OF_FAITH_BUFF_IDS = { 156910 }
    local BEACON_OF_VIRTUE_TALENT_ID = 200025

    local function ClampClassStuffReminderScale(value)
        local n = tonumber(value) or 1
        if n < 0.5 then
            n = 0.5
        elseif n > 2.0 then
            n = 2.0
        end
        return math.floor(n * 100 + 0.5) / 100
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

    local function SyncDungeonCombatStarted()
        if not IsInSupportedInstanceContent() then
            classDungeonCombatStarted = false
            return
        end
        if IsPlayerInCombat() then
            classDungeonCombatStarted = true
        end
    end

    local function PlayerCanCastSpell(spellID)
        if not spellID or not IsSpellKnown then
            return false
        end
        return IsSpellKnown(spellID) or (IsPlayerSpell and IsPlayerSpell(spellID)) or false
    end

    local function IsSpellReady(spellID)
        if not spellID then
            return false
        end

        if C_Spell and C_Spell.GetSpellCooldown then
            local cooldownInfo = C_Spell.GetSpellCooldown(spellID)
            if cooldownInfo and cooldownInfo.isEnabled then
                local startTime = cooldownInfo.startTime or 0
                local duration = cooldownInfo.duration or 0
                return duration <= 0 or startTime <= 0
            end
        end

        if GetSpellCooldown then
            local startTime, duration, enabled = GetSpellCooldown(spellID)
            if enabled == 0 then
                return false
            end
            return (duration or 0) <= 0 or (startTime or 0) <= 0
        end

        return true
    end

    local function UnitHasAnyBuff(unit, spellIDs)
        if type(spellIDs) ~= "table" then
            return false
        end
        if not unit or not UnitExists or not UnitExists(unit) then
            return false
        end

        for _, spellID in ipairs(spellIDs) do
            if unit == "player" and C_UnitAuras and C_UnitAuras.GetPlayerAuraBySpellID and C_UnitAuras.GetPlayerAuraBySpellID(spellID) then
                return true
            end
            if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellID and C_UnitAuras.GetAuraDataBySpellID(unit, spellID, "HELPFUL") then
                return true
            end
            if AuraUtil and AuraUtil.FindAuraBySpellID and AuraUtil.FindAuraBySpellID(spellID, unit, "HELPFUL") then
                return true
            end

            local spellName = C_Spell and C_Spell.GetSpellName and C_Spell.GetSpellName(spellID)
            if type(spellName) == "string" and spellName ~= "" then
                if C_UnitAuras and C_UnitAuras.GetAuraDataBySpellName and C_UnitAuras.GetAuraDataBySpellName(unit, spellName, "HELPFUL") then
                    return true
                end
                if AuraUtil and AuraUtil.FindAuraByName and AuraUtil.FindAuraByName(spellName, unit, "HELPFUL") then
                    return true
                end
            end
        end

        return false
    end

    local function GroupHasAnyBuff(spellIDs)
        if not IsInGroup or not IsInGroup() then
            return false
        end

        if IsInRaid and IsInRaid() then
            local numMembers = GetNumGroupMembers and GetNumGroupMembers() or 0
            for i = 1, numMembers do
                if UnitHasAnyBuff("raid" .. i, spellIDs) then
                    return true
                end
            end
            return false
        end

        if UnitHasAnyBuff("player", spellIDs) then
            return true
        end

        local numMembers = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for i = 1, numMembers do
            if UnitHasAnyBuff("party" .. i, spellIDs) then
                return true
            end
        end
        return false
    end

    local function GetSpellIcon(spellID)
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
        return nil
    end

    local function HasElementalOrbitTalent()
        return IsPlayerSpell and IsPlayerSpell(ELEMENTAL_ORBIT_TALENT_SPELL_ID) or false
    end

    local function IsRestoShamanSpec()
        if not GetSpecialization or not GetSpecializationInfo then
            return false
        end
        local specIndex = GetSpecialization()
        if not specIndex then
            return false
        end
        local specID = GetSpecializationInfo(specIndex)
        return specID == 264 -- Restoration
    end

    local function IsHolyPaladinSpec()
        if not GetSpecialization or not GetSpecializationInfo then
            return false
        end
        local specIndex = GetSpecialization()
        if not specIndex then
            return false
        end
        local specID = GetSpecializationInfo(specIndex)
        return specID == PALADIN_HOLY_SPEC_ID
    end

    local function GetPreferredElementalShield(knowsLightning, knowsWater, hasLightning, hasWater)
        local preferWater = IsRestoShamanSpec()
        if preferWater then
            if knowsWater and not hasWater then
                return WATER_SHIELD_SPELL_ID
            end
            if knowsLightning and not hasLightning then
                return LIGHTNING_SHIELD_SPELL_ID
            end
        else
            if knowsLightning and not hasLightning then
                return LIGHTNING_SHIELD_SPELL_ID
            end
            if knowsWater and not hasWater then
                return WATER_SHIELD_SPELL_ID
            end
        end
        return nil
    end

    local function PlayerHasEarthShieldOnOtherTarget()
        if not IsInGroup or not IsInGroup() then
            return false
        end

        if IsInRaid and IsInRaid() then
            local numMembers = GetNumGroupMembers and GetNumGroupMembers() or 0
            for i = 1, numMembers do
                local unit = "raid" .. i
                if UnitExists and UnitExists(unit) and not UnitIsUnit(unit, "player") and UnitHasAnyBuff(unit, EARTH_SHIELD_BUFF_IDS) then
                    return true
                end
            end
            return false
        end

        local numMembers = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for i = 1, numMembers do
            local unit = "party" .. i
            if UnitExists and UnitExists(unit) and UnitHasAnyBuff(unit, EARTH_SHIELD_BUFF_IDS) then
                return true
            end
        end
        return false
    end

    local function ShouldEvaluateClassStuffReminder()
        local db = MattActionBarFontDB
        if not db then
            return false
        end
        if not db.warnClassSoulstone and not db.warnClassShamanShields and not db.warnClassPaladinBeacons then
            return false
        end
        if UnitIsDeadOrGhost and UnitIsDeadOrGhost("player") then
            return false
        end
        if db.classOnlyInInstance ~= false and not IsInSupportedInstanceContent() then
            return false
        end
        if db.classSuppressInMPlus ~= false and IsKeystoneChallengeActive() then
            return false
        end
        if db.classHideInRestArea ~= false and IsResting and IsResting() then
            return false
        end
        if db.classSuppressAfterFirstPull and classDungeonCombatStarted and IsInSupportedInstanceContent() then
            return false
        end
        if db.classHideWhenLFGComplete ~= false and IsLFGComplete and IsLFGComplete() then
            return false
        end
        if IsPlayerInCombat() then
            return false
        end
        return true
    end

    local function GetClassStuffReminderData()
        local db = MattActionBarFontDB
        if not db then
            return nil
        end

        local _, classToken = UnitClass("player")
        if classToken == "WARLOCK" and db.warnClassSoulstone then
            if not (IsInGroup and IsInGroup()) then
                return nil
            end
            if not PlayerCanCastSpell(SOULSTONE_SPELL_ID) then
                return nil
            end
            if not IsSpellReady(SOULSTONE_SPELL_ID) then
                return nil
            end
            if GroupHasAnyBuff(SOULSTONE_BUFF_IDS) then
                return nil
            end
            return {
                text = "Soulstone someone!",
                icon = GetSpellIcon(SOULSTONE_SPELL_ID),
            }
        end

        if classToken == "SHAMAN" and db.warnClassShamanShields then
            local knowsEarth = PlayerCanCastSpell(EARTH_SHIELD_SPELL_ID)
            local knowsLightning = PlayerCanCastSpell(LIGHTNING_SHIELD_SPELL_ID)
            local knowsWater = PlayerCanCastSpell(WATER_SHIELD_SPELL_ID)
            local hasOrbit = HasElementalOrbitTalent()
            if not (knowsEarth or knowsLightning or knowsWater) then
                return nil
            end

            local hasEarth = UnitHasAnyBuff("player", EARTH_SHIELD_BUFF_IDS)
            local hasLightning = UnitHasAnyBuff("player", LIGHTNING_SHIELD_BUFF_IDS)
            local hasWater = UnitHasAnyBuff("player", WATER_SHIELD_BUFF_IDS)
            local hasEarthOnOther = knowsEarth and PlayerHasEarthShieldOnOtherTarget() or false

            -- Only require a second Earth Shield target when Elemental Orbit is talented.
            if hasOrbit and knowsEarth and IsInGroup and IsInGroup() and hasEarth and not hasEarthOnOther then
                return { text = "Apply Earth Shield to ally!", icon = GetSpellIcon(EARTH_SHIELD_SPELL_ID) }
            end

            local activeCount = 0
            if hasEarth then activeCount = activeCount + 1 end
            if hasLightning then activeCount = activeCount + 1 end
            if hasWater then activeCount = activeCount + 1 end

            if hasOrbit then
                if activeCount >= 2 then
                    return nil
                end
                if knowsEarth and not hasEarth then
                    return { text = "Apply Earth Shield!", icon = GetSpellIcon(EARTH_SHIELD_SPELL_ID) }
                end
                local elementalShieldSpellID = GetPreferredElementalShield(knowsLightning, knowsWater, hasLightning, hasWater)
                if elementalShieldSpellID then
                    return { text = "Apply Elemental Shield!", icon = GetSpellIcon(elementalShieldSpellID) }
                end
                return nil
            end

            if activeCount >= 1 then
                return nil
            end

            -- No Elemental Orbit:
            -- If Earth is already on an ally, next priority is your self elemental shield.
            if knowsEarth and IsInGroup and IsInGroup() and hasEarthOnOther then
                local elementalShieldSpellID = GetPreferredElementalShield(knowsLightning, knowsWater, hasLightning, hasWater)
                if elementalShieldSpellID then
                    return { text = "Apply Elemental Shield!", icon = GetSpellIcon(elementalShieldSpellID) }
                end
                return nil
            end

            if knowsEarth and not hasEarth then
                return { text = "Apply Earth Shield!", icon = GetSpellIcon(EARTH_SHIELD_SPELL_ID) }
            end
            local elementalShieldSpellID = GetPreferredElementalShield(knowsLightning, knowsWater, hasLightning, hasWater)
            if elementalShieldSpellID then
                return { text = "Apply Elemental Shield!", icon = GetSpellIcon(elementalShieldSpellID) }
            end
            return nil
        end

        if classToken == "PALADIN" and db.warnClassPaladinBeacons then
            if not IsHolyPaladinSpec() then
                return nil
            end
            if IsPlayerSpell and IsPlayerSpell(BEACON_OF_VIRTUE_TALENT_ID) then
                return nil
            end

            local knowsLight = PlayerCanCastSpell(BEACON_OF_LIGHT_SPELL_ID)
            local knowsFaith = PlayerCanCastSpell(BEACON_OF_FAITH_SPELL_ID)
            if not (knowsLight or knowsFaith) then
                return nil
            end

            local hasFaith = (IsInGroup and IsInGroup()) and GroupHasAnyBuff(BEACON_OF_FAITH_BUFF_IDS) or UnitHasAnyBuff("player", BEACON_OF_FAITH_BUFF_IDS)
            local hasLight = (IsInGroup and IsInGroup()) and GroupHasAnyBuff(BEACON_OF_LIGHT_BUFF_IDS) or UnitHasAnyBuff("player", BEACON_OF_LIGHT_BUFF_IDS)

            -- If both beacons are available, require both buffs to be present.
            if knowsFaith and knowsLight then
                if hasFaith and hasLight then
                    return nil
                end
                if not hasFaith then
                    return { text = "Apply Beacon of Faith!", icon = GetSpellIcon(BEACON_OF_FAITH_SPELL_ID) }
                end
                return { text = "Apply Beacon of Light!", icon = GetSpellIcon(BEACON_OF_LIGHT_SPELL_ID) }
            end

            -- Otherwise only require the beacon this character can cast.
            if knowsFaith then
                if hasFaith then
                    return nil
                end
                return { text = "Apply Beacon of Faith!", icon = GetSpellIcon(BEACON_OF_FAITH_SPELL_ID) }
            end
            if knowsLight then
                if hasLight then
                    return nil
                end
                return { text = "Apply Beacon of Light!", icon = GetSpellIcon(BEACON_OF_LIGHT_SPELL_ID) }
            end

            return nil
        end

        return nil
    end

    local function LayoutClassStuffReminder(reminderFrame)
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

    local function SetClassStuffGlow(reminderFrame, shouldGlow)
        if not reminderFrame or not reminderFrame.iconFrame or not LCG then
            return
        end
        if shouldGlow then
            if reminderFrame._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Start(reminderFrame.iconFrame, CLASS_STUFF_GLOW_COLOR, 8, 0.25, 6, 2, 0, 0, false, CLASS_STUFF_GLOW_KEY, reminderFrame.iconFrame:GetFrameLevel() + 6)
            reminderFrame._mabfGlowActive = true
        else
            if not reminderFrame._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Stop(reminderFrame.iconFrame, CLASS_STUFF_GLOW_KEY)
            reminderFrame._mabfGlowActive = false
        end
    end

    function MABF:UpdateClassStuffReminder()
        local reminderFrame = self._classStuffReminderFrame
        if not reminderFrame or not reminderFrame.text or not reminderFrame.icon then
            return
        end

        if not ShouldEvaluateClassStuffReminder() then
            SetClassStuffGlow(reminderFrame, false)
            reminderFrame:Hide()
            return
        end

        local reminderData = GetClassStuffReminderData()
        if not reminderData then
            SetClassStuffGlow(reminderFrame, false)
            reminderFrame:Hide()
            return
        end

        reminderFrame.icon:SetTexture(reminderData.icon or 134400)
        reminderFrame.text:SetText(reminderData.text or "Class reminder")
        LayoutClassStuffReminder(reminderFrame)
        SetClassStuffGlow(reminderFrame, true)
        reminderFrame:Show()
    end

    function MABF:SetupClassStuffReminder()
        if not self._classStuffReminderFrame then
            local reminderFrame = CreateFrame("Frame", "MABFClassStuffReminderFrame", UIParent)
            reminderFrame:SetSize(360, 26)
            reminderFrame:SetPoint("TOP", UIParent, "TOP", CLASS_STUFF_DEFAULT_ANCHOR_X, CLASS_STUFF_DEFAULT_ANCHOR_Y)
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
                db.classStuffReminderPos = { mode = "screenCenter", x = x * scale, y = y * scale }
            end

            local function RestorePosition()
                reminderFrame:ClearAllPoints()
                local pos = MattActionBarFontDB and MattActionBarFontDB.classStuffReminderPos
                if type(pos) == "table" and pos.mode == "screenCenter" and tonumber(pos.x) and tonumber(pos.y) then
                    local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                    reminderFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / scale, pos.y / scale)
                else
                    reminderFrame:SetPoint("TOP", UIParent, "TOP", CLASS_STUFF_DEFAULT_ANCHOR_X, CLASS_STUFF_DEFAULT_ANCHOR_Y)
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
            text:SetPoint("LEFT", iconFrame, "RIGHT", 6, 0)
            text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 16, "OUTLINE")
            text:SetTextColor(1, 1, 1, 1)
            text:SetText("Class reminder")
            reminderFrame.text = text
            LayoutClassStuffReminder(reminderFrame)

            RestorePosition()
            reminderFrame:Hide()
            self._classStuffReminderFrame = reminderFrame
        end

        self:ApplyClassStuffReminderScale()

        if not self._classStuffReminderEvents then
            self._classStuffReminderEvents = CreateFrame("Frame")
        end
        local evf = self._classStuffReminderEvents
        evf:UnregisterAllEvents()
        evf:SetScript("OnEvent", nil)
        evf:SetScript("OnUpdate", nil)

        local db = MattActionBarFontDB
        if not (db and (db.warnClassSoulstone or db.warnClassShamanShields or db.warnClassPaladinBeacons)) then
            self:UpdateClassStuffReminder()
            return
        end

        evf:RegisterEvent("PLAYER_ENTERING_WORLD")
        evf:RegisterEvent("PLAYER_REGEN_DISABLED")
        evf:RegisterEvent("PLAYER_REGEN_ENABLED")
        evf:RegisterEvent("PLAYER_UPDATE_RESTING")
        evf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        evf:RegisterEvent("UNIT_AURA")
        evf:RegisterEvent("SPELLS_CHANGED")
        evf:RegisterEvent("SPELL_UPDATE_COOLDOWN")
        evf:RegisterEvent("GROUP_ROSTER_UPDATE")

        evf:SetScript("OnEvent", function(_, event, unit)
            if event == "UNIT_AURA" and unit and unit ~= "player" then
                local _, classToken = UnitClass("player")
                if classToken ~= "WARLOCK" and classToken ~= "SHAMAN" and classToken ~= "PALADIN" then
                    return
                end
            end
            if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
                SyncDungeonCombatStarted()
            elseif event == "PLAYER_REGEN_DISABLED" then
                if IsInSupportedInstanceContent() then
                    classDungeonCombatStarted = true
                end
            elseif event == "PLAYER_REGEN_ENABLED" and not IsInSupportedInstanceContent() then
                classDungeonCombatStarted = false
            end
            if MABF and MABF.UpdateClassStuffReminder then
                MABF:UpdateClassStuffReminder()
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
            if MABF and MABF.UpdateClassStuffReminder then
                MABF:UpdateClassStuffReminder()
            end
        end)

        SyncDungeonCombatStarted()
        self:UpdateClassStuffReminder()
    end

    function MABF:ApplyClassStuffReminderScale()
        local frame = self._classStuffReminderFrame
        if not frame then
            return
        end
        local db = MattActionBarFontDB
        local scale = ClampClassStuffReminderScale(db and db.classStuffReminderScale or 1.0)
        if db then
            db.classStuffReminderScale = scale
        end
        frame:SetScale(scale)
    end

    function MABF:ResetClassStuffReminderPosition()
        local db = MattActionBarFontDB
        if db then
            db.classStuffReminderPos = nil
        end

        local reminderFrame = self._classStuffReminderFrame
        if reminderFrame then
            reminderFrame:ClearAllPoints()
            reminderFrame:SetPoint("TOP", UIParent, "TOP", CLASS_STUFF_DEFAULT_ANCHOR_X, CLASS_STUFF_DEFAULT_ANCHOR_Y)
        end
    end
end
