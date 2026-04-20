-- Show buttons to the left of the professions panel to switch professions.
-- Todo: make the buttons nice

local _, addon = ...

local TabButtons = { }

local function Update()
    local p1, p2, _, fishing, cooking = GetProfessions()
    for i, index in ipairs({ p1, p2, fishing, cooking }) do
        local _, icon, _, _, _, _, skillLine = GetProfessionInfo(index)
        TabButtons[i]:SetNormalTexture(icon)
        TabButtons[i]:Show()
        TabButtons[i]:SetScript('OnClick', function () C_TradeSkillUI.OpenTradeSkill(skillLine) end)
    end
end

local function CreateTabButtons()
    for i = 1, 4 do
        local b = CreateFrame('Button', nil, ProfessionsFrame)
        b:SetSize(32, 32)
        TabButtons[i] = b
        if i == 1 then
            b:ClearAllPoints()
            b:SetPoint("TOPRIGHT", ProfessionsFrame, "TOPLEFT", -2, -48)
        else
            b:SetPoint("TOP", TabButtons[i-1], "BOTTOM", 0, -4)
        end
    end
    ProfessionsFrame:HookScript('OnShow', Update)
end

local function Initialize()
    if ProfessionsFrame then
        CreateTabButtons()
    else
        hooksecurefunc('ProfressionsFrame_LoadUI', CreateTabButtons)
    end
end

addon.RegisterModule({ Initialize = Initialize })
