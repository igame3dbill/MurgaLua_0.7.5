/* System library for Lua */

#include "common.h"

#include <sys/stat.h>

#include <lua.h> // Added for MurgaLua
#include <lauxlib.h> // Added for MurgaLua

#ifdef _WIN32

#define mode_t	int
#define ssize_t	DWORD

int is_WinNT;

#else

#include <sys/ioctl.h>
#include <sys/wait.h>
#include <sys/resource.h>

#if defined(sun) || defined(__sun) || defined(__sun__)
// Nothing
#else
#include <sys/sysctl.h>
#endif

#define MAX_PATH	260

#endif


static const int sig_flags[] = {
    SIGHUP, SIGINT, SIGQUIT, SIGTERM
};

static const char *const sig_names[] = {
    "HUP", "INT", "QUIT", "TERM", NULL
};

/*
 * Returns: string
 */
static int
sys_strerror (lua_State *L)
{
    const int err = SYS_ERRNO;
#ifndef _WIN32
    const char *s = strerror(err);
#else
    char s[256];

    if (FormatMessage(FORMAT_MESSAGE_FROM_SYSTEM, NULL, err,
     MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
     s, sizeof(s), NULL)) {
	char *cp = strrchr(s, '\r');
	if (cp) *cp = '\0';
    } else
	sprintf(s, "Unknown error %i", err);
#endif
    lua_pushstring(L, s);
    return 1;
}

/*
 * Returns: nil, string
 */
int
sys_seterror (lua_State *L, int err)
{
    if (err != 0) {
#ifndef _WIN32
	errno = err;
#else
	SetLastError(err);
#endif
    }
    lua_pushnil(L);
    sys_strerror(L);
    lua_pushvalue(L, -1);
    lua_setglobal(L, "errorMessage");
    return 2;
}


/*
 * Returns: number_of_processors (number)
 */
static int
sys_ncpu (lua_State *L)
{
#ifndef _WIN32
    int n = 1;
#if defined(__linux)
#define PTRN	"\nprocessor\t:"
    int fd = open("/proc/cpuinfo", O_RDONLY, 0);
    if (fd != -1) {
	char buf[4096];
	int nr;

	do nr = read(fd, buf, sizeof(buf));
	while (nr == -1 && SYS_ERRNO == EINTR);
	if (nr > 0) {
	    const char *bp = buf, *endp = buf + nr;

	    while (bp < endp && (bp = memchr(bp, '\n', endp - bp))) {
		if (!memcmp(bp, PTRN, sizeof(PTRN) - 1)) n++;
		bp++;
	    }
	}
	close(fd);
    }
#undef PTRN
#elif defined(__FreeBSD__) || defined(__NetBSD__) || defined(__OpenBSD__)
    int mib[2];
    size_t len = sizeof(int);

    mib[0] = CTL_HW;
    mib[1] = HW_NCPU;
    sysctl(mib, 2, &n, &len, NULL, 0);
#endif
    lua_pushinteger(L, n);
#else
    SYSTEM_INFO si;
    GetSystemInfo(&si);
    lua_pushinteger(L, si.dwNumberOfProcessors);
#endif
    return 1;
}

/*
 * Arguments: [number_of_files (number)]
 * Returns: [number_of_files (number)]
 */
static int
sys_limit_nfiles (lua_State *L)
{
#ifndef _WIN32
    struct rlimit rlim;

    if (lua_gettop(L)) {
	const int n = lua_tointeger(L, 1);

	rlim.rlim_cur = rlim.rlim_max = n;
	if (!setrlimit(RLIMIT_NOFILE, &rlim))
	    return 1;
    } else {
	if (!getrlimit(RLIMIT_NOFILE, &rlim)) {
	    lua_pushinteger(L, rlim.rlim_max);
	    return 1;
	}
    }
#else
    const int n = lua_gettop(L)
     ? _setmaxstdio(lua_tointeger(L, 1))
     : _getmaxstdio();

    if (n > 0) {
	lua_pushinteger(L, n);
	return 1;
    }
#endif
    return sys_seterror(L, 0);
}

/*
 * Arguments: string
 * Returns: number
 */
static int
sys_toint (lua_State *L)
{
    const char *s = lua_tostring(L, 1);
    int num = 0, sign = 1;

    if (s) {
	if (*s == '+' || (*s == '-' && (sign = -1)))
	    ++s;
	while (*s >= '0' && *s <= '9')
	    num = (num << 3) + (num << 1) + (*s++ & ~'0');
    }
    lua_pushinteger(L, sign * num);
    return 1;
}


#ifndef _WIN32
// Removed for MurgaLua - #include "sys_unix.c"
#endif

#include "sys_comm.c"
#include "sys_file.c"
#include "sys_env.c"
#include "sys_date.c"
// Removed for MurgaLua - #include "sys_fs.c"
// Removed for MurgaLua - #include "sys_log.c"
#include "sys_proc.c"
// Removed for MurgaLua - #include "sys_rand.c"
// Removed for MurgaLua - #include "sys_evq.c"


static luaL_reg syslib[] = {
    {"handle",		sys_file},
    {"strerror",	sys_strerror},
    {"ncpu",		sys_ncpu},
    {"limit_nfiles",	sys_limit_nfiles},
    {"toint",		sys_toint},
// Removed for MurgaLua -     {"stat",		sys_stat},
// Removed for MurgaLua -     {"utime",		sys_utime},
// Removed for MurgaLua -     {"remove",		sys_remove},
// Removed for MurgaLua -     {"rename",		sys_rename},
// Removed for MurgaLua -     {"curdir",		sys_curdir},
// Removed for MurgaLua -     {"mkdir",		sys_mkdir},
// Removed for MurgaLua -     {"rmdir",		sys_rmdir},
// Removed for MurgaLua -     {"dir",		sys_dir},
    {"run",		sys_run},
    {"spawn",		sys_spawn},
    {"getpid",		sys_getpid},
    {"exit",		sys_exit},
    {"getenv",		sys_getenv},
    {"setenv",		sys_setenv},
    {"env",		sys_env},
    {"msec",		sys_msec},
    {"date",		sys_date},
    {"time",		sys_time},
    {"difftime",	sys_difftime},
    {"period",		sys_period},
// Removed for MurgaLua -     {"log",		sys_log},
    {"pid",		sys_pid},
// Removed for MurgaLua -     {"random",		sys_random},
// Removed for MurgaLua -     {"event_queue",	sys_event_queue},
// Removed for MurgaLua - #ifndef _WIN32
// Removed for MurgaLua -     {"chroot",		sys_chroot},
// Removed for MurgaLua -     {"daemon",		sys_daemon},
// Removed for MurgaLua - #endif
    {NULL, NULL}
};


/*
 * Arguments: ..., sys_lib (table)
 */
static void
createmeta (lua_State *L)
{
    const int top = lua_gettop(L);

    luaL_newmetatable(L, FD_TYPENAME);
    lua_pushvalue(L, -1);  /* push metatable */
    lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
    luaL_register(L, NULL, fd_meth);

    /* predefined file handles */
    {
	const char *std[] = {"stdin", "stdout", "stderr"};
#ifdef _WIN32
	const fd_t std_fd[] = {
	    GetStdHandle(STD_INPUT_HANDLE),
	    GetStdHandle(STD_OUTPUT_HANDLE),
	    GetStdHandle(STD_ERROR_HANDLE)
	};
#endif
	int i;
	for (i = 3; i--; ) {
#ifndef _WIN32
	    const fd_t fd = i;
#else
	    const fd_t fd = std_fd[i];
#endif
	    lua_pushstring(L, std[i]);
	    lua_boxpointer(L, (void *) fd);
	    lua_pushvalue(L, -3);  /* metatable */
	    lua_pushboolean(L, 1);
	    lua_rawseti(L, -2, (int) fd);  /* don't close std. handles */
	    lua_setmetatable(L, -2);
	    lua_rawset(L, top);
	}
    }

// Removed for MurgaLua -     luaL_newmetatable(L, PERIOD_TYPENAME);
// Removed for MurgaLua -     lua_pushvalue(L, -1);  /* push metatable */
// Removed for MurgaLua -     lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
// Removed for MurgaLua -     luaL_register(L, NULL, period_meth);

// Removed for MurgaLua -     luaL_newmetatable(L, LOG_TYPENAME);
// Removed for MurgaLua -     luaL_register(L, NULL, log_meth);

    luaL_newmetatable(L, PID_TYPENAME);
    lua_pushvalue(L, -1);  /* push metatable */
    lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
    luaL_register(L, NULL, pid_meth);

// Removed for MurgaLua -     luaL_newmetatable(L, RAND_TYPENAME);
// Removed for MurgaLua -     luaL_register(L, NULL, rand_meth);

// Removed for MurgaLua -     luaL_newmetatable(L, DIR_TYPENAME);
// Removed for MurgaLua -     luaL_register(L, NULL, dir_meth);

// Removed for MurgaLua -     luaL_newmetatable(L, EVQ_TYPENAME);
// Removed for MurgaLua -     lua_pushvalue(L, -1);  /* push metatable */
// Removed for MurgaLua -     lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
// Removed for MurgaLua -     luaL_register(L, NULL, evq_meth);

    lua_settop(L, top);
}


LUALIB_API int luaopen_sys (lua_State *L);

LUALIB_API int
luaopen_sys (lua_State *L)
{
    luaL_register(L, "sys", syslib);
    createmeta(L);

    luaopen_sys_mem(L);
// Removed for MurgaLua -     luaopen_sys_thread(L);
#ifdef _WIN32
// Removed for MurgaLua -     luaopen_sys_win32(L);

    /* Is Win32 NT platform? */
    {
	OSVERSIONINFO osvi;

	osvi.dwOSVersionInfoSize = sizeof(OSVERSIONINFO);
	is_WinNT = (GetVersionEx(&osvi) && osvi.dwPlatformId == VER_PLATFORM_WIN32_NT);
    }
#else
    /* Ignore sigpipe or it will crash us */
    // signal_set(SIGPIPE, SIG_IGN);
    /* To interrupt blocking syscalls */
    // signal_set(SYS_SIGINTR, NULL);
#endif
    return 1;
}
