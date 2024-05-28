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
        if info.location:IsBagAndSlot() then
            local count = info.item:GetStackCount()
            local _, spellID = C_Item.GetItemSpell(info.item:GetItemLink())
            if spellID and count and count >= 3 then
                self:SetAttribute("type", "item")
                self:SetAttribute("item", info.item:GetItemName())
                self:Enable()
                return
            end
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
    if self.item then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.item:GetItemLink())
        GameTooltip:Show()
    end
end

function PandaGemEntryMixin:OnLeave()
    GameTooltip_Hide()
end

function PandaGemEntryMixin:OnClick()
    if IsModifiedClick("CHATLINK") then
        ChatEdit_LinkItem(self.item:GetItemLink())
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
    button.item = info.item
    button.location = info.location
    button.Stripe:SetShown(info.index % 2 == 1)
    local c = info.item:GetItemQualityColor()
    local name = c.color:WrapTextInColorCode(info.item:GetItemName())
    local count = info.item:GetStackCount()
    button.Text:SetText(format("%s (%d)", name, count))
    button.Icon:SetTexture(info.item:GetItemIcon())

    button.Combine:Hide()
    local _, spellID = C_Item.GetItemSpell(info.item:GetItemLink())
    if spellID and count and count >= 3 then
        button.Combine:SetAttribute("type", "item")
        button.Combine:SetAttribute("item", info.item:GetItemName())
        button.Combine:Show()
    end

    local equipmentSlot, gemSocketIndex = PandaGem:FindSocketForGem(info)
    if equipmentSlot then
        local bag, slot = info.location:GetBagAndSlot()
        button:SetScript('PreClick',
            function ()
                SocketInventoryItem(equipmentSlot)
                C_Container.PickupContainerItem(bag, slot)
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
    button.item = info.item
    button.location = info.location
    button.Stripe:SetShown(info.index % 2 == 1)

    local equipmentSlot = info.location:GetEquipmentSlot()
    local equipmentSlotName = InventorySlotTable[equipmentSlot]

    if info.item then
        local c = info.item:GetItemQualityColor()
        local name = c.color:WrapTextInColorCode(info.item:GetItemName())
        button.Text:SetText(format("%s - %s", equipmentSlotName, name))
        button.Icon:SetTexture(info.item:GetItemIcon())
        button.Icon:Show()
        button:SetScript('PreClick', function () SocketInventoryItem(equipmentSlot) end)
        button:SetScript('PostClick', function () CloseSocketInfo() end)
        button:SetAttribute("type", "macro")
        button:SetAttribute("macrotext", format("/cast Extract Gem\n/click ItemSocketingSocket%d", info.gemSocketIndex))
    else
        button.Text:SetText(format("%s - %s", equipmentSlotName, EMPTY))
        button.Icon:Hide()
        button:SetScript('PreClick', nil)
        button:SetScript('PostClick', nil)
        button:SetAttribute("type", nil)
    end
end

function PandaGemMixin:FindSocketForGem(gemInfo)
    for _, socketInfo in ipairs(self.freeGemSockets) do
        if socketInfo.gemSocketType == gemInfo.gemSocketType then
            local equipmentSlot = socketInfo.location:GetEquipmentSlot()
            return equipmentSlot, socketInfo.gemSocketIndex
        end
    end
end

function PandaGemMixin:AddGem(t, info)
    local classId, subClassId = select(6, C_Item.GetItemInfoInstant(info.item:GetItemLink()))
    if classId == 3 and subClassId == 9 then
        local tt = C_TooltipInfo.GetHyperlink(info.item:GetItemLink())
        local socketText = tt.lines[2].leftText:gsub("|c........(.*)|r", "%1")
        info.gemSocketType = self.SocketTypeTable[socketText]
        table.insert(t, info)
    end
end

function PandaGemMixin:RefreshBagsData()
    self.bags = {}
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local info = {
                item = Item:CreateFromBagAndSlot(bag, slot),
                location = ItemLocation:CreateFromBagAndSlot(bag, slot),
            }
            if not info.item:IsItemEmpty() then
                info.item:ContinueOnItemLoad(
                    function ()
                        self:AddGem(self.bags, info)
                        self.needsUpdate = true
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
                    location = equippedItem:GetItemLocation(),
                    gemSocketType = stat,
                    gemSocketIndex = i,
                }
                local gemName, gemLink = C_Item.GetItemGem(equippedItemLink, i)
                if gemName and gemLink then
                    info.item = Item:CreateFromItemLink(gemLink)
                    info.item:ContinueOnItemLoad(
                        function ()
                            self:AddGem(self.equipped, info)
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

    local aStack = a.item:GetItemLocation() and a.item:GetStackCount() or 1
    local bStack = b.item:GetItemLocation() and b.item:GetStackCount() or 1
    local aCombine = (C_Item.GetItemSpell(a.item:GetItemLink()) ~= nil and aStack >= 3)
    local bCombine = (C_Item.GetItemSpell(b.item:GetItemLink()) ~= nil and bStack >= 3)

    if aCombine and not bCombine then
        return true
    elseif not aCombine and bCombine then
        return false
    end

    local aQuality = a.item:GetItemQuality()
    local bQuality = b.item:GetItemQuality()

    if aQuality ~= bQuality then
        return aQuality > bQuality
    end

    return a.item:GetItemName() < b.item:GetItemName()
end

function PandaGemMixin:RefreshData()
    self:RefreshBagsData()
    self:RefreshEquippedData()
    table.sort(self.bags, CompareGem)
    table.sort(self.equipped,
        function (a, b)
            return a.location:GetEquipmentSlot() < b.location:GetEquipmentSlot()
        end)
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
