local has_monitoring = minetest.get_modpath("monitoring")
local has_mesecons_random = minetest.get_modpath("mesecons_random")
local has_technic = minetest.get_modpath("technic")

local metric_space_vacuum_leak_abm

if has_monitoring then
  metric_space_vacuum_leak_abm = monitoring.counter("vacuum_abm_leak_count", "number of space vacuum leak abm calls")
end

-- air leaking nodes
local leaky_nodes = {
	--"group:door",
	--"group:soil",
	--"group:pipe", "group:tube"
}

if has_mesecons_random then
  table.insert(leaky_nodes, "mesecons_random:ghoststone_active")
end

if has_technic then
  --table.insert(leaky_nodes, "technic:lv_cable")
  table.insert(leaky_nodes, "technic:mv_cable")
  table.insert(leaky_nodes, "technic:hv_cable")
end


-- depressurize through leaky nodes
minetest.register_abm({
        label = "space vacuum depressurize",
	nodenames = leaky_nodes,
	neighbors = {"vacuum:vacuum"},
	interval = 2,
	chance = 2,
	action = vacuum.throttle(250, function(pos)
		if metric_space_vacuum_leak_abm ~= nil then metric_space_vacuum_leak_abm.inc() end

		if not vacuum.is_pos_in_space(pos) or vacuum.near_powered_airpump(pos) then
			-- on earth: TODO: replace vacuum with air
			return
		else
			local node = minetest.get_node(pos)

			if node.name == "pipeworks:entry_panel_empty" or node.name == "pipeworks:entry_panel_loaded" then
				-- air thight pipes
				return
			end

			if node.name == "vacuum:airpump" then
				-- pump is airthight
				return
			end

			-- TODO check n nodes down (multiple simple door airlock hack)
			-- in space: replace air with vacuum
			local surrounding_node = minetest.find_node_near(pos, 1, {"air"})

			if surrounding_node ~= nil then
			        if vacuum.debug then
					-- debug mode, set
					minetest.set_node(surrounding_node, {name = "default:cobble"})
				else
					-- normal case
					minetest.set_node(surrounding_node, {name = "vacuum:vacuum"})
				end
			end
		end
	end)
})
