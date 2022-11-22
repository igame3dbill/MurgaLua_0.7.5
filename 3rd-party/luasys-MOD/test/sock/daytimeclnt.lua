#!/usr/local/bin/lua

local sys = require"sys"
local sock = require"sys.sock"


local host, port = "127.0.0.1", 13
local MAX_MSG_LEN = 100

local fd = sock.handle()
assert(fd:socket("dgram"), "Create socket")

local addr = sock.addr_in(port, sock.inet_aton(host))

fd:nonblocking(true)
if fd:send("get time", addr) then
    local data = assert(fd:recv(MAX_MSG_LEN, addr), "Receive")
    port, host = sock.addr_in(addr)
    print(sock.inet_ntoa(host) .. ":" .. port .. "> " .. data)
end
