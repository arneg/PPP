// vim:syntax=lpc
#include <new_assert.h>

inherit MMP.Utils.Debug;

mapping events = ([]);
object storage;

void create(mapping params) {
    object handling;
    ::create(params["debug"]);

    enforce(objectp(storage = params["storage"]));
    enforce(objectp(handling = params["handling"]));

    handling->register_handler("notify", this);
}

void add_notify(object handler, mapping e) {
    foreach (e; string name; int|mapping|array spec) {
	PSYC.AR o = PSYC.handler_parser(spec);
	string fname = "notify_"+name;

	if (!functionp(o->handler = `->(handler, fname))) {
	    do_throw(sprintf("%O does not offer %O function.\n", handler, fname));
	}

	if (has_index(events, name)) {
	    events[name] += ({ o });
	} else {
	    events[name] = ({ o });
	}
    }
}

void notify(string name, mixed ... args) {
    if (!has_index(events, name)) {
	debug("event_handling", 2, "Unused notify %O.\n", name);
	return;
    }

    array(PSYC.AR) ao = events[name];

    foreach (ao; ; PSYC.AR o) {
	if (!o->lvars && !o->wvars) {
	    MMP.Utils.invoke_later(o->handler, @args);
	} else {
	    PSYC.Storage.multifetch(this->storage, o->lvars && (multiset)o->lvars, o->wvars && (multiset)o->wvars, o->handler, 0, @args);
	}
    }
}

