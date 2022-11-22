#ifndef WIN32_H
#define WIN32_H

#define EVQ_SOURCE	"win32.c"

#define NEVENT		(MAXIMUM_WAIT_OBJECTS-1)

/* Win32 Thread */
struct win32thr {
    struct event_queue *evq;
    struct timeout_queue *tq;
    struct win32thr *next, *next_ready;

    CRITICAL_SECTION cs;
    HANDLE signal;
    volatile unsigned int n;  /* count of events */

#define WTHR_SLEEP	1
#define WTHR_POLL	2
#define WTHR_READY	3
#define WTHR_ACK	4
    volatile unsigned int state;

    unsigned int idx;  /* result of Wait* */
    HANDLE handles[NEVENT];  /* last handle is reserved for signal event */
    struct event *events[NEVENT-1];
};

/* Win32 IOCP */
struct win32iocp {
    int n;  /* number of assosiated events */
    HANDLE h;  /* IOCP handle */
};

#define EVENT_EXTRA							\
    struct win32thr *wth;						\
    unsigned int index;							\
    OVERLAPPED rov, wov;  /* for IOCP */

#define EVQ_EXTRA							\
    HANDLE ack_event;							\
    struct event *win_msg;  /* window messages handler */		\
    struct win32iocp iocp;						\
    volatile struct win32thr *ready;					\
    struct win32thr head;						\
    volatile int nwakeup;  /* number of the re-polling threads */	\
    volatile int sig_ready;  /* triggered signals */

int win32iocp_set (struct event *ev, unsigned int ev_flags);

#define evq_post_call(ev, ev_flags) do {				\
	if ((ev_flags & EVENT_IOCP) && !(ev)->index)			\
	    win32iocp_set((ev),						\
	     (ev_flags & EVENT_READ_RES) ? EVENT_READ : 0		\
	     | (ev_flags & EVENT_WRITE_RES) ? EVENT_WRITE : 0);		\
	else if (ev_flags & EVENT_DIRWATCH)				\
	    FindNextChangeNotification((ev)->fd);			\
    } while (0)

#define event_get_evq(ev)	(ev)->wth->evq
#define event_deleted(ev)	((ev)->wth == NULL)
#define iocp_is_empty(evq)	(!(evq)->iocp.n)
#define evq_is_empty(evq)	(!((evq)->nevents || (evq)->head.next))

#endif
