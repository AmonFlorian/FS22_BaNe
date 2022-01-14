-- Business administration & national economy (for FS22)
-- helper changes file: BaNe_fields.lua
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

function BaNe:inject_fields()
	g_currentMission.inGameMenu.pageMapOverview.onMenuExtra2 = function(self) g_BaNe:LeaseCallback(self.selectedFarmland, self.playerFarm:getBalance()) end
	local buttonLeaseFarmland = ButtonElement.new()
	buttonLeaseFarmland:copyAttributes(g_currentMission.inGameMenu.pageMapOverview.buttonBuyFarmland)
	--buttonLeaseFarmland.parent = g_currentMission.inGameMenu.pageMapOverview.buttonBuyFarmland.parent
	buttonLeaseFarmland.text = g_i18n:getText("uiBaNe_buttonLeaseFarmland")
	buttonLeaseFarmland.id = "buttonLeaseFarmland"
	buttonLeaseFarmland.onClickCallback = g_currentMission.inGameMenu.pageMapOverview.onMenuExtra2
	buttonLeaseFarmland.profile = "buttonBuyFarmland"
	buttonLeaseFarmland:setInputAction("MENU_EXTRA_2")
	buttonLeaseFarmland:loadInputGlyph(true)
	buttonLeaseFarmland:applyScreenAlignment()
	buttonLeaseFarmland:updateSize()
	g_currentMission.inGameMenu.pageMapOverview.buttonBuyFarmland.parent:addElement(buttonLeaseFarmland)
	g_currentMission.inGameMenu.pageMapOverview["buttonLeaseFarmland"] = g_currentMission.inGameMenu.pageMapOverview.buttonBuyFarmland.parent.elements[#g_currentMission.inGameMenu.pageMapOverview.buttonBuyFarmland.parent.elements]
	g_currentMission.inGameMenu.pageMapOverview.controlIDs["leaseText"] = true
	g_currentMission.inGameMenu.pageMapOverview.controlIDs["buttonLeaseFarmland"] = true
	local function bLFvisible(self,canBuy)
		self.buttonLeaseFarmland:setVisible(self.buttonBuyFarmland.visible)
		self.buttonLeaseFarmland:updateSize()
	end
	
	local function bLFregIn(self,...)
		self.inputManager:registerActionEvent(InputAction.MENU_EXTRA_2, self, self.onMenuExtra2, false, true, false, true)
	end
	g_currentMission.inGameMenu.pageMapOverview.showContextInput = Utils.appendedFunction(g_currentMission.inGameMenu.pageMapOverview.showContextInput, bLFvisible)
	g_currentMission.inGameMenu.pageMapOverview.registerInput = Utils.appendedFunction(g_currentMission.inGameMenu.pageMapOverview.registerInput, bLFregIn)

end

function BaNe:LeaseCallback(selectedFarmland, balance)
	if selectedFarmland ~= nil then
		local fieldInfo = g_fieldManager.farmlandIdFieldMapping[selectedFarmland.id]
		fieldInfo = fieldInfo[1]
		local price = g_farmlandManager:getPricePerHa() * fieldInfo.fieldArea * selectedFarmland.priceFactor
		local leaseOptions = {}
		local yearText = nil
		for i=1,20,1 do
			if i == 1 then
				yearText = g_i18n:getText("uiBaNe_leaseYear")
			else
				yearText = g_i18n:getText("uiBaNe_leaseYears")
			end
			table.insert(leaseOptions,tostring(i) .. " "..tostring(yearText))
		end
		local priceperyr = math.round(price * g_BaNe.settings.fields.leaseFactor,1)
		g_gui:showOptionDialog({
			title = g_i18n:getText("uiBaNe_leaseFarmland_title"),			
			text = string.format(g_i18n:getText("uiBaNe_textLeaseOption"),g_i18n:formatMoney(priceperyr, 0, true, true)),
			options = leaseOptions,
			callback = function(item) g_BaNe:optionDialogCallback(item, selectedFarmland, priceperyr, fieldInfo) end
		})
		
	else
		if g_BaNe.debug then
			print("ooo BaNe:LeaseCallback() has no field selected! ooo")
		end
	end
end

function BaNe:optionDialogCallback(selectedRuntime, selectedFarmland, pricePerYr, selectedField)
	if selectedRuntime ~= nil and selectedFarmland ~= nil and pricePerYr ~= nil and selectedField ~= nil then
		local payOptions = {}
		local yearPeriods = Environment.PERIODS_IN_YEAR
		local monthlyPrice = math.floor(pricePerYr / yearPeriods)
		local quarterlyPrice = math.floor(pricePerYr / 4)
		local biannualPrice = math.floor(pricePerYr / 2)
		local annualPrice = math.floor(pricePerYr)
		table.insert(payOptions,g_i18n:getText("uiBaNe_payMonthly").." ("..g_i18n:formatMoney(monthlyPrice, 0, true, true)..")")
		table.insert(payOptions,g_i18n:getText("uiBaNe_payQuarterly").." ("..g_i18n:formatMoney(quarterlyPrice, 0, true, true)..")")
		table.insert(payOptions,g_i18n:getText("uiBaNe_payBiannual").." ("..g_i18n:formatMoney(biannualPrice, 0, true, true)..")")
		table.insert(payOptions,g_i18n:getText("uiBaNe_payAnnual").." ("..g_i18n:formatMoney(annualPrice, 0, true, true)..")")
		
		g_gui:showOptionDialog({
			title = g_i18n:getText("uiBaNe_leaseFarmland_title"),			
			text = g_i18n:getText("uiBaNe_textLeaseOption2"),
			options = payOptions,
			callback = function(item) g_BaNe:optionDialogCallback2(item, selectedRuntime, selectedFarmland, pricePerYr, selectedField) end
		})
	else
		if g_BaNe.debug then
			print("ooo BaNe:optionDialogCallback has missing arguments! ooo")
		end
		return true
	end
end

function BaNe:optionDialogCallback2(item, selectedRuntime, selectedFarmland, pricePerYr, selectedField)
	if item > 0 then
		local yearPeriods = Environment.PERIODS_IN_YEAR
		local selectedPayPeriods = 12
		if item == 1 then
			selectedPayPeriods = 1
		elseif item == 2 then
			selectedPayPeriods = yearPeriods / 4
		elseif item == 3 then
			selectedPayPeriods = yearPeriods / 2
		elseif item == 4 then
			selectedPayPeriods = yearPeriods
		end
		
		if g_BaNe.debug then
			print("ooo BaNe:LeaseCallback2 adding lease for farmland with id '"..tostring(selectedFarmland.id).."' for €"..tostring(pricePerYr).." over "..tostring(selectedRuntime).." year(s) and fieldID '"..tostring(selectedField.fieldId).."' with payPeriods='"..tostring(selectedPayPeriods).."' ooo")
		end
		self:addFieldLeasing(selectedFarmland.id, true, selectedRuntime, selectedPayPeriods, selectedField.fieldId, pricePerYr, selectedField.fieldArea)
	end
end

function BaNe:convertDateString(str)
--[[	WINTER = 3,
		SUMMER = 1,
		SPRING = 0,
		AUTUMN = 2	]]---
	local SEASON_TRANSLATION = {
	["0"] = "uiBaNe_SPRING",
	["1"] = "uiBaNe_SUMMER",
	["2"] = "uiBaNe_AUTUMN",
	["3"] = "uiBaNe_WINTER"
	}
	local yr,period,day,dip,dpp,season = str:match("(%x%x)(%x)(%x%x%x%x)(%d%d)(%d%d)(%d)")  

	if tonumber(yr,16) ~= nil and tonumber(period,16) and tonumber(day,16) ~= nil and tonumber(dip) ~= nil and tonumber(dpp) ~= nil and SEASON_TRANSLATION[season] ~= nil then
		return tonumber(yr,16), tonumber(period,16), tonumber(day,16), tonumber(dip), tonumber(dpp), SEASON_TRANSLATION[season]
	end
	return nil
end

function BaNe:getBaNeDate(future, runTime, fromDay, runtimeInDays)
--[[	WINTER = 3,
		SUMMER = 1,
		SPRING = 0,
		AUTUMN = 2	]]---
		local env = g_currentMission.environment
		local retString = nil
	if future == nil then
		local currentYear = env.currentYear
		local currentDay = env.currentDay
		local currentDaysPerPeriod = env.daysPerPeriod
		local currentPeriod = math.ceil(((currentDay % - 1) % (currentDaysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / currentDaysPerPeriod)
		local currentSeason = math.fmod(math.floor((currentDay) / (currentDaysPerPeriod * 3)), Environment.SEASONS_IN_YEAR)
		local currentDayInPeriod = (currentDay - 1) % currentDaysPerPeriod + 1
		retString = string.format("%02x%x%04x%02d%02d%d",currentYear,currentPeriod,currentDay,currentDayInPeriod,currentDaysPerPeriod,currentSeason)
	elseif future then
		if fromDay == nil then
			fromDay = env.currentDay
		end
		if tonumber(runTime) == nil or tonumber(runTime) < 1 then
			runTime = 1
		end
		local futureDaysPerPeriod = env.daysPerPeriod
		local futureDay = nil
		if runtimeInDays == nil or runtimeInDays == "false" then			
			futureDay = fromDay + (futureDaysPerPeriod * 3 * Environment.SEASONS_IN_YEAR) * runTime
		elseif runtimeInDays then
			futureDay = fromDay + runTime
		end
		local futureDayInPeriod = (futureDay -1) % futureDaysPerPeriod + 1
		local futurePeriod = math.ceil(((futureDay - 1) % (futureDaysPerPeriod * Environment.PERIODS_IN_YEAR) + 1) / futureDaysPerPeriod)
		local futureYear = math.floor(futureDay / (futureDaysPerPeriod * Environment.PERIODS_IN_YEAR)) + 1
		local futureSeason = math.fmod(math.floor((futureDay) / (futureDaysPerPeriod * 3)), Environment.SEASONS_IN_YEAR)
		retString = string.format("%02x%x%04x%02d%02d%d",futureYear,futurePeriod,futureDay,futureDayInPeriod,futureDaysPerPeriod,futureSeason)		
	end
	
	return retString
end

function BaNe:daysToPayment(startDate, payPeriods)
	local env = g_currentMission.environment
	daysPerPeriod = env.daysPerPeriod
	currentDay = env.currentDay
	local factor = 1.0
	local _, _, startDay, _, _, _ = self:convertDateString(startDate)
	local daysSinceStart = currentDay - startDay
	local daysSinceLastPayment = (currentDay % (daysPerPeriod * payPeriods)) - 1
	--local daysToNextPayment = 
	if daysSinceStart < daysSinceLastPayment then
		factor = math.round(((daysPeriod * payPeriods)-((startDay % (daysPerPeriod * payPeriods)) - 1))/(daysPeriod * payPeriods),0.01)
	end
	return daysToNextPayment, factor
end

function BaNe:addFieldLeasing(farmlandID, isLeased, runTime, payPeriods, fieldID, pricePerYear, fieldArea, canCancel)
	local newField = nil
	if farmlandID ~= nil then
		newField = {}
		if fieldID == nil or pricePerYear == nil or fieldArea == nil or payPeriods == nil then
			local field = g_fieldManager.farmlandIdFieldMapping[farmlandID][1]
			if fieldID == nil then
				fieldID = field.fieldId
			end
			if fieldArea == nil then
				fieldArea = field.fieldArea
			end
			if pricePerYear == nil then
				pricePerYear = g_farmlandManager:getPricePerHa() * fieldArea * g_farmlandManager.farmlands[farmlandID]["priceFactor"]
				pricePerYear = math.round(pricePerYear * g_BaNe.settings.fields.leaseFactor,1)
			end
			if payPeriods == nil then
				payPeriods = 12
			end
		end
		if isLeased == nil then
			isLeased = false
		end
		newField["fieldID"] = tonumber(fieldID)
		newField["farmlandID"] = tonumber(farmlandID)
		newField["isLeased"] = isLeased
		newField["payPeriods"] = payPeriods
		newField["fieldArea"] = math.round(fieldArea,0.01)
		newField["pricePerYear"] = tonumber(pricePerYear)
		newField["startDate"] = self:getBaNeDate()
		newField["endDate"] = self:getBaNeDate(true, runTime)
		newField["canCancel"] = true
	end
	if newField ~= nil and table.length(newField) == 9 then
		if g_BaNe.settings.fields.leasing ~= nil and (g_BaNe.settings.fields.leasing[newField.farmlandID] == nil or g_BaNe.settings.fields.leasing[newField.farmlandID][isLeased]) then
			g_BaNe.settings.fields.leasing[newField.farmlandID] = newField
			if g_BaNe.debug then
				print("ooo BaNe:LeaseCallback added field to settings! ooo")
				DebugUtil.printTableRecursively(g_BaNe.settings.fields.leasing[newField.farmlandID],"_",0,1)
			end
		else	
			if g_BaNe.debug then
				print("ooo BaNe:LeaseCallback couldn't add field to settings! already exists! ooo")
			end
		end
	elseif (newField == nil or #newField ~= 8) and g_BaNe.debug then
		print("ooo BaNe:LeaseCallback couldn't add field to settings! #newField="..tostring(table.length(newField)).." with table: ooo")
		DebugUtil.printTableRecursively(newField,"_",0,1)
	end
end

function BaNe:removeFieldLeasing(fieldID)
	if fieldID ~= nil then
		g_BaNe.settings.fields.leasing[tostring(fieldID)] = nil
	end
end