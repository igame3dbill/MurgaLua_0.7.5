/* Timeouts (Timers) */

#include "../common.h"

#include "evq.h"

/*
 * Timer values are spread in small range (usually several minutes) and overflow each 49.7 days.
 * The comparison has to take into account that overflow.
 */


int
timeout_add (struct timeout_queue **headp, struct event *ev, msec_t msec)
{
    const msec_t now = get_milliseconds();
    struct timeout_queue *tq, *tq_prev;

    if (ev->tq) {
	if (ev->tq->msec == msec) {
	    timeout_reset(ev, now);
	    return 0;
	}
	timeout_del(headp, ev);
    }

    tq_prev = NULL;
    for (tq = *headp; tq && tq->msec < msec; tq = tq->next)
	tq_prev = tq;

    if (!tq || tq->msec != msec) {
	struct timeout_queue *tq_new;

	tq_new = malloc(sizeof(struct timeout_queue));
	if (!tq_new) return -1;

	tq_new->msec = msec;
	tq_new->next = tq;
	tq = tq_new;

	if (tq_prev)
	    tq_prev->next = tq;
	else
	    *headp = tq;

	tq->event_head = ev;
	ev->prev = NULL;
    } else {
	ev->prev = tq->event_tail;
	tq->event_tail->next = ev;
    }
    tq->event_tail = ev;
    ev->next = NULL;
    ev->tq = tq;
    ev->timeout = msec + now;
    return 0;
}

static void
timeout_destroy (struct timeout_queue **headp, struct timeout_queue *tq)
{
    struct timeout_queue *head = *headp;

    if (head == tq)
	*headp = tq->next;
    else {
	while (head->next != tq)
	    head = head->next;
	head->next = tq->next;
    }
    free(tq);
}

void
timeout_del (struct timeout_queue **headp, struct event *ev)
{
    struct timeout_queue *tq = ev->tq;
    struct event *ev_prev, *ev_next;

    if (!tq) return;
    ev->tq = NULL;

    ev_prev = ev->prev;
    ev_next = ev->next;

    /* empty queue */
    if (!ev_prev && !ev_next) {
	timeout_destroy(headp, tq);
	return;
    }

    if (ev_prev)
	ev_prev->next = ev_next;
    else
	tq->event_head = ev_next;

    if (ev_next)
	ev_next->prev = ev_prev;
    else
	tq->event_tail = ev_prev;
}

void
timeout_reset (struct event *ev, msec_t now)
{
    struct timeout_queue *tq = ev->tq;
    const msec_t msec = tq->msec;

    if (msec == TIMEOUT_INFINITE)
	return;

    ev->timeout = msec + now;
    if (!ev->next)
	return;

    if (ev->prev)
	ev->prev->next = ev->next;
    else
	tq->event_head = ev->next;

    ev->next->prev = ev->prev;
    ev->next = NULL;
    ev->prev = tq->event_tail;
    tq->event_tail->next = ev;
    tq->event_tail = ev;
}

msec_t
timeout_get (const struct timeout_queue *tq, msec_t min)
{
    msec_t now;
    int is_infinite = 0;

    if (!tq) return min;

    now = get_milliseconds();

    if (min == TIMEOUT_INFINITE)
	is_infinite = 1;
    else
	min += now;

    do {
	if (tq->msec != TIMEOUT_INFINITE) {
	    const msec_t t = tq->event_head->timeout;
	    if (is_infinite) {
		is_infinite = 0;
		min = t;
	    } else if ((long) t < (long) min)
		min = t;
	}
	tq = tq->next;
    } while (tq);

    if (is_infinite)
	return TIMEOUT_INFINITE;
    else {
	const long timeout = (long) min - (long) now;
	return (timeout < 0L) ? 0L : (msec_t) timeout;
    }
}

struct event *
timeout_process (struct timeout_queue *tq, struct event *ev_ready)
{
    msec_t now = get_milliseconds();
    long timeout = (long) now + MIN_TIMEOUT;
    struct event *ev;

    while (tq && tq->msec != TIMEOUT_INFINITE) {
	struct event *ev_head = tq->event_head;

	if (ev_head) {
	    ev = ev_head;
	    while ((long) ev->timeout <= timeout) {
		ev->flags |= EVENT_ACTIVE | EVENT_TIMEOUT_RES;
		ev->timeout = tq->msec + now;

		ev->next_ready = ev_ready;
		ev_ready = ev;
		ev = ev->next;
		if (!ev) break;
	    }
	    if (ev && ev != ev_head) {
		/* recycle timeout queue */
		tq->event_head = ev;  /* head */
		ev->prev = NULL;
		tq->event_tail->next = ev_head;  /* middle */
		ev_head->prev = tq->event_tail;
		tq->event_tail = ev_ready;  /* tail */
		ev_ready->next = NULL;
	    }
	}
	tq = tq->next;
    }
    return ev_ready;
}

