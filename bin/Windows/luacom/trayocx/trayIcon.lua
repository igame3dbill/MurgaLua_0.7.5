
local init, err1, err2 = package.loadlib("luacom.dll","luacom_open")
assert (init, (err1 or '')..(err2 or ''))
init()

talk = assert (luacom.CreateObject ("TrayPut.Tray"), "cannot open SAPI")
talk.SetTip = "This is a test message"
talk:Add()

murgaLua.sleep(10000)