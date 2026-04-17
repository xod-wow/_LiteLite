-- Take the confirmation off the "sell all junk" button

local _, addon = ...

local function Initialize()
    if MerchantSellAllJunkButton then
        MerchantSellAllJunkButton:SetScript('OnClick', MerchantFrame_OnSellAllJunkButtonConfirmed)
    end
end

addon.RegisterModule({ Initialize = Initialize })
