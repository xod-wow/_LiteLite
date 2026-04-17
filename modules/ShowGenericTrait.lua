-- Slash command to open the DRIVE UI. Could be expanded to other Generic
-- Trait systems if there was any point.

local _, addon = ...

local function ShowDRIVE()
    C_AddOns.LoadAddOn("Blizzard_GenericTraitUI")
    GenericTraitFrame:SetTreeID(1056)
    GenericTraitFrame:Show()
    GenericTraitFrame:SetParent(UIParent)
    GenericTraitFrame:ClearAllPoints()
    GenericTraitFrame:SetPoint("CENTER")
end

local moduleInfo = {
    SlashCommands = {
        ['drive'] = ShowDRIVE,
    }
}
addon.RegisterModule(moduleInfo)
