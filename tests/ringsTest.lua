require"rings"
S = rings.new ()

S:dostring ([[print("test")
_enableRingsStable()
_enableMurgaLuaCore()
print(murgaLua_About .. murgaLua_Level)
murgaLua.debug.printTable(_G)]])

S:close ()

