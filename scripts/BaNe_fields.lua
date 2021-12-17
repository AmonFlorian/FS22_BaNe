-- Business administration & national economy (for FS22)
-- helper changes file: BaNe_fields.lua
-- v1.1.5b
--
-- @author [kwa:m]
-- @date 17.12.2021
--
-- Copyright (c) [kwa:m]
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
	--g_currentMission.inGameMenu.pageMapOverview["buttonLeaseFarmland"] = buttonLeaseFarmland
	--print(#g_currentMission.inGameMenu.pageMapOverview.buttonBuyFarmland)
	--print(#g_currentMission.inGameMenu.pageMapOverview.buttonLeaseFarmland)
	--DebugUtil.printTableRecursively(g_currentMission.inGameMenu.pageMapOverview ,"_",0,2)
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
			callback = function(item) g_BaNe:optionDialogCallback(item, selectedFarmland, priceperyr) end
		})
		
	else
		if g_BaNe.debug then
			print("ooo BaNe:LeaseCallback() has no field selected! ooo")
		end
	end
end

function BaNe:optionDialogCallback(selectedRuntime, selectedFarmland, priceperyr)
	if selectedRuntime > 0 then
		if g_BaNe.debug then
			print("ooo BaNe:LeaseCallback wants to lease farmland with id '"..tostring(selectedFarmland.id).."' for €"..tostring(priceperyr).." over "..tostring(selectedRuntime).." year(s) ooo")
		end
	end
end