--[[
	This example classifies a RPG character in classes, according to its
	attributes (strength, dexterity, constitution, intelligence, wisdom and
		charisma).
--]]

local net = fann.Net.create_standard{6, 18, 18, 9}

-- Configure the activation function
net:set_activation_function_hidden(fann.SIGMOID_SYMMETRIC)
net:set_activation_function_output(fann.SIGMOID_SYMMETRIC)

-- Configure other parameters
net:set_training_algorithm(fann.TRAIN_RPROP)

-- Train the net from a file
net:train_on_file("train.data", 100000, 50, 0.001)

-- Save the net to a file for a latter execution 
net:save("rpg.net");
