

-- plants in vacuum
minetest.register_abm({
        label = "space vacuum plants",
	nodenames = {
		"group:sapling",
		"group:plant",
		"group:flora",
		"group:flower",
		"group:leafdecay",
		"ethereal:banana", -- ethereal compat
		"ethereal:orange",
		"ethereal:strawberry"
	},
	neighbors = {"vacuum:vacuum"},
	interval = 1,
	chance = 1,
	action = vacuum.throttle(100, function(pos)
		minetest.set_node(pos, {name = "default:dry_shrub"})
	end)
})
