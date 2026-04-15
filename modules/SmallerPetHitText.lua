local _, addon = ...

local function Initialize()
    PetHitIndicator:SetScale(0.5)
end

addon.RegisterModule({ Initialize = Initialize })
