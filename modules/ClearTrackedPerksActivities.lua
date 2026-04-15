local _, addon = ...

local function Initialize()
    if not C_PerksActivities then return end
    local ids = C_PerksActivities.GetTrackedPerksActivities().trackedIDs
    for _, id in ipairs(ids) do
       C_PerksActivities.RemoveTrackedPerksActivity(id)
    end
end

addon.RegisterModule({ Initialize = Initialize })
