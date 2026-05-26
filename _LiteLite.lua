--[[----------------------------------------------------------------------------
--
-- _LiteLite
--
----------------------------------------------------------------------------]]--

local _, addon = ...

local modules = {}

local ModuleCmdList = { }

local function SlashCommand(arg)
    local cmd, rest = string.split(' ', arg, 2)

    if ModuleCmdList[cmd] then
        ModuleCmdList[cmd](rest)
        return true
    end

    -- XXX FIXME PRINT HELP XXX
    return true
end

local function Initialize()
    addon.printf('Initialized.')

    _LiteLiteDB = _LiteLiteDB or {}
    addon.db = _LiteLiteDB

    for _, info in ipairs(modules) do
        if info.Initialize then
            info.Initialize()
        end
    end

    SlashCmdList['_LiteLite'] = SlashCommand
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

    SlashCmdList['CDM'] = function () CooldownViewerSettings:Show() end
    _G.SLASH_CDM1 = "/cdm"
end

EventUtil.ContinueOnPlayerLogin(Initialize)

EventRegistry:RegisterFrameEventAndCallback('SPELL_CONFIRMATION_PROMPT',
    function (_ownerID, ...)
        addon.db.SCP = addon.db.SCP or {}
        table.insert(addon.db.SCP, { ... })
        print('SPELL_CONFIRMATION_PROMPT', ...)
    end)

--[[ Utilities ]]---------------------------------------------------------------

local printTag = ORANGE_FONT_COLOR:WrapTextInColorCode("LiteLite: ")

function addon.RegisterModule(info)
    table.insert(modules, info)
    if info.SlashCommands then
        for keyword, func in pairs(info.SlashCommands) do
            ModuleCmdList[keyword] = func
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

--[[------------------------------------------------------------------------]]--

--[[
-- So I can toggle between my USB headset and my speakers without
-- having to drill down so far into the interface.

local function NextGameSoundOutput()
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
]]
