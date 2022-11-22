/* Lua System: Networking */

#include "../common.h"

#ifdef _WIN32

#include <mswsock.h>	/* TransmitFile */

#define IS_OVERLAPPED	(is_WinNT ? WSA_FLAG_OVERLAPPED : 0)

#define INET_ATON

#define SHUT_WR		SD_SEND

typedef long		ssize_t;
typedef int		socklen_t;

#undef EINTR
#define EINTR		WSAEINTR
#define EINPROGRESS	WSAEINPROGRESS
#define EALREADY	WSAEALREADY

#define SOCK_ERRNO	WSAGetLastError()

#else

#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>	/* TCP_NODELAY */
#include <netdb.h>

extern int h_errno;
#define SOCK_ERRNO	h_errno

#ifdef __linux
#include <sys/sendfile.h>	/* sendfile */
#else
#include <sys/uio.h>		/* sendfile */
#endif

#ifdef __sun
    #include <sys/filio.h>	/* FIONBIO */
#else
    #include <sys/ioctl.h>	/* FIONBIO */
#endif

#define ioctlsocket	ioctl

#endif /* !WIN32 */


#define SD_TYPENAME	"sys.sock.handle"

struct sock_addr {
    socklen_t addrlen;
#define	SA_PREFIX	sizeof(size_t)
    struct sockaddr addr;
};


/*
 * Returns: string
 */
static int
sock_strerror (lua_State *L)
{
    const int err = SOCK_ERRNO;
#ifndef _WIN32
    const char *s = hstrerror(err);
#else
    static HANDLE hDLL = NULL;
    char s[256];

    if (hDLL == NULL)
	hDLL = LoadLibraryEx("netmsg.dll", NULL,
	 DONT_RESOLVE_DLL_REFERENCES | LOAD_LIBRARY_AS_DATAFILE);

    if (hDLL != NULL
     && FormatMessage(FORMAT_MESSAGE_IGNORE_INSERTS
     | FORMAT_MESSAGE_FROM_SYSTEM | FORMAT_MESSAGE_FROM_HMODULE,
     hDLL, err, MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
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
static int
sock_seterror (lua_State *L)
{
    lua_pushnil(L);
    sock_strerror(L);
    lua_pushvalue(L, -1);
    lua_setglobal(L, "errorMessage");
    return 2;
}


/*
 * Returns: sd_udata
 */
static int
sock_new (lua_State *L)
{
    lua_boxpointer(L, (void *) -1);
    luaL_getmetatable(L, SD_TYPENAME);
    lua_setmetatable(L, -2);
    return 1;
}

#ifdef _WIN32
static int
sock_pair (int type, sd_t sv[2])
{
    struct sockaddr_in sa;
    sd_t sd;
    int res = -1, len = sizeof(struct sockaddr_in);

    sa.sin_family = PF_INET;
    sa.sin_port = 0;
    sa.sin_addr.s_addr = htonl(INADDR_LOOPBACK);

    if ((sd = WSASocket(PF_INET, type, 0, NULL, 0, IS_OVERLAPPED)) != -1) {
	if (!bind(sd, (struct sockaddr *) &sa, len)
	 && !listen(sd, 1)
	 && !getsockname(sd, (struct sockaddr *) &sa, &len)
	 && (sv[0] = WSASocket(PF_INET, type, 0, NULL, 0, IS_OVERLAPPED)) != -1) {
	    if (!connect(sv[0], (struct sockaddr *) &sa, len)
	     && (sv[1] = accept(sd, (struct sockaddr *) &sa, &len)) != -1)
		res = 0;
	    else
		closesocket(sv[0]);
	}
	closesocket(sd);
    }
    return res;
}
#endif

/*
 * Arguments: sd_udata, [type ("stream", "dgram"), domain ("inet", "unix"),
 *	sd_udata (socketpair)]
 * Returns: [sd_udata]
 */
static int
sock_socket (lua_State *L)
{
    sd_t *sdp = checkudata(L, 1, SD_TYPENAME);
    const char *typep = lua_tostring(L, 2);
    const char *domainp = lua_tostring(L, 3);
    int type = SOCK_STREAM, domain = PF_INET;
    sd_t sd, sv[2];
    sd_t *pair_sdp = (lua_gettop(L) > 1 && lua_isuserdata(L, -1))
     ? checkudata(L, -1, SD_TYPENAME) : NULL;

    if (typep && typep[0] == 'd')
	type = SOCK_DGRAM;
    if (domainp && domainp[0] == 'u')
	domain = PF_UNIX;

#ifndef _WIN32
    sd = (pair_sdp) ? socketpair(PF_UNIX, type, 0, sv)
     : socket(domain, type, 0);
#else
    sd = (pair_sdp) ? sock_pair(type, sv)
     : WSASocket(domain, type, 0, NULL, 0, IS_OVERLAPPED);
#endif

    if (sd != -1) {
	if (pair_sdp) {
	    *sdp = sv[0];
	    *pair_sdp = sv[1];
	} else
	    *sdp = sd;
	lua_settop(L, 1);
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata
 * Returns: [boolean, sd_udata]
 */
static int
sock_close (lua_State *L)
{
    sd_t *sdp = checkudata(L, 1, SD_TYPENAME);

    if (*sdp != (sd_t) -1) {
#ifndef _WIN32
	int res;

	do res = close(*sdp);
	while (res == -1 && SOCK_ERRNO == EINTR);
	lua_pushboolean(L, !res);
#else
	lua_pushboolean(L, !closesocket(*sdp));
#endif
	*sdp = (sd_t) -1;
	return 1;
    }
    return 0;
}

/*
 * Arguments: sd_udata
 * Returns: [sd_udata]
 */
static int
sock_shutdown (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);

    /* SHUT_RD (SD_RECEIVE) has different behavior in unix and win32 */
    if (!shutdown(sd, SHUT_WR)) {
	lua_settop(L, 1);
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata, nonblocking (boolean)
 * Returns: [sd_udata]
 */
static int
sock_nonblocking (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    unsigned long opt = lua_toboolean(L, 2);

    lua_settop(L, 1);
    return !ioctlsocket(sd, FIONBIO, &opt) ? 1
     : sock_seterror(L);
}

/*
 * Arguments: sd_udata, option (string),
 *	[value_lo (number), value_hi (number)]
 * Returns: [sd_udata | value_lo (number), value_hi (number)]
 */
static int
sock_sockopt (lua_State *L)
{
    static const int opt_flags[] = {
	SO_REUSEADDR, SO_TYPE, SO_ERROR, SO_DONTROUTE,
	SO_SNDBUF, SO_RCVBUF, SO_SNDLOWAT, SO_RCVLOWAT,
	SO_BROADCAST, SO_KEEPALIVE, SO_OOBINLINE, SO_LINGER,
#define OPTNAMES_TCP	12
	TCP_NODELAY
    };
    static const char *const opt_names[] = {
	"reuseaddr", "type", "error", "dontroute",
	"sndbuf", "rcvbuf", "sndlowat", "rcvlowat",
	"broadcast", "keepalive", "oobinline", "linger",
	"tcp_nodelay", NULL
    };
#undef OPT_START
#define OPT_START	2
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    const int optname = luaL_checkoption(L, OPT_START, NULL, opt_names);
    const int level = (optname < OPTNAMES_TCP) ? SOL_SOCKET : IPPROTO_TCP;
    const int optflag = opt_flags[optname];
    int optval[4];
    socklen_t optlen = sizeof(int);
    const int nargs = lua_gettop(L);

    if (nargs > OPT_START) {
	optval[0] = lua_tointeger(L, OPT_START + 1);
	if (nargs > OPT_START + 1) {
	    optval[1] = lua_tointeger(L, OPT_START + 2);
	    optlen *= 2;
	}
	if (!setsockopt(sd, level, optflag, (char *) &optval, optlen)) {
	    lua_settop(L, 1);
	    return 1;
	}
    }
    else if (!getsockopt(sd, level, optflag, (char *) &optval, &optlen)) {
	lua_pushinteger(L, optval[0]);
	if (optlen <= sizeof(int))
	    return 1;
	lua_pushinteger(L, optval[1]);
	return 2;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: sd_udata, sock_addr_udata
 * Returns: [sd_udata]
 */
static int
sock_bind (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    struct sock_addr *sap = lua_touserdata(L, 2);

    if (!sap) luaL_typerror(L, 2, "socket address");

    if (!bind(sd, &sap->addr, sap->addrlen)) {
	lua_settop(L, 1);
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata, [backlog (number)]
 * Returns: [sd_udata]
 */
static int
sock_listen (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    const int backlog = luaL_optinteger(L, 2, SOMAXCONN);

    if (!listen(sd, backlog)) {
	lua_settop(L, 1);
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata, [sock_addr_udata]
 * Returns: [new_sd_udata | false (EAGAIN)]
 */
static int
sock_accept (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    struct sock_addr *from = lua_touserdata(L, 2);
    struct sockaddr *sap = NULL;
    socklen_t *lenp = NULL;

    if (from) {
	sap = &from->addr;
	lenp = &from->addrlen;
    }
#ifndef _WIN32
    do sd = accept(sd, sap, lenp);
    while (sd == -1 && SOCK_ERRNO == EINTR);
#else
    sd = accept(sd, sap, lenp);
#endif
    if (sd == (sd_t) -1 && SOCK_ERRNO == EAGAIN) {
	lua_pushboolean(L, 0);
	return 1;
    }
    if (sd != (sd_t) -1) {
	lua_boxpointer(L, (void *) sd);
	luaL_getmetatable(L, SD_TYPENAME);
	lua_setmetatable(L, -2);
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata, sock_addr_udata
 * Returns: [sd_udata | false (EINPROGRESS)]
 */
static int
sock_connect (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    struct sock_addr *sap = lua_touserdata(L, 2);
    int res;

    if (!sap) luaL_typerror(L, 2, "socket address");

    sys_vm_leave();
    do res = connect(sd, &sap->addr, sap->addrlen);
    while (res == -1 && SOCK_ERRNO == EINTR);
    sys_vm_enter();

    if (!res || SOCK_ERRNO == EINPROGRESS || SOCK_ERRNO == EALREADY) {
	if (res) lua_pushboolean(L, 0);
	else lua_settop(L, 1);
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata, [sock_addr_udata]
 * Returns: [sock_addr_udata]
 */
static int
sock_getpeername (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    struct sock_addr *sap = lua_touserdata(L, 2);

    if (!sap) sap = lua_newuserdata(L, sizeof(struct sock_addr));
    sap->addrlen = sizeof(struct sockaddr);
    if (!getpeername(sd, &sap->addr, &sap->addrlen)) {
	return 1;
    }
    return sock_seterror(L);
}

/*
 * Arguments: sd_udata, {string | membuf_udata},
 *	[to (sock_addr_udata), options (string) ...]
 * Returns: [success/partial (boolean), count (number)]
 */
static int
sock_send (lua_State *L)
{
    static const int o_flags[] = {
	MSG_OOB, MSG_DONTROUTE,
    };
    static const char *const o_names[] = {
	"oob", "dontroute", NULL
    };
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    const struct sock_addr *to = lua_touserdata(L, 3);
    struct sys_buffer sb;
    int nw;  /* number of chars actually send */
    unsigned int i, flags = 0;

    if (!sys_buffer_read(L, 2, &sb))
	luaL_argerror(L, 2, "buffer expected");
    for (i = lua_gettop(L); i > 3; --i) {
	flags |= o_flags[luaL_checkoption(L, i, NULL, o_names)];
    }
    sys_vm_leave();
    do nw = !to ? send(sd, sb.ptr.r, sb.size, flags)
     : sendto(sd, sb.ptr.r, sb.size, flags, &to->addr, to->addrlen);
    while (nw == -1 && SOCK_ERRNO == EINTR);
    sys_vm_enter();
    if (nw == -1) {
	if (SOCK_ERRNO != EAGAIN)
	    return sock_seterror(L);
	nw = 0;
    } else {
	sys_buffer_readed(&sb, nw);
    }
    lua_pushboolean(L, ((size_t) nw == sb.size));
    lua_pushinteger(L, nw);
    return 2;
}

/*
 * Arguments: sd_udata, [count (number) | membuf_udata,
 *	from (sock_addr_udata), options (string) ...]
 * Returns: [string | count (number) | false (EAGAIN)]
 */
static int
sock_recv (lua_State *L)
{
    static const int o_flags[] = {
	MSG_OOB, MSG_PEEK,
#ifndef _WIN32
	MSG_WAITALL
#endif
    };
    static const char *const o_names[] = {
	"oob", "peek",
#ifndef _WIN32
	"waitall",
#endif
	NULL
    };
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    struct sock_addr *from = lua_touserdata(L, 3);
    struct sockaddr *sap = NULL;
    socklen_t *lenp = NULL;
    unsigned int i, flags = 0;

    size_t n = !lua_isnumber(L, 2) ? ~((size_t) 0)
     : (size_t) lua_tonumber(L, 2);
    const size_t len = n;  /* how much total to read */
    size_t rlen;  /* how much to read */
    int nr;  /* number of bytes actually read */
    struct sys_buffer sb;
    char buf[SYS_BUFSIZE];

    sys_buffer_write(L, 2, &sb, buf, sizeof(buf));

    for (i = lua_gettop(L); i > 3; --i) {
	flags |= o_flags[luaL_checkoption(L, i, NULL, o_names)];
    }
    if (from) {
	sap = &from->addr;
	lenp = &from->addrlen;
    }
    do {
	rlen = (n <= sb.size) ? n : sb.size;
	sys_vm_leave();
#ifndef _WIN32
	do nr = recvfrom(sd, sb.ptr.w, rlen, flags, sap, lenp);
	while (nr == -1 && SOCK_ERRNO == EINTR);
#else
	nr = recvfrom(sd, sb.ptr.w, rlen, flags, sap, lenp);
#endif
	sys_vm_enter();
	if (nr == -1) break;
	n -= nr;  /* still have to read `n' bytes */
    } while ((n != 0L && nr == (int) rlen)  /* until end of count or eof */
     && sys_buffer_written(L, &sb, buf));
    if (nr <= 0 && len == n) {
	if (!nr || SOCK_ERRNO != EAGAIN) goto err;
	lua_pushboolean(L, 0);
    } else {
	if (!sys_buffer_push(L, &sb, buf, nr))
	    lua_pushinteger(L, len - n);
    }
    return 1;
 err:
    return sock_seterror(L);
}


#ifdef _WIN32

static BOOL
TransmitMapFile (SOCKET sd, HANDLE fd, DWORD n)
{
    HANDLE hMap = CreateFileMapping(fd, NULL, PAGE_READONLY, 0, 0, NULL);
    BOOL res = FALSE;

    if (hMap) {
	DWORD offset = SetFilePointer(fd, 0, NULL, FILE_CURRENT);
	DWORD size = SetFilePointer(fd, 0, NULL, FILE_END) - offset;
	void *base;

	if (n <= 0 || n > size) n = size;
	base = MapViewOfFile(hMap, FILE_MAP_READ, 0, offset, n);
	CloseHandle(hMap);
	if (base) {
	    WSABUF buf = {n, base};
	    if (!WSASend(sd, &buf, 1, &size, 0, NULL, NULL)) {
		offset += size;
		res = TRUE;
	    }
	    UnmapViewOfFile(base);
	}
	SetFilePointer(fd, offset, NULL, FILE_BEGIN);
    }
    return res;
}

#endif


/*
 * Arguments: sd_udata, fd_udata, [count (number)]
 * Returns: [sd_udata | false (EAGAIN)]
 */
static int
sock_sendfile (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    fd_t fd = (fd_t) lua_unboxpointer(L, 2, FD_TYPENAME);
    off_t n = (off_t) lua_tonumber(L, 3);
    int res;

#ifndef _WIN32
    off_t offset = lseek(fd, 0, SEEK_CUR);

    sys_vm_leave();
#ifdef __linux
    do res = sendfile(sd, fd, &offset, n ? (size_t) n : ~((size_t) 0));
    while (res == -1 && SOCK_ERRNO == EINTR);
#else
    do res = sendfile(fd, sd, offset, n, NULL, &n, 0);
    while (res == -1 && SOCK_ERRNO == EINTR);
    offset += n;
#endif
    sys_vm_enter();

    if (res != -1 || SOCK_ERRNO == EAGAIN) {
	if (res != -1) {
	    lua_pushboolean(L, 0);
	    return 1;
	}
	lseek(fd, offset, SEEK_SET);
#else
    sys_vm_leave();
    res = is_WinNT ? TransmitFile(sd, fd, n, 0, NULL, NULL, 0)
     : TransmitMapFile(sd, fd, n);
    sys_vm_enter();

    if (res) {
#endif
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: sd_udata, {string | membuf_udata} ...
 * Returns: [success/partial (boolean), count (number)]
 */
static int
sock_write (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
    ssize_t n = 0;  /* number of chars actually write */
    int i, nargs = lua_gettop(L);

    for (i = 2; i <= nargs; ++i) {
	struct sys_buffer sb;
	int nw;

	if (!sys_buffer_read(L, i, &sb))
	    continue;
	sys_vm_leave();
#ifndef _WIN32
	do nw = write(sd, sb.ptr.r, sb.size);
	while (nw == -1 && SOCK_ERRNO == EINTR);
#else
	{
	    WSABUF buf = {sb.size, sb.ptr.w};
	    usize_t l;
	    nw = !WSASend(sd, &buf, 1, &l, 0, NULL, NULL) ? l : -1;
	}
#endif
	sys_vm_enter();
	if (nw == -1) {
	    if (n > 0 || SYS_ERRNO == EAGAIN) break;
#ifndef _WIN32
	    return sys_seterror(L, 0);
#else
	    return sock_seterror(L);
#endif
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
 * Arguments: sd_udata, [membuf_udata, count (number)]
 * Returns: [string | false (EAGAIN)]
 */
static int
sock_read (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);
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
	do nr = read(sd, sb.ptr.w, rlen);
	while (nr == -1 && SOCK_ERRNO == EINTR);
#else
	{
	    WSABUF buf = {rlen, sb.ptr.w};
	    usize_t l, flags = 0;
	    nr = !WSARecv(sd, &buf, 1, &l, &flags, NULL, NULL) ? l : -1;
	}
#endif
	sys_vm_enter();
	if (nr == -1) break;
	n -= nr;  /* still have to read `n' bytes */
    } while ((n != 0L && nr == (int) rlen)  /* until end of count or eof */
     && sys_buffer_written(L, &sb, buf));
    if (nr <= 0 && len == n) {
	if (!nr || SOCK_ERRNO != EAGAIN) goto err;
	lua_pushboolean(L, 0);
    } else {
	if (!sys_buffer_push(L, &sb, buf, nr))
	    lua_pushinteger(L, len - n);
    }
    return 1;
 err:
#ifndef _WIN32
    return sys_seterror(L, 0);
#else
    return sock_seterror(L);
#endif
}

/*
 * Arguments: sd_udata
 * Returns: string
 */
static int
sock_tostring (lua_State *L)
{
    sd_t sd = (sd_t) lua_unboxpointer(L, 1, SD_TYPENAME);

    if (sd != (sd_t) -1)
	lua_pushfstring(L, SD_TYPENAME " (%d)", (int) sd);
    else
	lua_pushliteral(L, SD_TYPENAME " (closed)");
    return 1;
}


/*
 * Arguments: sock_addr_udata
 * Returns: port, in_addr_udata
 * |
 * Arguments: [port, in_addr_udata]
 * Returns: sock_addr_udata
 */
static int
sock_addr_in (lua_State *L)
{
    struct sock_addr *sap = lua_touserdata(L, 1);
    struct sockaddr_in *sinp;
    struct in_addr *inp;

    if (sap) {
	sinp = (struct sockaddr_in *) &sap->addr;
	lua_pushinteger(L, ntohs(sinp->sin_port));
	inp = lua_newuserdata(L, sizeof(struct in_addr));
	*inp = sinp->sin_addr;
	return 2;
    } else {
	unsigned short port = (unsigned short) lua_tointeger(L, 1);

	inp = lua_touserdata(L, 2);

	sap = lua_newuserdata(L, SA_PREFIX + sizeof(struct sockaddr_in));
	sap->addrlen = sizeof(struct sockaddr_in);
	sinp = (struct sockaddr_in *) &sap->addr;
	memset(sinp, 0, sizeof(struct sockaddr_in));
	/* host is either a valid ip address or not exist */
	sinp->sin_addr.s_addr = htonl(INADDR_ANY);
	sinp->sin_port = htons(port);
	sinp->sin_family = PF_INET;
	if (inp) sinp->sin_addr = *inp;
	return 1;
    };
}


#ifndef _WIN32

/*
 * Arguments: sock_addr_udata
 * Returns: path (string)
 * |
 * Arguments: path (string)
 * Returns: sock_addr_udata
 */
static int
sock_addr_un (lua_State *L)
{
    struct sock_addr *sap;
    struct sockaddr_un *sunp;

    if ((sap = lua_touserdata(L, 1))) {
	sunp = (struct sockaddr_un *) &sap->addr;
	lua_pushstring(L, sunp->sun_path);
	return 1;
    } else {
	const char *path = luaL_checkstring(L, 1);
	size_t len = strlen(path);

	if (len > sizeof(sunp->sun_path) - 1) return 0;

	sap = lua_newuserdata(L, SA_PREFIX + sizeof(struct sockaddr_un));
	sunp = (struct sockaddr_un *) &sap->addr;
	sap->addrlen = len + sizeof(sunp->sun_family);
	sunp->sun_family = PF_UNIX;
	memcpy(sunp->sun_path, path, ++len);
	return 1;
    };
}

#endif


#ifdef INET_ATON

#define atod(cp, num)							\
    while (isdigit(*(cp)))						\
	(num) = ((num) << 3) + ((num) << 1) + (*((cp)++) & ~'0');

static int
inet_aton (const char *cp, struct in_addr *inp)
{
    unsigned long int addr = 0;
    int n = 0;

    atod(cp, n);
    if (n > 255 || !*cp++) return 0;
    addr = n;
    n = 0;
    atod(cp, n);
    if (n > 255 || !*cp++) return 0;
    addr = (addr << 8) | n;
    n = 0;
    atod(cp, n);
    if (n > 255 || !*cp++) return 0;
    addr = (addr << 8) | n;
    n = 0;
    atod(cp, n);
    if (n > 255) return 0;
    inp->s_addr = htonl((addr << 8) | n);
    return 1;
}

#endif

/*
 * Arguments: host (string)
 * Returns: in_addr_udata
 */
static int
sock_inet_aton (lua_State *L)
{
    const char *host = luaL_checkstring(L, 1);
    struct in_addr *inp = lua_newuserdata(L, sizeof(struct in_addr));
    return inet_aton(host, inp) ? 1 : 0;
}

/*
 * Arguments: in_addr_udata
 * Returns: [host (string)]
 */
static int
sock_inet_ntoa (lua_State *L)
{
    struct in_addr *inp = lua_touserdata(L, 1);
    char *host;

    if (!inp) luaL_typerror(L, 1, "socket address");

    host = inet_ntoa(*inp);
    if (host) {
	lua_pushstring(L, host);
	return 1;
    }
    return 0;
}

/*
 * Arguments: address (string)
 * Returns: [in_addr_udata, name (string), aliases (table)]
 */
static int
sock_gethostbyname (lua_State *L)
{
    const char *address = luaL_checkstring(L, 1);
    struct hostent *hp;
    struct in_addr *inp;
    int i;

    sys_vm_leave();
    hp = gethostbyname(address);
    sys_vm_enter();

    if (!hp) return sock_seterror(L);

    inp = lua_newuserdata(L, sizeof(struct in_addr));
    *inp = *((struct in_addr *) *hp->h_addr_list);
    lua_pushstring(L, hp->h_name);
    /* aliases */
    if (hp->h_aliases) {
	const char *alias = *hp->h_aliases;

	lua_newtable(L);
	for (i = 1; alias; ++i, ++alias) {
	    lua_pushstring(L, alias);
	    lua_rawseti(L, -2, i);
	}
    } else
	lua_pushnil(L);
    return 3;
}


static luaL_reg sd_meth[] = {
    {"socket",		sock_socket},
    {"close",		sock_close},
    {"shutdown",	sock_shutdown},
    {"nonblocking",	sock_nonblocking},
    {"sockopt",		sock_sockopt},
    {"bind",		sock_bind},
    {"listen",		sock_listen},
    {"accept",		sock_accept},
    {"connect",		sock_connect},
    {"getpeername",	sock_getpeername},
    {"send",		sock_send},
    {"recv",		sock_recv},
    {"sendfile",	sock_sendfile},
    {"write",		sock_write},
    {"read",		sock_read},
    {"__tostring",	sock_tostring},
    {"__gc",		sock_close},
    {NULL, NULL}
};

static luaL_reg socklib[] = {
    {"handle",		sock_new},
    {"addr_in",		sock_addr_in},
#ifndef _WIN32
    {"addr_un",		sock_addr_un},
#endif
    {"inet_aton",	sock_inet_aton},
    {"inet_ntoa",	sock_inet_ntoa},
    {"gethostbyname",	sock_gethostbyname},
    {"strerror",	sock_strerror},
    {NULL, NULL}
};


#ifdef _WIN32

static int
sock_uninit (lua_State *L)
{
    (void) L;
    WSACleanup();
    return 0;
}

/*
 * Arguments: sock_lib (table)
 */
static int
sock_init (lua_State *L)
{
    WSADATA wsaData;
    WORD wVersionRequested = MAKEWORD(2, 2);
    if (WSAStartup(wVersionRequested, &wsaData)
     || (LOBYTE(wsaData.wVersion) != 2 || HIBYTE(wsaData.wVersion) != 2)) {
	WSACleanup();
	return -1;
    }
    lua_newuserdata(L, 0);
    lua_newtable(L);  /* metatable */
    lua_pushvalue(L, -1);
    lua_pushliteral(L, "__gc");
    lua_pushcfunction(L, sock_uninit);
    lua_rawset(L, -3);
    lua_setmetatable(L, -3);
    lua_rawset(L, -3);
    return 0;
}

#endif


LUALIB_API int luaopen_sys_sock (lua_State *L);

LUALIB_API int
luaopen_sys_sock (lua_State *L)
{
    luaL_register(L, "sys.sock", socklib);

#ifdef _WIN32
    if (sock_init(L)) return 0;
#endif

    luaL_newmetatable(L, SD_TYPENAME);
    lua_pushvalue(L, -1);  /* push metatable */
    lua_setfield(L, -2, "__index");  /* metatable.__index = metatable */
    luaL_register(L, NULL, sd_meth);
    lua_pop(L, 1);
    return 1;
}
