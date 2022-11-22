/* Lua System: Unix specifics */

/*
 * Arguments: path (string)
 * Returns: [boolean]
 */
static int
sys_chroot (lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);

    if (!chroot(path)) {
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: [don't close standard files (boolean)]
 */
static int
sys_daemon (lua_State *L)
{
    switch (fork()) {
    case -1: goto err;
    case 0:  break;
    default: _exit(0);
    }
    if (setsid() == -1) return 0;
    /* standard files */
    if (!lua_toboolean(L, 1)) {
	int fd = open("/dev/null", O_RDWR, 0);
	if (fd == -1
	 || dup2(fd, 0) == -1
	 || dup2(fd, 1) == -1
	 || dup2(fd, 2) == -1)
	    goto err;
	if (fd > 2) close(fd);
    }
    lua_pushboolean(L, 1);
    return 1;
 err:
    return sys_seterror(L, 0);
}

