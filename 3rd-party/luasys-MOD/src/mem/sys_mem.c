/* Lua System: Memory Buffers */

#include "../common.h"


#ifdef _WIN32

#define SYSMEM_HAVE_MMAP

#else

#include <sys/stat.h>
#include <sys/mman.h>

#ifdef _POSIX_MAPPED_FILES
#define SYSMEM_HAVE_MMAP
#endif

#endif


#define MEM_TYPENAME	"sys.mem.pointer"

#define BUFF_INITIALSIZE	128

void sys_vm_enter (void) {}; // Added for MurgaLua
void sys_vm_leave (void) {}; // Added for MurgaLua

struct membuf {
    char *data;
    int len, offset;

#define SYSMEM_TYPE_SHIFT	8
#define SYSMEM_TCHAR		((0  << SYSMEM_TYPE_SHIFT) | sizeof(char))
#define SYSMEM_TUCHAR		((1  << SYSMEM_TYPE_SHIFT) | sizeof(unsigned char))
#define SYSMEM_TSHORT		((2  << SYSMEM_TYPE_SHIFT) | sizeof(short))
#define SYSMEM_TUSHORT		((3  << SYSMEM_TYPE_SHIFT) | sizeof(unsigned short))
#define SYSMEM_TINT		((4  << SYSMEM_TYPE_SHIFT) | sizeof(int))
#define SYSMEM_TUINT		((5  << SYSMEM_TYPE_SHIFT) | sizeof(unsigned int))
#define SYSMEM_TLONG		((6  << SYSMEM_TYPE_SHIFT) | sizeof(long))
#define SYSMEM_TULONG		((7  << SYSMEM_TYPE_SHIFT) | sizeof(unsigned long))
#define SYSMEM_TFLOAT		((8  << SYSMEM_TYPE_SHIFT) | sizeof(float))
#define SYSMEM_TDOUBLE		((9  << SYSMEM_TYPE_SHIFT) | sizeof(double))
#define SYSMEM_TNUMBER		((10 << SYSMEM_TYPE_SHIFT) | sizeof(lua_Number))
#define SYSMEM_TBITSTRING	((11 << SYSMEM_TYPE_SHIFT) | sizeof(unsigned char))
#define SYSMEM_SIZE_MASK	0x00FF
#define SYSMEM_TYPE_MASK	0xFFFF

#define SYSMEM_UDATA		0x010000  /* memory allocated as userdata */
#define SYSMEM_ALLOC		0x020000  /* memory allocated */
#define SYSMEM_MAP		0x080000  /* memory mapped */
#define SYSMEM_BUFFLUSH		0x100000  /* auto-flush the buffer */
#define SYSMEM_ISTREAM		0x200000  /* buffer assosiated with input streams */
#define SYSMEM_OSTREAM		0x400000  /* buffer assosiated with output streams */
    unsigned int flags;
};

#define memisptr(mb)		(!((mb)->flags & (SYSMEM_UDATA | SYSMEM_ALLOC | SYSMEM_MAP)))
#define memtype(mb)		((mb)->flags & SYSMEM_TYPE_MASK)
#define memtypesize(mb)		((mb)->flags & SYSMEM_SIZE_MASK)
#define memlen(type, nitems)	((type) != SYSMEM_TBITSTRING				\
				 ? (nitems) * ((type) & SYSMEM_SIZE_MASK)		\
				 : ((nitems) >> 3) + 1)

static const int type_flags[] = {
    SYSMEM_TCHAR, SYSMEM_TUCHAR, SYSMEM_TSHORT, SYSMEM_TUSHORT,
    SYSMEM_TINT, SYSMEM_TUINT, SYSMEM_TLONG, SYSMEM_TULONG,
    SYSMEM_TFLOAT, SYSMEM_TDOUBLE, SYSMEM_TNUMBER, SYSMEM_TBITSTRING
};

static const char *const type_names[] = {
    "char", "uchar", "short", "ushort", "int", "uint", "long", "ulong",
    "float", "double", "number", "bitstring", NULL
};

/* MemBuffer metatable reserved indexes */
enum {
    SYSMEM_IDENT = 1,
    SYSMEM_ENVIRON
};


static int membuf_addlstring (lua_State *L, struct membuf *mb,
                              const char *s, size_t n);


static struct membuf *
mem_tobuffer (lua_State *L, int idx)
{
    struct membuf *mb = lua_touserdata(L, idx);

    if (mb && lua_getmetatable(L, idx)) {
	unsigned long id;

	lua_rawgeti(L, -1, SYSMEM_IDENT);
	id = (unsigned long) lua_tonumber(L, -1);
	lua_pop(L, 2);
	if (id == (unsigned long) luaopen_sys_mem)
	    return mb;
    }
    return NULL;
}

/*
 * Arguments: ..., {string | membuf_udata}
 */
int
sys_buffer_read (lua_State *L, int idx, struct sys_buffer *sb)
{
    struct membuf *mb = mem_tobuffer(L, idx);

    if (mb) {
	sb->ptr.r = mb->data;
	sb->size = mb->offset;
	sb->mb = mb;
	return 1;
    }
    else {
	sb->ptr.r = lua_tolstring(L, idx, &sb->size);
	if (sb->ptr.r) {
	    sb->mb = NULL;
	    return 1;
	}
    }
    return 0;
}

void
sys_buffer_readed (struct sys_buffer *sb, size_t n)
{
    struct membuf *mb = sb->mb;

    if (!mb) return;

    if (mb->offset == (int) n)
	mb->offset = 0;
    else {
	/* move tail */
	mb->offset -= n;
	memmove(mb->data, mb->data + n, mb->offset);
    }
}

/*
 * Arguments: ..., [membuf_udata]
 */
void
sys_buffer_write (lua_State *L, int idx, struct sys_buffer *sb,
                  char *buf, size_t buflen)
{
    struct membuf *mb = mem_tobuffer(L, idx);

    if (mb) {
	sb->ptr.w = mb->data + mb->offset;
	sb->size = mb->len - mb->offset;
	sb->mb = mb;
    }
    else {
	sb->ptr.w = buf;
	sb->size = buflen;
	sb->mb = NULL;
    }
}

int
sys_buffer_written (lua_State *L, struct sys_buffer *sb, char *buf)
{
    struct membuf *mb = sb->mb;

    if (mb) {
	const size_t len = mb->len;

	mb->offset = len;
	if (!membuf_addlstring(L, mb, NULL, 0))
	    return 0;
	sb->ptr.w = mb->data + mb->offset;
	sb->size = mb->len - mb->offset;
    }
    else {
	struct sys_buffer *osb = (void *) buf;
	size_t size;
	char *p;

	if (sb->ptr.w == buf) {
	    size = sb->size;
	    p = malloc(2 * size);
	    if (!p) return 0;
	    memcpy(p, buf, size);
	}
	else {
	    size = 2 * osb->size;
	    p = realloc(osb->ptr.w, 2 * size);
	    if (!p) return 0;
	    sb->size = size;
	}
	sb->ptr.w = p + size;
	osb->ptr.w = p;
	osb->size = size;
    }
    return 1;
}

int
sys_buffer_push (lua_State *L, struct sys_buffer *sb, char *buf, size_t tail)
{
    struct membuf *mb = sb->mb;

    if (mb) {
	mb->offset += tail;
	return 0;
    }
    else {
	if (sb->ptr.w == buf)
	    lua_pushlstring(L, buf, tail);
	else {
	    struct sys_buffer *osb = (void *) buf;
	    lua_pushlstring(L, osb->ptr.w, osb->size + tail);
	    free(osb->ptr.w);
	}
	return 1;
    }
}


/*
 * Arguments: [num_bytes (number)]
 * Returns: membuf_udata
 */
static int
mem_new (lua_State *L)
{
    const size_t len = lua_tointeger(L, 1);
    struct membuf *mb = lua_newuserdata(L, sizeof(struct membuf) + len);

    memset(mb, 0, sizeof(struct membuf) + len);
    mb->flags = SYSMEM_TCHAR;
    if (len) {
	mb->data = (char *) (mb + 1);
	mb->len = len;
	mb->flags |= SYSMEM_UDATA;
    }

    luaL_getmetatable(L, MEM_TYPENAME);
    lua_rawgeti(L, -1, SYSMEM_ENVIRON);
    lua_setfenv(L, -3);
    lua_setmetatable(L, -2);
    return 1;
}

/*
 * Arguments: membuf_udata, [type (string)]
 * Returns: membuf_udata | type (string)
 */
static int
mem_type (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (lua_gettop(L) > 1) {
	const int type = type_flags[luaL_checkoption(L, 2, NULL, type_names)];

	mb->flags &= ~SYSMEM_TYPE_MASK;
	mb->flags |= type;
	lua_settop(L, 1);
    }
    else {
	lua_pushstring(L,
	 type_names[(mb->flags & SYSMEM_TYPE_MASK) >> SYSMEM_TYPE_SHIFT]);
    }
    return 1;
}

/*
 * Arguments: membuf_udata
 * Returns: size (number)
 */
static int
mem_typesize (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    lua_pushinteger(L, memtypesize(mb));
    return 1;
}

/*
 * Arguments: membuf_udata, [num_bytes (number), zerofill (boolean)]
 * Returns: [membuf_udata]
 */
static int
mem_alloc (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int len = luaL_optinteger(L, 2, BUFF_INITIALSIZE);
    const int zerofill = lua_isboolean(L, -1) && lua_toboolean(L, -1);

    mb->flags |= SYSMEM_ALLOC;
    mb->len = len;
    mb->offset = 0;
    mb->data = zerofill ? calloc(len, 1) : malloc(len);
    lua_settop(L, 1);
    return mb->data ? 1 : 0;
}

/*
 * Arguments: membuf_udata, num_bytes (number)
 * Returns: [membuf_udata]
 */
static int
mem_realloc (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int len = luaL_checkinteger(L, 2);
    void *p = realloc(mb->data, len);

    if (!p) return 0;
    mb->data = p;
    mb->len = len;
    lua_settop(L, 1);
    return 1;
}


#ifdef SYSMEM_HAVE_MMAP

/*
 * Arguments: membuf_udata, fd_udata, [protection (string: "rw"),
 *	offset (number), num_bytes (number), private/shared (boolean)]
 * Returns: [membuf_udata]
 */
static int
mem_map (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int *fdp = checkudata(L, 2, FD_TYPENAME);
    int fd = fdp ? *fdp : -1;  /* named or anonymous mapping */
    const char *protstr = lua_tostring(L, 3);
    off_t off = (off_t) lua_tonumber(L, 4);
    size_t len = (size_t) lua_tonumber(L, 5);
    const int is_private = lua_isboolean(L, -1) && lua_toboolean(L, -1);
    int prot = 0, flags;
    void *ptr;

    sys_vm_leave();
#ifndef _WIN32
#ifndef MAP_ANON
    int is_anon = 0;
#endif
    /* length */
    if (!len) {
	struct stat sb;
	if (fd == -1 || fstat(fd, &sb) == -1)
	    goto err;
	len = sb.st_size - off;
    }
    /* protection and flags */
    prot = PROT_READ;
    if (protstr) {
	if (protstr[0] == 'w')
	    prot = PROT_WRITE;
	else if (protstr[1] == 'w')
	    prot |= PROT_WRITE;
    }
    flags = is_private ? MAP_PRIVATE : MAP_SHARED;
    /* anonymous shared memory? */
    if (fd == -1) {
#ifdef MAP_ANON
	flags |= MAP_ANON;
#else
	if ((fd = open("/dev/zero", O_RDWR)) == -1)
	    goto err;
	is_anon = 1;
#endif
    }
    /* map file to memory */
    ptr = mmap(0, len, prot, flags, (int) fd, off);
#ifndef MAP_ANON
    if (is_anon) close(fd);
#endif
    if (ptr == MAP_FAILED) goto err;

#else
    /* length */
    if (!len) {
	if (fd == -1) goto err;
	len = GetFileSize((HANDLE) fd, NULL);
	if (len == INVALID_FILE_SIZE)
	    goto err;
	len -= off;
    }
    /* protection and flags */
    if (protstr && (protstr[0] == 'w' || protstr[1] == 'w')) {
	prot = PAGE_READWRITE;
	flags = FILE_MAP_WRITE;
    } else {
	prot = PAGE_READONLY;
	flags = FILE_MAP_READ;
    }
    if (is_private) {
	prot = PAGE_WRITECOPY;
	flags = FILE_MAP_COPY;
    }
    /* map file to memory */
    {
	HANDLE hMap = CreateFileMapping((HANDLE) fd, NULL, prot, 0, len, NULL);
	if (!hMap) goto err;
	ptr = MapViewOfFile(hMap, flags, 0, off, len);
	CloseHandle(hMap);
	if (!ptr) goto err;
    }
#endif /* !Win32 */
    sys_vm_enter();

    mb->flags |= SYSMEM_MAP;
    mb->len = len;
    mb->data = ptr;
    lua_settop(L, 1);
    return 1;
 err:
    sys_vm_enter();
    return sys_seterror(L, 0);
}

/*
 * Arguments: membuf_udata
 * Returns: [membuf_udata]
 */
static int
mem_sync (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    int res;

    sys_vm_leave();
#ifndef _WIN32
    res = msync(mb->data, mb->len, MS_SYNC);
#else
    res = !FlushViewOfFile(mb->data, 0);
#endif
    sys_vm_enter();

    return !res ? 1 : 0;
}

#endif /* SYSMEM_HAVE_MMAP */


/*
 * Arguments: membuf_udata
 * Returns: membuf_udata
 */
static int
mem_free (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (mb->data) {
	const unsigned int mb_flags = mb->flags;

	if (mb_flags & (SYSMEM_ISTREAM | SYSMEM_OSTREAM)) {
	    lua_getfenv(L, 1);  /* input streams */
	    lua_pushnil(L);
	    lua_rawseti(L, -2, (int) mb);
	    lua_rawgeti(L, -1, 0);  /* output streams */
	    lua_pushnil(L);
	    lua_rawseti(L, -2, (int) mb);
	    lua_settop(L, 1);
	}

	switch (mb_flags & (SYSMEM_ALLOC | SYSMEM_MAP)) {
	case SYSMEM_ALLOC:
	    free(mb->data);
	    break;
#ifdef SYSMEM_HAVE_MMAP
	case SYSMEM_MAP:
#ifndef _WIN32
	    munmap(mb->data, mb->len);
#else
	    UnmapViewOfFile(mb->data);
#endif
	    break;
#endif /* SYSMEM_HAVE_MMAP */
	}
	mb->data = NULL;
	mb->flags &= SYSMEM_TYPE_MASK;
    }
    return 1;
}

/*
 * Arguments: membuf_udata, source (membuf_udata), num_bytes (number)
 * Returns: [membuf_udata]
 */
static int
mem_memcpy (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    struct membuf *src = checkudata(L, 2, MEM_TYPENAME);
    const int len = luaL_checkinteger(L, 3);

    lua_settop(L, 1);
    return memcpy(mb->data, src->data, len) ? 1 : 0;
}

/*
 * Arguments: membuf_udata, byte (number), num_bytes (number)
 * Returns: [membuf_udata]
 */
static int
mem_memset (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int ch = lua_tointeger(L, 2);
    const int len = luaL_checkinteger(L, 3);

    lua_settop(L, 1);
    return memset(mb->data, ch, len) ? 1 : 0;
}

/*
 * Arguments: membuf_udata, [num_bytes (number)]
 * Returns: membuf_udata | num_bytes (number)
 */
static int
mem_length (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);

    if (lua_gettop(L) == 1)
	lua_pushinteger(L, mb->len);
    else {
	if (mb->flags & SYSMEM_MAP)
	    luaL_argerror(L, 1, "membuf is mapped");

	mb->len = lua_tointeger(L, 2);
	lua_settop(L, 1);
    }
    return 1;
}

/*
 * Arguments: membuf_udata, [offset (number), target (membuf_udata)]
 * Returns: membuf_udata | pointer (ludata) | target (membuf_udata)
 */
static int
mem_call (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    void *ptr = mb->data + memtypesize(mb) * lua_tointeger(L, 2);
    struct membuf *mb2 = lua_isuserdata(L, 3) ? checkudata(L, 3, MEM_TYPENAME) : NULL;

    if (mb2) {
	mb2->data = ptr;
    } else if (memisptr(mb)) {
	mb->data = ptr;
	lua_settop(L, 1);
    } else {
	lua_pushlightuserdata(L, ptr);
    }
    return 1;
}

/*
 * Arguments: membuf_udata, offset (number)
 * Returns: value
 */
static int
mem_index (lua_State *L)
{
    if (lua_type(L, 2) == LUA_TNUMBER) {
	struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
	const int off = lua_tointeger(L, 2);
	const int type = memtype(mb);
	char *ptr = mb->data + memlen(type, off);

	switch (type) {
	case SYSMEM_TCHAR: lua_pushnumber(L, *((char *) ptr)); break;
	case SYSMEM_TUCHAR: lua_pushnumber(L, *((unsigned char *) ptr)); break;
	case SYSMEM_TSHORT: lua_pushnumber(L, *((short *) ptr)); break;
	case SYSMEM_TUSHORT: lua_pushnumber(L, *((unsigned short *) ptr)); break;
	case SYSMEM_TINT: lua_pushinteger(L, *((int *) ptr)); break;
	case SYSMEM_TUINT: lua_pushinteger(L, *((unsigned int *) ptr)); break;
	case SYSMEM_TLONG: lua_pushnumber(L, *((long *) ptr)); break;
	case SYSMEM_TULONG: lua_pushnumber(L, *((unsigned long *) ptr)); break;
	case SYSMEM_TFLOAT: lua_pushnumber(L, *((float *) ptr)); break;
	case SYSMEM_TDOUBLE: lua_pushnumber(L, *((double *) ptr)); break;
	case SYSMEM_TNUMBER: lua_pushnumber(L, *((lua_Number *) ptr)); break;
	case SYSMEM_TBITSTRING: lua_pushboolean(L, *(ptr - 1) & (1 << (off & 7))); break;
	}
    } else {
	lua_getmetatable(L, 1);
	lua_replace(L, 1);
	lua_rawget(L, 1);
    }
    return 1;
}

/*
 * Arguments: membuf_udata, offset (number), value
 */
static int
mem_newindex (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int off = lua_tointeger(L, 2);
    const int type = memtype(mb);
    char *ptr = mb->data + memlen(type, off);

    switch (lua_type(L, 3)) {
    case LUA_TNUMBER: {
	    lua_Number num = lua_tonumber(L, 3);

	    switch (type) {
	    case SYSMEM_TCHAR: *((char *) ptr) = (char) num; break;
	    case SYSMEM_TUCHAR: *((unsigned char *) ptr) = (unsigned char) num; break;
	    case SYSMEM_TSHORT: *((short *) ptr) = (short) num; break;
	    case SYSMEM_TUSHORT: *((unsigned short *) ptr) = (unsigned short) num; break;
	    case SYSMEM_TINT: *((int *) ptr) = (int) num; break;
	    case SYSMEM_TUINT: *((unsigned int *) ptr) = (unsigned int) num; break;
	    case SYSMEM_TLONG: *((long *) ptr) = (long) num; break;
	    case SYSMEM_TULONG: *((unsigned long *) ptr) = (unsigned long) num; break;
	    case SYSMEM_TFLOAT: *((float *) ptr) = (float) num; break;
	    case SYSMEM_TDOUBLE: *((double *) ptr) = (double) num; break;
	    case SYSMEM_TNUMBER: *((lua_Number *) ptr) = num; break;
	    case SYSMEM_TBITSTRING: luaL_typerror(L, 3, "boolean"); break;
	    }
	}
	break;
    case LUA_TBOOLEAN:
	if (type != SYSMEM_TBITSTRING)
	    luaL_typerror(L, 1, "bitstring");
	else {
	    const int bit = 1 << (off & 7);

	    --ptr;  /* correct address */
	    if (lua_toboolean(L, 3)) *ptr |= bit;  /* set */
	    else *ptr &= ~bit;  /* clear */
	}
	break;
    case LUA_TSTRING:
	{
	    size_t len;
	    const char *s = lua_tolstring(L, 3, &len);

	    memcpy(ptr, s, len);
	}
	break;
    default:
	luaL_typerror(L, 3, "membuf value");
    }
    return 0;
}

/*
 * Arguments: membuf_udata, num_bytes (number)
 * Returns: string
 */
static int
mem_tostring (lua_State *L)
{
    struct membuf *mb = checkudata(L, 1, MEM_TYPENAME);
    const int len = luaL_checkinteger(L, 2);

    lua_pushlstring(L, mb->data, len);
    return 1;
}


#include "membuf.c"


static luaL_reg mem_meth[] = {
    {"type",		mem_type},
    {"typesize",	mem_typesize},
    {"alloc",		mem_alloc},
    {"realloc",		mem_realloc},
#ifdef SYSMEM_HAVE_MMAP
    {"map",		mem_map},
    {"sync",		mem_sync},
#endif
    {"free",		mem_free},
    {"__gc",		mem_free},
    {"memcpy",		mem_memcpy},
    {"memset",		mem_memset},
    {"length",		mem_length},
    {"__len",		mem_length},
    {"__call",		mem_call},
    {"__index",		mem_index},
    {"__newindex",	mem_newindex},
    /* stream operations */
    {"write",		membuf_write},
    {"writeln",		membuf_writeln},
    {"getstring",	membuf_getstring},
    {"__tostring",	membuf_getstring},
    {"seek",		membuf_seek},
    {"output",		membuf_output},
    {"input",		membuf_input},
    {"read",		membuf_read},
    {"flush",		membuf_flush},
    {"close",		membuf_close},
    {NULL, NULL}
};

static luaL_reg memlib[] = {
    {"pointer",		mem_new},
    {"tostring",	mem_tostring},
    {NULL, NULL}
};

/*
 * Arguments: ..., mem_lib (table)
 */
static void
createmeta (lua_State *L)
{
    luaL_newmetatable(L, MEM_TYPENAME);

    /* identifier */
    lua_pushnumber(L, (unsigned long) luaopen_sys_mem);
    lua_rawseti(L, -2, SYSMEM_IDENT);

    /* environ. table: assosiated i/o streams */
    lua_newtable(L);  /* input streams: {num(membuf_udata) => object} | {0 => out_table} */
    lua_newtable(L);  /* output streams: {num(membuf_udata) => object} */
    lua_rawseti(L, -2, 0);
    lua_rawseti(L, -2, SYSMEM_ENVIRON);

    luaL_register(L, NULL, mem_meth);
}

void
luaopen_sys_mem (lua_State *L)
{
    luaL_register(L, "sys.mem", memlib);
    createmeta(L);
    lua_pop(L, 2);
}

