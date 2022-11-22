
local sys = require("sys")


local win32 = sys.win32

if not win32 then
	error"Windows 9x/NT required"
end


print"-- Mailslot"
do
	local fd = sys.handle()
	if not fd:mailslot([[\\.\mailslot\luasys]]) then
		error(errorMessage)
	end
	print(fd:mailslot_info())
	fd:close()
	print"OK"
end


print"-- Registry"
do
	local r = win32.registry()
	if not r:open("HKEY_LOCAL_MACHINE",
			[[Software\Microsoft\Windows\CurrentVersion\Setup]]) then
		error(errorMesage)
	end
	for i, k, v in r:values() do
		sys.stdout:write(k, ' = "', v, '"\n')
	end
	if r:set("TEST_SET", 666) then
		error("'Access denied.' expected")
	end
	r:close()
	print("OK")
end


