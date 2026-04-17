-- Move the keystone frame up a bit. Not sure if this is still the case but
-- in TWW it used to be hidden under the action bars meaning I couldn't click
-- or put in the keystone.

local _, addon = ...

local function MoveKeystoneFrame()
    if ChallengesKeystoneFrame then
        ChallengesKeystoneFrame:ClearAllPoints()
        ChallengesKeystoneFrame:SetPoint("TOP", UIParent, "TOP", 0, -60)
    end
end

local function Initialize()
    if ChallengesKeystoneFrame then
        MoveKeystoneFrame()
    elseif ChallengeMode_LoadUI then
        hooksecurefunc('ChallengeMode_LoadUI', MoveKeystoneFrame)
    end
end

addon.RegisterModule({ Initialize = Initialize })
