#ifndef EVQ_H
#define EVQ_H

struct event;
struct event_queue;

// Removed for MurgaLua - #define HAVE_EPOLL

#if defined(_WIN32)
#include "win32.h"
#elif defined(HAVE_KQUEUE)
#include "kqueue.h"
#elif defined(HAVE_EPOLL)
#include "epoll.h"
#elif defined(HAVE_POLL)
#include "poll.h"
#else
#include "select.h"
#endif

#include "timeout.h"

/* Event Queue special events */
#define EVQ_TIMEOUT	((void *) -1)
#define EVQ_FAILED	((void *) -2)

/* Event Queue environ. table reserved indexes */
enum {
    EVQ_FD_UDATA = 1,  /* {ev_id => fd_udata} */
    EVQ_CALLBACK,  /* {ev_id => cb_fun} */
    EVQ_ON_INTR,  /* cb_fun */
    EVQ_CACHE,  /* {i => ev_udata} */
    EVQ_EVENTS_ID
};

/* Directory watcher filter flags */
#define EVQ_DIRWATCH_MODIFY	0x01

struct event {
    struct event *next_ready, *next_signal;

    /* timeout */
    struct event *prev, *next;
    struct timeout_queue *tq;
    msec_t timeout;

    int ev_id;
    fd_t fd;

#define EVENT_READ		0x00000001
#define EVENT_WRITE		0x00000002
#define EVENT_ONESHOT		0x00000004
#define EVENT_DELETE		0x00000008
#define EVENT_NOTSOCK		0x00000010
#define EVENT_TIMER		0x00000020
#define EVENT_PID		0x00000040
#define EVENT_SIGNAL		0x00000080
#define EVENT_WINMSG		0x00000100
#define EVENT_DIRWATCH		0x00000200  /* directory watcher */
#define EVENT_OBJECT		0x00000400  /* event of triggerable object */
#define EVENT_CALLBACK		0x00001000  /* callback exist */
#define EVENT_ACCEPT		0x00004000  /* to avoid IOCP signalling of accept-socket */
#define EVENT_IOCP		0x00008000
#define EVENT_MASK		0x0000FFFF
/* triggered events (result of waiting) */
#define EVENT_ACTIVE		0x00010000
#define EVENT_READ_RES		0x00100000
#define EVENT_WRITE_RES		0x00200000
#define EVENT_TIMEOUT_RES	0x00400000
#define EVENT_EOF_RES		0x01000000
#define EVENT_EOF_MASK_RES	0xFF000000
#define EVENT_EOF_SHIFT_RES	24  /* last byte is error status */
    unsigned int flags;

    EVENT_EXTRA
};

struct event_queue {
    int nevents;  /* total number of events */
    int ncache;  /* number of cached (deleted) events */
    int events_id;  /* generator of events identifiers */

#define EVQ_STOP	0x01  /* stop the main loop? */
#define EVQ_INTR	0x02  /* evq interrupted */
    unsigned int flags;

    struct sys_vmthread *vmtd;  /* for inter-vm events (eg. threads i/o) */
    volatile struct event *object_events;  /* ready object events */

    EVQ_EXTRA
};

int evq_init (struct event_queue *evq);
void evq_done (struct event_queue *evq);

int evq_add (struct event_queue *evq, struct event *ev);
int evq_add_dirwatch (struct event_queue *evq, struct event *ev, const char *path);
int evq_del (struct event *ev, int reuse_fd);

int evq_change (struct event *ev, unsigned int flags);

struct event *evq_wait (struct event_queue *evq, msec_t timeout);

int evq_add_timer (struct event_queue *evq, struct event *ev, msec_t msec);
void evq_del_timer (struct event *ev);

int evq_ignore_signal (struct event_queue *evq, int signo, int ignore);
int evq_interrupt (struct event_queue *evq);


#ifndef WIN32

#define evq_post_call(ev, ev_flags)

#define event_get_evq(ev)	(ev)->evq
#define event_deleted(ev)	((ev)->evq == NULL)
#define evq_is_empty(evq)	(!(evq)->nevents)

typedef void (*sig_handler_t) (int);

int signal_set (int signo, sig_handler_t func);

#endif

#endif
