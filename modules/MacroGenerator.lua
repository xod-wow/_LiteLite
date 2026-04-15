local _, addon = ...

local MouseoverMacroTemplate =
[[#showtooltip {1}
/cast [@mouseover,help,nodead][help,nodead] {1}
/stopspelltarget
]]

local TrinketMacroTemplate =
[[#showtooltip {1}
/use [harm] 13
/use [harm] 14
/cast {1}
]]

local CursorMacroTemplate =
[[#showtooltip {1}
/cast [mod:alt][@cursor] {1}
]]

local PlayerMacroTemplate =
[[#showtooltip {1}
/cast [mod:alt][@player] {1}
]]

local function strtemplate(str, vars, ...)
    -- Can pass {1} {2} etc. as varargs rather than table
    if type(vars) ~= 'table' then
        vars = { vars, ... }
    end

    -- If your key is '1', god help you
    return (string.gsub(
                str,
                "({([^}]+)})",
                function(whole, i) return vars[tonumber(i) or i] or whole end
            ))
end

local function CreateOrEditMacro(macroName, macroText, isLocal)
    local i = GetMacroIndexByName(macroName)
    if i == 0 then
        i = CreateMacro(macroName, 'INV_MISC_QUESTIONMARK', macroText, isLocal)
    else
        EditMacro(i, nil, nil, macroText)
    end
    return i
end

local function CreateSpellMacro(template, spell)
    spell = spell or GameTooltip:GetSpell()
    if not spell then
        return
    end

    local macroName = '_' .. spell
    local macroText = strtemplate(template, spell)
    local i = CreateOrEditMacro(macroName, macroText, true)
    if i then PickupMacro(i) end
end

local moduleInfo = {
    SlashCommands = {
        ['mouseover-macro'] = function (arg) CreateSpellMacro(MouseoverMacroTemplate, arg) end,
        ['trinket-macro'] = function (arg) CreateSpellMacro(TrinketMacroTemplate, arg) end,
        ['cursor-macro'] = function (arg) CreateSpellMacro(CursorMacroTemplate, arg) end,
        ['player-macro'] = function (arg) CreateSpellMacro(PlayerMacroTemplate, arg) end,
    }
}
moduleInfo.SlashCommands['mm'] = moduleInfo.SlashCommands['mouseover-macro']
moduleInfo.SlashCommands['tm'] = moduleInfo.SlashCommands['trinket-macro']
moduleInfo.SlashCommands['cm'] = moduleInfo.SlashCommands['cursor-macro']
moduleInfo.SlashCommands['pm'] = moduleInfo.SlashCommands['player-macro']

addon.RegisterModule(moduleInfo)
