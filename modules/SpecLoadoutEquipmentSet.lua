local function UpdateEquipmentSetForLoadout()
    if InCombatLockdown() then return end

    if not _LiteLite.equipmentSetLoadoutDirty then return end

    _LiteLite.equipmentSetLoadoutDirty = nil

    local specID, specName = PlayerUtil.GetCurrentSpecID()
    if not specID then return end

    local configID = C_ClassTalents.GetLastSelectedSavedConfigID(specID)
    if not configID then return end

    local info = C_Traits.GetConfigInfo(configID)
    if not info or info.type ~= Enum.TraitConfigType.Combat then return end

    local loadoutSetName = specName .. ' ' .. info.name
    local loadoutSetID = C_EquipmentSet.GetEquipmentSetID(loadoutSetName)

    if loadoutSetID then
        addon.printf('Change equipment set ' .. loadoutSetName)
        C_EquipmentSet.UseEquipmentSet(loadoutSetID)
        return
    end

    local specIndex = GetSpecialization()
    if not specIndex then return end

    local specSetID = C_EquipmentSet.GetEquipmentSetForSpec(specIndex)
    if specSetID then
        local specSetName = C_EquipmentSet.GetEquipmentSetInfo(specSetID)
        addon.printf('Change equipment set ' .. specSetName)
        C_EquipmentSet.UseEquipmentSet(specSetID)
        return
    end
end

function _LiteLite:UpdateEquipmentSet()
    self.equipmentSetLoadoutDirty = true
    C_Timer.After(0, UpdateEquipmentSetForLoadout)
end

function _LiteLite:TRAIT_CONFIG_UPDATED(id)
    if id == C_ClassTalents.GetActiveConfigID() then
        self:UpdateEquipmentSet()
    end
end

function _LiteLite:ACTIVE_TALENT_GROUP_CHANGED()
    self:UpdateEquipmentSet()
end

function _LiteLite:PLAYER_REGEN_ENABLED()
    UpdateEquipmentSetForLoadout()
end

