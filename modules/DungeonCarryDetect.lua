local _, addon = ...

local MAX_PARTY_MEMBERS, MAX_RAID_MEMBERS = MAX_PARTY_MEMBERS, MAX_RAID_MEMBERS

local UnitItemLevelByGUID = {}
local PendingInspect = {}
local LastInspectTime = 0
local ticker

local function IterateGroupMembers()
    local i = 0
    local n, prefix
    if IsInRaid() then
        prefix, n = 'raid', MAX_RAID_MEMBERS
    else
        prefix, n = 'party', MAX_PARTY_MEMBERS
    end
    return function ()
        while true do
            i = i + 1
            if i > n then
                return nil
            end
            local unitToken = prefix..i
            if UnitExists(unitToken) then
                return unitToken
            end
        end
    end
end

-- UnitTokenFromGUID doesn't work in instances?

local function GroupTokenFromGUID(guid)
    -- No need for UnitExists, UnitGUID will just be nil
    for unitToken in IterateGroupMembers() do
        if UnitGUID(unitToken) == guid then
            return unitToken
        end
    end
end

local function INSPECT_READY(_owner, guid)
    local unitToken = GroupTokenFromGUID(guid)
    -- addon.printf('Event %s %s', guid, unitToken)
    if unitToken then
        UnitItemLevelByGUID[guid] = C_PaperDollInfo.GetInspectItemLevel(unitToken)
    end
    LastInspectTime = 0
end

local function Tick()
    -- addon.printf('Tick %d', #PendingInspect)

    if InCombatLockdown() or UnitIsDead('player') then
        -- addon.printf('Cancelling due to combat or dead')
        PendingInspect = {}
        ticker:Cancel()
        ticker = nil
        return
    end

    while PendingInspect[1] and UnitItemLevelByGUID[PendingInspect[1]] do
        local guid = table.remove(PendingInspect, 1)
        local ilevel = UnitItemLevelByGUID[guid]
        local name = UnitNameFromGUID(guid)
        addon.printf("%s ilevel %s", name, ilevel)
    end

    local unitToken

    while PendingInspect[1] do
        unitToken = GroupTokenFromGUID(PendingInspect[1])
        -- addon.printf('Clean pending %s=%s', PendingInspect[1], tostring(unitToken))
        if unitToken then
            break
        else
            table.remove(PendingInspect, 1)
        end
    end

    if not PendingInspect[1] then
        -- addon.printf('Cancelling due to nothing left to do')
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
        -- addon.printf('Scheduling %s %d', unitToken, sinceLastInspect)
        LastInspectTime = GetTime()
        NotifyInspect(unitToken)
    end
end

local function ScanParty()
    local playerGUID = GetPlayerGuid()
    local _, playerItemLevel = GetAverageItemLevel()
    UnitItemLevelByGUID[playerGUID] = playerItemLevel
    PendingInspect = {}
    for unitToken in IterateGroupMembers() do
        local guid = UnitGUID(unitToken)
        if guid and not UnitItemLevelByGUID[gid] then
            table.insert(PendingInspect, UnitGUID(unitToken))
        end
    end
    if next(PendingInspect) then
        ticker = ticker or C_Timer.NewTicker(0.1, Tick)
    end
end

local function PrintParty()
    for unitToken in IterateGroupMembers() do
        local guid = UnitGUID(unitToken)
        if guid and UnitItemLevelByGUID[guid] then
            local ilevel = UnitItemLevelByGUID[guid]
            local name = UnitNameFromGUID(guid)
            addon.printf("%s ilevel %s", name, ilevel)
        end
    end
end

local function Initialize()
    EventRegistry:RegisterFrameEventAndCallback("INSPECT_READY", INSPECT_READY)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_FORMED", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_JOINED", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_LEFT", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("GROUP_ROSTER_UPDATE", ScanParty)
    EventRegistry:RegisterFrameEventAndCallback("READY_CHECK", PrintParty)
end

local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ["party-scan"] = ScanParty,
        ["party-ilevel"] = PrintParty,
    }
}

addon.RegisterModule(moduleInfo)
