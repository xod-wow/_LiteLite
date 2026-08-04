-- Show how much rest remains numerically

local _, addon = ...

local MAX_LEVEL = GetMaxLevelForExpansionLevel(LE_EXPANSION_LEVEL_CURRENT)

local playerFullName

local function SaveRest()
    local level = UnitLevel('player')
    if level < 20 or level == MAX_LEVEL then
        addon.db.characterRest[playerFullName] = nil
    else
        addon.db.characterRest[playerFullName] = {
            class = select(2, UnitClass('player')),
            amount = GetXPExhaustion() or 0,
            isResting = IsResting(),
            level = level,
            levelXP = UnitXPMax('player'),
            multiplier = IsPlayerSpell(107074) and 2 or 1,
            time = time(),
        }
    end
end

local function CurrentRest(rest)
    -- Earn 10% of current level per 16 hours
    local mult = rest.multiplier * (rest.isResting and 1 or 0.25)
    local n = rest.amount + (time() - rest.time) * mult * rest.levelXP / (10*3600*16)
    return math.min(n, rest.levelXP * 1.5 * rest.multiplier)
end

local function ShowRest()
    SaveRest()
    local rows = {}
    for name, rest in pairs(addon.db.characterRest) do
        local color = C_ClassColor.GetClassColor(rest.class or "") or WHITE_FONT_COLOR
        local r = CurrentRest(rest)
        table.insert(rows,
            {
                color = color,
                name,
                rest.level or 0,
                math.floor(r),
                string.format("%.1f", r == 0 and 0 or 100 * r/rest.levelXP),
                string.format("%.1f", 150 * rest.multiplier),
            })
    end
    _LiteLiteTable:Reset()
    _LiteLiteTable:SetAutoWidth(true)
    _LiteLiteTable:Setup("Character Rest", { "Name", "Level", "Rest", "Rest%", "RestMax" })
    _LiteLiteTable:SetRows(rows)
    _LiteLiteTable:SetEnableSort(true)
    _LiteLiteTable:SetSortColumn(-4)
    _LiteLiteTable:Show()
end

-- GetMessageTypeColor doesn't work on init, even after PLAYER_LOGIN

local function DisplayRest(owner)
    local rest = GetXPExhaustion()
    if not rest or rest == 0 then return end
    local r, g, b = GetMessageTypeColor('COMBAT_XP_GAIN')
    local pct = 100 * rest / UnitXPMax('player')
    local msg = string.format('Rest remaining: %s (%0.1f%%)', AbbreviateNumbers(rest), pct)
    if owner then
        -- From event
        for i = 1, NUM_CHAT_WINDOWS do
            local f = Chat_GetChatFrame(i)
            if tContains(f.messageTypeList, 'COMBAT_XP_GAIN') then
                f:AddMessage(addon.format("%s", msg), r, g, b)
            end
        end
    else
        -- Command line
        SELECTED_CHAT_FRAME:AddMessage(addon.format("%s", msg), r, g, b)
    end
end

local function Initialize()
    playerFullName = string.join('-', UnitFullName('player'))
    addon.db.characterRest = addon.db.characterRest or {}
    EventRegistry:RegisterFrameEventAndCallback('CHAT_MSG_COMBAT_XP_GAIN', DisplayRest)
    -- For some reason GetXPExhuastion() doesn't work at either PLAYER_LOGOUT or
    -- PLAYER_LEAVING_WORLD
    EventRegistry:RegisterFrameEventAndCallback('PLAYER_LOGIN',  SaveRest)
    EventRegistry:RegisterFrameEventAndCallback('UPDATE_EXHAUSTION',  SaveRest)
end


local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ['xp'] = function () DisplayRest() end,
        ['xpp'] = ShowRest,
    }
}

addon.RegisterModule(moduleInfo)
