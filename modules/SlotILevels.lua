local _, addon = ...

-- highest ilevel in each slot check

local slotToName = tInvert(Enum.ItemRedundancySlot)
local irs = Enum.ItemRedundancySlot

local function PrintSlotIlevels()
    for i = 0, Enum.ItemRedundancySlot.Cloak do
        local highWaterMark = C_ItemUpgrade.GetHighWatermarkForSlot(i)
        print(slotToName[i], highWaterMark)
    end
    
    local w1 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.Twohand)
    local w2 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.MainhandWeapon)
    local w3 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.OnehandWeapon)
    
    print(slotToName[irs.MainhandWeapon], math.max(w1, w2, w3))
    
    local o1 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.OnehandWeaponSecond)
    local o2 = C_ItemUpgrade.GetHighWatermarkForSlot(irs.Offhand)
    
    print(slotToName[irs.Offhand], math.max(o1, o2))
end

PrintSlotIlevels()
local addonInfo = {
     SlashCommands = {
          ['slot-ilevels'] = PrintSlotIlevels,
          ['si'] = PrintSlotIlevels,
     }
}

addon.RegisterModule(addonInfo)
