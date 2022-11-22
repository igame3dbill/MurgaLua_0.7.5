#! /usr/bin/env lua

require("lfann")

-- Create a shortcut neural network to serve as base to the cascade training
local net = fann.Net.create_shortcut{2, 1}

-- Train the net from a file
net:set_train_stop_function(fann.STOPFUNC_MSE)
net:cascade_train_on_file("train.data", 10, 1, 0.0001)

-- Save the net to a file for a latter execution 
net:save("xor.net");
