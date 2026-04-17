-- Show a table of delves, including zone, current story and bountiful state
-- Requires _LiteTable library. Could be modified to have its own _LiteTable
-- but for now shares the global _LiteLite one.

local _, addon = ...

-- {
--  atlasName="delves-regular",
--  description="Delve",
--  isAlwaysOnFlightmap=false,
--  isPrimaryMapForPOI=true,
--  highlightVignettesOnHover=false,
--  linkedUiMapID=2269,
--  areaPoiID=7863,
--  name="Earthcrawl Mines",
--  position={
--    RotateDirection=<function>,
--    GetLength=<function>,
--    Normalize=<function>,
--    Dot=<function>,
--    GetLengthSquared=<function>,
--    GetXY=<function>,
--    OnLoad=<function>,
--    IsZero=<function>,
--    DivideBy=<function>,
--    x=0.38592737913132,
--    y=0.73871922492981,
--    Subtract=<function>,
--    Clone=<function>,
--    Cross=<function>,
--    ScaleBy=<function>,
--    SetXY=<function>,
--    IsEqualTo=<function>,
--    Add=<function>
--  },
--  shouldGlow=false,
--  isCurrentEvent=false,
--  highlightWorldQuestsOnHover=false
-- }

local function GetDelveStory(poiInfo)
    if poiInfo.tooltipWidgetSet then
        local widgets = C_UIWidgetManager.GetAllWidgetsBySetID(poiInfo.tooltipWidgetSet)
        for _, w in ipairs(widgets) do
            local info = C_UIWidgetManager.GetTextWithStateWidgetVisualizationInfo(w.widgetID)
            if info.orderIndex == 0 then
                local text = string.match(info.text, ': (.*)$'):gsub('|cn.-:', '')
                return text
            end
        end
    end
end

local function ListDelves()
    local delveDataByName = {}
    for _, mapID in ipairs(addon.FindChildZoneMaps('midnight')) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        local delveList = C_AreaPoiInfo.GetDelvesForMap(mapID)
        for _, poiID in ipairs(delveList) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
            local isBountiful = ( poiInfo.atlasName == 'delves-bountiful' )
            local data = {
                mapInfo.name,
                poiInfo.name,
                GetDelveStory(poiInfo),
                isBountiful,
                isPrimary = poiInfo.isPrimaryMapForPOI,
                color = isBountiful and ORANGE_FONT_COLOR or nil,
            }
            -- isPrimaryMapForPOI is only true when there are at least two
            if not delveDataByName[poiInfo.name] or poiInfo.isPrimaryMapForPOI then
                delveDataByName[poiInfo.name] = data
            end
        end
    end

    local delveData = GetValuesArray(delveDataByName)

    table.sort(delveData,
        function (a, b)
            if a[1] ~= b[1] then
                return a[1] < b[1]
            else
                return a[2] < b[2]
            end
        end)

    _LiteLiteTable:Reset()
    _LiteLiteTable:Setup(DELVES_LABEL, { "Map", "Delve", "Story", "Bountiful?" })

    -- Seems to be no way to get a list of delve runs the way you can with M+
    -- Figure out what the highest ilevel reward is and see how many we've done
    -- that would give that reward. Relies on the a vault slot showing more than
    -- the threshold until you complete the next one.

    local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World)
    local maxItemLevel
    local progress = 0
    if next(activities) then
        local activityTierID = activities[1].activityTierID
        for i = 1, 32 do
            local _, _, _, itemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(activityTierID, i)
            maxItemLevel = itemLevel or maxItemLevel
        end

        for _, info in ipairs(activities) do
            local itemLink = C_WeeklyRewards.GetExampleRewardItemHyperlinks(info.id)
            local itemLevel = itemLink and C_Item.GetDetailedItemLevelInfo(itemLink)
            if itemLevel == maxItemLevel then progress = info.progress end
        end

        local completedJourney = C_QuestLog.IsQuestFlaggedCompleted(86371)
        local progText = WHITE_FONT_COLOR:WrapTextInColorCode(string.format("%d/%d", progress, activities[3].threshold))
        local journeyColor = completedJourney and GREEN_FONT_COLOR or RED_FONT_COLOR
        local journeyText = journeyColor:WrapTextInColorCode(tostring(completedJourney))
        local footer = string.format("Max level delves: %s. Journey: %s", progText, journeyText)
        _LiteLiteTable:SetFooter(footer)
    end

    _LiteLiteTable:SetEnableSort(true)
    _LiteLiteTable:SetRows(delveData)
    _LiteLiteTable:Show()
end

local moduleInfo = {
    HelpLines = {
        "delves",
    },
    SlashCommands = {
        ['delves'] = ListDelves
    }
}
addon.RegisterModule(moduleInfo)
