-- Add the actions onto my dragonriding bar in the order I like them

local _, addon = ...

local DragonridingActions = {
    [121] = 372608,
    [122] = 372610,
    [123] = 361584,
    [124] = 403092,
    [125] = 425782,
    [126] = 0,
}

local function SetupDragonridingBar()
    for actionID, spellID in pairs(DragonridingActions) do
        if spellID == 0 then
            PickupAction(actionID)
            ClearCursor()
        else
            local aType, aID, aSubType = GetActionInfo(actionID)
            if aType ~= 'spell' or aID ~= spellID then
                C_Spell.PickupSpell(spellID)
                PlaceAction(actionID)
                ClearCursor()
            end
        end
    end
end

local moduleInfo = {
    HelpLines = {
        "dragon-riding-bar | drb"
    },
    SlashCommands = {
        ['dragon-riding-bar'] = SetupDragonridingBar,
        ['drb'] = SetupDragonridingBar,
    }
}
addon.RegisterModule(moduleInfo)
