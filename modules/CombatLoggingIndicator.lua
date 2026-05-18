local _, addon = ...

local icon = Minimap:CreateTexture()
icon:SetSize(16, 16)
icon:SetTexture(7467223)
icon:SetPoint("BOTTOMRIGHT", Minimap, "BOTTOMRIGHT", -1, 1)

EventRegistry:RegisterFrameEventAndCallback('CHAT_LOGGING_CHANGED',
    function (_, whichLog, isEnabled)
        -- print('CHAT_LOGGING_CHANGED', whichLog, isEnabled)
        if whichLog == 1 then
            icon:SetShown(isEnabled)
        end
    end)

EventRegistry:RegisterFrameEventAndCallback('PLAYER_ENTERING_WORLD',
    function ()
        local isEnabled = LoggingCombat()
        -- print('PLAYER_ENTERING_WORLD', isEnabled)
        icon:SetShown(isEnabled)
    end)
