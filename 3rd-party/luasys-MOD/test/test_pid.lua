#!/usr/local/bin/lua

local sys = require"sys"

-- Timer
local timer = murgaLua.createFltkTimer()
do
	local function on_timer()
		print"Working..."
		timer:doWait(0.5)
	end

  timer:callback(on_timer)
	timer:doWait(0.5)
end

-- Subprocess
do
	local pid = sys.pid()
	local fdi, fdo = sys.handle(), sys.handle()
	assert(fdi:pipe(fdo))
	do
		local sleep_msec = 1000
		local subprocess = [[
			murgaLua.sleep(]] .. sleep_msec .. [[)
			sys.stdout:write"Exited normally."
		]]
		print("Subprocess sleep:", sleep_msec)

		local args = {"-e", subprocess}
		if not sys.spawn("../../../bin/murgaLua.exe", args, pid, nil, fdo, nil) then
			error(errorMessage)
		end
		fdo:close()
	end

	local function on_child(evq, evid, pid, _, _, timeout, err)
		evq:del(timer_id)
		if timeout then
			print("Timeout:", timeout)
			if not pid:kill() then
				print("Kill:", errorMessage)
			end
		else
			print("Status:", err or 0)
			if err then
				print("Subprocess killed.")
			else
				print("Subprocess output:", fdi:read())
			end
		end
	end

	assert(evq:add_pid(pid, on_child, 1005))
end

evq:loop()

