--[[------------------------------------------------------------------------]]--

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
