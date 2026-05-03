-- Scan POI for things, alert sounds

local _, addon = ...

local Scanner = CreateFrame('Frame')
Scanner:SetScript('OnEvent', function (self, ...) self:OnEvent(...) end)

function Scanner:OnEvent(event)
    self:ScanAllPOI()
end

function Scanner:POIList()
    addon.printf("Scan for POI:")
    if next(addon.db.scanPOI or {}) then
        local names = GetKeysArray(addon.db.scanPOI)
        table.sort(names)
        for i, name in ipairs(names) do
            addon.printf("%d. %s", i, name)
        end
    else
        addon.printf("   None.")
    end
end

function Scanner:POIWipe()
    addon.db.scanPOI = table.wipe(addon.db.scanPOI or {})
    self:UpdateScanning()
end

function Scanner:POIAdd(name)
    addon.db.scanPOI = addon.db.scanPOI or {}
    addon.db.scanPOI[name:lower()] = {}
    self:UpdateScanning()
end

function Scanner:POIDel(name)
    if addon.db.scanPOI then
        local n = tonumber(name)
        if n then
            local names = GetKeysArray(addon.db.scanPOI)
            name = names[n]
        end
        addon.db.scanPOI[name] = nil
        self:UpdateScanning()
    end
end

function Scanner:UpdateScanning()
    if next(addon.db.scanPOI or {}) then
        self.seenPOI = self.seenPOI or {}
        self:RegisterEvent("AREA_POIS_UPDATED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        self:ScanAllPOI()
    else
        self:UnregisterAllEvents()
        self.seenPOI = table.wipe(self.seenPOI or {})
    end
end

function Scanner:POIMatches(text, info)
    text = text:lower()
    if text:sub(1,1) == '^' then
        if info.name:lower():find(text) then
            return true
        elseif info.atlasName:lower():find(text) then
            return true
        end
    else
        if info.name:lower():find(text, nil, true) then
            return true
        elseif info.atlasName:lower():find(text, nil, true) then
            return true
        end
    end
    return false
end

function Scanner:ScanPOI(map, id)
    if self.seenPOI[id] then
        return
    end

    local info = C_AreaPoiInfo.GetAreaPOIInfo(map, id)
    if not info then
        return
    end

    for n in pairs(addon.db.scanPOI) do
        if self:POIMatches(n, info) then
            addon.printf("POI found: %s", info.name)
            addon.printf("  atlas %s", info.atlasName)
            PlaySound(11466)
            self.seenPOI[id] = true
        end
    end
end

function Scanner:CleanPOI(map)
    local idList = C_AreaPoiInfo.GetEventsForMap(map)
    for id in pairs(self.seenPOI) do
        if not tContains(idList, id) then
            self.seenPOI[id] = nil
        end
    end
end

function Scanner:ScanAllPOI()
    local map = C_Map.GetBestMapForUnit('player')
    if map then
        self:CleanPOI(map)
        for _, id in ipairs(C_AreaPoiInfo.GetEventsForMap(map)) do
            self:ScanPOI(map, id)
        end
    end
end

local function SlashCommand(arg)
    local arg1, arg2 = string.split(' ', arg or '', 2)
    if arg1 == 'add' then
        Scanner:POIAdd(arg2)
    elseif arg1 == 'del' then
        Scanner:POIDel(arg2)
    elseif arg1 == 'wipe' then
        Scanner:POIWipe()
    end
    Scanner:POIList()
end

local moduleInfo = {
    Initialize = function () Scanner:UpdateScanning() end,
    SlashCommands = {
        ['poi-scan'] = SlashCommand,
        ['ps'] = SlashCommand,
    }
}
addon.RegisterModule(moduleInfo)
