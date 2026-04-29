-- Create hidden button to cycle through all the hearthstone toys owned, and
-- maintain a macro to click it that will update to show the icon of the one
-- it will cast.

local _, addon = ...

local HearthstoneToyButton = CreateFrame('Button', '_LLHS', nil, 'SecureActionButtonTemplate')
HearthstoneToyButton:RegisterForClicks('AnyDown', 'AnyUp')

local notHearthstone = {
    [110560] = true,
    [118427] = true,
    [119210] = true,
    [119211] = true,
    [140192] = true,
    [211946] = true,
}

local function IsMyMacro(index)
    local _, _, body = GetMacroInfo(index)
    return body and body:find("/click _LLHS", nil, true)
end

function HearthstoneToyButton:FindMacroIndex()
    local index = GetRunningMacro()
    if index and IsMyMacro(index) then
        return index
    else
        for i = 1, MAX_ACCOUNT_MACROS+MAX_CHARACTER_MACROS do
            if IsMyMacro(i) then
                return i
            end
        end
    end
end

function HearthstoneToyButton:UpdateMacro(index)
    local toyName = self.toys[self.n]
    local icon = select(5, C_Item.GetItemInfoInstant(toyName))
-- addon.printf('UpdateMacro %d toyName=%s icon=%d grm=%s', index, toyName, icon, tostring(GetRunningMacro()))
    if icon then
        local _, _, body = GetMacroInfo(index)
        if body and body:find("/click _LLHS", nil, true) then
            body = body:gsub("#showtooltip[^\n]*", "#showtooltip " .. toyName)
-- addon.printf('EditMacro %d toyName=%s icon=%d', index, toyName, icon)
            EditMacro(index, nil, icon, body)
        end
    end
end

function HearthstoneToyButton:Shuffle()
    for i = #self.toys, 2, -1 do
        local r = math.random(i)
        self.toys[i], self.toys[r] = self.toys[r], self.toys[i]
    end
end

function HearthstoneToyButton:Advance()
    if not InCombatLockdown() and self.toys ~= nil then
        if self.n == nil or self.n >= #self.toys then
            self:Shuffle()
            self.n = 1
        else
            self.n = self.n + 1
        end
        -- print(self:GetName(), 'Advance', self.toys[self.n])
        self:SetScript('PreClick', function () addon.printf(self.toys[self.n]) end)
        self:SetAttribute('toy', self.toys[self.n])
        -- Editing a macro while it's running is bad juju
        local macroIndex = self:FindMacroIndex()
        if macroIndex then
            C_Timer.After(0.1, function () self:UpdateMacro(macroIndex) end)
        end
    end
end

local ExtraHSItemIDs = {
    [54452] = true,         -- Ethereal Portal
    [190237] = true,        -- Broker Translocation Matrix
    [206195] = true,        -- Path of the Naaru
    [210455] = true,        -- Draenic Hologem
    [235016] = true,        -- Redeployment Module
}

function HearthstoneToyButton:IsHearthstone(item)
    local name = item:GetItemName()
    local id = item:GetItemID()
    local _, _, race = UnitRace('player')

    if notHearthstone[id] then
        return false
    elseif id == 210455 and not (race == 11 or race == 30) then
        -- Draenic Hologem requires Draenei or Lightforged Draenei
        return false
    elseif name:find('Hearthstone') then
        return true
    elseif ExtraHSItemIDs[id] then -- Ethereal Portal
        return true
    else
        return false
    end
end

function HearthstoneToyButton:UpdateToy(item)
    if self:IsHearthstone(item) then
        local name = item:GetItemName()
        local id = item:GetItemID()
        if not tContains(self.toys, name) and PlayerHasToy(id) then
            table.insert(self.toys, name)
            if self.n == nil then self:Advance() end
        end
    end
end

-- There's a few complicated cases on being able to scan toys, and I'm not
-- entirely sure when C_ToyBox.GetToyFromIndex works. I also don't think
-- there's any way to query toys outside the filter which is annoying, since
-- the index arg is a filtered toys index.

function HearthstoneToyButton:Update(_event, itemID, _isNew, _hasFanfare)
    if InCombatLockdown() then
        return
    elseif itemID == nil then
        -- I'm trying not to scan too much, as this fires semi-regularly, I think
        -- every PLAYER_ENTERING_WORLD.
        if self.initialFullScan ~= nil then return end

        local itemList = {}

        -- Sometimes on first login this is 2. though perhaps now I set the
        -- default filters explicitly that isn't true any more.
        C_ToyBox.SetAllSourceTypeFilters(true)
        C_ToyBox.SetAllExpansionTypeFilters(true)
        C_ToyBox.SetUncollectedShown(true)
        C_ToyBox.SetFilterString('')
        local numFilteredToys = C_ToyBox.GetNumFilteredToys()

        -- addon.printf('HearthstoneToyButton:Update: #%d', numFilteredToys)

        -- I think C_ToyBox.GetToyFromIndex relies on a client cache, which
        -- could just be the item cache. Calling C_ToyBox.GetToyFromIndex seems
        -- to return -1 if the toy is not cached, and trigger a TOYS_UPDATED
        -- event with the itemID when fetched. (It also returns -1 for indexes
        -- that don't exist.) It's possible GetItemInfo definitely works if the
        -- id is not -1 but I haven't tested it.

        for i = 1, numFilteredToys do
            local id = C_ToyBox.GetToyFromIndex(i)
            local item = Item:CreateFromItemID(id)
            if not item:IsItemEmpty() then
                table.insert(itemList, item)
            end
        end

        -- addon.printf('initial item count: %d', #itemList)

        -- Current toy count is 900+ so just bail out if it looks like things
        -- aren't working and assume we will get a TOYS_UPDATED nil event later.

        if #itemList < 900 then return end

        self.initialFullScan = true

        self.toys = self.toys or {}

        local cc = ContinuableContainer:Create()
        cc:AddContinuables(itemList)
        cc:ContinueOnLoad(
            function ()
                for _, item in ipairs(itemList) do
                    self:UpdateToy(item)
                end
            end)
    elseif itemID ~= nil then
        -- addon.printf('HearthstoneToyButton:Update: %d', itemID)
        self.toys = self.toys or {}
        local item = Item:CreateFromItemID(itemID)
        item:ContinueOnItemLoad(function () self:UpdateToy(item) end)
    end
end

local function Initialize()
    HearthstoneToyButton:SetAttribute('type', 'toy')
    HearthstoneToyButton:SetAttribute('typerelease', 'toy')
    HearthstoneToyButton:SetAttribute('pressAndHoldAction', true)
    HearthstoneToyButton:SetScript('PostClick', function (self) self:Advance() end)
    EventUtil.RegisterOnceFrameEventAndCallback('PLAYER_ENTERING_WORLD',
        function ()
            HearthstoneToyButton:RegisterEvent('TOYS_UPDATED')
            HearthstoneToyButton:SetScript('OnEvent', HearthstoneToyButton.Update)
            HearthstoneToyButton:Update()
        end)
end

addon.RegisterModule({ Initialize = Initialize })
