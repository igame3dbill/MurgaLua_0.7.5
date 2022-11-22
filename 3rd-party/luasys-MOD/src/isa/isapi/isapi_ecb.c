/* Lua System: Internet Server API: Extension Control Block */

#define ECB_TYPENAME	"sys.isa.isapi"


/*
 * Arguments: ..., status (boolean | string: "success", "keep_conn", "pending", "error")
 */
static int
ecb_tostatus (lua_State *L, int idx)
{
    static const int status_flags[] = {
	HSE_STATUS_SUCCESS, HSE_STATUS_SUCCESS_AND_KEEP_CONN,
	HSE_STATUS_PENDING, HSE_STATUS_ERROR
    };
    static const char *const status_names[] = {
	"SUCCESS", "SUCCESS_AND_KEEP_CONN", "PENDING", "ERROR", NULL
    };

    if (lua_isboolean(L, idx))
	return lua_toboolean(L, idx) ? HSE_STATUS_SUCCESS : HSE_STATUS_ERROR;
    return status_flags[luaL_checkoption(L, idx, "SUCCESS", status_names)];
}


/*
 * Arguments: ecb_udata, status (string: "success", "keep_conn", "pending", "error")
 */
static int
ecb_status (lua_State *L)
{
    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);

    ecb->dwHttpStatusCode = ecb_tostatus(L, 2);
    return 0;
}

/*
 * Arguments: ecb_udata, string
 */
static int
ecb_log (lua_State *L)
{
    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);
    size_t len;
    const char *str = lua_tolstring(L, 2, &len);

    if (str) {
	if (len >= HSE_LOG_BUFFER_LEN) len = HSE_LOG_BUFFER_LEN - 1;
	memcpy(ecb->lpszLogData, str, len);
	ecb->lpszLogData[len] = '\0';
    }
    return 0;
}

/*
 * Arguments: ecb_udata, variable (string)
 * Returns: value (string)
 */
static int
ecb_getvar (lua_State *L)
{
    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);
    char *var = (char *) luaL_checkstring(L, 2);
    char buf[SYS_BUFSIZE];
    usize_t len = sizeof(buf);

    if (ecb->GetServerVariable(ecb->ConnID, var, buf, &len)) {
	lua_pushlstring(L, buf, len);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: ecb_udata, {string | membuf_udata} ...
 * Returns: [success/partial (boolean), count (number)]
 */
static int
ecb_write (lua_State *L)
{
    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);
    size_t n = 0;  /* number of chars actually write */
    int i, nargs = lua_gettop(L);

    for (i = 2; i <= nargs; ++i) {
	struct sys_buffer sb;
	int nw;

	if (!sys_buffer_read(L, i, &sb)
	 || sb.size == 0)  /* don't close the connection */
	    continue;
	sys_vm_leave();
	{
	    usize_t nwr = sb.size;
	    nw = ecb->WriteClient(ecb->ConnID, sb.ptr.w, &nwr, 0) ? nwr : -1;
	}
	sys_vm_enter();
	if (nw == -1) {
	    if (n > 0 || SYS_ERRNO == EAGAIN) break;
	    return sys_seterror(L, 0);
	}
	n += nw;
	sys_buffer_readed(&sb, nw);
	if ((size_t) nw < sb.size) break;
    }
    lua_pushboolean(L, (i > nargs));
    lua_pushinteger(L, n);
    return 2;
}

/*
 * Arguments: ecb_udata, [membuf_udata, count (number)]
 * Returns: [string | count (number) | false (EAGAIN)]
 */
static int
ecb_read (lua_State *L)
{
    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);
    size_t n = !lua_isnumber(L, -1) ? ~((size_t) 0)
     : (size_t) lua_tonumber(L, -1);
    const size_t len = n;  /* how much total to read */
    size_t rlen;  /* how much to read */
    int nr;  /* number of bytes actually read */
    struct sys_buffer sb;
    char buf[SYS_BUFSIZE];

    sys_buffer_write(L, 2, &sb, buf, sizeof(buf));
    do {
	rlen = (n <= sb.size) ? n : sb.size;
	sys_vm_leave();
	{
	    usize_t l;
	    nr = ecb->ReadClient(ecb->ConnID, sb.ptr.w, &l) ? l : -1;
	}
	sys_vm_enter();
	if (nr == -1) break;
	n -= nr;  /* still have to read `n' bytes */
    } while ((n != 0L && nr == (int) rlen)  /* until end of count or eof */
     && sys_buffer_written(L, &sb, buf));
    if (nr <= 0 && len == n) {
	if (!nr || SYS_ERRNO != EAGAIN) goto err;
	lua_pushboolean(L, 0);
    } else {
	if (!sys_buffer_push(L, &sb, buf, nr))
	    lua_pushinteger(L, len - n);
    }
    return 1;
 err:
    return sys_seterror(L, 0);
}

/*
 * Arguments: ecb_udata, request (string), argument (string)
 * Returns: [boolean]
 */
static int
ecb_request (lua_State *L)
{
    static const int req_flags[] = {
	HSE_REQ_SEND_URL_REDIRECT_RESP,
	HSE_REQ_SEND_URL, HSE_REQ_SEND_RESPONSE_HEADER,
	HSE_REQ_DONE_WITH_SESSION, HSE_REQ_END_RESERVED
    };
    static const char *const req_names[] = {
	"SEND_URL_REDIRECT_RESP",
	"SEND_URL", "SEND_RESPONSE_HEADER",
	"DONE_WITH_SESSION", "END_RESERVED", NULL
    };

    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);
    size_t req = req_flags[luaL_checkoption(L, 2, NULL, req_names)];
    usize_t len = 0L;
    char *arg = (char *) lua_tolstring(L, 3, (size_t *) &len);

    if (ecb->ServerSupportFunction(ecb->ConnID, req, arg, &len, NULL)) {
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: ecb_udata
 * Returns: data (string), rest (number)
 */
static int
ecb_getdata (lua_State *L)
{
    LPEXTENSION_CONTROL_BLOCK ecb = lua_unboxpointer(L, 1, ECB_TYPENAME);

    lua_pushlstring(L, (const char *) ecb->lpbData, ecb->cbAvailable);
    lua_pushinteger(L, ecb->cbTotalBytes - ecb->cbAvailable);
    return 2;
}


static luaL_reg ecb_meth[] = {
    {"status",		ecb_status},
    {"log",		ecb_log},
    {"getvar",		ecb_getvar},
    {"write",		ecb_write},
    {"read",		ecb_read},
    {"request",		ecb_request},
    {"getdata",		ecb_getdata},
    {NULL, NULL}
};
