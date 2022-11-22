local open = assert(loadlib("./libluaiostring.so.1.0", "luaopen_iostring"))
open()

return ciostring
