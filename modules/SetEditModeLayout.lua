-- Add a slash command to set the edit mode layout, which without an
-- argument uses the current screen resolution.

local _, addon = ...

local function SetEditModeLayout(layout)
    if tonumber(layout) then
        C_EditMode.SetActiveLayout(tonumber(layout))
        return
    end

    if layout == nil then
        local w, h = GetPhysicalScreenSize()
        layout = tostring(w) .. 'x' .. tostring(h)
    end

    local layoutData = C_EditMode.GetLayouts()

    for i, layoutInfo in ipairs(layoutData.layouts) do
        if layoutInfo.layoutName == layout then
            C_EditMode.SetActiveLayout(i+2)
            return
        end
    end
end

local addonInfo = {
    SlashCommands = {
        ['layout'] = SetEditModeLayout
    }
}
addon.RegisterModule(addonInfo)
