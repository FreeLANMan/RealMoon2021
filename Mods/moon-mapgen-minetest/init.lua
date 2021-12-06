--[[
LICENSE FOR CODE (NOT FOR TEXTURES)

The MIT License (MIT)

Code copyright (c) 2015 Alexander R. Pruss

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE. 
--]]

local ie = _G

if minetest.request_insecure_envoironment then
local ie = minetest.request_insecure_environment()
end

local meters_per_land_node = 150
local height_multiplier = 1
--local gravity = 0.17
local sky = "fancy"
local projection_mode = "equaldistance"
local teleport = false
local albedo = true

	
local source = ie.debug.getinfo(1).source:sub(2)
-- Detect windows via backslashes in paths
local mypath = minetest.get_modpath(minetest.get_current_modname())
local is_windows = (nil ~= string.find(ie.package.path..ie.package.cpath..source..mypath, "%\\%?"))
local path_separator
if is_windows then
   path_separator = "\\"
else
   path_separator = "/"
end
mypath = mypath .. path_separator

local settings = Settings(mypath .. "settings.conf")
local x = settings:get("land_node_meters")
if x then meters_per_land_node = tonumber(x) end
x = settings:get("height_multiplier")
if x then height_multiplier = tonumber(x) end
--x = settings:get("gravity")
--if x then gravity = tonumber(x) end
x = settings:get("sky")
if x then sky = x end
x = settings:get("projection")
if x then projection_mode = x end
x = settings:get_bool("teleport")
if x ~= nil then teleport = x end
x = settings:get_bool("albedo")
if x ~= nil then albedo = x end

local need_update = false
local world_settings = Settings(minetest.get_worldpath() .. path_separator .. "moon-mapgen-settings.conf")
local x = world_settings:get("projection_mode")
if x then
	projection_mode = x
else
	world_settings:set("projection_mode", projection_mode)
	need_update = true
end
local x = world_settings:get("land_node_meters")
if x then
	meters_per_land_node=tonumber(x)
else
	world_settings:set("land_node_meters", tostring(meters_per_land_node))
	need_update = true
end
local x = world_settings:get("height_multiplier")
if x then
	height_multiplier=tonumber(x)
else
	world_settings:set("height_multiplier", tostring(height_multiplier))
	need_update = true
end
local x = world_settings:get_bool("teleport")
if x ~= nil then
	teleport=x
else
	world_settings:set("teleport", tostring(teleport))
	need_update = true
end
local x = world_settings:get_bool("albedo")
if x ~= nil then
	albedo=x
else
	world_settings:set("albedo", tostring(albedo))
	need_update = true
end
if need_update then 
	minetest.log("action", "Saving world-specific settings.")
	world_settings:write() 
end

minetest.set_mapgen_params({mgname="singlenode", water_level = -30000}) -- flags="nolight", flagmask="nolight"
local projection

local meters_per_vertical_node = meters_per_land_node / height_multiplier
local max_height_units = 255
local radius = 1738000
local meters_per_degree = 30336.3
local meters_per_height_unit = 77.7246
local inner_radius = 1737400

local nodes_per_height_unit = meters_per_height_unit / meters_per_vertical_node
local max_height_nodes = max_height_units * nodes_per_height_unit
local land_normalize = meters_per_land_node / radius

local radius_nodes = radius / meters_per_land_node
local inner_radius_nodes = inner_radius / meters_per_land_node
local outer_radius_nodes = inner_radius_nodes + max_height_nodes

local offsets = {0,0}
local farside_below = -5000
local thickness = 500


local chunks = {}
local data_per_degree = 64
local row_size = 360 * data_per_degree
local rows_per_hemisphere = 90 * data_per_degree
local rows_total = 180 * data_per_degree
local rows_per_chunk = 5 * data_per_degree
local columns_per_hemisphere = 180 * data_per_degree
local columns_total = 360 * data_per_degree
local half_pi = math.pi / 2
local radians_to_pixels = 180 * data_per_degree / math.pi

local function get_chunk(chunk_number)
	local chunk = chunks[chunk_number]

	if chunk then
		return chunk
	end

	local f = assert(ie.io.open(mypath .. "terrain" .. path_separator .. chunk_number .. ".dat.zlib", "rb"))
	chunk = minetest.decompress(f:read("*all"), 'inflate')
	f:close()
	chunks[chunk_number] = chunk
	return chunk
end

local function get_raw_data(column,row)
        if row < 0 then
           row = 0
        elseif row >= rows_total then
           row = rows_total - 1
        end
        if column < 0 then
           column = columns_total - 1
        elseif column >= columns_total then
           column = 0
        end
	local chunk_number = math.floor(row / rows_per_chunk)
	local offset = (row - chunk_number * rows_per_chunk) * row_size + column
	return get_chunk(chunk_number):byte(offset+1) -- correct for lua strings starting at index 1
end

local function get_interpolated_data(longitude,latitude)
    local row = (half_pi - latitude) * radians_to_pixels
	if longitude < 0 then longitude = longitude + 2 * math.pi end
    local column = longitude * radians_to_pixels
    local row0 = math.floor(row)
    local drow = row - row0
    local column0 = math.floor(column)
    local dcolumn = column - column0
    local v00 = get_raw_data(column0,row0)
    local v10 = get_raw_data(column0+1,row0)
    local v01 = get_raw_data(column0,row0+1)
    local v11 = get_raw_data(column0+1,row0+1)
    local v0 = v00 * (1-dcolumn) + v10 * dcolumn
    local v1 = v01 * (1-dcolumn) + v11 * dcolumn
    return v0 * (1-drow) + v1 * drow
end

local function height_by_longitude_latitude(longitude, latitude)
	return get_interpolated_data(longitude,latitude) * nodes_per_height_unit
end


local moonstone = {}
local block_prefix = minetest.get_current_modname()..":moonstone_"

-- recipe water bucket
minetest.register_craft({
    type = "shapeless",
    output = 'bucket:bucket_water',
    recipe = {
        "bucket:bucket_empty",
        "default:ice"
    }
})

-- recipe high FeO regolith
minetest.register_craft({
    type = "shapeless",
    output = minetest.get_current_modname()..":highFeOregolith",
    recipe = {
        minetest.get_current_modname()..":regolith",
        minetest.get_current_modname()..":regolith",
        minetest.get_current_modname()..":regolith",
        minetest.get_current_modname()..":regolith"
    },
    replacements = { 
        {minetest.get_current_modname()..":regolith", minetest.get_current_modname()..":lowFeOregolith"},
        {minetest.get_current_modname()..":regolith", minetest.get_current_modname()..":lowFeOregolith"},
        {minetest.get_current_modname()..":regolith", minetest.get_current_modname()..":lowFeOregolith"}
    },
})


minetest.register_craft({
    type = "cooking",
    output = minetest.get_current_modname()..":moldedregolith",
    recipe = minetest.get_current_modname()..":highFeOregolith",
    cooktime = 3,
})




-- Basalt
minetest.register_node(minetest.get_current_modname()..":basalt", {
    description = "basalt",
    tiles = {"moon_moonstone52.png"},
    groups = {cracky=3, stone=1},
    drop = minetest.get_current_modname()..":basalt",
    legacy_mineral = true,
})

-- regolith
minetest.register_node(minetest.get_current_modname()..":regolith", {
    description = "regolith",
    tiles = {"moon_moonstone180.png"},
    groups = {crumbly=1, sand=1, cracky=3},
    drop = minetest.get_current_modname()..":regolith",
    legacy_mineral = true,
})

-- low FeO regolith 
minetest.register_node(minetest.get_current_modname()..":lowFeOregolith", {
    description = "low-FeO regolith ",
    tiles = {"moon_moonstone236.png"},
    groups = {crumbly=1, sand=1, cracky=3},
    drop = minetest.get_current_modname()..":lowFeOregolith",
    legacy_mineral = true,
})

-- high FeO regolith 
minetest.register_node(minetest.get_current_modname()..":highFeOregolith", {
    description = "high-FeO regolith ",
    tiles = {"moon_moonstone92.png"},
    groups = {crumbly=1, sand=1, cracky=3},
    drop = minetest.get_current_modname()..":highFeOregolith",
    legacy_mineral = true,
})

-- molded regolith 
minetest.register_node(minetest.get_current_modname()..":moldedregolith", {
    description = "molded regolith ",
    tiles = {"moon_moldedregolith.png"},
    groups = {cracky=1, stone=1},
    drop = minetest.get_current_modname()..":moldedregolith",
    legacy_mineral = true,
})


for i = 16,244,4 do

    -- all blocks
 --   local name = block_prefix..i
  --  minetest.register_node(name, {
   --     description = "moon_moonstone",
    --    tiles = {"moon_moonstone"..i..".png"},
    --    groups = {cracky=3, stone=1},
    --    drop = block_prefix..i,
    --    legacy_mineral = true,
    --})

    -- Basalt
    if i < 90 then
	    local name = block_prefix..i
	    minetest.register_node(name, {
		    description = "basalt",
		    tiles = {"moon_moonstone"..i..".png"},
		    groups = {cracky=3, stone=1},
		    drop = "default:cobble",
		    --drop = minetest.get_current_modname()..":basalt",
		    legacy_mineral = true,
	    })
    end
    if i > 90 then
	    local name = block_prefix..i
	    minetest.register_node(name, {
		    description = "regolith",
		    tiles = {"moon_moonstone"..i..".png"},
		    groups = {cracky=1, crumbly=1, sand=1},
		    drop = minetest.get_current_modname()..":regolith",
		    legacy_mineral = true,
	    })
    end
    if i == 200 then
	    local name = block_prefix..i
	    minetest.register_node(name, {
		    description = "ice",
		    tiles = {"moon_moonstone"..i..".png"},
		    groups = {cracky=3, stone=1},
		    drop = "default:ice",
		    legacy_mineral = true,
	    })
    end
    if i == 196 then
	    local name = block_prefix..i
	    minetest.register_node(name, {
		    description = "anorthosite",
		    tiles = {"moon_moonstone"..i..".png"},
		    groups = {cracky=1, stone=1},
		    drop = block_prefix..i,
		    legacy_mineral = true,
	    })
    end
    if i == 236 then
	    local name = block_prefix..i
	    minetest.register_node(name, {
            description = "low-FeO regolith ",
            tiles = {"moon_moonstone236.png"},
            groups = {crumbly=1, sand=1, cracky=1},
            drop = minetest.get_current_modname()..":lowFeOregolith",
		    legacy_mineral = true,
	    })
    end
    if i == 92 then
	    local name = block_prefix..i
	    minetest.register_node(name, {
            description = "high-FeO regolith ",
            tiles = {"moon_moonstone92.png"},
            groups = {crumbly=1, sand=1, cracky=1},
            drop = minetest.get_current_modname()..":highFeOregolith",
		    legacy_mineral = true,
	    })
    end

end

local max_brightness = (244-16)/4

for i = 0,max_brightness do
	moonstone[i] = minetest.get_content_id(block_prefix..(16+i*4))
end
moonstone[max_brightness+1] = moonstone[max_brightness]

local albedo_width = 4096
local albedo_height = 2048
local albedo_filename = mypath .. "terrain" .. path_separator .. "albedo4096x2048.dat"
local albedo_radians_to_pixels = albedo_height / math.pi

local f = assert(ie.io.open(albedo_filename, "rb"))
local albedo = f:read("*all")
f:close()
local function get_raw_albedo(column,row)
	if row < 0 then
	   row = 0
	elseif row >= albedo_height then
	   row = albedo_height - 1
	end
	if column < 0 then
	   column = 0
	elseif column >= albedo_width then
	   column = albedo_width - 1
	end
	return albedo:byte(1 + row * albedo_width + column)
end

local function get_interpolated_block(longitude,latitude)
    local row = (half_pi - latitude) * albedo_radians_to_pixels
	if longitude < 0 then longitude = longitude + 2 * math.pi end
    local column = longitude * albedo_radians_to_pixels
    local row0 = math.floor(row)
    local drow = row - row0
    local column0 = math.floor(column)
    local dcolumn = column - column0
    local v00 = get_raw_albedo(column0,row0)
    local v10 = get_raw_albedo(column0+1,row0)
    local v01 = get_raw_albedo(column0,row0+1)
    local v11 = get_raw_albedo(column0+1,row0+1)
    local v0 = v00 * (1-dcolumn) + v10 * dcolumn
    local v1 = v01 * (1-dcolumn) + v11 * dcolumn
    local albedo = v0 * (1-drow) + v1 * drow
	return moonstone[math.floor(albedo * 58 / 255+math.random())]
end

local equaldistance

local orthographic = {


	get_longitude_latitude = function(x,y0,z,farside,allow_oversize)
		local x = x * land_normalize
		local z = z * land_normalize
		local xz2 = x*x + z*z
		if xz2 > 1 then
			if allow_oversize then
				local r = math.sqrt(xz2)
				x = x / r
				z = z / r
			else
				return nil
			end
		end
		local y = math.sqrt(1-xz2)
		local longitude
		if y < 1e-8 and math.abs(x) < 1e-8 then
			longitude = 0
		else
			longitude = math.atan2(x,y)
		end
		if farside then
			longitude = longitude + math.pi
			if longitude > math.pi then
				longitude = longitude - 2 * math.pi
			end
		end
		return longitude, math.asin(z)
	end,

	get_xz_from_longitude_latitude = function(longitude, latitude)
		local z = math.sin(latitude) / land_normalize
		if longitude < -half_pi or longitude > half_pi then
			longitude = longitude - math.pi
		end
		local x = math.cos(latitude) * math.sin(longitude) / land_normalize
		return x,z
	end,

	goto_latitude_longitude_degrees = function(name, latitude, longitude, feature_name)
		local side =  0

        -- 'delete' module
        --minetest.get_player_by_name(name):setpos({x=x,y=y,z=z})
         
		latitude = tonumber(latitude) * math.pi / 180
		longitude = tonumber(longitude)
		if longitude < -90 or longitude > 90 then
			side = 1
		end
		longitude = longitude * math.pi / 180
		if latitude < -half_pi or latitude > half_pi or longitude < -math.pi or longitude > math.pi then
			minetest.chat_send_player(name, "Out of range.")
			return
		end
		local x,z = projection.get_xz_from_longitude_latitude(longitude,latitude)
		local y = height_by_longitude_latitude(longitude, latitude) + offsets[side]			
		if feature_name then
			minetest.chat_send_player(name, "Jumping to "..feature_name..".")
			minetest.log("action", "jumping to "..feature_name.." at "..x.." "..y.." "..z)
		else
			minetest.log("action", "jumping to "..x.." "..y.." "..z)
		end

		--minetest.get_player_by_name(name):setpos({x=x,y=y,z=z})  -- mandando o jogador pra um lugar

		--minetest.get_player_by_name(name):setpos({x=x,y=100,z=x})

		--minetest.get_player_by_name(name):setpos({x=x,y=y+20,z=z})

        --local sec = tonumber(os.clock() + 2); 
        --while (os.clock() < sec) do 
        --end 

        --for i = 50,1,-1 
        --do 
        --minetest.get_player_by_name(name):setpos({x=x,y=y+i,z=z})
        --end

        --minetest.place_schematic({ x=x-2, y=y-2, z=z-2}, minetest.get_modpath("schematics").."/LunarModule1.mts", 0, true, true)
		
    minetest.place_schematic({ x=x-2, y=y-2, z=z-2}, minetest.get_modpath("schematics").."/LunarModule1.mts", 0, true, true)
    minetest.get_player_by_name(name):setpos({x=x,y=y,z=z})


	end,
	
	generate = function(minp, maxp, data, area, vacuum, stone)

		if minp.y > max_height_nodes then
			for pos in area:iterp(minp,maxp) do
				data[pos] = vacuum
			end
		else
			local offset, farside
			if minp.y <= farside_below then
				-- we assume the chunk we're generating never spans between far to nearside
				offset = offsets[1]
				farside = true
			else
				offset = offsets[0]
				farside = false
			end
			for x = minp.x,maxp.x do
				for z = minp.z,maxp.z do
					local longitude,latitude = projection.get_longitude_latitude(x,0,z,farside,teleport and projection==equaldistance)
					if not longitude then
						for y = minp.y,maxp.y do
							data[area:index(x, y, z)] = vacuum
						end
					else
						local f = math.floor(height_by_longitude_latitude(longitude, latitude) + offset)
						local block
						if albedo then
							block = get_interpolated_block(longitude,latitude)
						else
							block = stone
						end
						for y = minp.y,maxp.y do
							if y < offset - thickness or y > f then 
								data[area:index(x, y, z)] = vacuum
							elseif y <= f then
								data[area:index(x, y, z)] = block
							end
						end
					end
				end
			end
		end

	end
}

equaldistance = {
	get_longitude_latitude = function(x,y0,z,farside,allow_oversize)
		local x = x * land_normalize
		local z = z * land_normalize
		local xz2 = x*x + z*z

		if xz2 > 2 or (xz2 > 1 and not allow_oversize) then
			return nil
		end
		
		local xz = math.sqrt(xz2)
		
		if xz < 1e-8 then
			if farside then
				return math.pi,0
			else
				return 0,0
			end
		end

		local adjustment = math.sin(xz*half_pi)/xz
		x = x * adjustment
		z = z * adjustment

		local y = math.sqrt(1-x*x-z*z)

		local longitude = math.atan2(x,y)
		if farside then
			longitude = longitude + math.pi
			if longitude > math.pi then
				longitude = longitude - 2 * math.pi
			end
		end

		if xz > 1 then
			if longitude >= 0 then 
				longitude = math.pi - longitude
			else 
				longitude = -math.pi - longitude
			end
		end
		
		return longitude, math.asin(z)
	end,
	
	get_xz_from_longitude_latitude = function(longitude, latitude)
		local z = math.sin(latitude)
		if longitude < -half_pi or longitude > half_pi then
			longitude = longitude - math.pi
		end
		local x = math.cos(latitude) * math.sin(longitude)
		
		local xz = math.sqrt(x*x + z*z)
		
		if xz < 1e-8 then
			return x/land_normalize,z/land_normalize
		end
		
		local adjustment = math.asin(xz)/half_pi/xz
		
		return x * adjustment / land_normalize, z * adjustment / land_normalize
	end,

	goto_latitude_longitude_degrees = orthographic.goto_latitude_longitude_degrees,
	
	generate = orthographic.generate
}

local sphere = {
	get_longitude_latitude = function(x,y,z,farside)
		local r = math.sqrt(x*x+y*y+z*z)

		if r < 1e-8 then
			return 0,0
		end

		local latitude = math.asin(z/r)
		local longitude = math.atan2(x,y)
		
		return longitude, latitude
	end,

	get_block = function(x,y,z,vacuum,stone)
		local r = math.sqrt(x*x+y*y+z*z)
		
		if r < inner_radius_nodes - 5 then
			return stone
		elseif outer_radius_nodes < r then
			return vacuum
		end
		
		x = x / r
		y = y / r
		z = z / r
		
		local latitude = math.asin(z)
		local longitude = math.atan2(x,y)

		if r <= inner_radius_nodes + height_by_longitude_latitude(longitude, latitude) then
			if albedo then
				return get_interpolated_block(longitude,latitude)
			else
				return stone
			end
		else
			return vacuum
		end
	end,


	generate = function(minp, maxp, data, area, vacuum, stone)
		local block_radius = vector.distance(minp, maxp) / 2
		local r = vector.length(vector.multiply(vector.add(minp,maxp), 0.5))

		if r + block_radius < inner_radius_nodes then
			for pos in area:iterp(minp,maxp) do
				data[pos] = stone
			end
		elseif outer_radius_nodes < r - block_radius then
			for pos in area:iterp(minp,maxp) do
				data[pos] = vacuum
			end
		else
			for y = minp.y,maxp.y do
				for x = minp.x,maxp.x do
					for z = minp.z,maxp.z do
						data[area:index(x,y,z)] = projection.get_block(x,y,z,vacuum,stone)
					end
				end
			end
		end		
	end,
	
	goto_latitude_longitude_degrees = function(name, latitude, longitude, feature_name)
		latitude = latitude * math.pi / 180
		longitude = longitude * math.pi / 180
		local x = math.cos(latitude) * math.sin(longitude)
		local y = math.cos(latitude) * math.cos(longitude)
		local z = math.sin(latitude)
		local r = inner_radius_nodes + height_by_longitude_latitude(longitude, latitude)
		x = x * r
		y = y * r
		z = z * r
		local player = minetest.get_player_by_name(name)
		if y < 0 then 
			y = y - 2
		end

		if feature_name then
			minetest.chat_send_player(name, "Jumping to "..feature_name..".")
			minetest.log("action", "jumping to "..feature_name.." at "..x.." "..y.." "..z)
		else
			minetest.chat_send_player(name, "Jumping to coordinates.")
			minetest.log("action", "jumping to "..x.." "..y.." "..z)
		end
		player:setpos({x=x,y=y,z=z})
	end
}

minetest.log("action", "Moon projection mode: "..projection_mode)

if projection_mode == "sphere" then
	projection = sphere
	
else
	if projection_mode == "equaldistance" then
		projection = equaldistance
	else 
		projection = orthographic
	end
	
	offsets[0] = -height_by_longitude_latitude(0,0)
	offsets[1] = farside_below - max_height_nodes
end

minetest.register_on_generated(function(minp, maxp, seed)
	local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
	local data = vm:get_data()
	local area = VoxelArea:new{MinEdge=emin, MaxEdge=emax}



	--projection.generate(minp, maxp, data, area,  minetest.get_content_id("air"),
	projection.generate(minp, maxp, data, area,  minetest.get_content_id("vacuum:vacuum"),
		minetest.get_content_id("default:stone"))


    -- Shackleton base: /goto Shackleton

    --minetest.place_schematic({ x = 13, y = -5066, z = -11529}, minetest.get_modpath("schematics").."/habitat1l.mts", 180, true, true)
    --minetest.place_schematic({ x = -13, y = -5071, z = -11516}, minetest.get_modpath("schematics").."/habitat1l.mts", nil, true, true)
    --minetest.place_schematic({ x = 14, y = -5070, z = -11515}, minetest.get_modpath("schematics").."/habitat1l.mts", 180, true, true)

    -- size 11 6 7
    --minetest.place_schematic({ x = -6.2, y = -5070, z = -11489 }, minetest.get_modpath("schematics").."/void.mts", nil, true, true)
    --minetest.place_schematic({ x = -6.2, y = -5071, z = -11489 }, minetest.get_modpath("schematics").."/habitat21a.mts", nil, true, true)

    -- Marius abandon base:
    --minetest.place_schematic({ x = -6429,  1759, y = -11, z = 1759}, minetest.get_modpath("schematics").."/ruina1.mts", nil, true, true)

--    minetest.place_schematic({ x = -4, y = 0, z = -23 }, minetest.get_modpath("schematics").."/habitat2d.mts", 180, true, true)
--    minetest.place_schematic({ x = -25, y = 0, z = -6 }, minetest.get_modpath("schematics").."/habitat3v.mts", nil, true, true)
--    minetest.place_schematic({ x = -21, y = 0, z = -20 }, minetest.get_modpath("schematics").."/habitat4.mts", 180, true, true)
    --minetest.set_node({x=6, y=1, z=-1}, {name="vacuum:vacuum"})

    --minetest.register_alias("mapgen_ice", "default:ice")
    
--    =minetest.set_node({x=9, y=5071, z=-11487}, {name="air"})


    -- Tycho Base
    minetest.place_schematic({ x = -1762, y = -26, z = -8522}, minetest.get_modpath("schematics").."/habitat21a.mts", 270, true, true)
    --minetest.place_schematic({ x = -1775, y = -26, z = -8522}, minetest.get_modpath("schematics").."/habitat21a.mts", 90, true, true)
    --minetest.place_schematic({ x = -1785, y = -36, z = -8532}, minetest.get_modpath("schematics").."/signA.mts", 90, true, true)
    --minetest.place_schematic({ x = -1795, y = -56, z = -8572}, minetest.get_modpath("schematics").."/signA.mts", 90, true, true)

    minetest.place_schematic({ x = -1799, y = -24, z = -8505}, minetest.get_modpath("schematics").."/LunarModule1.mts", 0, true, true)

    -- Pictet A Base
    minetest.place_schematic({ x = -1192, y = -14, z = -8652}, minetest.get_modpath("schematics").."/habitat21a.mts", 270, true, true)


    --[[ air inside    
    for y=-24,-22 do
        minetest.set_node({x=-1772, y=y, z=-8518}, {name="air"})
        minetest.set_node({x=-1771, y=y, z=-8518}, {name="air"})
        minetest.set_node({x=-1770, y=y, z=-8518}, {name="air"})

        minetest.set_node({x=-1772, y=y, z=-8519}, {name="air"})
        minetest.set_node({x=-1771, y=y, z=-8519}, {name="air"})
        minetest.set_node({x=-1770, y=y, z=-8519}, {name="air"})

        minetest.set_node({x=-1772, y=y, z=-8520}, {name="air"})
        minetest.set_node({x=-1771, y=y, z=-8520}, {name="air"})
        minetest.set_node({x=-1770, y=y, z=-8520}, {name="air"})

    end ]]--
    
	vm:set_data(data)
    vm:set_lighting({day=15,night=1})
	vm:calc_lighting()
	vm:update_liquids()
	vm:write_to_map()
end)

		
local function find_feature(name)
    local lower_name = name:lower():gsub("[^A-Za-z0-9]", "")
	local name_length = lower_name:len()
    local f = assert(ie.io.open(mypath .. "features.txt", "r"))
	local partial_fullname,partial_lat,partial_lon,partial_size
	partial_lat = nil
    while true do
	    local line = f:read()
	    if not line then break end
	    local key,fullname,lat,lon,size = line:match("^([^|]+)%|([^|]+)%|([^|]+)%|([^|]+)%|([^|]+)")
	    if key == lower_name then
		   f:close()
		   return tonumber(lat),tonumber(lon),fullname
		end
		if not partial_lat and key:sub(1,name_length) == lower_name then
			partial_fullname,partial_lat,partial_lon,partial_size = fullname,lat,lon,size
		end
    end
	f:close()
	if partial_lat then
		return tonumber(partial_lat),tonumber(partial_lon),partial_fullname
	else
		return nil
	end
end

minetest.register_chatcommand("goto",
	{params="<latitude> <longitude>  or  <feature name>" ,
	description="Go to location on moon. Negative latitudes are south and negative longitudes are west.",
	func = function(name, args)
		if args ~= "" then
			local side = 0
			local latitude, longitude = args:match("^([-0-9.]+) ([-0-9.]+)")
			local feature_name = nil
			if not longitude then
				latitude,longitude,feature_name = find_feature(args)
				if not latitude then
					minetest.chat_send_player(name, "Cannot find object "..args)
					return
				end
			end
			projection.goto_latitude_longitude_degrees(name,latitude,longitude,feature_name)
		end
	end})

minetest.register_chatcommand("where",
	{params="" ,
	description="Get latitude and longitude of current position on moon.",
	func = function(name, args)
	        local pos = minetest.get_player_by_name(name):getpos()
			local farside = pos.y < farside_below + thickness -- irrelevant if sphere
            local longitude,latitude = projection.get_longitude_latitude(pos.x, pos.y, pos.z, farside)
			if longitude then
                minetest.chat_send_player(name, "Latitude: "..(latitude*180/math.pi)..", longitude: "..(longitude*180/math.pi))
			else
                minetest.chat_send_player(name, "Out of range.")
			end
	end})

minetest.register_on_joinplayer(function(player)
	--local override = player:get_physics_override()
	--override['gravity'] = 0.167
	--override['jump'] = 6
	--player:set_physics_override(override)
    

	--minetest.register_on_respawnplayer({x=4,y=-5065,z=-11523})

	 -- texture order: up,down,east,west,south,north
	if sky == "black" then
		player:set_sky({r=0,g=0,b=0},'plain')
	elseif sky == "fancy" then
		player:set_sky({r=0,g=0,b=0},'skybox',
			{'sky_pos_y.png','sky_neg_y.png','sky_neg_z.png','sky_pos_z.png','sky_neg_x.png','sky_pos_x.png'},false)
	end
	local name = player:get_player_name()
	local p = minetest.get_player_privs(name)
	p['fly'] = true
	minetest.set_player_privs(name, p)

    

end)



minetest.register_on_newplayer(function(player)
    --player:setpos({x=-1753,y=-25,z=-8522})
    player:setpos({x=-1797,y=-23,z=-8503})
end)


if projection == sphere then
	local default_location = function(player) 
		--player:setpos({x=0, y=inner_radius_nodes+height_by_longitude_latitude(0,0), z=0})
        player:setpos({x=-2848,y=-25,z=-14301})
	end

	minetest.register_on_newplayer(default_location)
	minetest.register_on_respawnplayer(default_location)
end

if teleport and projection ~= sphere then
	minetest.register_globalstep(function(dtime)
		local players = minetest.get_connected_players()
		for i = 1,#players do
			local pos = players[i]:getpos()
			local r = math.hypot(pos.x, pos.z)
			if r > radius_nodes then
				local farside = pos.y <= farside_below
				local longitude,latitude = 
					projection.get_longitude_latitude(
					pos.x,pos.y,pos.z,farside,true)
				if longitude then
					local name = players[i]:get_player_name()
					minetest.chat_send_player(name, 
						"Teleporting to other side, latitude: "..(latitude*180/math.pi)..", longitude: "..(longitude*180/math.pi))
					projection.goto_latitude_longitude_degrees(name, 
						latitude * 180 / math.pi, longitude * 180 / math.pi)
				end
			end
		end
	end)
end



-- Lunar Module command

minetest.register_node(minetest.get_current_modname()..":screen", {
    description = "moon_screen",
    tiles = {"moon_screen2.png",
            "moon_screen2.png",
            "moon_screen2.png",
            "moon_screen.png",
            "moon_screen2.png",
            "moon_screen2.png",
                },
    groups = {cracky = 1},
    after_place_node = function(pos, placer)
        -- This function is run when the chest node is placed.
        -- The following code sets the formspec for chest.
        -- Meta is a way of storing data onto a node.

        local meta = minetest.get_meta(pos)
        meta:set_string("formspec",
            "formspec_version[4]" ..
                "size[8,5]" ..
                "label[0.375,0.5;Autopilot Control]" ..
                "label[0.375,1;Enter a destination:]" ..
                "button[2.9,3.3;2,1;botao;Ok]" ..
                "field[0.4,1.5;6.8,0.6;destination;;${text}]" ..
                "label[0.4,2.5;Ex.: Sarton, Pythagoras, Tycho, etc.]"
    )
    end,
    on_receive_fields = function(pos, formname, fields, player)
        if fields.quit then
            return
        end
        local pname = player:get_player_name()
        minetest.chat_send_all(pname .. " choose " .. fields.destination)
        print(fields.x)
        local side = 0
        local latitude, longitude = fields.destination:match("^([-0-9.]+) ([-0-9.]+)")
        local feature_name = nil
        latitude,longitude,feature_name = find_feature(fields.destination)
        if not latitude then
            minetest.chat_send_player(pname, "Cannot find object ".. fields.destination)
        end
        projection.goto_latitude_longitude_degrees(pname,latitude,longitude,feature_name)
        --projection.goto_latitude_longitude_degrees(pname,latitude,longitude,feature_name)
    end
})








--[[

 +3 +3 +3

function default.get_furnace_active_formspec(fuel_percent, item_percent)
	return formspec_version[4]
size[8,6]
position[0.5,0.5]
label[0.375,0.5;Autopilot Control]
label[0.375,1.0;Choose a destination:]
button[0.375,1.5;6,0.5;test1;Tycho, LQ26, Near Side]
button[0.375,2;6,0.5;test2;Sarton, LQ02, Far Side]
button[0.375,2.5;6,0.5;test3;Pythagoras, LQ03, Near Side]
button[0.375,3;6,0.5;test4;Montes Recti, LQ04, Near Side]
]]--



