local _, addon = ...

--[[--------------------------------------------------------------------------]]--

-- These are per-spec but there's no point clearing them out I don't think.

local LinkedSpellIDs = {}

-- TODO equipped items without spellID?
local function ScanLinkedSpells()
    for c = Enum.CooldownViewerCategoryMeta.MinValue, Enum.CooldownViewerCategoryMeta.MaxValue do
        for _, cooldownID in ipairs(C_CooldownViewer.GetCooldownViewerCategorySet(c, true)) do
            local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
            if info.spellID then
                LinkedSpellIDs[info.spellID] = LinkedSpellIDs[info.spellID] or {}
                LinkedSpellIDs[info.spellID][info.spellID] = true
                for _, spellID in ipairs(info.linkedSpellIDs) do
                    LinkedSpellIDs[info.spellID][spellID] = true
                end
            end
        end
    end
end


--[[--------------------------------------------------------------------------]]--

local ContainerFilters = {
    { filter = "HELPFUL", unit = 'player', color = CreateColor(0, 0.7, 0, 0.5) },
    { filter = "HARMFUL", unit = 'target', color = CreateColor(1, 0, 0, 0.5) },
}

local AuraContainers = {}

local function InitializeFrame(f, color)
    -- AuraButton is not managing the border, it's fixed, since we don't need
    -- the color to change depending on auraData.dispelName.
    f.auraBorder = f:CreateTexture(nil, "ARTWORK")
    f.auraBorder:SetTexture([[Interface\Addons\_LiteLite\textures\Overlay]])
    f.auraBorder:SetVertexColor(color:GetRGBA())
    f.auraBorder:SetAllPoints(true)

    f.durationText = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.durationText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 3)
    f:SetDurationText(f.durationText)

    -- local formatter = C_StringUtil.CreateSecondsFormatter()
    -- formatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.Truncate)
    -- formatter:SetMillisecondsThreshold(2)
    -- local binding = C_DurationUtil.CreateDurationTextBinding()
    -- binding:SetFormatter(formatter)
    -- f:SetDurationText(f.durationText, { binding = binding })
end

-- This creates an insane amount of AuraContainers, two per ActionButton. It
-- would be much more efficient to create to only two, one to handle all
-- the 'target'+'HARMFUL' and one to handle all the 'player'+'HELPFUL'. Problem
-- is that you can't reparent the AuraButtons, so they don't get their scale.
--
-- The advantage of this approach though is that hidden action buttons have their
-- AuraContainers hidden so they don't do anything.

local function CreateButtonAuraContainers(button)
    local ButtonAuraContainers = { }
    for _, cf in ipairs(ContainerFilters) do
        local container = CreateFrame('AuraContainer', nil, button, 'CustomAuraContainerTemplate')
        container:SetUnit(cf.unit)
        container:SetPoint("TOPLEFT", button, "TOPLEFT")
        container:SetSize(1, 1)

        local options = {
            sortMethod = AuraContainerSortMethod.ExpirationOnly,
            sortDirection = AuraContainerSortDirection.Reverse,
            initializeFrame = function (f) InitializeFrame(f, cf.color) end
        }
        local as = container:AddAuraSlot(cf.filter, cf.filter, options)
        as:SetPoint("CENTER", button)
        PixelUtil.SetSize(as, button:GetSize())
        as:SetFrameLevel(button.cooldown:GetFrameLevel()+1)
        ButtonAuraContainers[cf.filter] = container
    end
    AuraContainers[button:GetName()] = ButtonAuraContainers
end

local function EnumerateActionButtons()
    local buttons = {}
    for _, actionBar in ipairs(ActionButtonUtil.ActionBarButtonNames) do
        for i = 1, NUM_ACTIONBAR_BUTTONS do
            local btn = _G[actionBar..i]
            table.insert(buttons, btn)
        end
    end
    local i = 0
    return function ()
        i = i + 1
        return buttons[i]
    end
end

local function CreateAuraContainers()
    for b in EnumerateActionButtons() do
        CreateButtonAuraContainers(b)
    end
end

local function GetActionFilters(actionID)
    local actionType, id, actionSubType = GetActionInfo(actionID)
    local filters = {
        isFromPlayerOrPlayerPet = true,
        includeSpellIDs = {},
    }
    if (actionType =="spell" or actionSubType == "spell") and id then
        filters.includeSpellIDs[id] = true
        -- Handle spells like Zenith which change to a completely different
        -- spell when active that is not linked.
        local baseSpellID = C_Spell.GetBaseSpell(id)
        filters.includeSpellIDs[baseSpellID] = true
    elseif actionType == "item" then
        local _, spellID = C_Item.GetItemSpell(id)
        filters.includeSpellIDs[spellID] = true
    elseif actionType == "macro" and actionSubType == "item" then
        local actionName = GetActionText(actionID)
        local _, link = GetMacroItem(actionName)
        if link then
            local _, spellID = C_Item.GetItemSpell(link)
            if spellID then
                filters.includeSpellIDs[spellID] = true
            end
        end
    end
    for spellID in pairs(filters.includeSpellIDs) do
        if LinkedSpellIDs[spellID] then
            Mixin(filters.includeSpellIDs, LinkedSpellIDs[spellID])
        end
    end
    return filters
end

local function UpdateOverlayFilters()
    for b in EnumerateActionButtons() do
        for slotName, container in pairs(AuraContainers[b:GetName()]) do
            local filters = GetActionFilters(b.action, slotName)
            if slotName == 'HARMFUL' then
                filters.isHarmful = true
            elseif slotName == 'HELPFUL' then
                filters.isHelpful = true
            end
            container:SetAuraSlotCandidateFilters(slotName, filters)
        end
    end
end

local EventFrame = CreateFrame('Frame')

local UpdateFiltersEvents = {
    ['ACTIONBAR_PAGE_CHANGED'] = true,
    ['ACTIONBAR_SLOT_CHANGED'] = true,
    ['PLAYER_ENTERING_WORLD'] = true,
    ['UPDATE_BONUS_ACTIONBAR'] = true,
    ['UPDATE_VEHICLE_ACTIONBAR'] = true,
}

local ScanLinkedSpellsEvents = {
    ['ACTIVE_COMBAT_CONFIG_CHANGED'] = true,
    ['ACTIVE_PLAYER_SPECIALIZATION_CHANGED'] = true,
    ['ACTIVE_TALENT_GROUP_CHANGED'] = true,
    ['TRAIT_CONFIG_UPDATED'] = true,
}

local AllEvents = CreateFromMixins(UpdateFiltersEvents, ScanLinkedSpellsEvents)

local function OnEvent(_, event)
    -- if InCombatLockdown() then return end
    if UpdateFiltersEvents[event] then
        UpdateOverlayFilters()
    elseif ScanLinkedSpellsEvents[event] then
        ScanLinkedSpells()
    end
end

local function Initialize()
    FrameUtil.RegisterFrameForEvents(EventFrame, GetKeysArray(AllEvents))
    EventFrame:SetScript('OnEvent', OnEvent)
    ScanLinkedSpells()
    CreateAuraContainers()
    UpdateOverlayFilters()
end

-- PLAYER_LOGIN is too late for creating AuraContainer during restrictions
Initialize()
