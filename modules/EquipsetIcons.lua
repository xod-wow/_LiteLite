local _, addon = ...

local function GetGameTooltipIcon()
    local _, id = GameTooltip:GetSpell()
    if id then
        return C_Spell.GetSpellTexture(id)
    end
    _,  id = GameTooltip:GetItem()
    if id then
        return select(10, GetItemInfo(id))
    end
end

local function SetEquipsetIcon(n, textureID)
    local setID = tonumber(n)
                    or C_EquipmentSet.GetEquipmentSetID(n)
                    or PaperDollFrame.EquipmentManagerPane.selectedSetID

    if setID == nil then
        return
    end

    local name = C_EquipmentSet.GetEquipmentSetInfo(setID)
    if name == nil then
        return
    end

    textureID = tonumber(textureID) or GetGameTooltipIcon()

    if textureID == nil then
        return
    end

    addon.printf('Setting equipset icon for %s (%d) to %d', name, setID, textureID)
    C_EquipmentSet.ModifyEquipmentSet(n, name, textureID)
end

local function AutoEquipsetIcons()
    for _, setID in ipairs(C_EquipmentSet.GetEquipmentSetIDs()) do
        local specIndex = C_EquipmentSet.GetEquipmentSetAssignedSpec(setID)
        if specIndex then
            local textureID = select(4, GetSpecializationInfo(specIndex))
            SetEquipsetIcon(setID, textureID)
        end
    end
end

local function SlashCommand(args)
    local arg1, arg2 = string.split(' ', args, 2)
    if arg1 == 'auto' then
        AutoEquipsetIcons()
    else
        SetEquipsetIcon(arg1, arg2)
    end
end

local moduleInfo = {
    SlashCommands = {
        ['esi'] = SlashCommand,
        ['equipset-icons'] = SlashCommand,
    },
}

addon.RegisterModule(moduleInfo)
