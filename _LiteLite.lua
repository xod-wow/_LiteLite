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

local function DreamweaversEmissaryUp()
    -- The Dreamweavers = Quest 42170
    -- Broken Isles = UiMapID 619

    local bountyQuests = GetQuestBountyInfoForMapID(619)
    for _, q in ipairs(bountyQuests) do
        if q.questID == 42170 then
            print(GREEN_FONT_COLOR_CODE .. '-----' .. FONT_COLOR_CODE_CLOSE)
            print(GREEN_FONT_COLOR_CODE .. 'The Dreamweavers is up' .. FONT_COLOR_CODE_CLOSE)
            print(GREEN_FONT_COLOR_CODE .. '-----' .. FONT_COLOR_CODE_CLOSE)
        end
    end
end

function _LiteLite:PLAYER_LOGIN()
    DreamweaversEmissaryUp()
end

-- Show the old guild UI which is better than the new thing

function _LiteLite.ToggleGuildUI()
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

function _LiteLite.NextGameSoundOutput()
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
