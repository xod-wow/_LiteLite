-- /tinspect but in a scrolling big window

local _, addon = ...

-- Relies on LM.TableToString from LiteMount

local function TableInspect(data)
    if not LM then return end
    local text = LM.TableToString(data)
    _LiteLiteText.EditBox:SetText(text)
    _LiteLiteText:Show()
end

local function TableInspectEval(cmd)
    local f = loadstring('return ' .. cmd)
    if f then
        local data = f()
        TableInspect(data)
    end
end

local moduleInfo = {
    SlashCommands = {
        ['tinspect'] = TableInspectEval,
    }
}
addon.RegisterModule(moduleInfo)
