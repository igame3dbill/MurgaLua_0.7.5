#!/usr/local/bin/lua

local sys = require"sys"
local sock = require"sys.sock"


local host, port = "127.0.0.1", 8080

local stdin, stdout = sys.stdin, sys.stdout

local fd = sock.handle()
assert(fd:socket(), "Create socket")

assert(fd:connect(sock.addr_in(port, sock.inet_aton(host))), "Connect")

while true do
    local line = stdin:read()
    if not fd:write(line) then break end
    line = fd:read()
    if not line then break end
    stdout:write(line)
end
