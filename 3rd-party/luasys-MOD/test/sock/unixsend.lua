#!/usr/local/bin/lua

local sys = require"sys"
local sock = require"sys.sock"


local file = "/tmp/test_sock_lua"

local fd = sock.handle()
assert(fd:socket("dgram", "unix"), "Create socket")
local addr = assert(sock.addr_un(file), "Create address")

assert(fd:connect(addr), "Connect")
fd:send(sys.stdin:read(13))
