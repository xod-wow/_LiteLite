local _, addon = ...

local function CHAT_MSG_COMBAT_XP_GAIN()
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

EventRegistry:RegisterFrameEventAndCallback('CHAT_MSG_COMBAT_XP_GAIN', CHAT_MSG_COMBAT_XP_GAIN)

local moduleInfo = {
    Initialize = CHAT_MSG_COMBAT_XP_GAIN,
    SlashCommands = {
        ['xp'] = CHAT_MSG_COMBAT_XP_GAIN,
    }
}
addon.RegisterModule(moduleInfo)
