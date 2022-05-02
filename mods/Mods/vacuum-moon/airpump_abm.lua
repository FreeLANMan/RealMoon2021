

minetest.register_abm({
  label = "airpump",
	nodenames = {"vacuum:airpump"},
	interval = 5,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		if vacuum.airpump_enabled(meta) then

			-- The spacesuit mod must be loaded after this mod, so we can't check at the start.
			local has_spacesuit = minetest.get_modpath("spacesuit")
			local used
			if vacuum.is_pos_in_space(pos) then
				used = vacuum.do_empty_bottle(meta:get_inventory())
				if used and has_spacesuit then
					vacuum.do_repair_spacesuit(meta:get_inventory())
				end
			else
				if has_spacesuit then
					used = vacuum.do_repair_spacesuit(meta:get_inventory())
				end
				if not used then
					used = vacuum.do_fill_bottle(meta:get_inventory())
				end
			end

			if used then
				minetest.sound_play("vacuum_hiss", {pos = pos, gain = 0.5})

				minetest.add_particlespawner({
					amount = 12,
					time = 4,
					minpos = vector.subtract(pos, 0.95),
					maxpos = vector.add(pos, 0.95),
					minvel = {x=-1.2, y=-1.2, z=-1.2},
					maxvel = {x=1.2, y=1.2, z=1.2},
					minacc = {x=0, y=0, z=0},
					maxacc = {x=0, y=0, z=0},
					minexptime = 0.5,
					maxexptime = 1,
					minsize = 1,
					maxsize = 2,
					vertical = false,
					texture = "bubble.png"
				})
			end
		end
	end
})



-- initial airpump step
minetest.register_abm({
  label = "airpump seed",
	nodenames = {"vacuum:airpump"},
	neighbors = {"vacuum:vacuum"},
	interval = 1,
	chance = 1,
	action = function(pos)
		local meta = minetest.get_meta(pos)
		if vacuum.airpump_active(meta) then
			-- seed initial air
			local node = minetest.find_node_near(pos, 1, {"vacuum:vacuum"})

			if node ~= nil then
				minetest.set_node(node, {name = "air"})
            end

			local node = minetest.find_node_near(pos, 2, {"vacuum:vacuum"})

			if node ~= nil then
				minetest.set_node(node, {name = "air"})

			end
		end
	end
})
