-- Business administration & national economy (for FS22)
-- helper changes file: BaNe_helper.lua
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

function BaNe:inject_helper()
	AIJob.getPricePerMs = Utils.overwrittenFunction(AIJob.getPricePerMs, self.getWagePerMs)
end

function BaNe:getWagePerMs(superFunc, ...)
	local wagePerHour = BaNe:getWagePerHour(g_BaNe.settings.helper.wageType, g_BaNe.settings.helper.wageAbsolute, g_BaNe.settings.helper.wagePercentile)
	local actPricePerMs = wagePerHour / 60 / 60 / 1000;
	local facA, facB = g_BaNe.settings.helper.factorA, g_BaNe.settings.helper.factorB
	local eFac, nFac1, nFac2 = 1.0, facA["factor"], facB["factor"]
	local currentTime = g_currentMission.environment.dayTime / 3600000
	local timeHours, timeMinutes
	
	local fhrsA, fminA, thrsA, tminA = tonumber(facA["from_hours"]), tonumber(facA["from_minutes"]), tonumber(facA["to_hours"]), tonumber(facA["to_minutes"])
	local fhrsB, fminB, thrsB, tminB = tonumber(facB["from_hours"]), tonumber(facB["from_minutes"]), tonumber(facB["to_hours"]), tonumber(facB["to_minutes"])

	if tminA ~= nil and thrsA ~= nil then
		if tminA == 0 then
			tminA = 59
			if thrsA == 0 then
				thrsA = 23
			else
				thrsA = thrsA - 1
			end
		else
			tminA = tminA - 1
		end
		
	end
	
	if tminB ~= nil and thrsB ~= nil then
		if tminB == 0 then
			tminB = 59
			if thrsB == 0 then
				thrsB = 23
			else
				thrsB = thrsB - 1
			end
		else
			tminB = tminB - 1
		end
	end
	
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
		local daychangeA, daychangeB = false
		if farm ~= nil then
			if g_BaNe.debug then
				print("ooo BaNe Debug ... BaNe:getWagePerMs ++ actual farm money="..tostring(farm.money)..", current time="..tostring(timeText).." ooo")
			end
		end

		eFac = 1.0
		if facA["enable"] then
			if (fhrsA*60 + fminA) > (thrsA*60 + tminA) then
				daychangeA = true
			end
			if daychangeA then
				if ((timeHours >= fhrsA and timeMinutes >= fminA) and (timeHours <= 23 and timeMinutes <= 59)) or ((timeHours >= 0 and timeMinutes >= 0) and (timeHours <= thrsA and timeMinutes <= tminA)) then
					eFac = eFac * nFac1
				end
			else
				if ((timeHours >= fhrsA and timeMinutes >= fminA) and (timeHours <= thrsA and timeMinutes <= tminA)) then
					eFac = eFac * nFac1
				end
			end
		end
		if facB["enable"] then
			if (fhrsB*60 + fminB) > (thrsB*60 + tminB) then
				daychangeB = true
			end
			if daychangeB then
				if ((timeHours >= fhrsB and timeMinutes >= fminB) and (timeHours <= 23 and timeMinutes <= 59)) or ((timeHours >= 0 and timeMinutes >= 0) and (timeHours <= thrsB and timeMinutes <= tminB)) then
					eFac = eFac * nFac2
				end
			else
				if ((timeHours >= fhrsB and timeMinutes >= fminB) and (timeHours <= thrsB and timeMinutes <= tminB)) then
					eFac = eFac * nFac2
				end
			end
		end
		
		if g_BaNe.debug then
			print("ooo BaNe Debug ... BaNe:getWagePerMs ++ wagePerHour="..tostring(wagePerHour).." ,nFac1="..tostring(nFac1).." ,nFac2="..tostring(nFac2).." ,actPricePerMs="..tostring(actPricePerMs)..", eFac="..tostring(eFac).." ooo")
			print("ooo BaNe Debug ... BaNe:getWagePerMs ++ nFac1 valid from (included):"..string.format("%02d:%02d - %02d:%02d", fhrsA, fminA, thrsA, tminA).." ooo")
			print("ooo BaNe Debug ... BaNe:getWagePerMs ++ nFac2 valid from (included):"..string.format("%02d:%02d - %02d:%02d", fhrsB, fminB, thrsB, tminB).." ooo")
		end
		return actPricePerMs * eFac
	else
		if g_BaNe.debug then
			print("ooo BaNe Debug ... BaNe:getPricePerMs ++ returning to superFunc() ooo")
		end
		return superFunc(self, ...)
	end
end