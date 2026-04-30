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
    if next(addon.db.scanMobNames or {}) then
        local names = GetKeysArray(addon.db.scanMobNames)
        table.sort(names)
        for i, name in ipairs(names) do
            addon.printf("%d. %s", i, name)
        end
    else
        addon.printf("   None.")
    end
end

function Scanner:ObjectWipe()
    addon.db.scanMobNames = table.wipe(addon.db.scanMobNames or {})
    self:UpdateScanning()
end

function Scanner:ObjectAdd(name)
    addon.db.scanMobNames = addon.db.scanMobNames or {}
    addon.db.scanMobNames[name:lower()] = {}
    self:UpdateScanning()
end

function Scanner:ObjectDel(name)
    if addon.db.scanMobNames then
        local n = tonumber(name)
        if n then
            local names = GetKeysArray(addon.db.scanMobNames)
            name = names[n]
        end
        addon.db.scanMobNames[name] = nil
        self:UpdateScanning()
    end
end

function Scanner:UpdateScanning()
    if next(addon.db.scanMobNames or {}) then
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

function Scanner:ScanUnitNameplate(unit)
    if C_Secrets.ShouldUnitIdentityBeSecret(unit) then
        return
    end

    local name = UnitName(unit):lower()
    local guid = UnitGUID(unit)

    local npcID = select(6, strsplit('-', UnitGUID(unit)))

    for n in pairs(addon.db.scanMobNames) do
        if ( name and name:find(n, nil, true) ) or
           ( npcID and tonumber(n) == tonumber(npcID) ) then
            if not self.scannedGUID[guid] then
                self.scannedGUID[guid] = { name = name }
                local msg = format("Nameplate %s found", name)
                addon.printf(msg)
                PlaySound(11466)
            end
            --[[
            if not GetRaidTargetIndex(unit) then
                SetRaidTarget(unit, 6)
            end
            ]]
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

function Scanner:VignetteMatches(scanMobName, info)
    scanMobName = scanMobName:lower()
    local guidType, _, _, _, _, id = strsplit('-', info.objectGUID)
    if badObjectIDs[id] then
        return false
    elseif scanMobName:sub(1,1) == '^' and info.atlasName:lower():find(scanMobName) then
        return true
    elseif info.atlasName:lower():find(scanMobName, nil, true) then
        return true
    elseif scanMobName == 'vignette' then
        return not badAtlasNames[info.atlasName]
    elseif guidType and guidType:lower() == scanMobName then
        return not badAtlasNames[info.atlasName]
    elseif info.name and info.name:lower():find(scanMobName, nil, true) then
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
    local mapInfo = C_Map.GetMapInfo(C_Map.GetBestMapForUnit('player'))
    if data.tomTomWaypoint[1] == mapInfo.mapID then
        return true
    elseif data.tomTomWaypoint[1] == mapInfo.parentMapID then
        return true
    else
        return false
    end
end

function Scanner:ShouldClear(data)
    if not data.tomTomWaypoint then
        return false
    elseif data.autoClear == true then
        return true
    elseif type(data.autoClear) == 'number' then
        return GetTime() >= data.autoClear
    elseif self:IsCloseWaypoint(data) then
        return true
    elseif not self:IsWaypointOnCurrentMap(data) then
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

    for n in pairs(addon.db.scanMobNames) do
        if self:VignetteMatches(n, info) then
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
    }
}
addon.RegisterModule(moduleInfo)
