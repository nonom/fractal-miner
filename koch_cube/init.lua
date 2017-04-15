-- Import Helpers
dofile(minetest.get_modpath("fractal_helpers").."/helpers.lua")

-- Parameters
local YWATER = -31000
local fractal_iteration = 4 -- min value 0, max value 10
local DEBUG = true
local fractal_block = minetest.get_content_id("default:desert_stone")

-- Set mapgen parameters
local fractal_size = math.pow(3, fractal_iteration)
local fractal_origin = math.floor(0 - fractal_size / 2)
minetest.set_mapgen_params({mgname = "singlenode", flags = "nolight", water_level = YWATER})

if DEBUG then
  print ("[koch_cube] origin: "..fractal_origin)
  print ("[koch_cube] size: "..fractal_size)
end

-- Localise data buffer
local dbuf = {}


-- ####################################################### --
-- KOCH CUBE FUNCTIONS

-- Tests if a point is in the Koch Cube
function koch_test(d, x, y, z)
  local d3 = d / 3

  -- test if coords are outside of the set
  local xOut = (x >= d3) and (x < 2 * d3)
  local yOut = (y >= d3) and (y < 2 * d3)
  local zOut = (z >= d3) and (z < 2 * d3)
  local score = (xOut and 1 or 0) + (yOut and 1 or 0) + (zOut and 1 or 0)

  -- return false unless only one value is outside of the range
  if score ~= 1 then
    return false
  elseif d3 >= 3 then
    return koch_test(d3, x % d3, y % d3, z % d3)
  else
    return true
  end
end


-- ####################################################### --
-- Minetest hooks

-- Chunk generation function
minetest.register_on_generated(function(minp, maxp, seed)
  local t0 = os.clock()

  local vm, emin, emax = minetest.get_mapgen_object("voxelmanip")
  local area = VoxelArea:new{MinEdge = emin, MaxEdge = emax}
  local data = vm:get_data(dbuf)

  if outside_region(fractal_origin, fractal_size, minp, maxp) then
    debug_message(DEBUG, "[koch_cube] Skipping "..region_text(minp, maxp))
  else
    debug_message(DEBUG, "[koch_cube] Generating blocks in "..region_text(minp, maxp))
    
    -- Iterate over fixed region for the koch cube
    local minv, maxv = get_fractal_region(minp, maxp, fractal_origin, fractal_size - 1)

    for z = minv.z, maxv.z do
      for y = minv.y, maxv.y do
        local vi = area:index(minv.x, y, z)
        for x = minv.x, maxv.x do
          if koch_test(fractal_size, x - fractal_origin, y - fractal_origin, z - fractal_origin) then
            data[vi] = fractal_block
          end
          vi = vi + 1
        end
      end
    end
  end
  
  vm:set_data(data)
  vm:calc_lighting(minp, maxp)
  vm:write_to_map(data)

  if DEBUG then
    local chugent = math.ceil((os.clock() - t0) * 1000)
    print ("[koch_cube] "..chugent.." ms")
  end
end)
  
-- Player spawn point
minetest.register_on_newplayer(function(player)
  local elevation = fractal_origin + fractal_size + 1
  player:setpos({x=0, y=elevation, z=fractal_origin})
end)