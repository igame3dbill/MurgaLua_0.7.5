/* Lua System: Internet Server API */

#include "../../common.h"

#include <httpext.h>


#ifndef NDEBUG
#include <stdio.h>

static FILE *flog;
#endif

#define LISAPI_DESCR	"Lua ISAPI Extension"

/* Global Lua State */
static struct {
    lua_State *L;
    struct sys_vmthread *vmtd;
} g_ISAPI;


#include "isapi_ecb.c"


static int
traceback (lua_State *L) {
    lua_getfield(L, LUA_GLOBALSINDEX, "debug");
    if (!lua_istable(L, -1)) {
	lua_pop(L, 1);
	return 1;
    }
    lua_getfield(L, -1, "traceback");
    if (!lua_isfunction(L, -1)) {
	lua_pop(L, 2);
	return 1;
    }
    lua_pushvalue(L, 1);  /* pass error message */
    lua_pushinteger(L, 2);  /* skip this function and traceback */
    lua_call(L, 2, 1);  /* call debug.traceback */
    return 1;
}


static int
lisapi_init ()
{
    lua_State *L;

    if (g_ISAPI.vmtd) return 0;

    L = lua_open();
    if (!L) return -1;

#ifndef NDEBUG
    flog = fopen("luaisapi.log", "w");
    if (!flog) goto err_log;
#endif

    luaL_openlibs(L);  /* open standard libraries */

    lua_pushcfunction(L, traceback);  /* push traceback function */
    if (luaL_loadfile(L, "isapi.lua")
     || lua_pcall(L, 0, 1, 1)
     || !lua_isfunction(L, -1))
	goto err;

    g_ISAPI.vmtd = sys_gettls();
    if (g_ISAPI.vmtd) {
	luaL_newmetatable(L, ECB_TYPENAME);
	lua_pushvalue(L, -1);  /* push metatable */
	lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
	luaL_register(L, NULL, ecb_meth);
	lua_pop(L, 1);

	g_ISAPI.L = L;
	sys_vm_leave();
	sys_settls(NULL);
	return 0;
    }
#ifndef NDEBUG
    lua_pushliteral(L, "Threading not initialized");
#endif

 err:
#ifndef NDEBUG
    fprintf(flog, "ERROR: %s\n", lua_tostring(L, -1));
    fclose(flog);
 err_log:
#endif
    lua_close(L);
    return -1;
}


BOOL WINAPI
GetExtensionVersion (HSE_VERSION_INFO *ver)
{
    ver->dwExtensionVersion = HSE_VERSION;
    memcpy(ver->lpszExtensionDesc, LISAPI_DESCR, sizeof(LISAPI_DESCR));

    return !lisapi_init();
}


BOOL WINAPI
TerminateExtension (DWORD flags)
{
    (void) flags;

    if (g_ISAPI.vmtd) {
	lua_close(g_ISAPI.L);
#ifndef NDEBUG
	fclose(flog);
#endif
	g_ISAPI.vmtd = NULL;
    }
    return TRUE;
}


DWORD WINAPI
HttpExtensionProc (LPEXTENSION_CONTROL_BLOCK ecb)
{
    static const char *const var_names[] = {
	"REQUEST_METHOD", "QUERY_STRING", "PATH_INFO",
	"PATH_TRANSLATED", "CONTENT_TYPE", NULL
    };
    const char *var_values[] = {
	ecb->lpszMethod, ecb->lpszQueryString, ecb->lpszPathInfo,
	ecb->lpszPathTranslated, ecb->lpszContentType
    };

    lua_State *L;
    DWORD res;
    int i;

    sys_vm2_enter(g_ISAPI.vmtd);

    L = sys_newthread(g_ISAPI.L, g_ISAPI.vmtd);
    if (!L) {
	res = HSE_STATUS_ERROR;
	goto err;
    }

    lua_pushvalue(g_ISAPI.L, 1);  /* push traceback function */
    lua_pushvalue(g_ISAPI.L, 2);  /* push process function */
    lua_xmove(g_ISAPI.L, L, 2);  /* move functions to L */

    /* Arguments */
    lua_boxpointer(L, ecb);
    luaL_getmetatable(L, ECB_TYPENAME);
    lua_setmetatable(L, -2);
    lua_newtable(L);  /* variables */
    for (i = 0; var_names[i] != NULL; ++i) {
	lua_pushstring(L, var_values[i]);
	lua_setfield(L, -2, var_names[i]);
    }

    if (!lua_pcall(L, 2, 1, 1)) {
	res = ecb_tostatus(L, -1);
    } else {
	char *str;

	lua_pushliteral(L, "\n\n<pre>");
	lua_insert(L, -2);
	lua_concat(L, 2);

	str = (char *) lua_tolstring(L, -1, (size_t *) &res);
	ecb->WriteClient(ecb->ConnID, str, &res, 0);
	res = HSE_STATUS_ERROR;
    }

    sys_delthread(L);
 err:
    sys_vm2_leave(g_ISAPI.vmtd);
    return res;
}

