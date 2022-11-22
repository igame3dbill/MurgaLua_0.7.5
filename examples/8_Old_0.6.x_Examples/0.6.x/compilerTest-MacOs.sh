../../bin/MacOs-Intel/murgaLua -e "murgaLua.compileMurgaLua (\"../calculator.lua\", \"../../bin/MacOs-Intel/murgaLua\", \"lua.out\")"
../../bin/MacOs-Intel/murgaLua -e "murgaLua.decompileMurgaLua (\"lua.out\", \"out.lua\")"
chmod +x lua.out
