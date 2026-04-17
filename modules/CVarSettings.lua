-- Just some random CVars, miscelleanous crap

local _, addon = ...

local function ApplySettings()
    SetCVar("cooldownViewerEnabled", true)
    SetCVar("damageMeterEnabled", true)

    SetCVar("autoLootDefault", true)
    SetCVar("AutoPushSpellToActionBar", 0)

    SetCVar("raidFramesDisplayClassColor", true)
    SetCVar("raidFramesDisplayPowerBars", true)
    SetCVar("raidFramesDisplayOnlyHealerPowerBars", true)
    SetCVar("raidOptionDisplayMainTankAndAssist", false)
end

EventRegistry:RegisterFrameEventAndCallback('SETTINGS_LOADED', ApplySettings)
