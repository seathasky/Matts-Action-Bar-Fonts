local addonName, MABF = ...

local function Copy(value)
    if type(value) ~= "table" then return value end
    local result = {}
    for key, child in pairs(value) do result[key] = Copy(child) end
    return result
end

local function ValidateName(name)
    if type(name) ~= "string" then return nil, "Enter a profile name." end
    name = name:match("^%s*(.-)%s*$")
    if name == "" then return nil, "Enter a profile name." end
    if #name > 80 or name:find("[%c|]") then
        return nil, "Choose a shorter, single-line name without |."
    end
    return name
end

function MABF:InitializeProfiles()
    if self.profileCharacterKey then return end
    local character = UnitName("player") .. " - " .. GetRealmName()
    if type(MABFProfilesDB) ~= "table" then
        MABFProfilesDB = { version = 1, profiles = {}, profileKeys = {} }
        if type(MattActionBarFontDB) == "table" and next(MattActionBarFontDB) then
            -- Keep the pre-profile setup for alts that have not logged in yet.
            -- Never replace it with changes made by the first migrated character.
            MABFProfilesDB.legacySettings = Copy(MattActionBarFontDB)
        end
    end
    local db = MABFProfilesDB
    db.profiles = type(db.profiles) == "table" and db.profiles or {}
    db.profileKeys = type(db.profileKeys) == "table" and db.profileKeys or {}
    if type(db.profiles.Default) ~= "table" then
        db.profiles.Default = Copy(self.defaults)
    end
    local name = db.profileKeys[character]
    if type(name) ~= "string" or type(db.profiles[name]) ~= "table" then
        -- Use a unique name so a user-created profile cannot replace an alt's setup.
        name = character
        local suffix = 2
        while db.profiles[name] ~= nil do
            name = character .. " (" .. suffix .. ")"
            suffix = suffix + 1
        end
        db.profiles[name] = Copy(db.legacySettings or self.defaults)
        db.profileKeys[character] = name
    end
    self.profileCharacterKey = character
    self.currentProfileName = name
    -- Existing modules keep using this settings table. Both saved variables are
    -- retained for migration compatibility; the profile store is authoritative.
    MattActionBarFontDB = db.profiles[name]
end

function MABF:GetCurrentProfile()
    return self.currentProfileName
end

function MABF:GetProfileDisplayName(name)
    -- Forever includes its region and realm number in the realm name. Keep the
    -- saved profile key intact, but show only the character and ruleset in UI.
    local character, ruleset = name:match("^(.-) %- CAMWOW%s+.-%s+Realm%s+%d+%s+(.+)$")
    if character then return character .. " - " .. ruleset end
    return name
end

function MABF:GetProfiles()
    local names = {}
    for name, settings in pairs(MABFProfilesDB.profiles) do
        if type(settings) == "table" then names[#names + 1] = name end
    end
    table.sort(names, function(a, b)
        if a == "Default" then return b ~= "Default" end
        if b == "Default" then return false end
        return a < b
    end)
    return names
end

function MABF:GetProfileUsage(name)
    local count = 0
    for _, selected in pairs(MABFProfilesDB.profileKeys) do
        if selected == name then count = count + 1 end
    end
    return count
end

local function CanChange()
    if InCombatLockdown() then return false, "Profiles cannot be changed during combat." end
    if MABF.profileReloadPending then return false, "Reload the UI to finish changing profiles." end
    return true
end

local function ReloadProfile()
    -- Keep the live table in place until reload: existing timers, UI controls and
    -- LibDBIcon still reference it. Only the next initialization binds the new one.
    MABF.profileReloadPending = true
    ReloadUI()
    return true
end

function MABF:SetProfile(name)
    local ok, err = CanChange()
    if not ok then return false, err end
    if type(MABFProfilesDB.profiles[name]) ~= "table" then return false, "Profile not found." end
    if name == self.currentProfileName then return true end
    MABFProfilesDB.profileKeys[self.profileCharacterKey] = name
    return ReloadProfile()
end

function MABF:CreateProfile(name)
    local ok, err = CanChange()
    if not ok then return false, err end
    name, err = ValidateName(name)
    if not name then return false, err end
    if MABFProfilesDB.profiles[name] ~= nil then return false, "A profile with that name already exists." end
    MABFProfilesDB.profiles[name] = Copy(self.defaults)
    return self:SetProfile(name)
end

function MABF:CopyProfile(name)
    local ok, err = CanChange()
    if not ok then return false, err end
    local source = MABFProfilesDB.profiles[name]
    if type(source) ~= "table" then return false, "Profile not found." end
    if name == self.currentProfileName then return false, "Choose a different profile to copy from." end
    MABFProfilesDB.profiles[self.currentProfileName] = Copy(source)
    return ReloadProfile()
end

function MABF:ResetProfile()
    local ok, err = CanChange()
    if not ok then return false, err end
    MABFProfilesDB.profiles[self.currentProfileName] = Copy(self.defaults)
    return ReloadProfile()
end

function MABF:RenameProfile(name)
    local ok, err = CanChange()
    if not ok then return false, err end
    if self.currentProfileName == "Default" then return false, "The Default profile cannot be renamed." end
    name, err = ValidateName(name)
    if not name then return false, err end
    if MABFProfilesDB.profiles[name] ~= nil then return false, "A profile with that name already exists." end
    local oldName = self.currentProfileName
    MABFProfilesDB.profiles[name] = MABFProfilesDB.profiles[oldName]
    MABFProfilesDB.profiles[oldName] = nil
    for character, selected in pairs(MABFProfilesDB.profileKeys) do
        if selected == oldName then MABFProfilesDB.profileKeys[character] = name end
    end
    self.currentProfileName = name
    return true
end

function MABF:DeleteProfile(name)
    local ok, err = CanChange()
    if not ok then return false, err end
    if name == "Default" or name == self.currentProfileName then
        return false, "The active profile and Default profile cannot be deleted."
    end
    if type(MABFProfilesDB.profiles[name]) ~= "table" then return false, "Profile not found." end
    MABFProfilesDB.profiles[name] = nil
    for character, selected in pairs(MABFProfilesDB.profileKeys) do
        if selected == name then MABFProfilesDB.profileKeys[character] = nil end
    end
    return true
end
