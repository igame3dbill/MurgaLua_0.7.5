#! /usr/bin/env lua

require("lfann")

-- Create a Neural Network with tree layers, with 2, 3 and 1 neurons, plus one
-- bias neuron per layer
local net = fann.Net.create_standard{2, 3, 1}

-- Configure the activation function
net:set_activation_function_hidden(fann.GAUSSIAN_SYMMETRIC)
net:set_activation_function_output(fann.GAUSSIAN_SYMMETRIC)

-- Train the net from a file
net:train_on_file("train.data", 1000, 10, 0.0001)

-- Save the net to a file for a latter execution 
net:save("xor.net");
