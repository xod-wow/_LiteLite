local _, addon = ...

local function Initialize()
    MerchantRepairAllButton:HookScript('OnShow', function () RepairAllItems() end)
end

addon.RegisterModule({ Initialize = Initialize })
