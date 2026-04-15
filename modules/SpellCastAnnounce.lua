local function SpellCastAnnounce(_ownerID, unit, _, spellID)
    if unit ~= 'player' then
        return
    end

    if not IsInInstance() or UnitIsPVP('player') or IsActiveBattlefieldArena() then
        return
    end

    if spellID == 1231411 then  -- Recuperate
        C_ChatInfo.SendChatMessage('Re-cu-per-ate.', 'SAY')
    end
--[[
    if spellID == 115310 then
        -- Revival (Mistweaver Monk)
        msg = format('%s cast - %s', GetSpellLink(spellName), self.playerName)
        SendChatMessage(msg, 'SAY')
    end
]]
end

EventRegistry:RegisterFrameEventAndCallback('UNIT_SPELLCAST_SUCCEEDED', SpellCastAnnounce)
