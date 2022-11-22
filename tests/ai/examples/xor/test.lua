#! /usr/bin/env lua

-- load the library
require("lfann")

-- load the network from the exported file
local net = fann.Net.create_from_file("xor.net")

local n_input, n_output = 2, 1
local input, output = {}
local write, sf = io.write, string.format

-- test using the stdio (enter q to quit)
while true do
	local cont = true
	
	-- input
	for i = 1, n_input do
		local aux = io.read("*n")
		
		if not aux then
			cont = false
			break
		end
		
		input[i] = aux
	end
	
	if not cont then break end
	
	-- run the network
	output = net:run(input)
	
	-- output
	for i = 1, n_output do
		if i >  1 then write(" ") end
		write( sf("%.6f", output[i]) )
	end
	
	write("\n")
end
