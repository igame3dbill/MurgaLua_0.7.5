/* EPoll */

#define EPOLLFD_READ	(EPOLLIN | EPOLLERR | EPOLLHUP)
#define EPOLLFD_WRITE	(EPOLLOUT | EPOLLERR | EPOLLHUP)

int
evq_init (struct event_queue *evq)
{
    fd_t *sig_fd = evq->sig_fd;

    evq->epoll_fd = epoll_create(NEVENT);
    if (evq->epoll_fd == -1)
	return -1;

    evq->ep_events = malloc(NEVENT * sizeof(struct epoll_event));
    if (!evq->ep_events)
	return -1;

    {
	struct epoll_event epev;

	memset(&epev, 0, sizeof(struct epoll_event));
	epev.events = EPOLLIN;

	sig_fd[0] = sig_fd[1] = (fd_t) -1;
	if (pipe(sig_fd) || fcntl(sig_fd[0], F_SETFL, O_NONBLOCK)
	 || epoll_ctl(evq->epoll_fd, EPOLL_CTL_ADD, sig_fd[0], &epev)) {
	    evq_done(evq);
	    return -1;
	}
    }

    evq->npolls++;
    evq->max_polls = NEVENT;
    return 0;
}

void
evq_done (struct event_queue *evq)
{
    close(evq->sig_fd[0]);
    close(evq->sig_fd[1]);

    close(evq->epoll_fd);
    free(evq->ep_events);
}

int
evq_add (struct event_queue *evq, struct event *ev)
{
    ev->evq = evq;

    if (ev->flags & EVENT_SIGNAL)
	return signal_add(evq, ev);

    if (evq->npolls >= evq->max_polls) {
	const unsigned int n = 2 * evq->max_polls;
	void *p;

	if (!(p = realloc(evq->ep_events, n * sizeof(struct epoll_event))))
	    return -1;
	evq->ep_events = p;
	evq->max_polls = n;
    }

    {
	struct epoll_event epev;

	memset(&epev, 0, sizeof(struct epoll_event));
	if (ev->flags & EVENT_READ)
	    epev.events = EPOLLIN;
	if (ev->flags & EVENT_WRITE)
	    epev.events |= EPOLLOUT;
	epev.events |= (ev->flags & EVENT_ONESHOT) ? EPOLLONESHOT : 0;
	epev.data.ptr = ev;
	if (epoll_ctl(evq->epoll_fd, EPOLL_CTL_ADD, ev->fd, &epev) == -1)
	    return -1;
    }

    evq->npolls++;
    evq->nevents++;
    return 0;
}

int
evq_add_dirwatch (struct event_queue *evq, struct event *ev, const char *path)
{
    const unsigned int filter = (ev->flags >> EVENT_EOF_SHIFT_RES)
     ? IN_MODIFY : IN_ALL_EVENTS ^ IN_ACCESS;

    ev->flags &= ~EVENT_EOF_MASK_RES;

    ev->fd = inotify_init();
    if (ev->fd == -1) return -1;

    if (inotify_add_watch(ev->fd, path, filter) == -1) {
	close(ev->fd);
	return -1;
    }

    return evq_add(evq, ev);
}

int
evq_del (struct event *ev, int reuse_fd)
{
    struct event_queue *evq = ev->evq;
    const unsigned int npolls = --evq->npolls;
    int i;

    ev->evq = NULL;
    evq->nevents--;

    if (ev->tq)
	timeout_del(&evq->tq, ev);

    if (ev->flags & EVENT_SIGNAL)
	return signal_del(evq, ev);

    if (ev->flags & EVENT_DIRWATCH)
	return close(ev->fd);

    if (reuse_fd)
     epoll_ctl(evq->epoll_fd, EPOLL_CTL_DEL, ev->fd, NULL);

    if (npolls > NEVENT / 2 && npolls <= evq->max_polls / 4) {
	void *p;

	i = (evq->max_polls /= 2);
	if ((p = realloc(evq->ep_events, i * sizeof(struct epoll_event))))
	    evq->ep_events = p;
    }
    return 0;
}

int
evq_change (struct event *ev, unsigned int flags)
{
    struct epoll_event epev;

    memset(&epev, 0, sizeof(struct epoll_event));
    if (flags & EVENT_READ)
	epev.events = EPOLLIN;
    if (flags & EVENT_WRITE)
	epev.events |= EPOLLOUT;
    epev.data.ptr = ev;
    return epoll_ctl(ev->evq->epoll_fd, EPOLL_CTL_MOD, ev->fd, &epev);
}

struct event *
evq_wait (struct event_queue *evq, msec_t timeout)
{
    struct event *ev_ready;
    struct epoll_event *epev = evq->ep_events;
    int nready;

    timeout = timeout_get(evq->tq, timeout);

    sys_vm_leave();

    nready = epoll_wait(evq->epoll_fd, epev, evq->npolls, (int) timeout);

    sys_vm_enter();

    if (nready == -1)
	return (errno == EINTR) ? NULL : EVQ_FAILED;

    if (timeout != TIMEOUT_INFINITE) {
	if (!nready) {
	    ev_ready = evq->tq ? timeout_process(evq->tq, NULL) : NULL;
	    return ev_ready ? ev_ready : EVQ_TIMEOUT;
	}

	timeout = get_milliseconds();
    }

    ev_ready = NULL;
    for (; nready--; ++epev) {
	const int revents = epev->events;
	struct event *ev;
	unsigned int res;

	if (!revents) continue;

	ev = epev->data.ptr;
	if (!ev) {
	    if (revents & EPOLLFD_READ)
		ev_ready = signal_process(evq, ev_ready, timeout);
	    continue;
	}

	res = EVENT_ACTIVE;
	if ((revents & EPOLLFD_READ) && (ev->flags & EVENT_READ)) {
	    res |= EVENT_READ_RES;

	    if (ev->flags & EVENT_DIRWATCH) {  /* skip inotify data */
		char buf[BUFSIZ];
		int n;
		do n = read(ev->fd, buf, sizeof(buf));
		while (n == -1 && errno == EINTR);
	    }
	}
	if ((revents & EPOLLFD_WRITE) && (ev->flags & EVENT_WRITE))
	    res |= EVENT_WRITE_RES;
	if (revents & EPOLLHUP)
	    res |= EVENT_EOF_RES;

	ev->flags |= res;
	if (ev->flags & EVENT_ONESHOT)
	    evq_del(ev, 1);
	else if (ev->tq)
	    timeout_reset(ev, timeout);

	ev->next_ready = ev_ready;
	ev_ready = ev;
    }
    return ev_ready;
}

