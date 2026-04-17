-- Remove the confirmation dialog on repair all. Don't be poor!

local _, addon = ...

local function Initialize()
    MerchantRepairAllButton:HookScript('OnShow', function () RepairAllItems() end)
end

addon.RegisterModule({ Initialize = Initialize })
