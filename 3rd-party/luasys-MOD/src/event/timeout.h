#ifndef TIMEOUT_H
#define TIMEOUT_H

#define MIN_TIMEOUT	10  /* milliseconds */

struct timeout_queue {
    struct timeout_queue *next;
    struct event *event_head, *event_tail;
    msec_t msec;
};

int timeout_add (struct timeout_queue **headp, struct event *ev, msec_t msec);
void timeout_del (struct timeout_queue **headp, struct event *ev);
void timeout_reset (struct event *ev, msec_t now);

msec_t timeout_get (const struct timeout_queue *tq, msec_t min);

struct event *timeout_process (struct timeout_queue *tq, struct event *ev_ready);

int event_set_timeout (struct event *ev, msec_t msec);

#define event_get_timeout(ev)	((ev)->tq->msec)

#endif
