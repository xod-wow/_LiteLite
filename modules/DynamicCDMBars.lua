-- Change the buff bars (not icons) in the cooldown manager so that they grow
-- upwards and are not in fixed places with gaps for any that aren't active.
-- Configured order is still respected.
--
-- Who knows what will taint here, but so far this works.
--
-- Set the invididual itemFrames to not "layout when hidden", and force a
-- re-layout when their shown state is changed. This is very efficient and
-- I feel much more clever than I should.

local _, addon = ...

local SpellIDColors = {
    DEFAULT     = { 1.00, 0.50, 0.25 },
    [132578]    = { 0.75, 0.75, 0.75 },     -- Invoke Niuzao, the Black Ox
    [184361]    = { 1.00, 0.25, 0.25 },     -- Enrage
    [12950]     = { 0.25, 0.25, 1.00 },     -- Improved Whirlwind
    [115203]    = { 0.25, 0.25, 1.00 },     -- Fortifying Brew
    [1249625]   = { 0.25, 1.00, 0.25 },     -- Zenith
    [322118]    = { 0.25, 0.75, 0.50 },     -- Invoke Yu'lon, the Jade Serpent
    [325192]    = { 1.00, 0.75, 0.25 },     -- Invoke Chi-Ji, the Red Crane
    [449582]    = { 0.25, 0.75, 1.00 },     -- Lighter than Air
}

local CooldownIDColors = { }

local function GetCooldownIDColor(id)
    if id and not CooldownIDColors[id] then
        local info = C_CooldownViewer.GetCooldownViewerCooldownInfo(id)
        if info and info.spellID then
            CooldownIDColors[id] = SpellIDColors[info.spellID]
        end
    end
    return CooldownIDColors[id] or SpellIDColors.DEFAULT
end

local function DynamicCDMBuffBars()
    local BuffBarCooldownViewer = BuffBarCooldownViewer

    local function Recolor()
        for _, itemFrame in ipairs(BuffBarCooldownViewer:GetItemFrames()) do
            local c = GetCooldownIDColor(itemFrame.cooldownID)
            itemFrame.Bar:SetStatusBarColor(unpack(c))
        end
    end

    local function Layout()
        BuffBarCooldownViewer:GetItemContainerFrame():Layout()
    end

    local isDirty

    local function MarkDirty()
        isDirty = true
    end

    local function UpdateIfDirty()
        if isDirty then
            Layout()
            Recolor()
            isDirty = nil
        end
    end

    local hookedFrames = {}

    local function HookItemFrame(itemFrame)
        if not hookedFrames[itemFrame] then
            itemFrame.includeAsLayoutChildWhenHidden = nil      -- Magic here
            hooksecurefunc(itemFrame, 'SetShown', MarkDirty)
            MarkDirty()
            hookedFrames[itemFrame] = true
        end
    end

    local cdmUpdater = CreateFrame('Frame')
    cdmUpdater:SetScript('OnUpdate', UpdateIfDirty)

    -- Hook them immediately
    for _, itemFrame in ipairs(BuffBarCooldownViewer:GetItemFrames()) do
        HookItemFrame(itemFrame)
    end

    -- And also hook any new ones that are made
    hooksecurefunc(BuffBarCooldownViewer, 'OnAcquireItemFrame',
        function (_, itemFrame) HookItemFrame(itemFrame) end)
end

addon.RegisterModule({ Initialize = DynamicCDMBuffBars })
