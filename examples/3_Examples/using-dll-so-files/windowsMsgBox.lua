user32=alien.load("user32.dll")

user32.MessageBoxA:types{  abi = "stdcall", ret = "int", "pointer", "string", "string", "int" }
user32.MessageBoxA(nil, "Hello From Lua", "C/Invoke Message Box", 0)
