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
    reverseBarGrowth  = false,    -- Normal bar 1 growth direction
    scaleObjectiveTracker = false, -- Don't scale objective tracker
    scaleStatusBar    = false,    -- Scale status/exp bar to 0.7
    hideMicroMenu     = false,    -- Hide micro menu buttons
    hideBagBar        = false,    -- Hide bag bar buttons
    petBarMouseoverFade = false,  -- Mouseover fade on pet action bar
    scaleTalkingHead  = false,    -- Scale talking head frame to 0.7

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
end
