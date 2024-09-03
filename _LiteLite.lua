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

local CursorMacroTemplate =
[[#showtooltip {1}
/cast [mod:alt][@cursor] {1}
]]

local PlayerMacroTemplate =
[[#showtooltip {1}
/cast [mod:alt][@player] {1}
]]

local function maybescape(str)
    if str:sub(1,1) == '^' or str:sub(-1) == '$' then
        return str
    else
        -- cut-and-paste I have no idea how this works
        return str:gsub('[%-%.%+%[%]%(%)%$%^%%%?%*]', '%%%1')
    end
end

local SecureButton = CreateFrame('Button', '_LiteLiteSecureButton', nil, 'SecureActionButtonTemplate')
SecureButton:RegisterForClicks('AnyDown', 'AnyUp')

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

local function printfc(fmt, color, ...)
    local msg = string.format(fmt, ...)
    SELECTED_CHAT_FRAME:AddMessage(printTag .. color:WrapTextInColorCode(msg))
end

local function Embiggen(f)
    f:SetScale(1.25)
end

function _LiteLite:BiggerFrames()
    QuestFrame:HookScript('OnShow', Embiggen)
    GossipFrame:HookScript('OnShow', Embiggen)
    ItemTextFrame:HookScript('OnShow', Embiggen)
    TabardFrame:HookScript('OnShow', Embiggen)
    CommunitiesFrame:HookScript('OnShow', Embiggen)
    if EncounterJournal_LoadUI then
        hooksecurefunc('EncounterJournal_LoadUI',
            function ()
                EncounterJournal:HookScript('OnShow', Embiggen)
            end)
    end
    if ChallengeMode_LoadUI then
        hooksecurefunc('ChallengeMode_LoadUI', self.MoveKeystoneFrame)
    end
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
    spell = spell or GameTooltip:GetSpell()
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
            local arg1 = select(4, GetSpecializationInfo(specIndex))
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
    local arg1, arg2, arg3

    -- Zero argument options
    if arg == 'quest-report' or arg == 'qr' then
        local now = GetServerTime()
        self:ScanQuestsCompleted(now)
        self:ReportQuestsCompleted()
        return true
    elseif arg == 'delves' then
        self:ListDelves()
        return true
    elseif arg == 'quest-baseline' or arg == 'qb' then
        local now = GetServerTime()
        self:ScanQuestsCompleted()
        for k in pairs(self.questsCompleted) do
            self.questsCompleted[k] = 0
        end
        return true
    elseif arg == 'spec-config' or arg == 'sc' then
        self:ImportExportSpecConfig()
        return true
    elseif arg == 'chatframe-settings' or arg == 'cs' then
        self:ChatFrameSettings()
        return true
    elseif arg == 'check-elemental-storms' or arg == 'ces' then
        self:CheckElementalStorms()
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
    elseif arg == 'mythic-plus-dungeons' or arg == 'mpd' then
        self:MythicPlusDungeons()
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
    elseif arg == 'dragonridingbar' or arg == 'drb' then
        self:SetupDragonridingBar()
        return true
    elseif arg == 'panda-gems' or arg == 'pg' then
        PandaGem:Show()
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
    elseif arg1 == 'wq-items' or arg1 == 'wqi' then
        self:WorldQuestItems(arg2)
        return true
    elseif arg1 == 'copy-chat' or arg1 == 'cc' then
        self:CopyChat()
        return true
    elseif arg1 == 'catalyst' or arg1 == 'cat' then
        self:CatalystCharges()
        return true
    elseif arg1 == 'guild-news' or arg1 == 'gn' then
        _LiteLiteLoot.minlevel = tonumber(arg2)
        if _LiteLiteLoot:IsShown() then
            _LiteLiteLoot:Update()
        else
            _LiteLiteLoot:Show()
        end
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
        else
            self:ScanMobList()
        end
        return true
    elseif arg1 == 'bind-macro' or arg1 == 'bm' then
        self.db.bindKey = arg2
        self.db.bindMacro = arg3:gsub("\\n", "\n")
        self:SetBindMacro()
        return true
    end

    printf("/ll adventure-upgrade | au")
    printf("/ll announce-mob | am")
    printf("/ll button-macro [|bm] <key> <macrotext>")
    printf("/ll chatframe-settings")
    printf("/ll delves")
    printf("/ll equipset-icon [n [iconid]]")
    printf("/ll equipset-icon auto")
    printf("/ll find-mob substring")
    printf("/ll gkeys text")
    printf("/ll great-vault | gv")
    printf("/ll gvals text")
    printf("/ll guild-news <min-ilevel>")
    printf("/ll mythic-plus-dungeons | mpd")
    printf("/ll mythic-plus-history | mph")
    printf("/ll nameplate-settings")
    printf("/ll quest-baseline")
    printf("/ll quest-report")
    printf("/ll spec-config | sc")
    printf("/ll tooltip-ids")
    printf("/ll cursor-macro [spellname]")
    printf("/ll mouseover-macro [spellname]")
    printf("/ll player-macro [spellname]")
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
    self:RegisterEvent('TRAIT_CONFIG_UPDATED')
    self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
    self:RegisterEvent('LFG_LIST_JOINED_GROUP')
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')

    self:BiggerFrames()
    self:OtherAddonProfiles()
    self:MuteDragonridingMounts()
    self:SellJunkButton()
    self:AutoRepairAll()
    self:RotatingMarker()
    self:StopSpellAutoPush()
    self:CHAT_MSG_COMBAT_XP_GAIN()
    -- self:LargerCUFDispelIcons()
    self:HideProfessionUnspentReminder()
    self:HideActionButtonEffects()
    self:UpdateScanning()
    self:ClearTrackedPerksActivities()
    self:SetBindMacro()
    self:RemixFix()
end

function _LiteLite:RemixFix()
    if PlayerGetTimerunningSeasonID and PlayerGetTimerunningSeasonID() == 1 then
        MailFrame:HookScript('OnShow',
            function () OpenAllMail:SetShown(UnitLevel('player') == 70) end)
    end
end

function _LiteLite:AutoRepairAll()
    MerchantRepairAllButton:HookScript('OnShow', function () RepairAllItems() end)
end

function _LiteLite:SellJunkButton()
    if MerchantSellAllJunkButton then
        MerchantSellAllJunkButton:SetScript('OnClick', MerchantFrame_OnSellAllJunkButtonConfirmed)
        -- MerchantSellAllJunkButton:SetScript('OnClick', self.SellJunk)
    end
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

    text = maybescape(text:lower())

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

    text = maybescape(text:lower())

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
    printf("Scan for mobs:")
    if next(self.db.scanMobNames or {}) then
        for i, name in pairs(self.db.scanMobNames or {}) do
            printf("%d. %s", i, name)
        end
    else
        printf("   None.")
    end
end

function _LiteLite:ScanMobClear()
    self.db.scanMobNames = table.wipe(self.db.scanMobNames or {})
    self:UpdateScanning()
end

function _LiteLite:ScanMobAdd(name)
    self.db.scanMobNames = self.db.scanMobNames or {}
    table.insert(self.db.scanMobNames, name:lower())
    self:UpdateScanning()
end

function _LiteLite:ScanMobDel(name)
    if self.db.scanMobNames then
        local n = tonumber(name)
        if n then
            table.remove(self.db.scanMobNames, n)
        else
            tDeleteItem(self.db.scanMobNames, name:lower())
        end
        self:UpdateScanning()
    end
end

function _LiteLite:UpdateScanning()
    if next(self.db.scanMobNames or {}) then
        self.announcedMobGUID = self.announcedMobGUID or {}
        self:RegisterEvent("NAME_PLATE_UNIT_ADDED")
        if WOW_PROJECT_ID == 1 then
            self:RegisterEvent("VIGNETTES_UPDATED")
            self:RegisterEvent("VIGNETTE_MINIMAP_UPDATED")
        end
    else
        self.announcedMobGUID = table.wipe(self.announcedMobGUID or {})
        self:UnregisterEvent("NAME_PLATE_UNIT_ADDED")
        if WOW_PROJECT_ID == 1 then
            self:UnregisterEvent("VIGNETTES_UPDATED")
            self:UnregisterEvent("VIGNETTE_MINIMAP_UPDATED")
        end
    end
end

function _LiteLite:NAME_PLATE_UNIT_ADDED(unit)
    local name = UnitName(unit):lower()
    local guid = UnitGUID(unit)

    local npcID = select(6, strsplit('-', UnitGUID(unit)))

    for _, n in ipairs(self.db.scanMobNames) do
        n = maybescape(n)
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

function _LiteLite:VignetteMatches(scanMobName, info)
    scanMobName = maybescape(scanMobName):lower()
    local guidType = strsplit('-', info.objectGUID)
    if scanMobName == 'vignette' then
        return true
    elseif guidType and guidType:lower() == scanMobName then
        return true
    elseif info.name and info.name:lower():find(scanMobName) then
        return true
    else
        return false
    end

end

function _LiteLite:VIGNETTE_MINIMAP_UPDATED(id)
    local info = C_VignetteInfo.GetVignetteInfo(id)
    if not info or self.announcedMobGUID[info.objectGUID] then return end

    for _, n in ipairs(self.db.scanMobNames) do
        if self:VignetteMatches(n, info) then
            self.announcedMobGUID[info.objectGUID] = info.name
            local msg = format("Vignette %s found guid %s", info.name, info.objectGUID)
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
            if equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
                printf('  [%s] %s (%d) - %s ', _G[equipLoc], link, itemLevel, mapInfo.name)
            elseif C_Soulbinds.IsItemConduitByItemInfo(link) then
                printf('  [CONDUIT] %s - %s ', link, mapInfo.name)
            end
        end)
end

function _LiteLite:WorldQuestItems(expansion)
    local maps
    if not expansion or expansion == 'tww' then
        maps = { 2274 }
    elseif expansion == 'df' then
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
    WeeklyRewards_ShowUI()
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

local function scoreSort(a, b)
    if a.name == 'Fortified' then
        return true
    else
        return false
    end
end

function _LiteLite:MythicPlusDungeons()
    local output = { }

    for _, mapID in pairs(C_ChallengeMode.GetMapTable()) do
        if next(output) ~= nil then table.insert(output, '') end
        local mapName, _, mapTimer = C_ChallengeMode.GetMapUIInfo(mapID)
        local scores, overallScore = C_MythicPlus.GetSeasonBestAffixScoreInfoForMap(mapID)
        table.insert(output, format('%s : %d', mapName, overallScore))
        if scores then
            table.sort(scores, scoreSort)
            for _, info in ipairs(scores) do
                local stars
                if info.durationSec < mapTimer * 0.6 then
                    stars = '+++'
                elseif info.durationSec < mapTimer * 0.8 then
                    stars = '++'
                elseif info.durationSec < mapTimer then
                    stars = '+'
                else
                    stars= ''
                end
                table.insert(output, format(' - %s : %s%d %d', info.name, stars, info.level, info.score))
            end
        end
    end

    _LiteLiteText.EditBox:SetText(table.concat(output, "\n"))
    _LiteLiteText:Show()
end

local function IsJunk(bag, slot)
    local info = C_Container.GetContainerItemInfo(bag, slot)
    if info and info.quality == Enum.ItemQuality.Poor and not info.hasNoValue and not info.isLocked then
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
            f:AddMessage(printTag .. msg, r, g, b)
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
    if not info then return end
    local name = info.lines[1].leftText
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
    local info = C_CurrencyInfo.GetCurrencyInfo(2533)
    if info then
        printf("%s: %d/%d\n", info.name, info.quantity, info.maxQuantity)
    end
end


-- /click RotatingMarker
function _LiteLite:RotatingMarker()
    local b = CreateFrame('Button', 'RotatingMarker', nil, 'SecureActionButtonTemplate')
    -- https://github.com/Stanzilla/WoWUIBugs/issues/317#issuecomment-1510847497
    b:SetAttribute("pressAndHoldAction", true)
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")

    SecureHandlerWrapScript(b, 'PreClick', b,
        [[
            if IsControlKeyDown() then
                self:SetAttribute("n", 0)
                self:SetAttribute("macrotext", "/cwm 0")
            else
                local n = ( self:GetAttribute("n") or 0 ) % 8 + 1
                self:SetAttribute("n", n)
                self:SetAttribute("macrotext", "/wm [@cursor] " .. n)
            end
        ]])
end

function _LiteLite:StopSpellAutoPush()
    SetCVar("AutoPushSpellToActionBar", 0)
end

local ImportExportMixin = {
    GetLoadoutExportString = function (self, currentSpecID, configID)
        local exportStream = ExportUtil.MakeExportDataStream();
        local configInfo = C_Traits.GetConfigInfo(configID)
        local treeInfo = C_Traits.GetTreeInfo(configID, configInfo.treeIDs[1])
        local treeHash = C_Traits.GetTreeHash(treeInfo.ID);
        local serializationVersion = C_Traits.GetLoadoutSerializationVersion()

        self:WriteLoadoutHeader(exportStream, serializationVersion, currentSpecID, treeHash);
        self:WriteLoadoutContent(exportStream, configID, treeInfo.ID);

        return exportStream:GetExportString();
    end,
    ImportLoadout = function (self, importText, loadoutName)
        printf('Importing loadout: ' .. loadoutName)
        local importStream = ExportUtil.MakeImportDataStream(importText)
        local headerValid, serializationVersion, specID, treeHash = self:ReadLoadoutHeader(importStream)

        if not headerValid then printf('Bad header') return end
        if specID ~= PlayerUtil.GetCurrentSpecID() then printf('Bad spec') return end

        local configID = C_ClassTalents.GetActiveConfigID()
        local configInfo = C_Traits.GetConfigInfo(configID)
        local treeInfo = C_Traits.GetTreeInfo(configID, configInfo.treeIDs[1])

        local loadoutContent = self:ReadLoadoutContent(importStream, treeInfo.ID)
        local loadoutEntryInfo = self:ConvertToImportLoadoutEntryInfo(configID, treeInfo.ID, loadoutContent)

        if not loadoutEntryInfo then printf('Loadout did not convert') return end

        local ok, err = C_ClassTalents.ImportLoadout(configID, loadoutEntryInfo, loadoutName)
        if not ok then
            printf('Loadout import failed: %s: %s', loadoutName, err)
            return
        end
    end,
    GetConfigID = function (self) return C_ClassTalents.GetActiveConfigID() end,
}

local function GetActionMacroInfo(actionID)
    local macroName = GetActionText(actionID)
    return GetMacroInfo(macroName)
end

local function SpecConfigToString()
    local ser = LibStub('AceSerializer-3.0', true)
    if not ser then return "" end
    local map = {}
    for i = 1, 180 do
        if GetActionInfo(i) then
            map[i] = { GetActionInfo(i) }
            if map[i][1] == "macro" then
                local name, icon, text = GetActionMacroInfo(i)
                if name then
                    if text:find('#showtooltip') then icon = 134400 end
                    map[i][3] = name
                    map.macros = map.macros or {}
                    map.macros[name] = { name, icon, text }
                end
            end
        end
    end

    LoadAddOn('Blizzard_PlayerSpells')

    local exporter = CreateFromMixins(ClassTalentImportExportMixin, ImportExportMixin)

    map.loadouts = {}

    local specID = PlayerUtil.GetCurrentSpecID()
    for _,configID in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID)) do
        local info = C_Traits.GetConfigInfo(configID)
        map.loadouts[info.name] = exporter:GetLoadoutExportString(specID, configID)
    end

    return ser:Serialize(map)
end

local function PickupFlyout(id)
   for i = 1, 1000 do
      local t, infoID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL)
      if t == "FLYOUT" and infoID == id then
         C_Spell.PickupSpellBookItem(i, BOOKTYPE_SPELL)
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
      PickupFlyout(action[2])
      PlaceAction(i)
   else
      print('hmm', unpack(action))
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
    local ser = LibStub('AceSerializer-3.0', true)
    if not ser then return end

    local isValid, map = ser:Deserialize(text)
    if not isValid then return end

    printf('Loading macros')
    if map.macros then
        for name, info in pairs(map.macros) do
            printf(' - ' .. name)
            SetMacro(info)
        end
    end

    printf('Setting action bar actions')
    for i = 1, 180 do
        SetAction(i, map[i])
    end

    printf('Setting up loadouts')
    local currentConfigsByName = {}
    local specID = PlayerUtil.GetCurrentSpecID()
    for _,configID in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID)) do
        local info = C_Traits.GetConfigInfo(configID)
        currentConfigsByName[info.name] = configID
    end

    local importer = CreateFromMixins(ClassTalentImportExportMixin, ImportExportMixin)
    for name, data in pairs(map.loadouts or {}) do
        if currentConfigsByName[name] then
            printf('Deleting existing loadout: ' .. name)
            C_ClassTalents.DeleteConfig(currentConfigsByName[name])
        end
        importer:ImportLoadout(data, name)
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
        printf('Change equipment set ' .. loadoutSetName)
        C_EquipmentSet.UseEquipmentSet(loadoutSetID)
        return
    end

    local specIndex = GetSpecialization()
    if not specIndex then return end

    local specSetID = C_EquipmentSet.GetEquipmentSetForSpec(specIndex)
    if specSetID then
        local specSetName = C_EquipmentSet.GetEquipmentSetInfo(specSetID)
        printf('Change equipment set ' .. specSetName)
        C_EquipmentSet.UseEquipmentSet(specSetID)
        return
    end
end

function _LiteLite:UpdateEquipmentSet()
    self.equipmentSetLoadoutDirty = true
    C_Timer.After(0, UpdateEquipmentSetForLoadout)
end

function _LiteLite:TRAIT_CONFIG_UPDATED(id, ...)
    if id == C_ClassTalents.GetActiveConfigID() then
        self:UpdateEquipmentSet()
    end
end

function _LiteLite:ACTIVE_TALENT_GROUP_CHANGED(...)
    self:UpdateEquipmentSet()
end

function _LiteLite:LargerCUFDispelIcons()
    hooksecurefunc("CompactUnitFrame_UpdateAuras",
        function (frame)
            if not frame:IsForbidden() and frame:GetName() then
                for _,f in ipairs(frame.dispelDebuffFrames) do
                    f:SetSize(24, 24)
                end
            end
        end)
end

function _LiteLite:HideProfessionUnspentReminder()
    hooksecurefunc('MainMenuMicroButton_ShowAlert',
        function (microButton, text, tutorialIndex, cvarBitfield)
            if text == PROFESSIONS_UNSPENT_SPEC_POINTS_REMINDER then
                -- print(microButton:GetName(), text, 'triggered')
                MainMenuMicroButton_HideAlert(microButton)
                MicroButtonPulseStop(microButton)
            end
        end)
end


function _LiteLite:HideActionButtonEffects()
    if WOW_PROJECT_ID ~= 1 then return end

    -- Stop the castbar inside the actionbuttons
    local events = {
        "UNIT_SPELLCAST_INTERRUPTED",
        "UNIT_SPELLCAST_SUCCEEDED",
        "UNIT_SPELLCAST_FAILED",
        "UNIT_SPELLCAST_START",
        "UNIT_SPELLCAST_STOP",
        "UNIT_SPELLCAST_CHANNEL_START",
        "UNIT_SPELLCAST_CHANNEL_STOP",
        "UNIT_SPELLCAST_RETICLE_TARGET",
        "UNIT_SPELLCAST_RETICLE_CLEAR",
        "UNIT_SPELLCAST_EMPOWER_START",
        "UNIT_SPELLCAST_EMPOWER_STOP",
    }

    for _,e in ipairs(events) do
        ActionBarActionEventsFrame:UnregisterEvent(e)
    end

    -- Stop the SpellActivationAlert start animation
    hooksecurefunc('ActionButton_ShowOverlayGlow',
        function (b)
            b.SpellActivationAlert.ProcStartAnim:Stop()
            b.SpellActivationAlert.ProcStartFlipbook:SetAlpha(0)
            b.SpellActivationAlert.ProcLoop:Play()
        end)
end

_LiteLiteLootMixin = {}

local function InitLootButton(button, data)
    button.data = data
    button.Date:SetText(data.date)
    button.Player:SetText(data.player)
    button.Level:SetText(data.level)
    button.Type:SetText(data.type)
    button.Item:SetText(data.item)
end

function _LiteLiteLootMixin:Update()
    local dataProvider = CreateDataProvider(self:GetData())
    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

function _LiteLiteLootMixin:OnLoad()
    self:SetTitle(GUILD_NEWS)
    ButtonFrameTemplate_HidePortrait(self)
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("_LiteLiteLootEntryTemplate", InitLootButton)
    view:SetPadding(2,2,2,2,5);
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view);
    table.insert(UISpecialFrames, self:GetName())

    self.guild = {}
    local realm = GetRealmName()
    C_GuildInfo.GuildRoster()
    for i = 1, GetNumGuildMembers() do
        local name, _, _, _, _, _, _, _, _, _, class = GetGuildRosterInfo(i)
        name = name:gsub("-"..realm, '')
        self.guild[name] = C_ClassColor.GetClassColor(class):WrapTextInColorCode(name)
    end

end

function _LiteLiteLootMixin:OnShow()
    self:RegisterEvent("GUILD_NEWS_UPDATE")
    QueryGuildNews()
end

function _LiteLiteLootMixin:OnHide()
    self:UnregisterAllEvents()
end

function _LiteLiteLootMixin:OnEvent()
    self:Update()
end

local DATE_FMT = "%.3s %d/%d"

function _LiteLiteLootMixin:GetData()
    local data = {}
    for i = 1, GetNumGuildNews() do
        local info = C_GuildInfo.GetGuildNewsInfo(i)
        if info and info.newsType == NEWS_ITEM_LOOTED then
            local level = GetDetailedItemLevelInfo(info.whatText)
            local invType, subType, _, equipSlot = select(6, GetItemInfo(info.whatText))
            if equipSlot ~= '' and level and level >= ( self.minlevel or 0 ) then
                local date = format(DATE_FMT, CALENDAR_WEEKDAY_NAMES[info.weekday + 1], info.day + 1, info.month + 1);
                local entry = {
                    date    = date,
                    player  = self.guild[info.whoText] or info.whoText,
                    level   = level,
                    type    = _G[equipSlot],
                    item    = info.whatText
                }
                table.insert(data, entry)
            end
        end
    end
    return data
end

function _LiteLite:LFG_LIST_JOINED_GROUP(id, kstringGroupName)
    local searchResultInfo = C_LFGList.GetSearchResultInfo(id)
    local _, status, _, _, role = C_LFGList.GetApplicationInfo(id)
    local activityName = C_LFGList.GetActivityFullName(searchResultInfo.activityID, nil, searchResultInfo.isWarMode);

    printf(format('Joined %s "%s" as %s', activityName, kstringGroupName, _G[role]))

    -- kstring is gone before the GROUP_JOINED so can't use it

    local chatMsg = format('Joined %s as %s', activityName, _G[role])
    local function sendmsg()
        SendChatMessage(chatMsg, IsInRaid() and "RAID" or "PARTY")
    end
    if IsInGroup() then
        sendmsg()
    else
        EventUtil.RegisterOnceFrameEventAndCallback("GROUP_JOINED", sendmsg)
    end
end

function _LiteLite:PLAYER_INTERACTION_MANAGER_FRAME_SHOW(id)
    if id == Enum.PlayerInteractionType.ItemUpgrade then
        ShowUIPanel(CharacterFrame)
    end
end

local DragonridingActions = {
    [121] = 372608,
    [122] = 372610,
    [123] = 361584,
    [124] = 403092,
    [125] = 425782,
    [126] = 374990,
}

function _LiteLite:SetupDragonridingBar()
    for actionID, spellID in pairs(DragonridingActions) do
        local aType, aID, aSubType = GetActionInfo(actionID)
        if aType ~= 'spell' or aID ~= spellID then
            C_Spell.PickupSpell(spellID)
            PlaceAction(actionID)
            ClearCursor()
        end
    end
end

local StormMapAchievements =  {
    [2022] = {
        id = 16468,
        ['ElementalStorm-Lesser-Air'] = 1,
        ['ElementalStorm-Lesser-Earth'] = 2,
        ['ElementalStorm-Lesser-Fire'] = 3,
        ['ElementalStorm-Lesser-Water'] = 4,
    },
    [2023] = {
        id = 16476,
        ['ElementalStorm-Lesser-Air'] = 1,
        ['ElementalStorm-Lesser-Earth'] = 2,
        ['ElementalStorm-Lesser-Fire'] = 3,
        ['ElementalStorm-Lesser-Water'] = 4,
    },
    [2024] = {
        id = 16484,
        ['ElementalStorm-Lesser-Air'] = 1,
        ['ElementalStorm-Lesser-Earth'] = 2,
        ['ElementalStorm-Lesser-Fire'] = 3,
        ['ElementalStorm-Lesser-Water'] = 4,
    },
    [2025] = {
        id = 16489,
        ['ElementalStorm-Lesser-Air'] = 1,
        ['ElementalStorm-Lesser-Earth'] = 2,
        ['ElementalStorm-Lesser-Fire'] = 3,
        ['ElementalStorm-Lesser-Water'] = 4,
    },
}


local CompletedColors = {
    [true] = GREEN_FONT_COLOR,
    [false] = RED_FONT_COLOR,
}

function _LiteLite:CheckElementalStorms()
    local found = false
    for uiMapID, achData in pairs(StormMapAchievements) do
        local mapName = C_Map.GetMapInfo(uiMapID).name
        local poiIDs = C_AreaPoiInfo.GetAreaPOIForMap(uiMapID)
        for _, poiID in ipairs(poiIDs) do
            local info = C_AreaPoiInfo.GetAreaPOIInfo(uiMapID, poiID)
            if strfind(info.description, 'Cobalt Assembly') then
                info.isPrimaryMapForPOI = ( uiMapID == 2024 )
            end
            if info.isPrimaryMapForPOI and info.name == "Elemental Storm" then
                local critID = achData[info.atlasName]
                local name, _, completed = GetAchievementCriteriaInfo(achData.id, critID)
                local c = CompletedColors[completed]
                printfc('%s : %s (%s)', c, mapName, name, completed and "DONE" or "MISSING")
                printf(info.description)
                found = true
            end
        end
    end
    if not found then
        printf('No storm active')
    end
end

function _LiteLite:ClearTrackedPerksActivities()
    if not C_PerksActivities then return end
    local ids = C_PerksActivities.GetTrackedPerksActivities().trackedIDs
    for _, id in ipairs(ids) do
       C_PerksActivities.RemoveTrackedPerksActivity(id)
    end
end

function _LiteLite:SetBindMacro()
    if self.db.bindKey and self.db.bindMacro then
        SecureButton:SetAttribute('type', 'macro')
        SecureButton:SetAttribute('macrotext', self.db.bindMacro)
        SetOverrideBindingClick(SecureButton, true, self.db.bindKey, SecureButton:GetName())
    end
end

local delveMaps = { 2248, 2214, 2215, 2255 }

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

function _LiteLite:ListDelves()
    for _, mapID in ipairs(delveMaps) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        local delveList = C_AreaPoiInfo.GetDelvesForMap(mapID)
        for _, poiID in ipairs(delveList) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
            if poiInfo.isPrimaryMapForPOI then
                printf("%s: %s %s", mapInfo.name, poiInfo.name, tostring(poiInfo.shouldGlow))
            end
        end
    end
end
