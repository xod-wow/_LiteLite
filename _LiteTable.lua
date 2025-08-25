--[[------------------------------------------------------------------------]]--

_LiteTableCellMixin = {}

function _LiteTableCellMixin:OnEnter()
    if self.link then
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetHyperlink(self.link)
        GameTooltip:Show()
    end
end

function _LiteTableCellMixin:OnLeave()
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

function _LiteLiteTableRowMixin:Init(fieldWidths, rowData)
    self.cells:ReleaseAll()

    local offset = 0
    for i = 1, #fieldWidths do
        local width, text = fieldWidths[i], rowData[i]
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

function _LiteTableMixin:Update()
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
        self:Update()
    end
    self:SetScript('OnUpdate', nil)
end

function _LiteTableMixin:OnLoad()
    ButtonFrameTemplate_HidePortrait(self)
    local view = CreateScrollBoxListLinearView()
    view:SetElementInitializer("_LiteTableRowTemplate",
        function (f, rowData)
            f:Init(self.fieldWidths, rowData)
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

function _LiteTableMixin:Layout()
    self.fieldWidths = {}
    for _, rowData in ipairs(self.data) do
        for i = 1, #rowData do
            local text = rowData[i] or ""
            self.Sizer:SetText(text)
            local width = math.ceil(self.Sizer:GetUnboundedStringWidth())
            self.Sizer:SetText(self.columnNames[i])
            local headerWidth = math.ceil(self.Sizer:GetUnboundedStringWidth())
            self.fieldWidths[i] = math.max(self.fieldWidths[i] or 0, width, headerWidth)
        end
    end
    self.headerFontStrings:ReleaseAll()
    local offset = 0
    for i, name in ipairs(self.columnNames) do
        local fs = self.headerFontStrings:Acquire()
        fs:SetPoint("BOTTOMLEFT", self.ScrollBox, "TOPLEFT", offset, 8)
        fs:SetTextToFit(self.columnNames[i] or "")
        fs:Show()
        offset = offset + self.fieldWidths[i] + 20
    end
end
