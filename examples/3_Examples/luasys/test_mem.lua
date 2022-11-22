#!/usr/local/bin/lua

local sys = require("sys")

local mem = sys.mem


print"-- Plain array"
do
	local arr = assert(mem.pointer(8))  -- default type is "char"

	for i = 0, 7 do arr[i] = 65 + i end
	assert("ABCDEFGH" == mem.tostring(arr, 8))

	local s = "zstring"
	arr[0] = s
	if s ~= mem.tostring(arr, #s) then
		error"mem.tostring"
	end
	print"OK"
end


print"-- Bits String"
do
	local bits = assert(mem.pointer(8):type"bitstring")
	bits[7] = true

	local intp = assert(mem.pointer():type"int")
	bits(0, intp)  -- set integer pointer to bitstring

	assert(intp[0] == 128)
	print"OK"
end


if (murgaLua.getHostOsName() == "macos") then
	print ("File Map test doesn't work on MacOS yet")
else
	print"-- File Map"
	local filename = "fmap"
	local f = assert(sys.handle():open(filename, "rw", 0x180, "creat"))

	local s1, s2 = "File ", "mapped."
	f:seek(#s1)
	f:write(s2)
	do
		local p = assert(mem.pointer())
		assert(p:map(f, "w"))
		p[0] = s1
		p:free()
	end
	f:seek(0)
	assert(f:read() == s1 .. s2)

	f:close()
	os.remove(filename)
	print"OK"
end


print"-- Buffer"
do
	local buf = assert(mem.pointer():alloc())
	local s = "append string to buffer"
	buf:write(s)
	assert(string.len(s) == buf:seek() and s == buf:getstring())
	buf:close()
	print"OK"
end


print"-- Buffer I/O Streams"
do
	local stream = {
		data = "characters\nnewline\nend";
		read = function(self)
			local data = self.data
			self.data = nil
			return data
		end;
		write = function(self, data)
			self.data = data
			return true
		end
	}
	local buf = assert(mem.pointer():alloc())

	buf:input(stream)
	do
		local stream_data, data = stream.data
		while true do
			local line = buf:read"*l"
			if not line then break end
			if data then
				data = data .. '\n' .. line
			else
				data = line
			end
		end
		assert(data == stream_data)
	end

	buf:output(stream)
	local s = "auto-flush"
	buf:write(s)
	buf:close()  -- flush & free
	assert(stream.data == s)
	print"OK"
end


