#! /usr/bin/env lua

require("lfann")

function eq(x, y)
	return math.abs(x - y) < 0.00001
end

local net = fann.Net.create_shortcut{2, 1}
net:set_callback() -- Disable logging

net:set_cascade_candidate_change_fraction(0.1)
assert(eq(net:get_cascade_candidate_change_fraction(), 0.1))

net:set_cascade_candidate_stagnation_epochs(5)
assert(net:get_cascade_candidate_stagnation_epochs(5) == 5)

net:set_cascade_output_change_fraction(0.2)
assert(eq(net:get_cascade_output_change_fraction(), 0.2))

net:set_cascade_output_stagnation_epochs(10)
assert(net:get_cascade_output_stagnation_epochs(10) == 10)

net:set_cascade_weight_multiplier(0.359)
assert(eq(net:get_cascade_weight_multiplier(), 0.359))

net:set_cascade_candidate_limit(800)
assert(eq(net:get_cascade_candidate_limit(), 800))

net:set_cascade_max_cand_epochs(100)
assert(net:get_cascade_max_cand_epochs() == 100)

net:set_cascade_max_out_epochs(120)
assert(net:get_cascade_max_out_epochs() == 120)

net:set_cascade_activation_functions{fann.SIGMOID, fann.GAUSSIAN}
local funcs = net:get_cascade_activation_functions()
assert(funcs[1] == fann.SIGMOID)
assert(funcs[2] == fann.GAUSSIAN)
assert(#funcs == net:get_cascade_activation_functions_count())

net:set_cascade_num_candidate_groups(3)
assert(net:get_cascade_num_candidate_groups(), 3)

net:set_cascade_activation_steepnesses{0.5, 0.25, 0.75}
local steps = net:get_cascade_activation_steepnesses()
assert(eq(steps[1], 0.5), steps[1])
assert(eq(steps[2], 0.25))
assert(eq(steps[3], 0.75))
assert(#steps == net:get_cascade_activation_steepnesses_count())

net:cascade_train_on_file("train.data", 10, 1, 0.1)

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
