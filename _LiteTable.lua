--[[------------------------------------------------------------------------]]--

_LiteTableCellMixin = {}

function _LiteTableCellMixin:OnEnter()
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
        self.UpdateTooltip = self.OnEnter
    end
end

function _LiteTableCellMixin:OnLeave()
    self.UpdateTooltip = nil
    GameTooltip_Hide()
end

function _LiteTableCellMixin:OnClick()
    if self.link and IsModifiedClick("CHATLINK") then
        ChatEdit_LinkItem(self.link)
    end
end


--[[------------------------------------------------------------------------]]--

_LiteLiteTableRowMixin = {}

function _LiteLiteTableRowMixin:OnLoad()
    self.cells = CreateFramePool("Button", self, "_LiteTableCellTemplate")
end

function _LiteLiteTableRowMixin:Init(columnWidths, rowData)
    self.cells:ReleaseAll()

    local offset = 0
    for i = 1, #columnWidths do
        local width, text = columnWidths[i], rowData[i]
        if text then
            local cell = self.cells:Acquire()
            cell:SetSize(width, self:GetHeight())
            cell:SetPoint("LEFT", self, "LEFT", offset, 0)
            text = tostring(text)
            cell.Text:SetFormattedText(text)
            local _, _, link = ExtractHyperlinkString(text)
            cell.link = link
            cell:Show()
        end
        offset = offset + width + 20
    end
end


--[[------------------------------------------------------------------------]]--

_LiteTableMixin = {}

function _LiteTableMixin:Setup(title, columnNames)
    self.title = title
    self.columnNames = columnNames
    self.data = {}
end

function _LiteTableMixin:SetRows(data)
    self.data = data
    self:MarkDirty()
end

function _LiteTableMixin:AddRow(rowData)
    table.insert(self.data, rowData)
    self:MarkDirty()
end

function _LiteTableMixin:CalculateColumnWidths()
    self.columnWidths = {}
    for _, rowData in ipairs(self.data) do
        for i = 1, #rowData do
            local text = rowData[i] or ""
            self.Sizer:SetText(text)
            local width = math.ceil(self.Sizer:GetUnboundedStringWidth())
            self.columnWidths[i] = math.max(self.columnWidths[i] or 0, width)
        end
    end
    for i, columnName in ipairs(self.columnNames) do
        self.Sizer:SetText(columnName)
        local width = math.ceil(self.Sizer:GetUnboundedStringWidth())
        self.columnWidths[i] = math.max(self.columnWidths[i] or 0, width)
    end
end

function _LiteTableMixin:SetupColumnHeaders()
    self.headerFontStrings:ReleaseAll()
    local offset = 0
    for i, name in ipairs(self.columnNames) do
        local fs = self.headerFontStrings:Acquire()
        fs:SetPoint("BOTTOMLEFT", self.ScrollBox, "TOPLEFT", offset, 8)
        fs:SetTextToFit(self.columnNames[i] or "")
        fs:Show()
        offset = offset + self.columnWidths[i] + 20
    end
end

function _LiteTableMixin:Layout()
    self:CalculateColumnWidths()
    self:SetupColumnHeaders()
end

function _LiteTableMixin:UpdateCells()
    self:SetTitle(self.title)
    local dataProvider = CreateDataProvider(self.data)
    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
end

function _LiteTableMixin:MarkDirty()
    self.isDirty = true
    self:SetScript('OnUpdate', self.Clean)
end

function _LiteTableMixin:Clean()
    if self.isDirty then
        self.isDirty = nil
        self:Layout()
        self:UpdateCells()
    end
    self:SetScript('OnUpdate', nil)
end

function _LiteTableMixin:OnLoad()
    ButtonFrameTemplate_HidePortrait(self)
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("_LiteTableRowTemplate",
        function (f, rowData)
            f:Init(self.columnWidths, rowData)
        end)
    view:SetPadding(2,2,2,2,5)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
    ScrollUtil.RegisterAlternateRowBehavior(self.ScrollBox,
        function (button, isAlternate)
            button.Stripe:SetShown(isAlternate)
        end)

    table.insert(UISpecialFrames, self:GetName())
    self.Sizer = self:CreateFontString(nil, nil, "GameFontNormal")
    self.headerFontStrings = CreateFontStringPool(self, "ARTWORK", 0, "GameFontNormalMed1")
end

