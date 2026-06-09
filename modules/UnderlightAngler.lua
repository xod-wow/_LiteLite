local _, addon = ...

-- Automatically handle equip swap Underlight Angler

local UnderlightAnglerItemID = 133755

local function KnowsFishing()
    local _, _, _, fishing = GetProfessions()
    return fishing ~= nil
end

local function HasUnderlightAngler()
    local n = C_Item.GetItemCount(UnderlightAnglerItemID)
    return n > 0
end

local function IsUnderlightAnglerEquipped()
    return GetInventoryItemID("player", 28) == 133755
end

local frame = CreateFrame('Frame')

local UpdateEvents = {
    "MOUNT_JOURNAL_USABILITY_CHANGED",
    "MIRROR_TIMER_START",
    "PLAYER_REGEN_DISABLED",
    "PLAYER_REGEN_ENABLED",
}

function frame:ProcessPending()
    if InCombatLockdown() then
        return
    end

    local currentEquippedItemID = GetInventoryItemID("player", 28)

    if self.pendingItemID == currentEquippedItemID then
        self.pendingItemID = nil
        return
    end

    self.previousItemID = currentEquippedItemID

    local name = C_Item.GetItemInfo(self.pendingItemID)
    if name then
        C_Item.EquipItemByName(name)
    end
end

function frame:QueueSwapIfNeeded()
end

function frame:EnableDisable()
    if KnowsFishing() and HasUnderlightAngler() then
        FrameUtil.RegisterFrameForEvents(self, UpdateEvents)
    else
        FrameUtil.UnregisterFrameForEvents(self, UpdateEvents)
    end
end

function frame:OnEvent(event)
    if event == 'SKILL_LINES_CHANGED' then
        self:CheckEnableDisable()
    end
end

function frame:Initialize()
    self:SetScript('OnEvent', self.OnEvent)
    self:RegisterEvent('SKILL_LINES_CHANGED')
    self:EnableDisable()
end

local function Initialize()
    frame:Initialize()
end

addon.RegisterModule({ Initialize=Initialize })
