local _, addon = ...

--[[

    Create and maintain a global 'Kick' macro that handles setting a
    target marker and focus.

    This is compatible with FocusKick. The marker used is your position in the
    name-sorted list of party members.

]]


local GlobalMacroName = "Kick"

local GlobalMacroBody = [[#showtooltip
/focus [mod,@mouseover,harm,nodead][mod,harm,nodead]
/tm [@focus,mod] ~{markIndex}
/stopmacro [mod]
/cast [@focus,harm] {spellName}; {spellName}]]

local Interrupts = {
    [ 47528] = true,                -- Mind Freeze (Death Knight)
    [183752] = true,                -- Disrupt (Demon Hunter)
    [ 78675] = true,                -- Solar Beam (Druid)
    [106839] = true,                -- Skull Bash (Druid)
    [147362] = true,                -- Counter Shot (Hunter)
    [187707] = true,                -- Muzzle (Hunter)
    [  2139] = true,                -- Counterspell (Mage)
    [116705] = true,                -- Spear Hand Strike (Monk)
    [ 96231] = true,                -- Rebuke (Paladin)
    [ 15487] = true,                -- Silence (Priest)
    [  1766] = true,                -- Kick (Rogue)
    [ 57994] = true,                -- Wind Shear (Shaman)
    [119910] = true,                -- Spell Lock (Warlock Felhunter Pet)
    [132409] = true,                -- Spell Lock (Warlock Fel Ravager)
    [119914] = true,                -- Axe Toss (Warlock Felguard Pet)
    [  6552] = true,                -- Pummel (Warrior)
    [351338] = true,                -- Quell (Evoker)
}

local Updater = CreateFrame('Frame')

function Updater:UpdateSpellName()
    self.spellName = nil
    for spellID in pairs(Interrupts) do
        if C_SpellBook.IsSpellKnown(spellID) then
            self.spellName = C_Spell.GetSpellName(spellID)
        end
    end
end

function Updater:UpdateMarkIndex()
    local oldIndex = self.markIndex
    local playerName = UnitName('player')
    local names = { playerName }
    for i = 1, 4 do
        local unit = 'party'..i
        if UnitExists(unit) then
            local name = UnitName(unit)
            table.insert(names, name)
        end
    end
    table.sort(names)
    local newIndex = tIndexOf(names, playerName)
    if newIndex ~= oldIndex then
        self.markIndex = newIndex
        self.markText = string.format('{rt%d}', newIndex)
        local markText = C_ChatInfo.ReplaceIconAndGroupExpressions(self.markText)
        addon.printf("Changing interrupt marker to %s", markText)
    end
end

function Updater:CreateOrUpdateGlobalMacro()
    -- In theory this should check if we are in M+ but ignore it for now since
    -- the only triggers are group change and spec/talent change, none of which
    -- can happen then.
    if self.spellName and not InCombatLockdown() then
        local replacements = {
            spellName = self.spellName,
            markIndex = self.markIndex,
        }
        local body = string.gsub(GlobalMacroBody, '{(.-)}', replacements)
        local macroIndex = GetMacroIndexByName(GlobalMacroName)
        if macroIndex > 0 then
            EditMacro(macroIndex, nil, nil, body)
        else
            CreateMacro(GlobalMacroName, 134400, body)
        end
    end
end

function Updater:FullUpdate()
    self:UpdateSpellName()
    self:UpdateMarkIndex()
    self:CreateOrUpdateGlobalMacro()
end

function Updater:NotifyMark()
    if self.interruptSpell and not IsInRaid() and IsInGroup(LE_PARTY_CATEGORY_HOME) then
        local msg = string.format('Interrupting %s', self.markText)
        SendChatMessage(msg, "PARTY")
    end
end

function Updater:OnEvent(event)
    if event == 'ACTIVE_TALENT_GROUP_CHANGED' or event == 'PLAYER_SPECIALIZATION_CHANGED' then
        self:UpdateSpellName()
        self:CreateOrUpdateGlobalMacro()
    elseif event == 'GROUP_ROSTER_UPDATE' then
        self:UpdateMarkIndex()
        self:CreateOrUpdateGlobalMacro()
    elseif event == 'READY_CHECK' then
        self:NotifyMark()
    end
end

local function Initialize()
    Updater:RegisterEvent('ACTIVE_TALENT_GROUP_CHANGED')
    Updater:RegisterEvent('PLAYER_SPECIALIZATION_CHANGED')
    Updater:RegisterEvent('GROUP_ROSTER_UPDATE')
    Updater:RegisterEvent('READY_CHECK')
    Updater:SetScript('OnEvent', Updater.OnEvent)
    Updater:FullUpdate()
end

local moduleInfo = {
    Initialize = Initialize,
    SlashCommands = {
        ['focus-interrupt'] = function () Updater:FullUpdate() end,
    }
}
addon.RegisterModule(moduleInfo)

