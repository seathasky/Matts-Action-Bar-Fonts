local addonName, MABF = ...
local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-- Reminders (Pet Missing + Passive Warning)
-----------------------------------------------------------
do
    local PET_DEFAULT_ANCHOR_X = 0
    local PET_DEFAULT_ANCHOR_Y = 210
    local petDungeonCombatStarted = false
    local PET_GLOW_KEY = "mabf_missing_pet_glow"
    local PET_GLOW_COLOR = {1.0, 0.85, 0.2, 1.0}

    local HUNTER_MARKSMANSHIP_SPEC_ID = 254
    local HUNTER_MM_PET_TALENT_ID = 1223323 -- Unbreakable Bond
    local DEATHKNIGHT_UNHOLY_SPEC_ID = 252
    local MAGE_FROST_SPEC_ID = 64
    local MAGE_WATER_ELEMENTAL_SPELL_ID = 31687

    local function ClampPetReminderScale(value)
        local n = tonumber(value) or 1
        if n < 0.5 then
            n = 0.5
        elseif n > 2.0 then
            n = 2.0
        end
        return math.floor(n * 100 + 0.5) / 100
    end

    local function GetCurrentSpecID()
        if not (GetSpecialization and GetSpecializationInfo) then
            return nil
        end
        local specIndex = GetSpecialization()
        if not specIndex then
            return nil
        end
        return GetSpecializationInfo(specIndex)
    end

    local function IsTrackedPetClass()
        local _, classToken = UnitClass("player")
        if not classToken then
            return false
        end

        if classToken == "WARLOCK" then
            return true
        end

        local specID = GetCurrentSpecID()
        if classToken == "HUNTER" then
            if specID == HUNTER_MARKSMANSHIP_SPEC_ID then
                return IsPlayerSpell and IsPlayerSpell(HUNTER_MM_PET_TALENT_ID) or false
            end
            return true
        end

        if classToken == "DEATHKNIGHT" then
            return specID == DEATHKNIGHT_UNHOLY_SPEC_ID
        end

        if classToken == "MAGE" then
            if specID ~= MAGE_FROST_SPEC_ID then
                return false
            end
            return IsPlayerSpell and IsPlayerSpell(MAGE_WATER_ELEMENTAL_SPELL_ID) or false
        end

        return false
    end

    local function IsPetCurrentlyPassive()
        if not UnitExists or not UnitExists("pet") then
            return false
        end
        if not GetPetActionInfo then
            return false
        end

        local function NormalizeTexturePath(textureValue)
            if type(textureValue) ~= "string" or textureValue == "" then
                return nil
            end
            return textureValue:lower():gsub("/", "\\")
        end

        local passiveTexturePath = NormalizeTexturePath(PET_PASSIVE_TEXTURE)
        local slots = NUM_PET_ACTION_SLOTS or 10
        for i = 1, slots do
            local name, texture, _, isActive = GetPetActionInfo(i)
            if isActive then
                local resolvedTexture = (type(texture) == "string" and _G[texture]) or texture
                local rawTexturePath = NormalizeTexturePath(texture)
                local resolvedTexturePath = NormalizeTexturePath(resolvedTexture)

                if texture == "PET_PASSIVE_TEXTURE" or name == "PET_PASSIVE" or name == "PET_ACTION_PASSIVE" then
                    return true
                end

                if passiveTexturePath and (
                    (rawTexturePath and rawTexturePath == passiveTexturePath)
                    or (resolvedTexturePath and resolvedTexturePath == passiveTexturePath)
                ) then
                    return true
                end

                if (rawTexturePath and rawTexturePath:find("ability_seal", 1, true))
                    or (resolvedTexturePath and resolvedTexturePath:find("ability_seal", 1, true)) then
                    return true
                end
            end
        end

        return false
    end

    local function IsPetMissing()
        if not UnitExists or not UnitExists("pet") then
            return true
        end
        if UnitIsDead and UnitIsDead("pet") then
            return true
        end
        return false
    end

    local function IsPlayerInCombat()
        return ((InCombatLockdown and InCombatLockdown()) or (UnitAffectingCombat and UnitAffectingCombat("player"))) and true or false
    end

    local function IsInSupportedInstanceContent()
        if not IsInInstance then
            return false
        end
        local inInstance, instanceType = IsInInstance()
        if not inInstance then
            return false
        end
        return (instanceType == "party" or instanceType == "raid" or instanceType == "scenario")
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

    local function SyncDungeonCombatStarted()
        if not IsInSupportedInstanceContent() then
            petDungeonCombatStarted = false
            return
        end
        if IsPlayerInCombat() then
            petDungeonCombatStarted = true
        end
    end

    local function GetMissingPetTextAndIcon()
        local _, classToken = UnitClass("player")
        if classToken == "HUNTER" then
            return "Summon Pet", 136095
        end
        if classToken == "DEATHKNIGHT" then
            return "Raise Dead", 1100170
        end
        if classToken == "MAGE" then
            return "Summon Elemental", 135862
        end
        if classToken == "WARLOCK" then
            local icon = (C_Spell and C_Spell.GetSpellTexture and C_Spell.GetSpellTexture(688))
                or (GetSpellTexture and GetSpellTexture(688))
                or 136218
            return "Summon Pet", icon
        end
        return "Missing Pet", 136218
    end

    local function ShouldShowMissingPetWarning()
        local db = MattActionBarFontDB
        if not db or not db.warnMissingPet then
            return false
        end
        if not IsTrackedPetClass() then
            return false
        end
        if db.petMissingOnlyInInstance ~= false and not IsInSupportedInstanceContent() then
            return false
        end
        if db.petMissingSuppressInMPlus ~= false and IsKeystoneChallengeActive() then
            return false
        end
        if db.petMissingHideInRestArea ~= false and IsResting and IsResting() then
            return false
        end
        if db.petMissingSuppressAfterFirstPull and petDungeonCombatStarted and IsInSupportedInstanceContent() then
            return false
        end
        if db.petMissingHideWhenLFGComplete ~= false and IsLFGComplete and IsLFGComplete() then
            return false
        end
        return IsPetMissing()
    end

    local function ShouldShowPetPassiveWarning()
        local db = MattActionBarFontDB
        if not db or not db.warnPetPassive then
            return false
        end
        if not IsTrackedPetClass() then
            return false
        end
        if not IsPlayerInCombat() then
            return false
        end
        return IsPetCurrentlyPassive()
    end

    local function GetCurrentClassLabel()
        local className = UnitClass and select(1, UnitClass("player"))
        return className or "Player"
    end

    local function GetCurrentClassColor()
        local _, classToken = UnitClass and UnitClass("player")
        if C_ClassColor and C_ClassColor.GetClassColor and classToken then
            local classColor = C_ClassColor.GetClassColor(classToken)
            if classColor then
                return classColor.r or 1, classColor.g or 1, classColor.b or 1
            end
        end
        if RAID_CLASS_COLORS and classToken and RAID_CLASS_COLORS[classToken] then
            local color = RAID_CLASS_COLORS[classToken]
            return color.r or 1, color.g or 1, color.b or 1
        end
        return 1, 1, 1
    end

    local function SetMissingPetGlow(reminderFrame, shouldGlow)
        if not reminderFrame or not reminderFrame.iconFrame or not LCG then
            return
        end
        if shouldGlow then
            if reminderFrame._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Start(reminderFrame.iconFrame, PET_GLOW_COLOR, 8, 0.25, 6, 2, 0, 0, false, PET_GLOW_KEY, reminderFrame.iconFrame:GetFrameLevel() + 6)
            reminderFrame._mabfGlowActive = true
        else
            if not reminderFrame._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Stop(reminderFrame.iconFrame, PET_GLOW_KEY)
            reminderFrame._mabfGlowActive = false
        end
    end

    function MABF:UpdatePetPassiveReminder()
        local reminderFrame = self._petPassiveReminderFrame
        if not reminderFrame then
            return
        end
        if ShouldShowMissingPetWarning() then
            if reminderFrame.text then
                local actionText, iconTexture = GetMissingPetTextAndIcon()
                reminderFrame.text:SetText(GetCurrentClassLabel() .. ": " .. actionText)
                local r, g, b = GetCurrentClassColor()
                reminderFrame.text:SetTextColor(r, g, b, 1)
                if reminderFrame.icon then
                    reminderFrame.icon:SetTexture(iconTexture)
                    reminderFrame.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                    reminderFrame.icon:Show()
                end
            end
            SetMissingPetGlow(reminderFrame, true)
            reminderFrame:Show()
        elseif ShouldShowPetPassiveWarning() then
            if reminderFrame.text then
                reminderFrame.text:SetText(GetCurrentClassLabel() .. ": Pet is on Passive")
                local r, g, b = GetCurrentClassColor()
                reminderFrame.text:SetTextColor(r, g, b, 1)
            end
            if reminderFrame.icon then
                reminderFrame.icon:Show()
                if SetPortraitTexture then
                    SetPortraitTexture(reminderFrame.icon, "pet")
                    reminderFrame.icon:SetTexCoord(0, 1, 0, 1)
                end
            end
            SetMissingPetGlow(reminderFrame, false)
            reminderFrame:Show()
        else
            SetMissingPetGlow(reminderFrame, false)
            if reminderFrame.icon then
                reminderFrame.icon:Hide()
            end
            reminderFrame:Hide()
        end
    end

    function MABF:SetupPetPassiveReminder()
        if not self._petPassiveReminderFrame then
            local reminderFrame = CreateFrame("Frame", "MABFPetPassiveReminderFrame", UIParent, "BackdropTemplate")
            reminderFrame:SetSize(360, 40)
            reminderFrame:SetPoint("CENTER", UIParent, "CENTER", PET_DEFAULT_ANCHOR_X, PET_DEFAULT_ANCHOR_Y)
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
                db.petPassiveReminderPos = { mode = "screenCenter", x = x * scale, y = y * scale }
            end

            local function RestorePosition()
                reminderFrame:ClearAllPoints()
                local pos = MattActionBarFontDB and MattActionBarFontDB.petPassiveReminderPos
                if type(pos) == "table" and pos.mode == "screenCenter" and tonumber(pos.x) and tonumber(pos.y) then
                    local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                    reminderFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / scale, pos.y / scale)
                else
                    reminderFrame:SetPoint("CENTER", UIParent, "CENTER", PET_DEFAULT_ANCHOR_X, PET_DEFAULT_ANCHOR_Y)
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

            local text = reminderFrame:CreateFontString(nil, "OVERLAY")
            text:SetPoint("CENTER", reminderFrame, "CENTER", 12, 0)
            text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 20, "OUTLINE")
            text:SetText(GetCurrentClassLabel() .. ": Pet is on Passive")
            local r, g, b = GetCurrentClassColor()
            text:SetTextColor(r, g, b, 1)
            reminderFrame.text = text

            local iconFrame = CreateFrame("Frame", nil, reminderFrame, "BackdropTemplate")
            iconFrame:SetSize(26, 26)
            iconFrame:SetPoint("RIGHT", text, "LEFT", -8, 0)
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
            icon:SetSize(24, 24)
            icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
            icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
            reminderFrame.icon = icon

            RestorePosition()
            reminderFrame:Hide()
            self._petPassiveReminderFrame = reminderFrame
        end

        self:ApplyPetReminderScale()

        if not self._petPassiveReminderEvents then
            self._petPassiveReminderEvents = CreateFrame("Frame")
        end
        local evf = self._petPassiveReminderEvents
        evf:UnregisterAllEvents()
        evf:SetScript("OnEvent", nil)
        evf:SetScript("OnUpdate", nil)

        local db = MattActionBarFontDB
        local enableSystem = db and (db.warnPetPassive or db.warnMissingPet) and IsTrackedPetClass()
        if not enableSystem then
            self:UpdatePetPassiveReminder()
            return
        end

        evf:RegisterEvent("PLAYER_ENTERING_WORLD")
        evf:RegisterEvent("PLAYER_REGEN_DISABLED")
        evf:RegisterEvent("PLAYER_REGEN_ENABLED")
        evf:RegisterEvent("PLAYER_UPDATE_RESTING")
        evf:RegisterEvent("PET_BAR_UPDATE")
        evf:RegisterEvent("PET_BAR_UPDATE_USABLE")
        evf:RegisterEvent("PET_UI_UPDATE")
        evf:RegisterEvent("PLAYER_CONTROL_LOST")
        evf:RegisterEvent("PLAYER_CONTROL_GAINED")
        evf:RegisterEvent("PLAYER_FARSIGHT_FOCUS_CHANGED")
        evf:RegisterEvent("PLAYER_TARGET_CHANGED")
        evf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        evf:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        evf:RegisterEvent("PLAYER_TALENT_UPDATE")
        evf:RegisterEvent("SPELLS_CHANGED")
        evf:RegisterEvent("UNIT_HEALTH")
        evf:RegisterEvent("UNIT_MAXHEALTH")
        evf:RegisterEvent("UNIT_FLAGS")
        evf:RegisterEvent("UNIT_PET")

        local elapsedSinceCheck = 0
        evf:SetScript("OnUpdate", function(_, elapsed)
            if not (IsPlayerInCombat() or IsInSupportedInstanceContent()) then
                return
            end
            elapsedSinceCheck = elapsedSinceCheck + (elapsed or 0)
            if elapsedSinceCheck < 0.2 then
                return
            end
            elapsedSinceCheck = 0
            SyncDungeonCombatStarted()
            if MABF and MABF.UpdatePetPassiveReminder then
                MABF:UpdatePetPassiveReminder()
            end
        end)

        evf:SetScript("OnEvent", function(_, event, unit)
            if unit then
                if event == "UNIT_PET" and unit ~= "player" then
                    return
                end
                if (event == "UNIT_HEALTH" or event == "UNIT_MAXHEALTH" or event == "UNIT_FLAGS") and unit ~= "pet" then
                    return
                end
            end
            if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
                SyncDungeonCombatStarted()
            elseif event == "PLAYER_REGEN_DISABLED" then
                if IsInSupportedInstanceContent() then
                    petDungeonCombatStarted = true
                end
            elseif event == "PLAYER_REGEN_ENABLED" and not IsInSupportedInstanceContent() then
                petDungeonCombatStarted = false
            end
            if MABF and MABF.UpdatePetPassiveReminder then
                MABF:UpdatePetPassiveReminder()
            end
        end)

        SyncDungeonCombatStarted()
        self:UpdatePetPassiveReminder()
    end

    function MABF:ApplyPetReminderScale()
        local frame = self._petPassiveReminderFrame
        if not frame then
            return
        end
        local db = MattActionBarFontDB
        local scale = ClampPetReminderScale(db and db.petReminderScale or 1.0)
        if db then
            db.petReminderScale = scale
        end
        frame:SetScale(scale)
    end

    function MABF:ResetPetPassiveReminderPosition()
        local db = MattActionBarFontDB
        if db then
            db.petPassiveReminderPos = nil
        end

        local reminderFrame = self._petPassiveReminderFrame
        if reminderFrame then
            reminderFrame:ClearAllPoints()
            reminderFrame:SetPoint("CENTER", UIParent, "CENTER", PET_DEFAULT_ANCHOR_X, PET_DEFAULT_ANCHOR_Y)
        end
    end
end
