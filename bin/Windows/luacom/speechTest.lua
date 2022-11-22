
local init, err1, err2 = package.loadlib("luacom.dll","luacom_open")
assert (init, (err1 or '')..(err2 or ''))
init()

talk = assert (luacom.CreateObject ("SAPI.SpVoice"), "cannot open SAPI")
talk:Speak ("Hello Zoran!")
