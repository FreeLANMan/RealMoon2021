
vacuum.airpump_digiline_effector = function(pos, _, channel, msg)
  local set_channel = "airpump" -- static channel for now

  local msgt = type(msg)

  if msgt ~= "table" then
    return
  end

  if channel ~= set_channel then
    return
  end

  if msg.command == "flush" and vacuum.can_flush_airpump(pos) then
    vacuum.flush_airpump(pos)
  end

  if msg.command == "enable" then
    local meta = minetest.get_meta(pos)
    meta:set_int("enabled", 1)
  end

  if msg.command == "disable" then
    local meta = minetest.get_meta(pos)
    meta:set_int("enabled", 0)
  end

end
