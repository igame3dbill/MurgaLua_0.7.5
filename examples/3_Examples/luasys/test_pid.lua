
local fdi, fdo = sys.handle(), sys.handle()
assert(fdi:pipe(fdo))
	
-- Timer
local timer = murgaLua.createFltkTimer()

function on_timer()
	result, err = fdi:read()

	if (err == nil and result ~= nil) then
		print("Subprocess output: ", result)
	io.flush()
		timer:doWait(0.5)
	else
		print("Process has ended?")
		io.flush()
		-- ? Second test ?
	end
end

timer:callback(on_timer)

-- Subprocess
local sleep_msec = 1000
local subprocess = [[
	murgaLua.sleep(]] .. sleep_msec .. [[)
	sys.stdout:write"Step 1."
	murgaLua.sleep(]] .. sleep_msec .. [[)
	sys.stdout:write"Step 2."
	murgaLua.sleep(]] .. sleep_msec .. [[)
	sys.stdout:write"Step 3."
	murgaLua.sleep(]] .. sleep_msec .. [[)
	sys.stdout:write"Step 4."
	murgaLua.sleep(]] .. sleep_msec .. [[)
	sys.stdout:write"Exited normally."
]]
print("Subprocess sleep: ", sleep_msec)
io.flush()

local args = {"-e", subprocess}
if not sys.spawn(murgaLua_ExePath, args, pid, nil, fdo, nil) then
	error(errorMessage)
end
fdo:close()

on_timer()

window = fltk:Fl_Window(100, 100, "PID test");
window:show()
Fl:run()
