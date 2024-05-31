local InventorySlotTable = {
    [INVSLOT_AMMO]      = AMMOSLOT,
    [INVSLOT_HEAD]      = HEADSLOT,
    [INVSLOT_NECK]      = NECKSLOT,
    [INVSLOT_SHOULDER]  = SHOULDERSLOT,
    [INVSLOT_BODY]      = SHIRTSLOT,
    [INVSLOT_CHEST]     = CHESTSLOT,
    [INVSLOT_WAIST]     = WAISTSLOT,
    [INVSLOT_WRIST]     = WRISTSLOT,
    [INVSLOT_HAND]      = HANDSSLOT,
    [INVSLOT_LEGS]      = LEGSSLOT,
    [INVSLOT_FEET]      = FEETSLOT,
    [INVSLOT_FINGER1]   = FINGER0SLOT .. " 1",
    [INVSLOT_FINGER2]   = FINGER1SLOT .. " 2",
    [INVSLOT_TRINKET1]  = TRINKET0SLOT .. " 1",
    [INVSLOT_TRINKET2]  = TRINKET1SLOT .. " 2",
    [INVSLOT_BACK]      = BACKSLOT,
    [INVSLOT_MAINHAND]  = MAINHANDSLOT,
    [INVSLOT_OFFHAND]   = SECONDARYHANDSLOT,
    [INVSLOT_RANGED]    = RANGEDSLOT,
    [INVSLOT_TABARD]    = TABARDSLOT,
}

-- One of each kind, to pull the tooltip line and use it to match them all
local ExampleSocketGems = {
    [218005]    = "EMPTY_SOCKET_COGWHEEL",
    [220211]    = "EMPTY_SOCKET_META",
    [211101]    = "EMPTY_SOCKET_PRISMATIC",
    [216627]    = "EMPTY_SOCKET_TINKER",
}

local GemSocketSortOrder = {
    ["EMPTY_SOCKET_META"]           = 1,
    ["EMPTY_SOCKET_COGWHEEL"]       = 3,
    ["EMPTY_SOCKET_TINKER"]         = 2,
    ["EMPTY_SOCKET_PRISMATIC"]      = 4,
}

PandaGemCombineAllMixin = {}

function PandaGemCombineAllMixin:OnLoad()
    self:RegisterForClicks("AnyDown")
    self:SetAttribute("pressAndHoldAction", 1)
end

function PandaGemCombineAllMixin:Update()
    local parent = self:GetParent()
    self:Disable()
    for _, info in ipairs(parent.bags) do
        local _, spellID = C_Item.GetItemSpell(info.link)
        if spellID and info.stackCount and info.stackCount >= 3 then
            self:SetAttribute("type", "item")
            self:SetAttribute("item", info.name)
            self:Enable()
            return
        end
    end
end

PandaGemEntryMixin = {}

function PandaGemEntryMixin:OnLoad()
    self.Combine:RegisterForClicks("AnyDown")
    self.Combine:SetAttribute("pressAndHoldAction", 1)
    self:RegisterForClicks("AnyDown")
    self:SetAttribute("pressAndHoldAction", 1)
end

function PandaGemEntryMixin:OnShow()
    self:SetWidth(self:GetParent():GetWidth())
end

function PandaGemEntryMixin:OnEnter()
    if self.info.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.info.link)
        GameTooltip:Show()
    end
end

function PandaGemEntryMixin:OnLeave()
    GameTooltip_Hide()
end

function PandaGemEntryMixin:OnClick()
    if IsModifiedClick("CHATLINK") then
        ChatEdit_LinkItem(self.info.link)
    end
end

PandaGemMixin  = {}

function PandaGemMixin:BuildSocketTypeTable()
    self.SocketTypeTable = {}
    for gemItemID, gemSocketType in pairs(ExampleSocketGems) do
        local item = Item:CreateFromItemID(gemItemID)
        item:ContinueOnItemLoad(
            function ()
                local tt = C_TooltipInfo.GetItemByID(item:GetItemID())
                if not tt or not tt.lines then  
                    print(gemItemID, item:GetItemName(), item:GetItemLink())
                else
                    local socketText = tt.lines[2].leftText:gsub("|c........(.*)|r", "%1")
                    self.SocketTypeTable[socketText] = gemSocketType
                end
            end)
    end
end

local function InitGemButtonBags(button, info)
    button.info = info
    button.Stripe:SetShown(info.index % 2 == 1)
    button.Text:SetText(format("%s (%d)", info.nameWithQuality, info.stackCount))
    button.Icon:SetTexture(info.icon)

    button.Combine:Hide()
    local _, spellID = C_Item.GetItemSpell(info.link)
    if spellID and info.stackCount and info.stackCount >= 3 then
        button.Combine:SetAttribute("type", "item")
        button.Combine:SetAttribute("item", info.name)
        button.Combine:Show()
    end

    local equipmentSlot, gemSocketIndex = PandaGem:FindSocketForGem(info)
    if equipmentSlot then
        button:SetScript('PreClick',
            function ()
                SocketInventoryItem(equipmentSlot)
                C_Container.PickupContainerItem(info.bag, info.slot)
                ClickSocketButton(gemSocketIndex)
                AcceptSockets()
                CloseSocketInfo()
            end)
        button:SetAttribute("type", nil)
    else
        button:SetScript('PreClick', nil)
        button:SetAttribute("type", nil)
    end
end

local function InitGemButtonEquipped(button, info)
    button.info = info
    button.Stripe:SetShown(info.index % 2 == 1)

    if info.name then
        button.Text:SetText(format("%s - %s", info.equipmentSlotName, info.nameWithQuality))
        button.Icon:SetTexture(info.icon)
        button.Icon:Show()
        button:SetScript('PreClick', function () SocketInventoryItem(info.equipmentSlot) end)
        button:SetScript('PostClick', function () CloseSocketInfo() end)
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", format("/cast Extract Gem\n/click ItemSocketingSocket%d", info.gemSocketIndex))
    else
        button.Text:SetText(format("%s - %s", info.equipmentSlotName, _G[info.gemSocketType]))
        button.Icon:Hide()
        button:SetScript('PreClick', nil)
        button:SetScript('PostClick', nil)
        button:SetAttribute("type", nil)
    end
end

function PandaGemMixin:FindSocketForGem(gemInfo)
    for _, socketInfo in ipairs(self.freeGemSockets) do
        if socketInfo.gemSocketType == gemInfo.gemSocketType then
            return socketInfo.equipmentSlot, socketInfo.gemSocketIndex
        end
    end
end

-- Items can be evicted from the cache at any second so we have to grab all
-- the fields we are going to use now and stash them away.

function PandaGemMixin:AddGemInfo(info, item)
    info.name = item:GetItemName()
    info.color = item:GetItemQualityColor().color
    info.quality = item:GetItemQuality()
    info.nameWithQuality = info.color:WrapTextInColorCode(info.name)
    info.link = item:GetItemLink()
    info.icon = item:GetItemIcon()

    -- Gems that are inside sockets don't have ItemLocation or stack
    info.stackCount = item:HasItemLocation() and item:GetStackCount()
    info.maxStackSize = item:GetItemMaxStackSize()

    local _, spellID = C_Item.GetItemSpell(info.link)
    info.spellID = spellID

    local tt = C_TooltipInfo.GetHyperlink(item:GetItemLink())
    local socketText = tt.lines[2].leftText:gsub("|c........(.*)|r", "%1")
    info.gemSocketType = self.SocketTypeTable[socketText]
end

function PandaGemMixin:RefreshBagsData()
    self.bags = {}
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = Item:CreateFromBagAndSlot(bag, slot)
            local info = {
                bag = bag,
                slot = slot,
            }
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(
                    function ()
                        local link = item:GetItemLink()
                        local classId, subClassId = select(6, C_Item.GetItemInfoInstant(link))
                        if classId == 3 and subClassId == 9 then
                            self:AddGemInfo(info, item)
                            table.insert(self.bags, info)
                            self.needsUpdate = true
                        end
                    end)
            end
        end
    end
end

function PandaGemMixin:AddEquippedItem(equippedItem)
    local equippedItemLink = equippedItem:GetItemLink()
    local stats = C_Item.GetItemStats(equippedItemLink)
    local equipmentSlot = equippedItem:GetItemLocation():GetEquipmentSlot()
    for stat, count in pairs(stats) do
        if stat:find("EMPTY_SOCKET") then
            for i = 1, count do
                local info = {
                    equipmentSlot = equipmentSlot,
                    equipmentSlotName = InventorySlotTable[equipmentSlot],
                    gemSocketType = stat,   -- Needed here for sockets
                    gemSocketIndex = i,
                }
                -- GetItemGem has cache chicken-and-egg problem, lookup by ID
                local gemID = C_Item.GetItemGemID(equippedItemLink, i)
                if gemID then
                    local item = Item:CreateFromItemID(gemID)
                    item:ContinueOnItemLoad(
                        function ()
                            self:AddGemInfo(info, item)
                            table.insert(self.equipped, info)
                            self.needsUpdate = true
                        end)
                else
                    table.insert(self.freeGemSockets, info)
                    table.insert(self.equipped, info)
                    self.needsUpdate = true
                end
            end
        end
    end
end

function PandaGemMixin:RefreshEquippedData()
    self.equipped = {}
    self.freeGemSockets = {}
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local item = Item:CreateFromEquipmentSlot(slot)
        if not item:IsItemEmpty() then
            item:ContinueOnItemLoad(
                function ()
                    self:AddEquippedItem(item)
                    self.needsUpdate = true
                end)
        end
    end
end

local function CompareGem(a, b)
    if GemSocketSortOrder[a.gemSocketType] ~= GemSocketSortOrder[b.gemSocketType] then
        return GemSocketSortOrder[a.gemSocketType] < GemSocketSortOrder[b.gemSocketType]
    end

    local aCombine = a.spellID and a.stackCount and a.stackCount >= 3
    local bCombine = b.spellID and b.stackCount and b.stackCount >= 3

    if aCombine and not bCombine then
        return true
    elseif not aCombine and bCombine then
        return false
    end

    if a.quality ~= b.quality then
        return a.quality > b.quality
    end

    return a.name < b.name
end

local function CompareEquipped(a, b)
    if GemSocketSortOrder[a.gemSocketType] ~= GemSocketSortOrder[b.gemSocketType] then
        return GemSocketSortOrder[a.gemSocketType] < GemSocketSortOrder[b.gemSocketType]
    end
    if a.equipmentSlot ~= b.equipmentSlot then
        return a.equipmentSlot < b.equipmentSlot
    end
    return a.gemSocketIndex < b.gemSocketIndex
end

function PandaGemMixin:RefreshData()
    self:RefreshBagsData()
    self:RefreshEquippedData()
    table.sort(self.bags, CompareGem)
    table.sort(self.equipped, CompareEquipped)
end

function PandaGemMixin:Update()
    for index, info in ipairs(self.bags) do info.index = index end
    for index, info in ipairs(self.equipped) do info.index = index end
    local dataProvider = CreateDataProvider(self.bags)
    self.BagsScroll:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    dataProvider = CreateDataProvider(self.equipped)
    self.EquippedScroll:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    self.CombineAll:Update()
end

function PandaGemMixin:OnLoad()
    self:SetTitle("Panda Gem")
    ButtonFrameTemplate_HidePortrait(self)
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("PandaGemEntryTemplate", InitGemButtonBags)
    -- view:SetPadding(2,2,2,2,5);
    ScrollUtil.InitScrollBoxListWithScrollBar(self.BagsScroll, self.BagsScrollBar, view);
    view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("PandaGemEntryTemplate", InitGemButtonEquipped)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.EquippedScroll, self.EquippedScrollBar, view);
    table.insert(UISpecialFrames, self:GetName())
    self:RegisterEvent('PLAYER_LOGIN')
end

function PandaGemMixin:Initialize()
    self.bags = {}
    self.equipped = {}
    self.freeGemSockets = {}
    self:BuildSocketTypeTable()
end

function PandaGemMixin:OnShow()
    self:RegisterEvent('BAG_UPDATE_DELAYED')
    self:RefreshData()
    self:Update()
end

function PandaGemMixin:OnHide()
    self:UnregisterEvent('BAG_UPDATE_DELAYED')
    self.needsUpdate = nil
    self.needsRefresh = nil
end

function PandaGemMixin:OnEvent(event, ...)
    if event == 'PLAYER_LOGIN' then
        self:Initialize()
    else
        self.needsRefresh = true
        self.needsUpdate = true
    end
end

function PandaGemMixin:OnUpdate()
    if self.needsRefresh then
        self:RefreshData()
        self.needsRefresh = nil
    end
    if self.needsUpdate then
        self:Update()
        self.needsUpdate = nil
    end
end

function PandaGemMixin:OnDragStart()
    self:StartMoving()
end

function PandaGemMixin:OnDragStop()
    self:StopMovingOrSizing()
end
