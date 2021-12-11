-- Business administration & national economy (for FS22)
-- main faile: BaNe_main.lua
local version = "0.5.0a"
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


local modDir = g_currentModDirectory
local modName = g_currentModName

BaNe = {}
local BaNe_mt = Class(BaNe)

function BaNe.prerequisitesPresent(specializations)
    return true
end

function BaNe.new(i18n)
	self={}
	setmetatable(self, BaNe_mt)
	self.version = version
	self.debug = true
	self.mdir = modDir
	self.mname = modName
	-- Initialize standard values
	self.eventId = {}
	self.settings = {}
	self.settings["general"] = {}
	self.settings["helper"] = {}
	self.settings["fields"] = {}
	self.settings["shops"] = {}
	self.i18n = i18n
	
	return self
end

function BaNe:loadMap()
	source(Utils.getFilename("scripts/BaNe_luautils.lua", self.mdir))
	source(Utils.getFilename("scripts/BaNe_helper.lua", self.mdir))
	helper = g_BaNe.settings.helper
	print("ooo BaNe debugging is "..tostring(self.debug).." ooo")
	if self.debug then
		print("ooo BaNe Debug ... BaNe:loadMap ++ isClient="..tostring(g_currentMission:getIsClient()).." ,isServer="..tostring(g_currentMission:getIsServer()).." ,isMasterUser="..tostring(g_currentMission.isMasterUser).." ,isMultiplayer="..tostring(g_currentMission.missionDynamicInfo.isMultiplayer).." mname="..tostring(self.mname).." ooo")
	end
	
	-- Save current settings on gamesave
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, self.saveSettings)
	
	--load Savegame
	local sgIndex = g_currentMission.missionInfo.savegameIndex
	local sgFolderPath = g_currentMission.missionInfo.savegameDirectory
	if sgFolderPath == nil then
		sgFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), sgIndex)
	end
	if g_currentMission:getIsServer() then
		if fileExists(sgFolderPath .. '/careerSavegame.xml') then
			if fileExists(sgFolderPath .. '/BaNe.xml') then
				print("ooo loading BaNe v".. self.version .. " Copyright (c) [kwa:m] ooo loading savedata ooo")
				local key = "BaNe"
				local xmlFile = loadXMLFile("BaNe", sgFolderPath .. "/BaNe.xml", key)
				if xmlFile ~= nil then
					-- saveVersion					
					local sgXmlVersion = Utils.getNoNil(getXMLString(xmlFile, key.."#version"), "0.0.0")
					
					if tostring(sgXmlVersion) == tostring(self.version) then
						-- wagePerHour
						helper.wageType = Utils.getNoNil(getXMLInt(xmlFile, key.."#wageType"), 1)
						helper.wageAbsolute = Utils.getNoNil(getXMLFloat(xmlFile, key.."#wageAbsolute"), 800.0)
						helper.wagePercentile = Utils.getNoNil(getXMLFloat(xmlFile, key.."#wagePercentile"), 100.0)						
						helper.wagePerHour = Utils.getNoNil(BaNe:getWagePerHour(helper.wageType,helper.wageAbsolute,helper.wagePercentile), 800.0)
						-- nighttime factors
						helper.nightFactor_A = Utils.getNoNil(getXMLFloat(xmlFile, key.."#helper_nightFactor_A"), 1.5)
						helper.nightFactor_A = math.round(helper.nightFactor_A, 0.1)
						helper.nightFactor_B = Utils.getNoNil(getXMLFloat(xmlFile, key.."#helper_nightFactor_B"), 2.5)
						helper.nightFactor_B = math.round(helper.nightFactor_B, 0.1)
					else
						if self.debug then
							print("ooo saved settings are BaNe v".. sgXmlVersion .. " - using defaults for mod version v"..tostring(self.version).." ooo")
						end
					end
				end;
				delete(xmlFile)
			else

				print("ooo loading BaNe v"..tostring(self.version).. " - no savedata found ooo")
			end;		
		else
			print("ooo loading BaNe v"..tostring(self.version).." - no savedata found ooo")
		end;	
	end;
	self.settings.helper = helper
	if g_BaNe.debug then
		print("ooo g_BaNe settings after load ---> ooo")
		DebugUtil.printTableRecursively(g_BaNe.settings ,"_",0,4)
	end
end;

local function DoneLoadMission(mission, node)
	local state, result = pcall(BaNe.LoadMissionDone, g_BaNe, mission)
	if state then 
		return result 
	else 
		print("ooo BaNe:LoadMissionDone with error:"..tostring(result).." ooo") 
	end 
end 

function BaNe:LoadMissionDone(mission)	
	-- initialize GUI
	
	-- okay...this is a somewhat tricky part (shoutouts to the VCA guys for that clever idea to l10n those textes by adding an id-key, god damn)
	
	if g_client ~= nil then --g_currentMission:getIsClient()
	
		local function loadTextElement( self, xmlFile, key )		
			local id = getXMLString(xmlFile, key .. "#baneTextID")
			if id ~= nil and g_i18n:hasText(id) ~= nil and type(self.setText) == "function" then 
				self:setText(g_i18n:getText(id))			
			end 
		end
		local function loadGuiElement( self, xmlFile, key )		
			local id = getXMLString(xmlFile, key .. "#baneTextID")
			if id ~= nil and g_i18n:hasText(id) ~= nil and type(self.setText) == "function" then 
				self:setText(g_i18n:getText(id))			
			end 
		end
		
		local origTextElementLoadFromXML = TextElement.loadFromXML
		local origGuiElementLoadFromXML  = GuiElement.loadFromXML
		
		TextElement.loadFromXML = Utils.appendedFunction(origTextElementLoadFromXML, loadTextElement)
		GuiElement.loadFromXML  = Utils.appendedFunction(origGuiElementLoadFromXML, loadGuiElement)
		
		source(Utils.getFilename("scripts/gui/BaNeMenu.lua", self.mdir))
		source(Utils.getFilename("scripts/gui/BaNeMenuMainFrame.lua", self.mdir))
		source(Utils.getFilename("scripts/gui/BaNeMenuHelperFrame.lua", self.mdir))
		source(Utils.getFilename("scripts/gui/BaNeMenuFieldPricesFrame.lua", self.mdir))
		source(Utils.getFilename("scripts/gui/BaNeMenuShopPricesFrame.lua", self.mdir))

		local uiBaNeMenu = BaNeMenu.new(nil, g_messageCenter, g_i18n, g_gui.inputManager)

		local uiBaNeMenuMainFrame = BaNeMenuMainFrame.new()
		local uiBaNeHelperFrame = BaNeMenuHelperFrame.new()
		local uiBaNeFieldPricesFrame = BaNeMenuFieldPricesFrame.new()
		local uiBaNeShopPricesFrame = BaNeMenuShopPricesFrame.new()

		g_gui:loadGui(Utils.getFilename("gui/BaNeMenuMainFrame.xml", self.mdir), "BaNeMenuMainFrame", uiBaNeMenuMainFrame, true)
		g_gui:loadGui(Utils.getFilename("gui/BaNeMenuHelperFrame.xml", self.mdir), "BaNeMenuHelperFrame", uiBaNeHelperFrame, true)
		g_gui:loadGui(Utils.getFilename("gui/BaNeMenuFieldPricesFrame.xml", self.mdir), "BaNeMenuFieldPricesFrame", uiBaNeFieldPricesFrame, true)
		g_gui:loadGui(Utils.getFilename("gui/BaNeMenuShopPricesFrame.xml", self.mdir), "BaNeMenuShopPricesFrame", uiBaNeShopPricesFrame, true)

		g_gui:loadGui(Utils.getFilename("gui/BaNeMenu.xml", self.mdir), "BaNeMenu", uiBaNeMenu)
		
		TextElement.loadFromXML = origTextElementLoadFromXML
		GuiElement.loadFromXML  = origGuiElementLoadFromXML
	
	end
	-- Replace wage return values
	self:inject_helper()
end

function BaNe:loadSavegame() 
end

function BaNe:onInputOpenSettings(actionName, keyStatus, arg3, arg4, arg5)
    if not g_gui:getIsGuiVisible() and g_gui.currentGui == nil then
        g_gui:showGui("BaNeMenu")
    end
end

function BaNe:mouseEvent(posX, posY, isDown, isUp, button)
end

function BaNe:keyEvent(unicode, sym, modifier, isDown)
end

function BaNe:update(dt)
end

function BaNe:draw()   
end

local function registerActionEventsPlayer()
	local state, result = pcall(BaNe.registerActionEventsPlayer, g_BaNe)
	if state then 
		return result 
	else 
		print("ooo BaNe.registerActionEventsPlayer with error:"..tostring(result).." ooo") 
	end 
end

function BaNe:registerActionEventsPlayer()
	-- BaNe settings GUI
	if self.debug then
		print("ooo Called BaNe:registerActionEventsPlayer() ooo")
	end
	local result, eventId = g_inputBinding:registerActionEvent(InputAction.uiBaNe_openMenu, self, self.onInputOpenSettings, false, true, false, true)
	if result then
		g_inputBinding:setActionEventTextVisibility(eventId, false)
		table.insert(self.eventId, eventId)
		if self.debug then
			print("ooo BaNe.eventId="..tostring(self.eventId).." got inserted:"..tostring(eventId).." ooo")
		end
	end
end

local function removeActionEventsPlayer()
	local state, result = pcall(BaNe.removeActionEventsPlayer, g_BaNe)
	if state then 
		return result 
	else 
		print("Error calling BaNe.removeActionEventsPlayer :"..tostring(result)) 
	end 
end

function BaNe:removeActionEventsPlayer()
	self.eventId = {}
end

function BaNe:saveSettings()
	local sgIndex = g_currentMission.missionInfo.savegameIndex
	local sgFolderPath = g_currentMission.missionInfo.savegameDirectory
	if sgFolderPath == nil then
		sgFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), sgIndex)
	end
	
	local key = "BaNe"
	local xmlFile = createXMLFile("BaNe", sgFolderPath .. "/BaNe.xml", key)
	
	-- version
	setXMLString(xmlFile, key.."#version", g_BaNe.version)
	
	--helper values
	
	-- wagePerHour
	setXMLInt(xmlFile, key.."#wageType", g_BaNe.settings.helper.wageType)
	setXMLFloat(xmlFile, key.."#wageAbsolute", g_BaNe.settings.helper.wageAbsolute)
	setXMLFloat(xmlFile, key.."#wagePercentile", g_BaNe.settings.helper.wagePercentile)
	setXMLFloat(xmlFile, key.."#wagePerHour", g_BaNe.settings.helper.wagePerHour)
	-- nighttime factors
	setXMLFloat(xmlFile, key.."#helper_nightFactor_A", g_BaNe.settings.helper.nightFactor_A)
	setXMLFloat(xmlFile, key.."#helper_nightFactor_B", g_BaNe.settings.helper.nightFactor_B)

	saveXMLFile(xmlFile)
	delete(xmlFile)
	print "ooo BaNe settings saved! ooo"
end;

function BaNe:setDefaults()
	local settings = {}
	local general = {}
	local helper = {}
	helper.wageType = 1 -- 1=absolute, 2=percentile
	helper.wageAbsolute = 800.0 -- 800.0 seems to be the smallest reasonable number (= 0.00022 per ms)
	helper.wagePercentile = 1.0 -- 1.0 = 100%
	helper.wagePerHour = BaNe:getWagePerHour(helper.wageType, helper.wageAbsolute, helper.wagePercentile)
	helper.nightFactor_A = 1.5 -- 150% for a good start
	helper.nightFactor_B = 2.5 -- 250% for a good start
	local fields = {}
	local shops = {}		
	settings.general = general
	settings.helper = helper
	settings.fields = fields
	settings.shops = shops
	return settings
end

function BaNe:getWagePerHour(wageType,wageAbs,wagePer)
	local ret = nil
	if wageType ~= nil then
		if wageType == 1 then
			ret = wageAbs
		elseif wageType == 2 then
			ret = 0.001 * 3600 * 1000 * wagePer
			ret = math.round(ret, 0.1)
		else
			print("ooo BaNe:getWagePerHour: couldn't find valid wageType (="..tostring(wageType).." of type '"..tostring(type(wageType)).."')! falling back to 800.0 per Hour absolute! ooo")
			ret = 800.0
		end
	else
		print("ooo BaNe:getWagePerHour: wageType not set! falling back to 800.0 per Hour absolute! ooo")
		ret = 800.0
	end
	if ret ~= nil then
		return ret
	else
		print("ooo BaNe:getWagePerHour: would return nil! falling back to 800.0 per Hour absolute! ooo")
		return 800.0
	end
end

local function beforeLoadMission(mission)
	assert( g_BaNe == nil )
	local base = BaNe.new(g_i18n)
	base.settings = BaNe:setDefaults()
	getfenv(0)["g_BaNe"] = base
	addModEventListener(base);
	if g_BaNe.debug then
		print("ooo BaNe created? getfenv(0)[\"g_BaNe\"]="..tostring(getfenv(0)["g_BaNe"]).." with settings ---> ooo")
		DebugUtil.printTableRecursively(g_BaNe.settings ,"_",0,4)
	end
end 

local function init()
-- first things first
Mission00.load = Utils.prependedFunction(Mission00.load, beforeLoadMission)

-- Append input actions
Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, registerActionEventsPlayer)
Player.removeActionEvents = Utils.appendedFunction(Player.removeActionEvents, removeActionEventsPlayer)

--append loadMission00Finished
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, DoneLoadMission)
end

init()