-- This looks for fleeting potions in your bags and if you have the normal
-- version on your bars replaces them. And in reverse, looks for fleeting
-- potions on your bars, and if you don't have them but do have normal
-- versions, replace them.
-- 
-- In an ideal world I would adjust this to do Demonic Healthstone and
-- Healthstone too, but I am lazy.

local _, addon = ...

local function CheckAndSwapAction(actionID)
    local actionType, itemID = GetActionInfo(actionID)
    if actionType ~= 'item' then
        return
    end

    local name, _, _, _, _, itemType, itemSubType = C_Item.GetItemInfo(itemID)
    if not (name and itemType == 'Consumable' and itemSubType == 'Potions') then
        return
    end

    local normal = name:gsub("^Fleeting ", "")
    local normalCount = C_Item.GetItemCount(normal)
    local fleeting = "Fleeting " .. normal
    local fleetingCount = C_Item.GetItemCount(fleeting)
    if fleetingCount > 0 then
        if name ~= fleeting then
            addon.printf("Switching %d to %s", actionID, fleeting)
            C_Item.PickupItem(fleeting)
            C_ActionBar.PutActionInSlot(actionID)
            ClearCursor()
        end
    elseif normalCount > 0 then
        if name ~= normal then
            addon.printf("Switching %d to %s", actionID, normal)
            C_Item.PickupItem(normal)
            C_ActionBar.PutActionInSlot(actionID)
            ClearCursor()
        end
    end
end

local dirty = false

local function OnUpdate()
    if dirty then
        if not InCombatLockdown() then
            for actionID = 1, 180 do
                CheckAndSwapAction(actionID)
            end
        end
        dirty = false
    end
end

local function MarkDirty()
    dirty = true
end

local events = {
    "ACTIONBAR_SLOT_CHANGED",
    "ACTIVE_TALENT_GROUP_CHANGED",
    "BAG_UPDATE_DELAYED",
    "PLAYER_ENTERING_WORLD",
    "PLAYER_SPECIALIZATION_CHANGED",
}

local PotionScanner = CreateFrame("Frame")
FrameUtil.RegisterFrameForEvents(PotionScanner, events)

PotionScanner:SetScript('OnEvent', MarkDirty)
PotionScanner:SetScript('OnUpdate', OnUpdate)

local addonInfo = {
    SlashCommands = {
        ['fleeting-potions'] = MarkDirty,
        ['fp'] = MarkDirty,
    }
}
addon.RegisterModule(addonInfo)
