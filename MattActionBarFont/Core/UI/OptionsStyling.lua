local addonName, MABF = ...

function MABF:ApplyOptionsControlStyling(opts)
    if type(opts) ~= "table" then return end

    local StyleMinimalCheckbox = opts.StyleMinimalCheckbox
    local mouseoverBarChecks = opts.mouseoverBarChecks
    local remindersPages = opts.remindersPages

    if type(StyleMinimalCheckbox) ~= "function" then
        return
    end

    local optionChecks = opts.optionChecks or {}
    for _, cb in ipairs(mouseoverBarChecks or {}) do
        optionChecks[#optionChecks + 1] = cb
    end
    for _, cb in ipairs(optionChecks) do
        StyleMinimalCheckbox(cb)
    end

    local function StyleReminderCheckboxTree(frame)
        if not frame or not frame.GetChildren then return end
        local children = { frame:GetChildren() }
        for _, child in ipairs(children) do
            if child and child.GetObjectType and child:GetObjectType() == "CheckButton" then
                StyleMinimalCheckbox(child)
            end
            if child and child.GetChildren then
                StyleReminderCheckboxTree(child)
            end
        end
    end

    if remindersPages then
        StyleReminderCheckboxTree(remindersPages.consumables)
        StyleReminderCheckboxTree(remindersPages.pets)
        StyleReminderCheckboxTree(remindersPages.buffs)
        StyleReminderCheckboxTree(remindersPages.classstuff)
    end

    local function EmphasizeReminderPrimaryLabel(label)
        if not label then return end
        label:SetFont("Interface\\AddOns\\MattActionBarFont\\CustomFonts\\Naowh.ttf", 14, "OUTLINE")
        label:SetTextColor(1, 1, 1, 1)
    end

    EmphasizeReminderPrimaryLabel(opts.trackConsumablesText)
    EmphasizeReminderPrimaryLabel(opts.warnMissingPetText)
    EmphasizeReminderPrimaryLabel(opts.warnMissingClassBuffsText)
end
