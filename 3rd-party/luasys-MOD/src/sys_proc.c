/* Lua System: Processes */

#ifdef _WIN32
#include <shellapi.h>	/* ShellExecute */
#endif

#define PID_TYPENAME	"sys.pid"

#ifdef _POSIX_OPEN_MAX
#define MAX_OPEN_FDS	_POSIX_OPEN_MAX
#else
#define MAX_OPEN_FDS	20
#endif


/*
 * Arguments: [command (string)]
 * Returns: [boolean]
 */
static int
sys_run (lua_State *L)
{
    const char *cmd = luaL_checkstring(L, 1);
    int res;

#ifndef _WIN32
    sys_vm_leave();
    res = system(cmd);
    sys_vm_enter();

    if (res != -1) {
#else
    char path[MAX_PATH];
    const char *arg = NULL;

    if (cmd && (arg = strchr(cmd, ' '))) {
	unsigned int n = arg - cmd;
	if (n >= sizeof(path))
	    return 0;
	memcpy(path, cmd, n);
	path[n] = '\0';
	cmd = path;
	++arg;  /* skip space */
    }

    sys_vm_leave();
    res = (int) ShellExecute(0, 0, cmd, arg, 0, SW_SHOWNORMAL);
    sys_vm_enter();

    if (res > 32) {
#endif
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

#define MAX_ARGS	32
/*
 * Arguments: filename (string), [arguments (table: {number => string}),
 *	pid_udata (of new process),
 *	in (fd_udata), out (fd_udata), err (fd_udata),
 *	is_console (boolean)]
 * Returns: [boolean]
 */
static int
sys_spawn (lua_State *L)
{
    const char *cmd = luaL_checkstring(L, 1);
    fd_t *pidp = lua_isuserdata(L, 3) ? checkudata(L, 3, PID_TYPENAME) : NULL;
    fd_t *in_fdp = lua_isuserdata(L, 4) ? checkudata(L, 4, FD_TYPENAME) : NULL;
    fd_t *out_fdp = lua_isuserdata(L, 5) ? checkudata(L, 5, FD_TYPENAME) : NULL;
    fd_t *err_fdp = lua_isuserdata(L, 6) ? checkudata(L, 6, FD_TYPENAME) : NULL;

#ifndef _WIN32
    const char *argv[MAX_ARGS];
    int pid;

    /* fill arguments array */
    {
	const char *arg;
	int i = 1;

	/* filename in argv[0] */
	if ((arg = strrchr(cmd, '/')))
	    argv[0] = arg + 1;
	else
	    argv[0] = cmd;
	if (lua_istable(L, 2))
	    do {
		lua_rawgeti(L, 2, i);
		arg = lua_tostring(L, -1);
		lua_pop(L, 1);
		if (!arg) break;
		argv[i] = arg;
	    } while (++i < MAX_ARGS);
	argv[i] = NULL;
    }

    switch ((pid = fork())) {
    case 0:
	/* redirect standard handles */
	if (in_fdp) dup2(*in_fdp, STDIN_FILENO);
	if (out_fdp) dup2(*out_fdp, STDOUT_FILENO);
	if (err_fdp) dup2(*err_fdp, STDERR_FILENO);

	/* close other files */
	{
	    int n = sysconf(_SC_OPEN_MAX);
	    if (n < 0) n = MAX_OPEN_FDS;
	    while (n > 2)
		close(n--);
	}
	execvp(cmd, (void *) argv);
	perror(cmd);
	_exit(-1);
    case -1:
	goto err;
    default:
	if (pidp) *pidp = pid;
    }
#else
    const int is_console = lua_isboolean(L, -1) && lua_toboolean(L, -1);
    const int std_redirect = (in_fdp || out_fdp || err_fdp);
    STARTUPINFO si;
    PROCESS_INFORMATION pi;
    char line[MAX_PATH*2];  /* command line */
    int res;

    /* fill command line */
    {
	char *cp = line;
	int len = lua_strlen(L, 1);

	/* filename */
	if (len >= sizeof(line) - 2)
	    return 0;
	memcpy(cp, cmd, len);
	cp += len;
	*cp++ = ' ';

	if (lua_istable(L, 2)) {
	    const char *arg, *endp = line + sizeof(line) - 2;
	    int i;

	    for (i = 1; i < MAX_ARGS; ++i) {
		lua_rawgeti(L, 2, i);
		arg = lua_tostring(L, -1);
		lua_pop(L, 1);
		if (!arg) break;
		*cp++ = '"';
		while (*arg && cp < endp) {
		    if (*arg == '"' || *arg == '\\')
			*cp++ = '\\';  /* escape special chars */
		    *cp++ = *arg++;
		}
		if (cp + 3 >= endp)
		    return 0;
		*cp++ = '"';
		*cp++ = ' ';
	    }
	}
	*(--cp) = '\0';
    }

    memset(&si, 0, sizeof(STARTUPINFO));
    si.cb = sizeof(STARTUPINFO);
    si.dwFlags = STARTF_USESHOWWINDOW;

    memset(&pi, 0, sizeof(PROCESS_INFORMATION));

    /* redirect std. handles */
    if (std_redirect) {
	HANDLE hProc = GetCurrentProcess();

	res = 0;  /* go to err by default */
	si.dwFlags |= STARTF_USESTDHANDLES;
	si.wShowWindow = SW_MINIMIZE;
	si.hStdInput = si.hStdOutput = si.hStdError = INVALID_HANDLE_VALUE;

	if (!DuplicateHandle(hProc,
	 in_fdp ? *in_fdp : GetStdHandle(STD_INPUT_HANDLE),
	 hProc, &si.hStdInput, 0, TRUE, DUPLICATE_SAME_ACCESS) && in_fdp)
	    goto std_err;

	if (!DuplicateHandle(hProc,
	 out_fdp ? *out_fdp : GetStdHandle(STD_OUTPUT_HANDLE),
	 hProc, &si.hStdOutput, 0, TRUE, DUPLICATE_SAME_ACCESS) && out_fdp)
	    goto std_err;

	if (!DuplicateHandle(hProc,
	 err_fdp ? *err_fdp : GetStdHandle(STD_ERROR_HANDLE),
	 hProc, &si.hStdError, 0, TRUE, DUPLICATE_SAME_ACCESS) && err_fdp)
	    goto std_err;
    }
    res = CreateProcess(NULL, line, NULL, NULL, TRUE,
     is_console ? CREATE_NEW_CONSOLE : 0, NULL, NULL, &si, &pi);
    if (std_redirect) {
 std_err:
	CloseHandle(si.hStdInput);
	CloseHandle(si.hStdOutput);
	CloseHandle(si.hStdError);
    }
    if (!res) goto err;
    CloseHandle(pi.hThread);
    if (pidp)
	*pidp = pi.hProcess;
    else
	CloseHandle(pi.hProcess);
#endif
    lua_pushboolean(L, 1);
    return 1;
 err:
    return sys_seterror(L, 0);
}
#undef MAX_ARGS

/*
 * Arguments: [success/failure (boolean) | status (number)]
 */
static int
sys_exit (lua_State *L)
{
    exit (lua_isboolean(L, 1)
     ? (lua_toboolean(L, 1) ? EXIT_SUCCESS : EXIT_FAILURE)
     : lua_tointeger(L, 1));
    return 0;
}

/*
 * Returns: current process id. (number)
 */
static int
sys_getpid (lua_State *L)
{
#ifndef _WIN32
    lua_pushnumber(L, getpid());
#else
    lua_pushnumber(L, GetCurrentProcessId());
#endif
    return 1;
}


/*
 * Returns: pid_udata
 */
static int
sys_pid (lua_State *L)
{
    lua_boxpointer(L, (void *) -1);
    luaL_getmetatable(L, PID_TYPENAME);
    lua_setmetatable(L, -2);
    return 1;
}

/*
 * Arguments: pid_udata
 * Returns: [boolean]
 */
static int
proc_close (lua_State *L)
{
    fd_t *pidp = checkudata(L, 1, PID_TYPENAME);

    if (*pidp != (fd_t) -1) {
#ifdef _WIN32
	lua_pushboolean(L, CloseHandle(*pidp));
#endif
	*pidp = (fd_t) -1;
	return 1;
    }
    return 0;
}

/*
 * Arguments: pid_udata
 * Returns: status (number)
 */
static int
proc_wait (lua_State *L)
{
    fd_t pid = (fd_t) lua_unboxpointer(L, 1, PID_TYPENAME);

#ifndef _WIN32
    int status;

    while ((waitpid(pid, &status, 0)) == -1 && SYS_ERRNO == EINTR)
	continue;
    status = WIFEXITED(status) ? WEXITSTATUS(status) : -1;
#else
    DWORD status;

    WaitForSingleObject(pid, INFINITE);
    GetExitCodeProcess(pid, &status);
#endif
    lua_pushinteger(L, status);
    return 1;
}

/*
 * Arguments: pid_udata, [signal (string)]
 * Returns: [pid_udata]
 */
static int
proc_kill (lua_State *L)
{
    fd_t pid = (fd_t) lua_unboxpointer(L, 1, PID_TYPENAME);
#ifndef _WIN32
    const int signo = sig_flags[luaL_checkoption(L, 2, "TERM", sig_names)];
#endif

    if (pid == (fd_t) -1)
	return 0;

#ifndef _WIN32
    if (!kill(pid, signo)) {
#else
    if (TerminateProcess(pid, (unsigned int) -1)) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: pid_udata
 * Returns: string
 */
static int
proc_tostring (lua_State *L)
{
    fd_t pid = (fd_t) lua_unboxpointer(L, 1, PID_TYPENAME);

    if (pid != (fd_t) -1)
	lua_pushfstring(L, PID_TYPENAME " (%d)", (int) pid);
    else
	lua_pushliteral(L, PID_TYPENAME " (closed)");
    return 1;
}


static luaL_reg pid_meth[] = {
    {"close",		proc_close},
    {"wait",		proc_wait},
    {"kill",		proc_kill},
    {"__tostring",	proc_tostring},
#ifdef _WIN32
    {"__gc",		proc_close},
#endif
    {NULL, NULL}
};
