--[[----------------------------------------------------------------------------
--
-- _LiteLite
--
----------------------------------------------------------------------------]]--

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

local ScanTooltip = CreateFrame("GameTooltip", "_LiteLiteScanTooltip", nil, "GameTooltipTemplate")
do
    ScanTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

    ScanTooltip.left = {}
    ScanTooltip.right = {}

    for i = 1, 5 do
        local L = ScanTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        local R = ScanTooltip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        ScanTooltip.left[i] = L
        ScanTooltip.right[i] = R
        ScanTooltip:AddFontStrings(L, R)
    end
end

_LiteLite = CreateFrame('Frame')
_LiteLite:SetScript('OnEvent',
        function (self, e, ...)
            if self[e] then self[e](self, ...) end
        end)
_LiteLite:RegisterEvent('PLAYER_LOGIN')

local printTag = ORANGE_FONT_COLOR:WrapTextInColorCode("LiteLite: ")

local function printf(fmt, ...)
    local msg = string.format(fmt, ...)
    SELECTED_CHAT_FRAME:AddMessage(printTag .. msg)
end

local function Embiggen(f)
    f:SetScale(1.25)
end

function _LiteLite:BiggerFrames()
    QuestFrame:HookScript('OnShow', Embiggen)
    GossipFrame:HookScript('OnShow', Embiggen)
    ItemTextFrame:HookScript('OnShow', Embiggen)
    hooksecurefunc('Communities_LoadUI',
        function ()
            CommunitiesFrame:HookScript('OnShow', Embiggen)
        end)
    hooksecurefunc('EncounterJournal_LoadUI',
        function ()
            EncounterJournal:HookScript('OnShow', Embiggen)
        end)
    hooksecurefunc('ChallengeMode_LoadUI', self.MoveKeystoneFrame)
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

--[[
    if spellID == 115310 then
        -- Revival (Mistweaver Monk)
        msg = format('%s cast - %s', GetSpellLink(spellName), self.playerName)
        SendChatMessage(msg, 'SAY')
    end
]]
end

function _LiteLite:NameplateSettings()
    SetCVar('nameplateShowFriendlyNPCs', 1)
    SetCVar('nameplateShowFriends', 1)
    SetCVar('nameplateShowEnemies', 1)
    SetCVar('nameplateShowAll', 1)
    SetCVar('nameplateMaxDistance', 100)
end

function _LiteLite:ChatFrameSettings()
    -- Edit mode?
end

local function GetGameTooltipIcon()
    local _, id = GameTooltip:GetSpell()
    if id then
        return select(3, GetSpellInfo(id))
    end
    _,  id = GameTooltip:GetItem()
    if id then
        return select(10, GetItemInfo(id))
    end
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

    arg1 = tonumber(arg1) or GetGameTooltipIcon()

    if arg1 == nil then
        return
    end

    printf('Setting equipset icon for %s (%d) to %d', name, n, arg1)
    C_EquipmentSet.ModifyEquipmentSet(n, name, arg1)
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
    elseif arg == 'actionbuttons' or arg == 'ab' then
        self:ImportExportActionButtons()
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
    elseif arg == 'skips' then
        self:PrintSkips()
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
    elseif arg1 == 'catalyst' or arg1 == 'cat' then
        self:CatalystCharges()
        return true
    end

    -- Two argument options
    local arg1, arg2, arg3 = string.split(' ', arg, 3)
    if arg1 == 'equipset-icon' or arg1 == 'esi' then
        if arg2 == 'auto' then
            self:AutoEquipsetIcons()
        else
            self:SetEquipsetIcon(arg2, arg3)
        end
        return true
    end

    printf("/ll adventure-upgrade | au")
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
    self:RegisterEvent('CHAT_MSG_MONSTER_EMOTE')
    self:RegisterEvent('ENCOUNTER_START')
    self:RegisterEvent('ENCOUNTER_END')
    self:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
    self:RegisterEvent('COVENANT_CHOSEN')

    self:BiggerFrames()
    self:OtherAddonProfiles()
    self:MuteDragonridingMounts()
    self:SellJunkButton()
    self:AutoRepairAll()
    self:RotatingMarker()
    self:StopSpellAutoPush()
end

function _LiteLite:AutoRepairAll()
    local function RAI() RepairAllItems() end
    MerchantRepairAllButton:HookScript('OnShow', RAI)
end

function _LiteLite:SellJunkButton()

    local b = CreateFrame('Button', nil, MerchantRepairItemButton)
    b:SetPushedTexture('Interface\\Buttons\\UI-Quickslot-Depress')
    b:SetHighlightTexture('Interface\\Buttons\\ButtonHilight-Square')

    b.Icon = b:CreateTexture()
    b.Icon:SetAtlas("bags-junkcoin")
    b.Icon:SetAllPoints()

    b:SetScript('OnClick', function () self:SellJunk() end)
    b:SetScript('OnEnter',
        function (self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT");
            GameTooltip:SetText('Sell junk')
        end)
    b:SetScript('OnLeave', GameTooltip_Hide)

    b:Show()
    b:SetAllPoints()

    self.SellJunkButton = b
end

function _LiteLite:CHAT_MSG_MONSTER_YELL(msg, name)
    if C_Map.GetBestMapForUnit('player') == 534 then -- Tanaan Jungle
        PlaySound(11466)
        self:FlashScreen(10)
        msg = ORANGE_FONT_COLOR:WrapTextInColorCode(msg)
        UIErrorsFrame:AddMessage(msg, 0.1, 1.0, 0.1)
    end
end

function _LiteLite:CHAT_MSG_MONSTER_EMOTE(msg, name)
    if C_Map.GetBestMapForUnit('player') == 1970 then -- Zereth Mortis
        msg = ORANGE_FONT_COLOR:WrapTextInColorCode(msg)
        UIErrorsFrame:AddMessage(string.format(msg, name))
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
            if unit then
                local _, _, _, _, _, id = strsplit('-', UnitGUID(unit))
                if id then
                    ttFrame:AddDoubleLine("UnitID", id)
                end
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

local function PrintEquipmentQuestRewards(info)
    local i, rewardType = QuestUtils_GetBestQualityItemRewardIndex(info.questId)
    if not i or i == 0 then return end
    local itemID, itemLevel = select(6, GetQuestLogRewardInfo(i, info.questId))
    if not itemID then return end

    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(
        function ()
            local mapInfo = C_Map.GetMapInfo(info.mapID)
            ScanTooltip:SetQuestLogItem(rewardType, i, info.questId, true) 
            local name, link = ScanTooltip:GetItem()
            local equipLoc = select(9, GetItemInfo(itemID))
            if equipLoc ~= "" then
                printf('  [%s] %s (%d) - %s ', _G[equipLoc], link, itemLevel, mapInfo.name)
            elseif C_Soulbinds.IsItemConduitByItemInfo(link) then
                printf('  [CONDUIT] %s - %s ', link, mapInfo.name)
            end
        end)
end

function _LiteLite:WorldQuestItems(expansion)
    local maps
    if not expansion or expansion == 'df' then
        maps = { 1978 }
    elseif expansion == 'sl' then
        maps = { 1550 }
    elseif expansion == 'bfa' then
        maps = { 875, 876 }
    else
        return
    end

    local mapQuests = { }
    for _, parentMapID in ipairs(maps) do
        local childInfo = C_Map.GetMapChildrenInfo(parentMapID)
        for _,mapInfo in pairs(childInfo or {}) do
            if mapInfo.mapType == Enum.UIMapType.Zone then
                for _, questInfo in ipairs(C_TaskQuest.GetQuestsForPlayerByMapID(mapInfo.mapID)) do
                    if C_QuestLog.IsWorldQuest(questInfo.questId) then
                        mapQuests[questInfo.questId] = questInfo
                        C_TaskQuest.RequestPreloadRewardData(questInfo.questId)
                    end
                end
            end
        end
    end

    C_Timer.NewTicker(0.5,
        function (self)
            local allKnown = true
            for _, info in pairs(mapQuests) do
                if not HaveQuestRewardData(info.questId) then allKnown = false break end
            end
            if allKnown then
                printf("World quest item rewards:")
                for _, info in pairs(mapQuests) do
                    PrintEquipmentQuestRewards(info)
                end
                self:Cancel()
            end
        end, 10)
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
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue and not info.isLocked then
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
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            if IsJunk(bag, slot) then
                C_Container.UseContainerItem(bag, slot)
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

local function PrintIfCompletedQuest(questID)
    local info = C_TooltipInfo.GetHyperlink("quest:"..questID)
    local name = info.lines[1].args[2].stringVal
    if name then
        local complete = C_QuestLog.IsQuestFlaggedCompleted(questID)
        local color = complete and GREEN_FONT_COLOR or RED_FONT_COLOR
        printf( "%s: %s", name, color:WrapTextInColorCode(tostring(complete)))
    end
end

function _LiteLite:PrintSkips(what)
    PrintIfCompletedQuest(45383)        -- Nighthold
end


function _LiteLite:SetAceProfile(svName, profileName)
    if not svName or not _G[svName] then return end

    local acedb = LibStub('AceDB-3.0', true)
    if not acedb then return end

    local PlayerProfileName = string.format('%s - %s', UnitFullName('player'))
    local _, ClassProfileName = UnitClass('player')
    local RealmProfileName = GetRealmName()

    for db in pairs(acedb.db_registry) do
        if db.sv == _G[svName] then
            if db:GetCurrentProfile() ~= profileName then
                printf('Set %s profile %s', svName, profileName)
                db:SetProfile(profileName)
            end
            if db.profiles[PlayerProfileName] then
                printf('Delete %s profile %s', svName, PlayerProfileName)
                db:DeleteProfile(PlayerProfileName)
            end
            if db.profiles[ClassProfileName] then
                printf('Delete %s profile %s', svName, ClassProfileName)
                db:DeleteProfile(ClassProfileName)
            end
            if db.profiles[RealmProfileName] then
                printf('Delete %s profile %s', svName, RealmProfileName)
                db:DeleteProfile(RealmProfileName)
            end
        end
    end
end

function _LiteLite:OtherAddonProfiles()
    self:SetAceProfile('HandyNotesDB', 'Default')
    self:SetAceProfile('EnhancedRaidFramesDB', 'Default')
end

function _LiteLite:MuteDragonridingMounts()
    -- These came from a weakaura
    MuteSoundFile(4634942)
    MuteSoundFile(4634944)
    MuteSoundFile(4634946)
    MuteSoundFile(4634910)
    MuteSoundFile(4634908)
    MuteSoundFile(4634912)
    MuteSoundFile(4634914)
    MuteSoundFile(4634916)
    MuteSoundFile(4633292)
    MuteSoundFile(4633294)
    MuteSoundFile(4633296)
    MuteSoundFile(4633298)
    MuteSoundFile(4633300)
    MuteSoundFile(4633392)
    MuteSoundFile(4674593)
    MuteSoundFile(4674595)
    MuteSoundFile(4674599)
    MuteSoundFile(4543973)
    MuteSoundFile(4543973)
    MuteSoundFile(4543977)
    MuteSoundFile(4543979)
    MuteSoundFile(4627086)
    MuteSoundFile(4627088)
    MuteSoundFile(4627090)
    MuteSoundFile(4627092)
    MuteSoundFile(4634924)
    MuteSoundFile(4634926)
    MuteSoundFile(4634928)
    MuteSoundFile(4634930)
    MuteSoundFile(4634932)
    MuteSoundFile(4550997)
    MuteSoundFile(4550999)
    MuteSoundFile(4551001)
    MuteSoundFile(4551003)
    MuteSoundFile(4551005)
    MuteSoundFile(4551007)
    MuteSoundFile(4551009)
    MuteSoundFile(4551011)
    MuteSoundFile(4551013)
    MuteSoundFile(4551015)
    MuteSoundFile(4551017)
    MuteSoundFile(1489053)
    MuteSoundFile(1489050)
    MuteSoundFile(540221)
    MuteSoundFile(540218)
    MuteSoundFile(540213)
    MuteSoundFile(540119)
    MuteSoundFile(540182)
    MuteSoundFile(540243)
    MuteSoundFile(540188)
    MuteSoundFile(540108)
    MuteSoundFile(540211)
    MuteSoundFile(540197)
    MuteSoundFile(1489050)
    MuteSoundFile(1489051)
    MuteSoundFile(1489052)
    MuteSoundFile(1489053)
    MuteSoundFile(12694571)
    MuteSoundFile(12694572)
    MuteSoundFile(12694573)
    MuteSoundFile(597932)
    MuteSoundFile(4633302)
    MuteSoundFile(1563058)
    MuteSoundFile(803549)
    MuteSoundFile(803545)
    MuteSoundFile(803547)
    MuteSoundFile(803551)
    MuteSoundFile(1321216)
    MuteSoundFile(1321217)
    MuteSoundFile(1321218)
    MuteSoundFile(1321219)
    MuteSoundFile(1321220)
    MuteSoundFile(4634009)
    MuteSoundFile(4634011)
    MuteSoundFile(4634013)
    MuteSoundFile(4634015)
    MuteSoundFile(4634017)
    MuteSoundFile(4634019)
    MuteSoundFile(4634021)
    MuteSoundFile(547436)
    MuteSoundFile(4633370)
    MuteSoundFile(4633372)
    MuteSoundFile(4633374)
    MuteSoundFile(4633376)
    MuteSoundFile(4633378)
    MuteSoundFile(4633382)
    MuteSoundFile(4337227)
    MuteSoundFile(4633304)
    MuteSoundFile(4633306)
    MuteSoundFile(4633308)
    MuteSoundFile(4633310)
    MuteSoundFile(4633312)
    MuteSoundFile(4633314)
    MuteSoundFile(4633338)
    MuteSoundFile(4633340)
    MuteSoundFile(4633342)
    MuteSoundFile(4633344)
    MuteSoundFile(4633346)
    MuteSoundFile(4633348)
    MuteSoundFile(4633350)
    MuteSoundFile(4633354)
    MuteSoundFile(4633356)
    MuteSoundFile(4634009)
    MuteSoundFile(4634011)
    MuteSoundFile(4634013)
    MuteSoundFile(4634015)
    MuteSoundFile(4634017)
    MuteSoundFile(4634019)
    MuteSoundFile(4634021)
    MuteSoundFile(547436)
    MuteSoundFile(4633370)
    MuteSoundFile(4633372)
    MuteSoundFile(4633374)
    MuteSoundFile(4633376)
    MuteSoundFile(4633378)
    MuteSoundFile(4633382)
    MuteSoundFile(4337227)
    MuteSoundFile(4633304)
    MuteSoundFile(4633306)
    MuteSoundFile(4633308)
    MuteSoundFile(4633310)
    MuteSoundFile(4633312)
    MuteSoundFile(4633314)
    MuteSoundFile(4633338)
    MuteSoundFile(4633340)
    MuteSoundFile(4633342)
    MuteSoundFile(4633344)
    MuteSoundFile(4633346)
    MuteSoundFile(4633348)
    MuteSoundFile(4633350)
    MuteSoundFile(4633354)
    MuteSoundFile(4633356)
    MuteSoundFile(547714)
    MuteSoundFile(547715)
    MuteSoundFile(547716)
    MuteSoundFile(4663454)
    MuteSoundFile(4663456)
    MuteSoundFile(4663458)
    MuteSoundFile(4663460)
    MuteSoundFile(4663462)
    MuteSoundFile(4663464)
    MuteSoundFile(4663466)
    MuteSoundFile(1467222)
    MuteSoundFile(598016)
    MuteSoundFile(597968)
    MuteSoundFile(597998)
    MuteSoundFile(597968)
    MuteSoundFile(598004)
    MuteSoundFile(598010)
    MuteSoundFile(597989)
    MuteSoundFile(597932)
    MuteSoundFile(598028)
    MuteSoundFile(597986)
    MuteSoundFile(3014246)
    MuteSoundFile(3014247)
    MuteSoundFile(1563054)
    MuteSoundFile(1563055)
end

-- Damn thing is underneath the action bars

function _LiteLite.MoveKeystoneFrame()
    if ChallengesKeystoneFrame then
        ChallengesKeystoneFrame:ClearAllPoints()
        ChallengesKeystoneFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
    end
end

function _LiteLite:CatalystCharges()
    local info = C_CurrencyInfo.GetCurrencyInfo(2167)
    if info then
        printf("%s: %d/%d\n", info.name, info.quantity, info.maxQuantity)
    end
end


-- /click RotatingMarker LeftButton 1
function _LiteLite:RotatingMarker()
    local b = CreateFrame('Button', 'RotatingMarker', nil, 'SecureActionButtonTemplate')
    b:SetAttribute("type", "macro")
    SecureHandlerWrapScript(b, 'PreClick', b,
        [[
            if IsControlKeyDown() then
                self:SetAttribute("n", 0)
                self:SetAttribute("macrotext", "/cwm 0")
            else
                local n = ( self:GetAttribute("n") or 0 ) % 8 + 1
                self:SetAttribute("n", n)
                self:SetAttribute("macrotext", "/wm [@cursor] " .. n)
                -- RotatingMarkerN = (RotatingMarkerN or 0) % 8 + 1
                -- self:SetAttribute("macrotext", "/wm [@cursor] " .. RotatingMarkerN)
            end
        ]])
end

function _LiteLite:StopSpellAutoPush()
    SetCVar("AutoPushSpellToActionBar", 0)
end

local function ActionButtonsToString()
    local ser = LibStub('AceSerializer-3.0', true)
    if not ser then return "" end

    local map = {}
    for i = 1, 180 do
        if GetActionInfo(i) then
            map[i] = { GetActionInfo(i) }
            if map[i][1] == "macro" then
                map[i][3] = GetMacroInfo(map[i][2])
            end
        end
    end

    return ser:Serialize(map)
end

local function PickupFlyout(id)
   for i = 1, 1000 do
      local t, infoID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
      if t == "FLYOUT" and infoID == id then
         PickupSpellBookItem(i, BOOKTYPE_SPELL)
         return
      end
   end
end

local function SetAction(i, action)
   if not action or not action[1] then
      PickupAction(i)
   elseif action[1] == "spell" then
      PickupSpell(action[2])
      PlaceAction(i)
   elseif action[1] == "macro" then
      PickupMacro(action[3])
      PlaceAction(i)
   elseif action[1] == "item" then
      PickupItem(action[2])
      PlaceAction(i)
   elseif action[1] == "flyout" then
      PickupFlyout(action[2])
      PlaceAction(i)
   else
      print('hmm', unpack(action))
   end
   ClearCursor()
end

local function ActionButtonsFromString(text)
    local ser = LibStub('AceSerializer-3.0', true)
    if not ser then return end

    local isValid, map = ser:Deserialize(text)
    if not isValid then return end

    for i = 1, 180 do
        SetAction(i, map[i])
    end

end

function _LiteLite:ImportExportActionButtons()
    _LiteLiteText.ApplyFunc = 
        function ()
            local text = _LiteLiteText.EditBox:GetText()
            ActionButtonsFromString(text)
        end
    _LiteLiteText.EditBox:SetText(ActionButtonsToString())
    _LiteLiteText:Show()
end
