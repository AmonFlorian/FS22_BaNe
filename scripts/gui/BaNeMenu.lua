-- Business administration & national economy (for FS22)
-- settings menu file: BaNeMenu.lua
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

BaNeMenu = {}
local BaNeMenu_mt = Class(BaNeMenu, TabbedMenu)
BaNeMenu.CONTROLS = {
	"pageBaNeHelper",
	"pageBaNeFieldPrices",
	"pageBaNeShopPrices",
	"pageBaNeMain",
	"background"
}
BaNeMenu.L10N_SYMBOL = {
	BUTTON_BACK = "uiBaNe_backbutton",
	BUTTON_SAVE_SETTINGS = "uiBaNe_savebutton",
	BUTTON_CANCEL = "uiBaNe_cancelbutton"
}

function BaNeMenu.new(target, messageCenter, l10n, inputManager, savegameController, fruitTypeManager, fillTypeManager, isConsoleVersion)
	local self = BaNeMenu:superClass().new(target, BaNeMenu_mt, messageCenter, l10n, inputManager)

	self:registerControls(BaNeMenu.CONTROLS)

	self.performBackgroundBlur = true
	self.gameState = GameState.MENU_INGAME
	self.currentUserId = -1
	self.settings = {}
	self.activeDetailPage = nil
	self.paused = false
	self.client = nil
	self.server = nil
	self.isMasterUser = false
	self.isServer = false
	self.currentBalanceValue = 0
	self.timeSinceLastMoneyUpdate = 0
	self.defaultMenuButtonInfo = {}
	self.backButtonInfo = {}
	self.l10n = l10n
	self.continueEnabled = true
	self.isSaving = false

	return self
end

function BaNeMenu:InitSettings(settings)
	self.settings = settings
	self.pageBaNeMain:InitSettings(self.settings.general, self.settings.fields)
	self.pageBaNeHelper:InitSettings(self.settings.helper)
	self.pageBaNeFieldPrices:InitSettings(self.settings.fields)
	self.pageBaNeShopPrices:InitSettings(self.settings.shops)
end

function BaNeMenu:setupMenuPages()
	
	local orderedDefaultPages = {
		{
			self.pageBaNeMain,
			self:makeIsMainEnabledPredicate(),
			BaNeMenu.TAB_UV.MAIN
		},
		{
			self.pageBaNeHelper,
			self:makeIsHelperEnabledPredicate(),
			BaNeMenu.TAB_UV.HELPER
		},
		{
			self.pageBaNeFieldPrices,
			self:makeIsFieldPricesEnabledPredicate(),
			BaNeMenu.TAB_UV.FIELDPRICES
		},
		{
			self.pageBaNeShopPrices,
			self:makeIsShopPricesEnabledPredicate(),
			BaNeMenu.TAB_UV.SHOPPRICES
		}
	}

	for i, pageDef in ipairs(orderedDefaultPages) do
		local page, predicate, iconUVs = unpack(pageDef)

		if page ~= nil then
			
			page:initialize(self.l10n)
			self:registerPage(page, i, predicate)

			local normalizedUVs = GuiUtils.getUVs(iconUVs)

			self:addPageTab(page, g_iconsUIFilename, normalizedUVs)
		end
	end
end

function BaNeMenu:setupMenuButtonInfo()
	BaNeMenu:superClass().setupMenuButtonInfo(self)
	local onButtonBackFunction = self:makeSelfCallback(self.onButtonBack)
	local onButtonQuitFunction = self:makeSelfCallback(self.onButtonQuit)
	local onButtonSaveSettingsFunction = self:makeSelfCallback(self.onButtonSaveSettings)
	self.backButtonInfo = {
		inputAction = InputAction.MENU_BACK,
		text = self.l10n:getText(BaNeMenu.L10N_SYMBOL.BUTTON_BACK),
		callback = onButtonBackFunction
	}
	self.saveButtonInfo = {
		showWhenPaused = true,
		inputAction = InputAction.MENU_ACTIVATE,
		text = self.l10n:getText(BaNeMenu.L10N_SYMBOL.BUTTON_SAVE_SETTINGS),
		callback = onButtonSaveSettingsFunction
	}
--	self.quitButtonInfo = {
--		showWhenPaused = true,
--		inputAction = InputAction.MENU_CANCEL,
--		text = self.l10n:getText(BaNeMenu.L10N_SYMBOL.BUTTON_CANCEL),
--		callback = onButtonQuitFunction
--	}

	self.defaultMenuButtonInfo = {
		self.backButtonInfo,
		self.saveButtonInfo,
--		self.quitButtonInfo
	}

	self.defaultMenuButtonInfoByActions[InputAction.MENU_BACK] = self.defaultMenuButtonInfo[1]
	self.defaultMenuButtonInfoByActions[InputAction.MENU_ACTIVATE] = self.defaultMenuButtonInfo[2]
--	self.defaultMenuButtonInfoByActions[InputAction.MENU_CANCEL] = self.defaultMenuButtonInfo[3]
	self.defaultButtonActionCallbacks = {
		[InputAction.MENU_BACK] = onButtonBackFunction,
--		[InputAction.MENU_CANCEL] = onButtonQuitFunction,
		[InputAction.MENU_ACTIVATE] = onButtonSaveSettingsFunction
	}
end

function BaNeMenu:onGuiSetupFinished()
	BaNeMenu:superClass().onGuiSetupFinished(self)
	self:setupMenuPages()
	self:InitSettings(g_BaNe.settings)
end

function BaNeMenu:updateBackground()
	self.background:setVisible(self.currentPage.needsSolidBackground)
end

function BaNeMenu:setCurrentUserId(currentUserId)
	self.currentUserId = currentUserId
end

function BaNeMenu:exitMenu()
	if self.continueEnabled and not self.isSaving then
		BaNeMenu:superClass().exitMenu(self)
	end
end

function BaNeMenu:reset()
	BaNeMenu:superClass().reset(self)
	self.isMasterUser = false
	self.isServer = false

end

function BaNeMenu:onMenuOpened()
		self.messageCenter:publish(MessageType.GUI_INGAME_OPEN)
end

function BaNeMenu:onClose(element)

	BaNeMenu:superClass().onClose(self)

	self.mouseDown = false
	self.alreadyClosed = true

end

function BaNeMenu:onButtonSaveSettings()
	BaNe:saveSet(g_BaNe.settings)
	g_gui:showInfoDialog({
		visible = true,
		dialogType = DialogElement.TYPE_INFO,
		text = g_i18n:getText("uiBaNe_savedSettings"),
		isCloseAllowed = true
	})
	
end

--function BaNeMenu:onButtonQuit()
--	return true
--end

function BaNeMenu:onButtonBack()
	if self.currentPage == self.pageBaNeMain then
		if BaNe.debug then
			print("ooo BaNeMenu:onButtonBack() triggered for superClass ooo")
		end
		BaNeMenu:superClass().onButtonBack(self)
	else
		self:goToPage(self.pageBaNeMain)
	end
end

function BaNeMenu:setIsGamePaused(paused)
	self.paused = paused

	if self.currentPage ~= nil then
		self:updateButtonsPanel(self.currentPage)
	end
end

function BaNeMenu:update(dt)

	BaNeMenu:superClass().update(self, dt)

end

function BaNeMenu:updateButtonsPanel(page)
	local buttonsDisabled = false

	self.buttonsPanel:setVisible(not buttonsDisabled)
	self.buttonsPanel:setDisabled(buttonsDisabled)
	BaNeMenu:superClass().updateButtonsPanel(self, page)
end


function BaNeMenu:openHelperScreen()
	self:changeScreen(BaNeMenu)

	local pageHelperIndex = self.pagingElement:getPageMappingIndexByElement(self.pageBaNeHelper)

	self.pageSelector:setState(pageHelperIndex, true)
end

function BaNeMenu:openFieldPricesScreen()
	self:changeScreen(BaNeMenu)

	local pageFieldPricesIndex = self.pagingElement:getPageMappingIndexByElement(self.pageBaNeFieldPrices)

	self.pageSelector:setState(pageFieldPricesIndex, true)
end

function BaNeMenu:openShopPricesScreen()
	self:changeScreen(BaNeMenu)

	local pageShopPricesIndex = self.pagingElement:getPageMappingIndexByElement(self.pageBaNeShopPrices)

	self.pageSelector:setState(pageShopPricesIndex, true)
end

function BaNeMenu:getTabBarProfile()
	return BaNeMenu.PROFILES.TAB_BAR_LIGHT
end

function BaNeMenu:onClickMenu()
	self:exitMenu()

	return true
end

function BaNeMenu:onPageChange(pageIndex, pageMappingIndex, element, skipTabVisualUpdate)
	local prevPage = self.pagingElement:getPageElementByIndex(self.currentPageId)

	BaNeMenu:superClass().onPageChange(self, pageIndex, pageMappingIndex, element, skipTabVisualUpdate)

	local page = self.pagingElement:getPageElementByIndex(pageIndex)

	self.header:applyProfile(self:getTabBarProfile())
	self:updateBackground()
end

function BaNeMenu:getPageButtonInfo(page)
	local buttonInfo = BaNeMenu:superClass().getPageButtonInfo(self, page)

	return buttonInfo
end

function BaNeMenu:makeIsMainEnabledPredicate()
	return function ()
		return true
	end
end

function BaNeMenu:makeIsHelperEnabledPredicate()
	return function ()
		return true
	end
end

function BaNeMenu:makeIsFieldPricesEnabledPredicate()
	return function ()
		return true
	end
end

function BaNeMenu:makeIsShopPricesEnabledPredicate()
	return function ()
		return true
	end
end

BaNeMenu.TAB_UV = {
	MAIN = {
		0,
		0,
		65,
		65
	},
	HELPER = {
		910,
		65,
		65,
		65
	},
	FIELDPRICES = {
		195,
		0,
		65,
		65
	},
	SHOPPRICES = {
		325,
		0,
		65,
		65
	}
}

BaNeMenu.PROFILES = {
	TAB_BAR_DARK = "uiInGameMenuHeaderDark",
	TAB_BAR_LIGHT = "uiInGameMenuHeader"
}
