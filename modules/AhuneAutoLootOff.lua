local _, addon = ...

local function Update()
    local id = select(8, GetInstanceInfo())
    local v = C_CVar.GetCVarBool('autoLootDefault')
    if id == 547 and v == true then
        C_CVar.SetCVar('autoLootDefault', "0")
        addon.printf('DISABLING AUTOLOOT')
    elseif id ~= 547 and v == false then
        C_CVar.SetCVar('autoLootDefault', "1")
        addon.printf('ENABLING AUTOLOOT')
    end
end

EventRegistry:RegisterFrameEventAndCallback('PLAYER_ENTERING_WORLD', Update)
