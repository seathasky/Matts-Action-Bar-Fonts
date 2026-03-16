local addonName, MABF = ...

-- Builds shared options-window helper context used by page builders.
function MABF:BuildOptionsContext(opts)
    if type(opts) ~= "table" then return nil end

    local hostFrame = opts.hostFrame
    local rightPanel = opts.rightPanel
    if not hostFrame or not rightPanel then
        return nil
    end

    local pages = {}

    local function CreatePageTitle(page, text)
        return MABF:CreatePageTitle(page, text)
    end

    local function CreateContentPage(index)
        local page = CreateFrame("Frame", nil, rightPanel, "BackdropTemplate")
        page:SetAllPoints(rightPanel)
        pages[index] = page
        return page
    end

    local function CreateBasicCheckbox(parent, name, anchorTo, anchorPoint, xOffset, yOffset, labelText, checkedValue, onClick)
        return MABF:CreateBasicCheckbox(parent, name, anchorTo, anchorPoint, xOffset, yOffset, labelText, checkedValue, onClick)
    end

    local function CreateMinimalDropdown(parent, width, visibleRows)
        return MABF:CreateMinimalDropdown(parent, width, visibleRows, hostFrame)
    end

    local function StyleSlider(slider)
        return MABF:StyleSlider(slider)
    end

    local function StyleMinimalCheckbox(checkButton)
        return MABF:StyleMinimalCheckbox(checkButton)
    end

    local function StyleMinimalRadio(radioButton, textLabel)
        return MABF:StyleMinimalRadio(radioButton, textLabel)
    end

    local function StyleMinimalButton(btn, isDanger)
        return MABF:StyleMinimalButton(btn, isDanger)
    end

    local function StyleMinimalDropdown(dropdown)
        return MABF:StyleMinimalDropdown(dropdown)
    end

    return {
        pages = pages,
        CreatePageTitle = CreatePageTitle,
        CreateContentPage = CreateContentPage,
        CreateBasicCheckbox = CreateBasicCheckbox,
        CreateMinimalDropdown = CreateMinimalDropdown,
        StyleSlider = StyleSlider,
        StyleMinimalCheckbox = StyleMinimalCheckbox,
        StyleMinimalRadio = StyleMinimalRadio,
        StyleMinimalButton = StyleMinimalButton,
        StyleMinimalDropdown = StyleMinimalDropdown,
    }
end
