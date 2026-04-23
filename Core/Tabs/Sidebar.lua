local addonName, MABF = ...

-- Builds the left sidebar tab/header structure to mirror the options GUI.
function MABF:BuildOptionsSidebarTabs(opts)
    if type(opts) ~= "table" then return nil end

    local leftPanel = opts.leftPanel
    local sectionGap = opts.sectionGap
    local CreateSectionHeader = opts.CreateSectionHeader
    local CreateTabButton = opts.CreateTabButton
    local tabButtons = opts.tabButtons

    if not leftPanel or not sectionGap or not CreateSectionHeader or not CreateTabButton or type(tabButtons) ~= "table" then
        return nil
    end

    -- Action Bars section.
    CreateSectionHeader(leftPanel, "ACTION BARS", nil, nil, -4)
    local btnTextSizes = CreateTabButton(leftPanel, "Text", 1, leftPanel, "TOP", -14)
    tabButtons[1] = btnTextSizes
    local btnOffsets = CreateTabButton(leftPanel, "Offsets", 2, btnTextSizes)
    tabButtons[2] = btnOffsets
    local btnThemes = CreateTabButton(leftPanel, "Themes", 3, btnOffsets)
    tabButtons[3] = btnThemes
    local btnABFading = CreateTabButton(leftPanel, "Fading", 4, btnThemes)
    tabButtons[4] = btnABFading
    local btnABFeatures = CreateTabButton(leftPanel, "Features", 11, btnABFading)
    tabButtons[11] = btnABFeatures

    -- UI / QoL section.
    CreateSectionHeader(leftPanel, "UI / QoL", btnABFeatures, "BOTTOMLEFT", -sectionGap)
    local btnUIFeatures = CreateTabButton(leftPanel, "UI Features", 5, btnABFeatures, "BOTTOM", -(sectionGap + 12))
    tabButtons[5] = btnUIFeatures
    local btnQuests = CreateTabButton(leftPanel, "Quests", 8, btnUIFeatures)
    tabButtons[8] = btnQuests
    local btnReminders = CreateTabButton(leftPanel, "Reminders", 12, btnQuests)
    tabButtons[12] = btnReminders
    local btnBags = CreateTabButton(leftPanel, "Bags", 9, btnReminders)
    tabButtons[9] = btnBags
    local btnMerchant = CreateTabButton(leftPanel, "Merchant", 10, btnBags)
    tabButtons[10] = btnMerchant

    -- Shortcuts section.
    CreateSectionHeader(leftPanel, "SHORTCUTS", btnMerchant, "BOTTOMLEFT", -sectionGap)
    local keybindBtn = CreateTabButton(leftPanel, "Keybind", nil, btnMerchant, "BOTTOM", -(sectionGap + 12))
    local editModeBtn = CreateTabButton(leftPanel, "Edit Mode", nil, keybindBtn)

    -- System section.
    CreateSectionHeader(leftPanel, "SYSTEM", editModeBtn, "BOTTOMLEFT", -sectionGap)
    local qcTabBtn = CreateTabButton(leftPanel, "Quick Cmds", 6, editModeBtn, "BOTTOM", -(sectionGap + 12))
    tabButtons[6] = qcTabBtn
    local systemTabBtn = CreateTabButton(leftPanel, "System", 7, qcTabBtn)
    tabButtons[7] = systemTabBtn

    return {
        keybindBtn = keybindBtn,
        editModeBtn = editModeBtn,
    }
end
