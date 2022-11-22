require"inilazy"
local c1 = os.clock()

local tt = assert (inilazy.get"big.ini")
assert (inilazy.set(tt,"big_ini.ini"))
print('done: ',os.clock()-c1,' s')

for k,v in pairs(tt['Subscription']['url']) do
	print(k)
end




