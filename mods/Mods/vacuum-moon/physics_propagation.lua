local has_monitoring = minetest.get_modpath("monitoring")

local metric_space_vacuum_abm

if has_monitoring then
  metric_space_vacuum_abm = monitoring.counter("vacuum_abm_count", "number of space vacuum abm calls")
end

-- vacuum propagation
minetest.register_abm({
  label = "air -> vacuum replacement",
	nodenames = {"air"},
	neighbors = {"vacuum:vacuum"},
	interval = 1,
    chance = 0,
    --chance = 3,
	--chance = 1,
	action = vacuum.throttle(1000, function(pos)
    -- update metrics
		if metric_space_vacuum_abm ~= nil then metric_space_vacuum_abm.inc() end

		--if vacuum.is_pos_in_space(pos) and not vacuum.near_powered_airpump(pos) then
			-- in space, evacuate air
			--minetest.set_node(pos, {name = "vacuum:vacuum"})
		--end
	end)
})

-- air propagation
-- works slower than vacuum abm
minetest.register_abm({
  label = "vacuum -> air replacement",
	nodenames = {"vacuum:vacuum"},
	neighbors = {"air"},
	interval = 1,
	chance = 2,
	action = vacuum.throttle(1000, function(pos)

    -- update metrics
		if metric_space_vacuum_abm ~= nil then metric_space_vacuum_abm.inc() end

		if not vacuum.is_pos_in_space(pos) or vacuum.near_powered_airpump(pos) then
			-- on earth or near a powered airpump
			minetest.set_node(pos, {name = "air"})
		end
	end)
})
