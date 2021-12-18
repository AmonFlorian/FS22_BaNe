-- Business administration & national economy (for FS22)
-- LUA utility file: BaNe_main.lua
-- v1.2.0b
--
-- @author [kwa:m]
-- @date 18.12.2021
--
-- Copyright (c) [kwa:m]
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


function math.sign(n)
	return (n >= 0 and 1) or -1
end

function math.round(n, bracket)
	bracket = bracket or 1;
	return math.floor(n/bracket + math.sign(n) * 0.5) * bracket;
end;

function arrayMerge(array1, array2)
    local temparray = {}
    local strong = {}
    local weak = {}
    strong = array1
    weak = array2
    if type(strong) == "table" and type(weak) == "table" then
        for k,v in pairs(strong) do
            if type(v) == "table" and weak[k] ~= nil then
                temparray[k] = arrayMerge(strong[k],weak[k])
            elseif weak[k] == nil or (weak[k] ~= nil and type(weak[k]) ~= "table") then
                temparray[k] = v
            end
        end
        for k,v in pairs(weak) do
            if type(v) == "table" and strong[k] ~= nil then
                temparray[k] = arrayMerge(strong[k],weak[k])
            elseif strong[k] == nil then
                temparray[k] = v
            end
        end
        return temparray 
    else
        if type(strong) == table then
            return strong
        elseif type(weak) == table then
            return weak
        else
            return strong
        end
    end
end

function validateTimeString(str, pat)
	if str ~= nil then
		if str:len() >= 4 and str:len() <= 5 then
			if pat == nil then
				pat = "^%d+:%d%d$"
			end
			if string.find(str,pat) ~= nil then
				local tstr, thr, tmin = {}, nil, nil
				tstr = str:split(":")
				if #tstr >= 2 then
					thr, tmin = tonumber(tstr[1]), tonumber(tstr[2])
					if thr ~= nil and tmin ~= nil then
						if thr >= 0 and thr <= 23 and tmin >= 0 and tmin <= 59 then
							return true 
						else
							return false
						end
					else
						return false
					end
				else
					return false
				end
			else
				return false
			end
		else
			return false
		end
	else
		return false
	end
end

function validateString(str, pat)
	if str ~= nil then
		
		if pat == nil then
			pat = "(%s+)"
		end
		if string.find(str,pat) ~= nil then
			return true 
		else
			return false
		end
		
	else
		return false
	end
end