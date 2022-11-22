#!/usr/local/bin/lua

local sys = require"sys"
local sock = require"sys.sock"


local ONE_SHOT_CLIENT = false
local DEBUG = false

local bind = {
    [8080] = "127.0.0.1",
}

local stderr = sys.stderr


local nskt = 0

local function chan_insert(evq, fd, cb, timeout)
    if not evq:add(fd, 'r', cb, timeout) then
	error(errorMessage)
    end
    --fd:nonblocking(true)

    if DEBUG then
	nskt = nskt + 1
	stderr:write("+ Insert in set (", nskt, ")\n")
    end
end

local function chan_remove(evq, evid, fd)
    evq:del(evid)
    fd:close()

    if DEBUG then
	nskt = nskt - 1
	stderr:write("- Remove from set (", nskt, ")\n")
    end
end

local function process(evq, evid, fd, _, _, _, eof)
    local line
    if not eof then
	line = fd:read()
    end
    if line then
	line = fd:write(line)
	if ONE_SHOT_CLIENT then
	    fd:shutdown()
	end
    end
    if not line then
	chan_remove(evq, evid, fd)
    end
end

local function accept(evq, evid, fd)
    local peer
    if DEBUG then
	peer = sock.addr_in()
    end
    local newfd = fd:accept(peer)

    if newfd then
	chan_insert(evq, newfd, process)

	if DEBUG then
	    local port, addr = sock.addr_in(peer)
	    stderr:write("Peer: " .. sock.inet_ntoa(addr)
		 .. ":" .. port .. "\n")
	end
    else
	stderr:write("accept: " .. errorMessage)
    end
end

local evq = sys.event_queue()
if not evq then error(errorMessage) end

print("Binding servers...")
for port, host in pairs(bind) do
    local fd = sock.handle()
    assert(fd:socket(), "Create socket")
    assert(fd:sockopt("reuseaddr", 1), "Reuse address")
    local addr = sock.inet_aton(host)
    assert(fd:bind(sock.addr_in(port, addr)), "Bind")
    assert(fd:listen(), "Listen")
    chan_insert(evq, fd, accept)
end

-- Quit by Ctrl-C
assert(evq:add_signal("INT", evq.stop))

print("Loop...")
evq:loop()
