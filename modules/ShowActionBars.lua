local _, addon = ...

local function Initialize()
    -- SetCVar('enableMultiActionBars', 0x1f)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_2", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_3", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_4", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_5", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_6", true)
end

EventUtil.RegisterOnceFrameEventAndCallback("SETTINGS_LOADED", Initialize)
