-- Slash command to show the Great Value without having to fiddle with the map

local _, addon = ...

local function ShowGreatVault()
    WeeklyRewards_ShowUI()
    WeeklyRewardsFrame:SetUpConditionalActivities()
    WeeklyRewardsFrame:Refresh()
end

local function NotifyGreatVault()
    if C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards() then
        addon.printf("Check your vault!")
    end
end

local moduleInfo = {
    Initialize = NotifyGreatVault,
    SlashCommands = {
        ['great-vault'] = ShowGreatVault,
        ['gv'] = ShowGreatVault,
    }
}
addon.RegisterModule(moduleInfo)
