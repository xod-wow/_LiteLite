-- Just some random CVars, miscelleanous crap

local _, addon = ...

local function ApplySettings()
    SetCVar("cooldownViewerEnabled", true)

    SetCVar("autoLootDefault", true)

    if EXPANSION_LEVEL > 0 then
        SetCVar("AutoPushSpellToActionBar", 0)
    end

    SetCVar("raidFramesDisplayClassColor", true)
    SetCVar("raidFramesDisplayPowerBars", true)
    SetCVar("raidFramesDisplayOnlyHealerPowerBars", true)
    SetCVar("raidOptionDisplayMainTankAndAssist", false)
end

EventRegistry:RegisterFrameEventAndCallback('SETTINGS_LOADED', ApplySettings)
