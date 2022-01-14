-- Business administration & national economy (for FS22)
-- main frame file: BaNeMenuMainFrame.lua
-- v1.2.5b
--
-- @author [kwa:m]
-- @date 20.12.2021
--
-- Copyright (c) [kwa:m]
-- v1.2.5b - close to add leasing of fields (GUI good to go)
-- v1.2.0b - completly rewritten save- und load-functions for settings (dynamic, better structured, better to go with fields then ... hard work, gosh)
-- v1.1.5b - base UI has option besides buying farmland to lease the farmland (to be implemented) - price is per field ha not like buyprice for farmland ha
-- v1.1.0b - added first iteration of field pricing
-- v1.0.1b - added jobType branch in helper factors
-- v1.0.0b - finished helper settings w/ working GUI (able to present as SP beta version)
-- v0.6.0a - added customizable nighttime/overtime factors
-- v0.5.0a - done GUI general layout, changed initialization process
-- v0.1.0a - added first iteration of GUI
-- v0.0.5a - added version in XML to overwrite values if changed defaults (TODO: GUI with possibility to warn that changes happened)
-- v0.0.3a - working alpha release with fixed values and manual xml editing for savegame
-- v0.0.1a - initial alpha release for internal testing (021221)

BaNeMenuMainFrame = {}
local BaNeMenuMainFrame_mt = Class(BaNeMenuMainFrame, TabbedMenuFrameElement)
BaNeMenuMainFrame.CONTROLS = {
	TABLE_HEADER_BOX = "tableHeaderBox",
	MAIN_BOX = "mainBox",
	FIELD_LIST_SLIDER = "fieldListSlider",
	FIELD_TABLE = "leasedFieldsTable"
}
BaNeMenuMainFrame.SCROLL_DELAY = FocusManager.DELAY_TIME
BaNeMenuMainFrame.MAX_NUM_FIELDS = GS_IS_MOBILE_VERSION and 6 or 15

function BaNeMenuMainFrame.new()
	local self = TabbedMenuFrameElement.new(nil, BaNeMenuMainFrame_mt)
	self.l10n = g_i18n
	self.general = {}
	self:registerControls(BaNeMenuMainFrame.CONTROLS)
	self.fields = {}
	self.fieldList = {}
	self.maxDisplayFields = 0
	self.dataBindings = {}
	self.needTableInit = true
	self.hasCustomMenuButtons = true
	return self
end

function BaNeMenuMainFrame:InitSettings(general,fields)
	self.general = general
	self.fields = fields
end

function BaNeMenuMainFrame:delete()
	BaNeMenuMainFrame:superClass().delete(self)
end

local function alwaysOverride()
	return true
end

function BaNeMenuMainFrame:initialize(l10n)
	self.l10n = l10n
--	for _, tableHeader in pairs(self.tableHeaderBox.elements) do
--		tableHeader.focusChangeOverride = self:makeTableHeaderFocusOverrideFunction(tableHeader)
--	end
	

	self.cancelButton = {
		profile = "buttonCancel",
		inputAction = InputAction.MENU_EXTRA_2,
		text = self.l10n:getText("uiBaNe_button_cancelLease"),
		callback = function ()
			self:onButtonCancelLease()
		end
	}
end

function BaNeMenuMainFrame:onGuiSetupFinished()
	BaNeMenuMainFrame:superClass().onGuiSetupFinished(self)
end

function BaNeMenuMainFrame:onFrameOpen()
	BaNeMenuMainFrame:superClass().onFrameOpen(self)

	if self.needTableInit then
		self.leasedFieldsTable:initialize()
		self.leasedFieldsTable:setProfileOverrideFilterFunction(alwaysOverride)
		self.maxDisplayFields = self.leasedFieldsTable.maxNumItems
		
		self.needTableInit = false
	end
	self.tableHeaderBox:invalidateLayout()
	
	self:updateFields()
	self:setSoundSuppressed(true)
	
	if GS_IS_MOBILE_VERSION then
		FocusManager:setFocus(self.leasedFieldsTable)
	else
		FocusManager:setFocus(self.tableHeaderBox)
	end
	
	self:setSoundSuppressed(false)
	self:updateMenuButtons()
end

function BaNeMenuMainFrame:onFrameClose()
	BaNeMenuMainFrame:superClass().onFrameClose(self)
	
	self.fieldList = {}
end

function BaNeMenuMainFrame:updateLeasedLands()
	if self:getIsVisible() then
		if GS_IS_MOBILE_VERSION then
			self:setNumberOfPages(math.ceil(#self.fieldList / BaNeMenuMainFrame.MAX_NUM_FIELDS))
		end
		self.leasedFieldsTable:clearData()
		for id, field in ipairs(self.fieldList) do
			local dataRow = self:buildDataRow(id,field)
			self.leasedFieldsTable:addRow(dataRow)
			
		end
		self.leasedFieldsTable:updateView(false)
	end
end

function BaNeMenuMainFrame:updateVerticalSlider()
	if self.fieldListSlider ~= nil then
		local maxVerticalSliderValue = math.max(1, #self.fieldList - self.maxDisplayFields)

		self.fieldListSlider:setMinValue(1)
		self.fieldListSlider:setMaxValue(maxVerticalSliderValue)

		local numVisibleItems = math.min(#self.fieldList, self.maxDisplayFields)

		self.fieldListSlider:setSliderSize(numVisibleItems, #self.fieldList)
	end
end

function BaNeMenuMainFrame:updateFields()
	self.fieldList = {}
	if g_currentMission.player ~= nil and g_BaNe.settings.fields.leasing ~= nil then
		for _, field in pairs(g_BaNe.settings.fields.leasing) do
			local isLeased = field.isLeased == true				
			if isLeased then
				table.insert(self.fieldList, field)
			end
		end
	end

	self:updateLeasedLands()
	self:updateVerticalSlider()
end

function BaNeMenuMainFrame:getMainElementSize()
	return self.mainBox.size
end

function BaNeMenuMainFrame:getMainElementPosition()
	return self.mainBox.absPosition
end

function BaNeMenuMainFrame:makeTableHeaderFocusOverrideFunction(headerElement)
	return function (target, direction)
		local doOverride = false
		local newTarget = nil

		if direction == FocusManager.TOP then
			doOverride = true
			newTarget = headerElement

			if self.fieldListSlider ~= nil then
				self.fieldListSlider:onScrollDown()
			end
		elseif direction == FocusManager.BOTTOM then
			doOverride = true
			newTarget = headerElement

			if self.fieldListSlider ~= nil then
				self.fieldListSlider:onScrollUp()
			end
		end

		return doOverride, newTarget
	end
end



BaNeMenuMainFrame.DATA_BINDING = {
	FIELD_ID = "leasedFieldID",
	SIZE = "fieldSize",
	LEASE_PRICE = "leasePrice",
	PAY_PERIODS = "payPeriods",
	END_DATE = "endDate",
	CANCEL = "leaseCancel",
}

function BaNeMenuMainFrame:onDataBindFieldID(element)
	self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.FIELD_ID] = element.name
end

function BaNeMenuMainFrame:onDataBindSize(element)
	self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.SIZE] = element.name
end

function BaNeMenuMainFrame:onDataBindLeasePrice(element)
	self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.LEASE_PRICE] = element.name
end

function BaNeMenuMainFrame:onDataBindPayPeriods(element)
	self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.PAY_PERIODS] = element.name
end

function BaNeMenuMainFrame:onDataBindEndDate(element)
	self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.END_DATE] = element.name
end

function BaNeMenuMainFrame:onDataBindLeaseCancel(element)
	self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.CANCEL] = element.name
end

function BaNeMenuMainFrame:setNameData(dataCell, field)
		dataCell.text = "Feld #"..field.fieldID
		local x, _, z = g_currentMission.player:getPositionData()
		local currentFarmland = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
		if currentFarmland == field.farmlandID then
			dataCell.overrideProfileName = "uiBaNeMenuFieldsRowFieldsCellActive"
		else
			dataCell.overrideProfileName = "uiBaNeMenuFieldsRowFieldsCell"
		end
		dataCell.value = field.fieldID
end

function BaNeMenuMainFrame:getActiveProfile(profile, field)
	local x, _, z = g_currentMission.player:getPositionData()
	local currentFarmland = g_farmlandManager:getFarmlandIdAtWorldPosition(x, z)
	local isActive = currentFarmland == field.farmlandID

	if isActive then
		if profile == BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL then
			return BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_ACTIVE_NEUTRAL
		else
			return BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_ACTIVE_NEGATIVE
		end
	end

	return profile
end

function BaNeMenuMainFrame:setSizeData(dataCell, field)
	local profile = BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL
	local sizeText = string.format("%.2f %s",math.round(field.fieldArea,0.01),"ha")

	dataCell.value = field.fieldArea
	dataCell.text = sizeText
	dataCell.overrideProfileName = self:getActiveProfile(profile, field)
end

function BaNeMenuMainFrame:setLeasePriceData(dataCell, field)
	local profile = BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL
	local priceText = g_i18n:formatMoney(field.pricePerYear, 0, true, true)

	dataCell.value = field.pricePerYear
	dataCell.text = priceText
	dataCell.overrideProfileName = self:getActiveProfile(profile, field)
end

function BaNeMenuMainFrame:setPayPeriodsData(dataCell, field)
	local profile = BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL
	local payPeriods = field.payPeriods
	local payText = "uiBaNe_payMonthly"
	if payPeriods == 1 then
		payText = "uiBaNe_payMonthly"
	elseif payPeriods == 3 then
		payText = "uiBaNe_payQuarterly"
	elseif payPeriods == 6 then
		payText = "uiBaNe_payBiannual"
	elseif payPeriods == 12 then
		payText = "uiBaNe_payAnnual"
	end

	dataCell.value = payPeriods
	dataCell.text = g_i18n:getText(payText)
	dataCell.overrideProfileName = self:getActiveProfile(profile, field)
end

function BaNeMenuMainFrame:setEndDateData(dataCell, field)
	local profile = BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL
	local year,period,day,dayInPeriod = g_BaNe:convertDateString(field.endDate)
	local dateText = string.format("%s %d %s %s %d",self.l10n:getText("uiBaNe_leaseYear"),year,self.l10n:formatPeriod(period, true),self.l10n:getText("uiBaNe_leaseDay"),dayInPeriod)

	dataCell.value = day
	dataCell.text = dateText
	dataCell.overrideProfileName = self:getActiveProfile(profile, field)
end

function BaNeMenuMainFrame:setCancelData(dataCell, field)
	local profile = BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEUTRAL
	local translate = nil
	local boolVal = nil
	if field.canCancel then
		translate = "uiBaNe_cancelLeaseAllowed"
		boolVal = "0"
	else
		translate = "uiBaNe_cancelLeaseDenied"
		boolVal = "1"
	end
	local cancelText = self.l10n:getText(translate)
	if not field.canCancel then
			profile = BaNeMenuMainFrame.PROFILE.ATTRIBUTE_CELL_NEGATIVE
	end

	dataCell.value = tonumber(boolVal)
	dataCell.text = cancelText
	dataCell.overrideProfileName = self:getActiveProfile(profile, field)
end

function BaNeMenuMainFrame:buildDataRow(id,field)
	local dataRow = TableElement.DataRow.new(id, self.dataBindings)
	local fieldCell = dataRow.columnCells[self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.FIELD_ID]]
	local sizeCell = dataRow.columnCells[self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.SIZE]]
	local priceCell = dataRow.columnCells[self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.LEASE_PRICE]]
	local periodCell = dataRow.columnCells[self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.PAY_PERIODS]]
	local endCell = dataRow.columnCells[self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.END_DATE]]
	local cancelCell = dataRow.columnCells[self.dataBindings[BaNeMenuMainFrame.DATA_BINDING.CANCEL]]

	self:setNameData(fieldCell, field)
	self:setSizeData(sizeCell, field)
	self:setLeasePriceData(priceCell, field)
	self:setPayPeriodsData(periodCell, field)
	self:setEndDateData(endCell, field)
	self:setCancelData(cancelCell, field)

	return dataRow
end

function BaNeMenuMainFrame.sortAttributes(sortCell1, sortCell2)
	return sortCell1.value - sortCell2.value
end

function BaNeMenuMainFrame:onClickFieldHeader(element)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self.leasedFieldsTable:setCustomSortFunction(BaNeMenuMainFrame.sortAttributes, true)
	self.leasedFieldsTable:onClickHeader(element)
	self.leasedFieldsTable:updateView(true)
	FocusManager:setFocus(self.tableHeaderBox)
end

function BaNeMenuMainFrame:onClickAttributeHeader(element)
	self:playSample(GuiSoundPlayer.SOUND_SAMPLES.CLICK)
	self.leasedFieldsTable:setCustomSortFunction(BaNeMenuMainFrame.sortAttributes, true)
	self.leasedFieldsTable:onClickHeader(element)
	self.leasedFieldsTable:updateView(true)
	FocusManager:setFocus(self.tableHeaderBox)
end

function BaNeMenuMainFrame:onPageChanged(page, fromPage)
	BaNeMenuMainFrame:superClass().onPageChanged(self, page, fromPage)

	local firstIndex = (page - 1) * BaNeMenuMainFrame.MAX_NUM_FIELDS + 1

	self.BaNeMenuMainFrame:scrollTo(firstIndex)
end

function BaNeMenuMainFrame:onButtonCancelLease()
	local fieldIndex = self.fieldList[self.leasedFieldsTable.selectedIndex]

	if fieldIndex ~= nil then
		print ("ooo need to do stuff here to 'sell' and to delete index:"..tostring(fieldIndex).." ooo")
	end
end

function BaNeMenuMainFrame:onSelectionChanged()	
	if self.leasedFieldsTable ~= nil then
		self.leasedFieldsTable:updateRowSelection()
		self:updateMenuButtons()
	end
end

function BaNeMenuMainFrame:onFieldSellEvent()
	self:updateFields()
end

function BaNeMenuMainFrame:onFieldBuyEvent()
	self:updateFields()
end


function BaNeMenuMainFrame:updateMenuButtons()
	
	self.menuButtonInfo = {
		{
			inputAction = InputAction.MENU_BACK
		}
	}
	if self.leasedFieldsTable.selectedId ~= nil and self.fieldList ~= nil then
		local selectedField = self.fieldList[self.leasedFieldsTable.selectedId]
		if selectedField ~= nil then		
			if #self.fieldList > 0 and selectedField.canCancel then
				table.insert(self.menuButtonInfo, self.cancelButton)
			end
		end
	end

	self:setMenuButtonInfoDirty()
end

BaNeMenuMainFrame.PROFILE = {
	ATTRIBUTE_CELL_NEUTRAL = "uiBaNeMenuFieldsRowAttributeCell",
	ATTRIBUTE_CELL_ACTIVE_NEUTRAL = "uiBaNeMenuFieldsRowAttributeCellActive",
	ATTRIBUTE_CELL_ACTIVE_NEGATIVE = "uiBaNeMenuFieldsRowAttributeCellActiveNegative",
	ATTRIBUTE_CELL_NEGATIVE = "uiBaNeMenuFieldsRowAttributeCellNegative"
}
