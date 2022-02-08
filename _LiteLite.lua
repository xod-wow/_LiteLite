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
/run m="UI_ERROR_MESSAGE" f=UIErrorsFrame f:UnregisterEvent(m)
/use [harm] 13
/use [harm] 14
/run f:RegisterEvent(m)
/cast {1}
]]

_LiteLite = CreateFrame('Frame')
_LiteLite:SetScript('OnEvent',
        function (self, e, ...)
            if self[e] then self[e](self, ...) end
        end)
_LiteLite:RegisterEvent('PLAYER_LOGIN')

local printTag = ORANGE_FONT_COLOR_CODE
                     .. "LiteLite: "
                     .. FONT_COLOR_CODE_CLOSE

local function printf(fmt, ...)
    local msg = string.format(fmt, ...)
    SELECTED_CHAT_FRAME:AddMessage(printTag .. msg)
end

local function Embiggen(f)
    --[[
    local ratio = f:GetHeight() / GetScreenHeight()
    local scale = (2/3) / ratio
    f:SetScale(scale)
    ]]
    f:SetScale(1.25)
end

function _LiteLite:BiggerFrames()
    QuestFrame:HookScript('OnShow', Embiggen)
    GossipFrame:HookScript('OnShow', Embiggen)
    ItemTextFrame:HookScript('OnShow', Embiggen)
    hooksecurefunc('Communities_LoadUI',
            function () CommunitiesFrame:HookScript('OnShow', Embiggen) end
        )
    hooksecurefunc('ToggleEncounterJournal',
            function () EncounterJournal:HookScript('OnShow', Embiggen) end
        )
end

function _LiteLite:FlashScreen(seconds)
    local f = _LiteLiteFullScreenFlash
    f:Show()
    f.pulseAnim:Play()
    C_Timer.After(seconds or 5, function () f.pulseAnim:Stop() f:Hide() end)
end

function _LiteLite:SpellCastAnnounce(spellID, spellName)
    if UnitIsPVP('player') or IsActiveBattlefieldArena() then
        return
    end

    if spellID == 115310 then
        -- Revival (Mistweaver Monk)
        msg = format('%s cast - %s', GetSpellLink(spellName), self.playerName)
        SendChatMessage(msg, 'SAY')
    end
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
    FCF_RestorePositionAndDimensions(ChatFrame1)

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
    spell = spell or GameTooltipSpellInfo()
    if not spell then
        return
    end

    local macroName = '_' .. spell
    local macroText = strtemplate(template, spell)
    local i = CreateOrEditMacro(macroName, macroText, true)
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
    if name == nil then
        return
    end

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
    if arg == 'quest-report' or arg == 'qr' then
        local now = GetServerTime()
        self:ScanQuestsCompleted(now)
        self:ReportQuestsCompleted()
        return true
    elseif arg == 'quest-baseline' or arg == 'qb' then
        local now = GetServerTime()
        self:ScanQuestsCompleted()
        for k in pairs(self.questsCompleted) do
            self.questsCompleted[k] = 0
        end
        return true
    elseif arg == 'chatframe-settings' or arg == 'cs' then
        self:ChatFrameSettings()
        return true
    elseif arg == 'nameplate-settings' or arg == 'ns' then
        self:NameplateSettings()
        return true
    elseif arg == 'tooltip-ids' or arg == 'ti' then
        self:HookTooltip()
        return true
    elseif arg == 'kickoff' or arg == 'ko' then
        self:KickOfflineRaidMembers()
        return true
    elseif arg == 'great-vault' or arg == 'gv' then
        self:ShowGreatVault()
        return true
    elseif arg == 'mythic-plus-history' or arg == 'mph' then
        self:MythicPlusHistory()
        return true
    elseif arg == 'xp' then
        self:CHAT_MSG_COMBAT_XP_GAIN()
        return true
    elseif arg == 'announce-mob' or arg == 'am' then
        self:ReportTargetLocation()
        return true
    elseif arg == 'paste' then
        self:CopyPaste()
        return true
    end

    -- One argument options
    local arg1, arg2 = string.split(' ', arg, 2)
    if arg1 == 'mouseover-macro' or arg1 == 'mm' then
        self:CreateSpellMacro(MouseoverMacroTemplate, arg2)
        return true
    elseif arg1 == 'trinket-macro' or arg1 == 'tm' then
        self:CreateSpellMacro(TrinketMacroTemplate, arg2)
        return true
    elseif arg1 == 'gkeys' or arg1 == 'gk' then
        self:SearchGlobalKeys(arg2)
        return true
    elseif arg1 == 'gvals' or arg1 == 'gv' then
        self:SearchGlobalValues(arg2)
        return true
    elseif arg1 == 'find-mob' or arg1 == 'fm' then
        if not arg2 then
            self:ListScanMobs()
        else
            self:ScanForMob(arg2)
        end
        return true
    elseif arg1 == 'clear-find-mob' or arg1 == 'cfm' then
        self:ClearScanMobs()
        return true
    elseif arg1 == 'wq-items' or arg1 == 'wqi' then
        self:WorldQuestItems(arg2)
        return true
    elseif arg1 == 'copy-chat' or arg1 == 'cc' then
        self:CopyChat()
        return true
    end

    -- Two argument options
    local arg1, arg2, arg3 = string.split(' ', arg, 3)
    if arg1 == 'equipset-icon' or arg1 == 'esi' then
        if arg2 == 'auto' then
            self:AutoEquipsetIcons()
        elseif arg2 and arg3 then
            self:SetEquipsetIcon(arg2, arg3)
        end
        return true
    end

    printf("/ll announce-mob | am")
    printf("/ll chatframe-settings")
    printf("/ll equipset-icon [n [iconid]]")
    printf("/ll equipset-icon auto")
    printf("/ll find-mob substring")
    printf("/ll gkeys text")
    printf("/ll great-vault | gv")
    printf("/ll gvals text")
    printf("/ll mouseover-macro [spellname]")
    printf("/ll mythic-plus-history | mp")
    printf("/ll nameplate-settings")
    printf("/ll quest-baseline")
    printf("/ll quest-report")
    printf("/ll tooltip-ids")
    printf("/ll trinket-macro [spellname]")
    printf("/ll wq-items")
    return true
end

function _LiteLite:SetupSlashCommand()
    SlashCmdList['_LiteLite'] = function (...) self:SlashCommand(...) end
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

end

function _LiteLite:PLAYER_LOGIN()
    printf('Initialized.')

    _LiteLiteDB = _LiteLiteDB or {}
    self.db = _LiteLiteDB

    self.playerName = format("%s-%s", UnitFullName('player'))

    self.questsCompleted = {}
    self:ScanQuestsCompleted()

    self:SetupSlashCommand()
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    self:RegisterEvent('CHAT_MSG_MONSTER_YELL')
    self:RegisterEvent('ENCOUNTER_START')
    self:RegisterEvent('ENCOUNTER_END')
    self:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
    self:RegisterEvent('COVENANT_CHOSEN')

    self:BiggerFrames()
    self:ShiftEnchantsScroll()
    self:HideMainMenuBarArt()
    self:UpdateCovenantMacros()

    hooksecurefunc('IslandsQueue_LoadUI', self.DefaultIslandsQueueHeroic)

    MerchantRepairItemButton:SetScript('OnClick', function () self:SellJunk() end)

    C_Timer.After(15, _LiteLite.RunTimedChecks)
end

function _LiteLite:CHAT_MSG_MONSTER_YELL(msg, name)
    if C_Map.GetBestMapForUnit('player') == 534 then -- Tanaan Jungle
        PlaySound(11466)
        self:FlashScreen(10)
        UIErrorsFrame:AddMessage(msg, 0.1, 1.0, 0.1)
    end
end

function _LiteLite:COMBAT_LOG_EVENT_UNFILTERED()
    local ts, e, _, srcGUID, srcName, srcFlags, srcRaidFlags, destGUID, destName, destFlags, destRaidFlags, arg1, arg2, arg3 = CombatLogGetCurrentEventInfo()
    if e == 'SPELL_CAST_SUCCESS' then
        if srcGUID == UnitGUID('player') then
            self:SpellCastAnnounce(arg1, arg2)
        end
    end
end

local StartQuotes = {
    "I have a bad feeling about this.",
    "Never tell me the odds!",
    "Let's keep a little optimism here.",
    "I expect to be well paid. I'm in it for the money.",
    "What good is a reward if you ain't around to use it?",
    "I take orders from just one person: me.",
    "You said you wanted to be around when I made a mistake, well, this could be it, sweetheart.",
    "Bring em on! I prefer a straight fight to all this sneaking around.",
}

function _LiteLite:ENCOUNTER_START()
    if UnitName('player') == "Tansolo" and math.random() <= 0.2 then
        local n = math.random(#StartQuotes)
        SendChatMessage(StartQuotes[n], 'SAY')
    end
end

local EndQuotes = {
    "Don't everbody thank me at once.",
    "You know, sometimes I amaze even myself.",
    "You like me because I'm a scoundrel. There aren’t enough scoundrels in your life.",
    "Afraid I was gonna leave without giving you a goodbye kiss?",
    "Sorry about the mess.",
    "Come on, admit it. Sometimes you think I’m all right.",
    "Scoundrel? Scoundrel? I like the sound of that.",
    "No reward is worth this.",
}

function _LiteLite:ENCOUNTER_END()
    if UnitName('player') == "Tansolo" and math.random() <= 0.2 then
        local n = math.random(#EndQuotes)
        SendChatMessage(EndQuotes[n], 'SAY')
    end
end

-- Show the old guild UI which is better than the new thing

function _LiteLite:ToggleGuildUI()
    if InCombatLockdown() then return end

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
    scanTime = scanTime or 0

    for i = 1,100000 do
        if not self.questsCompleted[i] and C_QuestLog.IsQuestFlaggedCompleted(i) then
            self.questsCompleted[i] = scanTime
        end
    end
end

function _LiteLite:ReportQuestsCompleted()
    printf("Completed quests report:")
    for i = 1,100000 do
        if self.questsCompleted[i] and self.questsCompleted[i] > 0 then
            local title = C_TaskQuest.GetQuestInfoByQuestID(i)
            printf(format("Newly completed: %d (%s) at %d", i, title or UNKNOWN, self.questsCompleted[i]))
        end
    end
end

function _LiteLite:SearchGlobalKeys(text)
    if not text then return end

    text = text:lower()

    printf("Searching global keys for %s", tostring(text))

    local lines = {}
    for k, v in pairs(_G) do
        if type(k) == 'string' and k:lower():find(text) then
            table.insert(lines, string.format("%s = %s", k, tostring(v)))
        end
    end

    table.sort(lines)
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

function _LiteLite:SearchGlobalValues(text)
    if not text then return end

    text = text:lower()

    printf("Searching global values for %s", tostring(text))

    local lines = {}
    for k, v in pairs(_G) do
        if type(k) == 'string' and type(v) == 'string' and v:lower():find(text) then
            table.insert(lines, string.format("%s = %s", k, tostring(v)))
        end
    end
    table.sort(lines)
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

function _LiteLite:CopyChat(sourceFrame)
    sourceFrame = sourceFrame or SELECTED_CHAT_FRAME
    local lines = {}
    for i = 1, sourceFrame:GetNumMessages() do
        local msg = sourceFrame:GetMessageInfo(i)
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

    GameTooltip:HookScript('OnTooltipSetUnit',
        function (ttFrame)
            local _, unit = GameTooltip:GetUnit()
            local _, _, _, _, _, id = strsplit('-', UnitGUID(unit))
            if id then
                ttFrame:AddDoubleLine("UnitID", id)
            end
        end)
end

function _LiteLite:ListScanMobs()
    for k,v in pairs(self.scanMobNames or {}) do
        printf(v)
    end
end

function _LiteLite:ClearScanMobs()
    self.scanMobNames = table.wipe(self.scanMobNames or {})
    self.announcedMobGUID = table.wipe(self.announcedMobGUID or {})
    self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
    self:UnregisterEvent("VIGNETTES_UPDATED")
    self:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

function _LiteLite:ScanForMob(name)
    self.scanMobNames = self.scanMobNames or {}
    self.announcedMobGUID = self.announcedMobGUID or {}
    table.insert(self.scanMobNames, name:lower())
    self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    self:RegisterEvent("VIGNETTES_UPDATED")
    self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
end

function _LiteLite:NAME_PLATE_UNIT_ADDED(unit)
    local name = UnitName(unit):lower()
    local guid = UnitGUID(unit)

    local npcID = select(6, strsplit('-', UnitGUID(unit)))

    for _, n in ipairs(self.scanMobNames) do
        if ( name and name:find(n) ) or
           ( npcID and tonumber(n) == tonumber(npcID) ) then
            if not self.announcedMobGUID[guid] then
                self.announcedMobGUID[guid] = name
                local msg = format("Nameplate %s found", name)
                printf(msg)
                PlaySound(11466)
            end
            if not GetRaidTargetIndex(unit) then
                SetRaidTarget(unit, 6)
            end
        end
    end
end

function _LiteLite:VIGNETTE_MINIMAP_UPDATED(id)
    local info = C_VignetteInfo.GetVignetteInfo(id)
    if not info or self.announcedMobGUID[info.objectGUID] then return end

    for _, n in ipairs(self.scanMobNames) do
        if info.name and info.name:lower():find(n) then
            self.announcedMobGUID[info.objectGUID] = info.name
            local msg = format("Vignette %s found", info.name)
            printf(msg)
            PlaySound(11466)
        end
    end
end

function _LiteLite:VIGNETTES_UPDATED()
    for _, id in ipairs(C_VignetteInfo.GetVignettes()) do
        self:VIGNETTE_MINIMAP_UPDATED(id)
    end
end

local function PrintEquipmentQuestRewards(mapName, questID)
    if not QuestUtils_IsQuestWorldQuest(questID) then
        return true
    end

    if not HaveQuestRewardData(questID) then
        C_TaskQuest.RequestPreloadRewardData(questID)
        return false
    end

    local n = GetNumQuestLogRewards(questID)
    if n == 0 then return end
    for i = 1, n do
        local name, texture, quantity, quality, isUsable, itemID, itemLevel = GetQuestLogRewardInfo(i, questID)
        if itemID then
            local item = Item:CreateFromItemID(itemID)
            item:ContinueOnItemLoad(
                function ()
                    local _, link, _, _, _, _, _, _, equipLoc = GetItemInfo(itemID)
                    if equipLoc ~= "" then
                        printf('    %s %d : [%s] %s (%d)', mapName, questID, _G[equipLoc], link or name, itemLevel)
                    elseif C_Soulbinds.IsItemConduitByItemInfo(link) then
                        printf('    %s %d : [CONDUIT] %s (%d)', mapName, questID, link or name, itemLevel)
                    end
                end)
        end
    end

    return true
end

local function GetMapQuestRewards(mapInfo)
    local quests = C_TaskQuest.GetQuestsForPlayerByMapID(mapInfo.mapID)
    for _, info in ipairs(quests) do
        if info.mapID == mapInfo.mapID then
            local done = PrintEquipmentQuestRewards(mapInfo.name, info.questId)
            if not done then
                C_Timer.After(2,
                    function ()
                        PrintEquipmentQuestRewards(mapInfo.name, info.questId)
                    end)
            end
        end
    end
end

function _LiteLite:WorldQuestItems(expansion)
    local maps
    if not expansion or expansion == 'sl' then
        maps = { 1550 }
    elseif expansion == 'bfa' then
        maps = { 876, 876 }
    else
        return
    end

    --[[
    printf('Emissary item rewards:')
    local bounties = GetQuestBountyInfoForMapID(875)
    for _, bounty in ipairs(bounties) do
        -- PrintEquipmentQuestRewards('Emissary', bounty.questID)
    end
    ]]

    printf('World quest item rewards:')
    for _, parentMapID in ipairs(maps) do
        local childInfo = C_Map.GetMapChildrenInfo(parentMapID)
        for _,mapInfo in pairs(childInfo or {}) do
            if mapInfo.mapType == Enum.UIMapType.Zone then
                GetMapQuestRewards(mapInfo)
            end
        end
    end
end

function _LiteLite:DefaultIslandsQueueHeroic()
    IslandsQueueFrame:HookScript('OnShow',
        function (self)
            local d
            if GetNumGroupMembers() == 3 then
                d = 1737
            else
                d = 1736
            end
            local dsf =  self.DifficultySelectorFrame
            for button in dsf.difficultyPool:EnumerateActive() do
                if button.difficulty == d then
                    self.DifficultySelectorFrame:SetActiveDifficulty(button)
                return
            end
            end
        end)
end

function _LiteLite:KickOfflineRaidMembers()
    if not UnitIsGroupLeader('player') or not IsInRaid() then   
        return
    end

    for i = 40, 1, -1 do
        local unit = 'raid'..i
        if UnitExists(unit) and not UnitIsConnected(unit) then
            UninviteUnit(GetUnitName(unit, true))
        end
    end
end

function _LiteLite:ShowGreatVault()
    LoadAddOn('Blizzard_WeeklyRewards')
    WeeklyRewardsFrame:Show()
end

function _LiteLite:MythicPlusHistory()
    local runs = C_MythicPlus.GetRunHistory(false, true)
    table.sort(runs, function (a, b) return a.level > b.level end)
    printf('Mythic plus runs this week:')
    for i, info in ipairs(runs) do
        local name = C_ChallengeMode.GetMapUIInfo(info.mapChallengeModeID)
        printf('% 2d:  %d%s %s',
                i, info.level, info.completed and '+' or '', name)
    end
end

local function IsJunk(bag, slot)
    local _, _, locked, quality, _, _, _, _, noValue = GetContainerItemInfo(bag, slot)
    if quality == Enum.ItemQuality.Poor and not noValue and not locked then
        return true
    end
end

local function IsDowngrade(bag, slot)
    local loc = ItemLocation:CreateFromBagAndSlot(bag, slot)
    if not loc:IsValid() or not C_Item.IsBound(loc) then
        return
    end
    local quality = C_Item.GetItemQuality(loc)
    if not quality or quality > Enum.ItemQuality.Rare then
        return
    end
    local equipSlot = C_Item.GetItemInventoryType(loc)
    if equipSlot < INVSLOT_FIRST_EQUIPPED then return end
    if equipSlot > INVSLOT_LAST_EQUIPPED then return end
    local item = Item:CreateFromBagAndSlot(bag, slot)
    local equipped = Item:CreateFromEquipmentSlot(equipSlot)
    if not equipped.itemLocation:IsValid() then
        return
    end
    if item:GetCurrentItemLevel() < equipped:GetCurrentItemLevel() then
        return true
    end
end

function _LiteLite:SellJunk()
    local numSold = 0
    for bag = 0, 4, 1 do
        local n = GetContainerNumSlots(bag)
        for slot = 1, GetContainerNumSlots(bag) do
            if IsJunk(bag, slot) then
                UseContainerItem(bag, slot)
                numSold = numSold + 1
                if numSold == 12 then return end
            end
        end
    end
end

function _LiteLite:CHAT_MSG_COMBAT_XP_GAIN()
    local rest = GetXPExhaustion()
    if not rest or rest == 0 then return end
    local r, g, b = GetMessageTypeColor('COMBAT_XP_GAIN')
    local pct = 100 * rest / UnitXPMax('player')
    local msg = string.format('Rest remaining: %s (%0.1f%%)', AbbreviateNumbers(rest), pct)
    for i = 1, NUM_CHAT_WINDOWS do
        local f = Chat_GetChatFrame(i)
        if tContains(f.messageTypeList, 'COMBAT_XP_GAIN') then
            f:AddMessage(msg, r, g, b)
        end
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

function _LiteLite:HideMainMenuBarArt()
    MainMenuBarArtFrame.Background:Hide()
    MainMenuBarArtFrame.LeftEndCap:Hide()
    MainMenuBarArtFrame.RightEndCap:Hide()
end


local CastFormat = '#showtooltip\n/cast %s'
local CastAtFormat = '#showtooltip\n/cast [mod:alt][nocombat][@player] %s'

local SignatureAbilities = {
    [1] = 324739,   -- Kyrian, Summon Steward
    [2] = 300728,   -- Venthyr, Door of Shadows
    [3] = 310143,   -- Night Fae, Soulshape
    [4] = 324631,   -- Necrolord, Fleshcraft
}

local CastFormats = {
    [306830] = CastAtFormat,    -- Elysian Decree (Kyrian Demon Hunter)
    [307865] = CastAtFormat,    -- Spear of Bastion (Kyrian Warrior)
    [325216] = CastAtFormat,    -- Bonedust Brew (Necrolord Monk)
}

function _LiteLite:UpdateCovenantMacros()
    local id = C_Covenants.GetActiveCovenantID()
    if ( id or 0 ) == 0 then return end

    local sig = GetSpellInfo(SignatureAbilities[id])
    local sigText = string.format(CastFormat, sig)
    CreateOrEditMacro('Signature', sigText)

    local covenantName = C_Covenants.GetCovenantData(id).name

    -- Scan the spellbook for a spell whose subtext is the covenant name
    -- and which isn't the signature ability. Subtext is load on demand
    -- so we have to use the callback. If there's more than one that matches
    -- I guess they'll just duke it out.

    local i = 1
    while true do
        local name, _, id = GetSpellBookItemName(i, "spell")
        if not name then break end
        if id and not tContains(SignatureAbilities, id) then
            local spell = Spell:CreateFromSpellID(id)
            spell:ContinueOnSpellLoad(function()
                if spell:GetSpellSubtext() ~= covenantName then return end
                local covText = string.format(CastFormats[id] or CastFormat, name)
                CreateOrEditMacro('Covenant', covText)
            end)
        end
        i = i + 1
    end
end

function _LiteLite:COVENANT_CHOSEN()
    self:UpdateCovenantMacros()
end
