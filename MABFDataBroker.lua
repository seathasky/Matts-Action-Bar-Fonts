-- MABFDataBroker.lua
local addonName, MABF = ...

local ldb = LibStub("LibDataBroker-1.1", true)
if ldb then
    local MABF_DataObject = ldb:NewDataObject("MABF", {
        type = "launcher",
        icon = "Interface\\AddOns\\MattActionBarFont\\Images\\mabficon.png",
        OnClick = function(self, button)
            SlashCmdList["MABF"]("")
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("Matt's Action Bar Fonts")
            tooltip:AddLine("Click to open options", 1, 1, 1)
        end,
    })
    local ldbIcon = LibStub("LibDBIcon-1.0", true)
    if ldbIcon then
        local db = {}
        ldbIcon:Register("MABF", MABF_DataObject, db)
    end
end
