-- Slash command to open the DRIVE UI. Could be expanded to other Generic
-- Trait systems if there was any point.

local _, addon = ...

local function Handle(arg)
    if not arg or arg == '' then
        GenericTraitUI_LoadUI()
        for id = 1, 2000 do
            local info = GenericTraitUtil.GetFrameLayoutInfo(id)
            if info and info.Title then
                addon.printf('%d: %s', id, info.Title)
            end
        end
    elseif tonumber(arg) then
        TraitUtil.OpenTraitFrame(arg)
    else
        GenericTraitUI_LoadUI()
        for id = 1, 2000 do
            local info = GenericTraitUtil.GetFrameLayoutInfo(id)
            if info and info.Title and info.Title:find(arg) then
                TraitUtil.OpenTraitFrame(id)
                return
            end
        end
    end
end

local moduleInfo = {
    SlashCommands = {
        ['generic-traits'] = Handle,
        ['gt'] = Handle,
    }
}
addon.RegisterModule(moduleInfo)
