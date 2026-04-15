--[[----------------------------------------------------------------------------
--
-- _LiteLite
--
----------------------------------------------------------------------------]]--

local _, addon = ...

local modules = {}

local MouseoverMacroTemplate =
[[#showtooltip {1}
/cast [@mouseover,help,nodead][help,nodead] {1}
/stopspelltarget
]]

local TrinketMacroTemplate =
[[#showtooltip {1}
/use [harm] 13
/use [harm] 14
/cast {1}
]]

local CursorMacroTemplate =
[[#showtooltip {1}
/cast [mod:alt][@cursor] {1}
]]

local PlayerMacroTemplate =
[[#showtooltip {1}
/cast [mod:alt][@player] {1}
]]

_LiteLite = CreateFrame('Frame')
_LiteLite:SetScript('OnEvent',
        function (self, e, ...)
            if self[e] then self[e](self, ...) end
        end)
_LiteLite:RegisterEvent('PLAYER_LOGIN')

local printTag = ORANGE_FONT_COLOR:WrapTextInColorCode("LiteLite: ")

function addon.RegisterModule(info)
    table.insert(modules, info)
    if info.SlashCommands then
        for keyword, func in pairs(info.SlashCommands) do
            addon.SlashCmdList[keyword] = func
        end
    end
end

function addon.format(fmt, ...)
    return printTag .. string.format(fmt, ...)
end

function addon.printf(fmt, ...)
    SELECTED_CHAT_FRAME:AddMessage(addon.format(fmt, ...))
end

function addon.formatc(fmt, color, ...)
    local msg = string.format(fmt, ...)
    return printTag .. color:WrapTextInColorCode(msg)
end

function addon.printfc(fmt, color, ...)
    SELECTED_CHAT_FRAME:AddMessage(addon.formatc(fmt, color, ...))
end

function addon.FlashScreen(seconds)
    local f = _LiteLiteFullScreenFlash
    f:Show()
    f.pulseAnim:Play()
    C_Timer.After(seconds or 5, function () f.pulseAnim:Stop() f:Hide() end)
end

local function strtemplate(str, vars, ...)
    -- Can pass {1} {2} etc. as varargs rather than table
    if type(vars) ~= 'table' then
        vars = { vars, ... }
    end

    -- If your key is '1', god help you
    return (string.gsub(
                str,
                "({([^}]+)})",
                function(whole, i) return vars[tonumber(i) or i] or whole end
            ))
end

local function CreateOrEditMacro(macroName, macroText, isLocal)
    local i = GetMacroIndexByName(macroName)
    if i == 0 then
        i = CreateMacro(macroName, 'INV_MISC_QUESTIONMARK', macroText, isLocal)
    else
        EditMacro(i, nil, nil, macroText)
    end
    return i
end

function _LiteLite:CreateSpellMacro(template, spell)
    spell = spell or GameTooltip:GetSpell()
    if not spell then
        return
    end

    local macroName = '_' .. spell
    local macroText = strtemplate(template, spell)
    local i = CreateOrEditMacro(macroName, macroText, true)
    if i then PickupMacro(i) end
end

addon.SlashCmdList = { }

function _LiteLite:SlashCommand(arg)
    local cmd, rest = string.split(' ', arg, 2)

    if addon.SlashCmdList[cmd] then
        addon.SlashCmdList[cmd](rest)
        return true
    end

    local arg1, arg2, arg3

    -- Zero argument options
    if arg == 'spec-config' or arg == 'sc' then
        self:ImportExportSpecConfig()
        return true
    elseif arg == 'tooltip-ids' or arg == 'ti' then
        self:HookTooltip()
        return true
    elseif arg == 'great-vault' or arg == 'gv' then
        self:ShowGreatVault()
        return true
    elseif arg == 'mythic-plus-history' or arg == 'mph' then
        self:MythicPlusHistory()
        return true
    elseif arg == 'announce-mob' or arg == 'am' then
        self:ReportTargetLocation()
        return true
    elseif arg == 'paste' then
        self:CopyPaste()
        return true
    elseif arg == 'dragonridingbar' or arg == 'drb' then
        self:SetupDragonridingBar()
        return true
    elseif arg == 'panda-gems' or arg == 'pg' then
        PandaGem:Show()
        return true
    elseif arg == 'scan-vignettes' or arg == 'sv' then
        self:VIGNETTES_UPDATED()
        return true
    elseif arg == 'drive' then
        self:ShowDRIVE()
        return true
    elseif arg == 'reshii' then
        self:ShowRESHII()
        return true
    elseif arg == 'cagepets' or arg == 'cp' then
        self:CageTriplicatePets()
        return true
    elseif arg == 'lure' then
        self:MidnightSkinningLure()
        return true
    elseif arg == 'decode' then
        self:Decode()
        return true
    end

    -- One argument options
    arg1, arg2 = string.split(' ', arg, 2)
    if arg1 == 'mouseover-macro' or arg1 == 'mm' then
        self:CreateSpellMacro(MouseoverMacroTemplate, arg2)
        return true
    elseif arg1 == 'trinket-macro' or arg1 == 'tm' then
        self:CreateSpellMacro(TrinketMacroTemplate, arg2)
        return true
    elseif arg1 == 'cursor-macro' or arg1 == 'cm' then
        self:CreateSpellMacro(CursorMacroTemplate, arg2)
        return true
    elseif arg1 == 'player-macro' or arg1 == 'pm' then
        self:CreateSpellMacro(PlayerMacroTemplate, arg2)
        return true
    elseif arg1 == 'gkeys' or arg1 == 'gk' then
        self:SearchGlobalKeys(arg2)
        return true
    elseif arg1 == 'gvals' or arg1 == 'gv' then
        self:SearchGlobalValues(arg2)
        return true
    elseif arg1 == 'copy-chat' or arg1 == 'cc' then
        self:CopyChat()
        return true
    elseif arg1 == 'guild-news' or arg1 == 'gn' then
        local iLevel = tonumber(arg2)
        self:GuildNews(iLevel)
        return true
    elseif arg1 == 'delves' then
        self:ListDelves(arg2)
        return true
    elseif arg1 == 'auto-waypoint' or arg1 == 'aw' then
        addon.db.autoScanWaypoint = StringToBoolean(arg2 or 0) or nil
        return true
    elseif arg1 == 'tinspect' then
        self:TableInspectEval(arg2)
        return true
    end

    -- Two argument options
    arg1, arg2, arg3 = string.split(' ', arg, 3)
    if arg1 == 'equipset-icon' or arg1 == 'esi' then
        if arg2 == 'auto' then
            self:AutoEquipsetIcons()
        else
            self:SetEquipsetIcon(arg2, arg3)
        end
        return true
    elseif arg1 == 'find-mob' or arg1 == 'fm' then
        if arg2 == 'add' then
            self:ScanMobAdd(arg3)
        elseif arg2 == 'del' then
            self:ScanMobDel(arg3)
        elseif arg2 == 'clear' then
            self:ScanMobClear()
        elseif arg2 == 'way' then
            if TomTom then
                self:ShowScanWaypoints()
                TomTom:SetClosestWaypoint()
            end
        end
        self:ScanMobList()
        return true
    elseif arg1 == 'bind-macro' or arg1 == 'bm' then
        addon.db.bindKey = arg2
        addon.db.bindMacro = arg3:gsub("\\n", "\n")
        self:SetBindMacro()
        return true
    end

    addon.printf("/ll announce-mob | am")
    addon.printf("/ll auto-waypoint | aw")
    addon.printf("/ll button-macro [|bm] <key> <macrotext>")
    addon.printf("/ll delves")
    addon.printf("/ll equipset-icon [n [iconid]]")
    addon.printf("/ll equipset-icon auto")
    addon.printf("/ll find-mob substring")
    addon.printf("/ll gkeys text")
    addon.printf("/ll great-vault | gv")
    addon.printf("/ll gvals text")
    addon.printf("/ll guild-news <min-ilevel>")
    addon.printf("/ll mythic-plus-history | mph")
    addon.printf("/ll nameplate-settings")
    addon.printf("/ll quest-baseline")
    addon.printf("/ll quest-report")
    addon.printf("/ll spec-config | sc")
    addon.printf("/ll tooltip-ids")
    addon.printf("/ll cursor-macro [spellname]")
    addon.printf("/ll mouseover-macro [spellname]")
    addon.printf("/ll player-macro [spellname]")
    addon.printf("/ll trinket-macro [spellname]")
    addon.printf("/ll world-quest [tww|df|sl|bfa|legion|<mapid>]")
    return true
end

function _LiteLite:SetupSlashCommand()
    SlashCmdList['_LiteLite'] = function (...) self:SlashCommand(...) end
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

    SlashCmdList['CDM'] = function () CooldownViewerSettings:Show() end
    _G.SLASH_CDM1 = "/cdm"
end

function _LiteLite:PLAYER_LOGIN()
    addon.printf('Initialized.')

    _LiteLiteDB = _LiteLiteDB or {}
    addon.db = _LiteLiteDB

    for _, info in ipairs(modules) do
        if info.Initialize then
            info.Initialize()
        end
    end

    self:SetupSlashCommand()
    self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE')
    -- self:RegisterEvent('FACTION_STANDING_CHANGED')
    self:RegisterEvent('TRAIT_CONFIG_UPDATED')
    self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
    self:RegisterEvent('LFG_LIST_JOINED_GROUP')
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
    self:RegisterEvent('PLAYER_LOGOUT')
    self:RegisterEvent('SETTINGS_LOADED')

    self:UpdateScanning()
    self:SetBindMacro()
    self:CheckVaultRewards()

    _LiteLiteTable:SetAutoWidth(true)
end

function _LiteLite:CheckVaultRewards()
    if C_WeeklyRewards and C_WeeklyRewards.HasAvailableRewards() then
        addon.printf("Check your vault!")
    end
end

function _LiteLite:SETTINGS_LOADED()
    SetCVar("cooldownViewerEnabled", true)
    SetCVar("damageMeterEnabled", true)

    SetCVar("autoLootDefault", true)
    SetCVar("AutoPushSpellToActionBar", 0)

    self:RaidFrameOptions()
end

-- So I can toggle between my USB headset and my speakers without
-- having to drill down so far into the interface.

function _LiteLite:NextGameSoundOutput()
    local cvar = 'Sound_OutputDriverIndex'
    local i = GetCVar(cvar) or 0

    i = i + 1
    if i >= Sound_GameSystem_GetNumOutputDrivers() then
        i = 0
    end

    SetCVar(cvar, i)
    Sound_GameSystem_RestartSoundSystem()

    local deviceName = Sound_GameSystem_GetOutputDriverNameByIndex(i)
    UIErrorsFrame:AddMessage(deviceName, 0.1, 1.0, 0.1)
end

function _LiteLite:SearchGlobalKeys(text)
    if not text then return end

    text = text:lower()

    addon.printf("Searching global keys for %s", tostring(text))

    local lines = {}
    for k, v in pairs(_G) do
        if type(k) == 'string' then
            local allowPattern = text:sub(1,1) == '^' or text:sub(-1) == '$'
            if k:lower():find(text, nil, not allowPattern) then
                table.insert(lines, string.format("%s = %s", k, tostring(v)))
            end
        end
    end

    table.sort(lines)
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

function _LiteLite:SearchGlobalValues(text)
    if not text then return end

    text = text:lower()

    addon.printf("Searching global values for %s", tostring(text))

    local lines = {}
    for k, v in pairs(_G) do
        if type(k) == 'string' and type(v) == 'string' then
            local allowPattern = text:sub(1,1) == '^' or text:sub(-1) == '$'
            if v:lower():find(text, nil, not allowPattern) then
                table.insert(lines, string.format("%s = %s", k, tostring(v)))
            end
        end
    end
    table.sort(lines)
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

function _LiteLite:TableInspect(data)
    if not LM then return end
    local text = LM.TableToString(data)
    _LiteLiteText.EditBox:SetText(text)
    _LiteLiteText:Show()
end

function _LiteLite:TableInspectEval(cmd)
    local f = loadstring('return ' .. cmd)
    if f then
        local data = f()
        self:TableInspect(data)
    end
end

function _LiteLite:CopyChat(sourceFrame)
    sourceFrame = sourceFrame or SELECTED_CHAT_FRAME
    local lines = {}
    for i = 1, sourceFrame:GetNumMessages() do
        local msg = sourceFrame:GetMessageInfo(i)
        msg = msg:gsub("|K(.-)|k", "<kstring>")
        table.insert(lines, msg or "")
    end
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

local function ApplyPaste()
    local text = _LiteLiteText.EditBox:GetText()
    ChatFrame_OpenChat("")
    local edit = ChatEdit_GetActiveWindow()
    for _, line in ipairs({ string.split("\n", text) }) do
        edit:SetText(line)
        ChatEdit_SendText(edit, 1)
        ChatEdit_DeactivateChat(edit)
    end
end

function _LiteLite:CopyPaste()
    _LiteLiteText.ApplyFunc = ApplyPaste
    _LiteLiteText.EditBox:SetText('')
    _LiteLiteText:Show()
end

local function ApplyDecode()
    local encoded = _LiteLiteText.EditBox:GetText()
    local compressed = C_EncodingUtil.DecodeBase64(encoded)
    if not compressed then return end
    local serialized = C_EncodingUtil.DecompressString(compressed)
    if not serialized then return end
    local data = C_EncodingUtil.DeserializeCBOR(serialized)
    if not data then return end
    _LiteLiteText.EditBox:SetText(LM.TableToString(data))
end

function _LiteLite:Decode()
    _LiteLiteText.ApplyFunc = ApplyDecode
    _LiteLiteText.EditBox:SetText('')
    _LiteLiteText:Show()
end

function _LiteLite:HookTooltip()
    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Item,
        function (ttFrame)
            local _, link = ttFrame:GetItem()
            local id = GetItemInfoFromHyperlink(link)
            if id then
                ttFrame:AddDoubleLine("ItemID", id)
            end
        end)

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Spell,
        function (ttFrame)
            local _, id = ttFrame:GetSpell()
            if id then
                ttFrame:AddDoubleLine("SpellID", id)
            end
        end)

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Unit,
        function (ttFrame)
            local _, unit = ttFrame:GetUnit()
            if unit then
                local _, _, _, _, _, id = strsplit('-', UnitGUID(unit))
                if id then
                    ttFrame:AddDoubleLine("UnitID", id)
                end
            end
        end)
end

function _LiteLite:ScanMobList()
    addon.printf("Scan for mobs:")
    if next(addon.db.scanMobNames or {}) then
        for i, name in pairs(addon.db.scanMobNames or {}) do
            addon.printf("%d. %s", i, name)
        end
    else
        addon.printf("   None.")
    end
end

function _LiteLite:ScanMobClear()
    addon.db.scanMobNames = table.wipe(addon.db.scanMobNames or {})
    self:UpdateScanning()
end

function _LiteLite:ScanMobAdd(name)
    addon.db.scanMobNames = addon.db.scanMobNames or {}
    table.insert(addon.db.scanMobNames, name:lower())
    self:UpdateScanning()
end

function _LiteLite:ScanMobDel(name)
    if addon.db.scanMobNames then
        local n = tonumber(name)
        if n then
            table.remove(addon.db.scanMobNames, n)
        else
            tDeleteItem(addon.db.scanMobNames, name:lower())
        end
        self:UpdateScanning()
    end
end

function _LiteLite:UpdateScanning()
    if next(addon.db.scanMobNames or {}) then
        self.scannedGUID = self.scannedGUID or {}
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        if WOW_PROJECT_ID == 1 then
            self:RegisterEvent("VIGNETTES_UPDATED")
            self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
            self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        end
    else
        self:RemoveAllScanWaypoints()
        self.scannedGUID = table.wipe(self.scannedGUID or {})
        self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
        if WOW_PROJECT_ID == 1 then
            self:UnregisterEvent("VIGNETTES_UPDATED")
            self:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
            self:UnregisterEvent("ZONE_CHANGED_NEW_AREA")
        end
    end
end

function _LiteLite:NAME_PLATE_UNIT_ADDED(unit)
    if C_Secrets.ShouldUnitIdentityBeSecret(unit) then
        return
    end

    local name = UnitName(unit):lower()
    local guid = UnitGUID(unit)

    local npcID = select(6, strsplit('-', UnitGUID(unit)))

    for _, n in ipairs(addon.db.scanMobNames) do
        if ( name and name:find(n, nil, true) ) or
           ( npcID and tonumber(n) == tonumber(npcID) ) then
            if not self.scannedGUID[guid] then
                self.scannedGUID[guid] = { name = name }
                local msg = format("Nameplate %s found", name)
                addon.printf(msg)
                PlaySound(11466)
            end
            if not GetRaidTargetIndex(unit) then
                SetRaidTarget(unit, 6)
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
}

function _LiteLite:VignetteMatches(scanMobName, info)
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

function _LiteLite:AddWaypoint(data)
    print(format("Adding %s (%s)", data.objectGUID, data.name))
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

function _LiteLite:RemoveWaypoint(data)
    if data.tomTomWaypoint then
        print(format("Clearing %s (%s)", data.objectGUID, data.name))
        TomTom:RemoveWaypoint(data.tomTomWaypoint)
        data.tomTomWaypoint = nil
    end
end


function _LiteLite:ShowScanWaypoints()
    if not self.scannedGUID or not TomTom then
        return
    end
    for _, data in pairs(self.scannedGUID) do
        if data.pos and not data.tomTomWaypoint then
            self:AddWaypoint(data)
        end
    end
end

function _LiteLite:RemoveAllScanWaypoints()
    if not self.scannedGUID or not TomTom then
        return
    end
    for _, data in pairs(self.scannedGUID) do
        self:RemoveWaypoint(data)
    end
end

function _LiteLite:IsCloseWaypoint(data)
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

function _LiteLite:ShouldClear(data)
    if not data.tomTomWaypoint then
        return false
    elseif data.autoClear == true then
        return true
    elseif type(data.autoClear) == 'number' then
        return GetTime() >= data.autoClear
    elseif self:IsCloseWaypoint(data) then
        return true
    else
        return false
    end
end

function _LiteLite:PruneScanWaypoints()
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
                print(format("Clearing %s (%s)", objectGUID, data.name))
                local wp = data.tomTomWaypoint
                data.tomTomWaypoint = nil
                TomTom:RemoveWaypoint(wp)
            end
        end
    end
end

function _LiteLite:ScanMobAddFromVignette(id)
    local info = C_VignetteInfo.GetVignetteInfo(id)
    if not info then
        return
    end
    if self.scannedGUID[info.objectGUID] then
        return
    end

    local uiMapID = C_Map.GetBestMapForUnit('player')
    if not uiMapID then return end

    for _, n in ipairs(addon.db.scanMobNames) do
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

function _LiteLite:VIGNETTE_MINIMAP_UPDATED(id)
    self:ScanMobAddFromVignette(id)
end

function _LiteLite:VIGNETTES_UPDATED()
    for _, id in ipairs(C_VignetteInfo.GetVignettes()) do
        self:ScanMobAddFromVignette(id)
    end

    if not TomTom then return end

    -- Sometimes (like with S.C.R.A.P. Heap) a vignette is removed then
    -- replaced with another with the same objectGUID (to change icon).
    -- Delay the delete to give the new one a chance to spawn.
    C_Timer.After(1,
        function ()
            self:PruneScanWaypoints()
            TomTom:SetClosestWaypoint()
        end)
end

function _LiteLite:ZONE_CHANGED_NEW_AREA()
    self:VIGNETTES_UPDATED()
end

function _LiteLite:PLAYER_LOGOUT()
    self:RemoveAllScanWaypoints()
end

local IgnoreMaps = {
    [2213] = true,      -- City of Threads
    [2216] = true,      -- City of Threads - Lower
    [2256] = true,      -- Azj-kahet Lower
}

function addon.FindChildZoneMaps(expansion)
    local todo
    if not expansion or expansion == 'midnight' then
        todo = { 2537 }
    elseif expansion == 'tww' then
        todo = { 2274 }
    elseif expansion == 'df' then
        todo = { 1978 }
    elseif expansion == 'sl' then
        todo = { 1550 }
    elseif expansion == 'bfa' then
        todo = { 875, 876 }
    elseif expansion == 'legion' then
        todo = { 619 }
    elseif tonumber(expansion) then
        todo = { tonumber(expansion) }
    else
        return {}
    end

    local maps = {}

    while #todo > 0 do
        local mapID = table.remove(todo, 1)
        local mapInfo = C_Map.GetMapInfo(mapID)
        maps[mapID] = C_Map.GetMapInfo(mapID)
        for _, info in ipairs(C_Map.GetMapChildrenInfo(mapID)) do
            if maps[info.mapID] == nil then
                table.insert(todo, info.mapID)
            end
        end
    end

    local wanted = {}
    for _,info in pairs(maps) do
        if info.mapType == Enum.UIMapType.Zone and not IgnoreMaps[info.mapID] then
            table.insert(wanted, info.mapID)
        end
    end
    table.sort(wanted)
    return wanted
end

function _LiteLite:ShowGreatVault()
    WeeklyRewards_ShowUI()
    WeeklyRewardsFrame:SetUpConditionalActivities()
    WeeklyRewardsFrame:Refresh()
end

function _LiteLite:MythicPlusHistory()
    local runs = C_MythicPlus.GetRunHistory(false, true)
    table.sort(runs, function (a, b) return a.level > b.level end)
    addon.printf('Mythic plus runs this week:')
    for i, info in ipairs(runs) do
        local name = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID)
        addon.printf('% 2d:  %d%s %s',
                i, info.level, info.completed and '+' or '', name)
    end
end

local function GetFactionNumbersByName(name)
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.factionID and data.name == name then
            local friendshipData = C_GossipInfo.GetFriendshipReputation(data.factionID)
            if friendshipData and friendshipData.friendshipFactionID > 0 then
                local rankData = C_GossipInfo.GetFriendshipReputationRanks(data.factionID)
                local rankText = string.format('%s %d/%d (%s)', FRIEND, rankData.currentLevel, rankData.maxLevel, friendshipData.reaction)
                if rankData.currentLevel == rankData.maxLevel then
                    return rankText, friendshipData.standing, friendshipData.reactionThreshold
                else
                    return rankText,
                        friendshipData.standing - friendshipData.reactionThreshold,
                        friendshipData.nextThreshold - friendshipData.reactionThreshold
                end
            end
            if C_Reputation.IsFactionParagonForCurrentPlayer(data.factionID) then
                local currentValue, threshold = C_Reputation.GetFactionParagonInfo(data.factionID)
                return 'P x' .. math.floor(currentValue / threshold),
                       currentValue % threshold,
                       threshold
            end
            local majorFactionData = C_MajorFactions.GetMajorFactionData(data.factionID)
            if majorFactionData then
                return RENOWN_LEVEL_LABEL:format(majorFactionData.renownLevel),
                       majorFactionData.renownReputationEarned,
                       majorFactionData.renownLevelThreshold
            end
            return _G['FACTION_STANDING_LABEL'..data.reaction],
                   data.currentStanding,
                   data.nextReactionThreshold
        end
    end
end

local function PrintFactionIncrease(factionName, amount)
    local name, cur, max = GetFactionNumbersByName(factionName)
    if name then
        local txt = string.format('%s +%d -> %s: %d/%d', factionName, amount, name, cur, max)
        addon.printf(BLUE_FONT_COLOR:WrapTextInColorCode(txt))
    end
end

function _LiteLite:FACTION_STANDING_CHANGED(factionID, updatedStanding)
    addon.printf("FACTION_STANDING_CHANGED %d %s", factionID, tostring(updatedStanding))
end

function _LiteLite:CHAT_MSG_COMBAT_FACTION_CHANGE(msg)
    if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then
        return
    end
    local factionName, amount = msg:match('with (.-) increased by (%d+)')
    amount = tonumber(amount)
    if factionName and amount and amount >= 50 then
        C_Timer.After(0.1, function () PrintFactionIncrease(factionName, amount) end)
    end
end

function _LiteLite:ReportTargetLocation()
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

function _LiteLite:RaidFrameOptions()
    SetCVar("raidFramesDisplayClassColor", true)
    SetCVar("raidFramesDisplayPowerBars", true)
    SetCVar("raidFramesDisplayOnlyHealerPowerBars", true)
    SetCVar("raidOptionDisplayMainTankAndAssist", false)
end

local ImportExportMixin = {
    ImportLoadout =
        function (self, importText, loadoutName)
            addon.printf('Importing loadout: ' .. loadoutName)
            local importStream = ExportUtil.MakeImportDataStream(importText)
            local headerValid, serializationVersion, specID, treeHash = self:ReadLoadoutHeader(importStream)

            if not headerValid then addon.printf('Bad header') return end
            if specID ~= PlayerUtil.GetCurrentSpecID() then addon.printf('Bad spec') return end

            local configID = C_ClassTalents.GetActiveConfigID()
            local configInfo = C_Traits.GetConfigInfo(configID)
            local treeInfo = C_Traits.GetTreeInfo(configID, configInfo.treeIDs[1])

            local loadoutContent = self:ReadLoadoutContent(importStream, treeInfo.ID)
            if not loadoutContent then addon.printf('Loadout did not convert') return end
            local loadoutEntryInfo = self:ConvertToImportLoadoutEntryInfo(configID, treeInfo.ID, loadoutContent)

            if loadoutName == 'active' then
                C_Traits.ResetTree(configID, configInfo.treeIDs[1])
                self:PurchaseLoadout(configID, loadoutEntryInfo)
                C_Traits.CommitConfig(configID) -- TTT says this doesn't work
            else
                local ok, err = C_ClassTalents.ImportLoadout(configID, loadoutEntryInfo, loadoutName)
                C_Traits.CommitConfig(configID) -- TTT says this doesn't work
                if not ok then
                    addon.printf('Loadout import failed: %s: %s', loadoutName, err)
                    return
                end
            end
        end,
    -- Two annoyances, solved with brute force. The nodes are not in dependency
    -- order, and the loadoutEntryInfo doesn't contain whether this is a choice
    -- node or not. The neat answer to the second and probably the first is to
    -- go spelunking around in the trait tree, but associating the treeNodes
    -- with the nodeEntry is annoying and this works.
    PurchaseLoadout =
        function (self, configID, loadoutEntryInfo)
            local allSucceeded
            while true do
                local didSomething = false
                allSucceeded = true
                for _, nodeEntry in pairs(loadoutEntryInfo) do
                    local success = C_Traits.SetSelection(configID, nodeEntry.nodeID, nodeEntry.selectionEntryID)
                    if not success then
                        for _rank = 1, nodeEntry.ranksPurchased do
                            success = C_Traits.PurchaseRank(configID, nodeEntry.nodeID)
                        end
                    end
                    if success then
                        didSomething = true
                    else
                        allSucceeded = false
                    end
                end
                if not didSomething then break end
            end
            return allSucceeded
        end,
    GetConfigID = function (self) return C_ClassTalents.GetActiveConfigID() end,
}

local function GetActionMacroInfo(actionID)
    local macroName = GetActionText(actionID)
    return GetMacroInfo(macroName)
end

--- Use JSON becuase I can peer at it. CBOR is better but it would have to be
--- Base64 encoded. Difficulty: JSON can't have gaps in an array, and Blizzard's
--- serializer will bomb out if t[1] exists and there are gaps, so force the
--- serializer to output a key table by tostring()ing the indexes.
local function SpecConfigToString()
    local map = {}

    map.actions = {}

    for i = 1, 180 do
        if GetActionInfo(i) then
            local index = tostring(i)
            map.actions[index] = { GetActionInfo(i) }
            if map.actions[index][1] == "macro" then
                local name, icon, text = GetActionMacroInfo(i)
                if name then
                    if text:find('#showtooltip') then icon = 134400 end
                    map.actions[index][3] = name
                    map.macros = map.macros or {}
                    map.macros[name] = { name, icon, text }
                end
            end
        end
    end

    local specID = PlayerUtil.GetCurrentSpecID()
    local lastSelectedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    local configID = C_ClassTalents.GetActiveConfigID()

    map.loadout = {
        string = C_Traits.GenerateImportString(configID),
        name = lastSelectedConfigID and C_Traits.GetConfigInfo(lastSelectedConfigID).name or 'active'
    }

    -- Clique bindings
    if Clique and Clique.db then
        map.clique = CopyTable(Clique.db.profile.bindings)
    end

    return C_EncodingUtil.SerializeJSON(map)
end

local function PickupFlyoutByActionID(id)
    for i = 1, 1000 do
        local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
        if info and info.itemType == Enum.SpellBookItemType.Flyout and info.actionID == id then
             C_SpellBook.PickupSpellBookItem(i, Enum.SpellBookSpellBank.Player)
            return
        end
    end
end

local function SetAction(i, action)
    if not action or not action[1] then
        PickupAction(i)
    elseif action[1] == "spell" then
        C_Spell.PickupSpell(action[2])
        PlaceAction(i)
    elseif action[1] == "macro" then
        PickupMacro(action[3])
        PlaceAction(i)
    elseif action[1] == "item" then
        PickupItem(action[2])
        PlaceAction(i)
    elseif action[1] == "flyout" then
        PickupFlyoutByActionID(action[2])
        PlaceAction(i)
    elseif action[1] == "companion" then
        PickupCompanion(action[3], action[2])
        PlaceAction(i)
    else
        print("Don't know how to place action of type:", unpack(action))
    end
    ClearCursor()
end

local function SetMacro(info)
    local name, icon, text = unpack(info)
    local i, existingName, existingIcon, existingText = GetMacroInfo(name)
    if text:find('#showtooltip') then icon = 134400 end
    if i == nil then
        CreateMacro(name, icon, text, true)
    elseif text ~= existingText then
        EditMacro(i, name, icon, text)
    end
end

local function SpecConfigFromString(text)
    local map = C_EncodingUtil.DeserializeJSON(text)
    if not map then return end

    addon.printf('Loading macros')
    if map.macros then
        for name, info in pairs(map.macros) do
            addon.printf(' - ' .. name)
            SetMacro(info)
        end
    end

    addon.printf('Setting action bar actions')
    for i = 1, 180 do
        local index = tostring(i)
        SetAction(i, map.actions[index])
    end

    addon.printf('Setting up loadout')
    if map.loadout then
        local currentConfigsByName = {}
        local specID = PlayerUtil.GetCurrentSpecID()
        for _,configID in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID)) do
            local info = C_Traits.GetConfigInfo(configID)
            currentConfigsByName[info.name] = configID
        end

        C_AddOns.LoadAddOn('Blizzard_PlayerSpells')
        local importer = CreateFromMixins(ClassTalentImportExportMixin, ImportExportMixin)
        if currentConfigsByName[map.loadout.name] then
            local lastSelectedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            local activeConfigName = lastSelectedConfigID and C_Traits.GetConfigInfo(lastSelectedConfigID).name
            if activeConfigName == map.loadout.name then
                addon.printf('Importing into active loadout: ' .. map.loadout.name)
                map.loadout.name = 'active'
            else
                addon.printf('Deleting existing inactive loadout: ' .. map.loadout.name)
                C_ClassTalents.DeleteConfig(currentConfigsByName[map.loadout.name])
            end
        end
        importer:ImportLoadout(map.loadout.string, map.loadout.name)
    end

    if map.clique and Clique and Clique.db then
        addon.printf('Setting up Clique')
        local p = Clique.db.profile
        p.bindings = p.bindings or {}
        table.wipe(p.bindings)
        Mixin(p.bindings, map.clique)
    end
end

function _LiteLite:ImportExportSpecConfig()
    _LiteLiteText.ApplyFunc =
        function ()
            local text = _LiteLiteText.EditBox:GetText()
            SpecConfigFromString(text)
        end
    _LiteLiteText.EditBox:SetText(SpecConfigToString())
    _LiteLiteText.EditBox:HighlightText()
    _LiteLiteText.EditBox:SetAutoFocus(true)
    _LiteLiteText:Show()
end

local function UpdateEquipmentSetForLoadout()
    if InCombatLockdown() then return end

    if not _LiteLite.equipmentSetLoadoutDirty then return end

    _LiteLite.equipmentSetLoadoutDirty = nil

    local specID, specName = PlayerUtil.GetCurrentSpecID()
    if not specID then return end

    local configID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    if not configID then return end

    local info = C_Traits.GetConfigInfo(configID)
    if not info or info.type ~= Enum.TraitConfigType.Combat then return end

    local loadoutSetName = specName .. ' ' .. info.name
    local loadoutSetID = C_EquipmentSet.GetEquipmentSetID(loadoutSetName)

    if loadoutSetID then
        addon.printf('Change equipment set ' .. loadoutSetName)
        C_EquipmentSet.UseEquipmentSet(loadoutSetID)
        return
    end

    local specIndex = GetSpecialization()
    if not specIndex then return end

    local specSetID = C_EquipmentSet.GetEquipmentSetForSpec(specIndex)
    if specSetID then
        local specSetName = C_EquipmentSet.GetEquipmentSetInfo(specSetID)
        addon.printf('Change equipment set ' .. specSetName)
        C_EquipmentSet.UseEquipmentSet(specSetID)
        return
    end
end

function _LiteLite:UpdateEquipmentSet()
    self.equipmentSetLoadoutDirty = true
    C_Timer.After(0, UpdateEquipmentSetForLoadout)
end

function _LiteLite:TRAIT_CONFIG_UPDATED(id)
    if id == C_ClassTalents.GetActiveConfigID() then
        self:UpdateEquipmentSet()
    end
end

function _LiteLite:ACTIVE_TALENT_GROUP_CHANGED()
    self:UpdateEquipmentSet()
end

function _LiteLite:PLAYER_REGEN_ENABLED()
    UpdateEquipmentSetForLoadout()
end

local guildNameColors = {}

local function UpdateGuildNameColors()
    local realm = GetRealmName()
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
        name = name:gsub("-"..realm, '')
        guildNameColors[name] = C_ClassColor.GetClassColor(class):WrapTextInColorCode(name)
    end
end

local guildNews = {}

local DATE_FMT = "%.3s %d/%d"

local function UpdateGuildNews(minItemLevel)
    guildNews = {}
    for i = 1, GetNumGuildNews() do
        local info = C_GuildInfo.GetGuildNewsInfo(i)
        if info and info.newsType == NEWS_ITEM_LOOTED and info.whatText then
            local level = GetDetailedItemLevelInfo(info.whatText)
            local invType, subType, _, equipSlot = select(6, GetItemInfo(info.whatText))
            if equipSlot ~= '' and level and level >= ( minItemLevel or 0 ) then
                local date = format(DATE_FMT, CALENDAR_WEEKDAY_NAMES[info.weekday + 1], info.day + 1, info.month + 1)
                local entry = {
                    date,
                    guildNameColors[info.whoText] or info.whoText,
                    level,
                    _G[equipSlot],
                    info.whatText
                }
                table.insert(guildNews, entry)
            end
        end
    end
end

function _LiteLite:GuildNews(minItemLevel)
    self.newsScanner = self.newsScanner or CreateFrame("Frame")
    self.newsScanner:RegisterEvent("GUILD_NEWS_UPDATE")
    self.newsScanner:RegisterEvent("GUILD_ROSTER_UPDATE")
    self.newsScanner:SetScript("OnEvent",
        function (self, event)
            if not _LiteLiteTable:IsShown() then
                self:UnregisterAllEvents()
            elseif event == "GUILD_ROSTER_UPDATE" then
                UpdateGuildNameColors()
                UpdateGuildNews(minItemLevel)
            elseif event == "GUILD_NEWS_UPDATE" then
                UpdateGuildNews(minItemLevel)
                _LiteLiteTable:SetRows(guildNews)
            end
        end)
    QueryGuildNews()
    C_GuildInfo.GuildRoster()
    _LiteLiteTable:Reset()
    _LiteLiteTable:Setup(GUILD_NEWS, { "Date", "Player", "iLvl", "Slot", "Item" })
    UpdateGuildNews(minItemLevel)
    _LiteLiteTable:SetRows(guildNews)
    _LiteLiteTable:SetEnableSort(false)
    _LiteLiteTable:Show()
end


--[[------------------------------------------------------------------------]]--

function _LiteLite:LFG_LIST_JOINED_GROUP(resultID, kstringGroupName)
    local searchResultInfo = C_LFGList.GetSearchResultInfo(resultID)

    local activityID = searchResultInfo.activityIDs[1]
    local isWarMode = searchResultInfo.isWarMode
    local activityInfo = C_LFGList.GetActivityInfoTable(activityID, nil, isWarMode)

    if activityInfo.isMythicPlusActivity then
        local _, _, _, _, role = C_LFGList.GetApplicationInfo(resultID)
        local msg = format('Joined %s "%s" as %s', activityInfo.fullName, kstringGroupName, _G[role])
        local dashes = string.rep('-', msg:len())
        addon.printf(HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(dashes))
        addon.printf(HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(msg))
        addon.printf(HEIRLOOM_BLUE_COLOR:WrapTextInColorCode(dashes))

--[[
        -- kstring is gone before the GROUP_JOINED so can't use it
        local chatMsg = format('Joined %s as %s', activityInfo.fullName, _G[role])
        local function sendmsg()
            SendChatMessage(chatMsg, IsInRaid() and "RAID" or "PARTY")
        end
        if IsInGroup() then
            sendmsg()
        else
            EventUtil.RegisterOnceFrameEventAndCallback("GROUP_JOINED", sendmsg)
        end
]]
    end
end


--[[------------------------------------------------------------------------]]--

function _LiteLite:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(id)
    if id == Enum.PlayerInteractionType.ItemUpgrade then
        ToggleCharacter("PaperDollFrame")
    end
end

local DragonridingActions = {
    [121] = 372608,
    [122] = 372610,
    [123] = 361584,
    [124] = 403092,
    [125] = 425782,
    [126] = 0,
}

function _LiteLite:SetupDragonridingBar()
    for actionID, spellID in pairs(DragonridingActions) do
        if spellID == 0 then
            PickupAction(actionID)
            ClearCursor()
        else
            local aType, aID, aSubType = GetActionInfo(actionID)
            if aType ~= 'spell' or aID ~= spellID then
                C_Spell.PickupSpell(spellID)
                PlaceAction(actionID)
                ClearCursor()
            end
        end
    end
end

local BindMacroButton = CreateFrame('Button', '_LiteLiteBindMacroButton', nil, 'SecureActionButtonTemplate')
BindMacroButton:RegisterForClicks('AnyDown', 'AnyUp')

function _LiteLite:SetBindMacro()
    if addon.db.bindKey and addon.db.bindMacro then
        BindMacroButton:SetAttribute('type', 'macro')
        BindMacroButton:SetAttribute('macrotext', addon.db.bindMacro)
        SetOverrideBindingClick(BindMacroButton, true, addon.db.bindKey, BindMacroButton:GetName())
    end
end

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

function _LiteLite:ListDelves()
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

local DRIVE_TREE = 1056

function _LiteLite:ShowDRIVE()
    C_AddOns.LoadAddOn("Blizzard_GenericTraitUI")
    GenericTraitFrame:SetTreeID(DRIVE_TREE)
    GenericTraitFrame:Show()
    GenericTraitFrame:SetParent(UIParent)
    GenericTraitFrame:ClearAllPoints()
    GenericTraitFrame:SetPoint("CENTER")
end

function _LiteLite:ShowRESHII()
    C_AddOns.LoadAddOn("Blizzard_GenericTraitUI")
    GenericTraitFrame:SetSystemID(29)
    GenericTraitFrame:SetTreeID(1115)
    ToggleFrame(GenericTraitFrame)
end

-- Cage any battle pets we have 3 of
function _LiteLite:CageTriplicatePets()
    local counts = {}

    -- Assumption is that the pet indexes are ordered by level
    -- with the highest first, so we will always cage the lowest
    -- level one.

    for i = 1, C_PetJournal.GetNumPets() do
       local info = { C_PetJournal.GetPetInfoByIndex(i) }
       counts[info[2]] = ( counts[info[2]] or 0 ) + 1
       if counts[info[2]] > 2 and info[16] and info[1] then
          C_PetJournal.CagePetByID(info[1])
       end
    end
end
