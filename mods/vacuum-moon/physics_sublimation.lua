

-- sublimate nodes in vacuum
minetest.register_abm({
  label = "space vacuum sublimate",
	nodenames = {"group:snowy", "group:leaves", "group:water"},
	neighbors = {"vacuum:vacuum"},
	interval = 1,
	chance = 1,
	action = vacuum.throttle(100, function(pos)
		if not vacuum.is_pos_in_space(pos) or vacuum.near_powered_airpump(pos) then
			return
		end

		minetest.set_node(pos, {name = "vacuum:vacuum"})
	end)
})
