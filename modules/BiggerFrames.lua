-- Make some of the Blizzard frames bigger because I am blind.

local _, addon = ...

local function Embiggen(f)
    f:SetScale(1.25)
end

local function Initialize()
    QuestFrame:HookScript('OnShow', Embiggen)
    GossipFrame:HookScript('OnShow', Embiggen)
    ItemTextFrame:HookScript('OnShow', Embiggen)
    TabardFrame:HookScript('OnShow', Embiggen)
    CommunitiesFrame:HookScript('OnShow', Embiggen)
    if EncounterJournal_LoadUI then
        hooksecurefunc('EncounterJournal_LoadUI',
            function ()
                EncounterJournal:HookScript('OnShow', Embiggen)
            end)
    end
end

addon.RegisterModule({ Initialize = Initialize })
