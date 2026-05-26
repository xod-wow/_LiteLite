-- A better version of what loot people got, extracted from the guild news.
-- Sadly the dates on them are in "maybe somewhere in the USA who knows"
-- day granularity.

local _, addon = ...

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

local NewsScanner = CreateFrame("Frame")

local function ShowGuildNews(minItemLevel)
    minItemLevel = tonumber(minItemLevel)
    NewsScanner:RegisterEvent("GUILD_NEWS_UPDATE")
    NewsScanner:RegisterEvent("GUILD_ROSTER_UPDATE")
    NewsScanner:SetScript("OnEvent",
        function (self, event)
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
    _LiteLiteTable:SetAutoWidth(true)
    _LiteLiteTable:Setup(GUILD_NEWS, { "Date", "Player", "iLvl", "Slot", "Item" })
    UpdateGuildNews(minItemLevel)
    _LiteLiteTable:SetRows(guildNews)
    _LiteLiteTable:SetEnableSort(false)
    _LiteLiteTable:Show()
end

local function SlashCommand(arg)
    local iLevel = tonumber(arg)
    ShowGuildNews(iLevel)
end

local moduleInfo = {
    SlashCommands = {
        ['guild-news'] = ShowGuildNews,
        ['gn'] = ShowGuildNews,
    }
}
addon.RegisterModule(moduleInfo)
