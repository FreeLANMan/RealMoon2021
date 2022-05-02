
-- weird behaving nodes in vacuum
local drop_nodes = {
	"default:torch",
	"default:torch_wall",
	"default:torch_ceiling",
	"default:ladder_wood",
	"default:ladder_steel",
	"default:dry_shrub",
	"default:papyrus",
	"default:cactus",
	"group:wool",
	"group:wood",
	"group:tree",
	-- "group:mesecon", TODO: add hardcore setting for that one
	-- TODO: maybe: group:dig_immediate
}


local function get_node_drops(node)
	if node.name == "default:papyrus" then
		if math.random(3) == 1 then
			return {"default:paper"}
		end
		return {}
	end
	return minetest.get_node_drops(node)
end

-- weird nodes in vacuum
minetest.register_abm({
        label = "space drop nodes",
	nodenames = drop_nodes,
	neighbors = {"vacuum:vacuum"},
	interval = 1,
	chance = 1,
	action = vacuum.throttle(100, function(pos)

		if not vacuum.is_pos_in_space(pos) or vacuum.near_powered_airpump(pos) then
			return
		end

		local node = minetest.get_node(pos)
		minetest.set_node(pos, {name = "vacuum:vacuum"})

		for _, drop in pairs(get_node_drops(node)) do
			minetest.add_item(pos, ItemStack(drop))
		end
	end)
})
