local _, addon = ...

if not C_AuraContainerUtil then return end

--[[--------------------------------------------------------------------------]]--

-- These are per-spec but there's no point clearing them out I don't think.
-- [BarSpellID] = { [AuraSpellID] = true, ... }

local LinkedSpellIDs = {
    [100784]    = { [202090] = true },
    [30455]     = { [1221389] = true },
}

-- TODO equipped items without spellID?
local function ScanLinkedSpells()
    for c = Enum.CooldownViewerCategoryMeta.MinValue, Enum.CooldownViewerCategoryMeta.MaxValue do
        for _, cooldownID in ipairs(C_CooldownViewer.GetCooldownViewerCategorySet(c, true)) do
            local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(cooldownID)
            if info.spellID then
                local name = C_Spell.GetSpellName(info.spellID)
                LinkedSpellIDs[name] = LinkedSpellIDs[info.spellID] or {}
                LinkedSpellIDs[name][info.spellID] = true
                for _, spellID in ipairs(info.linkedSpellIDs) do
                    LinkedSpellIDs[name][spellID] = true
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

local AuraDurationFormatter = C_StringUtil.CreateSecondsFormatter()
AuraDurationFormatter:SetDefaultAbbreviation(Enum.SecondsFormatterAbbreviation.OneLetter)
AuraDurationFormatter:SetMinInterval(Enum.SecondsFormatterInterval.Seconds)
AuraDurationFormatter:SetDesiredUnitCount(1)
AuraDurationFormatter:SetMillisecondsThreshold(3)
AuraDurationFormatter:SetStripIntervalWhitespace(Enum.SecondsFormatterIntervalWhitespace.Strip)

local AuraColorCurve = C_CurveUtil.CreateColorCurve()
AuraColorCurve:SetType(Enum.LuaCurveType.Cosine)
AuraColorCurve:AddPoint(0.0, CreateColor(1, 0.5, 0.5))
AuraColorCurve:AddPoint(3.0, CreateColor(1, 1, 0.5))
AuraColorCurve:AddPoint(10.0, CreateColor(1, 1, 1))

local function InitializeFrame(f, color)
    -- AuraButton is not managing the border, it's fixed, since we don't need
    -- the color to change depending on auraData.dispelName.
    f.auraBorder = f:CreateTexture(nil, "ARTWORK")
    f.auraBorder:SetBlendMode("ADD")
    f.auraBorder:SetTexture([[Interface\Addons\_LiteLite\textures\Overlay]])
    f.auraBorder:SetVertexColor(color:GetRGBA())
    f.auraBorder:SetAllPoints(true)

    f.durationText = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.durationText:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 3, 3)

    local durationTextOptions = {
        textFormatter = AuraDurationFormatter,
        textColor = {
            curve = AuraColorCurve,
            property = Enum.DurationTextBindingProperty.RemainingDuration
        }
    }
    f:SetDurationText(f.durationText, durationTextOptions)

    f.stacksText = f:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
    f.stacksText:SetPoint("TOPLEFT", f, "TOPLEFT", 3, -3)
    f:SetApplicationCount(f.stacksText)

    f:EnableMouse(false)
end

-- This creates an insane amount of AuraContainers, two per ActionButton. It
-- would be much more efficient to create two, one to per unit (player/target).
--
-- Problem is the scaling/size.
--
-- You can't reparent the AuraSlots, so they can't individually scale
-- themselves. You can SetAllPoints on the button which works but it doesn't
-- scale the child elements.
--
-- In 12.1.5 we are promised SetUnit per slot which halves the number.

local function CreateButtonAuraContainers(button)
    local ButtonAuraContainers = { }
    for _, cf in ipairs(ContainerFilters) do
        local name = button:GetName() .. cf.filter
        local container = CreateFrame('AuraContainer', name, button, 'CustomAuraContainerTemplate')
        container:SetUnit(cf.unit)
        container:SetPoint("TOPLEFT", button, "TOPLEFT")
        container:SetSize(1, 1)

        local options = {
            sortMethod = AuraContainerSortMethod.ExpirationOnly,
            sortDirection = AuraContainerSortDirection.Reverse,
            initializeFrame = function (f) InitializeFrame(f, cf.color) end
        }
        local auraSlotName = cf.filter
        local auraSlotFilter = cf.filter .. '|PLAYER'
        local as = container:AddAuraSlot(auraSlotName, auraSlotFilter, options)
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

    -- Dominos
    if Dominos then
        for btn in pairs(Dominos.ActionButtons.buttons) do
            table.insert(buttons, btn)
        end
    end

    -- LibActionButton variants
    -- The %- here is a literal "-"
    for name, lib in LibStub:IterateLibraries() do
        if name:match('^LibActionButton%-1.0') then
            for btn in pairs(lib:GetAllButtons()) do
                local actionType, _action = btn:GetAction()
                if actionType == "action" then
                    table.insert(buttons, btn)
                end
            end
        end
    end


    local i = 0
    return function ()
        i = i + 1
        return buttons[i]
    end
end

local function UpdateAllAuras()
    for _, cf in ipairs(ContainerFilters) do
        if cf.unit == 'target' then
            for _, ButtonAuraContainers in pairs(AuraContainers) do
                ButtonAuraContainers[cf.filter]:UpdateAllAuras()
            end
        end
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
        filters.includeSpellIDs[id] = true
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
        local name = C_Spell.GetSpellName(spellID)
        if LinkedSpellIDs[name] then
            Mixin(filters.includeSpellIDs, LinkedSpellIDs[name])
        end
    end
    return filters
end

local function UpdateOverlayFilters()
    for b in EnumerateActionButtons() do
        for slotName, container in pairs(AuraContainers[b:GetName()]) do
            local filters = GetActionFilters(b.action, slotName)
            if slotName == 'HARMFUL' then
                if UnitCanAssist('player', 'target') then
                    -- Hacky disable when spell filters are prohibited
                    filters.maxDuration = 0
                end
                filters.isHarmful = true
                -- filters.canApplyAura = true
            elseif slotName == 'HELPFUL' then
                if not UnitCanAssist('player', 'player') then
                    filters.maxDuration = 0
                end
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

-- From CooldownViewerSettingsDataProvider.lua
local ScanLinkedSpellsEvents = {
    ['ACTIVE_COMBAT_CONFIG_CHANGED'] = true,
    ['ACTIVE_PLAYER_SPECIALIZATION_CHANGED'] = true,
    ['ACTIVE_TALENT_GROUP_CHANGED'] = true,
    ['COOLDOWN_VIEWER_TRABLE_HOTFIXED'] = true,
    ['PLAYER_EQUIMENT_CHANGED'] = true,
    ['PLAYER_PVP_TALENT_UPDATE'] = true,
    ['SPELLS_CHANGED'] = true,
    ['TRAIT_CONFIG_UPDATED'] = true,
}

local UpdateAllAurasEvents = {
    ['PLAYER_TARGET_CHANGED'] = true,
    ['UNIT_ENTERED_VEHICLE'] = true,
    ['UNIT_EXITED_VEHICLE'] = true,
}

local AllEvents = CreateFromMixins(UpdateFiltersEvents, ScanLinkedSpellsEvents, UpdateAllAurasEvents)

local function OnEvent(_, event, ...)
    if UpdateFiltersEvents[event] then
        UpdateOverlayFilters()
    elseif ScanLinkedSpellsEvents[event] then
        ScanLinkedSpells()
        UpdateOverlayFilters()
    elseif event == 'UNIT_ENTERED_VEHICLE' or event == 'UNIT_EXITED_VEHICLE' then
        -- Necessary to do the disabling so we don't get all auras showing
        -- when UnitCanAssist('player', 'player') is false. If Blizzard add
        -- something to show nothing if filters can't be applied this can go.
        local unit = ...
        if unit == 'player' then
            UpdateAllAuras()
        end
    elseif event == 'PLAYER_TARGET_CHANGED' then
        UpdateAllAuras()
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
