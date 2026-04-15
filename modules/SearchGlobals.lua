
local _, addon = ...

local function SearchGlobalKeys(text)
    if not text then return end

    text = text:lower()

    addon.printf("Searching global keys for %s", tostring(text))

    local lines = {}
    for k, v in pairs(_G) do
        if type(k) == 'string' then
            local allowPattern = text:sub(1,1) == '^' or text:sub(-1) == '$'
            if k:lower():find(text, nil, not allowPattern) then
                table.insert(lines, string.format("%s = %s", k, tostring(v)))
            end
        end
    end

    table.sort(lines)
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

local function SearchGlobalValues(text)
    if not text then return end

    text = text:lower()

    addon.printf("Searching global values for %s", tostring(text))

    local lines = {}
    for k, v in pairs(_G) do
        if type(k) == 'string' and type(v) == 'string' then
            local allowPattern = text:sub(1,1) == '^' or text:sub(-1) == '$'
            if v:lower():find(text, nil, not allowPattern) then
                table.insert(lines, string.format("%s = %s", k, tostring(v)))
            end
        end
    end
    table.sort(lines)
    _LiteLiteText.EditBox:SetText(table.concat(lines, "\n"))
    _LiteLiteText:Show()
end

local moduleInfo = {
    SlashCommands = {
        ['gkeys'] = SearchGlobalKeys,
        ['gvals'] = SearchGlobalValues,
    }
}
addon.RegisterModule(moduleInfo)
