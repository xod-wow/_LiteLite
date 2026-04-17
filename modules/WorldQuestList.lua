-- Show a table of world quests and their rep and item/gold rewards

local _, addon = ...

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

local function WorldQuestProcess(expansion)
    local mapQuests = { }
    for _, mapID in ipairs(addon.FindChildZoneMaps(expansion)) do
        for _, questInfo in ipairs(C_TaskQuest.GetQuestsOnMap(mapID)) do
            if C_QuestLog.IsWorldQuest(questInfo.questID) and questInfo.mapID == mapID then
                table.insert(mapQuests, questInfo)
                C_TaskQuest.RequestPreloadRewardData(questInfo.questID)
            end
        end
    end

    C_Timer.NewTicker(0.5,
        function (ticker)
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
                ticker:Cancel()
            end
        end, 10)
end

local function SlashCommand(expansion)
    WorldQuestProcess(expansion)
end

local addonInfo = {
    SlashCommands = {
        ['world-quest'] = SlashCommand,
        ['wq'] = SlashCommand,
    }
}
addon.RegisterModule(addonInfo)
