local _, addon = ...

local function Initialize()
    local x, y = RaidInfoFrame:GetSize()
    RaidInfoFrame:SetSize(x, y + 150)
    x, y = RaidInfoFrame.ScrollBox:GetSize()
    RaidInfoFrame.ScrollBox:SetSize(x, y + 150)
end

addon.RegisterModule({ Initialize = Initialize })
