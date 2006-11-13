// vim:syntax=lpc
#include <debug.h>
inherit PSYC.Storage;

MMP.Uniform link_to;
object uni;
int linked = 0;
MMP.Utils.Queue queue = MMP.Utils.Queue();

void create(MMP.Uniform link_to_, object uni_) {
    link_to = link_to_;
    uni = uni_;
}

void link() {
    linked = 1;
    while (!queue->isEmpty()) {
	array a = queue->shift();
	array args = a[1..sizeof(a)-2]+a[sizeof(a)-1];
	a[0](@args);
    }
}

// Genereal Retrieve CallBack
void grcb(MMP.Packet p, function callback, string key, string mc, array args) {
    PSYC.Packet m = p->data;

    P3(("RemoteStorage", "grcb(%O, %O, %O, %O)\n", p, callback, key, args))

    if (key == m["_key"] && search(m->mc, "_notice"+mc) == 0) {
	call_out(callback, 0, key, m["_value"], @args);
    } else {
	// this is somewhat blurry since we consider every !_notice_retrieve
	// to be a failure/error
	call_out(callback, 0, key, UNDEFINED, @args);
    }
}

// Generæl Store CallBack
void gscb(MMP.Packet p, function callback, string key, string mc, array args) {
    PSYC.Packet m = p->data;

    if (key == m["_key"] && search(m->mc, "_notice"+mc) == 0) {
	call_out(callback, 0, 1, key, @args);
    } else {
	call_out(callback, 0, UNDEFINED, key, @args);
    }
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

void set(string key, mixed value, function callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ _set, key, value, callback, args, "_store" }));
	return;
    }

    _set(key, value, callback, args, "_store");
}

void set_lock(string key, mixed value, function callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ _set, key, value, callback, args, "_store_lock" }));
	return;
    }

    _set(key, value, callback, args, "_store_lock");
}

void set_unlock(string key, mixed value, function callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ _set, key, value, callback, args, "_store_unlock" }));
	return;
    }

    _set(key, value, callback, args, "_store_unlock");
}

void lock(string key, function callback, mixed ... args) {
    
    if (!linked) {
	queue->push(({ _lock, key, callback, args, "_lock" }));
	return;
    }

    _lock(key, callback, args, "_lock");
}

void unlock(string key, function callback, mixed ... args) {

    if (!linked) {
	queue->push(({ _lock, key, callback, args, "_unlock" }));
	return;
    }

    _lock(key, callback, args, "_unlock");
}

void _lock(string key, function callback, array(mixed) args, 
	   string mc) {
    uni->send_tagged(link_to, PSYC.Packet("_request"+mc, 0, ([
				"_key" : key
			    ])), gscb, callback, key, mc, args);
}

void _set(string key, mixed value, function callback,
	  array(mixed) args, string mc) {
    uni->send_tagged(link_to, PSYC.Packet("_request"+mc, 0, ([
				"_key" : key,
				"_value" : value,
			    ])), gscb, callback, key, mc, args);
}

void _get(string key, function callback, array(mixed) args, string mc) {
    uni->send_tagged(link_to, PSYC.Packet("_request"+mc, 0, ([
				"_key" : key
			    ])), grcb, callback, key, mc, args);
}

