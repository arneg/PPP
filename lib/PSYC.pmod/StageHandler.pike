// vim:syntax=lpc
#include <debug.h>

PSYC.Storage storage;
mapping table = ([]);
mapping requested = ([]);
function go_on, stop, error;
string prefix;

void create(string foo, function go_on_, function stop_, function error_, PSYC.Storage s) {
    prefix = foo;

    go_on = go_on_;
    stop = stop_;
    error = error_;

    storage = s;
}

class AR(function handler, array(string) wvars, int async) {
    
    string _sprintf(int type) {
	if (type == 'O') {
	    return sprintf("AR(%O)", handler);
	}
    
	return UNDEFINED;
    }
}


void add(string mc, object handler, void|mapping|array(string) d) {
    int async = 0;
    array(string) wvars;

    P3(("PSYC.StageHandler", "add(%O)\n", handler))

    if (!has_index(table, mc)) table[mc] = ({ }); 

    if (mappingp(d)) {
	if (has_index(d, "async")) {
	    async = d["async"];
	} 
	
	if (has_index(d, "wvars")) {
	    wvars = d["wvars"];
	}

    } else {
	wvars = d;
    }

    function cb = `->(handler, prefix + mc);
    if (!functionp(cb)) {
	THROW(sprintf("No method %s defined in %O.\n", prefix+mc, handler));
    }

    table[mc] += ({ AR(cb, wvars, async) });

    P3(("StageHandler", "table: %O\n", table))
}

void handle(MMP.Packet p) {

    P3(("StageHandler", "%s:handle(%s)\n", prefix, p->data->mc))

    array(string) l = p->data->mc / "_";
    MMP.Utils.Queue liste = MMP.Utils.Queue(); 

    for (int i = sizeof(l)-1; i >= 0; i--) {
	string temp = l[0..i] * "_";
	if (has_index(table, temp)) {
	    foreach(table[temp];; object a) {
		liste->push(a);
	    }
	}
    }

    P3(("StageHandler", "stack for %s is %O\n", p->data->mc, (array)liste))
    progress(liste, p);
}


void fetched(string key, string value, MMP.Utils.Queue stack, MMP.Packet p,
	     multiset(string) wvars) {
    P3(("StageHandler", "fetched(%O, %O, %O, %O, %O)\n", key, value, stack,
	p, wvars))

    requested[p][key] = value;

    if (wvars[key]) while(--wvars[key]);

    if (!sizeof(wvars)) {
	call_handler(stack, p, m_delete(requested, p));
    }
}

void progress(MMP.Utils.Queue stack, MMP.Packet p) {
    if (stack->isEmpty()) {
	call_out(go_on, 0, p);

	return;
    }

    if (stack->shift_()->wvars) {
	multiset wvars = (multiset)stack->shift_()->wvars;

	requested[p] = ([ ]);
	foreach(stack->shift_()->wvars;; string key) {
	    storage->get(key, fetched, stack, p, wvars);
	}
    } else {
	call_out(call_handler, 0, stack, p, ([]));	
    }

}

void call_handler(MMP.Utils.Queue stack, MMP.Packet p, mapping _v) {
    int in_progress = 1;

    AR o = stack->shift();
    if (o->async) {
	void callback(int i) {
	    if (in_progress) {
		throw(({ "callback called, but handler didn't yet return. "
			 "use call_out, stupid!", backtrace() }));
	    }

	    if (i == PSYC.Handler.GOON) {
		progress(stack, p);
	    } else {
		stop(p);
	    }
	};

	P3(("PSYC.StageHandler", "attempting to call %O.\n", o->handler))

	o->handler(p, _v, callback);
	in_progress = 0;
    } else {
	if (o->handler(p, _v) == PSYC.Handler.GOON) {
	    progress(stack, p);
	} else {
	    stop(p);
	}
    }

}
