local m = 400000
local net = fann.Net.create_from_file("xor.net")

for i = 1, m do
	local out = net:run{i % 1000, i > (m / 2) and 1 or 0}
	assert(out[1] >= -1 and out[1] <= 1)
end

print("End.")

if arg[1] == "mem" then
	io.read("*n")
end
