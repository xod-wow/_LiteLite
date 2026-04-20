local _, addon = ...

-- Color nameplate health bars for casters, and also if you are tanking and
-- lose or don't have threat. This used to be LiteNamePlates but now you can't
-- color by NPC ID it's not worth its own addon.

local C_NamePlate = C_NamePlate
local GetSpecialization = GetSpecialization
local GetSpecializationRole = GetSpecializationRole
local IsInGroup = IsInGroup
local UnitThreatSituation = UnitThreatSituation
local UnitGroupRolesAssigned = UnitGroupRolesAssigned
local UnitPowerType = UnitPowerType
local UnitIsBossMob = UnitIsBossMob
local UnitIsPlayer = UnitIsPlayer
local UnitIsTapDenied = UnitIsTapDenied
local UnitReaction = UnitReaction

local ColorRules = {
    {
        checks = { "lostthreat" },
        color = { 1, 1, 0, 0.6 },
        colorHealthBar = false,
        colorName = true,
        enabled = true,
    },
    {
        checks = { "hasmana" },
        colorHealthBar = true,
        colorName = true,
        color = { 1, 0.5, 1, 1 },
        enabled = true,
    },
}


--[[------------------------------------------------------------------------]]--

local function IsHostileWithPlayer(unit)
    if UnitReaction(unit, 'player') == 2 then
        return true
    else
        local threatStatus = UnitThreatSituation("player", unit)
        return threatStatus ~= nil
    end
end

local function IsPlayerEffectivelyTank()
    local assignedRole = UnitGroupRolesAssigned("player")
    if assignedRole == "NONE" then
        local spec = GetSpecialization()
        return spec and GetSpecializationRole(spec) == "TANK"
    end
    return assignedRole == "TANK"
end


--[[------------------------------------------------------------------------]]--

local Checks = {
    ["hasmana"] =
        function (unit)
            -- return UnitClassBase(unit) == "PALADIN"
            return UnitPowerType(unit) == Enum.PowerType.Mana
        end,
    ["lostthreat"] =
        function (unit)
            if IsPlayerEffectivelyTank() and IsInGroup() then
                local threatStatus = UnitThreatSituation("player", unit)
                return threatStatus and threatStatus ~= 3
            end
        end,
}


--[[------------------------------------------------------------------------]]--

local function ShouldColorUnit(unit, includeBoss)
    -- Forbidden nameplates don't work, but will still have their unitframes
    -- passed to the hook. Because you can't call any functions on them you
    -- can't tie them back to their nameplate to tell it's forbidden. I
    -- think this check works.
    if not unit then
        return false
    elseif not UnitCanAttack('player', unit) then
        return false
    elseif unit:sub(1, 5) == 'arena' then
        -- C_NamePlate.GetNamePlateForUnit errors on arena in retail
        return false
    elseif C_NamePlate.GetNamePlateForUnit(unit) == nil then
        return false
    elseif unit:sub(1,9) ~= 'nameplate' then
        return false
    elseif UnitIsPlayer(unit) then
        return false
    elseif not includeBoss and UnitIsBossMob(unit) then
        return false
    elseif UnitIsTapDenied(unit) then
        return false
    elseif not IsHostileWithPlayer(unit) then
        return false
    else
        return true
    end
end

local function CheckRule(rule, unit)
    if not rule.enabled then
        return false
    end
    for _, check in ipairs(rule.checks) do
        local handler = Checks[check]
        if not handler or not handler(unit, arg) then
            return false
        end
    end
    return true
end

local function UpdateUnitFrameColor(unitFrame)
    local todo = { name = true, healthBar = true }
    for _, rule in ipairs(ColorRules) do
        if CheckRule(rule, unitFrame.unit) then
            if todo.healthBar and rule.colorHealthBar then
                unitFrame.healthBar:SetStatusBarColor(unpack(rule.color))
                todo.healthBar = nil
            end
            if todo.name and rule.colorName then
                unitFrame.name:SetTextColor(unpack(rule.color))
                todo.name = nil
            end
        end
        if next(todo) == nil then
            return
        end
    end
end

local function UpdateHook(unitFrame)
    if ShouldColorUnit(unitFrame.unit) then
        UpdateUnitFrameColor(unitFrame)
    end
end

local function Initialize()
    hooksecurefunc('CompactUnitFrame_UpdateName', UpdateHook)
    hooksecurefunc('CompactUnitFrame_UpdateHealthColor', UpdateHook)
    hooksecurefunc('CompactUnitFrame_UpdateHealthBorder', UpdateHook)
end

addon.RegisterModule({ Initialize = Initialize })
