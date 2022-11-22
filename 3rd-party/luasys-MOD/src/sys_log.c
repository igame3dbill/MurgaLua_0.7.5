/* Lua System: Logging */

#ifndef _WIN32
#include <syslog.h>
#endif

#define LOG_TYPENAME	"sys.log"

/* Log event types */
#ifdef _WIN32
#define LOG_TDEBUG	EVENTLOG_SUCCESS
#define LOG_TERROR	EVENTLOG_ERROR_TYPE
#define LOG_TWARN	EVENTLOG_WARNING_TYPE
#define LOG_TINFO	EVENTLOG_INFORMATION_TYPE
#else
#define LOG_TDEBUG	LOG_DEBUG
#define LOG_TERROR	LOG_ERR
#define LOG_TWARN	LOG_WARNING
#define LOG_TINFO	LOG_INFO
#endif

struct sys_log {
#ifdef _WIN32
    HANDLE h;
#endif
    int type;
};


/*
 * Arguments: ident (string)
 * Returns: [log_udata]
 */
static int
sys_log (lua_State *L)
{
    const char *ident = luaL_checkstring(L, 1);
    struct sys_log *logp = lua_newuserdata(L, sizeof(struct sys_log));

#ifndef _WIN32
    openlog(ident, LOG_CONS, LOG_USER);
    {
#else
    logp->h = OpenEventLog(NULL, ident);
    if (logp->h) {
#endif
	logp->type = LOG_TERROR;
	luaL_getmetatable(L, LOG_TYPENAME);
	lua_setmetatable(L, -2);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: log_udata
 */
static int
log_close (lua_State *L)
{
#ifndef _WIN32
    (void) L;
    closelog();
#else
    struct sys_log *logp = checkudata(L, 1, LOG_TYPENAME);
    CloseEventLog(logp->h);
#endif
    return 0;
}

/*
 * Arguments: log_udata, type (string: "debug", "error", "warn", "info")
 * Returns: log_report (function)
 */
static int
log_type (lua_State *L)
{
    struct sys_log *logp = checkudata(L, 1, LOG_TYPENAME);
    const char *type = lua_tostring(L, 2);

    if (type) {
	int t = LOG_TERROR;
	switch (type[0]) {
	case 'd': t = LOG_TDEBUG; break;
	case 'e': t = LOG_TERROR; break;
	case 'w': t = LOG_TWARN; break;
	case 'i': t = LOG_TINFO; break;
	default: luaL_argerror(L, 2, "invalid option");
	}
	logp->type = t;
    }
    lua_getmetatable(L, 1);
    lua_getfield(L, -1, "__call");
    return 1;
}

/*
 * Arguments: log_udata, message (string)
 * Returns: [log_udata]
 */
static int
log_report (lua_State *L)
{
    struct sys_log *logp = checkudata(L, 1, LOG_TYPENAME);
    const char *msg = luaL_checkstring(L, 2);

#ifndef _WIN32
    syslog(logp->type, "%s", msg);
    {
#else
    if (ReportEvent(logp->h, (short) logp->type,
     0, 0, NULL, 1, 0, &msg, NULL)) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}


static luaL_reg log_meth[] = {
    {"__index",		log_type},
    {"__call",		log_report},
    {"__gc",		log_close},
    {NULL, NULL}
};
