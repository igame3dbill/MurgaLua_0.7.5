/* Lua System: Process Environment */

#ifndef _WIN32
extern char **environ;
#endif


/*
 * Arguments: name (string)
 * Returns: [value (string)]
 */
static int
sys_getenv (lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);

#ifndef _WIN32
    lua_pushstring(L, getenv(name));
    return 1;
#else
    char *buf = NULL;
    unsigned int len;

    len = GetEnvironmentVariable(name, NULL, 0);
    if (len) {
	buf = malloc(len);
	--len;  /* not including term. zero */
	if (buf && GetEnvironmentVariable(name, buf, (len + 1)) == len) {
	    lua_pushlstring(L, buf, len);
	    free(buf);
	    return 1;
	}
    }
    return sys_seterror(L, 0);
#endif
}

/*
 * Arguments: name (string), [value (string)]
 * Returns: [boolean]
 */
static int
sys_setenv (lua_State *L)
{
    const char *name = luaL_checkstring(L, 1);
    const char *value = lua_tostring(L, 2);

#ifndef _WIN32
    if ((!value && (unsetenv(name), 1))
     || !setenv(name, value, 1)) {
#else
    if (SetEnvironmentVariable(name, value)) {
#endif
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Returns: environment (table)
 */
static int
sys_env (lua_State *L)
{
    const char *name, *value, *end;

#ifndef _WIN32
    const char **env = (const char **) environ;

    lua_newtable(L);
    for (; (name = *env); ++env) {
	value = strchr(name, '=') + 1;
	end = strchr(value, '\0');

	lua_pushlstring(L, name, value - name - 1);
	lua_pushlstring(L, value, end - value);
	lua_rawset(L, -3);
    }
#else
    const char *env = GetEnvironmentStrings();

    lua_newtable(L);
    if (!env) return 0;
    for (name = env; *name != '\0'; name = end + 1) {
	value = strchr(name, '=') + 1;
	end = strchr(value, '\0');

	lua_pushlstring(L, name, value - name - 1);
	lua_pushlstring(L, value, end - value);
	lua_rawset(L, -3);
    }
    FreeEnvironmentStrings((char *) env);
#endif
    return 1;
}

