local _, addon = ...

local CompletedMap = {
    [true] = GREEN_FONT_COLOR:WrapTextInColorCode(COMPLETE),
    [false] = RED_FONT_COLOR:WrapTextInColorCode(INCOMPLETE:upper()),
}

local data = {
    { mapID = 2395, questID = 88545, x = 41.95, y = 80.05, text = "Gloomclaw" },
    { mapID = 2437, questID = 88526, x = 47.69, y = 53.25, text = "Silverscale" },
    { mapID = 2413, questID = 88531, x = 66.28, y = 47.91, text = "Lumenfin" },
    { mapID = 2405, questID = 88532, x = 54.60, y = 65.80, text = "Umbrafan" },
    { mapID = 2405, questID = 88524, x = 43.25, y = 82.75, text = "Netherscythe" },
}

local function OnMapForWaypoint(mapInfo, waypointMapID)
    return mapInfo.mapID == waypointMapID or mapInfo.parentMapID == waypointMapID
end

local function AddWaypoint(info)
    if TomTom then
        TomTom:AddWaypoint(
            info.mapID,
            info.x / 100,
            info.y / 100,
            { title = info.text, minimap = true, world = true }
        )
    end
end

local function MidnightSkinningLure()
    local currentMapID = C_Map.GetBestMapForUnit('player')
    local currentMapInfo = C_Map.GetMapInfo(currentMapID)
    for _, info in ipairs(data) do
        local completed = C_QuestLog.IsQuestFlaggedCompleted(info.questID)
        local mapInfo = C_Map.GetMapInfo(info.mapID)
        addon.printf("%s (%s): %s", info.text, mapInfo.name, CompletedMap[completed])
        if not completed and OnMapForWaypoint(currentMapInfo, info.mapID) then
            AddWaypoint(info)
        end
    end
end

local addonInfo = {
    SlashCommands = {
        ['lure'] = MidnightSkinningLure
    }
}
addon.RegisterModule(addonInfo)
