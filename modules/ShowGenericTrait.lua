-- Slash command to open the DRIVE UI. Could be expanded to other Generic
-- Trait systems if there was any point.

local _, addon = ...

local moduleInfo = {
    SlashCommands = {
        ['drive'] = function () TraitUtil.OpenTraitFrame(1056) end,
        ['loa'] = function () TraitUtil.OpenTraitFrame(1166) end,
        ['void'] = function () TraitUtil.OpenTraitFrame(1180) end,
    }
}
addon.RegisterModule(moduleInfo)
