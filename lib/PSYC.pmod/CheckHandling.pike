// vim:syntax=lpc
#include <debug.h>

mapping checks = ([]);
object storage;

void create(object handling, object storage) {
    handling->register_handler("check", this);
    this_program::storage = storage;
}

void add_check(object handler, mapping e) {
    foreach (e; string name; int|mapping|array spec) {
	PSYC.AR o = PSYC.handler_parser(spec);
	string fname = "check_"+name;

	if (!functionp(o->handler = `->(handler, fname))) {
	    THROW(sprintf("%O does not offer %O function.\n", handler, fname));
	}

	P0(("NotifyHandling","%O\n", checks))
	if (has_index(checks, name)) {
	    checks[name] += ({ o });
	} else {
	    checks[name] = ({ o });
	}
    }
}

void check(string name, function cb, mixed ... args) {
    if (!has_index(checks, name)) {
	P0(("CheckHandling", "Unregistered check %O defaults to FALSE.\n", name))
	MMP.Utils.invoke_later(cb, 0);
	return;
    }

    // TODO: think about deleted checks. is copying smarty?
    array(PSYC.AR) ao = checks[name];

    int i = 0;

    void callback() {
	if (!has_index(ao, i)) {
	    MMP.Utils.invoke_later(cb, 1);
	    return;
	}

	PSYC.AR o = ao[i];

	void _cb(int ret) {
	    if (ret) {
		i++;	
		MMP.Utils.invoke_later(callback);
	    } else {
		MMP.Utils.invoke_later(cb, 0);
	    }
	};

	if (!o->lvars && !o->wvars) {
	    MMP.Utils.invoke_later(o->handler, _cb, @args);
	} else {
	    PSYC.Storage.multifetch(this->storage, o->lvars && (multiset)o->lvars, o->wvars && (multiset)o->wvars, o->handler, 0, _cb, @args);
	}
    };

    callback();
}

