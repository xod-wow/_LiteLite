local _, addon = ...

local VoidCacheItems = {
--  [itemID] =  { itemContext, treasureContextLevel }

    -- Raid
    [268459] =  { 16, 10 },     -- Imperator Averzian
    [268460] =  { 16, 10 },     -- Vorasius
    [268461] =  { 16, 10 },     -- Fallen-King Salhadaar
    [268462] =  { 16, 10 },     -- Vaelgor & Ezzorak
    [248463] =  { 16, 10 },     -- Lightblinded Vanguard
    [267488] =  { 16, 10 },     -- Crown of the Cosmos
    [268464] =  { 16, 10 },     -- Chimaerus the Undreamt God
    [268458] =  { 16, 10 },     -- Belo'ren, Child of Al'ar
    [262658] =  { 16, 10 },     -- Midnight Falls

    -- M+
    [268465] =  { 16, 10 },     -- Algeth'ar Academy
    [268466] =  { 16, 10 },     -- Magister's Terrace
    [268473] =  { 16, 10 },     -- Maisara Caverns
    [268467] =  { 16, 10 },     -- Nexus-Point Xenas
    [268468] =  { 16, 10 },     -- Pit of Saron
    [268469] =  { 16, 10 },     -- Seat of the Triumvirate
    [268470] =  { 16, 10 },     -- Skyreach
    [268471] =  { 16, 10 },     -- Windrunner Spire

    -- World
    [269768] =  { 55, 0 },      -- Prey
    [268969] =  { 108, 11 },    -- Delves
}

-- ttInfo = C_TooltipInfo.GetItemByID(itemID, nil, itemContext, treasureContextLevel)
--
-- M+
--  itemContext = 16
--  treasureContextLevel = keystone level
--
-- Raid
--  itemContext
--
-- Prey
--  itemContext = 55
--  treasureContextLevel = 0
--
-- Delves
--  itemContext = 108
--  treasureContextLevel = delve level
--

local function GetTooltipItems(ttInfo)
    local inItems = false
    local items = {}
    for _, line in ipairs(ttInfo.lines) do
        if line.leftText == PUNCH_LIST_ITEM_CACHE_TOOLTIP then
            inItems = true
        elseif inItems then
            table.insert(items, line.leftText:sub(3))
        end
    end
    local i = 0
    return function () i = i + 1 return items[i] end
end

local function GetNumTooltipItemLines(ttInfo)
    local inItems = false
    local itemLineCount = 0

    if ttInfo and ttInfo.lines then
        for _, line in ipairs(ttInfo.lines) do
            if line.leftText == PUNCH_LIST_ITEM_CACHE_TOOLTIP then
                inItems = true
            elseif inItems then
                itemLineCount = itemLineCount + 1
            end
        end
    end
    if inItems then
        return itemLineCount
    end
end

local function AddTooltipItems(name, ttInfo)
    for item in GetTooltipItems(ttInfo) do
        _LiteLiteTable:AddRow({ name, item })
    end
end

local pending = {}

local function ProcessOneItem(item, ttInfo)
    local name = item:GetItemName():gsub('Nebulous Voidcache: ', '')
    AddTooltipItems(name, ttInfo)
end

local Scanner = CreateFrame('Frame')

local currentItem, currentItemLines

local elapsedWait = 0

function Scanner:OnUpdate(elapsed)
    elapsedWait = elapsedWait - elapsed
    if elapsedWait > 0 then return else elapsedWait = 0.05 end

    if not currentItem then
        currentItem = table.remove(pending)
        currentItemLines = nil
    end

    if not currentItem then
        _LiteLiteTable:SetFooter()
        self:SetScript('OnUpdate', nil)
        return
    end

    local item, context, treasureContext = unpack(currentItem)
    _LiteLiteTable:SetFooter(item:GetItemName())
    local ttInfo = C_TooltipInfo.GetItemByID(item:GetItemID(), nil, context, treasureContext)
    local itemLines = GetNumTooltipItemLines(ttInfo)
    if itemLines and itemLines == currentItemLines then
        ProcessOneItem(item, ttInfo)
        currentItem = nil
    else
        currentItemLines = itemLines
    end
end

function Scanner:ListRerolls()
    _LiteLiteTable:Reset()
    _LiteLiteTable:SetAutoWidth(true)
    _LiteLiteTable:Setup("Nebulous Voidcache", { "Reroll", "Item" })

    currentItem, currentItemLines = nil, nil

    for itemID, ctx in pairs(VoidCacheItems) do
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(
            function ()
                table.insert(pending, { item, unpack(ctx) })
                self:SetScript('OnUpdate', self.OnUpdate)
            end)
    end
    _LiteLiteTable:SetSortColumn(1, 2)
    _LiteLiteTable:SetEnableSort(true)
    _LiteLiteTable:Show()
end

local moduleInfo = {
    HelpLines = {
        "nebulous-void-cache",
    },
    SlashCommands = {
        ['nebulous-void-cache'] = function () Scanner:ListRerolls() end,
        ['nvc'] = function () Scanner:ListRerolls() end,
        ['rerolls'] = function () Scanner:ListRerolls() end
    }
}
addon.RegisterModule(moduleInfo)
