#! /usr/bin/env lua

require("lfann")

local data = fann.Data.read_from_file("train.data")
assert(data:lenght() == 4)
local data2 = data:subset(0, data:lenght() - 1)
assert(data2:lenght() == 3)
local data3 = data:merge(data2)
assert(data3:lenght() == data:lenght() + data2:lenght())
assert(data:num_input() == 2)
assert(data:num_output() == 1)
assert(data2:num_input() == 2)
assert(data2:num_output() == 1)
assert(data3:num_input() == 2)
assert(data3:num_output() == 1)

local row = data:get_row(1)
assert(row[1] == 1 and row[2] == 1 and row[3] == -1)
row = data:get_row(2)
assert(row[1] == 1 and row[2] == 0 and row[3] == 1)
row = data:get_row(3)
assert(row[1] == 0 and row[2] == 1 and row[3] == 1)
row = data:get_row(4)
assert(row[1] == 0 and row[2] == 0 and row[3] == -1)

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
