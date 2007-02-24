// vim:syntax=lpc
inherit PSYC.Handler.Base;
#include <debug.h>

//! An Implementation of PSYC storage. Handles @expr{get@}, @expr{set@} and
//! @expr{lock@} operations, namely:
//! @pre{
//! _request_store[_lock|_unlock]
//! _request_retrieve[_lock|_unlock]
//! _request_lock
//! _request_unlock@}
//! Needs a storage object to work on. Also, only incoming packets from linked
//! clients are accepted ("itsme" has to be set in the misc mapping as done by
//! @[Handler.Link]).

object storage;

constant _ = ([ 
    "postfilter" : ([ 
	"_request_store" : 0,
	"_request_store_lock" : 0,
	"_request_store_unlock" : 0,
	"_request_retrieve" : 0,
	"_request_retrieve_lock" : 0,
	"_request_retrieve_unlock" : 0,
	"_request_lock" : 0,
	"_request_unlock" : 0,
	"_request_save" : 0,
    ]),
]);

int postfilter_request_store_lock(MMP.Packet p, mapping _v, mapping _m) {

    return _set(p, _v, _m, "_store_lock", storage->set_lock);
}

int postfilter_request_store_unlock(MMP.Packet p, mapping _v, mapping _m) {
    return _set(p, _v, _m, "_store_unlock", storage->set_unlock);
}

int postfilter_request_store(MMP.Packet p, mapping _v, mapping _m) {
    return _set(p, _v, _m, "_store", storage->set);
}

int _set(MMP.Packet p, mapping _v, mapping _m, string mc, function set) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure"+mc));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key") || !has_index(m->vars, "_value")) {
	sendmsg(p["_source"], m->reply("_error"+mc));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];
    mixed value = m->vars["_value"];

    void callback(int error, string key, MMP.Uniform target, PSYC.Packet m) {
	PT(("Handler.Storage", "callback(%O, %O, %O)\n", error, target, m))
	if (error) {
	    sendmsg(target, m->reply("_error"+mc,
					  ([ "_key" : key ])));
	} else {
	    sendmsg(target, m->reply("_notice"+mc,
				      ([ "_key" : key ])));
	}
    };

    set(key, value, callback, p["_source"], m);
    return PSYC.Handler.STOP;
}

int postfilter_request_retrieve_lock(MMP.Packet p, mapping _v, mapping _m) {
    return _get(p, _v, _m, "_retrieve_lock", storage->get_lock);
}


int postfilter_request_retrieve_unlock(MMP.Packet p, mapping _v, mapping _m) {
    return _get(p, _v, _m, "_retrieve_unlock", storage->get_unlock);
}

int postfilter_request_retrieve(MMP.Packet p, mapping _v, mapping _m) {
    return _get(p, _v, _m, "_retrieve", storage->get);
}

int _get(MMP.Packet p, mapping _v, mapping _m, string mc, function get) {
    PSYC.Packet m = p->data;
    
    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure"+mc));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key")) {
	sendmsg(p["_source"], m->reply("_error"+mc));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(string key, string value, MMP.Uniform target, 
		  PSYC.Packet m) {
	if (value != UNDEFINED) {
	    sendmsg(target, m->reply("_notice"+mc,
					  ([ "_key" : key,
					     "_value" : value ])));
	} else {
	    sendmsg(target, m->reply("_error"+mc,
					  ([ "_key" : key ])));
	}
    };

    get(key, callback, p["_source"], m);
    return PSYC.Handler.STOP;
}

int postfilter_request_lock(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure_lock"));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key")) {
	sendmsg(p["_source"], m->reply("_error_lock"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(int error, MMP.Uniform target, PSYC.Packet m) {
	if (error) {
	    sendmsg(target, m->reply("_error_lock", ([ "_key" : key ])));
	} else {
	    sendmsg(target, m->reply("_notice_lock", ([ "_key" : key ])));
	}
    };

    storage->lock(key, callback, p->source(), m);
    return PSYC.Handler.STOP;
}

int postfilter_request_unlock(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure_unlock"));
	return PSYC.Handler.STOP;
    }

    if (!has_index(m->vars, "_key")) {
	sendmsg(p["_source"], m->reply("_error_unlock"));
	return PSYC.Handler.STOP;
    }

    string key = m->vars["_key"];

    void callback(int error, MMP.Uniform target, PSYC.Packet m) {
	if (error) {
	    sendmsg(target, m->reply("_error_unlock", ([ "_key" : key ])));
	} else {
	    sendmsg(target, m->reply("_notice_unlock", ([ "_key" : key ])));
	}
    };

    storage->unlock(key, callback, p->source(), m);
    return PSYC.Handler.STOP;
}

int postfilter_request_save(MMP.Packet p, mapping _v, mapping _m) {
    PSYC.Packet m = p->data;

    if (!_m["itsme"]) {
	sendmsg(p->source(), m->reply("_failure_save"));
	return PSYC.Handler.STOP;
    }

    if (catch { storage->save(); }) {
	sendmsg(p->source(), m->reply("_error_save"));
    } else {
	sendmsg(p->source(), m->reply("_notice_save"));
    }
}

//! @param s
//! 	The storage object.
//! @seealso
//! 	@[PSYC.HandlingTools()->create()] for documentation of the other
//! 	arguments.
void create(object uni, function f, MMP.Uniform u, object s) {
    storage = s;
    ::create(uni, f, u);
}

