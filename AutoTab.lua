local AutoTabFrames = {
    {
        binding =   "TOGGLEACHIEVEMENT",
        frame =     "AchievementFrame",
        loader =    "AchievementFrame_LoadUI",
    },
    {
        binding =   "TOGGLECOLLECTIONS",
        frame =     "CollectionsJournal",
    },
    {
        binding =   "TOGGLECHARACTER0",
        frame =     "CharacterFrame",
    },
    {
        binding =   "TOGGLESPELLBOOK",
        frame =     "SpellBookFrame",
    },
    {
        binding =   "TOGGLETALENTS",
        frame =     "ClassTalentFrame",
        loader =    "ClassTalentFrame_LoadUI"
    },
    {
        binding =   "TOGGLEGROUPFINDER",
        frame =     "PVEFrame",
    },
    {
        binding =   "TOGGLESOCIAL",
        frame =     "FriendsFrame",
    },
    {
        binding =   "TOGGLEGUILDTAB",
        frame =     "CommunitiesFrame",
        loader =    "Communities_LoadUI",
        tabKeys =   { "ChatTab", "RosterTab", "GuildBenefitsTab", "GuildInfoTab" },
    },
    {
        binding =   "TOGGLEENCOUNTERJOURNAL",
        frame =     "EncounterJournal",
        loader =    "EncounterJournal_LoadUI",
    },
}

CreateFrame("Button", "AutoTabButton", nil, "SecureActionButtonTemplate")

function AutoTabButton:PreClick(key)
    if InCombatLockdown() then return end
    local info = self[key]
    if not info then return end
    local frame = _G[info.frame]
    if frame.Tabs and frame.selectedTab then
        local tab = frame.selectedTab
        local newTab = tab % frame.numTabs + 1
        local tabButton = frame.Tabs[newTab]
        self:SetAttribute("clickbutton", tabButton)
    elseif frame.numTabs and frame.selectedTab then
        local tab = frame.selectedTab
        local newTab = tab % frame.numTabs + 1
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
            local newTab = tab % frame.numTabs + 1
            local tabButton = frame.Tabs[newTab]
            self:SetAttribute("clickbutton", tabButton)
        end
    elseif frame.TabSystem then
        local tab = frame.TabSystem.selectedTabID
        local newTab = tab % #frame.TabSystem.tabs + 1
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
        local newTab = tab % #info.tabKeys + 1
        tabButton = frame[info.tabKeys[newTab]]
        self:SetAttribute("clickbutton", tabButton)
    end
end

function AutoTabButton:SetUpFrame(info)
    if info.hooked then return end
    local frame = _G[info.frame]
    frame:HookScript("OnShow",
        function ()
            if InCombatLockdown() then return end
            local key = GetBindingKey(info.binding)
            if key then
                self[key] = info
                SetOverrideBindingClick(self, true, key, self:GetName(), key)
            end
        end)
    frame:HookScript("OnHide",
        function ()
            if InCombatLockdown() then return end
            local key = GetBindingKey(info.binding)
            if key then
                SetOverrideBinding(self, true, key, nil)
                self[key] = nil
            end
        end)
    info.hooked = true
end

function AutoTabButton:OnEvent(event, ...)
    print('abc')
    if event == "PLAYER_LOGIN" then
        self:Initialize()
    elseif event == "PLAYER_REGEN_DISABLED" then
        ClearOverrideBindings(self)
    end
end

function AutoTabButton:Initialize()
    for _, info in ipairs(AutoTabFrames) do
        if info.loader then
            hooksecurefunc(info.loader, function () self:SetUpFrame(info) end)
        else
            self:SetUpFrame(info)
        end
    end
    self:SetAttribute("type", "click")
    self:RegisterForClicks("AnyUp", "AnyDown")
    self:SetScript("PreClick", self.PreClick)
    self:RegisterEvent("PLAYER_REGEN_DISABLED")
end

AutoTabButton:SetScript("OnEvent", AutoTabButton.OnEvent)
AutoTabButton:RegisterEvent("PLAYER_LOGIN")
