-- Nameplate settings, these need redoing for Midnight

local _, addon = ...

local function Setup()
    SetCVar('nameplateShowFriendlyNPCs', 1)
    SetCVar('nameplateShowFriends', 1)
    SetCVar('nameplateShowEnemies', 1)
    SetCVar('nameplateShowAll', 1)
    SetCVar('nameplateMaxDistance', 100)
end

local addonInfo = {
    SlashCommands= {
        ['nameplate-settings'] = Setup,
        ['ns'] = Setup,
    }
}

addon.RegisterModule(addonInfo)
