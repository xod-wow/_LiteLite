local _, addon = ...

local iconTextures = {}

local function GetFrameIconTexture(f)
    local name = f:GetName()
    if not iconTextures[name] then
        local t = f:CreateTexture()
        t:SetDrawLayer("OVERLAY", -1)
        t:SetSize(14, 14)
        t:SetPoint("LEFT", f)
        t:SetTexture([[Interface\TargetingFrame\UI-RaidTargetingIcons]])
        t:Hide()
        iconTextures[name] = t
    end
    return iconTextures[name]
end

local function UpdateFrameRaidIcon(f)
    if f and f:IsVisible() then
        local iconTexture = GetFrameIconTexture(f)
        local index = GetRaidTargetIndex(f.unit) -- secret
        if index then
            SetRaidTargetIconTexture(iconTexture, index)
            iconTexture:Show()
        else
            iconTexture:Hide()
        end
    end
end

local function Update()
    for f in addon.IterateGroupFrames() do
        UpdateFrameRaidIcon(f)
    end
end

local function ScheduleUpdate()
    C_Timer.After(0, Update)
end

local function Initialize()
    EventRegistry:RegisterFrameEventAndCallback('GROUP_ROSTER_UPDATE', ScheduleUpdate)
    EventRegistry:RegisterFrameEventAndCallback('PLAYER_ENTERING_WORLD', ScheduleUpdate)
    EventRegistry:RegisterFrameEventAndCallback('RAID_TARGET_UPDATE', ScheduleUpdate)
end

addon.RegisterModule({ Initialize = Initialize })
