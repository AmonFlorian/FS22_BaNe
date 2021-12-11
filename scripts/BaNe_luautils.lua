-- Business administration & national economy (for FS22)
-- LUA utility file: BaNe_main.lua
-- v0.5.0a
--
-- @author [kwa:m]
-- @date 02.12.2021
--
-- Copyright (c) [kwa:m]
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