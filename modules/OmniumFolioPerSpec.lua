local _, addon = ...

local SYSTEM_ID = 48
local TREE_ID = 1186

local configID = C_Traits.GetConfigIDBySystemID(SYSTEM_ID)

local currentSpecID

local function GetCurrentTraits()
    local traits = {}
    for _, nodeID in ipairs(C_Traits.GetTreeNodes(TREE_ID)) do
        local info = C_Traits.GetNodeInfo(configID, nodeID)
        if info and #info.entryIDs > 1 and info.ranksPurchased > 0 and info.activeEntry then
            traits[nodeID] = info.activeEntry.entryID
        end
    end
    return traits
end

local function ApplyTraits(traits)
    if InCombatLockdown() then
        -- No need to register regen because can't change traits in combat
        return
    elseif not C_Traits.CanEditConfig(configID) then
        return
    else
        for nodeID, entryID in pairs(traits) do
            C_Traits.SetSelection(configID, nodeID, entryID)
        end
    end
end

local function Save()
    local specID = PlayerUtil.GetCurrentSpecID()
    local name = GetSpecializationNameForSpecID(specID)
    addon.printf('Save omnium folio traits: %s (%d)', name, specID)
    local traits = GetCurrentTraits()
    addon.db.omniumFolioTraitsBySpecID[specID] = traits
end

local function Restore()
    local specID = PlayerUtil.GetCurrentSpecID()
    if specID ~= currentSpecID then
        local traits = addon.db.omniumFolioTraitsBySpecID[specID]
        if traits then
            local name = GetSpecializationNameForSpecID(specID)
            addon.printf('Restore omnium folio traits: %s (%d)', name, specID)
            ApplyTraits(traits)
        else
            Save()
        end
        currentSpecID = specID
    end
end

local function OnEvent(_self, event, ...)
    if event == 'TRAIT_CONFIG_UPDATED' then
        local eventConfigID = ...
        if configID == eventConfigID then
            Save()
        end
    elseif event == 'ACTIVE_PLAYER_SPECIALIZATION_CHANGED' then
        Restore()
    elseif event == 'PLAYER_ENTERING_WORLD' then
        Restore()
    end
end

local EventFrame = CreateFrame('Frame')

local function Initialize()
    if configID then
        addon.db.omniumFolioTraitsBySpecID = addon.db.omniumFolioTraitsBySpecID or {}
        EventFrame:RegisterEvent('ACTIVE_PLAYER_SPECIALIZATION_CHANGED')
        EventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
        EventFrame:RegisterEvent('TRAIT_CONFIG_UPDATED')
        EventFrame:SetScript('OnEvent', OnEvent)
    end
end

if WOW_PROJECT_ID == 1 then
    addon.RegisterModule({ Initialize = Initialize })
end
