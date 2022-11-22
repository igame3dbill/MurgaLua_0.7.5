/* Lua System: Win32 specifics */

#include "../common.h"


/*
 * Arguments: [frequency (hertz), duration (milliseconds)]
 */
static int
sys_beep (lua_State *L)
{
    const int freq = luaL_optinteger(L, 1, 1000);
    const int dur = luaL_optinteger(L, 2, 100);

    Beep(freq, dur);
    return 0;
}


#include "win32_svc.c"
#include "win32_reg.c"


static luaL_reg win32lib[] = {
    {"beep",		sys_beep},
    {"registry",	reg_new},
    {NULL, NULL}
};

void
luaopen_sys_win32 (lua_State *L)
{
    luaL_newmetatable(L, WREG_TYPENAME);
    lua_pushvalue(L, -1);  /* push metatable */
    lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
    luaL_register(L, NULL, reg_meth);

    luaL_register(L, "sys.win32", win32lib);
    lua_pop(L, 2);

    luaopen_sys_win32_service(L);
}
