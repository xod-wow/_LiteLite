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

function _LiteLite:SmallerPetHitText()
    PetHitIndicator:SetScale(0.5)
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

function _LiteLite:SetEditModeLayout(layout)
    if tonumber(layout) then
        C_EditMode.SetActiveLayout(tonumber(layout))
        return
    end

    if layout == nil then
        local w, h = GetPhysicalScreenSize()
        layout = tostring(w) .. 'x' .. tostring(h)
    end

    local layoutData = C_EditMode.GetLayouts()

    for i, layoutInfo in ipairs(layoutData.layouts) do
        if layoutInfo.layoutName == layout then
            C_EditMode.SetActiveLayout(i+2)
            return
        end
    end
end


function _LiteLite:SpellCastAnnounce(spellID, spellName)
    if UnitIsPVP('player') or IsActiveBattlefieldArena() then
        return
    end

    if spellID == 1231411 then  -- Recuperate
        SendChatMessage('Re-cu-per-ate.', 'SAY')
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
        return C_Spell.GetSpellTexture(id)
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
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local specIndex = C_EquipmentSet.GetEquipmentSetAssignedSpec(n)
        if specIndex then
            local textureID = select(4, GetSpecializationInfo(specIndex))
            self:SetEquipsetIcon(setID, textureID)
        end
    end
end

function _LiteLite:SetEquipsetIcon(n, textureID)
    local setID = tonumber(n)
                    or C_EquipmentSet.GetEquipmentSetID(n)
                    or PaperDollFrame.EquipmentManagerPane.selectedSetID

    if setID == nil then
        return
    end

    local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
    if name == nil then
        return
    end

    textureID = tonumber(textureID) or GetGameTooltipIcon()

    if textureID == nil then
        return
    end

    printf('Setting equipset icon for %s (%d) to %d', name, setID, textureID)
    C_EquipmentSet.ModifyEquipmentSet(n, name, textureID)
end

function _LiteLite:SlashCommand(arg)
    local arg1, arg2, arg3

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
    elseif arg == 'restored-coffer-keys' or arg == 'rck' then
        self:RestoredCofferKeys()
        return true
    elseif arg == 'auto-invite-myself' or arg == 'aim' then
        self:AutoInviteMyself()
        return true
    elseif arg == 'decode' then
        self:Decode()
        return true
    elseif arg == 'world-quest' or arg == 'wq' then
        self:WorldQuestList()
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
    elseif arg1 == 'catalyst' or arg1 == 'cat' then
        self:CatalystCharges()
        return true
    elseif arg1 == 'guild-news' or arg1 == 'gn' then
        local iLevel = tonumber(arg2)
        self:GuildNews(iLevel)
        return true
    elseif arg1 == 'delves' then
        self:ListDelves(arg2)
        return true
    elseif arg1 == 'auto-waypoint' or arg1 == 'aw' then
        self.db.autoScanWaypoint = StringToBoolean(arg2 or 0) or nil
        return true
    elseif arg1 == 'layout' then
        self:SetEditModeLayout(arg2)
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
            self:ShowScanWaypoints()
            TomTom:SetClosestWaypoint()
        end
        self:ScanMobList()
        return true
    elseif arg1 == 'bind-macro' or arg1 == 'bm' then
        self.db.bindKey = arg2
        self.db.bindMacro = arg3:gsub("\\n", "\n")
        self:SetBindMacro()
        return true
    end

    printf("/ll announce-mob | am")
    printf("/ll auto-waypoint | aw")
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
    printf("/ll world-quest [expansion] [-i|-r|-l]")
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
    self.playerGUID = UnitGUID('player')

    self.questsCompleted = {}
    -- self:ScanQuestsCompleted()

    self:SetupSlashCommand()
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    self:RegisterEvent('CHAT_MSG_MONSTER_YELL')
    self:RegisterEvent('CHAT_MSG_MONSTER_EMOTE')
    self:RegisterEvent('CHAT_MSG_LOOT')
    self:RegisterEvent('ENCOUNTER_START')
    self:RegisterEvent('ENCOUNTER_END')
    self:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
    self:RegisterEvent('CHAT_MSG_COMBAT_FACTION_CHANGE')
    self:RegisterEvent('TRAIT_CONFIG_UPDATED')
    self:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
    self:RegisterEvent('PLAYER_REGEN_ENABLED')
    self:RegisterEvent('LFG_LIST_JOINED_GROUP')
    self:RegisterEvent('PLAYER_INTERACTION_MANAGER_FRAME_SHOW')
    self:RegisterEvent('PLAYER_LOGOUT')
    self:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')

    self:PageMultiBarBottomRight()

    self:BiggerFrames()
    self:SmallerPetHitText()
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
    self:SetupHearthstoneButton()
    self:CheckCitrines()
    self:AcceptMyInvites()

    _LiteLiteTable:SetAutoWidth(true)
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

function _LiteLite:CHAT_MSG_LOOT(...)
    if select(8, GetInstanceInfo()) == 2769 then
        local msg = ...
        if msg and msg:find('Prototype A.S.M.R.', nil, true) then
            PlaySound(11466)
            self:FlashScreen(10)
            msg = ORANGE_FONT_COLOR:WrapTextInColorCode(msg)
            UIErrorsFrame:AddMessage(msg)
            printf(msg)
        end
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

    printf("Searching global values for %s", tostring(text))

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
    local name = UnitName(unit):lower()
    local guid = UnitGUID(unit)

    local npcID = select(6, strsplit('-', UnitGUID(unit)))

    for _, n in ipairs(self.db.scanMobNames) do
        if ( name and name:find(n, nil, true) ) or
           ( npcID and tonumber(n) == tonumber(npcID) ) then
            if not self.scannedGUID[guid] then
                self.scannedGUID[guid] = { name = name }
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

local badAtlasNames = {
    ["VignetteLoot"]        = true,
    ["racing"]              = true,
    ["poi-scrapper"]        = true,
    ["dragon-rostrum"]      = true,
}

function _LiteLite:VignetteMatches(scanMobName, info)
    scanMobName = scanMobName:lower()
    local guidType = strsplit('-', info.objectGUID)
    if info.atlasName:lower():find(scanMobName, nil, true) then
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
    print(format("Addin %s (%s)", data.objectGUID, data.name))
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
    for objectGUID, data in pairs(self.scannedGUID) do
        self:RemoveWaypoint(data)
    end
end

function _LiteLite:IsCloseWaypoint(data)
    if not data.tomTomWaypoint then
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

    for _, n in ipairs(self.db.scanMobNames) do
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
                printf(format("Vignette %s at (%.2f, %.2f)", data.name, pos.x*100, pos.y*100))
                printf(format("  guid %s", data.objectGUID))
                printf(format("  atlas %s", data.atlasName))
                printf(format("  autoClear %s", tostring(data.autoClear)))
                PlaySound(11466)
                self.scannedGUID[data.objectGUID] = data
                if self.db.autoScanWaypoint then
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

local function UpdateQuestRewards(tableWidget, rowData, info)
    local numRewards = GetNumQuestLogRewards(info.questID)
    if numRewards == 0 then
        local copper = GetQuestLogRewardMoney(info.questID)
        if copper > 0 then
            rowData[4] = GetMoneyString(copper)
            tableWidget:MarkDirty()
        end
        return
    end

    local questContainer = ContinuableContainer:Create()

    for i = 1, numRewards do
        local _, _, _, _, _, itemID = GetQuestLogRewardInfo(i, info.questID)
        local item = Item:CreateFromItemID(itemID)
        questContainer:AddContinuable(item)
    end

    questContainer:ContinueOnLoad(
        function ()
            for i = 1, numRewards do
                local itemName, itemTexture, numItems, quality, _, itemID, itemLevel = GetQuestLogRewardInfo(i, info.questID)
                ScanTooltip:SetQuestLogItem("reward", i, info.questID, true)
                local _, link = ScanTooltip:GetItem()
                rowData[4] = format("%s x%d", link, numItems)
            end
            tableWidget:MarkDirty()
        end)
end

local function GetQuest(tableWidget, info)
    local link = GetQuestLink(info.questID)
    local name, faction, capped = C_TaskQuest.GetQuestInfoByQuestID(info.questID)
    local secondsRemaining = C_TaskQuest.GetQuestTimeLeftSeconds(info.questID)
    local color = QuestUtils_GetQuestTimeColor(secondsRemaining or 0)
    local formatterOutput = WorldQuestsSecondsFormatter:Format(secondsRemaining)
    local mapInfo = C_Map.GetMapInfo(info.mapID)
    local rowData = { mapInfo.name, link or name, nil, nil, color:WrapTextInColorCode(formatterOutput) }
    if faction and C_QuestLog.QuestContainsFirstTimeRepBonusForPlayer(info.questID) then
        local factionData = C_MajorFactions.GetMajorFactionData(faction)
                            or C_Reputation.GetFactionDataByID(faction)
        rowData[3] = factionData and factionData.name
    end
    UpdateQuestRewards(tableWidget, rowData, info)
    tableWidget:AddRow(rowData)
end

local IgnoreMaps = {
    [2213] = true,      -- City of Threads
    [2216] = true,      -- City of Threads - Lower
    [2256] = true,      -- Azj-kahet Lower
}

function _LiteLite:FindChildZoneMaps(expansion)
    local todo
    if not expansion or expansion == 'tww' then
        todo = { 2274 }
    elseif expansion == 'df' then
        todo = { 1978 }
    elseif expansion == 'sl' then
        todo = { 1550 }
    elseif expansion == 'bfa' then
        todo = { 875, 876 }
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

function _LiteLite:WorldQuestProcess(expansion)
    local mapQuests = { }
    for _, mapID in ipairs(self:FindChildZoneMaps(expansion)) do
        for _, questInfo in ipairs(C_TaskQuest.GetQuestsForPlayerByMapID(mapID)) do
            if C_QuestLog.IsWorldQuest(questInfo.questID) and questInfo.mapID == mapID then
                table.insert(mapQuests, questInfo)
                C_TaskQuest.RequestPreloadRewardData(questInfo.questID)
            end
        end
    end

    C_Timer.NewTicker(0.5,
        function (self)
            local allKnown = true
            for _, info in pairs(mapQuests) do
                if not HaveQuestRewardData(info.questID) then allKnown = false break end
            end
            if allKnown then
                _LiteLiteTable:Setup("World Quests", { "Zone", "Quest", "Reputation", "Reward", "Time left" })
                for _, info in pairs(mapQuests) do
                    GetQuest(_LiteLiteTable, info)
                end
                _LiteLiteTable:SetEnableSort(true)
                _LiteLiteTable:SetSortColumn(1)
                _LiteLiteTable:Show()
                self:Cancel()
            end
        end, 10)
end

function _LiteLite:WorldQuestList(...)
    local filter, expansion

    for i = 1, select('#', ...) do
        local arg = select(i, ...)
        if arg:sub(1,1) == '-' then
            filter = arg
        else
            expansion = arg
        end
    end

    self:WorldQuestProcess(expansion)
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
    WeeklyRewardsFrame:SetUpConditionalActivities()
    WeeklyRewardsFrame:Refresh()
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

local function GetFactionNumbersByName(name)
    for i = 1, C_Reputation.GetNumFactions() do
        local data = C_Reputation.GetFactionDataByIndex(i)
        if data and data.isHeader == false and data.name == name then
            if C_Reputation.IsFactionParagon(data.factionID) then
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
        printf(BLUE_FONT_COLOR:WrapTextInColorCode(txt))
    end
end

function _LiteLite:CHAT_MSG_COMBAT_FACTION_CHANGE(msg)
    local factionName, amount = msg:match('with (.-) increased by (%d+)')
    amount = tonumber(amount)
    if factionName and amount and amount > 50 then
        C_Timer.After(0, function () PrintFactionIncrease(factionName, amount) end)
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


-- Also does ping mouseover now

function _LiteLite:RotatingMarker()
    local b = CreateFrame('Button', 'RotatingMarker', nil, 'SecureActionButtonTemplate')
    -- https://github.com/Stanzilla/WoWUIBugs/issues/317#issuecomment-1510847497
    b:SetAttribute("pressAndHoldAction", true)
    b:SetAttribute("type", "macro")
    b:SetAttribute("typerelease", "macro")

    SecureHandlerWrapScript(b, 'PreClick', b,
        [[
            if IsShiftKeyDown() then
                self:SetAttribute("macrotext", "/ping [@mouseover,help] warning; [@mouseover] attack")
            elseif IsControlKeyDown() then
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
    GetLoadoutExportString =
        function (self, currentSpecID, configID)
            local exportStream = ExportUtil.MakeExportDataStream()
            local configInfo = C_Traits.GetConfigInfo(configID)
            local treeInfo = C_Traits.GetTreeInfo(configID, configInfo.treeIDs[1])
            local treeHash = C_Traits.GetTreeHash(treeInfo.ID)
            local serializationVersion = C_Traits.GetLoadoutSerializationVersion()

            self:WriteLoadoutHeader(exportStream, serializationVersion, currentSpecID, treeHash)
            self:WriteLoadoutContent(exportStream, configID, treeInfo.ID)

            return exportStream:GetExportString()
        end,
    ImportLoadout =
        function (self, importText, loadoutName)
            printf('Importing loadout: ' .. loadoutName)
            local importStream = ExportUtil.MakeImportDataStream(importText)
            local headerValid, serializationVersion, specID, treeHash = self:ReadLoadoutHeader(importStream)

            if not headerValid then printf('Bad header') return end
            if specID ~= PlayerUtil.GetCurrentSpecID() then printf('Bad spec') return end

            local configID = C_ClassTalents.GetActiveConfigID()
            local configInfo = C_Traits.GetConfigInfo(configID)
            local treeInfo = C_Traits.GetTreeInfo(configID, configInfo.treeIDs[1])

            local loadoutContent = self:ReadLoadoutContent(importStream, treeInfo.ID)
            if not loadoutContent then printf('Loadout did not convert') return end
            local loadoutEntryInfo = self:ConvertToImportLoadoutEntryInfo(configID, treeInfo.ID, loadoutContent)


            if loadoutName == 'active' then
                C_Traits.ResetTree(configID, configInfo.treeIDs[1])
                self:PurchaseLoadout(configID, loadoutEntryInfo)
                C_Traits.CommitConfig(configID) -- TTT says this doesn't work
            else
                local ok, err = C_ClassTalents.ImportLoadout(configID, loadoutEntryInfo, loadoutName)
                if not ok then
                    printf('Loadout import failed: %s: %s', loadoutName, err)
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
                allSuccedeed = true
                for i, nodeEntry in pairs(loadoutEntryInfo) do
                    local success = C_Traits.SetSelection(configID, nodeEntry.nodeID, nodeEntry.selectionEntryID)
                    if not success then
                        for rank = 1, nodeEntry.ranksPurchased do
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

-- JSON strictly can't have gaps in an array, and Blizzard's serializer isn't
-- smart enough to turn it into a hash without string-ifying the keys
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

    C_AddOns.LoadAddOn('Blizzard_PlayerSpells')

    local exporter = CreateFromMixins(ClassTalentImportExportMixin, ImportExportMixin)

    map.loadouts = {}

    local specID = PlayerUtil.GetCurrentSpecID()
    for _,configID in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID)) do
        local info = C_Traits.GetConfigInfo(configID)
        map.loadouts[info.name] = exporter:GetLoadoutExportString(specID, configID)
    end

    -- No named sets, export current talents instead
    if next(map.loadouts) == nil then
        local configID = C_ClassTalents.GetActiveConfigID()
        map.loadouts['active'] = exporter:GetLoadoutExportString(specID, configID)
    end

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

    printf('Loading macros')
    if map.macros then
        for name, info in pairs(map.macros) do
            printf(' - ' .. name)
            SetMacro(info)
        end
    end

    printf('Setting action bar actions')
    for i = 1, 180 do
        local index = tostring(i)
        SetAction(i, map.actions[index])
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

    if map.clique and Clique and Clique.db then
        printf('Setting up Clique')
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

function _LiteLite:PLAYER_REGEN_ENABLED()
    UpdateEquipmentSetForLoadout()
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
    hooksecurefunc(ActionButtonSpellAlertManager, 'ShowAlert',
        function (_, b)
            -- Bad attempt to restrict to ActionBarActionButtonMixin
            if b.HasAction and b.SpellActivationAlert then
                b.SpellActivationAlert.ProcStartAnim:Stop()
                b.SpellActivationAlert.ProcStartFlipbook:SetAlpha(0)
                b.SpellActivationAlert.ProcLoop:Play()
            end
        end)
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
        function (self, event, ...)
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
        printf(format('Joined %s "%s" as %s', activityInfo.fullName, kstringGroupName, _G[role]))

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
    end
end


--[[------------------------------------------------------------------------]]--

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

local BindMacroButton = CreateFrame('Button', '_LiteLiteBindMacroButton', nil, 'SecureActionButtonTemplate')
BindMacroButton:RegisterForClicks('AnyDown', 'AnyUp')

function _LiteLite:SetBindMacro()
    if self.db.bindKey and self.db.bindMacro then
        BindMacroButton:SetAttribute('type', 'macro')
        BindMacroButton:SetAttribute('macrotext', self.db.bindMacro)
        SetOverrideBindingClick(BindMacroButton, true, self.db.bindKey, BindMacroButton:GetName())
    end
end

local HearthstoneToyButton = CreateFrame('Button', '_LLHS', nil, 'SecureActionButtonTemplate')
HearthstoneToyButton:RegisterForClicks('AnyDown', 'AnyUp')

local notHearthstone = {
    [110560] = true,
    [118427] = true,
    [119210] = true,
    [119211] = true,
    [140192] = true,
    [211946] = true,
}

function HearthstoneToyButton:Shuffle()
    for i = #self.toys, 2, -1 do
        local r = math.random(i)
        self.toys[i], self.toys[r] = self.toys[r], self.toys[i]
    end
end

function HearthstoneToyButton:Advance()
    if not InCombatLockdown() and self.toys ~= nil then
        if self.n == nil or self.n >= #self.toys then
            self:Shuffle()
            self.n = 1
        else
            self.n = self.n + 1
        end
        -- print(self:GetName(), 'Advance', self.toys[self.n])
        self:SetScript('PreClick', function () printf(self.toys[self.n]) end)
        self:SetAttribute('toy', self.toys[self.n])
    end
end

function HearthstoneToyButton:UpdateToy(item)
    local name = item:GetItemName()
    if name:find('Hearthstone') and not tContains(self.toys, name) then
        local id = item:GetItemID()
        if notHearthstone[id] then
            -- pass
        elseif PlayerHasToy(id) then
            table.insert(self.toys, name)
            if self.n == nil then self:Advance() end
        -- else
        --     print('No toy', id, name)
        end
    end
end

-- There's a few complicated cases on being able to scan toys, and I'm not
-- entirely sure when C_ToyBox.GetToyFromIndex works. I also don't think
-- there's any way to query toys outside the filter which is annoying, since
-- the index arg is a filtered toys index.

function HearthstoneToyButton:Update(event, itemID, isNew, hasFanfare)
    if itemID == nil then
        -- I'm trying not to scan too much, as this fires semi-regularly, I think
        -- every PLAYER_ENTERING_WORLD.
        if self.initialFullScan ~= nil then return end

        local itemList = {}

        -- Sometimes on first login this is 2. though perhaps now I set the
        -- default filters explicitly that isn't true any more.
        C_ToyBox.SetAllSourceTypeFilters(true)
        C_ToyBox.SetAllExpansionTypeFilters(true)
        C_ToyBox.SetUncollectedShown(true)
        C_ToyBox.SetFilterString('')
        local numFilteredToys = C_ToyBox.GetNumFilteredToys()

        -- printf('HearthstoneToyButton:Update: #%d', numFilteredToys)

        -- I think C_ToyBox.GetToyFromIndex relies on a client cache, which
        -- could just be the item cache. Calling C_ToyBox.GetToyFromIndex seems
        -- to return -1 if the toy is not cached, and trigger a TOYS_UPDATED
        -- event with the itemID when fetched. (It also returns -1 for indexes
        -- that don't exist.) It's possible GetItemInfo definitely works if the
        -- id is not -1 but I haven't tested it.

        for i = 1, numFilteredToys do
            local id = C_ToyBox.GetToyFromIndex(i)
            local item = Item:CreateFromItemID(id)
            if not item:IsItemEmpty() then
                table.insert(itemList, item)
            end
        end

        -- printf('initial item count: %d', #itemList)

        -- Current toy count is 900+ so just bail out if it looks like things
        -- aren't working and assume we will get a TOYS_UPDATED nil event later.

        if #itemList < 900 then return end

        self.initialFullScan = true

        self.toys = self.toys or {}

        local cc = ContinuableContainer:Create()
        cc:AddContinuables(itemList)
        cc:ContinueOnLoad(
            function ()
                for _, item in ipairs(itemList) do
                    self:UpdateToy(item)
                end
            end)
    elseif itemID ~= nil then
        -- printf('HearthstoneToyButton:Update: %d', itemID)
        self.toys = self.toys or {}
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function () self:UpdateToy(item) end)
    end
end

function _LiteLite:SetupHearthstoneButton()
    if WOW_PROJECT_ID ~= 1 then return end
    HearthstoneToyButton:SetAttribute('type', 'toy')
    HearthstoneToyButton:SetAttribute('typerelease', 'toy')
    HearthstoneToyButton:SetAttribute('pressAndHoldAction', true)
    HearthstoneToyButton:SetScript('PostClick', function (self) self:Advance() end)
    EventUtil.RegisterOnceFrameEventAndCallback('PLAYER_ENTERING_WORLD',
        function ()
            HearthstoneToyButton:RegisterEvent('TOYS_UPDATED')
            HearthstoneToyButton:SetScript('OnEvent', HearthstoneToyButton.Update)
            HearthstoneToyButton:Update()
        end)
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

local DelvePrimaryOnlyMaps = {
    [2346]  = true,     -- Undermine
    [2371]  = true,     -- K'aresh
}

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
    local delveData = {}
    for _, mapID in ipairs(self:FindChildZoneMaps('tww')) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        local delveList = C_AreaPoiInfo.GetDelvesForMap(mapID)
        for _, poiID in ipairs(delveList) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
            if poiInfo.isPrimaryMapForPOI or DelvePrimaryOnlyMaps[mapID] then
                local name = poiInfo.name
                local isBountiful = ( poiInfo.atlasName == 'delves-bountiful' )
                local story = GetDelveStory(poiInfo)
                if isBountiful then
                    table.insert(delveData, { mapInfo.name, name, story, isBountiful, color=ORANGE_FONT_COLOR })
                else
                    table.insert(delveData, { mapInfo.name, name, story, isBountiful })
                end
            end
        end
    end

    table.sort(delveData,
        function (a, b)
            if a[1] ~= b[1] then
                return a[1] < b[1]
            else
                return a[2] < b[2]
            end
        end)

    -- Seems to be no way to get a list of delve runs the way you can with M+
    -- Figure out what the highest ilevel reward is and see how many we've done
    -- that would give that reward. Relies on the a vault slot showing more than
    -- the threshold until you complete the next one.

    local activities = C_WeeklyRewards.GetActivities(Enum.WeeklyRewardChestThresholdType.World)
    local activityTierID = activities[1].activityTierID
    local maxItemLevel
    for i = 1, 32 do
        local _, _, _, itemLevel = C_WeeklyRewards.GetNextActivitiesIncrease(activityTierID, i)
        maxItemLevel = itemLevel or maxItemLevel
    end

    local progress = 0
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
    _LiteLiteTable:Reset()
    _LiteLiteTable:Setup(DELVES_LABEL, { "Map", "Delve", "Story", "Bountiful?" })
    _LiteLiteTable:SetFooter(footer)
    _LiteLiteTable:SetEnableSort(true)
    _LiteLiteTable:SetRows(delveData)
    _LiteLiteTable:Show()
end

--[[
    Not sure how to make ActionBarController_UpdateAll without taint. Or how to
    make actionpage change without taint before UPDATE_BONUS_ACTIONBAR which
    causes it to be called.

    Things that don't work:
    1. RegisterAttributeDriver(MultiBarBottomRight, "actionpage", "[stealth] 14; 5")
        because the individual bars don't control their own updating
    2. SecureHandlerSetFrameRef/WrapScript
        becuse ActionBarController is not a secure frame.
]]


function _LiteLite:PageMultiBarBottomRight()
--[=[
    local ap = CreateFrame("Frame", "_LiteLiteActionPager", nil, "SecureGroupHeaderTemplate")
    SecureHandlerSetFrameRef(ap, "bar", MultiBarBottomRight)
    SecureHandlerWrapScript(MainMenuBar, "OnAttributeChanged", ap,
        [[
            print('x')
            print(name)
            print(value)
            if name == 'actionpage' then
                local bar = self:GetFrameRef('bar')
                if HasBonusActionBar() then
                    bar:SetAttribute("actionpage", 14)
                else
                    bar:SetAttribute("actionpage", 5)
                end
            end
       ]])

    local function Update()
        if HasBonusActionBar() then
            MultiBarBottomRight:SetAttribute("actionpage", 14)
        else
            MultiBarBottomRight:SetAttribute("actionpage", 5)
        end
    end
]=]
    -- Hooking because it's called in ActionBarController_UpdateAll before
    -- all of the bar buttons are updated for their state. Not because we care
    -- at all about the stance bar.
    -- hooksecurefunc(StanceBar, 'Update', Update)
    -- Update()
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

local HealerCitrines = { 228643, 228644 }

function _LiteLite:CheckCitrines()
    if WOW_PROJECT_ID ~= 1 then return end

    if select(2, UnitClass('player')) ~= 'MONK' then return end
    if GetSpecialization() == 2 then return end

    local link

    for _, inventorySlot in ipairs({ 11, 12 }) do
        if GetInventoryItemID('player', inventorySlot) == 228411 then
            link = GetInventoryItemLink('player', inventorySlot)
            break
        end
    end

    if not link then return end

    local gemID1, gemID2, gemID3 = link:match('item:%d+:%d*:(%d*):(%d*):(%d*)')


    if tContains(HealerCitrines, tonumber(gemID1))
    or tContains(HealerCitrines, tonumber(gemID2))
    or tContains(HealerCitrines, tonumber(gemID3)) then
        local cc = ContinuableContainer:Create()
        local gem1 = Item:CreateFromItemID(tonumber(gemID1))
        local gem2 = Item:CreateFromItemID(tonumber(gemID2))
        local gem3 = Item:CreateFromItemID(tonumber(gemID3))
        cc:AddContinuables({ gem1, gem2, gem3 })
        cc:ContinueOnLoad(
            function ()
                UIErrorsFrame:AddMessage('FIX YOUR GEMS NUBBIN')
                printf('FIX YOUR GEMS NUBBIN')
                printf('1. %s', gem1:GetItemLink())
                printf('2. %s', gem2:GetItemLink())
                printf('3. %s', gem3:GetItemLink())
            self:FlashScreen(10)
            end)
    end
end

function _LiteLite:PLAYER_SPECIALIZATION_CHANGED()
    self:CheckCitrines()
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

function _LiteLite:RestoredCofferKeys()
    local pinnacleCompleted = 0
    for _, questID in ipairs({ 82449, 82706, 82679, 85460 }) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID)then
            pinnacleCompleted = pinnacleCompleted + 1
            break
        end
    end

    local ecoSuccess = C_QuestLog.IsQuestFlaggedCompleted(85460)
    local phaseDiving = C_QuestLog.IsQuestFlaggedCompleted(91093)

    local specialCompleted =  false
    for _, questID in ipairs({ 89294, 89293 }) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            specialCompleted = true
            break
        end
    end

    local shardsCompleted = 0
    for _, questID in ipairs({ 84736, 84737, 84738, 84739 }) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            shardsCompleted = shardsCompleted + 1
        end
    end

    local keysCompleted = 0
    for _, questID in ipairs({ 91175, 91176, 91177, 91178 }) do
        if C_QuestLog.IsQuestFlaggedCompleted(questID) then
            keysCompleted = keysCompleted + 1
        end
    end

    printf("Full keys completed: %d/4", keysCompleted)
    printf("  Pinnacle cache: %d", pinnacleCompleted)
    printf("  Ecological succession: %s", tostring(ecoSuccess))
    printf("  Phase diving: %s", tostring(ecoSuccess))
    printf("  K'aresh special assignment: %s", tostring(specialCompleted))
    printf("Shards completed: %d/200", shardsCompleted*50)
end

-- All of the ticker weirdness with the auto-inviting is because (a) battle.net
-- does not always answer, and takes a while to answer after login and (b) as
-- far as I can tell there is no way to tell the difference between "can't look
-- this GUID up right now" and "can never look this GUID up because it is not
-- part of our battle.net friends".

function _LiteLite:OnBattleNetInfoAvailable(guid, func)
    local attempts = 0

    local function TickerFunc(ticker)
        attempts = attempts + 1
        if attempts > 30 then
            ticker:Cancel()
            func(nil)   -- Call with nil info if attempts expired
            return
        end
        local info = C_BattleNet.GetAccountInfoByGUID(guid)
        if info then
            ticker:Cancel()
            func(info)
        end
    end

    C_Timer.NewTicker(0.1, TickerFunc)
end

function _LiteLite:AutoInviteMyself()
    self.invited = {}
    self:OnBattleNetInfoAvailable(GetPlayerGuid(),
        function (info)
            self.myBattleTag = info.battleTag
        end)
    self:RegisterEvent("GUILD_ROSTER_UPDATE")
    C_GuildInfo.GuildRoster()
end

function _LiteLite:AutoInvite(name, info)
    if info and info.battleTag == self.myBattleTag then
        printf("   - One of my toons, inviting %s", name)
        C_Timer.After(1, function () C_PartyInfo.InviteUnit(name) end)
        return true
    else
        return false
    end
end

function _LiteLite:GUILD_ROSTER_UPDATE()
    local myName = string.join('-', UnitFullName('player'))

    -- printf("AutoInviteMyself check due to GUILD_ROSTER_UPDATE")

    local _, n = GetNumGuildMembers()
    for i = 1, n do
        local name = GetGuildRosterInfo(i)
        if name ~= myName and self.invited[name] == nil then
            self.invited[name] = 'pending'
            printf(" - Checking %d. %s", i, name)
            local guid = select(17, GetGuildRosterInfo(i))
            self:OnBattleNetInfoAvailable(guid,
                function (info)
                    self.invited[name] = self:AutoInvite(name, info)
                end)
        end
    end
end

function _LiteLite:AcceptMyInvites()
    self:RegisterEvent("PARTY_INVITE_REQUEST")
end

function _LiteLite:AutoAcceptInvite(name, inviterInfo)
    if inviterInfo then
        local myInfo = C_BattleNet.GetAccountInfoByGUID(self.playerGUID)
        if inviterInfo.battleTag == myInfo.battleTag then
            print('AutoInvite OK', name, inviterInfo.battleTag, myInfo.battleTag)
            AcceptGroup()
            StaticPopup_Hide("PARTY_INVITE")
        end
    end
end

function _LiteLite:PARTY_INVITE_REQUEST(...)
    local inviterName, _, _, _, _, _, inviterGUID = ...

    if inviterName and inviterGUID then
    self:OnBattleNetInfoAvailable(inviterGUID,
        function (inviterInfo)
            self:AutoAcceptInvite(inviterName, inviterInfo)
        end)
    end
end
