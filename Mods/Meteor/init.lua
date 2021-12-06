--[[
The MIT License (MIT)

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

-- based on 'raining_death' mod 




local function spawn_tnt_action (pos, node, active_object_count, active_object_count_wider)
    if on_break then
        return
    end

    local spawn_pos = {
            x = pos.x,
            y = pos.y, 
            z = pos.z,
        }

    --if math.random(math.max(1, 12000000)) == 1 then
    -- 1/12000000 = <1 por hr
    --if math.random(math.max(1, 2000000)) == 1 then = <1 por hr
    --if math.random(math.max(1, 500000)) == 1 then = ~6 por 20min
    --if math.random(math.max(1, 15000)) == 1 then = dangerous for life
    if math.random(math.max(1, 1500000)) == 1 then 
        minetest.add_node(spawn_pos, {
            name="tnt:tnt_burning"
        })
    end
end

minetest.register_abm({
    label = "Rain TNT",
    nodenames = {"vacuum:vacuum"},
    interval = 1,
    chance = 1000,
    action = spawn_tnt_action,
})


