/* Lua System: Event Queue */

#include "event/evq.h"

#define EVQ_TYPENAME	"sys.evq"

/* Max. number to cache deleted events */
#define EVQ_CACHE_MAX	64


/*
 * Returns: [evq_udata]
 */
static int
sys_event_queue (lua_State *L)
{
    struct event_queue *evq = lua_newuserdata(L, sizeof(struct event_queue));
    memset(evq, 0, sizeof(struct event_queue));
    evq->vmtd = sys_get_vmthread();

    if (!evq_init(evq)) {
	luaL_getmetatable(L, EVQ_TYPENAME);
	lua_setmetatable(L, -2);

	lua_newtable(L);  /* environ. | {ev_id => ev_udata} */
	lua_newtable(L);  /* {ev_id => fd_udata | ev_ludata => get_objevent_func} */
	lua_rawseti(L, -2, EVQ_FD_UDATA);
	lua_newtable(L);  /* {ev_id => cb_fun} */
	lua_rawseti(L, -2, EVQ_CALLBACK);
	lua_newtable(L);  /* {i => ev_udata} */
	lua_pushliteral(L, "v");  /* weak values */
	lua_setfield(L, -2, "__mode");  /* metatable.__mode = "v" */
	lua_rawseti(L, -2, EVQ_CACHE);
	lua_setfenv(L, -2);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: evq_udata
 */
static int
levq_done (lua_State *L)
{
    struct event_queue *evq = checkudata(L, 1, EVQ_TYPENAME);

    /* delete all events */
    lua_getfenv(L, 1);
    lua_pushnil(L);
    while (lua_next(L, -2)) {
	struct event *ev = lua_touserdata(L, -1);

	if (ev && !event_deleted(ev)) {
	    if (ev->flags & EVENT_TIMER)
		evq_del_timer(ev);
	    else
		evq_del(ev, 0);
	}
	lua_pop(L, 1);  /* pop value */
    }

    evq_done(evq);
    return 0;
}


/*
 * Arguments: ..., EVQ_ENVIRON (table)
 * Returns: ev_udata
 */
static struct event *
levq_new_udata (lua_State *L, int idx, struct event_queue *evq)
{
    struct event *ev;

    if (evq->ncache) {
	lua_rawgeti(L, idx, EVQ_CACHE);
	lua_rawgeti(L, -1, evq->ncache--);
	ev = lua_touserdata(L, -1);
	if (ev) goto end;
	lua_pop(L, 3);
	evq->ncache = 0;
    }
    ev = lua_newuserdata(L, sizeof(struct event));
 end:
    memset(ev, 0, sizeof(struct event));
    return ev;
}

/*
 * Arguments: ..., EVQ_ENVIRON (table), EVQ_FD_UDATA (table), EVQ_CALLBACK (table)
 */
static void
levq_del_udata (lua_State *L, int idx, int ev_id, struct event_queue *evq)
{
    /* ev_udata */
    if (evq->ncache < EVQ_CACHE_MAX) {
	lua_rawgeti(L, idx, EVQ_CACHE);
	lua_rawgeti(L, idx, ev_id);
	lua_rawseti(L, -2, ++evq->ncache);
	lua_pop(L, 1);
    }
    lua_pushnil(L);
    lua_rawseti(L, idx, ev_id);
    /* fd_udata */
    lua_pushnil(L);
    lua_rawseti(L, idx + 1, ev_id);
    /* cb_fun */
    lua_pushnil(L);
    lua_rawseti(L, idx + 2, ev_id);
}


/*
 * Arguments: ..., EVQ_ENVIRON (table)
 */
static int
levq_nextid (lua_State *L, int idx, struct event_queue *evq)
{
    int ev_id = evq->events_id;
    int found;

    do {
	if (ev_id == 0) {
	    ev_id = EVQ_EVENTS_ID;
	    break;
	}
	lua_rawgeti(L, idx, ++ev_id);
	found = lua_isnil(L, -1);
	lua_pop(L, 1);
    } while (!found);
    evq->events_id = ev_id;
    return ev_id;
}

/*
 * Arguments: evq_udata, fd_udata,
 *	events (string: "r", "w", "rw") | signal (number),
 *	callback (function),
 *	[timeout (milliseconds), one_shot (boolean),
 *	event_flags (number), get_objevent_func (lightuserdata)]
 * Returns: [ev_id (number)]
 */
static int
levq_add (lua_State *L)
{
    struct event_queue *evq = checkudata(L, 1, EVQ_TYPENAME);
    fd_t *fdp = lua_touserdata(L, 2);
    const int signo = (lua_type(L, 3) == LUA_TNUMBER)
     ? lua_tointeger(L, 3) : 0;
    const char *evstr = signo ? NULL : lua_tostring(L, 3);
    const msec_t timeout = lua_isnoneornil(L, 5)
     ? TIMEOUT_INFINITE : (msec_t) lua_tonumber(L, 5);
    const unsigned int ev_flags = (lua_toboolean(L, 6) ? EVENT_ONESHOT : 0)
     | lua_tointeger(L, 7);
    sys_get_objevent_t get_objevent = ev_flags
     ? (sys_get_objevent_t) lua_touserdata(L, 8) : NULL;
    struct event *ev;
    int res;

#undef ARG_LAST
#define ARG_LAST	4

    lua_settop(L, ARG_LAST);
    lua_getfenv(L, 1);
    lua_rawgeti(L, ARG_LAST+1, EVQ_FD_UDATA);
    lua_rawgeti(L, ARG_LAST+1, EVQ_CALLBACK);

    ev = levq_new_udata(L, ARG_LAST+1, evq);
    ev->fd = fdp ? *fdp : (fd_t) signo;
    ev->flags = (!evstr ? EVENT_READ : (evstr[0] == 'r') ? EVENT_READ
     | (evstr[1] ? EVENT_WRITE : 0) : EVENT_WRITE)
     | (!lua_isnil(L, 4) ? EVENT_CALLBACK : 0)
     | ev_flags;

    if (ev_flags & EVENT_TIMER) {
	if (ev_flags & EVENT_OBJECT) {
	    struct sys_vmthread *vmtd;
	    struct event **ev_head;

	    lua_pushvalue(L, 2);
	    ev_head = (void *) get_objevent(L, &vmtd);
	    if (!ev_head) return 0;
	    lua_pop(L, 1);

	    if (vmtd != evq->vmtd) sys_vm2_enter(vmtd);
	    ev->next_signal = *ev_head;
	    *ev_head = ev;
	    if (vmtd != evq->vmtd) sys_vm2_leave(vmtd);
	}

	res = evq_add_timer(evq, ev, timeout);
    }
    else {
	if (ev_flags & EVENT_DIRWATCH)
	    res = evq_add_dirwatch(evq, ev, lua_tostring(L, 2));
	else
	    res = evq_add(evq, ev);

	if (!res && timeout != TIMEOUT_INFINITE)
	    event_set_timeout(ev, timeout);
    }
    if (!res) {
	const int ev_id = (ev->ev_id = levq_nextid(L, ARG_LAST+1, evq));

	/* ev_udata */
	lua_rawseti(L, ARG_LAST+1, ev_id);
	/* fd_udata */
	lua_pushvalue(L, 2);
	lua_rawseti(L, ARG_LAST+2, ev_id);
	/* cb_fun */
	lua_pushvalue(L, 4);
	lua_rawseti(L, ARG_LAST+3, ev_id);

	if (get_objevent) {
	    lua_pushlightuserdata(L, (void *) ev_id);
	    lua_pushlightuserdata(L, (void *) get_objevent);
	    lua_rawset(L, ARG_LAST+2);
	}

	lua_pushinteger(L, ev_id);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: evq_udata, callback (function), timeout (milliseconds)
 * Returns: [ev_id (number)]
 */
static int
levq_add_timer (lua_State *L)
{
    lua_settop(L, 3);
    lua_pushnil(L);  /* fd_udata */
    lua_insert(L, 2);
    lua_pushnil(L);  /* EVENT_READ */
    lua_insert(L, 3);
    lua_pushnil(L);  /* EVENT_ONESHOT */
    lua_pushinteger(L, EVENT_NOTSOCK | EVENT_TIMER);  /* event_flags */
    return levq_add(L);
}

/*
 * Arguments: evq_udata, pid_udata,
 *	callback (function), [timeout (milliseconds)]
 * Returns: [ev_id (number)]
 */
static int
levq_add_pid (lua_State *L)
{
    lua_settop(L, 4);
    lua_pushnil(L);  /* EVENT_READ */
    lua_insert(L, 3);
    lua_pushboolean(L, 1);  /* EVENT_ONESHOT */
    lua_pushinteger(L, EVENT_NOTSOCK | EVENT_PID
#ifndef WIN32
     | EVENT_SIGNAL
#endif
    );  /* event_flags */
    return levq_add(L);
}

/*
 * Arguments: evq_udata, fd_udata, callback (function)
 * Returns: [ev_id (number)]
 */
static int
levq_add_winmsg (lua_State *L)
{
    lua_settop(L, 3);
    lua_pushnil(L);  /* EVENT_READ */
    lua_insert(L, 3);
    lua_pushnil(L);  /* timeout */
    lua_pushnil(L);  /* EVENT_ONESHOT */
    lua_pushinteger(L, EVENT_WINMSG);  /* event_flags */
    return levq_add(L);
}

/*
 * Arguments: evq_udata, path (string), callback (function),
 *	[modify (boolean)]
 * Returns: [ev_id (number)]
 */
static int
levq_add_dirwatch (lua_State *L)
{
    unsigned int filter = lua_toboolean(L, 4) ? EVQ_DIRWATCH_MODIFY : 0;

    lua_settop(L, 3);
    lua_pushnil(L);  /* events */
    lua_insert(L, 3);
    lua_pushnil(L);  /* timeout */
    lua_pushnil(L);  /* EVENT_ONESHOT */
    lua_pushinteger(L, EVENT_NOTSOCK | EVENT_DIRWATCH
     | (filter << EVENT_EOF_SHIFT_RES));  /* event_flags */
    return levq_add(L);
}

/*
 * Arguments: evq_udata, object (any), [metatable (table)],
 *	events (string: "r", "w", "rw"),
 *	callback (function), [timeout (milliseconds), one_shot (boolean)]
 * Returns: [ev_id (number)]
 */
static int
levq_add_object (lua_State *L)
{
    int tblidx;

    lua_settop(L, 7);
    if (lua_istable(L, 3))
	tblidx = 3;
    else {
	lua_pop(L, 1);
	lua_getmetatable(L, 2);
	tblidx = 7;
    }
    lua_pushinteger(L, EVENT_NOTSOCK | EVENT_TIMER
     | EVENT_OBJECT);  /* event_flags */

    lua_getfield(L, tblidx, SYS_OBJEVENT_TAG);
    lua_remove(L, tblidx);
    luaL_checktype(L, 8, LUA_TLIGHTUSERDATA);

    return levq_add(L);
}

/*
 * Arguments: evq_udata, signal (string),
 *	callback (function), [timeout (milliseconds), one_shot (boolean)]
 * Returns: [ev_id (number)]
 */
static int
levq_add_signal (lua_State *L)
{
    lua_settop(L, 5);
    lua_pushinteger(L, sig_flags[luaL_checkoption(L, 2, NULL, sig_names)]); 
    lua_replace(L, 2);
    lua_pushnil(L);  /* fd_udata */
    lua_insert(L, 2);
    lua_pushinteger(L, EVENT_NOTSOCK | EVENT_SIGNAL);  /* event_flags */
    return levq_add(L);
}

/*
 * Arguments: evq_udata, signal (string), ignore (boolean)
 * Returns: [evq_udata]
 */
static int
levq_ignore_signal (lua_State *L)
{
    struct event_queue *evq = checkudata(L, 1, EVQ_TYPENAME);
    const int signo = sig_flags[luaL_checkoption(L, 2, NULL, sig_names)];

    if (!evq_ignore_signal(evq, signo, lua_toboolean(L, 3))) {
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}


/*
 * Arguments: evq_udata, ev_id (number), [reuse_fd (boolean)]
 * Returns: [evq_udata]
 */
static int
levq_del (lua_State *L)
{
    int ev_id = lua_tointeger(L, 2);
    const int reuse_fd = lua_toboolean(L, 3);
    struct event *ev;
    int res = 0;

#undef ARG_LAST
#define ARG_LAST	1

    lua_settop(L, ARG_LAST);
    lua_getfenv(L, 1);
    lua_rawgeti(L, ARG_LAST+1, EVQ_FD_UDATA);
    lua_rawgeti(L, ARG_LAST+1, EVQ_CALLBACK);

    lua_rawgeti(L, ARG_LAST+1, ev_id);
    ev = lua_touserdata(L, -1);
    if (!ev) return 0;

    if (!event_deleted(ev)) {
	if (ev->flags & EVENT_TIMER) {
	    if (ev->flags & EVENT_OBJECT) {
		struct event_queue *evq = event_get_evq(ev);
		sys_get_objevent_t get_objevent;
		struct sys_vmthread *vmtd;
		struct event **evhead;

		lua_pushlightuserdata(L, (void *) ev_id);
		/* get the function */
		lua_pushvalue(L, -1);
		lua_rawget(L, ARG_LAST+2);
		get_objevent = (sys_get_objevent_t) lua_touserdata(L, -1);
		lua_pop(L, 1);
		/* clear the function */
		lua_pushnil(L);
		lua_rawset(L, ARG_LAST+2);

		lua_rawgeti(L, ARG_LAST+2, ev_id);
		evhead = (void *) get_objevent(L, &vmtd);

		if (vmtd != evq->vmtd) sys_vm2_enter(vmtd);
		if (ev == *evhead)
		    *evhead = ev->next_signal;
		else {
		    struct event *virt = *evhead;
		    while (virt->next_signal != ev)
			virt = virt->next_signal;
		    virt->next_signal = ev->next_signal;
		}
		if (vmtd != evq->vmtd) sys_vm2_leave(vmtd);

		lua_pop(L, 1);
	    }

	    evq_del_timer(ev);
	}
	else
	    res = evq_del(ev, reuse_fd);
    }
    /* if in ready_set (active) then delete ev_udata & co. later (after processed) */
    if (ev->flags & EVENT_ACTIVE)
	ev->flags |= EVENT_DELETE;
    else
	levq_del_udata(L, ARG_LAST+1, ev_id, lua_touserdata(L, 1));

    if (!res) {
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: evq_udata, ev_id (number), events (string: [-+] "r", "w", "rw")
 * Returns: [evq_udata]
 */
static int
levq_change (lua_State *L)
{
    int ev_id = lua_tointeger(L, 2);
    const char *evstr = luaL_checkstring(L, 3);
    struct event *ev;
    int change, flags;

#undef ARG_LAST
#define ARG_LAST	1

    lua_settop(L, ARG_LAST);
    lua_getfenv(L, 1);
    lua_rawgeti(L, ARG_LAST+1, ev_id);
    ev = lua_touserdata(L, -1);
    if (!ev || event_deleted(ev) || (ev->flags & EVENT_NOTSOCK))
	return 0;

    change = 0, flags = ev->flags;
    for (; *evstr; ++evstr) {
	if (*evstr == '+' || *evstr == '-')
	    change = (*evstr++ == '+') ? 1 : -1;
	else {
	    int rw = (*evstr == 'r') ? EVENT_READ : EVENT_WRITE;
	    switch (change) {
	    case 0:
		change = 1;
		flags &= ~(EVENT_READ | EVENT_WRITE);
	    case 1:
		flags |= rw;
		break;
	    default:
		flags &= ~rw;
	    }
	}
    }
    if (!evq_change(ev, flags)) {
	ev->flags = flags;
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: evq_udata, ev_id (number), [callback (function)]
 * Returns: evq_udata | callback (function)
 */
static int
levq_callback (lua_State *L)
{
    int ev_id = lua_tointeger(L, 2);

#undef ARG_LAST
#define ARG_LAST	3

    lua_settop(L, ARG_LAST);
    lua_getfenv(L, 1);
    lua_rawgeti(L, ARG_LAST+1, EVQ_CALLBACK);

    if (lua_isnone(L, 3))
	lua_rawgeti(L, ARG_LAST+2, ev_id);
    else {
	struct event *ev;

	lua_rawgeti(L, ARG_LAST+1, ev_id);
	ev = lua_touserdata(L, -1);
	ev->flags &= ~EVENT_CALLBACK;
	if (!lua_isnoneornil(L, 3)) {
	    ev->flags |= EVENT_CALLBACK;
	}

	lua_pushvalue(L, 3);
	lua_rawseti(L, ARG_LAST+2, ev_id);
	lua_settop(L, 1);
    }
    return 1;
}

/*
 * Arguments: evq_udata, ev_id (number), [timeout (milliseconds)]
 * Returns: [evq_udata]
 */
static int
levq_timeout (lua_State *L)
{
    int ev_id = lua_tointeger(L, 2);
    msec_t timeout = lua_isnoneornil(L, 3)
     ? TIMEOUT_INFINITE : (msec_t) lua_tonumber(L, 3);
    struct event *ev;

    lua_getfenv(L, 1);
    lua_rawgeti(L, -1, ev_id);
    ev = lua_touserdata(L, -1);
    if (!ev || event_deleted(ev) || (ev->flags & EVENT_WINMSG))
	return 0;

    if (!event_set_timeout(ev, timeout)) {
	lua_settop(L, 1);
	return 1;
    }
    return sys_seterror(L, 0);
}

/*
 * Arguments: evq_udata, [callback (function)]
 */
static int
levq_on_interrupt (lua_State *L)
{
    lua_settop(L, 2);
    lua_getfenv(L, 1);
    lua_pushvalue(L, 2);
    lua_rawseti(L, -2, EVQ_ON_INTR);
    return 0;
}

/*
 * Arguments: evq_udata, [timeout (milliseconds)]
 * Returns: [evq_udata]
 */
static int
levq_loop (lua_State *L)
{
    struct event_queue *evq = checkudata(L, 1, EVQ_TYPENAME);
    msec_t timeout = lua_isnoneornil(L, 2)
     ? TIMEOUT_INFINITE : (msec_t) lua_tonumber(L, 2);
    struct event *ev;

#undef ARG_LAST
#define ARG_LAST	1

    lua_settop(L, ARG_LAST);
    lua_getfenv(L, 1);
    lua_rawgeti(L, ARG_LAST+1, EVQ_FD_UDATA);
    lua_rawgeti(L, ARG_LAST+1, EVQ_CALLBACK);

    evq->flags = 0;

    while (!((evq->flags & EVQ_STOP) || evq_is_empty(evq))) {
	ev = evq_wait(evq, timeout);

	if (ev == EVQ_TIMEOUT)
	    break;
	if (ev == EVQ_FAILED)
	    return sys_seterror(L, 0);

	if (evq->object_events) {
	    struct event *objev = (struct event *) evq->object_events;
	    while (objev->next_ready)
		objev = objev->next_ready;
	    objev->next_ready = ev;
	    ev = (struct event *) evq->object_events;
	    evq->object_events = NULL;
	}

	if (ev == NULL) {
	    if (evq->flags & EVQ_INTR) {
		evq->flags &= ~EVQ_INTR;
		lua_rawgeti(L, ARG_LAST+1, EVQ_ON_INTR);
		if (lua_isfunction(L, -1)) {
		    lua_pushvalue(L, 1);  /* evq_udata */
		    lua_call(L, 1, 0);
		}
	    }
	    continue;
	}

	while (ev) {
	    const int ev_id = ev->ev_id;
	    const unsigned int ev_flags = ev->flags;

	    if (!(ev_flags & EVENT_DELETE)) {
		lua_rawgeti(L, ARG_LAST+3, ev_id);  /* cb_fun | thread */
		if (ev_flags & EVENT_CALLBACK) {
		    /* Arguments */
		    lua_pushvalue(L, 1);  /* evq_udata */
		    lua_pushinteger(L, ev_id);
		    lua_rawgeti(L, ARG_LAST+2, ev_id);  /* fd_udata */
		    lua_pushboolean(L, ev_flags & EVENT_READ_RES);
		    lua_pushboolean(L, ev_flags & EVENT_WRITE_RES);
		    if (ev_flags & EVENT_TIMEOUT_RES)
			lua_pushnumber(L, event_get_timeout(ev));
		    else
			lua_pushnil(L);
		    if (ev_flags & EVENT_EOF_MASK_RES)
			lua_pushinteger(L, (int) ev_flags >> EVENT_EOF_SHIFT_RES);
		    else
			lua_pushnil(L);

		    lua_call(L, 7, 0);
		}
		ev->flags &= EVENT_MASK;  /* clear is_active and result flags */
	    }
	    /* delete if called {evq_del | one_shot} */
	    if (event_deleted(ev)) {
		struct event *ev_next_ready = ev->next_ready;
		levq_del_udata(L, ARG_LAST+1, ev_id, evq);
		ev = ev_next_ready;  /* to prevent being GC'ed */
		continue;
	    } else {
		evq_post_call(ev, ev_flags);
	    }
	    ev = ev->next_ready;
	}
    }
    lua_settop(L, 1);
    return 1;
}

/*
 * Arguments: evq_udata
 * Returns: [evq_udata]
 */
static int
levq_interrupt (lua_State *L)
{
    struct event_queue *evq = checkudata(L, 1, EVQ_TYPENAME);

    evq->flags |= EVQ_INTR;
    lua_settop(L, evq_interrupt(evq) ? 0 : 1);
    return 1;
}

/*
 * Arguments: evq_udata
 */
static int
levq_stop (lua_State *L)
{
    struct event_queue *evq = checkudata(L, 1, EVQ_TYPENAME);

    evq->flags |= EVQ_STOP;
    return 0;
}

int
sys_trigger_objevent (sys_objevent_t *event, int flags)
{
    struct sys_vmthread *vmtd = sys_get_vmthread();
    struct event *ev = (struct event *) *event;
    struct event_queue *evq = event_get_evq(ev);
    struct event *ev_ready;
    msec_t now = 0L;
    const int deleted = (flags & SYS_EVDEL) ? EVENT_DELETE : 0;

    if (deleted) *event = NULL;

    if (vmtd != evq->vmtd) sys_vm2_enter(evq->vmtd);
    ev_ready = (struct event *) evq->object_events;

    do {
	const unsigned int ev_flags = ev->flags;
	int res = 0;

	if ((flags & SYS_EVREAD) && (ev_flags & EVENT_READ))
	    res = EVENT_READ_RES;
	if ((flags & SYS_EVWRITE) && (ev_flags & EVENT_WRITE))
	    res |= EVENT_WRITE_RES;
	if (flags & SYS_EVEOF)
	    res |= EVENT_EOF_RES;

	if (res || deleted) {
	    struct event_queue *cur_evq = event_get_evq(ev);

	    ev->flags |= (res ? res : deleted);
	    if (ev_flags & EVENT_ACTIVE)
		continue;

	    ev->flags |= EVENT_ACTIVE;
	    if (deleted || (ev_flags & EVENT_ONESHOT))
		evq_del_timer(ev);
	    else if (ev->tq) {
		if (now == 0L)
		    now = get_milliseconds();
		timeout_reset(ev, now);
	    }

	    /* Is the event from the same event_queue? */
	    if (evq != cur_evq) {
		evq->object_events = ev_ready;
		if (vmtd != evq->vmtd) sys_vm2_leave(evq->vmtd);

		evq_interrupt(evq);

		evq = cur_evq;
		if (vmtd != evq->vmtd) sys_vm2_enter(evq->vmtd);
		ev_ready = (struct event *) evq->object_events;
	    }

	    ev->next_ready = ev_ready;
	    ev_ready = ev;
	}
	ev = ev->next_signal;
    } while (ev);

    evq->object_events = ev_ready;
    if (vmtd != evq->vmtd) sys_vm2_leave(evq->vmtd);

    return evq_interrupt(evq);
}


static luaL_reg evq_meth[] = {
    {"add",		levq_add},
    {"add_timer",	levq_add_timer},
    {"add_pid",		levq_add_pid},
    {"add_winmsg",	levq_add_winmsg},
    {"add_dirwatch",	levq_add_dirwatch},
    {"add_object",	levq_add_object},
    {"add_signal",	levq_add_signal},
    {"ignore_signal",	levq_ignore_signal},
    {"del",		levq_del},
    {"change",		levq_change},
    {"timeout",		levq_timeout},
    {"callback",	levq_callback},
    {"on_interrupt",	levq_on_interrupt},
    {"loop",		levq_loop},
    {"interrupt",	levq_interrupt},
    {"stop",		levq_stop},
    {"__gc",		levq_done},
    {NULL, NULL}
};
