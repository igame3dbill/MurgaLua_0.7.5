#! /usr/bin/env lua

require("lfann")

-- Load the network from a file
local net = fann.Net.create_from_file("xor.net")

-- Test using command line args
local input = {arg[1] and tonumber(arg[1]) or 1, arg[1] and tonumber(arg[2]) or 0}
local output = net:run(input)

for i, j in ipairs(output) do
	print(j)
end
