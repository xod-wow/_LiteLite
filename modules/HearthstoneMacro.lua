-- Create hidden button to cycle through all the hearthstone toys owned, and
-- maintain a macro to click it that will update to show the icon of the one
-- it will cast.

local _, addon = ...

local MAX_ACCOUNT_MACROS = MAX_ACCOUNT_MACROS or Constants.MacroConsts.MAX_ACCOUNT_MACROS
local MAX_CHARACTER_MACROS = MAX_CHARACTER_MACROS or Constants.MacroConsts.MAX_CHARACTER_MACROS
local MAX_TOTAL_MACROS = MAX_ACCOUNT_MACROS + MAX_CHARACTER_MACROS

local HearthstoneToyButton = CreateFrame('Button', '_LLHS', nil, 'SecureActionButtonTemplate')
HearthstoneToyButton:RegisterForClicks('AnyDown', 'AnyUp')

local function IsMyMacro(index)
    local _, _, body = GetMacroInfo(index)
    return body and body:find("/click _LLHS", nil, true)
end

function HearthstoneToyButton:FindMacroIndex()
    local index = GetRunningMacro()
    if index and IsMyMacro(index) then
        return index
    else
        for i = 1, MAX_TOTAL_MACROS do
            if IsMyMacro(i) then
                return i
            end
        end
    end
end

function HearthstoneToyButton:UpdateMacro(index, item)
    local toyName = item:GetItemName()
    local icon = item:GetItemIcon()
    if icon then
        local _, _, body = GetMacroInfo(index)
        if body and body:find("/click _LLHS", nil, true) then
            body = body:gsub("#showtooltip[^\n]*", "#showtooltip " .. toyName)
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
    if InCombatLockdown() or self.toys == nil or #self.toys == 0 then
        return
    end

    for i = 1, #self.toys do
        local offset = ( (self.n or 0) + i - 1) % #self.toys + 1
        if self:IsUsable(self.toys[offset]) then
            self.n = offset
            break
        end
    end

    if self.n == nil then
        return
    end

    local item = Item:CreateFromItemID(self.toys[self.n])
    item:ContinueOnItemLoad(
        function ()
            self:SetAttribute('toy', self.toys[self.n])
            self:SetScript('PreClick', function () addon.printf(item:GetItemName()) end)
            -- Editing a macro while it's running is bad juju
            local macroIndex = self:FindMacroIndex()
            if macroIndex then
                C_Timer.After(0, function () self:UpdateMacro(macroIndex, item) end)
            end
        end)
end

local HearthstoneItemOverride = {
    [54452] = true,         -- Ethereal Portal
    [64488] = true,         -- The Innkeeper's Daughter
    [93672] = true,         -- Dark Portal
    [142542] = true,        -- Tome of Town Portal
    [183716] = true,        -- Venthyr Sinstone
    [190237] = true,        -- Broker Translocation Matrix
    [206195] = true,        -- Path of the Naaru
    [210455] = true,        -- Draenic Hologem
    [212337] = true,        -- Stone of the Hearth
    [235016] = true,        -- Redeployment Module
    [263489] = true,        -- Naaru's Enfold
    [264367] = true,        -- Mycomancer's Hearthspore

    [110560] = false,       -- Garrison Hearthstone
    [118427] = false,       -- Autographed Hearthstone Card
    [119210] = false,       -- Hearthstone Board
    [119211] = false,       -- Hearthstone Card: Lord Jaraxxus
    [140192] = false,       -- Dalaran Hearthstone
    [211946] = false,       -- Hearthstone Game Table
}

function HearthstoneToyButton:IsHearthstone(item)
    local name = item:GetItemName()
    local id = item:GetItemID()
    if HearthstoneItemOverride[id] ~= nil then
        return HearthstoneItemOverride[id]
    elseif name:find('Hearthstone') then
        return true
    else
        return false
    end
end

function HearthstoneToyButton:IsUsable(id)
    if not PlayerHasToy(id) then
        return false
    elseif id == 210455 then
        -- Draenic Hologem requires Draenei or Lightforged Draenei
        local _, _, race = UnitRace('player')
        return (race == 11 or race == 30)
    else
        return true
    end
end

function HearthstoneToyButton:UpdateToyList(itemList)
    self.toys = {}
    self.n = nil

    local cc = ContinuableContainer:Create()
    cc:AddContinuables(itemList)
    cc:ContinueOnLoad(
        function ()
            for _, item in ipairs(itemList) do
                local id = item:GetItemID()
                if self:IsHearthstone(item) then
                    table.insert(self.toys, id)
                end
            end
            self:Shuffle()
            self:Advance()
        end)
end

-- There's a few complicated cases on being able to scan toys, and I'm not
-- entirely sure when C_ToyBox.GetToyFromIndex works. I also don't think
-- there's any way to query toys outside the filter which is annoying, since
-- the index arg is a filtered toys index.

function HearthstoneToyButton:ScanToys()
    if InCombatLockdown() then
        return false
    end

    local itemList = {}

    -- Sometimes on first login this is 2. though perhaps now I set the
    -- default filters explicitly that isn't true any more.
    C_ToyBox.SetAllSourceTypeFilters(true)
    C_ToyBox.SetAllExpansionTypeFilters(true)
    C_ToyBox.SetUncollectedShown(true)
    C_ToyBox.SetUnusableShown(true)
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

    C_ToyBoxInfo.SetDefaultFilters()

    -- addon.printf('initial item count: %d', #itemList)

    -- Current toy count is 900+ so just bail out if it looks like things
    -- aren't working and assume we will get a TOYS_UPDATED nil event later.

    if #itemList > 900 then
        self:UnregisterEvent('TOYS_UPDATED')
        self:UpdateToyList(itemList)
    end
end

local function Initialize()
    HearthstoneToyButton:SetAttribute('type', 'toy')
    HearthstoneToyButton:SetAttribute('typerelease', 'toy')
    HearthstoneToyButton:SetAttribute('pressAndHoldAction', true)
    HearthstoneToyButton:RegisterEvent('TOYS_UPDATED')
    HearthstoneToyButton:SetScript('PostClick', function (self) self:Advance() end)
    HearthstoneToyButton:SetScript('OnEvent', HearthstoneToyButton.ScanToys)
    HearthstoneToyButton:ScanToys()
end

addon.RegisterModule({ Initialize = Initialize })
