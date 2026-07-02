-- Show how much rest remains numerically

local _, addon = ...

-- GetMessageTypeColor doesn't work on init, even after PLAYER_LOGIN

local function DisplayRest()
    local rest = GetXPExhaustion()
    if not rest or rest == 0 then return end
    local r, g, b = GetMessageTypeColor('COMBAT_XP_GAIN')
    local pct = 100 * rest / UnitXPMax('player')
    local msg = string.format('Rest remaining: %s (%0.1f%%)', AbbreviateNumbers(rest), pct)
    for i = 1, NUM_CHAT_WINDOWS do
        local f = Chat_GetChatFrame(i)
        if tContains(f.messageTypeList, 'COMBAT_XP_GAIN') then
            f:AddMessage(addon.format("%s", msg), r, g, b)
        end
    end
end

local function Initialize()
    EventRegistry:RegisterFrameEventAndCallback('CHAT_MSG_COMBAT_XP_GAIN', DisplayRest)
end


local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ['xp'] = DisplayRest,
    }
}

addon.RegisterModule(moduleInfo)
