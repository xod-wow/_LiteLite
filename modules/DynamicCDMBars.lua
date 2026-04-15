local _, addon = ...

-- Don't leave gaps in the bar "grid". Who knows what will taint here, but so
-- far this works. Set the invididual itemFrames to not layout when hidden, and
-- force a relayout when their shown state is changed. This is very efficient.

local function DynamicCDMBuffBars()
    local BuffBarCooldownViewer = BuffBarCooldownViewer

    local function Layout()
        BuffBarCooldownViewer:GetItemContainerFrame():Layout()
    end

    local isDirty

    local function MarkDirty()
        isDirty = true
    end

    local function LayoutIfDirty()
        if isDirty then
            Layout()
            isDirty = nil
        end
    end

    local hookedFrames = {}

    local function HookItemFrame(itemFrame)
        if not hookedFrames[itemFrame] then
            itemFrame.includeAsLayoutChildWhenHidden = nil      -- Magic here
            -- hooksecurefunc(itemFrame, 'SetShown', Layout)
            hooksecurefunc(itemFrame, 'SetShown', MarkDirty)
            MarkDirty()
            hookedFrames[itemFrame] = true
        end
    end

    local cdmUpdater = CreateFrame('Frame')
    cdmUpdater:SetScript('OnUpdate', LayoutIfDirty)

    -- Hook them immediately
    for _, itemFrame in ipairs(BuffBarCooldownViewer:GetItemFrames()) do
        HookItemFrame(itemFrame)
    end

    -- And also hook any new ones that are made
    hooksecurefunc(BuffBarCooldownViewer, 'OnAcquireItemFrame',
        function (_, itemFrame) HookItemFrame(itemFrame) end)
end

addon.RegisterModule({ Initialize = DynamicCDMBuffBars })
