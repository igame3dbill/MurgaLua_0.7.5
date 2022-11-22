../../bin/Linux/murgaLua -e "murgaLua.compileMurgaLua (\"../calculator.lua\", \"../../bin/Linux/murgaLua\", \"lua.out\")"
../../bin/Linux/murgaLua -e "murgaLua.decompileMurgaLua (\"lua.out\", \"out.lua\")"
chmod +x lua.out

