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
    elseif arg == 'gallagio-garbage' or arg == 'gg' then
        printf('Gallagio Garbage completed: %s', tostring(C_QuestLog.IsQuestFlaggedCompleted(87007)))
        return true
    elseif arg == 'drive' then
        self:ShowDRIVE()
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
    elseif arg1 == 'world-quest' or arg1 == 'wq' then
        if arg2 then
            self:WorldQuestList(string.split(' ', arg2))
        else
            self:WorldQuestList()
        end
        return true
    elseif arg1 == 'guild-news' or arg1 == 'gn' then
        _LiteLiteLoot.minlevel = tonumber(arg2)
        if _LiteLiteLoot:IsShown() then
            _LiteLiteLoot:Update()
        else
            _LiteLiteLoot:Show()
        end
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
            self:ShowScanWaypoint()
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

    self.questsCompleted = {}
    self:ScanQuestsCompleted()

    self:SetupSlashCommand()
    self:RegisterEvent('COMBAT_LOG_EVENT_UNFILTERED')
    self:RegisterEvent('CHAT_MSG_MONSTER_YELL')
    self:RegisterEvent('CHAT_MSG_MONSTER_EMOTE')
    self:RegisterEvent('CHAT_MSG_LOOT')
    self:RegisterEvent('ENCOUNTER_START')
    self:RegisterEvent('ENCOUNTER_END')
    self:RegisterEvent('CHAT_MSG_COMBAT_XP_GAIN')
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
            self:RegisterEvent("ZONE_CHANGED_NEW_AREA")
        end
    else
        self.announcedMobGUID = table.wipe(self.announcedMobGUID or {})
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

function _LiteLite:ShowScanWaypoint()
    local wp = self.scanWaypoints and self.scanWaypoints[1]
    if wp and TomTom then
        -- printf('Adding waypoint: %s %s', wp.info.name, wp.info.objectGUID)
        wp.uid = TomTom:AddWaypoint(
                    wp.uiMapID,
                    wp.pos.x,
                    wp.pos.y,
                    {
                        title = wp.info.name,
                        persistent = nil,
                        minimap = true,
                        world = true
                    })
    end
end

function _LiteLite:RemoveAllScanWaypoints()
    while self.scanWaypoints and #self.scanWaypoints > 0 do
        local wp = table.remove(self.scanWaypoints)
        if wp.uid and TomTom then
            TomTom:ClearWaypoint(wp.uid)
        end
    end
end

function _LiteLite:ClearScanWaypoints()
    if not self.scanWaypoints then return end

    local objectGUIDs = {}
    for _, vignetteGUID in ipairs(C_VignetteInfo.GetVignettes()) do
        local info = C_VignetteInfo.GetVignetteInfo(vignetteGUID)
        if info then
            objectGUIDs[info.objectGUID] = info
        end
    end
    for i = #self.scanWaypoints, 1, -1 do
        local wp = self.scanWaypoints[i]
        if objectGUIDs[wp.info.objectGUID] == nil then
            -- DevTools_Dump({ objectGUIDs })
            -- printf('Removing waypoint: %s %s', wp.info.name, wp.info.objectGUID)
            if wp.uid then
                TomTom:ClearWaypoint(wp.uid)
            end
            table.remove(self.scanWaypoints, i)
        end
    end
end

function _LiteLite:AddScanWaypoint(info, pos, uiMapID)
    self.scanWaypoints = self.scanWaypoints or {}
    table.insert(self.scanWaypoints, 1, { info = info, pos = pos, uiMapID = uiMapID })
    if self.db.autoScanWaypoint then
        self:ShowScanWaypoint()
    end
end

function _LiteLite:VIGNETTE_MINIMAP_UPDATED(id)
    local info = C_VignetteInfo.GetVignetteInfo(id)
    if not info or self.announcedMobGUID[info.objectGUID] then return end

    local uiMapID = C_Map.GetBestMapForUnit('player')
    if not uiMapID then return end

    for _, n in ipairs(self.db.scanMobNames) do
        if self:VignetteMatches(n, info) then
            self.announcedMobGUID[info.objectGUID] = info.name
            local pos = C_VignetteInfo.GetVignettePosition(info.vignetteGUID, uiMapID)
            printf(format("Vignette %s at (%.2f, %.2f)", info.name, pos.x*100, pos.y*100))
            printf(format("  guid %s", info.objectGUID))
            printf(format("  atlas %s", info.atlasName))
            PlaySound(11466)
            self:AddScanWaypoint(info, pos, uiMapID)
        end
    end
end

function _LiteLite:VIGNETTES_UPDATED()
    for _, id in ipairs(C_VignetteInfo.GetVignettes()) do
        self:VIGNETTE_MINIMAP_UPDATED(id)
    end
    -- Sometimes (like with S.C.R.A.P. Heap) a vignette is removed then
    -- replaced with another with the same objectGUID (to change icon).
    -- Delay the delete to give the new one a chance to spawn.
    C_Timer.After(1, function () self:ClearScanWaypoints() end)
end

function _LiteLite:ZONE_CHANGED_NEW_AREA()
    self:VIGNETTES_UPDATED()
end

function _LiteLite:PLAYER_LOGOUT()
    self:RemoveAllScanWaypoints()
end

local function PrintQuestRewards(info)
    local questContainer = ContinuableContainer:Create()

    local numRewards = GetNumQuestLogRewards(info.questID)
    if numRewards == 0 then
        return
    end

    for i = 1, numRewards do
        local _, _, _, _, _, itemID = GetQuestLogRewardInfo(i, info.questID)
        local item = Item:CreateFromItemID(itemID)
        questContainer:AddContinuable(item)
    end

    local mapInfo = C_Map.GetMapInfo(info.mapID)

    questContainer:ContinueOnLoad(
        function ()
            local name = C_TaskQuest.GetQuestInfoByQuestID(info.questID)
            local qt = format("quest %s - %s", name, mapInfo.name)
            local copper = GetQuestLogRewardMoney(info.questID)
            if copper > 0 then
                printf("  %s %s", GetMoneyString(copper), qt)
            end
            for i = 1, numRewards do
                local itemName, itemTexture, numItems, quality, _, itemID, itemLevel = GetQuestLogRewardInfo(i, info.questID)
                ScanTooltip:SetQuestLogItem("reward", i, info.questID, true)
                local name, link = ScanTooltip:GetItem()
                printf("  %sx%d %s", link, numItems, qt)
            end
        end)
end

local function PrintEquipmentQuestRewards(info)
    local i, rewardType = QuestUtils_GetBestQualityItemRewardIndex(info.questID)
    if not i or i == 0 then return end
    local itemID, itemLevel = select(6, GetQuestLogRewardInfo(i, info.questID))
    if not itemID then return end

    local item = Item:CreateFromItemID(itemID)
    item:ContinueOnItemLoad(
        function ()
            local mapInfo = C_Map.GetMapInfo(info.mapID)
            ScanTooltip:SetQuestLogItem(rewardType, i, info.questID, true)
            local name, link = ScanTooltip:GetItem()
            local equipLoc = select(9, GetItemInfo(itemID))
            if equipLoc ~= "INVTYPE_NON_EQUIP_IGNORE" then
                printf('  [%s] %s (%d) - %s ', _G[equipLoc], link, itemLevel, mapInfo.name)
            elseif C_Soulbinds.IsItemConduitByItemInfo(link) then
                printf('  [CONDUIT] %s - %s ', link, mapInfo.name)
            end
        end)
end

local function PrintReputationQuestRewards(info)
    local name, faction, capped = C_TaskQuest.GetQuestInfoByQuestID(info.questID)
    if faction and C_QuestLog.QuestContainsFirstTimeRepBonusForPlayer(info.questID) then
        local secondsRemaining = C_TaskQuest.GetQuestTimeLeftSeconds(info.questID)
        local color = QuestUtils_GetQuestTimeColor(secondsRemaining or 0)
        local formatterOutput = WorldQuestsSecondsFormatter:Format(secondsRemaining)
        local mapInfo = C_Map.GetMapInfo(info.mapID)
        local factionData = C_MajorFactions.GetMajorFactionData(faction)
        printf("  %s - %s - %s", mapInfo.name, name, color:WrapTextInColorCode(formatterOutput))
    end
end

local function PrintQuest(info)
    local name, faction, capped = C_TaskQuest.GetQuestInfoByQuestID(info.questID)
    local secondsRemaining = C_TaskQuest.GetQuestTimeLeftSeconds(info.questID)
    local color = QuestUtils_GetQuestTimeColor(secondsRemaining or 0)
    local formatterOutput = WorldQuestsSecondsFormatter:Format(secondsRemaining)
    local mapInfo = C_Map.GetMapInfo(info.mapID)
    printf("  %s - %s - %s", mapInfo.name, name, color:WrapTextInColorCode(formatterOutput))
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

function _LiteLite:WorldQuestProcess(expansion, printFunc)
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
                printf("World quest rewards:")
                for _, info in pairs(mapQuests) do
                    printFunc(info)
                end
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

    if filter == nil then
        self:WorldQuestProcess(expansion, PrintQuestRewards)
    elseif filter:sub(2,2) == 'i' then
        self:WorldQuestProcess(expansion, PrintEquipmentQuestRewards)
    elseif filter:sub(2,2) == 'l' then
        self:WorldQuestProcess(expansion, PrintQuest)
    elseif filter:sub(2,2) == 'r' then
        self:WorldQuestProcess(expansion, PrintReputationQuestRewards)
    end
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
    return ser:Serialize(map)
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
    hooksecurefunc('ActionButton_ShowOverlayGlow',
        function (b)
            b.SpellActivationAlert.ProcStartAnim:Stop()
            b.SpellActivationAlert.ProcStartFlipbook:SetAlpha(0)
            b.SpellActivationAlert.ProcLoop:Play()
        end)
end

--[[------------------------------------------------------------------------]]--

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
    view:SetPadding(2,2,2,2,5)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
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
        if info and info.newsType == NEWS_ITEM_LOOTED and info.whatText then
            local level = GetDetailedItemLevelInfo(info.whatText)
            local invType, subType, _, equipSlot = select(6, GetItemInfo(info.whatText))
            if equipSlot ~= '' and level and level >= ( self.minlevel or 0 ) then
                local date = format(DATE_FMT, CALENDAR_WEEKDAY_NAMES[info.weekday + 1], info.day + 1, info.month + 1)
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

function _LiteLite:ListDelves(bountifulOnly)
    for _, mapID in ipairs(self:FindChildZoneMaps('tww')) do
        local mapInfo = C_Map.GetMapInfo(mapID)
        local delveList = C_AreaPoiInfo.GetDelvesForMap(mapID)
        for _, poiID in ipairs(delveList) do
            local poiInfo = C_AreaPoiInfo.GetAreaPOIInfo(mapID, poiID)
            if poiInfo.isPrimaryMapForPOI or mapID == 2346 then
                local name = poiInfo.name
                if poiInfo.atlasName == 'delves-bountiful' then
                    name = GOLD_FONT_COLOR:WrapTextInColorCode(name)
                    printf("%s: %s", mapInfo.name, name)
                elseif not bountifulOnly then
                    printf("%s: %s", mapInfo.name, name)
                end
            end
        end
    end

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
    printf("Max level delves completed: %d/%d", progress, activities[3].threshold)
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

local HealerCitrines = { 228643, 228644 }

function _LiteLite:CheckCitrines()
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
