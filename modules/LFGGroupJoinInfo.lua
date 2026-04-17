-- Print a message telling me what keystone I joined, because I can't remember
-- what I signed up for, and when the popup shows I instantly dismiss it without
-- even looking at it.
--
-- I should probably move this into LiteKeystone where it could pop up a button
-- to teleport there or something.

local _, addon = ...

local function LFG_LIST_JOINED_GROUP(_ownerID, resultID, kstringGroupName)
    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)

    local activityID = searchResultInfo.activityIDs[1]
    local isWarMode = searchResultInfo.isWarMode
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID, nil, isWarMode)

    if activityInfo.isMythicPlusActivity then
        local _, _, _, _, role = C_LFGList.GetApplicationInfo(resultID)
        local msg = format('Joined %s "%s" as %s', activityInfo.fullName, kstringGroupName, _G[role])
        local dashes = string.rep('-', msg:len())
        addon.printf(HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(dashes))
        addon.printf(HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(msg))
        addon.printf(HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(dashes))

--[[
        -- This used to print in party chat but wow did people get bigmad.
        -- kstring is gone before the GROUP_JOINED so can't use it
        local chatMsg = format('Joined %s as %s', activityInfo.fullName, _G[role])
        local function sendmsg()
            SendChatMessage(chatMsg, IsInRaid() and "RAID" or "PARTY")
        end
        if IsInGroup() then
            sendmsg()
        else
            EventUtil.RegisterOnceFrameEventAndCallback("GROUP_JOINED", sendmsg)
        end
]]
    end
end

EventRegistry:RegisterFrameEventAndCallback('LFG_LIST_JOINED_GROUP', LFG_LIST_JOINED_GROUP)
