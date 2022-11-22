/* Event queue */

#include "../common.h"

#include "evq.h"


#ifdef _WIN32

#include "win32sig.c"

#else

#include "signal.c"

int
event_set_timeout (struct event *ev, msec_t msec)
{
    struct event_queue *evq = ev->evq;
    const unsigned int ev_flags = ev->flags;

    if (msec == TIMEOUT_INFINITE && !(ev_flags & EVENT_TIMER)) {
	timeout_del(&evq->tq, ev);
	return 0;
    }

    return timeout_add(&evq->tq, ev, msec);
}

int
evq_add_timer (struct event_queue *evq, struct event *ev, msec_t msec)
{
    if (!timeout_add(&evq->tq, ev, msec)) {
	ev->evq = evq;
	evq->nevents++;
	return 0;
    }
    return -1;
}

void
evq_del_timer (struct event *ev)
{
    struct event_queue *evq = ev->evq;

    ev->evq = NULL;
    evq->nevents--;
    timeout_del(&evq->tq, ev);
}

#endif /* !WIN32 */


#include EVQ_SOURCE

