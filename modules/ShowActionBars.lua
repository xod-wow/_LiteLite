-- Settings to ensure I have action bars 1-6 shown.

local _, addon = ...

local function Initialize()
    -- SetCVar('enableMultiActionBars', 0x1f)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_2", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_3", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_4", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_5", true)
    Settings.SetValue("PROXY_SHOW_ACTIONBAR_6", true)
end

-- Not using addon.RegisterModules as SETTINGS_LOADED is later and
-- the Settings PROXY stuff isn't available yet at PLAYER_LOGIN.

if WOW_PROJECT_ID == 1 then
    EventUtil.RegisterOnceFrameEventAndCallback("SETTINGS_LOADED", Initialize)
end
