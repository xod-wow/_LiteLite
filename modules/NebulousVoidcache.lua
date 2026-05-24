local _, addon = ...

local VoidCacheItemIDs = {
   268465, -- Algeth'ar Academy
   268458, -- Belo'ren, Child of Al'ar
   268464, -- Chimaerus the Undreamt God
   267488, -- Crown of the Cosmos
   268461, -- Fallen-King Salhadaar
   268459, -- Imperator Averzian
   248463, -- Lightblinded Vanguard
   268466, -- Magister's Terrace
   268473, -- Maisara Caverns
   262658, -- Midnight Falls
   268467, -- Nexus-Point Xenas
   268468, -- Pit of Saron
   268469, -- Seat of the Triumvirate
   268470, -- Skyreach
   268462, -- Vaelgor & Ezzorak
   268460, -- Vorasius
   268471, -- Windrunner Spire
}

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

local function AddTooltipItems(name, ttInfo)
    for item in GetTooltipItems(ttInfo) do
        _LiteLiteTable:AddRow({ name, item })
    end
end

local pending = {}

local function ProcessOneItem(item)
    local ttInfo = C_TooltipInfo.GetItemByID(item:GetItemID(), nil, 16, 10)
    local name = item:GetItemName():gsub('Nebulous Voidcache: ', '')
    AddTooltipItems(name, ttInfo)
end

local Scanner = CreateFrame('Frame')

function Scanner:OnUpdate()
    self.currentItem = self.currentItem or table.remove(pending)
    if not self.currentItem then
        self:SetScript('OnUpdate', nil)
    else
        local ttInfo = C_TooltipInfo.GetItemByID(self.currentItem:GetItemID(), nil, 16, 10)
        if ttInfo and ttInfo.lines and #ttInfo.lines > 7 then
            ProcessOneItem(self.currentItem)
            self.currentItem = nil
        end
    end
end

function Scanner:ListRerolls()
    _LiteLiteTable:Reset()
    _LiteLiteTable:Setup("Nebulous Voidcache", { "Reroll", "Item" })

    self.currentItem = nil

    for _, itemID in ipairs(VoidCacheItemIDs) do
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(
            function ()
                table.insert(pending, item)
                self:SetScript('OnUpdate', self.OnUpdate)
            end)
    end
    _LiteLiteTable:SetSortColumn(1, 2)
    _LiteLiteTable:SetEnableSort(true)
    _LiteLiteTable:Show()
end

local moduleInfo = {
    HelpLines = {
        "rerolls",
    },
    SlashCommands = {
        ['rerolls'] = function () Scanner:ListRerolls() end
    }
}
addon.RegisterModule(moduleInfo)
