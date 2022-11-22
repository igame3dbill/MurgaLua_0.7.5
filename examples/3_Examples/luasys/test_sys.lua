local sys = require("sys")

print"-- sys.handle <-> io.file"
do
    local fd = sys.handle()
    assert(fd:create("test", 384))
    assert(fd:write"fd <")

    local file = fd:to_file"w"
    assert(file:write"> file")
    file:flush()

    fd:from_file(file)
    fd:close()
    os.remove"test"
    print("OK")
end

print"-- Emulate popen()"
do
    local fdi, fdo = sys.handle(), sys.handle()
    assert(fdi:pipe(fdo))
    local s = "test pipe"
    assert(sys.spawn(murgaLua_ExePath,
	{'-e', 'sys.stdout:write[[' .. s .. ']]'},
	nil, nil, fdo))
    fdo:close()
    assert(fdi:read() == s)
    fdi:close()
    print("OK")
end

