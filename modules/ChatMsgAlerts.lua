local _, addon = ...

local function MonsterYell(_ownerID, msg, _name)
    if C_Map.GetBestMapForUnit('player') == 534 then -- Tanaan Jungle
        PlaySound(11466)
        addon.FlashScreen(10)
        msg = ORANGE_FONT_COLOR:WrapTextInColorCode(msg)
        UIErrorsFrame:AddMessage(msg, 0.1, 1.0, 0.1)
    end
end

local function MonsterEmote(_ownerID, msg, name)
    if C_Map.GetBestMapForUnit('player') == 1970 then -- Zereth Mortis
        msg = ORANGE_FONT_COLOR:WrapTextInColorCode(msg)
        UIErrorsFrame:AddMessage(string.format(msg, name))
    end
end

local function Loot(_ownerID, ...)
    if select(8, GetInstanceInfo()) == 2769 then
        local msg = ...
        if msg and msg:find('Prototype A.S.M.R.', nil, true) then
            PlaySound(11466)
            addon.FlashScreen(10)
            msg = ORANGE_FONT_COLOR:WrapTextInColorCode(msg)
            UIErrorsFrame:AddMessage(msg)
            addon.printf(msg)
        end
    end
end

EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_MONSTER_YELL", MonsterYell)
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_MONSTER_EMOTE", MonsterEmote)
EventRegistry:RegisterFrameEventAndCallback("CHAT_MSG_LOOT", Loot)
