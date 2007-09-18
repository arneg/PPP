// vim:syntax=lpc
#include <debug.h>

mapping events = ([]);
object storage;

void create(object handling, object _storage) {
    handling->register_handler("notify", this);
    storage = _storage;
}

void add_notify(object handler, mapping e) {
    foreach (e; string name; int|mapping|array spec) {
	PSYC.AR o = PSYC.handler_parser(spec);
	string fname = "notify_"+name;

	if (!functionp(o->handler = `->(handler, fname))) {
	    THROW(sprintf("%O does not offer %O function.\n", handler, fname));
	}

	P0(("NotifyHandling","%O\n", events))
	if (has_index(events, name)) {
	    events[name] += ({ o });
	} else {
	    events[name] = ({ o });
	}
    }
}

void notify(string name, mixed ... args) {
    if (!has_index(events, name)) {
	P0(("NotifyHandling", "Unused notify %O.\n", name))
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

