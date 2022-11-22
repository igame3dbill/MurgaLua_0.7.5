#!/usr/local/bin/lua

-- LibEvent/test/test-time.c


local sys = require"sys"


local NEVENT = 20000

local called = 0

local timers = {}

local rand_int = assert(sys.random())

local function time_cb(evq, evid)
	called = called + 1

	if called < 10*NEVENT then
		for i = 1, 10 do
			local j = rand_int(NEVENT) + 1
			local id = timers[j]
			local msec = rand_int(50)
			if msec % 2 == 0 then
				if id then
					evq:del(id)
					timers[j] = nil
				end
			elseif id then
				evq:timeout(id, msec)
			else
				timers[j] = evq:add_timer(time_cb, msec)
			end
		end
	else
		evq:del(evid)
	end
end

do
	local evq = assert(sys.event_queue())

	for i = 1, NEVENT do
		timers[i] = evq:add_timer(time_cb, rand_int(50))
	end

	evq:loop()

	print("called", called)
	return (called < NEVENT)
end
