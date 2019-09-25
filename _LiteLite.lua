--[[----------------------------------------------------------------------------
--
-- _LiteLite
--
----------------------------------------------------------------------------]]--

BINDING_HEADER_LITELITE = "_LiteLite"
BINDING_NAME_LL_TOGGLE_GUILD_UI = "Toggle Guild UI"
BINDING_NAME_LL_NEXT_GAME_SOUND_OUTPUT = "Next Game Sound Output"

local MouseoverMacroTemplate =
[[#showtooltip {1}
/cast [@mouseover,help,nodead][help,nodead] {1}
/stopspelltarget
]]

local TrinketMacroTemplate =
[[#showtooltip {1}
/run SlashCmdList.UI_ERRORS_OFF()
/use [harm] 13
/use [harm] 14
/run SlashCmdList.UI_ERRORS_ON()
/cast {1}
]]

_LiteLite = CreateFrame('Frame')
_LiteLite:SetScript('OnEvent',
        function (self, e, ...)
            if self[e] then self[e](self, e, ...) end
        end)
_LiteLite:RegisterEvent('PLAYER_LOGIN')

local function GetActiveChatFrame()
    for i = 1, NUM_CHAT_WINDOWS do
        local f = _G['ChatFrame'..i]
        if f:IsShown() then
            return f
        end
    end
    return DEFAULT_CHAT_FRAME
end

local printTag = ORANGE_FONT_COLOR_CODE
                     .. "LiteLite: "
                     .. FONT_COLOR_CODE_CLOSE

local function printf(fmt, ...)
    local msg = string.format(fmt, ...)
    GetActiveChatFrame():AddMessage(printTag .. msg)
end

function _LiteLite:BiggerFrames()
    QuestFrame:SetScale(1.5)
    GossipFrame:SetScale(1.5)
    ItemTextFrame:SetScale(1.5)
    hooksecurefunc(
        'EncounterJournal_LoadUI',
        function () EncounterJournal:SetScale(1.5) end
    )
end

function _LiteLite:SpellCastAnnounce(spellID, spellName)
    if spellID == 115310 then
        -- Revival (Mistweaver Monk)
        msg = format('%s cast - %s', GetSpellLink(spellName), self.playerName)
        SendChatMessage(msg, 'SAY')
    end
end

function _LiteLite:NazChests()
    if not IsQuestFlaggedCompleted(55959) then SlashCmdList.TOMTOM_WAY("Nazjatar 37.9 6.4 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(55963) then SlashCmdList.TOMTOM_WAY("Nazjatar 43.8 16.5 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(56912) then SlashCmdList.TOMTOM_WAY("Nazjatar 24.8 35.2 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(56912) then SlashCmdList.TOMTOM_WAY("Nazjatar 26.7 33.8 Cave Entrance") end
    if not IsQuestFlaggedCompleted(55961) then SlashCmdList.TOMTOM_WAY("Nazjatar 55.7 14.5 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(55958) then SlashCmdList.TOMTOM_WAY("Nazjatar 61.4 22.9 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(55958) then SlashCmdList.TOMTOM_WAY("Nazjatar 61.4 19.9 Cave Entrance") end
    if not IsQuestFlaggedCompleted(55962) then SlashCmdList.TOMTOM_WAY("Nazjatar 64.1 28.6 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(55960) then SlashCmdList.TOMTOM_WAY("Nazjatar 37.2 19.2 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(55960) then SlashCmdList.TOMTOM_WAY("Nazjatar 39.7 10 Underwater Cave") end
    if not IsQuestFlaggedCompleted(56547) then SlashCmdList.TOMTOM_WAY("Nazjatar 80.5 31.9 Glowing Arcane Trunk") end
    if not IsQuestFlaggedCompleted(56547) then SlashCmdList.TOMTOM_WAY("Nazjatar 83.0 33.8 Pathway up building") end
    if not IsQuestFlaggedCompleted(55954) then SlashCmdList.TOMTOM_WAY("Nazjatar 34.5 40.4 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55949) then SlashCmdList.TOMTOM_WAY("Nazjatar 49.6 64.5 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55938) then SlashCmdList.TOMTOM_WAY("Nazjatar 85.3 38.6 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55957) then SlashCmdList.TOMTOM_WAY("Nazjatar 37.9 60.5 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55942) then SlashCmdList.TOMTOM_WAY("Nazjatar 79.5 27.2 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55947) then SlashCmdList.TOMTOM_WAY("Nazjatar 44.7 48.9 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55952) then SlashCmdList.TOMTOM_WAY("Nazjatar 37.4 42.8 Cave Entrance") end
    if not IsQuestFlaggedCompleted(55952) then SlashCmdList.TOMTOM_WAY("Nazjatar 34.6 43.6 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55953) then SlashCmdList.TOMTOM_WAY("Nazjatar 26.0 32.4 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55955) then SlashCmdList.TOMTOM_WAY("Nazjatar 50.6 50.0 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55955) then SlashCmdList.TOMTOM_WAY("Nazjatar 49.7 50.3 Cave Entrance") end
    if not IsQuestFlaggedCompleted(55943) then SlashCmdList.TOMTOM_WAY("Nazjatar 64.3 33.3 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55945) then SlashCmdList.TOMTOM_WAY("Nazjatar 52.8 49.8 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55951) then SlashCmdList.TOMTOM_WAY("Nazjatar 48.5 87.4 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55948) then SlashCmdList.TOMTOM_WAY("Nazjatar 43.4 58.2 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55941) then SlashCmdList.TOMTOM_WAY("Nazjatar 73.2 35.8 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55939) then SlashCmdList.TOMTOM_WAY("Nazjatar 80.4 29.8 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55946) then SlashCmdList.TOMTOM_WAY("Nazjatar 58.0 35.0 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55946) then SlashCmdList.TOMTOM_WAY("Nazjatar 57.3 39.0 Underwater Cave Entrance") end
    if not IsQuestFlaggedCompleted(55940) then SlashCmdList.TOMTOM_WAY("Nazjatar 74.8 53.2 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55956) then SlashCmdList.TOMTOM_WAY("Nazjatar 39.8 49.2 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55950) then SlashCmdList.TOMTOM_WAY("Nazjatar 38.7 74.4 Arcane Chest") end
    if not IsQuestFlaggedCompleted(55944) then SlashCmdList.TOMTOM_WAY("Nazjatar 56.3 33.8 Arcane Chest") end
end

function _LiteLite:ShiftEnchantsScroll()
    LoadAddOn('Blizzard_TradeSkillUI')

    hooksecurefunc(TradeSkillFrame.DetailsFrame, 'Create',
        function ()
            if IsShiftKeyDown() == false then
                return
            end

            -- Check for Enchanting
            local prof = select(6, C_TradeSkillUI.GetTradeSkillLine())
            if prof ~= 333 then
                return
            end

            -- Enchanting Vellum
            UseItemByName(38682)
        end)
end

function _LiteLite:DreamweaversEmissaryUp()
    -- The Dreamweavers = Quest 42170
    -- Faction ID = 1883
    -- Dalaran = UiMapID 627

    local total = C_Reputation.GetFactionParagonInfo(1883)
    if not total or total == 0 then
        return
    end

    local bountyQuests = GetQuestBountyInfoForMapID(627)
    local info = ChatTypeInfo['SYSTEM']
    for _, q in ipairs(bountyQuests) do
        if q.questID == 42170 then
            local msg = "|cff20ff20The Dreamweavers|r is available."
            printf(msg)
            RaidNotice_AddMessage(RaidWarningFrame, msg, info, 18)
        elseif q.questID == 43179 then
            local msg = "|cffff00ffThe Kirin Tor|r is available."
            printf(msg)
            RaidNotice_AddMessage(RaidWarningFrame, msg, info, 18)
        end
    end

end

function _LiteLite:DreamweaversMissionUp()
    LoadAddOn('Blizzard_GarrisonUI')

    local missions = C_Garrison.GetAvailableMissions(LE_FOLLOWER_TYPE_GARRISON_7_0) or {}

    for _, m in ipairs(missions) do
        for _, r in ipairs(m.rewards) do
            if r.itemID and (r.itemID == 141339 or r.itemID == 141988 or r.itemID == 146942 or r.itemID == 150926) then
                local msg = "|cff20ff20Dreamweavers|r mission available."
                local info = ChatTypeInfo['SYSTEM']
                printf(msg)
                RaidNotice_AddMessage(RaidWarningFrame, msg, info, 18)
                return
            end
        end
    end
end

local BfAInvasionMapIDs = {
    896,    -- Drustvar
    863,    -- Nazmir
    942,    -- Stormsong Valley
    895,    -- Tiragarde Sound
    864,    -- Vol'dun
    862,    -- Zuldazar
}

function _LiteLite:BfAInvasionUp()
    for _,uiMapID in ipairs(BfAInvasionMapIDs) do
        if C_InvasionInfo.GetInvasionForUiMapID(uiMapID) then
            local details = C_Map.GetMapInfo(uiMapID)
            local msg = "Battle for Azeroth Invasion UP in "..details.name
            local info = ChatTypeInfo['SYSTEM']
            printf(msg)
            RaidNotice_AddMessage(RaidWarningFrame, msg, info, 18)
            return
        end
    end
end

local TanaanRaresQuestIDs = {
    Deathtalon  = 39287,
    Terrorfist  = 39288,
    Doomroller  = 39289,
    Vengeance   = 39290
}

function _LiteLite:TanaanRares()
    local status
    for rare,questID in pairs(TanaanRaresQuestIDs) do
        if IsQuestFlaggedCompleted(questID) then
            status = RED_FONT_COLOR_CODE .. 'Completed' .. FONT_COLOR_CODE_CLOSE
        else
            status = GREEN_FONT_COLOR_CODE .. 'Available' .. FONT_COLOR_CODE_CLOSE
        end
        printf('%s: %s', rare, status)
    end
end

function _LiteLite:NameplateSettings()
    SetCVar('nameplateShowFriendlyNPCs', 1)
    SetCVar('nameplateShowFriends', 1)
    SetCVar('nameplateShowEnemies', 1)
    SetCVar('nameplateShowAll', 1)
    SetCVar('nameplateMaxDistance', 100)
end

function _LiteLite:ChatFrameSettings()
    ChatFrame1:SetSize(512,256)
    ChatFrame1:ClearAllPoints()
    ChatFrame1:SetPoint('BOTTOMLEFT', UIParent, 'BOTTOMLEFT' ,38, 8)
    FCF_SavePositionAndDimensions(ChatFrame1)

    for i = 1,NUM_CHAT_WINDOWS+1 do
        local f = _G['ChatFrame'..i]
        if f then
            FCF_SetWindowAlpha(f, 0.66)
            FCF_SetWindowColor(f, 0, 0, 0)
        end
    end
end

local function GameTooltipIcon()
    local _, id = GameTooltip:GetSpell()
    if id then
        return select(3, GetSpellInfo(id))
    end
    _,  id = GameTooltip:GetItem()
    if id then
        return select(10, GetItemInfo(id))
    end
end

function strtemplate(str, vars, ...)
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

function _LiteLite:CreateSpellMacro(template, spell)
    spell = spell or GameTooltipSpellInfo()
    if not spell then
        return
    end

    local macroName = '_' .. spell
    local macroText = strtemplate(template, spell)
    local i = GetMacroIndexByName(macroName)
    if i == 0 then
        i = CreateMacro(macroName, 'INV_MISC_QUESTIONMARK', macroText, true)
    else
        EditMacro(i, nil, nil, macroText)
    end
    if i then PickupMacro(i) end
end

function _LiteLite:AutoEquipsetIcons()
    for _, n in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local specIndex = C_EquipmentSet.GetEquipmentSetAssignedSpec(n)
        if specIndex then
            arg1 = select(4, GetSpecializationInfo(specIndex))
            self:SetEquipsetIcon(n, arg1)
        end
    end
end

function _LiteLite:SetEquipsetIcon(n, arg1)
    n = tonumber(n or PaperDollEquipmentManagerPane.selectedSetID)

    if n == nil then
        return
    end

    local name = C_EquipmentSet.GetEquipmentSetInfo(n)

    arg1 = tonumber(arg1) or GameTooltipIcon()

    if arg1 == nil then
        return
    end

    printf('Setting equipset icon for %s (%d) to %d', name, n, arg1)
    C_EquipmentSet.ModifyEquipmentSet(n, name, arg1)
end

function _LiteLite:RunTimedChecks()

    C_Timer.After(900, _LiteLite.RunTimedChecks)
end

function _LiteLite:SlashCommand(arg)

    -- Zero argument options
    if arg == 'quest-scan' then
        local now = GetServerTime()
        self:ScanQuestsCompleted(now)
        return true
    elseif arg == 'quest-report' then
        local now = GetServerTime()
        self:ScanQuestsCompleted(now)
        self:ReportQuestsCompleted()
        return true
    elseif arg == 'chatframe-settings' then
        self:ChatFrameSettings()
        return true
    elseif arg == 'nameplate-settings' then
        self:NameplateSettings()
        return true
    elseif arg == 'tanaan-rares' then
        self:TanaanRares()
        return true
    elseif arg == 'naz-chests' then
        self:NazChests()
        return true
    elseif arg == 'tooltip-ids' then
        self:HookTooltip()
        return true
    end

    -- One argument options
    local arg1, arg2 = string.split(' ', arg, 2)
    if arg1 == 'mouseover-macro' then
        self:CreateSpellMacro(MouseoverMacroTemplate, arg2)
        return true
    elseif arg1 == 'trinket-macro' then
        self:CreateSpellMacro(TrinketMacroTemplate, arg2)
        return true
    elseif arg1 == 'gkeys' then
        self:SearchGlobals(arg2, true)
        return true
    elseif arg1 == 'gvals' then
        self:SearchGlobals(arg2, false)
        return true
    end

    -- Two argument options
    local arg1, arg2, arg3 = string.split(' ', arg, 3)
    if arg1 == 'equipset-icon' and arg2 == 'auto' then
        self:AutoEquipsetIcons()
        return true
    elseif arg1 == 'equipset-icon' then
        self:SetEquipsetIcon(arg2, arg3)
        return true
    end

    printf("/ll chatframe-settings")
    printf("/ll equipset-icon [n [iconid]]")
    printf("/ll equipset-icon auto")
    printf("/ll nameplate-settings")
    printf("/ll quest-scan")
    printf("/ll quest-report")
    printf("/ll gkeys text")
    printf("/ll gvals text")
    printf("/ll tanaan-rares")
    printf("/ll tooltip-ids")
    printf("/ll mouseover-macro [spellname]")
    printf("/ll trinket-macro [spellname]")
    return true
end

function _LiteLite:SetupSlashCommand()
    SlashCmdList['_LiteLite'] = function (...) self:SlashCommand(...) end
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

end

function _LiteLite:PLAYER_LOGIN()
    printf('Initialized.')

    self.playerName = format("%s-%s", UnitFullName('player'))

    self:ScanQuestsCompleted()
    self:SetupSlashCommand()
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')

    self:BiggerFrames()
    self:ShiftEnchantsScroll()

    C_Timer.After(15, _LiteLite.RunTimedChecks)
end

function _LiteLite:COMBAT_LOG_EVENT_UNFILTERED()
    local ts, e, _, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3 = CombatLogGetCurrentEventInfo()
    if e == 'UNIT_DIED' then
        if bit.bor(destFlags, 0x40) ~= 0 then
            self.lastKillName = destName
            self.lastKillTime = ts
        end
    elseif e == 'SPELL_CAST_SUCCESS' then
        if srcGUID == UnitGUID('player') then
            self:SpellCastAnnounce(arg1, arg2)
        end
    end
end

-- Show the old guild UI which is better than the new thing

function _LiteLite:ToggleGuildUI()
    if not IsInGuild() then return end

    GuildFrame_LoadUI()

    if not GuildFrame then return end

    if GuildFrame:IsShown() then
        HideUIPanel(GuildFrame)
    else
        GuildFrameTab2:Click()
        ShowUIPanel(GuildFrame)
    end
end

-- So I can toggle between my USB headset and my speakers without
-- having to drill down so far into the interface.

function _LiteLite:NextGameSoundOutput()
    local cvar = 'Sound_OutputDriverIndex'
    local i = BlizzardOptionsPanel_GetCVarSafe(cvar) or 0
    local n = Sound_GameSystem_GetNumOutputDrivers() or 1

    i = i + 1
    if i >= Sound_GameSystem_GetNumOutputDrivers() then
        i = 0
    end

    SetCVar(cvar, i)
    Sound_GameSystem_RestartSoundSystem()

    local deviceName = Sound_GameSystem_GetOutputDriverNameByIndex(i)
    UIErrorsFrame:AddMessage(deviceName, 0.1, 1.0, 0.1)
end

function _LiteLite:ScanQuestsCompleted(scanTime)
    self.questsCompleted = self.questsCompleted or {}
    scanTime = scanTime or 0

    for i = 1,100000 do
        if not self.questsCompleted[i] and IsQuestFlaggedCompleted(i) then
            self.questsCompleted[i] = scanTime
        end
    end
end

function _LiteLite:ReportQuestsCompleted()
    printf("Completed quests report:")
    for i = 1,100000 do
        if self.questsCompleted[i] and self.questsCompleted[i] > 0 then
            printf(format("Newly completed: %d at %d", i, self.questsCompleted[i]))
        end
    end
end

function _LiteLite:SearchGlobals(text, findKey)
    if not text then return end

    text = text:lower()

    printf("Searching global variables for %s", tostring(text))

    for k, v in pairs(_G) do
        if type(k) == 'string' and type(v) == 'string' then
            if findKey and k:lower():match(text) or v:lower():match(text) then
                printf("%s = %s", k, tostring(v))
            end
        end
    end
end

function _LiteLite:HookTooltip()
    GameTooltip:HookScript('OnTooltipSetItem',
        function (ttFrame)
            local _, link = ttFrame:GetItem()
            local id = GetItemInfoFromHyperlink(link)
            if id then
                ttFrame:AddDoubleLine("ItemID", id)
            end
        end)

    GameTooltip:HookScript('OnTooltipSetSpell',
        function (ttFrame)
            local _, id = GameTooltip:GetSpell()
            if id then
                ttFrame:AddDoubleLine("SpellID", id)
            end
        end)
end

local JellyNodeCoords = {
    { 33.12, 71.66 },
    { 31.71, 74.54 },
    { 28.22, 74.87 },
    { 63.24, 28.47 },
    { 61.40, 22.33 },
    { 58.85, 30.83 },
    { 55.10, 31.26 },
    { 54.03, 31.28 },
    { 55.78, 27.94 },
    { 56.06, 37.13 },
    { 53.30, 43.19 },
    { 49.85, 36.74 },
    { 56.28, 28.95 },
    { 58.58, 28.41 },
    { 63.27, 22.24 },
    { 61.45, 55.92 },
    { 55.23, 41.02 },
    { 56.63, 20.36 },
    { 56.40, 18.77 },
    { 47.39, 25.42 },
    { 37.33, 37.29 },
    { 35.71, 31.35 },
    { 46.55, 41.98 },
    { 66.93, 63.51 },
    { 64.24, 52.43 },
    { 62.08, 46.11 },
    { 58.27, 21.38 },
    { 56.14, 26.06 },
    { 52.53, 39.13 },
    { 63.13, 51.40 },
    { 58.30, 54.29 },
    { 54.72, 48.45 },
    { 56.21, 58.78 },
    { 66.43, 70.37 },
    { 69.71, 75.98 },
    { 71.32, 67.24 },
    { 66.00, 58.21 },
    { 68.25, 55.41 },
    { 61.47, 51.92 },
    { 64.01, 37.28 },
    { 62.50, 22.71 },
    { 53.91, 27.73 },
    { 52.37, 27.08 },
    { 49.26, 35.59 },
    { 58.08, 27.45 },
    { 63.60, 25.67 },
    { 31.46, 60.14 },
    { 60.52, 29.15 },
    { 63.60, 28.23 },
    { 57.86, 28.50 },
    { 57.58, 30.01 },
    { 55.24, 38.46 },
    { 53.34, 43.12 },
    { 44.63, 49.27 },
    { 44.21, 50.94 },
    { 40.39, 47.35 },
    { 36.77, 47.69 },
    { 35.55, 52.37 },
    { 35.11, 64.45 },
    { 33.24, 67.87 },
    { 33.39, 71.99 },
    { 29.82, 76.19 },
    { 25.51, 67.16 },
    { 56.25, 30.51 },
    { 53.04, 36.02 },
    { 40.92, 42.23 },
    { 38.81, 63.51 },
    { 45.88, 64.48 },
    { 72.13, 74.18 },
    { 67.60, 56.57 },
    { 63.61, 28.18 },
    { 63.86, 19.65 },
    { 46.40, 47.61 },
    { 41.10, 46.32 },
    { 31.31, 31.67 },
    { 35.75, 29.42 },
    { 35.80, 36.91 },
    { 37.97, 51.24 },
    { 33.60, 53.17 },
    { 27.64, 64.34 },
    { 28.01, 69.34 },
    { 27.50, 72.97 },
    { 62.76, 75.16 },
    { 71.19, 71.87 },
    { 70.08, 66.58 },
    { 67.31, 53.90 },
    { 63.13, 31.35 },
    { 66.97, 40.71 },
    { 55.07, 27.64 },
    { 44.78, 39.16 },
    { 42.56, 51.13 },
    { 32.06, 59.61 },
    { 30.92, 63.05 },
    { 49.12, 75.33 },
    { 52.33, 75.59 },
    { 63.13, 76.59 },
    { 72.16, 75.29 },
    { 56.02, 75.62 },
    { 56.30, 76.15 },
    { 64.06, 75.22 },
    { 60.91, 54.47 },
    { 59.13, 56.22 },
    { 47.02, 55.96 },
    { 48.95, 54.81 },
    { 49.11, 63.11 },
    { 44.00, 65.35 },
    { 37.08, 62.78 },
    { 36.41, 59.79 },
    { 26.42, 65.47 },
    { 26.97, 71.60 },
    { 26.25, 77.32 },
    { 53.21, 76.69 },
    { 53.57, 73.47 },
    { 52.20, 74.09 },
    { 63.46, 73.66 },
    { 68.10, 68.29 },
    { 61.18, 29.41 },
    { 60.06, 19.55 },
    { 55.11, 20.90 },
    { 59.75, 23.54 },
    { 57.44, 27.81 },
    { 45.17, 27.68 },
    { 46.71, 22.79 },
    { 47.62, 29.34 },
    { 44.27, 41.48 },
    { 56.00, 37.18 },
    { 37.15, 38.81 },
    { 35.21, 32.14 },
    { 32.99, 32.78 },
};

function _LiteLite:JellyDeposits()
    local gm = GatherMate2
    if not gm then return end
    for _, c in ipairs(JellyNodeCoords) do
        gm:AddNode(942, c[1]/100, c[2]/100, "Treasure", "Jelly Deposit")
    end
end

