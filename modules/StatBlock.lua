local _, addon = ...

local stats = {
    {
        text = "Avoidance",
        get = function () return GetCombatRatingBonus(CR_AVOIDANCE) end,
        format = "%.1f%%",
    },
    {
        text = "Leech",
        get = function () return GetLifesteal() end,
        format = "%.1f%%",
    },
    {
        text = "Versatility",
        get =
            function ()
                return GetCombatRatingBonus(CR_VERSATILITY_DAMAGE_DONE)
                     + GetVersatilityBonus(CR_VERSATILITY_DAMAGE_DONE)
            end,
        format = "%.1f%%",
        color = FACTION_GREEN_COLOR,
    },
    {
        text = "Mastery",
        get = function () return GetMasteryEffect() end,
        format = "%.1f%%",
        color = YELLOW_FONT_COLOR,
    },
    {
        text = "Haste",
        get = function () return GetHaste() end,
        format = "%.1f%%",
        color = ORANGE_FONT_COLOR,
    },
    {
        text = "Crit",
        get = function () return GetSpellCritChance() end,
        format = "%.1f%%",
        color = FACTION_RED_COLOR,
    },
    {
        text =
            function ()
                local spec = C_SpecializationInfo.GetSpecialization()
                local primaryStat = select(6, C_SpecializationInfo.GetSpecializationInfo(spec))
                if primaryStat == 1 then
                    return "Strength"
                elseif primaryStat == 2 then
                    return "Agility"
                elseif primaryStat == 4 then
                    return "Intellect"
                end
            end,
        get =
            function ()
                local spec = C_SpecializationInfo.GetSpecialization()
                local primaryStat = select(6, C_SpecializationInfo.GetSpecializationInfo(spec))
                if primaryStat then
                    return UnitStat('player', primaryStat)
                end
            end,
        format = "%d",
        color = EPIC_PURPLE_COLOR,
    },
}

local LineMixin = {}

function LineMixin:UpdateFromInfo(info)
    local text = type(info.text) == 'function' and info.text() or info.text
    local v = info.get()
    if v then
        local valueString = string.format(info.format, v)
        self.LeftText:SetText(text)
        self.RightText:SetText(valueString)
    end
    return self.LeftText:GetWidth() + self.RightText:GetWidth() + 12
end

function LineMixin:Initialize(font, color)
    self:SetHeight(font:GetFontHeight() + 4)

    self.LeftText = self:CreateFontString(nil, "ARTWORK", font:GetName())
    self.LeftText:SetPoint("LEFT", self, "LEFT", 2)
    if color then
        self.LeftText:SetTextColor(color:GetRGB())
    end

    self.RightText = self:CreateFontString(nil, "ARTWORK", font:GetName())
    self.RightText:SetPoint("RIGHT", self, "RIGHT", -2)
    if color then
        self.RightText:SetTextColor(color:GetRGB())
    end
end

local function CreateLine(self, layoutIndex, font, color)
    local line = CreateFrame("Frame", nil, self)
    Mixin(line, LineMixin)
    line:Initialize(font, color)
    line.layoutIndex = layoutIndex
    return line
end

local StatBlock = CreateFrame("Frame", nil, UIParent, "VerticalLayoutFrame")
StatBlock:SetPoint("BOTTOMLEFT", ChatFrame1Background, "BOTTOMRIGHT", 4, 0)
StatBlock.childLayoutDirection = "bottomToTop"
for i, info in pairs(stats) do
    StatBlock[i] = CreateLine(StatBlock, i, NumberFontNormal, info.color)
end

local function Update()
    local width = 0
    for i, info in pairs(stats) do
        local lineWidth = StatBlock[i]:UpdateFromInfo(info)
        width = math.max(width, lineWidth)
    end
    for i in ipairs(StatBlock) do
        StatBlock[i]:SetWidth(width)
    end
    StatBlock:Layout()
end

--[[
StatBlock:SetScript('OnUpdate',
    function (self, elapsed)
        self.elapsed = (self.elapsed or 0) + elapsed
        if self.elapsed > 0.25 then
            Update(self)
            self.elapsed = 0
        end
    end)
]]

-- It's not even vaguely clear that this is worth it compared to
-- OnUpdate. This crazy list of events taken from PaperDollFrame.
StatBlock:SetScript('OnEvent', Update)
StatBlock:RegisterEvent("PLAYER_ENTERING_WORLD")
StatBlock:RegisterEvent("CHARACTER_POINTS_CHANGED")
StatBlock:RegisterEvent("UNIT_STATS")
StatBlock:RegisterEvent("UNIT_RANGEDDAMAGE")
StatBlock:RegisterEvent("UNIT_ATTACK_POWER")
StatBlock:RegisterEvent("UNIT_RANGED_ATTACK_POWER")
StatBlock:RegisterEvent("UNIT_ATTACK")
StatBlock:RegisterEvent("UNIT_SPELL_HASTE")
StatBlock:RegisterEvent("UNIT_RESISTANCES")
StatBlock:RegisterEvent("SKILL_LINES_CHANGED")
StatBlock:RegisterEvent("COMBAT_RATING_UPDATE")
StatBlock:RegisterEvent("MASTERY_UPDATE")
StatBlock:RegisterEvent("SPEED_UPDATE")
StatBlock:RegisterEvent("LIFESTEAL_UPDATE")
StatBlock:RegisterEvent("AVOIDANCE_UPDATE")
StatBlock:RegisterEvent("PLAYER_TALENT_UPDATE")
StatBlock:RegisterEvent("PLAYER_DAMAGE_DONE_MODS")
StatBlock:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
StatBlock:RegisterUnitEvent("UNIT_DAMAGE", "player")
StatBlock:RegisterUnitEvent("UNIT_ATTACK_SPEED", "player")
StatBlock:RegisterEvent("PLAYER_TARGET_CHANGED")
