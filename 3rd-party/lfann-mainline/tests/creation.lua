#! /usr/bin/env lua

require("lfann")

function eq(x, y)
	return math.abs(x - y) < 0.00001
end

for i = 1, 300 do
	local net = fann.Net.create_standard({2, 3, 2})
	
	local layers = net:get_layer_array()
	assert(#layers == 3)
	assert(layers[1] == 2)
	assert(layers[2] == 3)
	assert(layers[3] == 2)
	
	local layers = net:get_bias_array()
	assert(#layers == 3)
	assert(layers[1] == 1)
	assert(layers[2] == 1)
	assert(layers[3] == 0)
	
	net:set_weight(2, 6, 0.67)
	net:set_weight(3, 6, 0.89)
	
	local conn = net:get_connection_array()
	assert(#conn == 7)
	assert(eq(conn[2][6], 0.67))
	assert(eq(conn[3][6], 0.89))
	
	net = fann.Net.create_sparse(0.5, {2, 3, 2})
	local layers = net:get_layer_array()
	assert(#layers == 3)
	assert(layers[1] == 2)
	assert(layers[2] == 3)
	assert(layers[3] == 2)
	
	net = fann.Net.create_shortcut({2, 3, 2})
	local layers = net:get_layer_array()
	assert(#layers == 3)
	assert(layers[1] == 2)
	assert(layers[2] == 3)
	assert(layers[3] == 2)
	
	net = fann.Net.create_from_file("xor.net")
	local layers = net:get_layer_array()
	assert(#layers == 3)
	assert(layers[1] == 2)
	assert(layers[2] == 3)
	assert(layers[3] == 1)
	
	collectgarbage()
end

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
