local addonName, MABF = ...
local isWoWForever = select(4, GetBuildInfo()) == 16001

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
        -- Forever may expose the general aura reader without the buff helper.
        local getAura = C_UnitAuras and (C_UnitAuras.GetBuffDataByIndex or C_UnitAuras.GetAuraDataByIndex)
        if getAura then
            for index = 1, 255 do
                local isSecret = C_Secrets and C_Secrets.ShouldUnitAuraIndexBeSecret
                    and C_Secrets.ShouldUnitAuraIndexBeSecret("player", index, "HELPFUL")
                if not isSecret then
                    local auraData = getAura("player", index, "HELPFUL")
                    if not auraData then
                        break
                    end
                    local ok, matched = pcall(predicate, auraData)
                    if ok and matched then
                        return true
                    end
                end
            end
        end

        -- Classic clients may not expose the Retail C_UnitAuras iteration
        -- helpers. Keep the same predicate-based scan as a compatibility
        -- fallback without changing the Retail path above.
        if UnitBuff then
            for index = 1, 255 do
                local auraName, _, _, _, _, _, _, _, _, spellId = UnitBuff("player", index)
                if not auraName then
                    break
                end
                local auraData = { name = auraName, spellId = spellId }
                local ok, matched = pcall(predicate, auraData)
                if ok and matched then
                    return true
                end
            end
        end

        return false
    end

    -- Classic food effects can have generic names shared with non-food buffs.
    -- Match their IDs rather than accepting every regeneration/stat buff.
    local FOREVER_FOOD_BUFF_IDS = {
        [18125] = true, -- Blessed Sunfruit
        [18141] = true, -- Blessed Sunfruit Juice
        [18191] = true, -- Increased Stamina (Lobster Stew)
        [18192] = true, -- Increased Agility (Grilled Squid)
        [18193] = true, -- Increased Spirit (Hot Smoked Bass)
        [18194] = true, -- Mana Regeneration (Nightfin Soup)
        [18222] = true, -- Health Regeneration (Poached Sunscale Salmon)
        [19705] = true, -- Well Fed; also supplies the localized buff name
        [22730] = true, -- Increased Intellect (Runn Tum Tuber Surprise)
        [25661] = true, -- Increased Stamina (Dirge's Kickin' Chimaerok Chops)
    }

    local function PlayerHasFoodBuff()
        local wellFedName
        if isWoWForever then
            if C_Spell and C_Spell.GetSpellName then
                wellFedName = C_Spell.GetSpellName(19705)
            elseif GetSpellInfo then
                wellFedName = GetSpellInfo(19705)
            end
        end
        return AnyPlayerBuffMatches(function(auraData)
            if isWoWForever and auraData then
                local spellId = auraData.spellId
                if spellId and not (issecretvalue and issecretvalue(spellId)) and FOREVER_FOOD_BUFF_IDS[spellId] then
                    return true
                end
                -- Covers all Forever Well Fed ranks and new foods without
                -- maintaining a separate list of every dish or stat value.
                if wellFedName and auraData.name == wellFedName then
                    return true
                end
            end
            local auraName = auraData and auraData.name
            local ok, lowerName = pcall(function() return type(auraName) == "string" and auraName:lower() or "" end)
            if not ok then return false end
            return lowerName:find("well fed", 1, true) ~= nil
        end)
    end

    local FOOD_ICON_FILE_ID = 136000
    local FLASK_ICON_FILE_ID = "Interface\\Icons\\UI_Profession_Alchemy"
    local ELIXIR_ICON_FILE_ID = "Interface\\Icons\\INV_Potion_27"
    local OIL_ICON_FILE_ID = "Interface\\Icons\\INV_Potion_38"
    local CLASSIC_FLASK_BUFF_IDS = {
        [17626] = true, -- Flask of the Titans
        [17627] = true, -- Flask of Distilled Wisdom
        [17628] = true, -- Flask of Supreme Power
        [17629] = true, -- Flask of Chromatic Resistance
    }
    local FOREVER_ELIXIR_BUFF_IDS = {
        [673] = true, -- Minor Defense
        [2367] = true, -- Lion's Strength
        [2374] = true, -- Minor Agility
        [2378] = true, -- Minor Fortitude
        [3160] = true, -- Lesser Agility
        [3164] = true, -- Ogre's Strength
        [3166] = true, -- Wisdom
        [3219] = true, -- Minor Troll's Blood
        [3220] = true, -- Defense
        [3222] = true, -- Strong Troll's Blood
        [3223] = true, -- Mighty Troll's Blood
        [3593] = true, -- Fortitude
        [6512] = true, -- Detect Lesser Invisibility
        [7178] = true, -- Water Breathing
        [7844] = true, -- Firepower
        [8212] = true, -- Giant Growth
        [11319] = true, -- Water Walking
        [11328] = true, -- Agility
        [11334] = true, -- Greater Agility
        [11348] = true, -- Superior Defense
        [11349] = true, -- Greater Defense
        [11389] = true, -- Detect Undead
        [11390] = true, -- Arcane Elixir
        [11396] = true, -- Greater Intellect
        [11405] = true, -- Giants
        [11406] = true, -- Demonslaying
        [11407] = true, -- Detect Demon
        [11474] = true, -- Shadow Power
        [17535] = true, -- Sages
        [17537] = true, -- Brute Force
        [17538] = true, -- Mongoose
        [17539] = true, -- Greater Arcane Elixir
        [21920] = true, -- Frost Power
        [24361] = true, -- Major Troll's Blood
        [24363] = true, -- Mageblood Elixir
        [1245249] = true, -- Minor Force
        [1250920] = true, -- Phalanx
    }
    -- Aura IDs for the additional Forever flasks, not their Alchemy recipes.
    local FOREVER_FLASK_BUFF_IDS = {
        [1293740] = true, -- Flask of Natural Accuracy
        [1293741] = true, -- Flask of Natural Aggression
        [1293742] = true, -- Flask of Natural Precision
        [1293743] = true, -- Flask of Natural Swiftness
    }
    local AUGMENT_RUNE_SPELL_ID = 1264426
    local AUGMENT_RUNE_ICON_FILE_ID = 4549099
    local HEALTHSTONE_ITEM_IDS = isWoWForever and {
        5512, 19004, 19005, -- Minor, including Improved Healthstone variants
        5511, 19006, 19007, -- Lesser
        5509, 19008, 19009, -- Healthstone
        5510, 19010, 19011, -- Greater
        9421, 19012, 19013, -- Major
    } or { 6262, 5512, 224464 } -- Includes Retail Demonic Healthstone.
    local HEALTHSTONE_ICON_FILE_ID = 538745
    local CONSUMABLE_GLOW_KEY = "mabf_consumable_missing"
    local CONSUMABLE_GLOW_COLOR = {1.0, 0.85, 0.2, 1.0}
    local cachedGroupHasWarlock = nil

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
            local ok, spellId = pcall(function()
                return auraData and auraData.spellId
            end)
            if ok and spellId and not (issecretvalue and issecretvalue(spellId)) then
                if CLASSIC_FLASK_BUFF_IDS[spellId] or (isWoWForever and FOREVER_FLASK_BUFF_IDS[spellId]) then
                    return true
                end
            end
            local auraName = auraData and auraData.name
            local ok, lowerName = pcall(function() return type(auraName) == "string" and auraName:lower() or "" end)
            if not ok then return false end
            return (lowerName:find("flask", 1, true) ~= nil)
                or (not isWoWForever and ((lowerName:find("phial", 1, true) ~= nil)
                    or (lowerName:find("elixir", 1, true) ~= nil)))
        end)
    end

    local function PlayerHasElixirBuff()
        return AnyPlayerBuffMatches(function(auraData)
            if not auraData then return false end
            local spellId = auraData.spellId
            if spellId and not (issecretvalue and issecretvalue(spellId)) and FOREVER_ELIXIR_BUFF_IDS[spellId] then
                return true
            end
            local name = auraData.name
            return type(name) == "string" and name:lower():find("elixir", 1, true) ~= nil
        end)
    end

    local function PlayerHasWeaponOil()
        if not GetWeaponEnchantInfo then
            return false
        end
        local hasMainHandEnchant, _, _, hasOffHandEnchant = GetWeaponEnchantInfo()
        return (hasMainHandEnchant and true) or (hasOffHandEnchant and true) or false
    end

    local function PlayerHasAugmentRuneBuff()
        return AnyPlayerBuffMatches(function(auraData)
            if not auraData then
                return false
            end

            local ok, spellId = pcall(function()
                return auraData.spellId
            end)
            if not ok or spellId == nil then
                return false
            end
            if issecretvalue and issecretvalue(spellId) then
                return false
            end

            return spellId == AUGMENT_RUNE_SPELL_ID
        end)
    end

    local function PlayerHasHealthstone()
        local getItemCount = (C_Item and C_Item.GetItemCount) or GetItemCount
        if not getItemCount then
            return false
        end
        for _, itemID in ipairs(HEALTHSTONE_ITEM_IDS) do
            -- Count carried items, excluding bank contents and use charges.
            if (getItemCount(itemID, false, false) or 0) > 0 then
                return true
            end
        end
        return false
    end

    local function MarkGroupWarlockDirty()
        cachedGroupHasWarlock = nil
    end

    local function GroupHasWarlock()
        if cachedGroupHasWarlock ~= nil then
            return cachedGroupHasWarlock
        end
        if not IsInGroup or not IsInGroup() then
            cachedGroupHasWarlock = false
            return cachedGroupHasWarlock
        end

        if IsInRaid and IsInRaid() then
            local numMembers = GetNumGroupMembers and GetNumGroupMembers() or 0
            for i = 1, numMembers do
                local unit = "raid" .. i
                if UnitExists and UnitExists(unit) then
                    local _, classTag = UnitClass(unit)
                    if classTag == "WARLOCK" then
                        cachedGroupHasWarlock = true
                        return cachedGroupHasWarlock
                    end
                end
            end
            cachedGroupHasWarlock = false
            return cachedGroupHasWarlock
        end

        if UnitExists and UnitExists("player") then
            local _, classTag = UnitClass("player")
            if classTag == "WARLOCK" then
                cachedGroupHasWarlock = true
                return cachedGroupHasWarlock
            end
        end

        local numMembers = GetNumSubgroupMembers and GetNumSubgroupMembers() or 0
        for i = 1, numMembers do
            local unit = "party" .. i
            if UnitExists and UnitExists(unit) then
                local _, classTag = UnitClass(unit)
                if classTag == "WARLOCK" then
                    cachedGroupHasWarlock = true
                    return cachedGroupHasWarlock
                end
            end
        end

        cachedGroupHasWarlock = false
        return cachedGroupHasWarlock
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
        if db.consumablesHideWhileMounted and IsPlayerMounted() then
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
        -- Combat restrictions can outlive the combat-state event briefly in
        -- 12.1.  Wait until player auras are readable before scanning buffs.
        if C_Secrets and C_Secrets.ShouldAurasBeSecret and C_Secrets.ShouldAurasBeSecret() then
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
            SetConsumableGlow(reminderFrame.entries.elixir, false)
            SetConsumableGlow(reminderFrame.entries.oil, false)
            SetConsumableGlow(reminderFrame.entries.rune, false)
            SetConsumableGlow(reminderFrame.entries.healthstone, false)
            reminderFrame:Hide()
            return
        end

        local hasFood = PlayerHasFoodBuff()
        local hasFlask = PlayerHasFlaskBuff()
        local trackElixir = isWoWForever and MattActionBarFontDB.warnConsumableElixir
        local hasElixir = trackElixir and PlayerHasElixirBuff()
        -- Classic Forever does not use the Retail weapon-oil reminder. Keep
        -- the entry available in the shared frame, but never show/evaluate it.
        local hasOil = isWoWForever or PlayerHasWeaponOil()
        -- Augment Runes are a Retail-only consumable. Treat the Rune as
        -- present on Forever so an old Retail saved setting cannot show it.
        local hasRune = isWoWForever or PlayerHasAugmentRuneBuff()
        local trackHealthstone = (MattActionBarFontDB and MattActionBarFontDB.warnConsumableHealthstone) and GroupHasWarlock() or false
        local hasHealthstone = PlayerHasHealthstone()

        reminderFrame.entries.food:SetShown(MattActionBarFontDB.warnConsumableFood ~= false and (not hasFood))
        reminderFrame.entries.flask:SetShown(MattActionBarFontDB.warnConsumableFlask ~= false and (not hasFlask))
        reminderFrame.entries.elixir:SetShown(trackElixir and not hasElixir or false)
        reminderFrame.entries.oil:SetShown(not isWoWForever and MattActionBarFontDB.warnConsumableOil ~= false and (not hasOil))
        reminderFrame.entries.rune:SetShown(MattActionBarFontDB.warnConsumableAugmentRune ~= false and (not hasRune))
        reminderFrame.entries.healthstone:SetShown(trackHealthstone and (not hasHealthstone))
        SetConsumableGlow(reminderFrame.entries.food, reminderFrame.entries.food:IsShown())
        SetConsumableGlow(reminderFrame.entries.flask, reminderFrame.entries.flask:IsShown())
        SetConsumableGlow(reminderFrame.entries.elixir, reminderFrame.entries.elixir:IsShown())
        SetConsumableGlow(reminderFrame.entries.oil, reminderFrame.entries.oil:IsShown())
        SetConsumableGlow(reminderFrame.entries.rune, reminderFrame.entries.rune:IsShown())
        SetConsumableGlow(reminderFrame.entries.healthstone, reminderFrame.entries.healthstone:IsShown())

        local visibleEntries = reminderFrame._visibleEntries or {}
        wipe(visibleEntries)
        if reminderFrame.entries.food:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.food
        end
        if reminderFrame.entries.flask:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.flask
        end
        if reminderFrame.entries.elixir:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.elixir
        end
        if reminderFrame.entries.oil:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.oil
        end
        if reminderFrame.entries.rune:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.rune
        end
        if reminderFrame.entries.healthstone:IsShown() then
            visibleEntries[#visibleEntries + 1] = reminderFrame.entries.healthstone
        end

        if #visibleEntries == 0 then
            SetConsumableGlow(reminderFrame.entries.food, false)
            SetConsumableGlow(reminderFrame.entries.flask, false)
            SetConsumableGlow(reminderFrame.entries.elixir, false)
            SetConsumableGlow(reminderFrame.entries.oil, false)
            SetConsumableGlow(reminderFrame.entries.rune, false)
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
                elixir = CreateConsumableBlock(reminderFrame, ELIXIR_ICON_FILE_ID, "Elixir"),
                oil = CreateConsumableBlock(reminderFrame, OIL_ICON_FILE_ID, "Oil"),
                rune = CreateConsumableBlock(reminderFrame, AUGMENT_RUNE_ICON_FILE_ID, "Rune"),
                healthstone = CreateConsumableBlock(reminderFrame, HEALTHSTONE_ICON_FILE_ID, "Stone"),
            }
            reminderFrame._visibleEntries = {}
            reminderFrame.entries.food:SetPoint("TOPLEFT", reminderFrame, "TOPLEFT", 0, 0)
            reminderFrame.entries.flask:SetPoint("TOPLEFT", reminderFrame.entries.food, "TOPRIGHT", 14, 0)
            reminderFrame.entries.oil:SetPoint("TOPLEFT", reminderFrame.entries.flask, "TOPRIGHT", 14, 0)
            reminderFrame.entries.rune:SetPoint("TOPLEFT", reminderFrame.entries.oil, "TOPRIGHT", 14, 0)
            reminderFrame.entries.healthstone:SetPoint("TOPLEFT", reminderFrame.entries.rune, "TOPRIGHT", 14, 0)

            RestorePosition()
            reminderFrame:Hide()
            self._consumableReminderFrame = reminderFrame
        end

        self:ApplyConsumableReminderScale()
        if self.ApplyRemindersClickthroughLock then
            self:ApplyRemindersClickthroughLock()
        end

        if not self._consumableReminderEvents then
            self._consumableReminderEvents = CreateFrame("Frame")
        end
        local evf = self._consumableReminderEvents
        evf:UnregisterAllEvents()
        evf:SetScript("OnEvent", nil)
        evf:SetScript("OnUpdate", nil)
        if self._consumableReminderTicker and self._consumableReminderTicker.Cancel then
            self._consumableReminderTicker:Cancel()
            self._consumableReminderTicker = nil
        end

        local db = MattActionBarFontDB
        if not (db and db.trackConsumables) then
            self:UpdateConsumableReminder()
            return
        end

        evf:RegisterEvent("PLAYER_ENTERING_WORLD")
        evf:RegisterEvent("PLAYER_REGEN_DISABLED")
        evf:RegisterEvent("PLAYER_REGEN_ENABLED")
        evf:RegisterEvent("PLAYER_UPDATE_RESTING")
        evf:RegisterEvent("PLAYER_MOUNT_DISPLAY_CHANGED")
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
            if event == "GROUP_ROSTER_UPDATE" or event == "PLAYER_ENTERING_WORLD" then
                MarkGroupWarlockDirty()
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

        if C_Timer and C_Timer.NewTicker then
            self._consumableReminderTicker = C_Timer.NewTicker(1.0, function()
                SyncDungeonCombatStarted()
                if MABF and MABF.UpdateConsumableReminder then
                    MABF:UpdateConsumableReminder()
                end
            end)
        end

        MarkGroupWarlockDirty()
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
