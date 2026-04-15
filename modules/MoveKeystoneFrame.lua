local _, addon = ...

-- Damn thing is underneath the action bars

local function MoveKeystoneFrame()
    if ChallengesKeystoneFrame then
        ChallengesKeystoneFrame:ClearAllPoints()
        ChallengesKeystoneFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
    end
end

local function Initialize()
    if ChallengeMode_LoadUI then
        hooksecurefunc('ChallengeMode_LoadUI', MoveKeystoneFrame)
    end
end

addon.RegisterModule({ Initialize = Initialize })
