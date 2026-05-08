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

local UnitMarkerTexts = {
    [1]     = "{star}",
    [2]     = "{circle}",
    [3]     = "{diamond}",
    [4]     = "{triangle}",
    [5]     = "{moon}",
    [6]     = "{square}",
    [7]     = "{cross}",
    [8]     = "{skull}",
}

-- This is compatible with FocusKick for compatibility, the marker used
-- is your position in the name-sorted list of party members.

local function GetMyMark()
    local playerName = UnitName('player')
    local names = { playerName }
    for i = 1, 4 do
        local unit = 'party'..i
        local name = UnitName('party'..i)
        if UnitExists(unit) then
            table.insert(names, UnitName(unit))
        end
    end
    table.sort(names)
    local markIndex = tIndexOf(names, playerName)
    return markIndex, UnitMarkerTexts[markIndex]
end

local function IsFocusTargetMarkerMacro(body)
    if body and
       (body:find(SLASH_FOCUS1) or body:find(SLASH_FOCUS2)) and
       (body:find(SLASH_TARGETMARKER1) or body:find(SLASH_TARGETMARKER2)) then
        return true
    else
        return false
    end
end

local function UpdateMacro(macroIndex, body, markIndex)
    local lines = {}
    for line in body:gmatch('([^\r\n]+)') do
        line = line:gsub('^('..SLASH_TARGETMARKER1..'%s+.*)(%d)$', '%1'..markIndex)
        line = line:gsub('^('..SLASH_TARGETMARKER2..'%s+.*)(%d)$', '%1'..markIndex)
        table.insert(lines, line)
    end
    EditMacro(macroIndex, nil, nil, string.join('\n', lines))
end

local function UpdateAllMacros(markIndex)
    for macroIndex = 1, MAX_ACCOUNT_MACROS+MAX_CHARACTER_MACROS do
        local _, _, body = GetMacroInfo(macroIndex)
        if IsFocusTargetMarkerMacro(body) then
            UpdateMacro(macroIndex, body, markIndex)
        end
    end
end

local function OnEvent(_ownerID, event)
    local markIndex, markText = GetMyMark()
    local msg = 'Interrupting '..markText
    if event == 'GROUP_ROSTER_UPDATE' then
        addon.printf(C_ChatInfo.ReplaceIconAndGroupExpressions(msg))
        UpdateAllMacros(markIndex)
    elseif event == 'READY_CHECK' then
        SendChatMessage(msg, "PARTY")
    end
end

EventRegistry:RegisterFrameEventAndCallback('GROUP_ROSTER_UPDATE', OnEvent)
EventRegistry:RegisterFrameEventAndCallback('READY_CHECK', OnEvent)
