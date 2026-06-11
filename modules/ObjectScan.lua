-- Scan vignettes for things, alert sounds + tomtom
-- lately I've been using
--      ^vignetteloot$      treasures
--      ^vignettekill$      rares (but not the always up ones)

local _, addon = ...

local Scanner = CreateFrame('Frame')
Scanner:SetScript('OnEvent', function (self, ...) self:OnEvent(...) end)

function Scanner:OnEvent(event, ...)
    if event == "NAME_PLATE_UNIT_ADDED" then
        local unit = ...
        self:ScanUnitNameplate(unit)
    elseif event == "VIGNETTE_MINIMAP_UPDATED" then
        local id = ...
        self:ScanVignetteByID(id)
    elseif event == "PLAYER_LOGOUT" then
        self:RemoveAllWaypoints()
    else
        self:ScanAllVignettes()
    end
end

function Scanner:ObjectList()
    addon.printf("Scan for mobs:")
    if next(addon.db.objectScan or {}) then
        for i, scan in ipairs(addon.db.objectScan) do
            if scan.map then
                addon.printf("%d. %s [%d]", i, scan.name, scan.map)
            else
                addon.printf("%d. %s", i, scan.name)
            end
        end
    else
        addon.printf("   None.")
    end
end

function Scanner:ObjectWipe()
    addon.db.objectScan = table.wipe(addon.db.objectScan or {})
    self:UpdateScanning()
end

function Scanner:ObjectAdd(text)
    addon.db.objectScan = addon.db.objectScan or {}

    local opt, name = text:match('^(-.+)%s+(.*)')
    local scan = { name=(name or text):lower() }

    if opt == '-map' then
        scan.map = C_Map.GetBestMapForUnit('player')
    end
    table.insert(addon.db.objectScan, scan)
    table.sort(addon.db.objectScan, function (a,b) return a.name < b.name end)
    self:UpdateScanning()
end

function Scanner:ObjectDel(n)
    n = tonumber(n)
    if n and addon.db.objectScan then
        table.remove(addon.db.objectScan, n)
        self:UpdateScanning()
    end
end

function Scanner:UpdateScanning()
    if next(addon.db.objectScan or {}) then
        self.scannedGUID = self.scannedGUID or {}
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        self:RegisterEvent("PLAYER_ENTERING_WORLD")
        self:RegisterEvent("PLAYER_LOGOUT")
        if WOW_PROJECT_ID == 1 then
            self:RegisterEvent("VIGNETTES_UPDATED")
            self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
            self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        end
    else
        self:RemoveAllWaypoints()
        self:UnregisterAllEvents()
        self.scannedGUID = table.wipe(self.scannedGUID or {})
    end
end

function Scanner:MatchesConditions(scan)
    if scan.map then
        local map = C_Map.GetBestMapForUnit('player')
        while map and map > 0 do
            if map == scan.map then
                return true
            else
                local info = C_Map.GetMapInfo(map)
                map = info and info.parentMapID or nil
            end
        end
        return false
    end
    return true
end

function Scanner:ScanUnitNameplate(unit)
    if C_Secrets.ShouldUnitIdentityBeSecret(unit) then
        return
    end

    local name = UnitName(unit):lower()
    local guid = UnitGUID(unit)

    local npcID = select(6, strsplit('-', UnitGUID(unit)))

    for _, scan in ipairs(addon.db.objectScan) do
        if ( name and name:find(scan.name, nil, true) ) or
           ( npcID and tonumber(scan.name) == tonumber(npcID) ) then
            if not self.scannedGUID[guid] then
                self.scannedGUID[guid] = { name = name }
                local msg = format("Nameplate %s found", name)
                addon.printf(msg)
                PlaySound(11466)
            end
        end
    end
end

local badAtlasNames = {
    ["VignetteLoot"]        = true,
    ["racing"]              = true,
    ["poi-scrapper"]        = true,
    ["dragon-rostrum"]      = true,
}

-- Stuff that annoys me but I haven't put a deny option in yet
local badObjectIDs = {
    ["620688"]              = true, -- Incomplete Book of Sonnets
    ["617881"]              = true, -- Rookery Cache
}

function Scanner:VignetteMatches(scan, info)
    local guidType, _, _, _, _, id = strsplit('-', info.objectGUID)
    if not self:MatchesConditions(scan) then
        return false
    elseif badObjectIDs[id] then
        return false
    elseif scan.name:sub(1,1) == '^' and info.atlasName:lower():find(scan.name) then
        return true
    elseif info.atlasName:lower():find(scan.name, nil, true) then
        return true
    elseif scan.name == 'vignette' then
        return not badAtlasNames[info.atlasName]
    elseif guidType and guidType:lower() == scan.name then
        return not badAtlasNames[info.atlasName]
    elseif info.name and info.name:lower():find(scan.name, nil, true) then
        return true
    else
        return false
    end
end

function Scanner:AddWaypoint(data)
    addon.printf("Adding %s (%s)", data.objectGUID, data.name)
    data.tomTomWaypoint =
        TomTom:AddWaypoint(
            data.uiMapID,
            data.pos.x,
            data.pos.y,
            {
                title = data.name,
                persistent = nil,
                minimap = true,
                world = true
            })
end

function Scanner:RemoveWaypoint(data)
    if data.tomTomWaypoint then
        addon.printf("Clearing %s (%s)", data.objectGUID, data.name)
        TomTom:RemoveWaypoint(data.tomTomWaypoint)
        data.tomTomWaypoint = nil
    end
end


function Scanner:ShowWaypoints()
    if not self.scannedGUID or not TomTom then
        return
    end
    for _, data in pairs(self.scannedGUID) do
        if data.pos and not data.tomTomWaypoint then
            self:AddWaypoint(data)
        end
    end
end

function Scanner:RemoveAllWaypoints()
    if not self.scannedGUID or not TomTom then
        return
    end
    for _, data in pairs(self.scannedGUID) do
        self:RemoveWaypoint(data)
    end
end

function Scanner:IsCloseWaypoint(data)
    if not TomTom or not data.tomTomWaypoint then
        return false
    end

    -- I don't know how big the minimap is, pretty big?
    local dist = TomTom:GetDistanceToWaypoint(data.tomTomWaypoint)
    if dist and dist < 250 then
        return true
    end

    return false
end

function Scanner:IsWaypointOnCurrentMap(data)
    local mapID = C_Map.GetBestMapForUnit('player')
    if data.tomTomWaypoint[1] == mapID then
        return true
    end
    if not mapID then
        return false
    end
    local mapInfo = C_Map.GetMapInfo(mapID)
    if data.tomTomWaypoint[1] == mapInfo.parentMapID then
        return true
    end
    return false
end

function Scanner:ShouldClear(data)
    -- The order here is important to that the autoclear treasures don't
    -- disappear when someone else picks them, but do disappear if we
    -- change zones.
    if not data.tomTomWaypoint then
        return false
    elseif data.autoClear == true then
        return true
    elseif not self:IsWaypointOnCurrentMap(data) then
        return true
    elseif type(data.autoClear) == 'number' then
        return GetTime() >= data.autoClear
    elseif self:IsCloseWaypoint(data) then
        return true
    else
        return false
    end
end

function Scanner:PruneWaypoints()
    if not self.scannedGUID or not TomTom then
        return
    end

    local objectGUIDs = {}
    for _, vignetteGUID in ipairs(C_VignetteInfo.GetVignettes()) do
        local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
        if info then
            objectGUIDs[info.objectGUID] = info
        end
    end
    for objectGUID, data in pairs(self.scannedGUID) do
        if objectGUIDs[objectGUID] == nil and data.tomTomWaypoint then
            if not TomTom:IsValidWaypoint(data.tomTomWaypoint) then
                data.tomTomWaypoint = nil
            elseif self:ShouldClear(data) then
                addon.printf("Removing waypoint %s (%s)", objectGUID, data.name)
                local wp = data.tomTomWaypoint
                data.tomTomWaypoint = nil
                TomTom:RemoveWaypoint(wp)
            end
        end
    end
end

function Scanner:ScanVignetteByID(id)
    local info = C_VignetteInfo.GetVignetteInfo(id)
    if not info then
        return
    end
    if self.scannedGUID[info.objectGUID] then
        return
    end

    local uiMapID = C_Map.GetBestMapForUnit('player')
    if not uiMapID then return end

    for _, scan in ipairs(addon.db.objectScan) do
        if self:VignetteMatches(scan, info) then
            local pos = C_VignetteInfo.GetVignettePosition(info.vignetteGUID, uiMapID)
            if pos then
                local data = CopyTable(info)
                data.uiMapID = uiMapID
                data.pos = pos
                if data.onWorldMap and not data.onMinimap then
                    data.autoClear = true
                elseif info.atlasName == 'VignetteKillElite' then
                    data.autoClear = true
                elseif info.objectGUID:sub(1, 10) == 'GameObject' then
                    data.autoClear = GetTime() + 300
                else
                    data.autoClear = false
                end
                addon.printf(format("Vignette %s at (%.2f, %.2f)", data.name, pos.x*100, pos.y*100))
                addon.printf(format("  guid %s", data.objectGUID))
                addon.printf(format("  atlas %s", data.atlasName))
                addon.printf(format("  autoClear %s", tostring(data.autoClear)))
                PlaySound(11466)
                self.scannedGUID[data.objectGUID] = data
                if TomTom and addon.db.autoScanWaypoint then
                    self:AddWaypoint(data)
                    TomTom:SetClosestWaypoint()
                end
            end
        end
    end
end

function Scanner:ScanAllVignettes()
    for _, id in ipairs(C_VignetteInfo.GetVignettes()) do
        self:ScanVignetteByID(id)
    end

    if not TomTom then return end

    -- Sometimes (like with S.C.R.A.P. Heap) a vignette is removed then
    -- replaced with another with the same objectGUID (to change icon).
    -- Delay the delete to give the new one a chance to spawn.
    C_Timer.After(1,
        function ()
            self:PruneWaypoints()
            TomTom:SetClosestWaypoint()
        end)
end

local function SlashCommand(arg)
    local arg1, arg2 = string.split(' ', arg or '', 2)
    if arg1 == 'add' then
        Scanner:ObjectAdd(arg2)
    elseif arg1 == 'del' then
        Scanner:ObjectDel(arg2)
    elseif arg1 == 'wipe' then
        Scanner:ObjectWipe()
    elseif arg1 == 'way' then
        if TomTom then
            Scanner:ShowWaypoints()
            TomTom:SetClosestWaypoint()
        end
    elseif arg1 == 'clear' then
        Scanner:RemoveAllWaypoints()
    end
    Scanner:ObjectList()
end

local moduleInfo = {
    Initialize = function () Scanner:UpdateScanning() end,
    SlashCommands = {
        ['find-mob'] = SlashCommand,
        ['fm'] = SlashCommand,
        ['scan-vignettes'] = function () Scanner:ScanAllVignettes() end,
        ['sv'] = function () Scanner:ScanAllVignettes() end,
        ['prune'] = function () Scanner:PruneWaypoints() end,
    }
}
addon.RegisterModule(moduleInfo)
addon.Scanner = Scanner
