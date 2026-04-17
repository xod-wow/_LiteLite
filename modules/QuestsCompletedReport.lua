-- A bad attempt at a "what quest did I just complete" scanner, which is
-- pretty much totally useless since you have to know beforehand. There must be
-- a nice way to do this automatically since plenty of addons know questIDs for
-- rares and mounts and stuff.

local _, addon = ...

local questsCompleted = {}

local function ScanQuestsCompleted(scanTime)
    scanTime = scanTime or 0

    for i = 1,100000 do
        if not questsCompleted[i] and C_QuestLog.IsQuestFlaggedCompleted(i) then
            questsCompleted[i] = scanTime
        end
    end
end

local function ReportQuestsCompleted()
    addon.printf("Completed quests report:")
    for i = 1,100000 do
        if questsCompleted[i] and questsCompleted[i] > 0 then
            local title = C_TaskQuest.GetQuestInfoByQuestID(i)
            addon.printf(format("Newly completed: %d (%s) at %d", i, title or UNKNOWN, questsCompleted[i]))
        end
    end
end

local function Report()
    local now = GetServerTime()
    ScanQuestsCompleted(now)
    ReportQuestsCompleted()
end

local function Baseline()
    local now = GetServerTime()
    ScanQuestsCompleted()
    for k in pairs(questsCompleted) do
        questsCompleted[k] = 0
    end
end

local addonInfo = {
    SlashCommands = {
        ['quest-baseline'] = Baseline,
        ['qb'] = Baseline,
        ['quest-report'] = Report,
        ['qr'] = Report,
    }
}
addon.RegisterModule(addonInfo)
