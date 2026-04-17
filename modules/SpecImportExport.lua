-- An attempt at a complete spec setup copy from one of my chars to another.
-- There's a heap of bugs here I think but it's vaguely helpful. I wouldn't
-- run this on any character you care about.

local _, addon = ...

local ImportExportMixin = {
    ImportLoadout =
        function (self, importText, loadoutName)
            addon.printf('Importing loadout: ' .. loadoutName)
            local importStream = ExportUtil.MakeImportDataStream(importText)
            local headerValid, serializationVersion, specID, treeHash = self:ReadLoadoutHeader(importStream)

            if not headerValid then addon.printf('Bad header') return end
            if specID ~= PlayerUtil.GetCurrentSpecID() then addon.printf('Bad spec') return end

            local configID = C_ClassTalents.GetActiveConfigID()
            local configInfo = C_Traits.GetConfigInfo(configID)
            local treeInfo = C_Traits.GetTreeInfo(configID, configInfo.treeIDs[1])

            local loadoutContent = self:ReadLoadoutContent(importStream, treeInfo.ID)
            if not loadoutContent then addon.printf('Loadout did not convert') return end
            local loadoutEntryInfo = self:ConvertToImportLoadoutEntryInfo(configID, treeInfo.ID, loadoutContent)

            if loadoutName == 'active' then
                C_Traits.ResetTree(configID, configInfo.treeIDs[1])
                self:PurchaseLoadout(configID, loadoutEntryInfo)
                C_Traits.CommitConfig(configID) -- TTT says this doesn't work
            else
                local ok, err = C_ClassTalents.ImportLoadout(configID, loadoutEntryInfo, loadoutName)
                C_Traits.CommitConfig(configID) -- TTT says this doesn't work
                if not ok then
                    addon.printf('Loadout import failed: %s: %s', loadoutName, err)
                    return
                end
            end
        end,
    -- Two annoyances, solved with brute force. The nodes are not in dependency
    -- order, and the loadoutEntryInfo doesn't contain whether this is a choice
    -- node or not. The neat answer to the second and probably the first is to
    -- go spelunking around in the trait tree, but associating the treeNodes
    -- with the nodeEntry is annoying and this works.
    PurchaseLoadout =
        function (self, configID, loadoutEntryInfo)
            local allSucceeded
            while true do
                local didSomething = false
                allSucceeded = true
                for _, nodeEntry in pairs(loadoutEntryInfo) do
                    local success = C_Traits.SetSelection(configID, nodeEntry.nodeID, nodeEntry.selectionEntryID)
                    if not success then
                        for _rank = 1, nodeEntry.ranksPurchased do
                            success = C_Traits.PurchaseRank(configID, nodeEntry.nodeID)
                        end
                    end
                    if success then
                        didSomething = true
                    else
                        allSucceeded = false
                    end
                end
                if not didSomething then break end
            end
            return allSucceeded
        end,
    GetConfigID = function (self) return C_ClassTalents.GetActiveConfigID() end,
}

local function GetActionMacroInfo(actionID)
    local macroName = GetActionText(actionID)
    return GetMacroInfo(macroName)
end

--- Use JSON becuase I can peer at it. CBOR is better but it would have to be
--- Base64 encoded. Difficulty: JSON can't have gaps in an array, and Blizzard's
--- serializer will bomb out if t[1] exists and there are gaps, so force the
--- serializer to output a key table by tostring()ing the indexes.
local function SpecConfigToString()
    local map = {}

    map.actions = {}

    for i = 1, 180 do
        if GetActionInfo(i) then
            local index = tostring(i)
            map.actions[index] = { GetActionInfo(i) }
            if map.actions[index][1] == "macro" then
                local name, icon, text = GetActionMacroInfo(i)
                if name then
                    if text:find('#showtooltip') then icon = 134400 end
                    map.actions[index][3] = name
                    map.macros = map.macros or {}
                    map.macros[name] = { name, icon, text }
                end
            end
        end
    end

    local specID = PlayerUtil.GetCurrentSpecID()
    local lastSelectedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    local configID = C_ClassTalents.GetActiveConfigID()

    map.loadout = {
        string = C_Traits.GenerateImportString(configID),
        name = lastSelectedConfigID and C_Traits.GetConfigInfo(lastSelectedConfigID).name or 'active'
    }

    -- Clique bindings
    if Clique and Clique.db then
        map.clique = CopyTable(Clique.db.profile.bindings)
    end

    return C_EncodingUtil.SerializeJSON(map)
end

local function PickupFlyoutByActionID(id)
    for i = 1, 1000 do
        local info = C_SpellBook.GetSpellBookItemInfo(i, Enum.SpellBookSpellBank.Player)
        if info and info.itemType == Enum.SpellBookItemType.Flyout and info.actionID == id then
             C_SpellBook.PickupSpellBookItem(i, Enum.SpellBookSpellBank.Player)
            return
        end
    end
end

local function SetAction(i, action)
    if not action or not action[1] then
        PickupAction(i)
    elseif action[1] == "spell" then
        C_Spell.PickupSpell(action[2])
        PlaceAction(i)
    elseif action[1] == "macro" then
        PickupMacro(action[3])
        PlaceAction(i)
    elseif action[1] == "item" then
        PickupItem(action[2])
        PlaceAction(i)
    elseif action[1] == "flyout" then
        PickupFlyoutByActionID(action[2])
        PlaceAction(i)
    elseif action[1] == "companion" then
        PickupCompanion(action[3], action[2])
        PlaceAction(i)
    else
        print("Don't know how to place action of type:", unpack(action))
    end
    ClearCursor()
end

local function SetMacro(info)
    local name, icon, text = unpack(info)
    local i, existingName, existingIcon, existingText = GetMacroInfo(name)
    if text:find('#showtooltip') then icon = 134400 end
    if i == nil then
        CreateMacro(name, icon, text, true)
    elseif text ~= existingText then
        EditMacro(i, name, icon, text)
    end
end

local function SpecConfigFromString(text)
    local map = C_EncodingUtil.DeserializeJSON(text)
    if not map then return end

    addon.printf('Loading macros')
    if map.macros then
        for name, info in pairs(map.macros) do
            addon.printf(' - ' .. name)
            SetMacro(info)
        end
    end

    addon.printf('Setting action bar actions')
    for i = 1, 180 do
        local index = tostring(i)
        SetAction(i, map.actions[index])
    end

    addon.printf('Setting up loadout')
    if map.loadout then
        local currentConfigsByName = {}
        local specID = PlayerUtil.GetCurrentSpecID()
        for _,configID in ipairs(C_ClassTalents.GetConfigIDsBySpecID(specID)) do
            local info = C_Traits.GetConfigInfo(configID)
            currentConfigsByName[info.name] = configID
        end

        C_AddOns.LoadAddOn('Blizzard_PlayerSpells')
        local importer = CreateFromMixins(ClassTalentImportExportMixin, ImportExportMixin)
        if currentConfigsByName[map.loadout.name] then
            local lastSelectedConfigID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
            local activeConfigName = lastSelectedConfigID and C_Traits.GetConfigInfo(lastSelectedConfigID).name
            if activeConfigName == map.loadout.name then
                addon.printf('Importing into active loadout: ' .. map.loadout.name)
                map.loadout.name = 'active'
            else
                addon.printf('Deleting existing inactive loadout: ' .. map.loadout.name)
                C_ClassTalents.DeleteConfig(currentConfigsByName[map.loadout.name])
            end
        end
        importer:ImportLoadout(map.loadout.string, map.loadout.name)
    end

    if map.clique and Clique and Clique.db then
        addon.printf('Setting up Clique')
        local p = Clique.db.profile
        p.bindings = p.bindings or {}
        table.wipe(p.bindings)
        Mixin(p.bindings, map.clique)
    end
end

local function ImportExportSpecConfig()
    _LiteLiteText.ApplyFunc =
        function ()
            local text = _LiteLiteText.EditBox:GetText()
            SpecConfigFromString(text)
        end
    _LiteLiteText.EditBox:SetText(SpecConfigToString())
    _LiteLiteText.EditBox:HighlightText()
    _LiteLiteText.EditBox:SetAutoFocus(true)
    _LiteLiteText:Show()
end

local moduleInfo = {
    SlashCommands = {
        ['spec-config'] = ImportExportSpecConfig,
        ['sc'] = ImportExportSpecConfig,
    }
}
addon.RegisterModule(moduleInfo)
