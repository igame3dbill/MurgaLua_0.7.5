/* Win32 NT IOCP */

static struct event *
win32iocp_process (struct event_queue *evq, struct event *ev_ready)
{
    const HANDLE iocph = evq->iocp.h;
    msec_t now = 0L;

    for (; ; ) {
	unsigned long nr;
	struct event *ev;
	OVERLAPPED *ovp;

	if (GetQueuedCompletionStatus(iocph, &nr, (DWORD *) &ev, &ovp, 0L)) {
	    ev->flags |= (&ev->rov == ovp) ? EVENT_READ_RES : EVENT_WRITE_RES;
	} else {
	    const int err = GetLastError();

	    if (err == WAIT_TIMEOUT)
		break;
	    if (err == ERROR_OPERATION_ABORTED)
		continue;
	    if (ovp && ev)
		ev->flags |= EVENT_EOF_RES;
	    else
		break;  /* error */
	}

	ev->index = 0;  /* have to set IOCP request */
	ev->flags |= EVENT_ACTIVE;
	if (ev->flags & EVENT_ONESHOT)
	    evq_del(ev, 1);
	else if (ev->tq) {
	    if (now == 0L)
		now = get_milliseconds();
	    timeout_reset(ev, now);
	}

	ev->next_ready = ev_ready;
	ev_ready = ev;
    }
    return ev_ready;
}

int
win32iocp_set (struct event *ev, unsigned int ev_flags)
{
    WSABUF buf = {0};

    if (ev_flags & EVENT_READ) {
	DWORD flags = 0;

	memset(&ev->rov, 0, sizeof(OVERLAPPED) - sizeof(HANDLE));
	if (WSARecv((sd_t) ev->fd, &buf, 1, NULL, &flags, &ev->rov, NULL) != SOCKET_ERROR
	 || WSAGetLastError() != WSA_IO_PENDING)
	    return -1;
    }
    if (ev_flags & EVENT_WRITE) {
	memset(&ev->wov, 0, sizeof(OVERLAPPED) - sizeof(HANDLE));
	if (WSASend((sd_t) ev->fd, &buf, 1, NULL, 0, &ev->wov, NULL) != SOCKET_ERROR
	 || WSAGetLastError() != WSA_IO_PENDING)
	    return -1;
    }
    ev->index = 1;  /* IOCP request is installed */
    return 0;
}

