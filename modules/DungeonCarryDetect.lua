local _, addon = ...

local MAX_PARTY_MEMBERS, MAX_RAID_MEMBERS = MAX_PARTY_MEMBERS, MAX_RAID_MEMBERS

local UnitItemLevelByGUID = {}
local PendingInspect = {}
local LastInspectTime = 0
local ticker

-- UnitTokenFromGUID doesn't work in instances?

local function GroupTokenFromGUID(guid)
    -- No need for UnitExists, UnitGUID will just be nil
    for unitToken in addon.IterateGroupMembers() do
        if UnitGUID(unitToken) == guid then
            return unitToken
        end
    end
end

local function INSPECT_READY(_owner, guid)
    if InCombatLockdown() or UnitIsDead('player') then
        return
    end
    local unitToken = GroupTokenFromGUID(guid)
    if unitToken then
        addon.debugf('Event %s %s', guid, unitToken)
        UnitItemLevelByGUID[guid] = C_PaperDollInfo.GetInspectItemLevel(unitToken)
    end
    LastInspectTime = 0
end

local function NotAlreadyInspected(guid)
    return UnitItemLevelByGUID[guid] == nil
end

local function Tick()
    if InCombatLockdown() or UnitIsDead('player') then
        addon.debugf('Cancelling due to combat or dead')
        PendingInspect = {}
        ticker:Cancel()
        ticker = nil
        return
    end

    -- addon.debugf('Tick A %d %s', #PendingInspect, tostring(PendingInspect[1]))

    PendingInspect = tFilter(PendingInspect, NotAlreadyInspected, true)

    -- addon.debugf('Tick B %d %s', #PendingInspect, tostring(PendingInspect[1]))

    local unitToken

    while PendingInspect[1] do
        unitToken = GroupTokenFromGUID(PendingInspect[1])
        if unitToken then
            break
        else
            -- addon.debugf('Clean pending %s', PendingInspect[1])
            table.remove(PendingInspect, 1)
        end
    end

    -- addon.debugf('Tick C %d %s', #PendingInspect, tostring(PendingInspect[1]))

    if not PendingInspect[1] then
        addon.debugf('Cancelling due to nothing left to do')
        ticker:Cancel()
        ticker = nil
        return
    end

    -- It's not clear how long you should wait for an inspect result
    -- before requesting again. You might get stuck in an infinite loop
    -- if requesting aborts the previous response. Further complication
    -- is you can only have one pending NotifyInspect() at a time, and
    -- if something else (e.g. Details, Inspect Frame) runs one then ours
    -- will be lost.
    local sinceLastInspect = GetTime() - LastInspectTime
    if sinceLastInspect > 2 then
        addon.debugf('Scheduling %s %d', unitToken, sinceLastInspect)
        LastInspectTime = GetTime()
        NotifyInspect(unitToken)
    end
end

local function ScanParty()
    if InCombatLockdown() then
        return
    end

    local playerGUID = GetPlayerGuid()
    local _, playerItemLevel = GetAverageItemLevel()
    UnitItemLevelByGUID[playerGUID] = math.floor(playerItemLevel+0.5)
    PendingInspect = {}
    for unitToken in addon.IterateGroupMembers() do
        local guid = UnitGUID(unitToken)
        if guid and not UnitItemLevelByGUID[guid] then
            table.insert(PendingInspect, guid)
        end
    end
    if next(PendingInspect) then
        ticker = ticker or C_Timer.NewTicker(0.1, Tick)
    end
end

local function GUIDILevelSort(a, b)
    return UnitItemLevelByGUID[a] > UnitItemLevelByGUID[b]
end

local function PrintLow()
    local guidList = {}
    local total = 0

    for unitToken in addon.IterateGroupMembers() do
        local guid = UnitGUID(unitToken)
        if guid and UnitItemLevelByGUID[guid] then
            total = total + UnitItemLevelByGUID[guid]
            table.insert(guidList, guid)
        end
    end

    if #guidList == 0 then return end

    local mean = total / #guidList

    table.sort(guidList, GUIDILevelSort)

    for _, guid in ipairs(guidList) do
        local ilevel = UnitItemLevelByGUID[guid]
        if ilevel < mean - 5 then
            local name = UnitNameFromGUID(guid)
            addon.printf("%s ilevel %s", name, ilevel)
        end
    end
end

local function PrintAll()
    local guidList = {}

    for unitToken in addon.IterateGroupMembers() do
        local guid = UnitGUID(unitToken)
        if guid and UnitItemLevelByGUID[guid] then
            table.insert(guidList, guid)
        end
    end

    table.sort(guidList, GUIDILevelSort)

    for _, guid in ipairs(guidList) do
        local ilevel = UnitItemLevelByGUID[guid]
        local name = UnitNameFromGUID(guid)
        addon.printf("%s ilevel %s", name, ilevel)
    end
end

local function Dump()
    for guid, ilevel in pairs(UnitItemLevelByGUID) do
        addon.printf("%s = %s", guid, ilevel)
    end
end

local function Initialize()
    EventRegistry:RegisterFrameEventAndCallback("INSPECT_READY", INSPECT_READY)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_FORMED", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_JOINED", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_LEFT", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("READY_CHECK", PrintLow)
    if IsInGroup() then
        ScanParty()
    end
end

local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ["i-scan"] = ScanParty,
        ["i-low"] = PrintLow,
        ["i-print"] = PrintAll,
        ["i-dump"] = Dump,
    }
}

addon.RegisterModule(moduleInfo)
