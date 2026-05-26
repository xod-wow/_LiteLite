-- Print a message when you cast a specific spell

local function ShouldAnnounce()
    local ok, result = pcall(C_ChatInfo.InChatMessagingLockdown)
    if ok and result then
        return false
    end

    if UnitIsPVP('player') or IsActiveBattlefieldArena() then
        return false
    end

    local _, instanceType = IsInInstance()
    if instanceType == 'party' then
        return true
    elseif instanceType == 'raid' then
        return true
    end

    return false
end

local function SpellCastAnnounce(_ownerID, unit, _, spellID)
    if unit ~= 'player' or not ShouldAnnounce() then
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
