local _, addon = ...

local BindingOrder = { "F1", "F2", "F3", "F4" }

local CurrentBindings = {}

local EventFrame = CreateFrame('Frame')

function EventFrame:UpdateBindings()
    local abilities = C_ZoneAbility.GetActiveAbilities()
    table.sort(abilities, function (a,b) return a.uiPriority < b.uiPriority end)

    for i = 1, #BindingOrder do
        local info = abilities[i]
        if info and info.spellID then
            if CurrentBindings[i] ~= info.spellID then
                CurrentBindings[i] = info.spellID
                local name = C_Spell.GetSpellName(info.spellID)
                print('name', name)
                SetOverrideBindingSpell(self, false, BindingOrder[i], name)
            end
        elseif CurrentBindings[i] then
            SetOverrideBinding(self, false, BindingOrder[i], nil)
        end
    end
end

function EventFrame:MarkDirty()
    if not self.isDirty then
        self.isDirty = true
        C_Timer.After(0, function () self:Clean() end)
    end
end

function EventFrame:Clean()
    if not InCombatLockdown() then
        self:UpdateBindings()
    end
    self.isDirty = nil
end

local function Initialize()
    EventFrame:RegisterEvent("SPELLS_CHANGED")
    EventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
    EventFrame:SetScript("OnEvent", EventFrame.MarkDirty)
    EventFrame:UpdateBindings()
end

addon.RegisterModule({ Initialize = Initialize })
