-- Disable some of the crap in actionbar buttons I hate

local _, addon = ...

local function EnumerateActionButtons()
    local buttons = {}
    for _, actionBar in ipairs(ActionButtonUtil.ActionBarButtonNames) do
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local btn = _G[actionBar..i]
            table.insert(buttons, btn)
        end
    end

    local i = 0
    return function ()
        i = i + 1
        return buttons[i]
    end
end

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

    for b in EnumerateActionButtons() do
        -- ACTIONBAR_SLOT_CHANGED -> UpdateAction() is now calling
        -- self:UpdateCastingAnimation on indivdual buttons instead of it all
        -- being handled by the EventsFrame. This causes animations on some
        -- events, notably channeled spells like Arcane Missiles on Forever.
        -- This is quite heavy handed, but is probably enough to replace
        -- the EventFrame unregister if it doesn't taint the buttons.
        b.enableSpellFX = nil
    end

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
