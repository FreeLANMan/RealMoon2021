

vacuum.air_bottle_image = "vessels_steel_bottle.png^[colorize:#0000FFAA"

-- space pos checker
vacuum.is_pos_in_space = function(pos)
	return pos.y > vacuum.space_height
end

-- (cheaper) space check, gets called more often than `is_pos_in_space`
vacuum.no_vacuum_abm = function(pos)
	return pos.y > vacuum.space_height - 40 and pos.y < vacuum.space_height + 40
end

-- returns true if the position is near a powered air pump
function vacuum.near_powered_airpump(pos)
	local pos1 = vector.subtract(pos, {x=vacuum.air_pump_range, y=vacuum.air_pump_range, z=vacuum.air_pump_range})
	local pos2 = vector.add(pos, {x=vacuum.air_pump_range, y=vacuum.air_pump_range, z=vacuum.air_pump_range})

	local nodes = minetest.find_nodes_in_area(pos1, pos2, {"vacuum:airpump"})
	for _,node in ipairs(nodes) do
		local meta = minetest.get_meta(node)
		if vacuum.airpump_active(meta) then
			return true
		end
	end

	return false
end
