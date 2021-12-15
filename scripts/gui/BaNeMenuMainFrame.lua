-- Business administration & national economy (for FS22)
-- main frame file: BaNeMenuMainFrame.lua
-- v1.0.0b
--
-- @author [kwa:m]
-- @date 15.12.2021
--
-- Copyright (c) [kwa:m]
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
	VERSION = "version",
	CHANGELOG = "changelog"
}

function BaNeMenuMainFrame.new()
	local self = TabbedMenuFrameElement.new(nil, BaNeMenuMainFrame_mt)
	self.l10n = g_i18n
	self.general = {}
	self:registerControls(BaNeMenuMainFrame.CONTROLS)

	self.isColorBlindMode = false
	self.scrollInputDelay = 0
	self.scrollInputDelayDir = 0
	self.version = BaNe.version
	--self.changelog = BaNe.changelog

	return self
end

function BaNeMenuMainFrame:InitSettings(general)
	self.general = general
end

function BaNeMenuMainFrame:delete()
	BaNeMenuMainFrame:superClass().delete(self)
end

function BaNeMenuMainFrame:initialize(l10n)
	self.l10n = l10n
end

function BaNeMenuMainFrame:onGuiSetupFinished()
	BaNeMenuMainFrame:superClass().onGuiSetupFinished(self)
	--self.changelog:setDataSource(self)
end

function BaNeMenuMainFrame:onFrameOpen()
	BaNeMenuMainFrame:superClass().onFrameOpen(self)

	self.isColorBlindMode = g_gameSettings:getValue(GameSettings.SETTING.USE_COLORBLIND_MODE) or false

end

function BaNeMenuMainFrame:onFrameClose()

	BaNeMenuMainFrame:superClass().onFrameClose(self)
end


function BaNeMenuMainFrame:setColorBlindMode(isActive)
	if self.isColorBlindMode ~= isActive then
		self.isColorBlindMode = isActive

		--self:rebuildTable()

	end
end

function BaNeMenuMainFrame:inputEvent(action, value, eventUsed)
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
