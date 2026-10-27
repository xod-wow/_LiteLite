local _, addon = ...

local function PreClick(button)
    local savedOnClick = button:GetScript('OnClick')
    if not IsShiftKeyDown() then
        button:SetScript('OnClick', nil)
        button:SetScript('PostClick',
            function ()
                button:SetScript('OnClick', savedOnClick)
                button:SetScript('PostClick', nil)
            end)
    end
end

local function Initialize()
    BonusRollFrame.PromptFrame.RollButton:SetScript('PreClick', PreClick)
end

if WOW_PROJECT_ID == 1 then
    addon.RegisterModule({ Initialize = Initialize })
end
