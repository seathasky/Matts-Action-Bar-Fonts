local addonName, MABF = ...

--------------------------------------------------------------------------------
-- Edit Mode Device Manager
--------------------------------------------------------------------------------

function MABF:SetupEditModeDeviceManager()
    local db = MattActionBarFontDB
    if not db.editMode or not db.editMode.enabled then return end

    if not C_AddOns.IsAddOnLoaded("Blizzard_EditMode") then
        C_AddOns.LoadAddOn("Blizzard_EditMode")
    end

    local function ApplyEDMLayout()
        if not EditModeManagerFrame or not EditModeManagerFrame.GetLayouts then
            C_Timer.After(0.5, ApplyEDMLayout)
            return
        end
        local layouts = EditModeManagerFrame:GetLayouts()
        if not layouts then
            C_Timer.After(0.5, ApplyEDMLayout)
            return
        end
        local desired = db.editMode.presetIndexOnLogin
        if desired and desired > 0 and desired <= #layouts then
            EditModeManagerFrame:SelectLayout(desired, true)
            if MABFEDMStatusText then
                MABFEDMStatusText:SetText("Selected: |cff90E4C1" .. layouts[desired].layoutName .. "|r")
            end
            if MABFEDMLayoutDropdown then
                UIDropDownMenu_SetSelectedValue(MABFEDMLayoutDropdown, desired)
                UIDropDownMenu_SetText(MABFEDMLayoutDropdown, layouts[desired].layoutName)
            end
        end
    end

    C_Timer.After(1, ApplyEDMLayout)

    if not self._edmEventsRegistered then
        local edmEvents = CreateFrame("Frame")
        edmEvents:RegisterEvent("EDIT_MODE_LAYOUTS_UPDATED")
        edmEvents:RegisterEvent("PLAYER_SPECIALIZATION_CHANGED")
        edmEvents:SetScript("OnEvent", function(_, event)
            if db.editMode and db.editMode.enabled then
                C_Timer.After(0.5, ApplyEDMLayout)
            end
        end)
        self._edmEventsRegistered = true
    end
end
