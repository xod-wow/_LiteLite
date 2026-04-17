-- Show spell/item/unit IDs in tooltips. This will bug the hell out in various
-- secret-ladent scenarios and is generally only useful for temporary debugging.

local _, addon = ...

local function HookTooltip()
    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Item,
        function (ttFrame)
            local _, link = ttFrame:GetItem()
            local id = GetItemInfoFromHyperlink(link)
            if id then
                ttFrame:AddDoubleLine("ItemID", id)
            end
        end)

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Spell,
        function (ttFrame)
            local _, id = ttFrame:GetSpell()
            if id then
                ttFrame:AddDoubleLine("SpellID", id)
            end
        end)

    TooltipDataProcessor.AddTooltipPostCall(
        Enum.TooltipDataType.Unit,
        function (ttFrame)
            local _, unit = ttFrame:GetUnit()
            if unit then
                local _, _, _, _, _, id = strsplit('-', UnitGUID(unit))
                if id then
                    ttFrame:AddDoubleLine("UnitID", id)
                end
            end
        end)
end

local moduleInfo = {
    SlashCommands = {
        ['tooltip-ids'] = HookTooltip,
        ['ti'] = HookTooltip,
    }
}
addon.RegisterModule(moduleInfo)
