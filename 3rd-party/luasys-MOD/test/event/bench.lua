#!/usr/local/bin/lua

-- LibEvent/test/bench.c (comment EVLOOP_ONCE)


local sys = require"sys"
local sock = require"sys.sock"

local win32 = sys.win32


local num_pipes, num_active, num_writes = ...
local pipes = {}
local events, events_idx = {}, {}
local count, writes, fired

local period = sys.period()


local function read_cb(evq, ev_id, fd)
	if not fd:read(1) then
		error(errorMessage)
	end
	count = count + 1

	if writes ~= 0 then
		local widx = events_idx[ev_id] + 1
		if widx > num_pipes then
			widx = widx - num_pipes
		end

		local fdo = pipes[widx][2]
		if not fdo:write("e") then
			error(errorMessage)
		end

		writes = writes - 1
		fired = fired + 1
	end
end

local function run_once(evq)
	for i = 1, num_pipes do
		local fdi = pipes[i][1]
		local ev_id = events[i]
		if ev_id then
			evq:del(ev_id)
		end
		ev_id = evq:add(fdi, "r", read_cb)
		if not ev_id then
			error(errorMessage)
		end
		events[i], events_idx[ev_id] = ev_id, i
	end

	evq:loop(0)

	fired = 0
	local space = num_pipes / num_active
	for i = 0, num_active - 1 do
		local fdo = pipes[i * space + 1][2]
		if not fdo:write("e") then
			error(errorMessage)
		end
		fired = fired + 1
	end

	count = 0;
	writes = num_writes

	local xcount = 0
	period:start()
	repeat
		evq:loop(0)
		xcount = xcount + 1
	until (count == fired)
	print(period:get())

	if xcount ~= count then
		sys.stderr:write("Xcount: ", xcount, ", Rcount: ", count, "\n")
	end
end

local function main()
	num_pipes = tonumber(num_pipes) or 100
	num_active = tonumber(num_active) or 1
	num_writes = tonumber(num_writes) or num_pipes

	if not sys.limit_nfiles(num_pipes * 2 + 50) then
		error(errorMessage)
	end

	for i = 1, num_pipes do
		local fdi, fdo, res
		if win32 then
			fdi, fdo = sock.handle(), sock.handle()
			res = fdi:socket(fdo)
		else
			fdi, fdo = sys.handle(), sys.handle()
			res = fdi:pipe(fdo)
		end
		if not res then
			error(errorMessage)
		end
		pipes[i] = {fdi, fdo}
	end

	local evq = assert(sys.event_queue())

	for i = 1, 25 do
		run_once(evq)
	end
end

main()
