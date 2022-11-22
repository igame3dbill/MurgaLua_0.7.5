#! /usr/bin/env lua

require("lfann")

function eq(x, y)
	return math.abs(x - y) < 0.00001
end

local vals = {-1, 10, 20, 0, -10, 5, -1, 1, 30}

local function create_callback()
	return unpack(vals)
end

local data = fann.Data.create_from_callback(1, 4, 5, create_callback)

local rmin, rmax = data:get_bounds()
assert( eq(rmin, -10) and eq(rmax, 30) )

local rmin, rmax = data:get_bounds_input()
assert( eq(rmin, -1) and eq(rmax, 20) )

local rmin, rmax = data:get_bounds_output()
assert( eq(rmin, -10) and eq(rmax, 30) )

data:scale(-10, 30)

local rmin, rmax = data:get_bounds()
assert( eq(rmin, -10) and eq(rmax, 30) )

for i, j in ipairs(data:get_row(1)) do
	assert( eq(j, vals[i]) )
end

data:scale_input(-1, 1)

local rmin, rmax = data:get_bounds()
assert( eq(rmin, -10) and eq(rmax, 30) )

local row = data:get_row(1)
assert( eq(row[3], 1) )
assert( not eq(row[5], -1) )
assert( not eq(row[9], 1) )

data:scale(-1, 1)

local rmin, rmax = data:get_bounds()
assert( eq(rmin, -1) and eq(rmax, 1) )

local row = data:get_row(1)
assert( not eq(row[3], 1) )
assert( eq(row[5], -1) )
assert( eq(row[9], 1) )

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
