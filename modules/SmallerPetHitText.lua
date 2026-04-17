-- Make the pet "took damage" text much much smaller, as it is huge and hides
-- important things I need to see.

local _, addon = ...

local function Initialize()
    PetHitIndicator:SetScale(0.5)
end

addon.RegisterModule({ Initialize = Initialize })
