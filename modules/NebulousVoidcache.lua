local _, addon = ...

local VoidCacheItems = {
--  [itemID] =  { itemContext, treasureContextLevel }

    -- Raid
    [278283] =  { 6 },     -- Entombed Sentinels
    [286019] =  { 6 },     -- Kith'ix
    [274708] =  { 6 },     -- Nymrissa Wavecaller
    [278285] =  { 6 },     -- Soulcoiler Nek'zali
    [278288] =  { 6 },     -- Sszorak
    [278290] =  { 6 },     -- The Coiled Altar
    [278289] =  { 6 },     -- The Twin Fangs
    [278286] =  { 6 },     -- Tortollan Explorers
    [278284] =  { 6 },     -- Ula'tek
    [278287] =  { 6 },     -- Vashnik

    -- M+
    [279618] =  { 16, 10 },     -- Altar of Fangs
    [279620] =  { 16, 10 },     -- Den of Nalorakk
    [279621] =  { 16, 10 },     -- Kings' Rest
    [279623] =  { 16, 10 },     -- Murder Row
    [279622] =  { 16, 10 },     -- Ruby Life Pools
    [279624] =  { 16, 10 },     -- Temple of Sethraliss
    [279619] =  { 16, 10 },     -- The Blinding Vale
    [279625] =  { 16, 10 },     -- Voidscar Arena

    -- World
    -- [280131] =  { 55, 0 },      -- Prey
    -- [279284] =  { 108, 11 },    -- Delves
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
        "void-cache",
    },
    SlashCommands = {
        ['void-cache'] = function () Scanner:ListRerolls() end,
        ['vc'] = function () Scanner:ListRerolls() end,
        ['rerolls'] = function () Scanner:ListRerolls() end
    }
}
addon.RegisterModule(moduleInfo)
