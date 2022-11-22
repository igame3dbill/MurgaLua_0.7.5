#ifndef COMMON_H
#define COMMON_H

#include <sys/types.h>
#include <string.h>
#include <stdlib.h>
#include <errno.h>


#ifdef _WIN32

#define _WIN32_WINNT	0x0500

#define WIN32_LEAN_AND_MEAN
#include <windows.h>
#undef WIN32_LEAN_AND_MEAN

#include <winsock2.h>
#include <mmsystem.h>	/* timeGetTime */

#if (_WIN32_WINNT >= 0x0500)
#define InitCriticalSection(cs)		InitializeCriticalSectionAndSpinCount(cs, 3000)
#else
#define InitCriticalSection(cs)		(InitializeCriticalSection(cs), TRUE)
#endif

#define SIGINT		CTRL_C_EVENT
#define SIGQUIT		CTRL_BREAK_EVENT
#define SIGHUP		CTRL_LOGOFF_EVENT
#define SIGTERM		CTRL_SHUTDOWN_EVENT
#define NSIG 		(SIGTERM + 1)

#undef EAGAIN
#define EAGAIN		WSAEWOULDBLOCK

#define SYS_ERRNO	GetLastError()

extern int is_WinNT;

#else

#include <sys/time.h>
#include <unistd.h>
#include <signal.h>
#include <fcntl.h>

#define SYS_ERRNO	errno

#define SYS_SIGINTR	SIGWINCH

#endif


#define LUA_LIB

#include <lua.h>
#include <lualib.h>
#include <lauxlib.h>


#ifdef NO_CHECK_UDATA
#define checkudata(L,i,tname)	lua_touserdata(L, i)
#else
#define checkudata(L,i,tname)	luaL_checkudata(L, i, tname)
#endif

#define lua_boxpointer(L,u) \
	(*(void **) (lua_newuserdata(L, sizeof(void *))) = (u))

#define lua_unboxpointer(L,i,tname) \
	(*(void **) (checkudata(L, i, tname)))


#define FD_TYPENAME	"sys.handle"

#ifdef _WIN32
typedef DWORD	usize_t;
typedef HANDLE	fd_t;
typedef SOCKET	sd_t;
#else
typedef size_t	usize_t;
typedef int	fd_t;
typedef int	sd_t;
#endif


/*
 * Buffer Management
 */

#define SYS_BUFSIZE	4096

struct membuf;

struct sys_buffer {
    union {
	const char *r;  /* read from buffer */
	char *w;  /* write to buffer */
    } ptr;
    size_t size;
    struct membuf *mb;
};

int sys_buffer_read (lua_State *L, int idx, struct sys_buffer *sb);
void sys_buffer_readed (struct sys_buffer *sb, size_t n);

void sys_buffer_write (lua_State *L, int idx, struct sys_buffer *sb,
                       char *buf, size_t buflen);
int sys_buffer_written (lua_State *L, struct sys_buffer *sb, char *buf);
int sys_buffer_push (lua_State *L, struct sys_buffer *sb,
                     char *buf, size_t tail);


/*
 * Error Reporting
 */

int sys_seterror (lua_State *L, int err);


/*
 * Threading
 */

void sys_settls (void *value);
void *sys_gettls (void);

struct sys_vmthread;

struct sys_vmthread *sys_get_vmthread (void);

void sys_vm2_enter (struct sys_vmthread *vmtd);
void sys_vm2_leave (struct sys_vmthread *vmtd);

void sys_vm_enter (void);
void sys_vm_leave (void);

lua_State *sys_newthread (lua_State *L, struct sys_vmthread *vmtd);
void sys_delthread (lua_State *L);


/*
 * Object Events
 */

#define SYS_OBJEVENT_TAG	"__evq"

typedef volatile void *		sys_objevent_t;

typedef sys_objevent_t *(*sys_get_objevent_t) (lua_State *L, struct sys_vmthread **vmtdp);

enum {SYS_EVREAD = 1, SYS_EVWRITE = 2, SYS_EVEOF = 4, SYS_EVDEL = 8};

int sys_trigger_objevent (sys_objevent_t *event, int flags);


/*
 * Time
 */

typedef unsigned long	msec_t;

#ifdef _WIN32
#define get_milliseconds	timeGetTime
#else
msec_t get_milliseconds (void);
#endif

#define TIMEOUT_INFINITE	(~((msec_t) 0UL))


/*
 * Internal Libraries
 */

void luaopen_sys_mem (lua_State *L);
void luaopen_sys_thread (lua_State *L);
void luaopen_sys_win32 (lua_State *L);

#endif
