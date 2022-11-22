/* Lua System: File I/O */

#ifdef _WIN32

#include <stdio.h>	/* _fileno, P_tmpdir */
#include <io.h>		/* _open_osfhandle */

#define O_RDONLY	GENERIC_READ
#define O_WRONLY	GENERIC_WRITE
#define O_RDWR		(GENERIC_READ | GENERIC_WRITE)

#else

// Some POSIX systems don't have O_SYNC and O_DYSNC so we define them here.
// Needed in java/io/natFileDescriptorPosix.cc.
#if !defined (O_SYNC) && defined (O_FSYNC)
#define O_SYNC O_FSYNC
#endif
#if !defined (O_DSYNC) && defined (O_FSYNC)
#define O_DSYNC O_FSYNC
#endif
// If O_DSYNC is still not defined, use O_SYNC (needed for newlib)
#if !defined (O_DSYNC) 
#define O_DSYNC O_SYNC
#endif

#ifdef __linux
#define O_FSYNC         O_SYNC
#endif

#if !defined (O_FSYNC) 
#define O_FSYNC         O_SYNC
#endif

static const int fdopt_flags[] = {
    O_CREAT, O_EXCL, O_TRUNC, O_APPEND, O_NONBLOCK, O_FSYNC, O_NOCTTY
};
static const char *const fdopt_names[] = {
    "creat", "excl", "trunc", "append", "nonblock", "sync", "noctty",
    NULL
};

#endif


/*
 * Returns: fd_udata
 */
static int
sys_file (lua_State *L)
{
    lua_boxpointer(L, (void *) -1);
    luaL_getmetatable(L, FD_TYPENAME);
    lua_setmetatable(L, -2);
    return 1;
}

/*
 * Arguments: fd_udata, pathname (string), [mode (string: "r", "w", "rw"),
 *	permissions (number), options (string) ...]
 * Returns: [fd_udata]
 */
static int
sys_open (lua_State *L)
{
    fd_t fd, *fdp = checkudata(L, 1, FD_TYPENAME);
    const char *pathname = luaL_checkstring(L, 2);
    const char *mode = lua_tostring(L, 3);
#ifndef _WIN32
    mode_t perm = (mode_t) lua_tonumber(L, 4);
#else
    int append = 0;
#endif
    int flags = O_RDONLY, i;

#undef OPT_START
#define OPT_START	5

    if (mode) {
	switch (mode[0]) {
	case 'w': flags = O_WRONLY; break;
	case 'r': if (mode[1] == 'w') flags = O_RDWR;
	}
    }
#ifndef _WIN32
    for (i = lua_gettop(L); i >= OPT_START; --i) {
	flags |= fdopt_flags[luaL_checkoption(L, i, NULL, fdopt_names)];
    }

    sys_vm_leave();
    fd = open(pathname, flags, perm);
    sys_vm_enter();
#else
    {
	DWORD Share = FILE_SHARE_READ | FILE_SHARE_WRITE;
	DWORD Creation = OPEN_EXISTING;
	DWORD Attr = FILE_ATTRIBUTE_NORMAL
	 | SECURITY_SQOS_PRESENT | SECURITY_IDENTIFICATION;

	for (i = lua_gettop(L); i >= OPT_START; --i) {
	    const char *opt = lua_tostring(L, i);
	    if (opt)
		switch (opt[0]) {
		case 'c':	/* creat */
		    Creation &= ~OPEN_EXISTING;
		    Creation |= CREATE_ALWAYS;
		    break;
		case 'e':	/* excl */
		    Share = 0;
		    break;
		case 't':	/* trunc */
		    Creation &= ~OPEN_EXISTING;
		    Creation |= TRUNCATE_EXISTING;
		    break;
		case 'a':	/* append */
		    append = 1;
		    break;
		case 's':	/* sync */
		    Attr |= FILE_FLAG_WRITE_THROUGH;
		    break;
		case 'r':	/* random access */
		    Attr |= FILE_FLAG_RANDOM_ACCESS;
		    break;
		}
	}

	sys_vm_leave();
	fd = CreateFile(pathname, flags, Share, NULL, Creation, Attr, NULL);
	sys_vm_enter();
    }
#endif
    if (fd != (fd_t) -1) {
	*fdp = fd;
#ifdef _WIN32
	if (append)
	    SetFilePointer(fd, 0, NULL, FILE_END);
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, pathname (string), [permissions (number)]
 * Returns: [fd_udata]
 */
static int
sys_create (lua_State *L)
{
    fd_t fd, *fdp = checkudata(L, 1, FD_TYPENAME);
    const char *pathname = luaL_checkstring(L, 2);
#ifndef _WIN32
    mode_t perm = (mode_t) lua_tonumber(L, 3);
#endif

    sys_vm_leave();
#ifndef _WIN32
    fd = creat(pathname, perm);
#else
    fd = CreateFile(pathname, O_RDWR, FILE_SHARE_READ | FILE_SHARE_WRITE,
     NULL, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL
     | SECURITY_SQOS_PRESENT | SECURITY_IDENTIFICATION, NULL);
#endif
    sys_vm_enter();

    if (fd != (fd_t) -1) {
	*fdp = fd;
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, [prefix (string), auto-remove (boolean)]
 * Returns: [filename]
 */
static int
sys_tempfile (lua_State *L)
{
    fd_t fd, *fdp = checkudata(L, 1, FD_TYPENAME);
    const char *prefix = lua_tostring(L, 2);
    int auto_remove = lua_isboolean(L, -1) && lua_toboolean(L, -1);
    char path[MAX_PATH + 1];

#ifndef _WIN32
    static const char template[] = "XXXXXX";
    const char *tmpdir;
    size_t len, pfxlen = lua_strlen(L, 2);

    if (!(tmpdir = getenv("TMPDIR"))
     && !(tmpdir = getenv("TMP"))
     && !(tmpdir = getenv("TEMP")))
	tmpdir = P_tmpdir;
    len = strlen(tmpdir);
    if (len + 1 + pfxlen + sizeof(template) > sizeof(path))
	return 0;
    memcpy(path, tmpdir, len);
    if (path[len - 1] != '/')
	path[len++] = '/';
    if (pfxlen) {
	memcpy(path + len, prefix, pfxlen);
	len += pfxlen;
    }
    memcpy(path + len, template, sizeof(template));  /* include term. zero */

    sys_vm_leave();
    fd = mkstemp(path);
    sys_vm_enter();
#else
    char tmpdir[MAX_PATH + 1];

    if (!GetTempPath(MAX_PATH, tmpdir)
     || !GetTempFileName(tmpdir, prefix, 0, path))
	goto err;

    sys_vm_leave();
    fd = CreateFile(path, GENERIC_READ | GENERIC_WRITE,
     0, NULL, CREATE_ALWAYS, FILE_FLAG_RANDOM_ACCESS
     | FILE_ATTRIBUTE_TEMPORARY | FILE_ATTRIBUTE_HIDDEN
     | (auto_remove ? FILE_FLAG_DELETE_ON_CLOSE : 0), NULL);
    sys_vm_enter();
#endif
    if (fd != (fd_t) -1) {
	*fdp = fd;
#ifndef _WIN32
	if (auto_remove) unlink(path);
#endif
	lua_pushstring(L, path);
	return 1;
    }
#ifdef _WIN32
 err:
#endif
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata (reading), fd_udata (writing)
 * Returns: fd_udata (reading)
 */
static int
sys_pipe (lua_State *L)
{
    fd_t *rfdp = checkudata(L, 1, FD_TYPENAME);
    fd_t *wfdp = checkudata(L, 2, FD_TYPENAME);

#ifndef _WIN32
    fd_t filedes[2];
    if (!pipe(filedes)) {
	*rfdp = filedes[0];
	*wfdp = filedes[1];
#else
    if (CreatePipe(rfdp, wfdp, NULL, 0)) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, [close_std_handle (boolean)]
 * Returns: [boolean]
 */
static int
sys_close (lua_State *L)
{
    fd_t *fdp = checkudata(L, 1, FD_TYPENAME);
    const int close_std = lua_toboolean(L, 2);

    if (*fdp != (fd_t) -1) {
	luaL_getmetatable(L, FD_TYPENAME);
	lua_rawgeti(L, -1, (int) *fdp);  /* don't close std. handles */
	if (!(lua_isnil(L, -1) || close_std))
	    lua_pushboolean(L, 0);
	else {
#ifndef _WIN32
	    int res;
	    do res = close(*fdp);
	    while (res == -1 && SYS_ERRNO == EINTR);
	    lua_pushboolean(L, !res);
#else
	    lua_pushboolean(L, CloseHandle(*fdp));
#endif
	    *fdp = (fd_t) -1;
	}
	return 1;
    }
    return 0;
}

/*
 * Arguments: fd_udata
 */
static int
sys_dispose (lua_State *L)
{
    fd_t *fdp = checkudata(L, 1, FD_TYPENAME);
    *fdp = (fd_t) -1;
    return 0;
}

/*
 * Arguments: fd_udata, stream (string: "in", "out", "err")
 * Returns: [fd_udata]
 */
static int
sys_set_std (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    const char *stream = luaL_checkstring(L, 2);
    int dst;

#ifndef _WIN32
    int res;

    dst = (*stream == 'i') ? STDIN_FILENO
     : (*stream == 'o') ? STDOUT_FILENO : STDERR_FILENO;
    do res = dup2(fd, dst);
    while (res == -1 && SYS_ERRNO == EINTR);
    if (res != -1) {
#else
    dst = (*stream == 'i') ? STD_INPUT_HANDLE
     : (*stream == 'o') ? STD_OUTPUT_HANDLE : STD_ERROR_HANDLE;
    if (SetStdHandle(dst, fd)) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, offset (number),
 *	[whence (string: "set", "cur", "end")]
 * Returns: offset
 */
static int
sys_seek (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    off_t offset = (off_t) lua_tonumber(L, 2);
    const char *whencep = lua_tostring(L, 3);
    int whence = SEEK_SET;

    /* SEEK_* and FILE_* (win32) are equal */
    if (whencep)
	switch (whencep[0]) {
	case 'c': whence = SEEK_CUR; break;
	case 'e': whence = SEEK_END; break;
	}
#ifndef _WIN32
    offset = lseek(fd, offset, whence);
#else
    offset = SetFilePointer(fd, offset, NULL, whence);
#endif
    if (offset != (off_t) -1) {
	lua_pushnumber(L, offset);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, offset (number)
 * Returns: [fd_udata]
 */
static int
sys_set_end (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    off_t off = (off_t) lua_tonumber(L, 2);

#ifndef _WIN32
    int res;

    do res = ftruncate(fd, off);
    while (res == -1 && SYS_ERRNO == EINTR);
    if (!res) {
#else
    {
	off_t cur = SetFilePointer(fd, 0, NULL, FILE_CURRENT);
	SetFilePointer(fd, off, NULL, FILE_BEGIN);
	off = SetEndOfFile(fd);
	SetFilePointer(fd, cur, NULL, FILE_BEGIN);
    }
    if (off) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, offset (number), length (number),
 *	[lock/unlock (boolean)]
 * Returns: [fd_udata]
 */
static int
sys_lock (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    off_t off = (off_t) lua_tonumber(L, 2);
    size_t len = (size_t) lua_tonumber(L, 3);
    int locking = lua_isboolean(L, -1) && lua_toboolean(L, -1);
    int res;

#ifndef _WIN32
    struct flock lock;

    lock.l_type = locking ? (F_RDLCK | F_WRLCK) : F_UNLCK;
    lock.l_whence = SEEK_SET;
    lock.l_start = off;
    lock.l_len = len;

    sys_vm_leave();
    do res = fcntl(fd, F_SETLK, &lock);
    while (res == -1 && SYS_ERRNO == EINTR);
    sys_vm_enter();

    if (res != -1) {
#else
    sys_vm_leave();
    res = locking ? LockFile(fd, off, 0, len, 0)
     : UnlockFile(fd, off, 0, len, 0);
    sys_vm_enter();

    if (res) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, [mode (string)]
 * Returns: [file_udata]
 */
static int
sys_to_file (lua_State *L)
{
    fd_t *fdp = checkudata(L, 1, FD_TYPENAME);
    const char *mode = luaL_optstring(L, 2, "r");
    FILE *f;

#ifndef _WIN32
    f = fdopen((int) *fdp, mode);
#else
    f = _fdopen(_open_osfhandle((long) *fdp, 0), mode);
#endif
    if (f) {
	lua_boxpointer(L, f);
	luaL_getmetatable(L, LUA_FILEHANDLE);
	lua_setmetatable(L, -2);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, file_udata
 * Returns: [fd_udata]
 */
static int
sys_from_file (lua_State *L)
{
    fd_t *fdp = checkudata(L, 1, FD_TYPENAME);
    FILE **fp = checkudata(L, 2, LUA_FILEHANDLE);

#ifndef _WIN32
    *fdp = fileno(*fp);
#else
    *fdp = (fd_t) _get_osfhandle(_fileno(*fp));
#endif
    *fp = NULL;
    return 1;
}

/*
 * Arguments: fd_udata, {string | membuf_udata} ...
 * Returns: [success/partial (boolean), count (number)]
 */
static int
sys_write (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    ssize_t n = 0;  /* number of chars actually write */
    int i, nargs = lua_gettop(L);

    for (i = 2; i <= nargs; ++i) {
	struct sys_buffer sb;
	int nw;

	if (!sys_buffer_read(L, i, &sb))
	    continue;
	sys_vm_leave();
#ifndef _WIN32
	do nw = write(fd, sb.ptr.r, sb.size);
	while (nw == -1 && SYS_ERRNO == EINTR);
#else
	{
	    usize_t nwr;
	    nw = WriteFile(fd, sb.ptr.r, sb.size, &nwr, NULL) ? nwr : -1;
	}
#endif
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
 * Arguments: fd_udata, [membuf_udata, count (number)]
 * Returns: [string | count (number) | false (EAGAIN)]
 */
static int
sys_read (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
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
#ifndef _WIN32
	do nr = read(fd, sb.ptr.w, rlen);
	while (nr == -1 && SYS_ERRNO == EINTR);
#else
	{
	    usize_t l;
	    nr = ReadFile(fd, sb.ptr.w, rlen, &l, NULL) ? l : -1;
	}
#endif
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
 * Arguments: fd_udata
 * Returns: [fd_udata]
 */
static int
sys_flush (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    int res;

    sys_vm_leave();
#ifndef _WIN32
    res = fsync(fd);
#else
    res = !FlushFileBuffers(fd);
#endif
    sys_vm_enter();

    if (!res) {
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}


#ifndef _WIN32

/*
 * Arguments: fd_udata, option (string), [boolean]
 * Returns: [fd_udata]
 */
static int
sys_fdopt (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    int opt = fdopt_flags[luaL_checkoption(L, 2, NULL, fdopt_names)];
    int flags, res;

    flags = fcntl(fd, F_GETFL);
    if (lua_gettop(L) > 2) {
	flags = lua_toboolean(L, 3) ? flags | opt : flags & ~opt;
	res = !fcntl(fd, F_SETFL, flags);
    } else res = flags & opt;
    lua_settop(L, 1);
    return res ? 1 : 0;
}

#else

/*
 * Arguments: fd_udata, pathname (string),
 *	[maximum_message_size (number), timeout (milliseconds)]
 * Returns: [fd_udata]
 */
static int
sys_mailslot (lua_State *L)
{
    fd_t fd, *fdp = checkudata(L, 1, FD_TYPENAME);
    const char *pathname = luaL_checkstring(L, 2);
    size_t max_size = (size_t) lua_tonumber(L, 3);
    const msec_t timeout = lua_isnoneornil(L, 4)
     ? MAILSLOT_WAIT_FOREVER : (msec_t) lua_tonumber(L, 4);

    fd = CreateMailslot(pathname, max_size, timeout, NULL);

    if (fd != (fd_t) -1) {
	*fdp = fd;
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata
 * Returns: [next_message_size (number), message_count (number)]
 */
static int
sys_mailslot_info (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    usize_t next_size, count;

    if (GetMailslotInfo(fd, NULL, &next_size, &count, NULL)) {
	if (next_size == MAILSLOT_NO_MESSAGE)
	    next_size = count = 0;
	lua_pushinteger(L, next_size);
	lua_pushinteger(L, count);
	return 2;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: fd_udata, pipename (string),
 *	[write_through (boolean), timeout (milliseconds)]
 * Returns: [fd_udata]
 */
static int
sys_named_pipe (lua_State *L)
{
    fd_t fd, *fdp = checkudata(L, 1, FD_TYPENAME);
    const char *pipename = luaL_checkstring(L, 2);
    int open_mode = PIPE_ACCESS_DUPLEX | WRITE_OWNER
     | (lua_toboolean(L, 3) ? FILE_FLAG_WRITE_THROUGH : 0);
    const msec_t timeout = lua_isnoneornil(L, 4)
     ? NMPWAIT_WAIT_FOREVER : (msec_t) lua_tonumber(L, 4);

    fd = CreateNamedPipe(pipename, open_mode, 0, PIPE_UNLIMITED_INSTANCES,
     0, 0, timeout, NULL);

    if (fd != (fd_t) -1) {
	*fdp = fd;
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

#endif


/*
 * Arguments: fd_udata, nonblocking (boolean)
 * Returns: [fd_udata]
 */
static int
sys_nonblocking (lua_State *L)
{
#ifndef _WIN32
    lua_pushliteral(L, "nonblock");
    lua_insert(L, 2);
    return sys_fdopt(L);
#else
    /* Win32: Mailslot */
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);
    size_t mode = lua_toboolean(L, 2) ? 0 : MAILSLOT_WAIT_FOREVER;

    if (SetMailslotInfo(fd, mode)) {
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
#endif
}

/*
 * Arguments: fd_udata
 * Returns: string
 */
static int
sys_tostring (lua_State *L)
{
    fd_t fd = (fd_t) lua_unboxpointer(L, 1, FD_TYPENAME);

    if (fd != (fd_t) -1)
	lua_pushfstring(L, FD_TYPENAME " (%d)", (int) fd);
    else
	lua_pushliteral(L, FD_TYPENAME " (closed)");
    return 1;
}


static luaL_reg fd_meth[] = {
    {"open",		sys_open},
    {"create",		sys_create},
    {"tempfile",	sys_tempfile},
    {"pipe",		sys_pipe},
    {"close",		sys_close},
    {"dispose",		sys_dispose},
    {"set_std",		sys_set_std},
    {"seek",		sys_seek},
    {"set_end",		sys_set_end},
    {"lock",		sys_lock},
    {"to_file",		sys_to_file},
    {"from_file",	sys_from_file},
    {"write",		sys_write},
    {"read",		sys_read},
    {"flush",		sys_flush},
#ifndef _WIN32
    {"fdopt",		sys_fdopt},
#else
    {"mailslot",	sys_mailslot},
    {"mailslot_info",	sys_mailslot_info},
    {"named_pipe",	sys_named_pipe},
#endif
    {"nonblocking",	sys_nonblocking},
    {"__tostring",	sys_tostring},
    {"comm_init",	sys_comm_init},
    {"comm_control",	sys_comm_control},
    {"comm_timeout",	sys_comm_timeout},
    {"comm_queues",	sys_comm_queues},
    {"comm_purge",	sys_comm_purge},
    {"__gc",		sys_close},
    {NULL, NULL}
};
