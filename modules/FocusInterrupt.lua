local _, addon = ...

--[[

    This is expecting you have a macro like this

        /focus [@unit]
        /tm [@focus] 1

    Or maybe an all in one kick macro like this

        #showtooltip Spear Hand Strike
        /focus [mod:alt,@mouseover]
        /tm [@focus,mod:alt] 1
        /stopmacro [mod:alt]
        /cast [@focus,harm] Spear Hand Strike; Spear Hand Strike

    If it finds a macro with both "/focus" and "/tm" or "/targetmarker" it
    will replace the number with an appropriate number based on the players
    in your party.

]]

-- This is compatible with FocusKick. The marker used is your position in the
-- name-sorted list of party members.

local function HasInterrupt()
    local spec = GetSpecialization()
    if GetSpecializationRole(spec) ~= "HEALER" then
        return true
    elseif UnitClassBase('player') == 'SHAMAN' then
        return true
    else
        return false
    end
end

local currentMark

local function GetMyMark()
    local playerName = UnitName('player')
    local names = { playerName }
    for i = 1, 4 do
        local unit = 'party'..i
        if UnitExists(unit) then
            local name = UnitName(unit)
            table.insert(names, name)
        end
    end
    table.sort(names)
    local markIndex = tIndexOf(names, playerName)
    return markIndex, string.format('{rt%d}', markIndex)
end

local function IsFocusTargetMarkerMacro(body)
    if body
       and
       (body:find(SLASH_FOCUS1) or body:find(SLASH_FOCUS2))
       and
       (body:find(SLASH_TARGET_MARKER1) or
        body:find(SLASH_TARGET_MARKER2) or
        body:find(SLASH_TARGET_MARKER3) or
        body:find(SLASH_TARGET_MARKER4))
    then
        return true
    else
        return false
    end
end

local function UpdateMacro(macroIndex, body, markIndex)
    local lines = {}
    for line in body:gmatch('([^\r\n]+)') do
        line = line:gsub('^('..SLASH_TARGET_MARKER1..'%s+.*)(%d)$', '%1'..markIndex)
        line = line:gsub('^('..SLASH_TARGET_MARKER2..'%s+.*)(%d)$', '%1'..markIndex)
        line = line:gsub('^('..SLASH_TARGET_MARKER3..'%s+.*)(%d)$', '%1'..markIndex)
        line = line:gsub('^('..SLASH_TARGET_MARKER4..'%s+.*)(%d)$', '%1'..markIndex)
        table.insert(lines, line)
    end
    local newBody = table.concat(lines, '\n')
    EditMacro(macroIndex, nil, nil, newBody)
end

local function UpdateAllMacros(markIndex)
    for macroIndex = 1, MAX_ACCOUNT_MACROS+MAX_CHARACTER_MACROS do
        local _, _, body = GetMacroInfo(macroIndex)
        if IsFocusTargetMarkerMacro(body) then
            UpdateMacro(macroIndex, body, markIndex)
        end
    end
end

local function IsActive()
    return HasInterrupt() and not IsInRaid() and IsInGroup(LE_PARTY_CATEGORY_HOME)
end

local function NotifyMark()
    if IsActive() then
        local markIndex, markText = GetMyMark()
        local msg = string.format('Interrupting %s', markText)
        SendChatMessage(msg, "PARTY")
    end
end

local function UpdateMarkMacros()
    if IsActive() then
        local markIndex, markText = GetMyMark()
        if currentMark ~= markIndex and not InCombatLockdown() then
            markText = C_ChatInfo.ReplaceIconAndGroupExpressions(markText)
            addon.printf("Changing interrupt marker to %s", markText)
            UpdateAllMacros(markIndex)
            currentMark = markIndex
        end
    end
end

local function Initialize()
    EventRegistry:RegisterFrameEventAndCallback('GROUP_ROSTER_UPDATE', UpdateMarkMacros)
    EventRegistry:RegisterFrameEventAndCallback('READY_CHECK', NotifyMark)
end

local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ['focus-interrupt'] = UpdateMarkMacros,
    }
}
addon.RegisterModule(moduleInfo)

