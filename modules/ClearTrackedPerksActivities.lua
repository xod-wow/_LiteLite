-- At the start of Midnight apparently these were all getting added to
-- quest tracking and causing frame rate issues. Probably no longer any
-- kind of problem but I'll leave the clear here for now.

local _, addon = ...

local function Initialize()
    if not C_PerksActivities then return end
    local ids = C_PerksActivities.GetTrackedPerksActivities().trackedIDs
    for _, id in ipairs(ids) do
       C_PerksActivities.RemoveTrackedPerksActivity(id)
    end
end

addon.RegisterModule({ Initialize = Initialize })
