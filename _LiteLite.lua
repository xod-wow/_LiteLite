--[[----------------------------------------------------------------------------
--
-- _LiteLite
--
----------------------------------------------------------------------------]]--

BINDING_HEADER_LITELITE = "_LiteLite"
BINDING_NAME_LL_TOGGLE_GUILD_UI = "Toggle Guild UI"
BINDING_NAME_LL_NEXT_GAME_SOUND_OUTPUT = "Next Game Sound Output"

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
        print(format('%s: %s', rare, status))
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

function _LiteLite:CreateTrinketMacro(spell)
end

function _LiteLite:CreateMouseoverMacro(spell)
end

function _LiteLite:SetEquipsetIcon(n, arg1)
    if n == nil then
        n = PaperDollEquipmentManagerPane.selectedSetID
    elseif n == 'auto' then
        for n = 0, C_EquipmentSet.GetNumEquipmentSets() - 1 do
            local specIndex = C_EquipmentSet.GetEquipmentSetAssignedSpec(n)
            if specIndex then
                arg1 = select(4, GetSpecializationInfo(specIndex))
                self:SetEquipsetIcon(n, arg1)
            end
        end
        return
    else
        n = tonumber(n)
    end

    if n == nil then
        return
    end

    local name, icon = C_EquipmentSet.GetEquipmentSetInfo(n)

    arg1 = tonumber(arg1)

    if arg1 then
        if arg1 > 9 then
            C_EquipmentSet.ModifyEquipmentSet(n, name, arg1)
        else
            icon = select(4, GetSpecializationInfo(arg1))
            C_EquipmentSet.ModifyEquipmentSet(n, name, icon)
        end
    else
        local _, spellid = GameTooltip:GetSpell()
        if spellid then
            icon = select(3, GetSpellInfo(spellid))
            if icon then
                C_EquipmentSet.ModifyEquipmentSet(n, name, icon)
            end
        end
    end
end

function _LiteLite:SlashCommand(arg)
    if arg == 'qscan' then
        local now = GetServerTime()
        self:ScanQuestsCompleted(now)
        return true
    end

    if arg == 'qreport' then
        local now = GetServerTime()
        self:ScanQuestsCompleted(now)
        self:ReportQuestsCompleted()
        return true
    elseif arg == 'chat' then
        self:ChatFrameSettings()
        return true
    elseif arg == 'nameplate' then
        self:NameplateSettings()
        return true
    elseif arg == 'tanaan' then
        self:TanaanRares()
        return true
    end

    local arg1, arg2 = string.split(' ', arg, 2)

    if arg1 == 'eq' then
        self:SetEquipsetIcon(arg2)
        return true
    end

    printf("/ll chat")
    printf("/ll eq n [iconid]")
    printf("/ll eq auto")
    printf("/ll nameplates")
    printf("/ll qscan")
    printf("/ll qreport")
    printf("/ll tanaan")
    return true
end

function _LiteLite:SetupSlashCommand()
    SlashCmdList["_LiteLite"] = function (...) self:SlashCommand(...) end
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

end

function _LiteLite:PLAYER_LOGIN()
    self:ScanQuestsCompleted()
    self:SetupSlashCommand()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")

    self:BiggerFrames()

    C_Timer.After(10, function () self:DreamweaversEmissaryUp() end)
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
