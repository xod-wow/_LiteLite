--[[----------------------------------------------------------------------------
--
-- _LiteLite
--
----------------------------------------------------------------------------]]--

BINDING_HEADER_LITELITE = "_LiteLite"
BINDING_NAME_LL_TOGGLE_GUILD_UI = "Toggle Guild UI"
BINDING_NAME_LL_NEXT_GAME_SOUND_OUTPUT = "Next Game Sound Output"

do
    QuestFrame:SetScale(1.5)
    GossipFrame:SetScale(1.5)
    ItemTextFrame:SetScale(1.5)
end

_LiteLite = CreateFrame('Frame')
_LiteLite:SetScript('OnEvent',
        function (self, e, ...)
            if self[e] then self[e](self, e, ...) end
        end)
_LiteLite:RegisterEvent('PLAYER_LOGIN')

function _LiteLite:DreamweaversEmissaryUp()
    -- The Dreamweavers = Quest 42170
    -- Val'sharah = UiMapID 868

    local bountyQuests = GetQuestBountyInfoForMapID(868)
    for _, q in ipairs(bountyQuests) do
        if q.questID == 42170 then
            print(GREEN_FONT_COLOR_CODE .. '-----' .. FONT_COLOR_CODE_CLOSE)
            print(GREEN_FONT_COLOR_CODE .. 'The Dreamweavers is up' .. FONT_COLOR_CODE_CLOSE)
            print(GREEN_FONT_COLOR_CODE .. '-----' .. FONT_COLOR_CODE_CLOSE)
        end
    end
end

function _LiteLite:SlashCommand(arg)
    local now = GetServerTime()
    if arg == 'qscan' then
        self:ScanQuestsCompleted(now)
    elseif arg == 'qreport' then
        self:ScanQuestsCompleted(now)
        self:ReportQuestsCompleted()
    end
    return true
end

function _LiteLite:SetupSlashCommand()
    SlashCmdList["_LiteLite"] = function (...) self:SlashCommand(...) end
    _G.SLASH__LiteLite1 = "/litelite"
    _G.SLASH__LiteLite2 = "/ll"

end

function _LiteLite:PLAYER_LOGIN()
    self:DreamweaversEmissaryUp()
    self:ScanQuestsCompleted()
    self:SetupSlashCommand()
    self:RegisterEvent("COMBAT_LOG_EVENT_UNFILTERED")
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
    print("Completed quests report:")
    for i = 1,100000 do
        if self.questsCompleted[i] and self.questsCompleted[i] > 0 then
            print(format("Newly completed: %d at %d", i, self.questsCompleted[i]))
        end
    end
end
