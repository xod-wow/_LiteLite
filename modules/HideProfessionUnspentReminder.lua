local _, addon = ...

local function Initialize()
    hooksecurefunc('MainMenuMicroButton_ShowAlert',
        function (microButton, text, _tutorialIndex, _cvarBitfield)
            if text == PROFESSIONS_UNSPENT_SPEC_POINTS_REMINDER then
                -- print(microButton:GetName(), text, 'triggered')
                MainMenuMicroButton_HideAlert(microButton)
                MicroButtonPulseStop(microButton)
            end
        end)
end

addon.RegisterModule({ Initialize = Initialize })
