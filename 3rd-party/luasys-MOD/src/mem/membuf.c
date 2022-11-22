/* Lua System: Memory Buffers: Streams */

#define SYSMEM_BUFLINE	256


/*
 * Arguments: membuf_udata, ...
 */
static int
write_stream (lua_State *L, struct membuf *mb)
{
    lua_getfenv(L, 1);
    lua_rawgeti(L, -1, (int) mb);
    lua_getfield(L, -1, "write");
    lua_pushvalue(L, -2);  /* stream object */
    lua_pushlstring(L, mb->data, mb->offset);
    lua_call(L, 2, 1);
    if (lua_toboolean(L, -1)) {
	mb->offset = 0;
	return 1;
    }
    return 0;
}

static int
membuf_addlstring (lua_State *L, struct membuf *mb, const char *s, size_t n)
{
    int offset = mb->offset;
    size_t newlen = offset + n, len = mb->len;

    if (newlen >= len) {
	const unsigned int flags = mb->flags;
	void *p;

	if ((flags & SYSMEM_BUFFLUSH) && write_stream(L, mb)) {
	    offset = 0;
	    if (n < len) goto end;
	    newlen = n;
	} else {
	    while ((len *= 2) <= newlen)
		continue;
	    newlen = len;
	}
	if (!(flags & SYSMEM_ALLOC) || !(p = realloc(mb->data, newlen)))
	    return 0;
	mb->len = newlen;
	mb->data = p;
    }
 end:
    if (s != NULL) {
	memcpy(mb->data + offset, s, n);
	mb->offset = offset + n;
    }
    return 1;
}

/*
 * Arguments: membuf_udata, string ...
 * Returns: [boolean]
 */
static int
membuf_write (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    int nargs, i;

    nargs = lua_gettop(L);
    for (i = 2; i <= nargs; ++i) {
	size_t len = lua_strlen(L, i);
	if (len && !membuf_addlstring(L, mb, lua_tostring(L, i), len))
	    return 0;
    }
    lua_pushboolean(L, 1);
    return 1;
}

/*
 * Arguments: membuf_udata, string ...
 * Returns: [boolean]
 */
static int
membuf_writeln (lua_State *L)
{
    lua_pushliteral(L, "\n");
    return membuf_write(L);
}

/*
 * Arguments: membuf_udata, [take (boolean)]
 * Returns: string
 */
static int
membuf_getstring (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int take = lua_toboolean(L, 2);

    lua_pushlstring(L, mb->data, mb->offset);
    if (take) mb->offset = 0;
    return 1;
}

/*
 * Arguments: membuf_udata, [offset (number)]
 * Returns: membuf_udata | offset (number)
 */
static int
membuf_seek (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (lua_gettop(L) > 1) {
	mb->offset = lua_tointeger(L, 2);
	lua_settop(L, 1);
    } else
	lua_pushinteger(L, mb->offset);
    return 1;
}

/*
 * Arguments: membuf_udata, consumer_stream
 */
static int
membuf_output (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (lua_isnoneornil(L, 2))
	mb->flags &= ~(SYSMEM_BUFFLUSH | SYSMEM_OSTREAM);
    else
	mb->flags |= SYSMEM_BUFFLUSH | SYSMEM_OSTREAM;

    lua_settop(L, 2);
    lua_getfenv(L, 1);
    lua_rawgeti(L, -1, 0);  /* output streams */
    lua_pushvalue(L, 2);
    lua_rawseti(L, -2, (int) mb);
    return 0;
}

/*
 * Arguments: membuf_udata, producer_stream
 */
static int
membuf_input (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (lua_isnoneornil(L, 2))
	mb->flags &= SYSMEM_ISTREAM;
    else
	mb->flags |= SYSMEM_ISTREAM;

    lua_settop(L, 2);
    lua_getfenv(L, 1);  /* input streams */
    lua_pushvalue(L, 2);
    lua_rawseti(L, -2, (int) mb);
    return 0;
}

static void
read_stream (lua_State *L, int n)
{
    lua_pushvalue(L, -2);
    lua_pushvalue(L, -2);
    if (n == -1)
	lua_pushnil(L);
    else
	lua_pushinteger(L, n);
    lua_call(L, 2, 1);
}

static int
read_bytes (lua_State *L, struct membuf *mb, size_t l)
{
    int n = mb->offset;

    if (!n && (mb->flags & SYSMEM_ISTREAM)) {
	read_stream(L, l);
	return 1;
    }

    if (l > (size_t) n) l = n;
    if (l) {
	char *p = mb->data;  /* avoid warning */
	lua_pushlstring(L, p, l);
	n -= l;
	mb->offset = n;
	if (n) memmove(p, p + 1, n);
    } else
	lua_pushnil(L);
    return 1;
}

static int
read_line (lua_State *L, struct membuf *mb)
{
    const char *nl, *s = mb->data;
    size_t l, n = mb->offset;

    if (n && (nl = memchr(s, '\n', n))) {
	char *p = mb->data;  /* avoid warning */
	l = nl - p;
	lua_pushlstring(L, p, l);
	n -= l + 1;
	mb->offset = n;
	if (n) memmove(p, nl + 1, n);
	return 1;
    }
    if (!(mb->flags & SYSMEM_ISTREAM)) {
	n = 1;
	goto end;
    }
    for (; ; ) {
	read_stream(L, SYSMEM_BUFLINE);
	n = lua_strlen(L, -1);
	if (!n) {
	    n = 1;
	    break;
	}
	s = lua_tostring(L, -1);
	if (*s == '\n')
	    break;
	nl = memchr(s + 1, '\n', n - 1);
	l = !nl ? n : (size_t) (nl - s);
	if (!membuf_addlstring(L, mb, s, l))
	    return 0;
	/* tail */
	if (nl) {
	    n -= l;
	    s = nl;
	    break;
	}
	lua_pop(L, 1);
    }
 end:
    if ((l = mb->offset))
	lua_pushlstring(L, mb->data, l);
    else
	lua_pushnil(L);
    mb->offset = 0;
    return (!--n) ? 1 : membuf_addlstring(L, mb, s + 1, n);
}

/*
 * Arguments: membuf_udata, [count (number) | mode (string: "*l", "*a")]
 * Returns: [string | number]
 */
static int
membuf_read (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    lua_settop(L, 2);
    if (mb->flags & SYSMEM_ISTREAM) {
	lua_getfenv(L, 1);  /* input streams */
	lua_rawgeti(L, -1, (int) mb);
	lua_getfield(L, -1, "read");
	lua_pushvalue(L, -2);  /* stream object */
    }

    if (lua_type(L, 2) == LUA_TNUMBER)
	read_bytes(L, mb, lua_tointeger(L, 2));
    else {
	const char *s = luaL_optstring(L, 2, "*a");

	switch (s[1]) {
	case 'l':
	    return read_line(L, mb);
	case 'a':
	    read_bytes(L, mb, ~((size_t) 0));
	    break;
	default:
	    luaL_argerror(L, 2, "invalid option");
	}
    }
    return 1;
}

/*
 * Arguments: membuf_udata
 * Returns: [boolean]
 */
static int
membuf_flush (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (mb->flags & SYSMEM_BUFFLUSH)
	write_stream(L, mb);
    return 1;
}

/*
 * Arguments: membuf_udata
 * Returns: [membuf_udata]
 */
static int
membuf_close (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    int res = 1;

    if (mb->data) {
	if (mb->flags & SYSMEM_BUFFLUSH)
	    res = write_stream(L, mb);
	mem_free(L);
    }
    return res;
}


