local _, addon = ...

local function checkboot(unit)
    if UnitExists(unit) and not UnitIsConnected(unit) then
        UninviteUnit(GetUnitName(unit, true))
    end
end

local function KickOfflineMembers()
    if not UnitIsGroupLeader('player') then
        return
    end

    if IsInRaid() then
        for i = 40, 1, -1 do
            checkboot('raid'..i)
        end
    elseif IsInGroup() then
        for i = 4, 1, -1 do
            checkboot('party'..i)
        end
    end
end

local addonInfo = {
    SlashCommands = {
        ['kick-offline'] = KickOfflineMembers,
        ['ko'] = KickOfflineMembers,
    }
}
addon.RegisterModule(addonInfo)
