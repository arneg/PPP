// vim:syntax=lpc
#include <debug.h>
inherit PSYC.HandlingTools;
inherit PSTC.Storage.Base;
import .module;

//! A storage class that uses storage from a (possibly) remote entity using PSYC.
//! @seealso
//! 	@[Volatile] for method documentation, as this class is API compatible
//! 	to it (except for the methods explicitely documented here).

MMP.Uniform link_to;
int linked = 0;
MMP.Utils.Queue queue = MMP.Utils.Queue();

//! @param parent
//! 	The entity we provide storage for. @expr{parent@} needs to link to the
//!	 remote entity. As soon as the link is successful, @[link()] has to be called.
//! @param sendmmp
//! 	Usually @expr{parent->sendmmp@}.
//! @param u
//! 	The parent's uniform.
//! @param link_to_
//! 	The uniform of the entity to 'link' to.
void create(object parent, function sendmmp, MMP.Uniform u, MMP.Uniform link_to_) {
    link_to = link_to_;
    ::create(parent, sendmmp, u);
}

void save() {
    if (!linked) {
	queue->push(({ _save }));
	return;
    }
    
    call_out(_save, 0);
}

void _save() {
    P2(("PSYC.Storage.Remote", "Sending _request_save.\n"))
    send_tagged(link_to, PSYC.Packet("_request_save"), stopper);
}

//! Callback to signal that the @expr{parent@} has linked to the entity
//! providing the storage for us.
//!
//! Until this is invoked, all requests are queued in a private queue.
void link() {
    linked = 1;
    while (!queue->isEmpty()) {
	array a = queue->shift();
	a[0](@a[1..]);
    }
}

int stopper(mixed ... args) {
    return PSYC.Handler.STOP;
}

// Genereal Retrieve CallBack
int grcb(MMP.Packet p, function callback, string key, string mc, array args) {
    PSYC.Packet m = p->data;

    P3(("Storage.Remote", "grcb(%O, %O, %O, %O, %O)\n", p, callback, key, mc, args))

    if (key == m["_key"] && search(m->mc, "_notice"+mc) == 0) {
	call_out(callback, 0, OK, key, m["_value"], @args);
    } else {
	// this is somewhat blurry since we consider every !_notice_retrieve
	// to be a failure/error
	call_out(callback, 0, ERROR, key, UNDEFINED, @args);
    }

    return PSYC.Handler.STOP;
}

// General Store CallBack
int gscb(MMP.Packet p, function callback, string key, string mc, array args) {
    PSYC.Packet m = p->data;

    P3(("Storage.Remote", "gscb(%O, %O, %O, %O, %O)\n", p, callback, key, mc, args))

    if (key == m["_key"] && search(m->mc, "_notice"+mc) == 0) {
	call_out(callback, 0, OK, key, @args);
    } else {
	call_out(callback, 0, ERROR, key, @args);
    }

    return PSYC.Handler.STOP;
}

void get(string key, function callback, mixed ... args) {

    if (!linked) {
	queue->push(({ _get, key, callback, args, "_retrieve" }));
	return;
    }

    _get(key, callback, args, "_retrieve");
}

void get_lock(string key, function callback, mixed ... args) {

    if (!linked) {
	queue->push(({ _get, key, callback, args, "_retrieve_lock" }));
	return;
    }

    _get(key, callback, args, "_retrieve_lock");
}

void get_unlock(string key, function callback, mixed ... args) {

    if (!linked) {
	queue->push(({ _get, key, callback, args, "_retrieve_unlock" }));
	return;
    }

    _get(key, callback, args, "_retrieve_unlock");
}

void set(string key, mixed value, function|void callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ _set, key, value, callback, args, "_store" }));
	return;
    }

    _set(key, value, callback, args, "_store");
}

void set_lock(string key, mixed value, function|void callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ _set, key, value, callback, args, "_store_lock" }));
	return;
    }

    _set(key, value, callback, args, "_store_lock");
}

void set_unlock(string key, mixed value, function|void callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ _set, key, value, callback, args, "_store_unlock" }));
	return;
    }

    _set(key, value, callback, args, "_store_unlock");
}

void lock(string key, function|void callback, mixed ... args) {
    
    if (!linked) {
	queue->push(({ _lock, key, callback, args, "_lock" }));
	return;
    }

    _lock(key, callback, args, "_lock");
}

void unlock(string key, function|void callback, mixed ... args) {

    if (!linked) {
	queue->push(({ _lock, key, callback, args, "_unlock" }));
	return;
    }

    _lock(key, callback, args, "_unlock");
}

void _lock(string key, function callback, array(mixed) args, 
	   string mc) {
    PSYC.Packet request = PSYC.Packet("_request"+mc,
				      ([
				    "_key" : key
					]));

    if (callback) {
	send_tagged(link_to, request, gscb, callback, key, mc, args);
    } else { // maybe we should still send a tagged message.. but have dummy callback. not sure.
	send_tagged(link_to, request, stopper);
    }
}

void _set(string key, mixed value, function callback,
	  array(mixed) args, string mc) {
    PSYC.Packet request = PSYC.Packet("_request"+mc, ([
				"_key" : key,
				"_value" : value,
			    ]));

    if (callback) {
	send_tagged(link_to, request, gscb, callback, key, mc, args);
    } else {
	send_tagged(link_to, request, stopper);
    }
}

void _get(string key, function callback, array(mixed) args, string mc) {
    PSYC.Packet request = PSYC.Packet("_request"+mc, ([
				"_key" : key
			    ]));
    if (callback) {
	send_tagged(link_to, request, grcb, callback, key, mc, args);
    } else {
	// what is that for??
	send_tagged(link_to, request, stopper);
    }
}

