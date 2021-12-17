-- Business administration & national economy (for FS22)
-- helper frame file: BaNeMenuHelperFrame.lua
-- v1.0.1b
--
-- @author [kwa:m]
-- @date 16.12.2021
--
-- Copyright (c) [kwa:m]
-- v1.0.1b - added jobType branch in helper factors
-- v1.0.0b - finished helper settings w/ working GUI (able to present as SP beta version)
-- v0.6.0a - added customizable nighttime/overtime factors
-- v0.5.0a - done GUI general layout, changed initialization process
-- v0.1.0a - added first iteration of GUI
-- v0.0.5a - added version in XML to overwrite values if changed defaults (TODO: GUI with possibility to warn that changes happened)
-- v0.0.3a - working alpha release with fixed values and manual xml editing for savegame
-- v0.0.1a - initial alpha release for internal testing (021221)


BaNeMenuHelperFrame = {}
local BaNeMenuHelperFrame_mt = Class(BaNeMenuHelperFrame, TabbedMenuFrameElement)
BaNeMenuHelperFrame.CONTROLS = {
	"uiBaNe_helperSettingsContainer",
	"boxlayout",
	"checkHelperAbsolute",
	"textWageAbsolute",
	"checkHelperPercentile",
	"textWagePercentile",
	"textConveyorPercentile",
	"textFieldWorkPercentile",
	"checkHelperFactA",
	"textFactAval",
	"textFactAfrom",
	"textFactAto",
	"checkHelperFactB",
	"textFactBval",
	"textFactBfrom",
	"textFactBto"
}

function BaNeMenuHelperFrame.new()
	local self = TabbedMenuFrameElement.new(nil, BaNeMenuHelperFrame_mt)
	self.l10n = g_i18n

	self:registerControls(BaNeMenuHelperFrame.CONTROLS)
	self.helper = {}
	self.isColorBlindMode = false
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0
	self.version = g_BaNe.version
	--self.changelog = BaNe.changelog

	return self
end

function BaNeMenuHelperFrame:InitSettings(helper)
	if helper ~= nil then
		self.helper = helper
		local tWA = string.format("%.1f",self.helper.wageAbsolute)
		local tWP = self:factorizePercent(self.helper.wagePercentile,1)
		self.textWageAbsolute:setText(tWA)
		self.textWagePercentile:setText(tWP)
		if self.helper.wageType == 1 then
			self.checkHelperAbsolute:setIsChecked(true)
			self.checkHelperPercentile:setIsChecked(false)
			self.textWageAbsolute:setDisabled(false)
			self.textWagePercentile:setDisabled(true)
		elseif self.helper.wageType == 2 then
			self.checkHelperAbsolute:setIsChecked(false)
			self.checkHelperPercentile:setIsChecked(true)
			self.textWageAbsolute:setDisabled(true)
			self.textWagePercentile:setDisabled(false)
		end
		local tCP, tFWP = self:factorizePercent(self.helper.conveyorPercent,1),self:factorizePercent(self.helper.fieldworkPercent,1)
		self.textConveyorPercentile:setText(tCP)
		self.textFieldWorkPercentile:setText(tFWP)		
		self.checkHelperFactA:setIsChecked(self.helper.factorA["enable"])
		self.textFactAval:setText(string.format("%.1f",self.helper.factorA["factor"]))		
		self.textFactAfrom:setText(string.format("%02d:%02d",self.helper.factorA["from_hours"],self.helper.factorA["from_minutes"]))
		self.textFactAto:setText(string.format("%02d:%02d",self.helper.factorA["to_hours"],self.helper.factorA["to_minutes"]))
		self.checkHelperFactB:setIsChecked(self.helper.factorB["enable"])
		self.textFactBval:setText(string.format("%.1f",self.helper.factorB["factor"]))
		self.textFactBfrom:setText(string.format("%02d:%02d",self.helper.factorB["from_hours"],self.helper.factorB["from_minutes"]))
		self.textFactBto:setText(string.format("%02d:%02d",self.helper.factorB["to_hours"],self.helper.factorB["to_minutes"]))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:InitSettings() called! ooo")
		end
	else
		print("ooo BaNeMenuHelperFrame:InitSettings: helper is nil! ooo")
	end
end

function BaNeMenuHelperFrame:factorizePercent(value, dir)
	local vstring = nil
	local ret = nil
	if dir == 0 and value ~= nil then
		local vstring = string.match(tostring(value),"(%d+)")
		if tonumber(vstring) ~= nil then
			vstring = tonumber(vstring) / 100
			ret = math.round(tonumber(vstring),0.01)
			return ret
		else
			return nil
		end
	elseif dir == 1 and value ~= nil then
		if tonumber(value) ~= nil then
			ret = tostring((value*100).."%")
			return ret
		else
			return nil
		end
	else
		return nil
	end
end

function BaNeMenuHelperFrame:convertTimeString(tstr)
	local ttime = {}
	local thr, tmin = nil, nil
	if tstr ~= nil and type(tstr) == "string" then
		if tstr:len() <= 5 and tstr:len() >= 4 then
			ttime = tstr:split(":")
			thr = ttime[1]
			tmin = ttime[2]
			if thr ~= nil and tmin ~= nil and tonumber(thr) >= 0 and tonumber(thr) <= 23 and tonumber(tmin) >= 0 and tonumber(tmin) <= 59 then
				if g_BaNe.debug then
					print ("ooo BaNeMenuHelperFrame:convertTimeString:"..tstr.." converted to "..thr.." - "..tmin.." ooo")
				end
				return thr, tmin				
			else
				if g_BaNe.debug then
					print ("ooo BaNeMenuHelperFrame:convertTimeString:"..tstr.." not resolved correctly:"..tostring(thr).." - "..tostring(min).." ooo")
				end
				return nil
			end
		else
			if g_BaNe.debug then
				print ("ooo BaNeMenuHelperFrame:convertTimeString:"..tstr.." is too short:"..tstr:len())
			end
			return nil
		end
	else
		if g_BaNe.debug then
			print ("ooo BaNeMenuHelperFrame:convertTimeString:"..tstr.." is nil or no string ooo")
		end
		return nil
	end
end

function BaNeMenuHelperFrame:delete()
	BaNeMenuHelperFrame:superClass().delete(self)
end

function BaNeMenuHelperFrame:initialize(l10n)
	self.l10n = l10n
end

function BaNeMenuHelperFrame:onGuiSetupFinished()
	BaNeMenuHelperFrame:superClass().onGuiSetupFinished(self)
	--self.changelog:setDataSource(self)
end

function BaNeMenuHelperFrame:onFrameOpen()
	BaNeMenuHelperFrame:superClass().onFrameOpen(self)

	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false
	self:InitSettings(g_BaNe.settings.helper)

end

function BaNeMenuHelperFrame:onFrameClose()

	BaNeMenuHelperFrame:superClass().onFrameClose(self)
end


function BaNeMenuHelperFrame:setColorBlindMode(isActive)
	if self.isColorBlindMode ~= isActive then
		self.isColorBlindMode = isActive

		--self:rebuildTable()

	end
end

function BaNeMenuHelperFrame:inputEvent(action, value, eventUsed)
	local pressedUp = action == InputAction.MENU_AXIS_UP_DOWN and g_analogStickVTolerance < value
	local pressedDown = action == InputAction.MENU_AXIS_UP_DOWN and value < -g_analogStickVTolerance

	if pressedUp or pressedDown then
		local dir = pressedUp and -1 or 1

		if dir ~= self.scrollInputDelayDir or g_time - self.scrollInputDelay > 250 then
			self.scrollInputDelayDir = dir
			self.scrollInputDelay = g_time

			--self.changelogSlider:setValue(self.changelogSlider:getValue() + dir)
		end
	end

	return true
end

function BaNeMenuHelperFrame:onClickHelperAbsolute(state)
	if state == 2 then
		self.helper.wageType = 1
		self.checkHelperPercentile:setIsChecked(false)
		self.textWageAbsolute:setDisabled(false)
		self.textWagePercentile:setDisabled(true)
	elseif state == 1 then
		self.helper.wageType = 2
		self.checkHelperPercentile:setIsChecked(true)
		self.textWageAbsolute:setDisabled(true)
		self.textWagePercentile:setDisabled(false)
	end
end

function BaNeMenuHelperFrame:onClickHelperPercentile(state)
	if state == 2 then
		self.helper.wageType = 2
		self.checkHelperAbsolute:setIsChecked(false)
		self.textWageAbsolute:setDisabled(true)
		self.textWagePercentile:setDisabled(false)
	elseif state == 1 then
		self.helper.wageType = 1
		self.checkHelperAbsolute:setIsChecked(true)
		self.textWageAbsolute:setDisabled(false)
		self.textWagePercentile:setDisabled(true)
	end
end

function BaNeMenuHelperFrame:onEnterPressedWageValueAbs()
	local newWage = self.textWageAbsolute.text
	if newWage ~= self.helper.wageAbsolute and tonumber(newWage) ~= nil then
			newWage = math.round(tonumber(newWage),0.1)
			self.helper.wageAbsolute = newWage
			self.textWageAbsolute:setText(string.format("%.1f",self.helper.wageAbsolute))
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedWageValueAbs, new value ="..tostring(self.helper.wageAbsolute).." ooo")
			end
	else
		self.textWageAbsolute:setText(string.format("%.1f",self.helper.wageAbsolute))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedWageValueAbs, old wage value ="..tostring(self.helper.wageAbsolute).." vs new wage ="..tostring(newWage).." ooo")
		end
	end
end

function BaNeMenuHelperFrame:onEnterPressedWageValuePer()
	local factor = self:factorizePercent(self.textWagePercentile.text,0)
	local valid = validateString(factor,"%d+%%")
	if valid then
		factor = factor:gsub("%%","")
	end
	if tonumber(factor) ~= self.helper.wagePercentile and tonumber(factor) ~= nil then
		factor = math.round(tonumber(factor),0.01)
		self.helper.wagePercentile = factor
		self.textWagePercentile:setText(self:factorizePercent(self.helper.wagePercentile,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedWageValuePer, new wage value ="..tostring(self.helper.wagePercentile).." ooo")
		end
	else
		self.textWagePercentile:setText(self:factorizePercent(self.helper.wagePercentile,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedWageValuePer, old factor value ="..tostring(self.helper.wagePercentile).." vs new factor ="..tostring(factor).." ooo")
		end
	end
end

function BaNeMenuHelperFrame:onEnterPressedConveyorValuePer()
	local factor = self:factorizePercent(self.textConveyorPercentile.text,0)
	local valid = validateString(factor,"%d+%%")
	if valid then
		factor = factor:gsub("%%","")
	end
	if tonumber(factor) ~= self.helper.conveyorPercent and tonumber(factor) ~= nil then
		factor = math.round(tonumber(factor),0.01)
		self.helper.conveyorPercent = factor
		self.textConveyorPercentile:setText(self:factorizePercent(self.helper.conveyorPercent,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedConveyorValuePer, new wage value ="..tostring(self.helper.conveyorPercent).." ooo")
		end
	else
		self.textConveyorPercentile:setText(self:factorizePercent(self.helper.conveyorPercent,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedConveyorValuePer, old factor value ="..tostring(self.helper.conveyorPercent).." vs new factor ="..tostring(factor).." ooo")
		end
	end
end

function BaNeMenuHelperFrame:onEnterPressedFieldWorkValuePer()
	local factor = self:factorizePercent(self.textFieldWorkPercentile.text,0)
	local valid = validateString(factor,"%d+%%")
	if valid then
		factor = factor:gsub("%%","")
	end
	if tonumber(factor) ~= self.helper.fieldworkPercent and tonumber(factor) ~= nil then
		factor = math.round(tonumber(factor),0.01)
		self.helper.fieldworkPercent = factor
		self.textFieldWorkPercentile:setText(self:factorizePercent(self.helper.fieldworkPercent,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFieldWorkValuePer, new wage value ="..tostring(self.helper.fieldworkPercent).." ooo")
		end
	else
		self.textFieldWorkPercentile:setText(self:factorizePercent(self.helper.fieldworkPercent,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFieldWorkValuePer, old factor value ="..tostring(self.helper.fieldworkPercent).." vs new factor ="..tostring(factor).." ooo")
		end
	end
end

function BaNeMenuHelperFrame:onClickHelperFactA(state)
	self.helper.factorA["enable"] = self.checkHelperFactA:getIsChecked()
	if g_BaNe.debug then
		print("ooo BaNeMenuHelperFrame:onClickHelperFactA, self.helper.factorA[\"enable\"] ="..tostring(self.helper.factorA["enable"]).." ooo")
	end
end

function BaNeMenuHelperFrame:onEnterPressedFactAValue()
	local newVal = self.textFactAval.text
	if newVal ~= self.helper.factorA["factor"] and tonumber(newVal) ~= nil then
			newVal = math.round(tonumber(newVal),0.01)
			self.helper.factorA["factor"] = newVal
			self.textFactAval:setText(string.format("%.1f",self.helper.factorA["factor"]))
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedFactAValue, new factor value ="..tostring(self.helper.factorA["factor"]).." ooo")
			end
	else
		self.textFactAval:setText(string.format("%.1f",self.helper.factorA["factor"]))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFactAValue, old factor value ="..tostring(self.helper.factorA["factor"]).." vs new wage ="..tostring(newVal).." ooo")
		end
	end
end

function BaNeMenuHelperFrame:onEnterPressedFactATimeFrom()
	local valid = false
	local timestr = tostring(self.textFactAfrom.text)
	valid = validateTimeString(timestr)
	if not valid then
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFactATimeFrom - found no valid time! ooo")
		end
		self.textFactAfrom:setText(string.format("%02d:%02d",self.helper.factorA["from_hours"],self.helper.factorA["from_minutes"]))
	elseif valid then
		local timesplit = string.split(timestr,":")
		local timehrs, timemin = tonumber(timesplit[1]), tonumber(timesplit[2])
		if timehrs ~= nil and timemin ~= nil then
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedFactATimeFrom - found time: "..timehrs..":"..timemin.." ooo")
			end
			self.helper.factorA["from_hours"] = timehrs
			self.helper.factorA["from_minutes"] = timemin
			self.textFactAfrom:setText(string.format("%02d:%02d",self.helper.factorA["from_hours"],self.helper.factorA["from_minutes"]))
		end
	end	
end

function BaNeMenuHelperFrame:onEnterPressedFactATimeTo()
	local valid = false
	local timestr = tostring(self.textFactAto.text)
	valid = validateTimeString(timestr)
	if not valid then
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFactATimeTo - found no valid time! ooo")
		end
		self.textFactAto:setText(string.format("%02d:%02d",self.helper.factorA["to_hours"],self.helper.factorA["to_minutes"]))
	elseif valid then
		local timesplit = string.split(timestr,":")
		local timehrs, timemin = tonumber(timesplit[1]), tonumber(timesplit[2])
		if timehrs ~= nil and timemin ~= nil then
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedFactATimeTo - found time: "..timehrs..":"..timemin.." ooo")
			end
			self.helper.factorA["to_hours"] = timehrs
			self.helper.factorA["to_minutes"] = timemin
			self.textFactAto:setText(string.format("%02d:%02d",self.helper.factorA["to_hours"],self.helper.factorA["to_minutes"]))
		end
	end	
end

function BaNeMenuHelperFrame:onClickHelperFactB(state)
	self.helper.factorB["enable"] = self.checkHelperFactB:getIsChecked()
	if g_BaNe.debug then
		print("ooo BaNeMenuHelperFrame:onClickHelperFactB, self.helper.factorB[\"enable\"] ="..tostring(self.helper.factorB["enable"]).." ooo")
	end
end

function BaNeMenuHelperFrame:onEnterPressedFactBValue()
	local newVal = self.textFactBval.text
	if newVal ~= self.helper.factorB["factor"] and tonumber(newVal) ~= nil then
			newVal = math.round(tonumber(newVal),0.01)
			self.helper.factorB["factor"] = newVal
			self.textFactBval:setText(string.format("%.1f",self.helper.factorB["factor"]))
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedFactBValue, new factor value ="..tostring(self.helper.factorB["factor"]).." ooo")
			end
	else
		self.textFactBval:setText(string.format("%.1f",self.helper.factorB["factor"]))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFactBValue, old factor value ="..tostring(self.helper.factorB["factor"]).." vs new wage ="..tostring(newVal).." ooo")
		end
	end
end

function BaNeMenuHelperFrame:onEnterPressedFactBTimeFrom()
	local valid = false
	local timestr = tostring(self.textFactBfrom.text)
	valid = validateTimeString(timestr)
	if not valid then
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFactBTimeFrom - found no valid time! ooo")
		end
		self.textFactBfrom:setText(string.format("%02d:%02d",self.helper.factorB["from_hours"],self.helper.factorB["from_minutes"]))
	elseif valid then
		local timesplit = string.split(timestr,":")
		local timehrs, timemin = tonumber(timesplit[1]), tonumber(timesplit[2])
		if timehrs ~= nil and timemin ~= nil then
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedFactBTimeFrom - found time: "..timehrs..":"..timemin.." ooo")
			end
			self.helper.factorB["from_hours"] = timehrs
			self.helper.factorB["from_minutes"] = timemin
			self.textFactBfrom:setText(string.format("%02d:%02d",self.helper.factorB["from_hours"],self.helper.factorB["from_minutes"]))
		end
	end	
end

function BaNeMenuHelperFrame:onEnterPressedFactBTimeTo()
	local valid = false
	local timestr = tostring(self.textFactBto.text)
	valid = validateTimeString(timestr)
	if not valid then
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedFactBTimeTo - found no valid time! ooo")
		end
		self.textFactBto:setText(string.format("%02d:%02d",self.helper.factorB["to_hours"],self.helper.factorB["to_minutes"]))
	elseif valid then
		local timesplit = string.split(timestr,":")
		local timehrs, timemin = tonumber(timesplit[1]), tonumber(timesplit[2])
		if timehrs ~= nil and timemin ~= nil then
			if g_BaNe.debug then
				print("ooo BaNeMenuHelperFrame:onEnterPressedFactBTimeTo - found time: "..timehrs..":"..timemin.." ooo")
			end
			self.helper.factorB["to_hours"] = timehrs
			self.helper.factorB["to_minutes"] = timemin
			self.textFactBto:setText(string.format("%02d:%02d",self.helper.factorB["to_hours"],self.helper.factorB["to_minutes"]))
		end
	end	
end