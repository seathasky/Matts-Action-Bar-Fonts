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
            tooltip:AddLine("Matt's Action Bar Fonts & UI QoL")
            tooltip:AddLine("Click to open options", 1, 1, 1)
        end,
    })
    local ldbIcon = LibStub("LibDBIcon-1.0", true)
    if ldbIcon then
        local function SetupMinimapDB()
            MattActionBarFontDB = MattActionBarFontDB or {}
            MattActionBarFontDB.minimap = MattActionBarFontDB.minimap or {}
            ldbIcon:Register("MABF", MABF_DataObject, MattActionBarFontDB.minimap)
            if MattActionBarFontDB.minimap.hide then
                ldbIcon:Hide("MABF")
            else
                ldbIcon:Show("MABF")
            end
        end

        -- If savedvars are already present, set up now, otherwise wait for ADDON_LOADED
        if MattActionBarFontDB then
            SetupMinimapDB()
        else
            local f = CreateFrame("Frame")
            f:RegisterEvent("ADDON_LOADED")
            f:SetScript("OnEvent", function(self, event, name)
                if name == addonName then
                    SetupMinimapDB()
                    self:UnregisterEvent("ADDON_LOADED")
                    self:SetScript("OnEvent", nil)
                end
            end)
        end
    end
end

-- AddOn Compartment callbacks (referenced by TOC metadata).
function MABF_AddonCompartment_Click(addonName, buttonName)
    if SlashCmdList and SlashCmdList["MABF"] then
        SlashCmdList["MABF"]("")
    end
end

function MABF_AddonCompartment_OnEnter(addonName, button)
    if not button then return end
    GameTooltip:SetOwner(button, "ANCHOR_LEFT")
    GameTooltip:SetText("Matt's Action Bar Fonts & UI QoL")
    GameTooltip:AddLine("Click to open options", 1, 1, 1)
    GameTooltip:Show()
end

function MABF_AddonCompartment_OnLeave(addonName, button)
    GameTooltip:Hide()
end
