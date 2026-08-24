local _, addon = ...

local SYSTEM_ID = 48
local TREE_ID = 1186

local function GetCurrentTraits()
    local configID = C_Traits.GetConfigIDBySystemID(SYSTEM_ID)
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
    if InCombatLockdown() then return end
    local configID = C_Traits.GetConfigIDBySystemID(SYSTEM_ID)
    if C_Traits.CanEditConfig(configID) then
        for nodeID, entryID in pairs(traits) do
            C_Traits.SetSelection(configID, nodeID, entryID)
        end
    end
end

local function Save()
    -- addon.printf('Save omnium folio traits')
    local specID = PlayerUtil.GetCurrentSpecID()
    local traits = GetCurrentTraits()
    addon.db.omniumFolioTraitsBySpecID[specID] = traits
end

local function Restore()
    local specID = PlayerUtil.GetCurrentSpecID()
    local traits = addon.db.omniumFolioTraitsBySpecID[specID]
    if traits then
        -- addon.printf('Restore omnium folio traits')
        ApplyTraits(traits)
    else
        Save()
    end
end

local function OnEvent(_self, event, ...)
    if event == 'TRAIT_CONFIG_UPDATED' then
        local configID = C_Traits.GetConfigIDBySystemID(SYSTEM_ID)
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
    addon.db.omniumFolioTraitsBySpecID = addon.db.omniumFolioTraitsBySpecID or {}
    EventFrame:RegisterEvent('ACTIVE_PLAYER_SPECIALIZATION_CHANGED')
    EventFrame:RegisterEvent('PLAYER_ENTERING_WORLD')
    EventFrame:RegisterEvent('TRAIT_CONFIG_UPDATED')
    EventFrame:SetScript('OnEvent', OnEvent)
end

addon.RegisterModule({ Initialize = Initialize })
