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
        local f = _G["ChatFrame"..i]
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
    local info = ChatTypeInfo["SYSTEM"]
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
                local info = ChatTypeInfo["SYSTEM"]
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
            local info = ChatTypeInfo["SYSTEM"]
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
    ChatFrame1:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT" ,38, 8)
    FCF_SavePositionAndDimensions(ChatFrame1)

    for i = 1,NUM_CHAT_WINDOWS+1 do
        local f = _G["ChatFrame"..i]
        if f then
            FCF_SetWindowAlpha(f, 0.66)
            FCF_SetWindowColor(f, 0, 0, 0)
        end
    end
end

local function GameTooltipSpellInfo()
    local _, spellid = GameTooltip:GetSpell()
    if spellid then return GetSpellInfo(spellid) end
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
        i = CreateMacro(macroName, "INV_MISC_QUESTIONMARK", macroText, true)
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

    arg1 = tonumber(arg1 or select(3, GameTooltipSpellInfo()))

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
    end

    -- One argument options
    local arg1, arg2 = string.split(' ', arg, 2)
    if arg1 == 'mouseover-macro' then
        self:CreateSpellMacro(MouseoverMacroTemplate, arg2)
        return true
    elseif arg1 == 'trinket-macro' then
        self:CreateSpellMacro(TrinketMacroTemplate, arg2)
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
    elseif arg1 == 'search-globals' then
        self:SearchGlobals(arg2, arg3)
        return true
    end

    printf("/ll chatframe-settings")
    printf("/ll equipset-icon [n [iconid]]")
    printf("/ll equipset-icon auto")
    printf("/ll nameplate-settings")
    printf("/ll quest-scan")
    printf("/ll quest-report")
    printf("/ll search-globals text [doKeySearch]")
    printf("/ll tanaan-rares")
    printf("/ll mouseover-macro [spellname]")
    printf("/ll trinket-macro [spellname]")
    return true
end

function _LiteLite:SetupSlashCommand()
    SlashCmdList["_LiteLite"] = function (...) self:SlashCommand(...) end
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

end

function _LiteLite:PLAYER_LOGIN()
    printf('Initialized.')
    self:ScanQuestsCompleted()
    self:SetupSlashCommand()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    self:BiggerFrames()
    self:ShiftEnchantsScroll()

    C_Timer.After(15, _LiteLite.RunTimedChecks)
end

function _LiteLite:COMBAT_LOG_EVENT_UNFILTERED()
    local ts, e, _, _, _, _, _, _, name, flags = CombatLogGetCurrentEventInfo()
    if e ~= "UNIT_DIED" or bit.bor(flags, 0x40) == 0 then
        return
    end
    self.lastKillName = name
    self.lastKillTime = ts
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
