-- Business administration & national economy (for FS22)
-- helper changes file: BaNe_helper.lua
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

function BaNe:inject_helper()
	AIJob.getPricePerMs = Utils.overwrittenFunction(AIJob.getPricePerMs, self.getWagePerMs)
end

function BaNe:getWagePerMs(superFunc, ...)
	local wagePerHour = g_BaNe.settings.helper.wagePerHour
	local actPricePerMs = wagePerHour / 60 / 60 / 1000;
	local eFac, nFac1, nFac2 = 1.0, g_BaNe.settings.helper.nightFactor_A, g_BaNe.settings.helper.nightFactor_B
	local currentTime = g_currentMission.environment.dayTime / 3600000
	local timeHours, timeMinutes
	if currentTime ~= nil then
		timeHours = math.floor(currentTime)
		timeMinutes = math.floor((currentTime - timeHours) * 60)
		if g_BaNe.debug then
				print("ooo BaNe Debug ... BaNe:getWagePerMs ++ currentTime="..tostring(currentTime)..", timeHours="..tostring(timeHours)..", timeMinutes="..tostring(timeMinutes).." ooo")
		end;
	else
		timeHours = 11
		timeMinutes = 11
		if g_BaNe.debug then
				print("ooo BaNe Debug ... BaNe:getWagePerMs ++ no current time found! ooo")
		end
	end
	if actPricePerMs ~= nil then
		local timeText = string.format("%02d:%02d", timeHours, timeMinutes)
		local farm = g_farmManager:getFarmById(g_currentMission:getFarmId())
		if farm ~= nil then
			if g_BaNe.debug then
				print("ooo BaNe Debug ... BaNe:getWagePerMs ++ actual farm money="..tostring(farm.money)..", current time="..tostring(timeText).." ooo")
			end
		end
		if timeHours >= 18 and timeHours <=21 then
			eFac = nFac1
		elseif (timeHours >= 22) or (timeHours >= 0 and timeHours <= 5) then
			eFac = nFac2
		end;
		if g_BaNe.debug then
			print("ooo BaNe Debug ... BaNe:getWagePerMs ++ wagePerHour="..tostring(wagePerHour).." ,nFac1="..tostring(nFac1).." ,nFac2="..tostring(nFac2).." ,actPricePerMs="..tostring(actPricePerMs)..", eFac="..tostring(eFac).." ooo")
		end
		return actPricePerMs * eFac
	else
		if g_BaNe.debug then
			print("ooo BaNe Debug ... BaNe:getPricePerMs ++ returning to superFunc() ooo")
		end
		return superFunc(self, ...)
	end
end