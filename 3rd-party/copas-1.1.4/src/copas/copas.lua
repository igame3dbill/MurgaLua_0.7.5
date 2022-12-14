-------------------------------------------------------------------------------
-- Copas - Coroutine Oriented Portable Asynchronous Services
--
-- Offers a dispatcher and socket operations based on coroutines.
-- Usage:
--    copas.addserver(server, handler, timeout)
--    copas.addthread(thread, ...) Create a new coroutine thread and run it with args
--    copas.loop(timeout) - listens infinetely
--    copas.step(timeout) - executes one listening step
--    copas.receive(pattern or number) - receives data from a socket
--    copas.settimeout(client, time) if time=0 copas.receive(bufferSize) - receives partial data from a socket were data<=bufferSize
--    copas.send  - sends data through a socket
--    copas.wrap  - wraps a LuaSocket socket with Copas methods
--    copas.connect - blocks only the thread until connection completes
--    copas.flush - *deprecated* do nothing
--
-- Authors: Andre Carregal and Javier Guerra
-- Contributors: Diego Nehab, Mike Pall, David Burgess, Leonardo Godinho,
--               Thomas Harning Jr. and Gary NG
--
-- Copyright 2005 - Kepler Project (www.keplerproject.org)
--
-- $Id: copas.lua,v 1.34 2008/12/09 16:22:26 carregal Exp $
-------------------------------------------------------------------------------
local socket = require "socket"

require"coxpcall"

local WATCH_DOG_TIMEOUT = 120

-- Redefines LuaSocket functions with coroutine safe versions
-- (this allows the use of socket.http from within copas)
local function statusHandler(status, ...)
 if status then return ... end
 return nil, ...
end
function socket.protect(func)
 return function (...)
               return statusHandler(copcall(func, ...))
       end
end

function socket.newtry(finalizer)
       return function (...)
               local status = (...) or false
               if (status==false)then
                       copcall(finalizer, select(2, ...) )
                       error((select(2, ...)), 0)
               end
               return ...
       end
end
-- end of LuaSocket redefinitions


module ("copas", package.seeall)

-- Meta information is public even if begining with an "_"
_COPYRIGHT   = "Copyright (C) 2005 Kepler Project"
_DESCRIPTION = "Coroutine Oriented Portable Asynchronous Services"
_VERSION     = "Copas 1.1.4"

-------------------------------------------------------------------------------
-- Simple set implementation based on LuaSocket's tinyirc.lua example
-- adds a FIFO queue for each value in the set
-------------------------------------------------------------------------------
local function newset()
   local reverse = {}
   local set = {}
   local q = {}
   setmetatable(set, { __index = {
       insert = function(set, value)
           if not reverse[value] then
               set[#set + 1] = value
               reverse[value] = #set
           end
       end,

       remove = function(set, value)
           local index = reverse[value]
           if index then
               reverse[value] = nil
               local top = set[#set]
               set[#set] = nil
               if top ~= value then
                   reverse[top] = index
                   set[index] = top
               end
           end
       end,

               push = function (set, key, itm)
                       local qKey = q[key]
                       if qKey == nil then
                               q[key] = {itm}
                       else
                               qKey[#qKey + 1] = itm
                       end
               end,

       pop = function (set, key)
         local t = q[key]
         if t ~= nil then
           local ret = table.remove (t, 1)
           if t[1] == nil then
             q[key] = nil
           end
           return ret
         end
       end
   }})
   return set
end

local _servers = newset() -- servers being handled
local _reading_log = {}
local _writing_log = {}

local _reading = newset() -- sockets currently being read
local _writing = newset() -- sockets currently being written

-------------------------------------------------------------------------------
-- Coroutine based socket I/O functions.
-------------------------------------------------------------------------------
-- reads a pattern from a client and yields to the reading set on timeouts
function receive(client, pattern, part)
 local s, err
 pattern = pattern or "*l"
 repeat
   s, err, part = client:receive(pattern, part)
   if s or err ~= "timeout" then
       _reading_log[client] = nil
       return s, err, part
   end
   if part and tonumber(pattern) then
       pattern = pattern - #part
   end
   _reading_log[client] = os.time()
   coroutine.yield(client, _reading)
 until false
end

-- same as above but with special treatment when reading chunks,
-- unblocks on any data received.
function receivePartial(client, pattern)
 local s, err, part
 pattern = pattern or "*l"
 repeat
   s, err, part = client:receive(pattern)
   if s or ( (type(pattern)=="number") and part~="" and part ~=nil ) or
      err ~= "timeout" then
       _reading_log[client] = nil
       return s, err, part
   end
   _reading_log[client] = os.time()
   coroutine.yield(client, _reading)
 until false
end

-- sends data to a client. The operation is buffered and
-- yields to the writing set on timeouts
function send(client,data, from, to)
 local s, err,sent
 from = from or 1
 local lastIndex = from - 1

 repeat
   s, err, lastIndex = client:send(data, lastIndex + 1, to)
   -- adds extra corrotine swap
   -- garantees that high throuput dont take other threads to starvation
   if (math.random(100) > 90) then
       _writing_log[client] = os.time()
       coroutine.yield(client, _writing)
   end
   if s or err ~= "timeout" then
       _writing_log[client] = nil
       return s, err,lastIndex
   end
   _writing_log[client] = os.time()
   coroutine.yield(client, _writing)
 until false
end

-- waits until connection is completed
function connect(skt, host, port)
	skt:settimeout(0)
	local ret, err
	repeat
		ret, err = skt:connect (host, port)
		if ret or err ~= "timeout" then
			_writing_log[skt] = nil
			return ret, err
		end
		_writing_log[skt] = os.time()
		coroutine.yield(skt, _writing)
	until false
	return ret, err
end

-- flushes a client write buffer (deprecated)
function flush(client)
end

-- wraps a socket to use Copas methods (send, receive, flush and settimeout)
local _skt_mt = {__index = {
       send = function (self, data, from, to)
                       return send (self.socket, data, from, to)
       end,

       receive = function (self, pattern)
                       if (self.timeout==0) then
                               return receivePartial(self.socket, pattern)
                       end
                       return receive (self.socket, pattern)
       end,

       flush = function (self)
                       return flush (self.socket)
       end,

       settimeout = function (self,time)
                       self.timeout=time
                       return
       end,
}}

function wrap (skt)
       return  setmetatable ({socket = skt}, _skt_mt)
end

--------------------------------------------------
-- Error handling
--------------------------------------------------

local _errhandlers = {}   -- error handler per coroutine

function setErrorHandler (err)
       local co = coroutine.running()
       if co then
               _errhandlers [co] = err
       end
end

local function _deferror (msg, co, skt)
       print (msg, co, skt)
end

-------------------------------------------------------------------------------
-- Thread handling
-------------------------------------------------------------------------------

local function _doTick (co, skt, ...)
       if not co then return end

       local ok, res, new_q = coroutine.resume(co, skt, ...)

       if ok and res and new_q then
               new_q:insert (res)
               new_q:push (res, co)
       else
               if not ok then copcall (_errhandlers [co] or _deferror, res, co, skt) end
               if skt then skt:close() end
               _errhandlers [co] = nil
       end
end

-- accepts a connection on socket input
local function _accept(input, handler)
       local client = input:accept()
       if client then
               client:settimeout(0)
               local co = coroutine.create(handler)
               _doTick (co, client)
               --_reading:insert(client)
       end
       return client
end

-- handle threads on a queue
local function _tickRead (skt)
       _doTick (_reading:pop (skt), skt)
end

local function _tickWrite (skt)
       _doTick (_writing:pop (skt), skt)
end

-------------------------------------------------------------------------------
-- Adds a server/handler pair to Copas dispatcher
-------------------------------------------------------------------------------
function addserver(server, handler, timeout)
 server:settimeout(timeout or 0.1)
 _servers[server] = handler
 _reading:insert(server)
end

-------------------------------------------------------------------------------
-- Adds an new courotine thread to Copas dispatcher
-------------------------------------------------------------------------------
function addthread(thread, ...)
       local co = coroutine.create(thread)
       _doTick (co, nil, ...)
end

-------------------------------------------------------------------------------
-- tasks registering
-------------------------------------------------------------------------------

local _tasks = {}

local function addtaskRead (tsk)
       -- lets tasks call the default _tick()
       tsk.def_tick = _tickRead

       _tasks [tsk] = true
end

local function addtaskWrite (tsk)
       -- lets tasks call the default _tick()
       tsk.def_tick = _tickWrite

       _tasks [tsk] = true
end

local function tasks ()
       return next, _tasks
end

-------------------------------------------------------------------------------
-- main tasks: manage readable and writable socket sets
-------------------------------------------------------------------------------
-- a task to check ready to read events
local _readable_t = {
 events = function(self)
       local i = 0
       return function ()
               i = i + 1
               return self._evs [i]
       end
 end,

 tick = function (self, input)
       local handler = _servers[input]
       if handler then
               input = _accept(input, handler)
       else
               _reading:remove (input)
               self.def_tick (input)
       end
 end
}

addtaskRead (_readable_t)


-- a task to check ready to write events
local _writable_t = {
 events = function (self)
       local i = 0
       return function ()
               i = i+1
               return self._evs [i]
       end
 end,

 tick = function (self, output)
       _writing:remove (output)
       self.def_tick (output)
 end
}

addtaskWrite (_writable_t)

local last_cleansing = 0
local function _select (timeout)
       local err
   local readable={}
   local writable={}
   local r={}
   local w={}
   local now = os.time()
   local duration = os.difftime


       _readable_t._evs, _writable_t._evs, err = socket.select(_reading, _writing, timeout)
       local r_evs, w_evs = _readable_t._evs, _writable_t._evs

   if duration(now, last_cleansing) > WATCH_DOG_TIMEOUT then
       last_cleansing = now
       for k,v in pairs(_reading_log) do
           if not r_evs[k] and duration(now, v) > WATCH_DOG_TIMEOUT then
               _reading_log[k] = nil
               r_evs[#r_evs + 1] = k
               r_evs[k] = #r_evs
           end
       end

       for k,v in pairs(_writing_log) do
           if not w_evs[k] and duration(now, v) > WATCH_DOG_TIMEOUT then
               _writing_log[k] = nil
               w_evs[#w_evs + 1] = k
               w_evs[k] = #w_evs
           end
       end
   end

   if err == "timeout" and #r_evs + #w_evs > 0 then return nil
   else return err end
end


-------------------------------------------------------------------------------
-- Dispatcher loop step.
-- Listen to client requests and handles them
-------------------------------------------------------------------------------
function step(timeout)
 local err = _select (timeout)
 if err == "timeout" then return end

       if err then
               error(err)
       end

       for tsk in tasks() do
               for ev in tsk:events () do
                       tsk:tick (ev)
               end
       end
end

-------------------------------------------------------------------------------
-- Dispatcher endless loop.
-- Listen to client requests and handles them forever
-------------------------------------------------------------------------------
function loop(timeout)
       while true do
               step(timeout)
       end
end

