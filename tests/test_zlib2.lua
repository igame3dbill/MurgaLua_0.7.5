
-- local zlib = require 'zlib'

local data = 'abcde'
local cdata = zlib.compress(data)
local udata = zlib.decompress(cdata)

print('udata=['..udata..']')

local z = zlib.inflate(cdata)
print('z', z)
for i = 1, 5 do
	print(i, z:read(1))
end
z:close()

i = io.open('../LICENSE-GPL', 'rb') org = i:read('*a') i:close()
i = io.open('LICENSE-GPL.gz', 'rb')
dup = ''

o = io.open('txt.out', 'wb')
z = zlib.inflate(i)
print('z = ', z)
repeat
	local l = z:read(1024)
	if not l then
		break
	end
    dup = dup .. l
	o:write(l)
until false
i:close()
o:close()
z:close()

print('result:', (org == dup), org:len(), dup:len())

i = io.open('LICENSE-GPL.gz', 'rb')
o = io.open('txt.lines.out', 'w')
cpeek = 0
ccon = 0
z = zlib.inflate({
    peek = function(self, hint)
        local d = i:read(hint)
        if (d ~= nil) then
            i:seek('cur', -d:len())
            cpeek = cpeek + d:len()
        end
        --print('called peek with', hint, 'got', d and d:len())
        return d
    end,
    read = function(self, consume)
        --print('called read with', consume)
        ccon = ccon + consume
        i:read(consume)
    end
})
print('z = ', z)
for line in z:lines() do
    o:write(line, '\n')
end
i:close()
o:close()
z:close()

print('stats:', cpeek, ccon)
print('z = ', z)

i = io.open('../LICENSE-GPL', 'r')
o = io.open('txt-zlib.gz', 'wb')
z = zlib.deflate(o, nil, nil, 15 + 16)
for line in i:lines() do
	z:write(line, '\n')
end
z:flush('finish')
z:close()
o:close()
i:close()
