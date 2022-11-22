/* Lua System: File System */

#ifdef _WIN32
#include <sys/utime.h>
#else
#include <dirent.h>
#include <utime.h>
#endif

#define DIR_TYPENAME	"sys.dir"

/* Directory iterator */
struct dir {
#ifndef _WIN32
    DIR *data;
#else
    int is_drive;
    HANDLE h;
    WIN32_FIND_DATA data;
#endif
};


/*
 * Arguments: pathname (string), [more_info (boolean)]
 * Returns: [is_directory (boolean), is_file (boolean),
 *	is_read (boolean), is_write (boolean), is_execute (boolean),
 *	[is_link (boolean), size (number),
 *	access_time (number), modify_time (number), create_time (number)]]
 */
static int
sys_stat (lua_State *L)
{
    const char *pathname = luaL_checkstring(L, 1);
    const int more_info = lua_toboolean(L, 2);
    struct stat st;
    int res;

    sys_vm_leave();
    res = stat(pathname, &st);
    sys_vm_enter();

    if (!res) {
	/* is directory? */
	lua_pushboolean(L,
#ifndef _WIN32
	 S_ISDIR(st.st_mode)
#else
	 st.st_mode & _S_IFDIR
#endif
	);
	/* is regular file? */
	lua_pushboolean(L,
#ifndef _WIN32
	 S_ISREG(st.st_mode)
#else
	 st.st_mode & _S_IFREG
#endif
	);
	/* can anyone read from file? */
	lua_pushboolean(L,
#ifndef _WIN32
	 st.st_mode & (S_IRUSR | S_IRGRP | S_IROTH)
#else
	 st.st_mode & _S_IREAD
#endif
	);
	/* can anyone write to file? */
	lua_pushboolean(L,
#ifndef _WIN32
	 st.st_mode & (S_IWUSR | S_IWGRP | S_IWOTH)
#else
	 st.st_mode & _S_IWRITE
#endif
	);
	/* can anyone execute the file? */
	lua_pushboolean(L,
#ifndef _WIN32
	 st.st_mode & (S_IXUSR | S_IXGRP | S_IXOTH)
#else
	 st.st_mode & _S_IEXEC
#endif
	);
	if (more_info) {
	    /* is link? */
#ifndef _WIN32
	    lua_pushboolean(L, S_ISLNK(st.st_mode));
#else
	    size_t attr = GetFileAttributes(pathname);
	    lua_pushboolean(L, attr > 0 && (attr & FILE_ATTRIBUTE_REPARSE_POINT));
#endif
	    lua_pushnumber(L, st.st_size);  /* size in bytes */
	    lua_pushnumber(L, st.st_atime);  /* access time */
	    lua_pushnumber(L, st.st_mtime);  /* modification time */
	    lua_pushnumber(L, st.st_ctime);  /* creation time */
	    return 10;
	}
	return 5;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: filename (string), [modify_time (number)]
 * Returns: [boolean]
 */
static int
sys_utime (lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);
    struct utimbuf utb, *bp;
    int res;

    if (lua_gettop(L) == 1)
	bp = NULL;
    else {
	utb.modtime = utb.actime = (time_t) lua_tonumber(L, 2);
	bp = &utb;
    }
    res = !utime(filename, bp);
    if (res || SYS_ERRNO == ENOENT) {
	lua_pushboolean(L, res);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: filename (string)
 * Returns: [boolean]
 */
static int
sys_remove (lua_State *L)
{
    const char *filename = luaL_checkstring(L, 1);
    int res;

    sys_vm_leave();
#ifndef _WIN32
    res = remove(filename);
#else
    res = !DeleteFile(filename);
#endif
    sys_vm_enter();

    if (!res) {
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: existing_filename (string), new_filename (string)
 * Returns: [boolean]
 */
static int
sys_rename (lua_State *L)
{
    const char *old = luaL_checkstring(L, 1);
    const char *new = luaL_checkstring(L, 2);
    int res;

    sys_vm_leave();
#ifndef _WIN32
    res = rename(old, new);
#else
    res = !MoveFile(old, new);
#endif
    sys_vm_enter();

    if (!res) {
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: [pathname (string)]
 * Returns: [boolean | pathname (string)]
 */
static int
sys_curdir (lua_State *L)
{
    const char *pathname = lua_tostring(L, 1);

    if (pathname) {
#ifndef _WIN32
	if (!chdir(pathname)) {
#else
	if (SetCurrentDirectory(pathname)) {
#endif
	    lua_pushboolean(L, 1);
	    return 1;
	}
    } else {
	char path[MAX_PATH];
#ifndef _WIN32
	if (getcwd(path, MAX_PATH)) {
	    lua_pushstring(L, path);
#else
	int n = GetCurrentDirectory(MAX_PATH, path);
	if (n && n < MAX_PATH) {
	    lua_pushlstring(L, path, n);
#endif
	    return 1;
	}
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: path (string), [permissions (number)]
 * Returns: [boolean]
 */
static int
sys_mkdir (lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);

#ifndef _WIN32
    mode_t perm = (mode_t) lua_tonumber(L, 2);

    if (!mkdir(path, perm)) {
#else
    if (CreateDirectory(path, NULL)) {
#endif
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: path (string)
 * Returns: [boolean]
 */
static int
sys_rmdir (lua_State *L)
{
    const char *path = luaL_checkstring(L, 1);

#ifndef _WIN32
    if (!rmdir(path)) {
#else
    if (RemoveDirectory(path)) {
#endif
	lua_pushboolean(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}


/*
 * Arguments: ..., directory (string)
 */
static int
sys_dir_open (lua_State *L, const int idx, struct dir *dp)
{
    const char *dir = luaL_checkstring(L, idx);

#ifndef _WIN32
    if (dp->data)
	closedir(dp->data);
    dp->data = opendir(*dir == '\0' ? "/" : dir);
    return dp->data ? 1 : 0;
#else
    char *filename = dp->data.cFileName;

    if (*dir == '\0') {
	dp->is_drive = 1;

	/* list drive letters */
	*filename++ = 'A' - 1;
	*filename++ = ':';
	*filename++ = '\\';
	*filename = '\0';
    } else {
	const int len = lua_strlen(L, idx);

	dp->is_drive = 0;

	/* build search path */
	if (len >= MAX_PATH - 2)  /* concat "\\*" */
	    return 0;
	memcpy(filename, dir, len);
	filename += len - 1;
	if (*filename != '\\' || *filename != '/')
	    *(++filename) = '\\';
	*(++filename) = '*';
	*(++filename) = '\0';

	if (dp->h != INVALID_HANDLE_VALUE)
	    FindClose(dp->h);
	dp->h = FindFirstFile((const char *) dp->data.cFileName, &dp->data);
    }
    return 1;
#endif
}

/*
 * Arguments: [directory (string)]
 * Returns: [dir_udata]
 */
static int
sys_dir (lua_State *L)
{
    struct dir *dp = lua_newuserdata(L, sizeof(struct dir));

    luaL_getmetatable(L, DIR_TYPENAME);
    lua_setmetatable(L, -2);
    if (lua_gettop(L) == 1) {
#ifndef _WIN32
	dp->data = NULL;
#else
	dp->h = INVALID_HANDLE_VALUE;
#endif
	return 1;
    }
    return sys_dir_open(L, 1, dp);
}

/*
 * Arguments: dir_udata
 */
static int
sys_dir_close (lua_State *L)
{
    struct dir *dp = checkudata(L, 1, DIR_TYPENAME);

#ifndef _WIN32
    if (dp->data) {
	closedir(dp->data);
	dp->data = NULL;
    }
#else
    if (dp->h != INVALID_HANDLE_VALUE) {
	FindClose(dp->h);
	dp->h = INVALID_HANDLE_VALUE;
    }
#endif
    return 0;
}

/*
 * Arguments: dir_udata, directory (string)
 *
 * Returns: [filename (string), is_directory (boolean)]
 * |
 * Returns (win32): [drive letter (string: A: .. Z:), drive type (string)]
 */
static int
sys_dir_next (lua_State *L)
{
    struct dir *dp = checkudata(L, 1, DIR_TYPENAME);

    if (lua_gettop(L) == 2) {  /* `for' start? */
	/* return generator (dir_udata) */
	lua_pushvalue(L, 1);
	return sys_dir_open(L, 2, dp);
    } else {  /* `for' step */
	char *filename;

#ifndef _WIN32
	struct dirent *entry;

	if (!dp->data)
	    return 0;
	do {
	    entry = readdir(dp->data);
	    if (!entry) {
		closedir(dp->data);
		dp->data = NULL;
		return 0;
	    }
	    filename = entry->d_name;
	} while (filename[0] == '.' && (filename[1] == '\0'
	 || (filename[1] == '.' && filename[2] == '\0')));

	lua_pushstring(L, filename);
	lua_pushboolean(L, entry->d_type & DT_DIR);
	return 2;
#else
	int is_dots;

	filename = dp->data.cFileName;

	if (dp->is_drive) {
	    while (++*filename <= 'Z') {
		const char *type;

		switch (GetDriveType(filename)) {
		case DRIVE_REMOVABLE:	type = "removable"; break;
		case DRIVE_FIXED:	type = "fixed"; break;
		case DRIVE_REMOTE:	type = "remote"; break;
		case DRIVE_CDROM:	type = "cdrom"; break;
		case DRIVE_RAMDISK:	type = "ramdisk"; break;
		default: continue;
		}
		lua_pushlstring(L, filename, 2);
		lua_pushstring(L, type);
		return 2;
	    }
	    return 0;
	}

	if (dp->h == INVALID_HANDLE_VALUE)
	    return 0;
	do {
	    is_dots = 1;
	    if (!(filename[0] == '.' && (filename[1] == '\0'
	     || (filename[1] == '.' && filename[2] == '\0')))) {
		lua_pushstring(L, (const char *) filename);
		lua_pushboolean(L,
		 dp->data.dwFileAttributes & FILE_ATTRIBUTE_DIRECTORY);
		is_dots = 0;
	    }
	    if (!FindNextFile(dp->h, &dp->data)) {
		FindClose(dp->h);
		dp->h = INVALID_HANDLE_VALUE;
		return is_dots ? 0 : 2;
	    }
	} while (is_dots);
	return 2;
#endif
    }
}


static luaL_reg dir_meth[] = {
    {"__call",		sys_dir_next},
    {"__gc",		sys_dir_close},
    {NULL, NULL}
};
