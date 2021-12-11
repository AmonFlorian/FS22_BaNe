-- Business administration & national economy (for FS22)
-- helper frame file: BaNeMenuHelperFrame.lua
-- v0.5.0a
--
-- @author [kwa:m]
-- @date 05.12.2021
--
-- Copyright (c) [kwa:m]
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
	"textWagePercentile"
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
			ret = math.round(tonumber(vstring),0.1)
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
	if tonumber(factor) ~= self.helper.wagePercentile and tonumber(factor) ~= nil then
		factor = math.round(tonumber(factor),0.1)
		self.helper.wagePercentile = factor
		self.textWagePercentile:setText(self:factorizePercent(self.helper.wagePercentile,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedWageValuePer, new value ="..tostring(self.helper.wagePercentile).." ooo")
		end
	else
		self.textWagePercentile:setText(self:factorizePercent(self.helper.wagePercentile,1))
		if g_BaNe.debug then
			print("ooo BaNeMenuHelperFrame:onEnterPressedWageValuePer, old factor value ="..tostring(self.helper.wagePercentile).." vs new factor ="..tostring(factor).." ooo")
		end
	end
end