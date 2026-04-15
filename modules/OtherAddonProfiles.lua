local _, addon = ...

local function SetAceProfile(svName, profileName)
    if not svName or not _G[svName] then return end

    local acedb = LibStub('AceDB-3.0', true)
    if not acedb then return end

    local PlayerProfileName = string.format('%s - %s', UnitFullName('player'))
    local _, ClassProfileName = UnitClass('player')
    local RealmProfileName = GetRealmName()

    for db in pairs(acedb.db_registry) do
        if db.sv == _G[svName] then
            if db:GetCurrentProfile() ~= profileName then
                addon.printf('Set %s profile %s', svName, profileName)
                db:SetProfile(profileName)
            end
            if db.profiles[PlayerProfileName] then
                addon.printf('Delete %s profile %s', svName, PlayerProfileName)
                db:DeleteProfile(PlayerProfileName)
            end
            if db.profiles[ClassProfileName] then
                addon.printf('Delete %s profile %s', svName, ClassProfileName)
                db:DeleteProfile(ClassProfileName)
            end
            if db.profiles[RealmProfileName] then
                addon.printf('Delete %s profile %s', svName, RealmProfileName)
                db:DeleteProfile(RealmProfileName)
            end
        end
    end
end

local function Initialize()
    SetAceProfile('HandyNotesDB', 'Default')
    SetAceProfile('EnhancedRaidFramesDB', 'Default')
    SetAceProfile('SimulationCraftDB', 'Default')
end

addon.RegisterModule({ Initialize = Initialize })
