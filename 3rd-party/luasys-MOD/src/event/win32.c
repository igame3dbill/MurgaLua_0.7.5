/* Win32: MsgWaitForMultipleObjects and multiple threads */

#define WFD_READ	(FD_READ | FD_ACCEPT | FD_CLOSE)
#define WFD_WRITE	(FD_WRITE | FD_CONNECT | FD_CLOSE)


#include "win32iocp.c"
#include "win32thr.c"


int
event_set_timeout (struct event *ev, msec_t msec)
{
    struct win32thr *wth = ev->wth;
    const unsigned int ev_flags = ev->flags;

    if (!(ev_flags & EVENT_ACTIVE))
	win32thr_sleep(wth);

    if (msec == TIMEOUT_INFINITE && !(ev_flags & EVENT_TIMER)) {
	timeout_del(&wth->tq, ev);
	return 0;
    }

    return timeout_add(&wth->tq, ev, msec);
}

int
evq_init (struct event_queue *evq)
{
    struct win32thr *wth = &evq->head;

    evq->ack_event = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (evq->ack_event == NULL)
	return -1;

    wth->signal = CreateEvent(NULL, FALSE, FALSE, NULL);
    if (wth->signal == NULL) {
	CloseHandle(evq->ack_event);
	return -1;
    }
    wth->handles[0] = wth->signal;
    wth->evq = evq;

    InitCriticalSection(&wth->cs);

    if (is_WinNT)
	evq->iocp.h = CreateIoCompletionPort(INVALID_HANDLE_VALUE, NULL, 0, 1);

    return 0;
}

void
evq_done (struct event_queue *evq)
{
    struct win32thr *wth = &evq->head;

    if (wth->next)
	win32thr_poll(evq);

    if (evq->iocp.h)
	CloseHandle(evq->iocp.h);

    CloseHandle(evq->ack_event);
    CloseHandle(wth->signal);
    DeleteCriticalSection(&wth->cs);
}

int
evq_add (struct event_queue *evq, struct event *ev)
{
    const unsigned int ev_flags = ev->flags;
    struct win32thr *wth = &evq->head;
    int not_iocp, optlen;

    ev->wth = wth;

    if (ev_flags & EVENT_SIGNAL) {
	return signal_add(evq, ev);
    }

    if (ev_flags & EVENT_WINMSG) {
	evq->win_msg = ev;
	evq->nevents++;
	return 0;
    }

    /* find place for new event */
    not_iocp = 1;
    optlen = sizeof(int);
    if (!(ev_flags & EVENT_NOTSOCK)) {
	if (!getsockopt((sd_t) ev->fd, SOL_SOCKET, SO_TYPE,
	 (char *) &not_iocp, &optlen)) {
	    /* don't add listening socket to IOCP */
	    if (evq->iocp.h) {
		getsockopt((sd_t) ev->fd, SOL_SOCKET, SO_ACCEPTCONN,
		 (void *) &not_iocp, &optlen);
		ev->flags |= not_iocp ? EVENT_ACCEPT : 0;
	    }
	} else
	    ev->flags |= EVENT_NOTSOCK;
    }

    if (!not_iocp) {
	ev->rov.hEvent = ev->wov.hEvent = wth->signal;

	if (CreateIoCompletionPort((HANDLE) ev->fd, evq->iocp.h, (DWORD) ev, 0)
	 && !win32iocp_set(ev, ev_flags)) {
	    ev->flags |= EVENT_IOCP;
	    evq->iocp.n++;
	    evq->nevents++;
	    return 0;
	}
    }

    while (wth->n >= NEVENT - 1)
	if (!(wth = wth->next)) break;

    if (wth)
	win32thr_sleep(wth);
    else {
	wth = win32thr_init(evq);
	if (!wth) return -1;
    }

    return win32thr_add(wth, ev);
}

int
evq_add_dirwatch (struct event_queue *evq, struct event *ev, const char *path)
{
    const DWORD flags = FILE_NOTIFY_CHANGE_FILE_NAME | FILE_NOTIFY_CHANGE_DIR_NAME
     | FILE_NOTIFY_CHANGE_ATTRIBUTES | FILE_NOTIFY_CHANGE_SIZE
     | FILE_NOTIFY_CHANGE_LAST_WRITE | FILE_NOTIFY_CHANGE_CREATION
     | FILE_NOTIFY_CHANGE_SECURITY;

    const unsigned int filter = (ev->flags >> EVENT_EOF_SHIFT_RES)
     ? FILE_NOTIFY_CHANGE_LAST_WRITE : flags;

    ev->flags &= ~EVENT_EOF_MASK_RES;

    ev->fd = FindFirstChangeNotification(path, FALSE, filter);
    if (ev->fd == NULL || ev->fd == INVALID_HANDLE_VALUE)
	return -1;

    return evq_add(evq, ev);
}

int
evq_del (struct event *ev, int reuse_fd)
{
    struct win32thr *wth = ev->wth;
    const unsigned int ev_flags = ev->flags;

    if (ev_flags & (EVENT_IOCP | EVENT_SIGNAL | EVENT_WINMSG)) {
	struct event_queue *evq = wth->evq;

	ev->wth = NULL;
	evq->nevents--;

	if (ev->tq)
	    timeout_del(&wth->tq, ev);

	if (ev_flags & EVENT_IOCP) {
	    /* TODO: How de-assosiate socket from IOCP? */
	    if (reuse_fd && ev->index)
		CancelIo(ev->fd);
	    evq->iocp.n--;
	    return 0;
	}

	if (ev_flags & EVENT_SIGNAL)
	    return signal_del(ev);

	evq->win_msg = NULL;
	return 0;
    }

    if (!(ev_flags & EVENT_ACTIVE))
	win32thr_sleep(wth);

    return win32thr_del(wth, ev);
}

int
evq_change (struct event *ev, unsigned int flags)
{
    const unsigned int ev_flags = ev->flags;

    if (ev_flags & EVENT_IOCP) {
	if (ev->index)
	    CancelIo(ev->fd);
	return win32iocp_set(ev, flags);
    }

    if (!(ev_flags & EVENT_NOTSOCK)) {
	struct win32thr *wth = ev->wth;
	int event = 0;

	if (!(ev_flags & EVENT_ACTIVE))
	    win32thr_sleep(wth);

	if (flags & EVENT_READ)
	    event = WFD_READ;
	if (flags & EVENT_WRITE)
	    event |= WFD_WRITE;

	if (WSAEventSelect((int) ev->fd, wth->handles[ev->index], event) == SOCKET_ERROR)
	    return -1;
    }
    return 0;
}

int
evq_add_timer (struct event_queue *evq, struct event *ev, msec_t msec)
{
    if (!timeout_add(&evq->head.tq, ev, msec)) {
	ev->wth = &evq->head;
	evq->nevents++;
	return 0;
    }
    return -1;
}

void
evq_del_timer (struct event *ev)
{
    struct event_queue *evq = ev->wth->evq;

    ev->wth = NULL;
    evq->nevents--;
    timeout_del(&evq->head.tq, ev);
}

int
evq_interrupt (struct event_queue *evq)
{
    return !SetEvent(evq->head.signal);
}

struct event *
evq_wait (struct event_queue *evq, msec_t timeout)
{
    struct event *ev_ready = NULL;
    struct win32thr *wth = &evq->head;
    struct win32thr *threads = wth->next;
    CRITICAL_SECTION *head_cs = &wth->cs;
    int n = wth->n;
    int sig_ready = 0;
    DWORD wait_res;

    if (threads && win32thr_poll(evq) && evq_is_empty(evq))
	return NULL;

    if (!iocp_is_empty(evq))
	ev_ready = win32iocp_process(evq, ev_ready);

    sys_vm_leave();

    wait_res = MsgWaitForMultipleObjects(n + 1, wth->handles, FALSE,
     ev_ready ? 0L : timeout_get(wth->tq, timeout),
     evq->win_msg ? QS_ALLEVENTS : 0);

    sys_vm_enter();

    if (wait_res == WAIT_TIMEOUT) {
	if (ev_ready)
	    return ev_ready;
	if (!wth->tq)
	    return EVQ_TIMEOUT;
    }
    if (wait_res == (WAIT_OBJECT_0 + n + 1)) {
	struct event *ev = evq->win_msg;
	if (ev) ev->next_ready = NULL;
	return ev;
    }
    if (wait_res == WAIT_FAILED)
	return EVQ_FAILED;

    if (!iocp_is_empty(evq))
	ev_ready = win32iocp_process(evq, ev_ready);

    wth->idx = wait_res;

    if (threads) {
	EnterCriticalSection(head_cs);
	ResetEvent(wth->signal);

	(volatile void *) threads = evq->ready;
	evq->ready = NULL;

	sig_ready = evq->sig_ready;
	evq->sig_ready = 0;
	LeaveCriticalSection(head_cs);

	if (wait_res == (WAIT_OBJECT_0 + n))
	    wth = threads;
	else
	    wth->next_ready = threads;
    } else {
	wth->next_ready = NULL;

	if (evq->sig_ready) {
	    EnterCriticalSection(head_cs);
	    ResetEvent(wth->signal);

	    sig_ready = evq->sig_ready;
	    evq->sig_ready = 0;
	    LeaveCriticalSection(head_cs);
	}
    }

    if (sig_ready) {
	timeout = get_milliseconds();
	ev_ready = signal_process(sig_ready, ev_ready, timeout);
    } else
	timeout = 0L;

    for (; wth; wth = wth->next_ready) {
	HANDLE *hp;  /* event handles */
	const int idx = wth->idx;
	int i;

	wth->state = WTHR_SLEEP;

	if (wth->tq) {
	    if (idx == WAIT_TIMEOUT) {
		ev_ready = timeout_process(wth->tq, ev_ready);
		continue;
	    }
	    if (timeout == 0L)
		timeout = get_milliseconds();
	}

	hp = &wth->handles[idx];
	n = wth->n;
	i = idx;
	if (i >= n) continue;  /* some events deleted? */

	/* Traverse array of events */
	for (; ; ) {
	    WSANETWORKEVENTS ne;
	    struct event *ev = wth->events[i];
	    const int ev_flags = ev->flags;
	    unsigned int res = 0;

	    if (ev_flags & EVENT_NOTSOCK) {
		if (ev_flags & EVENT_PID) {
		    DWORD status;
		    GetExitCodeProcess(ev->fd, &status);
		    res = (status << EVENT_EOF_SHIFT_RES);
		} else
		    ResetEvent(ev->fd);  /* all events must be manual-reset */
		res |= EVENT_READ_RES;
	    }
	    else if (!WSAEnumNetworkEvents((int) ev->fd, *hp, &ne)) {
		if ((ev_flags & EVENT_READ) && (ne.lNetworkEvents & WFD_READ))
		    res = EVENT_READ_RES;
		if ((ev_flags & EVENT_WRITE) && (ne.lNetworkEvents & WFD_WRITE))
		    res |= EVENT_WRITE_RES;
		if (ne.lNetworkEvents & FD_CLOSE)
		    res |= EVENT_EOF_RES;
	    }

	    if (res) {
		ev->flags |= EVENT_ACTIVE | res;
		ev->next_ready = ev_ready;
		ev_ready = ev;

		if (ev_flags & EVENT_ONESHOT) {
		    win32thr_del(wth, ev);
		    --i, --n, --hp;
		} else if (ev->tq)
		    timeout_reset(ev, timeout);
	    }

	    /* skip inactive events */
	    do {
		if (++i == n)
		    goto end_thread;
	    } while (WaitForSingleObject(*(++hp), 0) != WAIT_OBJECT_0);
	}
 end_thread:
	;  /* avoid warning */
    }

    /* always check window messages */
    {
	struct event *ev = evq->win_msg;

	if (ev && GetQueueStatus(QS_ALLEVENTS)) {
	    ev->next_ready = ev_ready;
	    ev_ready = ev;
	}
    }
    return ev_ready ? ev_ready
     : (wait_res == WAIT_TIMEOUT ? EVQ_TIMEOUT : NULL);
}

