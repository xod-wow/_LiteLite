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


--[[----------------------------------------------------------------------------]]--

PandaGemCombineAllMixin = {}

function PandaGemCombineAllMixin:OnLoad()
    self:RegisterForClicks("AnyDown")
    self:SetAttribute("pressAndHoldAction", 1)
end

function PandaGemCombineAllMixin:Update()
    local parent = self:GetParent()
    self:Disable()
    for _, info in ipairs(parent.gems) do
        local _, spellID = C_Item.GetItemSpell(info.link)
        if spellID and info.stackCount and info.stackCount > 3 then
            self:SetAttribute("type", "item")
            self:SetAttribute("item", info.name)
            self:Enable()
            return
        end
    end
end


--[[----------------------------------------------------------------------------]]--

PandaGemEntryMixin = {}

function PandaGemEntryMixin:OnLoad()
    self:RegisterForClicks("AnyDown")
    self:SetAttribute("pressAndHoldAction", 1)
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

function PandaGemEntryMixin:Initialize(info)
    self.info = info

    self.Stripe:SetShown(not info.index or info.index % 2 == 1)
    self.Icon:SetTexture(info.icon)

    self:SetScript("PreClick", nil)
    self:SetScript("PostClick", nil)
    self:SetAttribute("type", nil)

    if info.bag and info.slot and info.gemSocketIndex then
        self.Text:SetText(format("%s (B)", info.nameWithQuality))
        self:SetScript('PreClick', function () SocketInventoryItem(info.equipmentSlot) end)
        self:SetScript('PostClick', function () CloseSocketInfo() end)
        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", format("/cast Extract Gem\n/use %d %d", info.bag, info.slot))
    elseif info.equipmentSlotName then
        self.Text:SetText(format("%s (E%d)", info.nameWithQuality, info.stackCount))
        self:SetScript('PreClick', function () SocketInventoryItem(info.equipmentSlot) end)
        self:SetScript('PostClick', function () CloseSocketInfo() end)
        self:SetAttribute("type", "macro")
        self:SetAttribute("macrotext", format("/cast Extract Gem\n/click ItemSocketingSocket%d", info.gemSocketIndex))
    else
        self.Text:SetText(format("%s (%d)", info.nameWithQuality, info.stackCount))
        local equipmentSlot, gemSocketIndex = PandaGem:FindSocketForGem(info)
        if equipmentSlot then
            self:SetScript("PostClick",
                function ()
                    SocketInventoryItem(equipmentSlot)
                    C_Container.PickupContainerItem(info.bag, info.slot)
                    ClickSocketButton(gemSocketIndex)
                    AcceptSockets()
                    CloseSocketInfo()
                end)
            self:SetAttribute("type", nil)
        end
    end
end


--[[----------------------------------------------------------------------------]]--

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

function PandaGemMixin:FindSocketForGem(gemInfo)
    for _, socketInfo in ipairs(self.freeGemSockets) do
        if socketInfo.gemSocketType == gemInfo.gemSocketType then
            return socketInfo.equipmentSlot, socketInfo.gemSocketIndex
        end
    end
end

-- Items can be evicted from the cache at any second so we have to grab all
-- the fields we are going to use now and stash them away.

function PandaGemMixin:ProcessGem(item, location, gemSocketIndex)
    local name = item:GetItemName()
    local color = item:GetItemQualityColor().color

    local info = {
        name = name,
        color = color,
        quality = item:GetItemQuality(),
        nameWithQuality = color:WrapTextInColorCode(name),
        link = item:GetItemLink(),
        icon = item:GetItemIcon(),

        -- Gems that are inside sockets don't have ItemLocation or stack
        stackCount = item:HasItemLocation() and item:GetStackCount(),
        maxStackSize = item:GetItemMaxStackSize(),

        gemSocketIndex = gemSocketIndex,
    }

    info.bag, info.slot = location:GetBagAndSlot()

    local equipmentSlot = location:GetEquipmentSlot()
    info.equipmentSlot = equipmentSlot
    info.equipmentSlotName = InventorySlotTable[equipmentSlot]
    
    local _, spellID = C_Item.GetItemSpell(info.link)
    info.spellID = spellID

    local tt = C_TooltipInfo.GetHyperlink(item:GetItemLink())
    local socketText = tt.lines[2].leftText:gsub("|c........(.*)|r", "%1")
    info.gemSocketType = self.SocketTypeTable[socketText]

    table.insert(self.gems, info)
end

function PandaGemMixin:ProcessFreeSocket(location, gemSocketIndex, gemSocketType)
    local bag, slot = location:GetBagAndSlot()
    local equipmentSlot = location:GetEquipmentSlot()

    local info = {
        bag = bag,
        slot = slot,
        equipmentSlot = equipmentSlot,
        equipmentSlotName = InventorySlotTable[equipmentSlot],
        gemSocketType = gemSocketType,
        gemSocketIndex = gemSocketIndex,
    }
    table.insert(self.freeGemSockets, info)
end

function PandaGemMixin:ProcessItem(item)
    local link = item:GetItemLink()
    local location = item:GetItemLocation()

    -- Is it a gem itself
    local classId, subClassId = select(6, C_Item.GetItemInfoInstant(link))
    if classId == 3 and subClassId == 9 then
        self:ProcessGem(item, location)
        self.needsUpdate = true
        return
    end

    -- Does it have sockets
    local stats = C_Item.GetItemStats(link)
    if stats == nil then
        return
    end

    for stat, count in pairs(stats) do
        if stat:find("EMPTY_SOCKET") then
            for i = 1, count do
                -- GetItemGem has cache chicken-and-egg problem, lookup by ID
                local gemID = C_Item.GetItemGemID(link, i)
                if gemID then
                    local gemItem = Item:CreateFromItemID(gemID)
                    gemItem:ContinueOnItemLoad(
                        function ()
                            self:ProcessGem(gemItem, location, i)
                            self.needsUpdate = true
                        end)
                else
                    self:ProcessFreeSocket(location, i, stat)
                    self.needsUpdate = true
                end
            end
        end
    end
end

function PandaGemMixin:RefreshBagsData()
    self.gems = {}
    for bag = BACKPACK_CONTAINER, NUM_TOTAL_EQUIPPED_BAG_SLOTS do
        for slot = 1, C_Container.GetContainerNumSlots(bag) do
            local item = Item:CreateFromBagAndSlot(bag, slot)
            if not item:IsItemEmpty() then
                item:ContinueOnItemLoad(
                    function ()
                        self:ProcessItem(item)
                        self.needsUpdate = true
                    end)
            end
        end
    end
end

function PandaGemMixin:RefreshEquippedData()
    self.freeGemSockets = {}
    for slot = INVSLOT_FIRST_EQUIPPED, INVSLOT_LAST_EQUIPPED do
        local item = Item:CreateFromEquipmentSlot(slot)
        if not item:IsItemEmpty() then
            item:ContinueOnItemLoad(
                function ()
                    self:ProcessItem(item)
                    self.needsUpdate = true
                end)
        end
    end
end

function PandaGemMixin:RefreshData()
    self:RefreshBagsData()
    self:RefreshEquippedData()
end

local function CompareGem(a, b)
    if a.equipmentSlot and not b.equipmentSlot then
        return true
    elseif not a.equipmentSlot and b.equipmentSlot then
        return false
    end

    if GemSocketSortOrder[a.gemSocketType] ~= GemSocketSortOrder[b.gemSocketType] then
        return GemSocketSortOrder[a.gemSocketType] < GemSocketSortOrder[b.gemSocketType]
    end

    if a.quality ~= b.quality then
        return a.quality > b.quality
    end

    if a.name ~= b.name then
        return a.name < b.name
    end
end

function PandaGemMixin:Aggregate(data)
    local seen, ag = {}, {}
    for i, info in ipairs(data) do
        info = CopyTable(info)
        if info.equipmentSlot then
            if not seen[info.link] then
                info.stackCount = info.stackCount or 1
                seen[info.link] = info
                table.insert(ag, info)
            else
                seen[info.link].stackCount = seen[info.link].stackCount + 1
            end
        else
            table.insert(ag, info)
        end
    end
    table.sort(ag, CompareGem)
    return ag
end

function PandaGemMixin:Update()
    for i, scroll in ipairs(self.Scrolls) do
        local function socketTypeMatch(e) return e.gemSocketType == scroll.gemSocketType end
        local free = tFilter(self.freeGemSockets, socketTypeMatch, true)
        scroll.Title:SetText(format("%s (%d Empty)", _G[scroll.gemSocketType], #free))
        local data = self:Aggregate(tFilter(self.gems, socketTypeMatch, true))
        for index, info in ipairs(data) do info.index = index end
        local dataProvider = CreateDataProvider(data)
        scroll:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    end
    self.CombineAll:Update()
end

function PandaGemMixin:OnLoad()
    self:SetTitle("Panda Gem")
    ButtonFrameTemplate_HidePortrait(self)

    local columnGap = 8
    local columnWidth = ( self:GetWidth() - 32 - ( #self.Scrolls - 1 ) * columnGap ) / #self.Scrolls
    local scrollBarSpace = self.Scrolls[1].ScrollBar:GetWidth() * 2
    
    local scrollWidth = columnWidth - scrollBarSpace

    for i, scroll in ipairs(self.Scrolls) do
        local view = CreateScrollBoxListLinearView()
        view:SetElementInitializer("PandaGemEntryTemplate", PandaGemEntryMixin.Initialize)
        ScrollUtil.InitScrollBoxListWithScrollBar(scroll, scroll.ScrollBar, view)

        -- For visibility
        scroll.Title:SetParent(self)
        scroll.ScrollBar:SetParent(self)

        scroll.ScrollBar:ClearAllPoints()
        scroll.ScrollBar:SetPoint("TOP", scroll, "TOPRIGHT", scrollBarSpace/2, -3)
        scroll.ScrollBar:SetPoint("BOTTOM", scroll, "BOTTOM", 0, 2)

        scroll:SetWidth(scrollWidth)
        scroll:ClearAllPoints()
        scroll:SetPoint("TOP", self, "TOP", 0, -64)
        scroll:SetPoint("BOTTOM", self, "BOTTOM", 0, 36)
        if i == 1 then
            scroll:SetPoint("LEFT", self, "LEFT", 16, 0)
        else
            scroll:SetPoint("LEFT", self.Scrolls[i-1], "RIGHT", scrollBarSpace + columnGap, 0)
        end
    end

--[[
    local function LineFactory(elementData)
        return "ScrollBoxDragLineTemplate"
    end

    local function AnchoringHandler(anchorFrame, candidateFrame, candidateArea)
        if candidateArea == DragIntersectionArea.Above then
            anchorFrame:SetPoint("BOTTOMLEFT", candidateFrame, "TOPLEFT", 0, 0)
            anchorFrame:SetPoint("BOTTOMRIGHT", candidateFrame, "TOPRIGHT", 0, 0)
        elseif candidateArea == DragIntersectionArea.Below then
            anchorFrame:SetPoint("TOPLEFT", candidateFrame, "BOTTOMLEFT", 0, 0)
            anchorFrame:SetPoint("TOPRIGHT", candidateFrame, "BOTTOMRIGHT", 0, 0)
        end
    end

    local function Initializer(button, sourceButton)
        button:Initialize(sourceButton.info)
        button:SetScript('OnEnter', nil)
        button:SetScript('OnLeave', nil)
        button:SetScript('OnShow', nil)
        button.Stripe:SetColorTexture(0, 0, 0, 1)
        button.Stripe:Show()
        button:SetWidth(sourceButton:GetWidth())
        button:SetFrameStrata('TOOLTIP')
    end

    local function CursorFactory(elementData)
        return "PandaGemEntryTemplate", Initializer
    end

    dragBehavior = ScrollUtil.AddLinearDragBehavior(self.BagsScroll,
                        CursorFactory, LineFactory, AnchoringHandler)
    dragBehavior:SetReorderable(true)
    dragBehavior:SetDragRelativeToCursor(true)

    dragBehavior:SetNotifyDragSource(
        function (sourceFrame, drag)
            sourceFrame:SetAlpha(drag and .5 or 1)
            sourceFrame:DesaturateHierarchy(drag and 1 or 0)
            sourceFrame:SetMouseMotionEnabled(not drag)
        end)

    dragBehavior:SetNotifyDragCandidates(
        function (candidateFrame, drag)
            candidateFrame:SetMouseMotionEnabled(not drag)
        end)

    dragBehavior:SetSourceDragCondition(
        function (sourceFrame, sourceElementData)
            return true
        end)
]]

    table.insert(UISpecialFrames, self:GetName())

    self:RegisterEvent('PLAYER_LOGIN')
end

function PandaGemMixin:Initialize()
    self.gems = {}
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
