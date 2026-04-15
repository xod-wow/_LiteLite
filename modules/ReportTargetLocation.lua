local _, addon = ...


local function ReportTargetLocation()
    local n = UnitName('target')
    if not n or UnitIsDead('target') then
        n = GameTooltip.TextLeft1:GetText()
    end
    local mapID = C_Map.GetBestMapForUnit('player')
    if not n or not mapID then return end
    local pos = C_Map.GetPlayerMapPosition(mapID,'player')
    local point = UiMapPoint.CreateFromCoordinates(mapID, pos.x, pos.y)
    C_Map.SetUserWaypoint(point)
    local link = C_Map.GetUserWaypointHyperlink()
    C_Map.ClearUserWaypoint()
    if link then
        SendChatMessage(n.." "..link, "CHANNEL", nil, 1)
    end
end

local moduleInfo = {
    SlashCommands = {
        ['announce-mob'] = ReportTargetLocation,
        ['am'] = ReportTargetLocation,
    }
}
addon.RegisterModule(moduleInfo)
