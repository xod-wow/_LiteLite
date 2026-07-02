-- Show buttons to the left of the professions panel to switch professions.
-- Todo: make the buttons nice

local _, addon = ...

local TabButtons = { }

local function Update()
    local p1, p2, _, fishing, cooking = GetProfessions()
    for i, index in ipairs({ p2, p1, fishing, cooking }) do
        local _, icon, _, _, _, _, skillLine = GetProfessionInfo(index)
        TabButtons[i]:SetNormalTexture(icon)
        TabButtons[i]:Show()
        TabButtons[i]:SetScript('OnClick', function () C_TradeSkillUI.OpenTradeSkill(skillLine) end)
    end
end

local function CreateTabButtons()
    for i = 1, 4 do
        local b = CreateFrame('Button', nil, ProfessionsFrame)
        b:SetSize(24, 24)
        TabButtons[i] = b
        if i == 1 then
            b:ClearAllPoints()
            b:SetPoint("BOTTOMRIGHT", ProfessionsFrame, "TOPRIGHT", -48, 2)
        elseif i == 3 then
            b:SetPoint("RIGHT", TabButtons[i-1], "LEFT", -16, 0)
        else
            b:SetPoint("RIGHT", TabButtons[i-1], "LEFT", -4, 0)
        end
    end
    ProfessionsFrame:HookScript('OnShow', Update)
end

local function Initialize()
    if ProfessionsFrame then
        CreateTabButtons()
    elseif ProfessionsFrame_LoadUI then
        hooksecurefunc('ProfessionsFrame_LoadUI', CreateTabButtons)
    end
end

addon.RegisterModule({ Initialize = Initialize })
