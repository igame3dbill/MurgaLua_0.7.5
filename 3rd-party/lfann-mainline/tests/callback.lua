#! /usr/bin/env lua

require("lfann")

function eq(x, y)
	return math.abs(x - y) < 0.00001
end

local num = 1

function callback(ud, nData, nIn, nOut)
	assert(ud == "Hi!")
	return 1 * nData, 2 * nData, 3 * nData, 4 * nData, 5 * nData, 6 * nData, 7 * nData
end

local data = fann.Data.create_from_callback(num, 2, 5, callback, "Hi!")

for i = 1, num do
	local row = data:get_row(i)

	for j, k in ipairs(row) do
		assert(k == i * j) 
	end
end

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
