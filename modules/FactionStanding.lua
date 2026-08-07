-- Print some better info when you get reputation increase, showing your new
-- standing. Surprisingly annoying, there are now four different reputation
-- mechanisms.

local _, addon = ...

local function GetFactionNumbersByName(name)
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.factionID and data.name == name then
            local friendshipData = C_GossipInfo.GetFriendshipReputation(data.factionID)
            if friendshipData and friendshipData.friendshipFactionID > 0 then
                local rankData = C_GossipInfo.GetFriendshipReputationRanks(data.factionID)
                local rankText = string.format('%s %d/%d (%s)', FRIEND, rankData.currentLevel, rankData.maxLevel, friendshipData.reaction)
                if rankData.currentLevel == rankData.maxLevel then
                    return rankText, friendshipData.standing, friendshipData.reactionThreshold
                else
                    return rankText,
                        friendshipData.standing - friendshipData.reactionThreshold,
                        friendshipData.nextThreshold - friendshipData.reactionThreshold
                end
            end
            if C_Reputation.IsFactionParagonForCurrentPlayer(data.factionID) then
                local currentValue, threshold = C_Reputation.GetFactionParagonInfo(data.factionID)
                return 'P x' .. math.floor(currentValue / threshold),
                       currentValue % threshold,
                       threshold
            end
            local majorFactionData = C_MajorFactions.GetMajorFactionData(data.factionID)
            if majorFactionData then
                return string.format("Renown %d/%d", majorFactionData.renownLevel, majorFactionData.maxLevel),
                       majorFactionData.renownReputationEarned,
                       majorFactionData.renownLevelThreshold
            end
            return _G['FACTION_STANDING_LABEL'..data.reaction],
                   data.currentStanding - data.currentReactionThreshold,
                   data.nextReactionThreshold - data.currentReactionThreshold
        end
    end
    for _, factionID in ipairs(C_MajorFactions.GetMajorFactionIDs(LE_EXPANSION_LEVEL_CURRENT)) do
        if C_MajorFactions.ShouldDisplayMajorFactionAsJourney(factionID) then
            local data = C_MajorFactions.GetMajorFactionData(factionID)
            if data and data.name == name then
                return string.format("Journey %d/%d", data.renownLevel, data.maxLevel),
                       data.renownReputationEarned,
                       data.renownLevelThreshold
            end
        end
    end
end

local queue = {}
local ticker

local function PrintFactionIncrease(factionName, amount)
    local name, cur, max = GetFactionNumbersByName(factionName)
print(factionName, amount, name, cur, max)
    if name then
        local txt = string.format('%s +%d -> %s: %d/%d', factionName, amount, name, cur, max)
        addon.printf(BLUE_FONT_COLOR:WrapTextInColorCode(txt))
    end
end

local function OnTick()
    local keys = GetKeysArray(queue)
    table.sort(keys)
    for _, factionName in ipairs(keys) do
        local info = queue[factionName]
        local elapsed = GetTime() - info.time
        if (info.amount >= 500 and elapsed > 0.5) or elapsed > 5 then
            PrintFactionIncrease(factionName, info.amount)
            queue[factionName] = nil
        end
    end
    if next(queue) == nil then
        ticker:Cancel()
        ticker = nil
    end
end

local function AccumulateFactionIncrease(factionName, amount)
    if queue[factionName] then
        queue[factionName].amount = queue[factionName].amount + amount
        queue[factionName].time = GetTime()
    else
        queue[factionName] = { time=GetTime(), amount=amount }
    end
    if ticker == nil then
        ticker = C_Timer.NewTicker(0.1, OnTick)
    end
end

local function CHAT_MSG_COMBAT_FACTION_CHANGE(_ownerID, msg)
    if issecretvalue(msg) then
        return
    end
    -- _G.FACTION_STANDING_INCREASED:gsub('%%.', '(.-)')
    -- _G.FACTION_STANDING_INCREASED_ACCOUNT_WIDE:gsub('%%.', '(.-)')
    local factionName, amount = msg:match('with (.-) increased by (%d+)')
    amount = tonumber(amount)
    if factionName and amount then
        AccumulateFactionIncrease(factionName, amount)
    end
end

EventRegistry:RegisterFrameEventAndCallback('CHAT_MSG_COMBAT_FACTION_CHANGE', CHAT_MSG_COMBAT_FACTION_CHANGE)
