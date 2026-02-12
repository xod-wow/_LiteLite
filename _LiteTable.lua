--[[------------------------------------------------------------------------]]--

local function GetCellDisplayText(val)
    if val == nil then
        return ""
    elseif type(val) == 'boolean' then
        if val then return YES else return NO end
    elseif type(val) == 'string' then
        return val
    elseif type(val) == 'number' then
        return tostring(val)
    end
end


--[[------------------------------------------------------------------------]]--

_LiteTableHeaderMixin = {}

function _LiteTableHeaderMixin:OnClick()
    local tableWidget = self:GetParent()
    local columnNumber = self:GetID()
    if tableWidget:GetSortColumn() == columnNumber then
        tableWidget:SetSortColumn(-columnNumber)
    else
        tableWidget:SetSortColumn(columnNumber)
    end
end


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

    local color = rowData.color or WHITE_FONT_COLOR
    local offset = 8
    for i = 1, #columnWidths do
        local width, val = columnWidths[i], rowData[i]
        if val ~= nil then
            local cell = self.cells:Acquire()
            cell:SetSize(width, self:GetHeight())
            cell:SetPoint("LEFT", self, "LEFT", offset, 0)
            local text = GetCellDisplayText(val)
            cell.Text:SetText(text)
            cell.Text:SetTextColor(color:GetRGBA())
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
            local text = GetCellDisplayText(rowData[i])
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

function _LiteTableMixin:UpdateWidth()
    if self.autoWidth then
        local w = 16 + 34 + 8 + 8 + 20*(#self.columnWidths-1)
        for _, n in ipairs(self.columnWidths) do
            w = w + n
        end
        self:SetWidth(w)
    end
end

function _LiteTableMixin:SetAutoWidth(v)
    self.autoWidth = v and true or nil
end

function _LiteTableMixin:SetEnableSort(v)
    self.enableSort = v and true or nil
end

function _LiteTableMixin:SetFooter(text)
    self.footer = text
end

function _LiteTableMixin:SetupColumnHeaders()
    self.headerCells:ReleaseAll()
    local offset = 8
    for i, name in ipairs(self.columnNames) do
        local cell = self.headerCells:Acquire()
        cell:SetID(i)
        cell:ClearAllPoints()
        cell:SetPoint("BOTTOMLEFT", self.ScrollBox, "TOPLEFT", offset, 2)
        cell:SetWidth(self.columnWidths[i])
        cell.Text:SetTextToFit(self.columnNames[i] or "")
        cell:Show()
        offset = offset + self.columnWidths[i] + 20
    end
end

function _LiteTableMixin:Layout()
    self:CalculateColumnWidths()
    self:SetupColumnHeaders()
    self:UpdateWidth()
end

function _LiteTableMixin:GetSortColumn()
    return self.sortColumn
end

function _LiteTableMixin:SetSortColumn(n)
    self.sortColumn = n
    if self:IsShown() then
        self:UpdateCells()
    end
end

function _LiteTableMixin:UpdateCells()
    self:SetTitle(self.title)
    local dataProvider = CreateDataProvider(self.data)
    if self.enableSort and self.sortColumn then
        local n = math.abs(self.sortColumn)
        local function colComp(a, b)
            local aVal = tonumber(a[n]) or GetCellDisplayText(a[n])
            local bVal = tonumber(b[n]) or GetCellDisplayText(b[n])
            if self.sortColumn >= 0 then
                return aVal < bVal
            else
                return aVal > bVal
            end
        end
        dataProvider:SetSortComparator(colComp)
    end
    self.ScrollBox:SetDataProvider(dataProvider, ScrollBoxConstants.RetainScrollPosition)
    if self.footer then
        self.Footer:SetText(self.footer)
        self.Footer:Show()
    else
        self.Footer:Hide()
    end
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
    -- view:SetPadding(2,2,2,2,5)
    ScrollUtil.InitScrollBoxListWithScrollBar(self.ScrollBox, self.ScrollBar, view)
    ScrollUtil.RegisterAlternateRowBehavior(self.ScrollBox,
        function (button, isAlternate)
            button.Stripe:SetShown(isAlternate)
        end)

    table.insert(UISpecialFrames, self:GetName())
    self.Sizer = self:CreateFontString(nil, nil, "GameFontNormal")
    self.headerCells = CreateFramePool("Button", self, "_LiteTableHeaderTemplate")
end

function _LiteTableMixin:Reset()
    self:Hide()
    self.data = {}
    self.footer = nil
    self.sortColumn = nil
    self.columnNames = nil
    self.columnWidths = {}
    self.autoWidth = nil
    self.enableSort = nil
    self.isDirty = nil
    self:SetScript('OnUpdate', nil)
    if self.cells then
        self.cells:ReleaseAll()
    end
    if self.headerCells then
        self.headerCells:ReleaseAll()
    end
end
