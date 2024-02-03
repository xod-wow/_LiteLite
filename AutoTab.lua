local AutoTabFrames = {
    {
        frame =                 "AchievementFrame",
        loadFunc =              "AchievementFrame_LoadUI",
    },
    {
        frame =                 "CollectionsJournal",
    },
    {
        frame =                 "CharacterFrame",
    },
    {
        frame =                 "SpellBookFrame",
    },
    {
        frame =                 "ClassTalentFrame",
        loadFunc =              "ClassTalentFrame_LoadUI"
    },
    {
        frame =                 "PVEFrame",
    },
    {
        frame =                 "FriendsFrame",
    },
    {
        frame =                 "CommunitiesFrame",
        loadFunc =              "Communities_LoadUI",
        tabKeys =               { "ChatTab", "RosterTab", "GuildBenefitsTab", "GuildInfoTab" },
    },
    {
        frame =                 "EncounterJournal",
        loadFunc =              "EncounterJournal_LoadUI",
    },
    {
        frame =                 "AuctionHouseFrame",
        loadFunc =              "AuctionHouseFrame_LoadUI",
    },
    {
        frame =                 "MerchantFrame",
    },
    {
        frame =                 "MailFrame",
    },
    {
        frame =                 "GuildBankFrame",
        loadInteractionType =   Enum.PlayerInteractionType.GuildBanker,
    },
}

CreateFrame("Button", "AutoTabButton", nil, "SecureActionButtonTemplate")

local function rotateN(currentVal, numVals, increment)
    return  ( currentVal - 1 + increment ) % numVals + 1
end

function AutoTabButton:PreClick(key)
    if InCombatLockdown() then return end
    local info = self.activeFrames[1]
    if not info then return end
    local frame = _G[info.frame]
    local direction = key == 'TAB' and 1 or -1
    if frame.Tabs and frame.selectedTab then
        local tab = frame.selectedTab
        local newTab = rotateN(tab, frame.numTabs, direction)
        local tabButton = frame.Tabs[newTab]
        self:SetAttribute("clickbutton", tabButton)
    elseif frame.numTabs and frame.selectedTab then
        local tab = frame.selectedTab
        local newTab = rotateN(tab, frame.numTabs, direction)
        local tabButton = _G[frame:GetName().."Tab"..newTab]
        self:SetAttribute("clickbutton", tabButton)
    elseif frame.Tabs and frame.currentTab then
        local tab
        for i, tabButton in ipairs(frame.Tabs) do
            if tabButton == frame.currentTab then
                tab = i
                break
            end
        end
        if tab then
            local newTab = rotateN(tab, frame.numTabs, direction)
            local tabButton = frame.Tabs[newTab]
            self:SetAttribute("clickbutton", tabButton)
        end
    elseif frame.TabSystem then
        local tab = frame.TabSystem.selectedTabID
        local newTab = rotateN(tab, #frame.TabSystem.tabs, direction)
        local tabButton = frame.TabSystem.tabs[newTab]
        self:SetAttribute("clickbutton", tabButton)
    elseif info.tabKeys then
        local tab = 0
        for i, tabKey in ipairs(info.tabKeys) do
            if frame[tabKey]:GetChecked() then
                tab = i
                break
            end
        end
        local newTab = rotateN(tab, #info.tabKeys, direction)
        tabButton = frame[info.tabKeys[newTab]]
        self:SetAttribute("clickbutton", tabButton)
    end
end


function AutoTabButton:HookTabKeys()
    SetOverrideBindingClick(self, true, 'TAB', self:GetName(), 'TAB')
    SetOverrideBindingClick(self, true, 'SHIFT-TAB', self:GetName(), 'SHIFT-TAB')
end

function AutoTabButton:UnhookTabKeys()
    ClearOverrideBindings(self)
end

function AutoTabButton:SetUpFrame(info)
    if info.hooked then return end
    local frame = _G[info.frame]
    -- print('SetUpFrame', frame:GetName())

    local function OnShow()
        tDeleteItem(self.activeFrames, info)
        table.insert(self.activeFrames, 1, info)
        if InCombatLockdown() then return end
        self:HookTabKeys()
    end

    local function OnHide()
        tDeleteItem(self.activeFrames, info)
        if InCombatLockdown() then return end
        if not next(self.activeFrames) then
            self:UnhookTabKeys()
        end
    end

    frame:HookScript("OnShow", OnShow)
    frame:HookScript("OnHide", OnHide)
    if frame:IsShown() then OnShow() end
        
    info.hooked = true
end

function AutoTabButton:OnEvent(event, ...)
    if event == "PLAYER_LOGIN" then
        self:Initialize()
    elseif event == "PLAYER_REGEN_DISABLED" then
        self:UnhookTabKeys()
    elseif event == "PLAYER_REGEN_ENABLED" then
        if next(self.activeFrames) then
            self:HookTabKeys()
        end
    elseif event == "PLAYER_INTERACTION_MANAGER_FRAME_SHOW" then
        local interactionType = ...
        for _, info in ipairs(AutoTabFrames) do
            if info.loadInteractionType and info.loadInteractionType == interactionType then
                self:SetUpFrame(info)
            end
        end
    end
end

function AutoTabButton:Initialize()
    self.activeFrames = {}
    for _, info in ipairs(AutoTabFrames) do
        if info.loadFunc then
            hooksecurefunc(info.loadFunc, function () self:SetUpFrame(info) end)
        elseif _G[info.frame] then
            self:SetUpFrame(info)
        end
    end
    self:SetAttribute("type", "click")
    self:RegisterForClicks("AnyUp", "AnyDown")
    self:SetScript("PreClick", self.PreClick)
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
    self:RegisterEvent("PLAYER_REGEN_ENABLED")
    self:RegisterEvent("PLAYER_INTERACTION_MANAGER_FRAME_SHOW")
end

AutoTabButton:SetScript("OnEvent", AutoTabButton.OnEvent)
AutoTabButton:RegisterEvent("PLAYER_LOGIN")
