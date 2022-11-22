-- Lua ISAPI Extension Initializer

local sys = require("sys")

sys.thread.init()


local function process(ecb, var)
	local chunk, err = loadfile(var.PATH_TRANSLATED)
	if err then error(err) end
	chunk(ecb, var)
end

return process
