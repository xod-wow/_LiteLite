local _, addon = ...

local playerName, playerGUID

local invited = { }

-- All of the ticker weirdness with the auto-inviting is because (a) battle.net
-- does not always answer, and takes a while to answer after login and (b) as
-- far as I can tell there is no way to tell the difference between "can't look
-- this GUID up right now" and "can never look this GUID up because it is not
-- part of our battle.net friends".

local function OnBattleNetInfoAvailable(guid, func)
    local attempts = 0

    local function TickerFunc(ticker)
        attempts = attempts + 1
        if attempts > 50 then
            print('Ticker timed out after 50 attempts')
            ticker:Cancel()
            func(nil)   -- Call with nil info if attempts expired
            return
        end
        local info = C_BattleNet.GetAccountInfoByGUID(guid)
        if info then
            print(string.format('Ticker succeeded after %d attempts', attempts))
            ticker:Cancel()
            func(info)
        end
    end

    C_Timer.NewTicker(0.2, TickerFunc)
end

local function AutoInvite(name, battleTag)
    if battleTag == addon.db.battleTag then
        addon.printf("   - One of my toons, inviting %s", name)
        C_Timer.After(1, function () C_PartyInfo.InviteUnit(name) end)
        return true
    else
        return false
    end
end

local function GUILD_ROSTER_UPDATE()
    -- addon.printf("AutoInviteMyself check due to GUILD_ROSTER_UPDATE")

    local _, n = GetNumGuildMembers()
    for i = 1, n do
        local name = GetGuildRosterInfo(i)
        if name and name ~= playerName and invited[name] == nil then
            addon.printf(" - Checking %d. %s", i, name)
            if addon.db.battleTagCache[name] then
                invited[name] = AutoInvite(name, addon.db.battleTagCache[name])
            else
                invited[name] = 'pending'
                local guid = select(17, GetGuildRosterInfo(i))
                OnBattleNetInfoAvailable(guid,
                    function (info)
                        if info then
                            addon.db.battleTagCache[name] = info.battleTag
                            invited[name] = AutoInvite(name, info.battleTag)
                        end
                    end)
            end
        end
    end
end

local function AutoAcceptInvite(name, inviterInfo)
    if inviterInfo then
        if inviterInfo.battleTag == addon.db.battleTag then
            print('AutoInvite OK', name, inviterInfo.battleTag, addon.db.battleTag)
            AcceptGroup()
            StaticPopup_Hide("PARTY_INVITE")
        end
    end
end

local function PARTY_INVITE_REQUEST(_ownerID, ...)
    local inviterName, _, _, _, _, _, inviterGUID = ...

    if inviterName and inviterGUID then
        OnBattleNetInfoAvailable(inviterGUID,
            function (inviterInfo)
                AutoAcceptInvite(inviterName, inviterInfo)
            end)
    end
end

local function Initialize()
    playerName = format("%s-%s", UnitFullName('player'))
    playerGUID = UnitGUID('player')

    addon.db.battleTagCache = addon.db.battleTagCache or {}

    if addon.db.battleTag == nil then
        OnBattleNetInfoAvailable(playerGUID,
            function (info)
                addon.db.battleTag = info and info.battleTag
            end)
    end

    EventRegistry:RegisterFrameEventAndCallback('PARTY_INVITE_REQUEST', PARTY_INVITE_REQUEST)
end

local function SlashCommand()
    EventRegistry:RegisterFrameEventAndCallback('GUILD_ROSTER_UPDATE', GUILD_ROSTER_UPDATE)
    C_GuildInfo.GuildRoster()
end

local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ['auto-invite-myself'] = SlashCommand,
        ['aim'] = SlashCommand,
    },
}
addon.RegisterModule(moduleInfo)
