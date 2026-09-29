local _, addon = ...

-- highest ilevel in each slot check

local irs = Enum.ItemRedundancySlot
local slotToName = tInvert(Enum.ItemRedundancySlot)

local function PrintSlotIlevels()
    local data = {}
    for i = 0, irs.Cloak do
        local highWaterMark = C_ItemUpgrade.GetHighWatermarkForSlot(i)
        table.insert(data, { slotToName[i], highWaterMark })
    end

    local w1 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.Twohand) or 0
    local w2 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.MainhandWeapon) or 0
    local w3 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.OnehandWeapon) or 0

    table.insert(data, { slotToName[irs.MainhandWeapon], math.max(w1, w2, w3) })

    local o1 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.OnehandWeaponSecond) or 0
    local o2 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.Offhand) or 0

    table.insert(data, { slotToName[irs.Offhand], math.max(w1, o1, o2) })

    _LiteLiteTable:Reset()
    _LiteLiteTable:SetAutoWidth(true)
    _LiteLiteTable:Setup("Slot High Water Marks", { "Slot", "iLvl" })
    _LiteLiteTable:SetRows(data)
    _LiteLiteTable:SetEnableSort(false)
    _LiteLiteTable:Show()

end

local addonInfo = {
     SlashCommands = {
          ['slot-ilevels'] = PrintSlotIlevels,
          ['si'] = PrintSlotIlevels,
     }
}

addon.RegisterModule(addonInfo)
