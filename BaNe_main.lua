-- Business administration & national economy (for FS22)
-- main faile: BaNe_main.lua
local version = "1.2.5b"
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


local modDir = g_currentModDirectory
local modName = g_currentModName

BaNe = {}
local BaNe_mt = Class(BaNe)

BaNe.setXMLfile = nil

BaNe.SETTINGS_SCHEMA = {}
BaNe.SETTINGS_SCHEMA["Bool"] = {
		"enable"
	}
BaNe.SETTINGS_SCHEMA["Float"] = {
		"factor",
		"leaseFactor"
	}
BaNe.SETTINGS_SCHEMA["Int"] = {
		"wageType",
		"from_hours",
		"to_hours",
		"from_minutes",
		"to_minutes"
	}
BaNe.SETTINGS_SCHEMA["String"] = {	
	}

function BaNe:hasType(vType, vName)
	local ret = false
	if vType ~= nil then
		if BaNe.SETTINGS_SCHEMA[vType] ~= nil then
			for _, v in pairs(BaNe.SETTINGS_SCHEMA[vType]) do
				if tostring(v) == tostring(vName) then
					ret = true
				end
			end
		end
	end
	return ret
end
BaNe.ELEMENT_READ_FUNCTIONS = {}
--

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
	self.settings.fields["leasing"] = {}
	self.settings["shops"] = {}
	self.i18n = i18n
	
	return self
end

function BaNe:loadMap()
	print("ooo BaNe debugging enabled? ooo "..tostring(self.debug).." ooo")
	if self.debug then
		print("ooo BaNe Debug ... BaNe:loadMap ++ isClient="..tostring(g_currentMission:getIsClient()).." ,isServer="..tostring(g_currentMission:getIsServer()).." ,isMasterUser="..tostring(g_currentMission.isMasterUser).." ,isMultiplayer="..tostring(g_currentMission.missionDynamicInfo.isMultiplayer).." mname="..tostring(self.mname).." ooo")
	end
	
	-- Save current settings on gamesave
	FSBaseMission.saveSavegame = Utils.appendedFunction(FSBaseMission.saveSavegame, self.saveSet)
	
	--load Savegame
	local sgIndex = g_currentMission.missionInfo.savegameIndex
	local sgFolderPath = g_currentMission.missionInfo.savegameDirectory
	if sgFolderPath == nil then
		sgFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), sgIndex)
	end

	if g_currentMission:getIsServer() then
		if fileExists(sgFolderPath .. '/careerSavegame.xml') then
			if fileExists(sgFolderPath .. '/BaNe.xml') then
				local loadArray = {}
				loadArray = self:loadSet()
				if loadArray.settings ~= nil then
					g_BaNe.settings = arrayMerge(loadArray.settings,g_BaNe.settings)
				end
				loadArray = nil
			else
				print("ooo loading BaNe v"..tostring(self.version).. " - no saved data found ooo")
			end;		
		else
			print("ooo loading BaNe v"..tostring(self.version).." - no valid savegame found ooo")
		end;	
	end;
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
		g_gui:loadProfiles(Utils.getFilename("guiProfiles.xml", self.mdir))

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
	self:inject_fields()
end

function BaNe:loadSet()
	local sgIndex = g_currentMission.missionInfo.savegameIndex
	local sgFolderPath = g_currentMission.missionInfo.savegameDirectory
	if sgFolderPath == nil then
		sgFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), sgIndex)
	end
	self.setXMLfile = nil
	self.setXMLfile = loadXMLFile("bTEMP", sgFolderPath .. "/newBaNe.xml")
	local subs = BaNe.SETTINGS_SCHEMA
	if self.setXMLfile ~= nil then
		local loadedSettings = {}
		main = "BaNe"
		-- saveVersion					
		local sgXmlVersion = Utils.getNoNil(getXMLString(self.setXMLfile, main.."#version"), "0.0.0")
			print("ooo loading BaNe v".. self.version .. " ooo loading savedata ooo")
		if tostring(sgXmlVersion) == tostring(self.version) then
			loadedSettings = self:loadSetRec(main)
		else
			print("ooo found settings are for BaNe v".. sgXmlVersion .. " - using defaults for used version v"..tostring(self.version).." ooo")						
		end
		return loadedSettings
	end
	delete(self.setXMLfile)
end

function BaNe:loadSetRec(nodePath, parent)
	local i = 0
	local setArray = {}
	while true do
		local xmlNodePath = nodePath..".SetElement("..i..")"
		local typeName = getXMLString(self.setXMLfile, xmlNodePath .. "#type")
		if typeName == nil then
			break
		end
		if setArray[typeName] == nil then
			setArray[typeName] = {}
		end
		local idName = getXMLString(self.setXMLfile, xmlNodePath .. "#id")
		local dataType = getXMLString(self.setXMLfile, xmlNodePath .. "#data")
		if dataType == nil and idName ~= nil then
			local tmpArray = {}
			tmpArray[typeName] = self:loadSetRec(xmlNodePath, typeName)
			if tmpArray[typeName][idName] ~= nil then
				setArray[typeName][idName] = {}
				setArray[typeName][idName] = tmpArray[typeName][idName]
			end			
		elseif dataType ~= nil and idName ~= nil then
			local readFunction = BaNe.ELEMENT_READ_FUNCTIONS[dataType]
			if dataType == "XMLFloat" then
				setArray[typeName][idName] = readFunction(self.setXMLfile, xmlNodePath.."#value", 0.001)
			else
				setArray[typeName][idName] = readFunction(self.setXMLfile, xmlNodePath.."#value")
			end
		end
		i = i + 1		
	end
	return setArray
end

function BaNe:saveSet(settings)
	if settings == nil then
		settings = g_BaNe.settings
	end
	local sgIndex = g_currentMission.missionInfo.savegameIndex
	local sgFolderPath = g_currentMission.missionInfo.savegameDirectory
	if sgFolderPath == nil then
		sgFolderPath = ('%ssavegame%d'):format(getUserProfileAppPath(), sgIndex)
	end
	
	local main = "BaNe"
	self.setXMLfile = nil
	self.setXMLfile = createXMLFile("BaNe", sgFolderPath .. "/newBaNe.xml", main)
	-- version
	setXMLString(self.setXMLfile, main.."#version", g_BaNe.version)
	local i = 0	
	if type(settings) == "table" then
		for k, v in pairs(settings) do
			local xmlNodePath = main..".SetElement("..i..")"
			if type(v) == "table" then				
				setXMLString(self.setXMLfile, xmlNodePath.."#type", "settings")
				setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
				self:saveSetRec(xmlNodePath, v, k)
			else
				if type(v) == "number" then
					setXMLString(self.setXMLfile, xmlNodePath.."#type", "settings")
					setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
					if self:hasType("Int",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLInt")
						setXMLInt(self.setXMLfile, xmlNodePath.."#value", v)
					elseif self:hasType("Float",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLFloat")
						setXMLFloat(self.setXMLfile, xmlNodePath.."#value", v)
					elseif self:hasType("Bool",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLBool")
						setXMLBool(self.setXMLfile, xmlNodePath.."#value", v)
					elseif self:hasType("String",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLString")
						setXMLString(self.setXMLfile, xmlNodePath.."#value", v)
					else
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLFloat")
						setXMLFloat(self.setXMLfile, xmlNodePath.."#value", v)
					end
				elseif type(v) == "boolean" then
					setXMLString(self.setXMLfile, xmlNodePath.."#type", "settings")
					setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
					setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLBool")
					setXMLBool(self.setXMLfile, xmlNodePath.."#value", v)
				elseif type(v) == "string" then
					setXMLString(self.setXMLfile, xmlNodePath.."#type", "settings")
					setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
					setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLString")
					setXMLString(self.setXMLfile, xmlNodePath.."#value", v)
				end
			end
			i = i + 1
		end
	end
	saveXMLFile(self.setXMLfile)
	delete(self.setXMLfile)
end

function BaNe:saveSetRec(nodePath, settings, parent)
	local setArray = {}
	setArray[parent] = settings
	local i = 0	
		for k, v in pairs(setArray[parent]) do
			local xmlNodePath = nodePath..".SetElement("..i..")"
			if type(v) == "table" then
				setXMLString(self.setXMLfile, xmlNodePath.."#type", parent)
				setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
				self:saveSetRec(xmlNodePath, v, k)
			else
				if type(v) == "number" then
					setXMLString(self.setXMLfile, xmlNodePath.."#type", parent)
					setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
					if self:hasType("Int",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLInt")
						setXMLInt(self.setXMLfile, xmlNodePath.."#value", v)
					elseif self:hasType("Float",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLFloat")
						setXMLFloat(self.setXMLfile, xmlNodePath.."#value", v)
					elseif self:hasType("Bool",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLBool")
						setXMLBool(self.setXMLfile, xmlNodePath.."#value", v)
					elseif self:hasType("String",k) then
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLString")
						setXMLString(self.setXMLfile, xmlNodePath.."#value", v)
					else
						setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLFloat")
						setXMLFloat(self.setXMLfile, xmlNodePath.."#value", v)
					end
				elseif type(v) == "boolean" then
					setXMLString(self.setXMLfile, xmlNodePath.."#type", parent)
					setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
					setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLBool")
					setXMLBool(self.setXMLfile, xmlNodePath.."#value", v)
				elseif type(v) == "string" then
					setXMLString(self.setXMLfile, xmlNodePath.."#type", parent)
					setXMLString(self.setXMLfile, xmlNodePath.."#id", k)
					setXMLString(self.setXMLfile, xmlNodePath.."#data","XMLFloat")
					setXMLString(self.setXMLfile, xmlNodePath.."#value", parent)			
				end
			end
			i = i + 1
		end
	
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

	--
	-- helper
	--	
	-- wagePerHour
	setXMLInt(xmlFile, key.."#helper_wageType", g_BaNe.settings.helper.wageType)
	setXMLFloat(xmlFile, key.."#helper_wageAbsolute", g_BaNe.settings.helper.wageAbsolute)
	setXMLFloat(xmlFile, key.."#helper_wagePercentile", g_BaNe.settings.helper.wagePercentile)
	setXMLFloat(xmlFile, key.."#helper_conveyorPercent", g_BaNe.settings.helper.conveyorPercent)
	setXMLFloat(xmlFile, key.."#helper_fieldworkPercent", g_BaNe.settings.helper.fieldworkPercent)
	-- nighttime factors
	setXMLBool(xmlFile, key.."#helper_enableFactor_A", g_BaNe.settings.helper.factorA["enable"])
	setXMLFloat(xmlFile, key.."#helper_nightFactor_A", g_BaNe.settings.helper.factorA["factor"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_A_fth", g_BaNe.settings.helper.factorA["from_hours"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_A_ftm", g_BaNe.settings.helper.factorA["from_minutes"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_A_tth", g_BaNe.settings.helper.factorA["to_hours"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_A_ttm", g_BaNe.settings.helper.factorA["to_minutes"])
	setXMLBool(xmlFile, key.."#helper_enableFactor_B", g_BaNe.settings.helper.factorB["enable"])
	setXMLFloat(xmlFile, key.."#helper_nightFactor_B", g_BaNe.settings.helper.factorB["factor"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_B_fth", g_BaNe.settings.helper.factorB["from_hours"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_B_ftm", g_BaNe.settings.helper.factorB["from_minutes"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_B_tth", g_BaNe.settings.helper.factorB["to_hours"])
	setXMLInt(xmlFile, key.."#helper_nightFactor_B_ttm", g_BaNe.settings.helper.factorB["to_minutes"])
	--
	-- fields
	--
	-- leaseFactor
	setXMLFloat(xmlFile, key.."#fields_leaseFactor", g_BaNe.settings.fields.leaseFactor)
	
	saveXMLFile(xmlFile)
	delete(xmlFile)
	print "ooo BaNe settings saved! ooo"
end;

function BaNe:setDefaults()
	local settings = {}
	local general = {}
	
	local helper = {}
	--
	-- helper
	--
	--wageSettings
	helper.wageType = 1 -- 1=absolute, 2=percentile
	helper.wageAbsolute = 800.0 -- 800.0 seems to be the smallest reasonable number (= 0.00022 per ms)
	helper.wagePercentile = 1.0 -- 1.0 = 100%
	helper.conveyorPercent = 1.25 -- 1.25 = 125%
	helper.fieldworkPercent = 1.25 -- 1.25 = 125%
	--helper.wagePerHour = BaNe:getWagePerHour(helper.wageType, helper.wageAbsolute, helper.wagePercentile)
	helper.factorA = {}
	helper.factorB = {}
	helper.factorA["enable"] = true
	helper.factorA["factor"] = 1.5 -- 150% for a good start
	helper.factorA["from_hours"] = 20
	helper.factorA["from_minutes"] = 0
	helper.factorA["to_hours"] = 22
	helper.factorA["to_minutes"] = 0
	helper.factorB["enable"] = true
	helper.factorB["factor"] = 2.5 -- 250% for a good start
	helper.factorB["from_hours"] = 22
	helper.factorB["from_minutes"] = 0
	helper.factorB["to_hours"] = 6
	helper.factorB["to_minutes"] = 0
	
	local fields = {}
	--
	-- fields
	--
	fields.leaseFactor = 0.015 -- 1.5%
	fields.leasing = {}
	
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
			ret = 0.0004 * 3600 * 1000 * wagePer
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
	source(Utils.getFilename("scripts/BaNe_luautils.lua", self.mdir))
	source(Utils.getFilename("scripts/BaNe_helper.lua", self.mdir))
	source(Utils.getFilename("scripts/BaNe_fields.lua", self.mdir))	
	local procFuncs = BaNe.ELEMENT_READ_FUNCTIONS
	procFuncs.XMLString = BaNe.readXMLString
	procFuncs.XMLBool = BaNe.readXMLBool
	procFuncs.XMLFloat = BaNe.readXMLFloat
	procFuncs.XMLInt = BaNe.readXMLInt
end 

function BaNe.readXMLString(xmlFile, key)
	return getXMLString(xmlFile, key)
end
function BaNe.readXMLBool(xmlFile, key)
	return getXMLBool(xmlFile, key)
end
function BaNe.readXMLFloat(xmlFile, key, round)
	return math.round(getXMLFloat(xmlFile, key), round)
end
function BaNe.readXMLInt(xmlFile, key)
	return getXMLInt(xmlFile, key)
end


function BaNe:init()

-- first things first
Mission00.load = Utils.prependedFunction(Mission00.load, beforeLoadMission)

-- Append input actions
Player.registerActionEvents = Utils.appendedFunction(Player.registerActionEvents, registerActionEventsPlayer)
Player.removeActionEvents = Utils.appendedFunction(Player.removeActionEvents, removeActionEventsPlayer)

--append loadMission00Finished
Mission00.loadMission00Finished = Utils.appendedFunction(Mission00.loadMission00Finished, DoneLoadMission)
end

BaNe:init()