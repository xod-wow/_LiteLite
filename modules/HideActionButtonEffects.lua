local _, addon = ...

local function Initialize()
    -- Stop the castbar inside the actionbuttons
    local events = {
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_RETICLE_TARGET",
        "UNIT_SPELLCAST_RETICLE_CLEAR",
        "UNIT_SPELLCAST_EMPOWER_START",
        "UNIT_SPELLCAST_EMPOWER_STOP",
    }

    FrameUtil.UnregisterFrameForEvents(ActionBarActionEventsFrame, events)

    -- Stop the SpellActivationAlert start animation
    hooksecurefunc(ActionButtonSpellAlertManager, 'ShowAlert',
        function (_, b)
            -- Bad attempt to restrict to ActionBarActionButtonMixin
            if b.HasAction and b.SpellActivationAlert then
                b.SpellActivationAlert.ProcStartAnim:Stop()
                b.SpellActivationAlert.ProcStartFlipbook:SetAlpha(0)
                b.SpellActivationAlert.ProcLoop:Play()
            end
        end)
end

addon.RegisterModule({ Initialize = Initialize })
