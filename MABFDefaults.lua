local addonName, MABF = ...

-----------------------------------------------------------
-- Default values for MattActionBarFontDB
-----------------------------------------------------------
MABF.defaults = {
    -- Font sizes
    fontSize          = 12,       -- Main action bar font size
    countFontSize     = 14,       -- Stack count font size
    macroTextSize     = 12,       -- Macro name text size
    petBarFontSize    = 12,       -- Pet bar font size

    -- Font family
    fontFamily        = "Naowh",    -- Default font
    fontFamilyPath    = nil,        -- Cached resolved path for selected font
    fontFamilyPathName = nil,       -- Name associated with cached font path
    enableCustomFontSection = true, -- Enable custom font family selection section
    optionsFramePos   = nil,        -- Saved options window position

    -- Offsets
    xOffset           = 0,        -- Count text X offset
    yOffset           = 0,        -- Count text Y offset
    abXOffset         = 0,        -- Action bar font X offset
    abYOffset         = 0,        -- Action bar font Y offset
    extraXOffset      = 0,        -- Extra action ability font X offset
    extraYOffset      = 0,        -- Extra action ability font Y offset

    -- Theme
    minimalTheme      = "blizzard", -- "blizzard", "minimalBlack", "minimalTranslucent", "minimalObsidianRed", "minimalFrostMage", "minimalArcane", "minimalFelGreen", "minimalHolyGold", "minimalBloodDK", "minimalStormSteel", "minimalEmerald", "minimalVoid", "minimalMonoLight"
    minimalThemeBgOpacity = 0.35, -- Background opacity for minimal theme (0-1)
    minimalThemeBorderSize = 1, -- Border thickness in theme pixels (1-4)
    guiScale          = 1.0,      -- Options window scale (0.5-1.5)

    -- Toggles
    hideMacroText     = false,    -- Show macro text by default
    mouseoverFade     = false,    -- Keep bars 4/5 always visible
    mouseoverFadeBars = {         -- Bars managed by action bar mouseover fade
        bar1 = false,
        bar2 = false,
        bar3 = false,
        bar4 = false,
        bar5 = false,
        bar6 = false,
    },
    actionBarFadeDuration = 0.15, -- Fade duration in seconds (0-1)
    reverseBarGrowth  = false,    -- Normal bar 1 growth direction
    scaleObjectiveTracker = false, -- Don't scale objective tracker
    scaleStatusBar    = false,    -- Scale status/exp bar to 0.7
    hideMicroMenu     = false,    -- Hide micro menu buttons
    hideBagBar        = false,    -- Hide bag bar buttons
    petBarMouseoverFade = false,  -- Mouseover fade on pet action bar
    scaleTalkingHead  = false,    -- Scale talking head frame to 0.7
    enableCursorCircle = false,   -- Show colored cursor circle
    cursorCircleColor = "lightBlue", -- Cursor circle color preset
    cursorCircleScale = 1.0,      -- Cursor circle scale (0.5-2.0)
    cursorCircleOpacity = 1.0,    -- Cursor circle opacity (0-1)

    -- Slash commands
    enableQuickBind   = true,    -- /kb keybind mode
    enableReloadAlias = true,    -- /rl reload command
    enableEditModeAlias = true,  -- /edit edit mode command
    enablePullAlias   = true,    -- /pull X countdown timer

    -- Performance
    enablePerformanceMonitor = false, -- Show FPS & MS display
    perfMonitorBgOpacity = 0.5,       -- Background opacity (0-1)
    perfMonitorColor  = "green",      -- Text color: white, red, green, yellow, blue
    perfMonitorVertical = false,      -- Vertical layout (FPS above MS)
    perfMonitorHideMS  = false,       -- Hide MS text
    perfMonitorPos    = nil,          -- Saved position for perf monitor

    -- Quest tweaks
    autoAcceptQuests  = false,  -- Auto accept quests (hold Shift to skip)
    autoTurnInQuests  = false,  -- Auto turn in quests (skips reward choices)
    warnMissingPet    = false,  -- Warn in combat when tracked-class pet is missing
    petMissingOnlyInInstance = true, -- Show missing-pet reminder only in instance content
    petMissingHideInRestArea = true, -- Hide missing-pet reminder while resting
    petMissingSuppressInMPlus = true, -- Hide missing-pet reminder during active keystones
    petMissingSuppressAfterFirstPull = false, -- Hide missing-pet reminder after first pull starts
    petMissingHideWhenLFGComplete = true, -- Hide missing-pet reminder when LFG run is completed
    warnPetPassive    = false,  -- Warn in combat when tracked-class pet is on Passive
    trackConsumables  = false,  -- Track missing food/flask/oil reminders
    consumablesOnlyInInstance = true, -- Show consumables reminder only in instance content
    consumablesHideInRestArea = true, -- Hide consumables reminder while resting
    consumablesSuppressInMPlus = true, -- Hide consumables reminder during active keystones
    consumablesSuppressAfterFirstPull = false, -- Hide after first pull starts in-instance
    consumablesHideWhenLFGComplete = true, -- Hide when LFG dungeon run is completed
    warnConsumableHealthstone = false, -- Track missing Healthstone when a warlock is in group
    consumableReminderPos = nil, -- Saved screen-center position for consumables reminder
    petPassiveReminderPos = nil, -- Saved screen-center position for pet passive reminder
    petReminderScale = 1.0, -- Scale for pet reminder frame (0.5-2.0)
    consumableReminderScale = 1.0, -- Scale for consumables reminder frame (0.5-2.0)
    warnMissingClassBuffs = false, -- Warn when tracked class buff is missing
    warnClassSoulstone = false, -- Warlock-only: remind to cast Soulstone on someone
    warnClassShamanShields = false, -- Shaman-only: remind when no self shield is active
    warnClassPaladinBeacons = false, -- Paladin-only: remind when beacons are missing
    classOnlyInInstance = true, -- Class reminders only in instance content
    classHideInRestArea = true, -- Hide class reminders while resting
    classSuppressInMPlus = true, -- Hide class reminders during active keystone runs
    classSuppressAfterFirstPull = false, -- Hide class reminders after first pull starts
    classHideWhenLFGComplete = true, -- Hide class reminders when LFG run is complete
    classStuffReminderPos = nil, -- Saved screen-center position for class-stuff reminder
    classStuffReminderScale = 1.0, -- Scale for class-stuff reminder frame (0.5-2.0)
    missingBuffReminderPos = nil, -- Saved screen-center position for missing buff reminder
    missingBuffReminderScale = 1.0, -- Scale for missing buff reminder frame (0.5-2.0)
    buffsOnlyInInstance = true, -- Buff reminder only in instance content
    buffsHideInRestArea = true, -- Hide buff reminder while resting
    buffsSuppressInMPlus = true, -- Hide buff reminder during active keystone runs
    buffsSuppressAfterFirstPull = false, -- Hide buff reminder after first pull starts
    buffsHideWhenLFGComplete = true, -- Hide buff reminder when LFG run is complete

    -- Merchant tweaks
    enableAutoRepair   = false,    -- Auto-repair gear at merchants
    enableAutoSellJunk = false,    -- Auto-sell junk at merchants
    autoRepairFundingSource = "GUILD", -- "GUILD" or "PLAYER"

    -- Bag tweaks
    enableBagItemLevels = false, -- Show item levels in bags & bank

    -- Minimap button
    minimap           = { hide = false },

    -- Edit Mode Device Manager
    editMode          = {
        enabled = false,
        presetIndexOnLogin = 1,
    },
}

function MABF:ApplyDefaults()
    if not MattActionBarFontDB then

        MattActionBarFontDB = {}
    end

    for key, defaultValue in pairs(self.defaults) do
        if MattActionBarFontDB[key] == nil then
            if type(defaultValue) == "table" then

                MattActionBarFontDB[key] = {}
                for k, v in pairs(defaultValue) do
                    MattActionBarFontDB[key][k] = v
                end
            else
                MattActionBarFontDB[key] = defaultValue
            end
        end
    end

    if type(MattActionBarFontDB.minimalTheme) == "boolean" then
        if MattActionBarFontDB.minimalTheme then
            MattActionBarFontDB.minimalTheme = "minimalBlack"
        else
            MattActionBarFontDB.minimalTheme = "blizzard"
        end
    end

    local borderSize = tonumber(MattActionBarFontDB.minimalThemeBorderSize or 1) or 1
    borderSize = math.floor(borderSize + 0.5)
    if borderSize < 1 then
        borderSize = 1
    elseif borderSize > 4 then
        borderSize = 4
    end
    MattActionBarFontDB.minimalThemeBorderSize = borderSize

    if type(MattActionBarFontDB.mouseoverFadeBars) ~= "table" then
        MattActionBarFontDB.mouseoverFadeBars = {}
    end
    for key, defaultValue in pairs(self.defaults.mouseoverFadeBars) do
        if MattActionBarFontDB.mouseoverFadeBars[key] == nil then
            MattActionBarFontDB.mouseoverFadeBars[key] = defaultValue
        end
    end

    local fadeDuration = tonumber(MattActionBarFontDB.actionBarFadeDuration or 0.15) or 0.15
    if fadeDuration < 0 then
        fadeDuration = 0
    elseif fadeDuration > 1 then
        fadeDuration = 1
    end
    MattActionBarFontDB.actionBarFadeDuration = fadeDuration
end
