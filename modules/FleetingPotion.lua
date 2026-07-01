-- This looks for fleeting potions in your bags and if you have the normal
-- version on your bars replaces them. And in reverse, looks for fleeting
-- potions on your bars, and if you don't have them but do have normal
-- versions, replace them.
--
-- In an ideal world I would adjust this to do Demonic Healthstone and
-- Healthstone too, but I am lazy.

local _, addon = ...

local function FindReplacements()
    local replacements = {}
    ItemUtil.IteratePlayerInventory(
        function (itemLocation)
            local itemLink = C_Item.GetItemLink(itemLocation)
            local name, _, _, _, _, itemType, itemSubType = C_Item.GetItemInfo(itemLink)
            if not (name and itemType == 'Consumable' and itemSubType == 'Potions') then
                return
            end
            local normal = name:gsub("^Fleeting ", "")
            local normalCount = C_Item.GetItemCount(normal)
            local fleeting = "Fleeting " .. normal
            local fleetingCount = C_Item.GetItemCount(fleeting)
            if replacements[normal] then
                return
            elseif fleetingCount > 0 then
                replacements[normal] = fleeting
                replacements[fleeting] = nil
            elseif normalCount > 0 then
                replacements[fleeting] = normal
            end
    end)
    return replacements
end

local function CheckAndSwapAction(actionID, replacements)
    local actionType, itemID = GetActionInfo(actionID)
    if actionType == 'item' then
        local name = C_Item.GetItemInfo(itemID)
        if replacements[name] then
            addon.printf("Switching %d to %s", actionID, replacements[name])
            C_Item.PickupItem(replacements[name])
            C_ActionBar.PutActionInSlot(actionID)
            ClearCursor()
        end
    elseif actionType == 'macro' then
        local macroName = GetActionText(actionID)
        local _, _, body = GetMacroInfo(macroName)
        if body then
            local newBody = body
            for from, to in pairs(replacements) do
                newBody = newBody:gsub("(/use%s+)"..from, "%1"..to)
                newBody = newBody:gsub("(/use%s+%[.+%]%s+)"..from, "%1"..to)
            end
            if newBody ~= body then
                addon.printf("Switching macro %s", macroName)
                EditMacro(macroName, nil, nil, newBody)
            end
        end
    end
end

local dirty = false

local function CanUpdateNow()
    if InCombatLockdown() then
        return false
    elseif C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.ChallengeMode) then
        return false
    else
        return true
    end
end


local function OnUpdate(self)
    if dirty then
        if CanUpdateNow() then
            local replacements = FindReplacements()
            for actionID = 1, 180 do
                CheckAndSwapAction(actionID, replacements)
            end
        end
        dirty = false
        self:SetScript('OnUpdate', nil)
    end
end

local function MarkDirty(self)
    dirty = true
    self:SetScript('OnUpdate', OnUpdate)
end

local events = {
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "BAG_UPDATE_DELAYED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_REGEN_ENABLED",
    "PLAYER_SPECIALIZATION_CHANGED",
}

local PotionScanner = CreateFrame("Frame")
FrameUtil.RegisterFrameForEvents(PotionScanner, events)

PotionScanner:SetScript('OnEvent', MarkDirty)

local addonInfo = {
    SlashCommands = {
        ['fleeting-potions'] = MarkDirty,
        ['fp'] = MarkDirty,
    }
}
addon.RegisterModule(addonInfo)
