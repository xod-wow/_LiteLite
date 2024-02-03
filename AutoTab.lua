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
    {
        frame =                 "ProfessionsFrame",
        loadFunc =              "ProfessionsFrame_LoadUI",
    },
}

CreateFrame("Button", "AutoTabButton", nil, "SecureActionButtonTemplate")

local function rotateN(currentVal, numVals, increment)
    return  ( currentVal - 1 + increment ) % numVals + 1
end

local function GetNextTabButton(info, direction)
    local frame = _G[info.frame]
    local tabButtons, currentTab, numTabs

    -- Try to handle all the different tabbing mechanisms

    if frame.Tabs and frame.selectedTab then
        currentTab = frame.selectedTab
        tabButtons = frame.Tabs
        numTabs = frame.numTabs
    elseif frame.numTabs and frame.selectedTab then
        currentTab = frame.selectedTab
        tabButtons = { }
        for i = 1, frame.numTabs do
            table.insert(tabButtons, _G[frame:GetName().."Tab"..i])
        end
        numTabs = #tabButtons
    elseif frame.Tabs and frame.currentTab then
        for i, tabButton in ipairs(frame.Tabs) do
            if tabButton == frame.currentTab then
                currentTab = i
                break
            end
        end
        tabButtons = frame.Tabs
        numTabs = frame.numTabs
    elseif frame.TabSystem then
        currentTab = frame.TabSystem.selectedTabID
        tabButtons = {}
        for _, tab in ipairs(frame.TabSystem.tabs) do
            table.insert(tabButtons, tab)
        end
        numTabs = #tabButtons
    elseif info.tabKeys then
        tabButtons = {}
        local tab = 0
        for i, tabKey in ipairs(info.tabKeys) do
            table.insert(tabButtons, frame[tabKey])
            if frame[tabKey]:GetChecked() then
                currentTab = i
            end
        end
        numTabs = #tabButtons
    end

    if currentTab then
        newTab = currentTab
        while true do
            newTab = rotateN(newTab, numTabs, direction)
            if newTab == currentTab then break end
            local tabButton = tabButtons[newTab]
            -- This should probably be moved to the info struct
            if tabButton:IsShown() and not tabButton.forceDisabled and tabButton:IsEnabled() then
                return tabButton
            end
        end
    end
end

function AutoTabButton:PreClick(key)
    if InCombatLockdown() then return end
    local info = self.activeFrames[1]
    if not info then return end
    local direction = key == 'TAB' and 1 or -1
    local tabButton = GetNextTabButton(info, direction)
    self:SetAttribute("clickbutton", tabButton)
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
