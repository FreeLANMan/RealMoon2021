
vacuum = {
	space_height = tonumber(minetest.settings:get("vacuum.space_height")) or -1000,
	air_pump_range = tonumber(minetest.settings:get("vacuum.air_pump_range")) or 5,
	profile_mapgen = minetest.settings:get("vacuum.profile_mapgen"),
	flush_bottle_usage = 99,
	debug = minetest.settings:get("vacuum.debug"),
	disable_physics = minetest.settings:get("vacuum.disable_physics"),
	disable_mapgen = minetest.settings:get("vacuum.disable_mapgen")
}

local MP = minetest.get_modpath("vacuum")

if minetest.get_modpath("digilines") then
	dofile(MP.."/digilines.lua")
end

dofile(MP.."/util/throttle.lua")
dofile(MP.."/common.lua")
dofile(MP.."/vacuum.lua")
dofile(MP.."/compat.lua")
dofile(MP.."/airbottle.lua")
dofile(MP.."/airpump_functions.lua")
dofile(MP.."/airpump.lua")
dofile(MP.."/airpump_abm.lua")
dofile(MP.."/dignode.lua")

if not vacuum.disable_mapgen then
	dofile(MP.."/mapgen.lua")
end

if not vacuum.disable_physics then
	dofile(MP.."/physics_drop.lua")
	dofile(MP.."/physics_leakage.lua")
	dofile(MP.."/physics_plants.lua")
	--dofile(MP.."/physics_propagation.lua")
	dofile(MP.."/physics_soil.lua")
	dofile(MP.."/physics_sublimation.lua")
end

if minetest.get_modpath("spacesuit") then
	dofile(MP.."/spacesuit.lua")
end



print("[OK] Vacuum")
