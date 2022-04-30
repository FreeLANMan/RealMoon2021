
-- various dirts in vacuum
minetest.register_abm({
  label = "space vacuum soil dry",
	nodenames = {
		"default:dirt",
		"default:dirt_with_grass",
		"default:dirt_with_snow",
		"default:dirt_with_dry_grass",
		"default:dirt_with_grass_footsteps",
		"default:dirt_with_rainforest_litter",
		"default:dirt_with_coniferous_litter"
	},
	neighbors = {"vacuum:vacuum"},
	interval = 1,
	chance = 1,
	action = vacuum.throttle(100, function(pos)
		minetest.set_node(pos, {name = "default:gravel"})
	end)
})
