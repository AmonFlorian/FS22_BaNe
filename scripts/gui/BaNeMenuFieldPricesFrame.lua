-- Business administration & national economy (for FS22)
-- field prices frame file: BaNeMenuFieldPricesFrame.lua
-- v0.1.0a
--
-- @author [kwa:m]
-- @date 05.12.2021
--
-- Copyright (c) [kwa:m]
-- v0.1.0a - added first iteration of GUI
-- v0.0.5a - added version in XML to overwrite values if changed defaults (TODO: GUI with possibility to warn that changes happened)
-- v0.0.3a - working alpha release with fixed values and manual xml editing for savegame
-- v0.0.1a - initial alpha release for internal testing (021221)

BaNeMenuFieldPricesFrame = {}
local BaNeMenuFieldPricesFrame_mt = Class(BaNeMenuFieldPricesFrame, TabbedMenuFrameElement)
BaNeMenuFieldPricesFrame.CONTROLS = {
	VERSION = "version",
	CHANGELOG = "changelog"
}

function BaNeMenuFieldPricesFrame.new()
	local self = TabbedMenuFrameElement.new(nil, BaNeMenuFieldPricesFrame_mt)
	self.l10n = g_i18n
	self.fields = {}
	self:registerControls(BaNeMenuFieldPricesFrame.CONTROLS)

	self.isColorBlindMode = false
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0
	self.version = BaNe.version
	--self.changelog = BaNe.changelog

	return self
end

function BaNeMenuFieldPricesFrame:InitSettings(fields)
	self.fields = {}
end

function BaNeMenuFieldPricesFrame:delete()
	BaNeMenuFieldPricesFrame:superClass().delete(self)
end

function BaNeMenuFieldPricesFrame:initialize(l10n)
	self.l10n = l10n
end

function BaNeMenuFieldPricesFrame:onGuiSetupFinished()
	BaNeMenuFieldPricesFrame:superClass().onGuiSetupFinished(self)
	--self.changelog:setDataSource(self)
end

function BaNeMenuFieldPricesFrame:onFrameOpen()
	BaNeMenuFieldPricesFrame:superClass().onFrameOpen(self)

	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false

end

function BaNeMenuFieldPricesFrame:onFrameClose()

	BaNeMenuFieldPricesFrame:superClass().onFrameClose(self)
end


function BaNeMenuFieldPricesFrame:setColorBlindMode(isActive)
	if self.isColorBlindMode ~= isActive then
		self.isColorBlindMode = isActive

		--self:rebuildTable()

	end
end

function BaNeMenuFieldPricesFrame:inputEvent(action, value, eventUsed)
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
