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
	_set(@(queue->shift()));		
    }
}

// Genereal Retrieve CallBack
void grcb(MMP.Packet p, function callback, string key, array args) {
    PSYC.Packet m = p->data;

    P3(("RemoteStorage", "grcb(%O, %O, %O, %O)\n", p, callback, key, args))

    if (key == m["_key"] && search(m->mc, "_notice_retrieve") == 0) {
	call_out(callback, 0, key, m["_value"], @args);
    } else {
	// this is somewhat blurry since we consider every !_notice_retrieve
	// to be a failure/error
	call_out(callback, 0, key, UNDEFINED, @args);
    }
}

// Generæl Store CallBack
void gscb(MMP.Packet p, function callback, string key, array args) {
    PSYC.Packet m = p->data;

    if (key == m["_key"] && search(m->mc, "_notice_store") == 0) {
	call_out(callback, 0, 1, key, @args);
    } else {
	call_out(callback, 0, UNDEFINED, key, @args);
    }
}

void get(string key, function callback, mixed ... args) {

    if (!linked) {
	P0(("RemoteStorage", "%O: requested variable %s in an unlinked client.\n", this, key))
	mixed value = UNDEFINED;
	// this is a HACK. it would be easier maybe to add the handler
	// which are not working for an unlinked client later on...
	switch(key) {
	case "_friends":
	case "_subscriptions":
	    value = ([]);
	    break;
	}

	call_out(callback, 0, key, value, @args);
	return;
    }


    uni->send_tagged(link_to, PSYC.Packet("_request_retrieve", 0, ([
				"_key" : key
			    ])), grcb, callback, key, args);
}

void set(string key, string|array(string) value, function callback, 
	 mixed ... args) {

    if (!linked) {
	queue->push(({ key, value, callback, args }));
	return;
    }
    _set(key, value, callback, args);
}

void _set(string key, string|array(string) value, function callback,
	  array(mixed) args) {
    uni->send_tagged(link_to, PSYC.Packet("_request_store", 0, ([
				"_key" : key,
				"_value" : value,
			    ])), gscb, callback, key, args);
}
