#! /usr/bin/env lua

require("lfann")

function eq(x, y)
	return math.abs(x - y) < 0.00001
end

local neurons = {4, 2, 2, 5, 4}
local net = fann.Net.create_standard(neurons)
assert(eq(net:get_connection_rate(), 1))

net:set_learning_rate(0.65)
assert(eq(net:get_learning_rate(), 0.65))

net:set_bit_fail_limit(2)
assert(eq(net:get_bit_fail_limit(), 2))

local n = #neurons - 1
for i, j in pairs(neurons) do n = n + j end
assert(net:get_total_neurons() == n)

net:set_activation_steepness(0.345, 2, 1)
assert(eq(net:get_activation_steepness(2, 1), 0.345))

net:set_activation_steepness_hidden(0.32)
assert(eq(net:get_activation_steepness(2, 1), 0.32))
assert(eq(net:get_activation_steepness(3, 2), 0.32))

net:set_activation_steepness_output(0.8)
assert(eq(net:get_activation_steepness(5, 1), 0.8))
assert(eq(net:get_activation_steepness(5, 4), 0.8))

local n = 0
for i = 1, #neurons - 1 do
	n = n + neurons[i] * neurons[i + 1] + neurons[i + 1]
end
assert(net:get_total_connections() == n)

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
