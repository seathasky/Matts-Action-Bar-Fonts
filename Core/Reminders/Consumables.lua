local addonName, MABF = ...

local LCG = LibStub and LibStub("LibCustomGlow-1.0", true)

-----------------------------------------------------------
-- Reminders (Dungeon Consumables)
-----------------------------------------------------------
do
    local dungeonCombatStarted = false
    local CONSUMABLES_DEFAULT_ANCHOR_Y = -140

    local function ClampConsumableReminderScale(value)
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
            dungeonCombatStarted = false
            return
        end
        if IsPlayerInCombat() then
            dungeonCombatStarted = true
        end
    end

    local function AnyPlayerBuffMatches(predicate)
        if not predicate then
            return false
        end
        if C_UnitAuras and C_UnitAuras.GetBuffDataByIndex then
            local index = 1
            local auraData = C_UnitAuras.GetBuffDataByIndex("player", index)
            while auraData do
                if predicate(auraData) then
                    return true
                end
                index = index + 1
                auraData = C_UnitAuras.GetBuffDataByIndex("player", index)
            end
        end
        return false
    end

    local function PlayerHasFoodBuff()
        return AnyPlayerBuffMatches(function(auraData)
            local auraName = auraData and auraData.name
            local lowerName = type(auraName) == "string" and auraName:lower() or ""
            return lowerName:find("well fed", 1, true) ~= nil
        end)
    end

    local FOOD_ICON_FILE_ID = 136000
    local FLASK_ICON_FILE_ID = "Interface\\Icons\\UI_Profession_Alchemy"
    local OIL_ICON_FILE_ID = "Interface\\Icons\\INV_Potion_38"
    local HEALTHSTONE_ITEM_IDS = { 6262, 5512 }
    local HEALTHSTONE_ICON_FILE_ID = 538745
    local CONSUMABLE_GLOW_KEY = "mabf_consumable_missing"
    local CONSUMABLE_GLOW_COLOR = {1.0, 0.85, 0.2, 1.0}

    local function SetConsumableGlow(block, shouldGlow)
        if not block or not block.iconFrame or not LCG then
            return
        end
        if shouldGlow then
            if block._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Start(block.iconFrame, CONSUMABLE_GLOW_COLOR, 8, 0.25, 6, 2, 0, 0, false, CONSUMABLE_GLOW_KEY, block.iconFrame:GetFrameLevel() + 6)
            block._mabfGlowActive = true
        else
            if not block._mabfGlowActive then
                return
            end
            LCG.PixelGlow_Stop(block.iconFrame, CONSUMABLE_GLOW_KEY)
            block._mabfGlowActive = false
        end
    end

    local function PlayerHasFlaskBuff()
        return AnyPlayerBuffMatches(function(auraData)
            local auraName = auraData and auraData.name
            local lowerName = type(auraName) == "string" and auraName:lower() or ""
            return (lowerName:find("flask", 1, true) ~= nil) or (lowerName:find("phial", 1, true) ~= nil)
        end)
    end

    local function PlayerHasWeaponOil()
        if not GetWeaponEnchantInfo then
            return false
        end
        local hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
        return (hasMainHandEnchant and true) or (hasOffHandEnchant and true) or false
    end

    local function PlayerHasHealthstone()
        if not GetItemCount then
            return false
        end
        for _, itemID in ipairs(HEALTHSTONE_ITEM_IDS) do
            if (GetItemCount(itemID, false, false) or 0) > 0 then
                return true
            end
        end
        return false
    end

    local function GroupHasWarlock()
        if not IsInGroup or not IsInGroup() then
            return false
        end

        if IsInRaid and IsInRaid() then
            local numMembers = GetNumGroupMembers and GetNumGroupMembers() or 0
            for i = 1, numMembers do
                local unit = "raid" .. i
                if UnitExists and UnitExists(unit) then
                    local _, classTag = UnitClass(unit)
                    if classTag == "WARLOCK" then
                        return true
                    end
                end
            end
            return false
        end

        if UnitExists and UnitExists("player") then
            local _, classTag = UnitClass("player")
            if classTag == "WARLOCK" then
                return true
            end
        end

        local numMembers = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for i = 1, numMembers do
            local unit = "party" .. i
            if UnitExists and UnitExists(unit) then
                local _, classTag = UnitClass(unit)
                if classTag == "WARLOCK" then
                    return true
                end
            end
        end

        return false
    end

    local function ShouldEvaluateConsumablesReminder()
        local db = MattActionBarFontDB
        if not db or not db.trackConsumables then
            return false
        end
        if db.consumablesOnlyInInstance ~= false and not IsInSupportedInstanceContent() then
            return false
        end
        if db.consumablesSuppressInMPlus ~= false and IsKeystoneChallengeActive() then
            return false
        end
        if db.consumablesHideInRestArea ~= false and IsResting and IsResting() then
            return false
        end
        if db.consumablesSuppressAfterFirstPull and dungeonCombatStarted and IsInSupportedInstanceContent() then
            return false
        end
        if db.consumablesHideWhenLFGComplete ~= false and IsLFGComplete and IsLFGComplete() then
            return false
        end
        if IsPlayerInCombat() then
            return false
        end
        return true
    end

    function MABF:UpdateConsumableReminder()
        local reminderFrame = self._consumableReminderFrame
        if not reminderFrame or not reminderFrame.entries then
            return
        end

        if not ShouldEvaluateConsumablesReminder() then
            SetConsumableGlow(reminderFrame.entries.food, false)
            SetConsumableGlow(reminderFrame.entries.flask, false)
            SetConsumableGlow(reminderFrame.entries.oil, false)
            SetConsumableGlow(reminderFrame.entries.healthstone, false)
            reminderFrame:Hide()
            return
        end

        local hasFood = PlayerHasFoodBuff()
        local hasFlask = PlayerHasFlaskBuff()
        local hasOil = PlayerHasWeaponOil()
        local trackHealthstone = (MattActionBarFontDB and MattActionBarFontDB.warnConsumableHealthstone) and GroupHasWarlock() or false
        local hasHealthstone = PlayerHasHealthstone()

        reminderFrame.entries.food:SetShown(not hasFood)
        reminderFrame.entries.flask:SetShown(not hasFlask)
        reminderFrame.entries.oil:SetShown(not hasOil)
        reminderFrame.entries.healthstone:SetShown(trackHealthstone and (not hasHealthstone))
        SetConsumableGlow(reminderFrame.entries.food, reminderFrame.entries.food:IsShown())
        SetConsumableGlow(reminderFrame.entries.flask, reminderFrame.entries.flask:IsShown())
        SetConsumableGlow(reminderFrame.entries.oil, reminderFrame.entries.oil:IsShown())
        SetConsumableGlow(reminderFrame.entries.healthstone, reminderFrame.entries.healthstone:IsShown())

        local visibleEntries = reminderFrame._visibleEntries or {}
        wipe(visibleEntries)
        if reminderFrame.entries.food:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.food
        end
        if reminderFrame.entries.flask:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.flask
        end
        if reminderFrame.entries.oil:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.oil
        end
        if reminderFrame.entries.healthstone:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.healthstone
        end

        if #visibleEntries == 0 then
            SetConsumableGlow(reminderFrame.entries.food, false)
            SetConsumableGlow(reminderFrame.entries.flask, false)
            SetConsumableGlow(reminderFrame.entries.oil, false)
            SetConsumableGlow(reminderFrame.entries.healthstone, false)
            reminderFrame:Hide()
            return
        end

        local spacing = 14
        local blockWidth = 48
        local totalWidth = (#visibleEntries * blockWidth) + ((#visibleEntries - 1) * spacing)
        if totalWidth < blockWidth then
            totalWidth = blockWidth
        end
        reminderFrame:SetSize(totalWidth, 50)

        for i, block in ipairs(visibleEntries) do
            block:ClearAllPoints()
            if i == 1 then
                block:SetPoint("TOPLEFT", reminderFrame, "TOPLEFT", 0, 0)
            else
                block:SetPoint("TOPLEFT", visibleEntries[i - 1], "TOPRIGHT", spacing, 0)
            end
        end

        reminderFrame:Show()
    end

    function MABF:SetupConsumableReminder()
        if not self._consumableReminderFrame then
            local reminderFrame = CreateFrame("Frame", "MABFConsumableReminderFrame", UIParent)
            reminderFrame:SetSize(176, 50)
            reminderFrame:SetPoint("TOP", UIParent, "TOP", 0, CONSUMABLES_DEFAULT_ANCHOR_Y)
            reminderFrame:SetFrameStrata("HIGH")
            reminderFrame:SetClampedToScreen(true)
            reminderFrame:SetMovable(true)
            reminderFrame:EnableMouse(true)
            reminderFrame:RegisterForDrag("LeftButton")

            local function SavePosition()
                local db = MattActionBarFontDB
                if not db then return end
                local x, y = reminderFrame:GetCenter()
                if not x or not y then return end
                local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                db.consumableReminderPos = { mode = "screenCenter", x = x * scale, y = y * scale }
            end

            local function RestorePosition()
                reminderFrame:ClearAllPoints()
                local pos = MattActionBarFontDB and MattActionBarFontDB.consumableReminderPos
                if type(pos) == "table" and pos.mode == "screenCenter" and tonumber(pos.x) and tonumber(pos.y) then
                    local scale = (UIParent and UIParent.GetEffectiveScale and UIParent:GetEffectiveScale()) or 1
                    reminderFrame:SetPoint("CENTER", UIParent, "BOTTOMLEFT", pos.x / scale, pos.y / scale)
                else
                    reminderFrame:SetPoint("TOP", UIParent, "TOP", 0, CONSUMABLES_DEFAULT_ANCHOR_Y)
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

            local function CreateConsumableBlock(parent, iconFileID, label)
                local block = CreateFrame("Frame", nil, parent)
                block:SetSize(48, 50)

                local iconFrame = CreateFrame("Frame", nil, block, "BackdropTemplate")
                iconFrame:SetSize(32, 32)
                iconFrame:SetPoint("TOP", block, "TOP", 0, 0)
                iconFrame:SetBackdrop({
                    bgFile = "Interface\\Buttons\\WHITE8X8",
                    edgeFile = "Interface\\Buttons\\WHITE8X8",
                    edgeSize = 1,
                    insets = { left = 0, right = 0, top = 0, bottom = 0 },
                })
                iconFrame:SetBackdropColor(0, 0, 0, 0.15)
                iconFrame:SetBackdropBorderColor(0, 0, 0, 1)
                block.iconFrame = iconFrame

                local icon = block:CreateTexture(nil, "OVERLAY")
                icon:SetSize(30, 30)
                icon:SetPoint("CENTER", iconFrame, "CENTER", 0, 0)
                icon:SetTexture(iconFileID)
                icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
                block.icon = icon

                local text = block:CreateFontString(nil, "OVERLAY")
                text:SetPoint("TOP", iconFrame, "BOTTOM", 0, -2)
                text:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 8, "OUTLINE")
                text:SetTextColor(1, 1, 1, 1)
                text:SetText(label)
                block.text = text

                return block
            end

            reminderFrame.entries = {
                food = CreateConsumableBlock(reminderFrame, FOOD_ICON_FILE_ID, "Food"),
                flask = CreateConsumableBlock(reminderFrame, FLASK_ICON_FILE_ID, "Flask"),
                oil = CreateConsumableBlock(reminderFrame, OIL_ICON_FILE_ID, "Oil"),
                healthstone = CreateConsumableBlock(reminderFrame, HEALTHSTONE_ICON_FILE_ID, "Stone"),
            }
            reminderFrame._visibleEntries = {}
            reminderFrame.entries.food:SetPoint("TOPLEFT", reminderFrame, "TOPLEFT", 0, 0)
            reminderFrame.entries.flask:SetPoint("TOPLEFT", reminderFrame.entries.food, "TOPRIGHT", 14, 0)
            reminderFrame.entries.oil:SetPoint("TOPLEFT", reminderFrame.entries.flask, "TOPRIGHT", 14, 0)
            reminderFrame.entries.healthstone:SetPoint("TOPLEFT", reminderFrame.entries.oil, "TOPRIGHT", 14, 0)

            RestorePosition()
            reminderFrame:Hide()
            self._consumableReminderFrame = reminderFrame
        end

        self:ApplyConsumableReminderScale()

        if not self._consumableReminderEvents then
            self._consumableReminderEvents = CreateFrame("Frame")
        end
        local evf = self._consumableReminderEvents
        evf:UnregisterAllEvents()
        evf:SetScript("OnEvent", nil)
        evf:SetScript("OnUpdate", nil)

        local db = MattActionBarFontDB
        if not (db and db.trackConsumables) then
            self:UpdateConsumableReminder()
            return
        end

        evf:RegisterEvent("PLAYER_ENTERING_WORLD")
        evf:RegisterEvent("PLAYER_REGEN_DISABLED")
        evf:RegisterEvent("PLAYER_REGEN_ENABLED")
        evf:RegisterEvent("PLAYER_UPDATE_RESTING")
        evf:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        evf:RegisterEvent("UNIT_AURA")
        evf:RegisterEvent("UNIT_INVENTORY_CHANGED")
        evf:RegisterEvent("BAG_UPDATE_DELAYED")
        evf:RegisterEvent("PLAYER_EQUIPMENT_CHANGED")
        evf:RegisterEvent("GROUP_ROSTER_UPDATE")

        evf:SetScript("OnEvent", function(_, event, unit)
            if (event == "UNIT_AURA" or event == "UNIT_INVENTORY_CHANGED") and unit and unit ~= "player" then
                return
            end
            if event == "PLAYER_ENTERING_WORLD" or event == "ZONE_CHANGED_NEW_AREA" then
                SyncDungeonCombatStarted()
            elseif event == "PLAYER_REGEN_DISABLED" then
                if IsInSupportedInstanceContent() then
                    dungeonCombatStarted = true
                end
            elseif event == "PLAYER_REGEN_ENABLED" and not IsInSupportedInstanceContent() then
                dungeonCombatStarted = false
            end
            if MABF and MABF.UpdateConsumableReminder then
                MABF:UpdateConsumableReminder()
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
            if MABF and MABF.UpdateConsumableReminder then
                MABF:UpdateConsumableReminder()
            end
        end)

        SyncDungeonCombatStarted()
        self:UpdateConsumableReminder()
    end

    function MABF:ApplyConsumableReminderScale()
        local frame = self._consumableReminderFrame
        if not frame then
            return
        end
        local db = MattActionBarFontDB
        local scale = ClampConsumableReminderScale(db and db.consumableReminderScale or 1.0)
        if db then
            db.consumableReminderScale = scale
        end
        frame:SetScale(scale)
    end

    function MABF:ResetConsumableReminderPosition()
        local db = MattActionBarFontDB
        if db then
            db.consumableReminderPos = nil
        end

        local reminderFrame = self._consumableReminderFrame
        if reminderFrame then
            reminderFrame:ClearAllPoints()
            reminderFrame:SetPoint("TOP", UIParent, "TOP", 0, CONSUMABLES_DEFAULT_ANCHOR_Y)
        end
    end
end
