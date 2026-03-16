local addonName, MABF = ...

-- Builds the System > Quick Cmds options page UI.
function MABF:BuildQuickCommandsPage(opts)
    if type(opts) ~= "table" then return nil end

    local pageSystem = opts.pageSystem
    local CreatePageTitle = opts.CreatePageTitle
    local CreateBasicCheckbox = opts.CreateBasicCheckbox
    local checkSpacing = opts.checkSpacing

    if not pageSystem or not CreatePageTitle or not CreateBasicCheckbox then
        return nil
    end

    local qcTitle = CreatePageTitle(pageSystem, "Quick Commands")

    local quickBindCheck = CreateBasicCheckbox(
        pageSystem,
        "MABFQuickBindCheck",
        qcTitle,
        "TOPLEFT",
        0,
        -8,
        "Keybind Mode |cffffd100(/kb)|r",
        MattActionBarFontDB.enableQuickBind,
        function(self)
            MattActionBarFontDB.enableQuickBind = self:GetChecked()
            MABF:SetupSlashCommands()
        end
    )

    local reloadAliasCheck = CreateBasicCheckbox(
        pageSystem,
        "MABFReloadAliasCheck",
        quickBindCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Reload UI |cffffd100(/rl)|r",
        MattActionBarFontDB.enableReloadAlias,
        function(self)
            MattActionBarFontDB.enableReloadAlias = self:GetChecked()
            MABF:SetupSlashCommands()
        end
    )

    local editModeAliasCheck = CreateBasicCheckbox(
        pageSystem,
        "MABFEditModeAliasCheck",
        reloadAliasCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Edit Mode |cffffd100(/edit)|r",
        MattActionBarFontDB.enableEditModeAlias,
        function(self)
            MattActionBarFontDB.enableEditModeAlias = self:GetChecked()
            MABF:SetupSlashCommands()
        end
    )

    local pullAliasCheck = CreateBasicCheckbox(
        pageSystem,
        "MABFPullAliasCheck",
        editModeAliasCheck,
        "TOPLEFT",
        0,
        checkSpacing,
        "Pull Timer |cffffd100(/pull X)|r",
        MattActionBarFontDB.enablePullAlias,
        function(self)
            MattActionBarFontDB.enablePullAlias = self:GetChecked()
            MABF:SetupSlashCommands()
        end
    )

    return {
        page = pageSystem,
        quickBindCheck = quickBindCheck,
        reloadAliasCheck = reloadAliasCheck,
        editModeAliasCheck = editModeAliasCheck,
        pullAliasCheck = pullAliasCheck,
    }
end
