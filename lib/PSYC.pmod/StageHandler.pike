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

class AR(function handler, array(string) wvars, int async, array(string) lvars,
	 function check) {
    
    string _sprintf(int type) {
	if (type == 'O') {
	    return sprintf("AR(%O)", handler);
	}
    
	return UNDEFINED;
    }
}


void add(string mc, object handler, void|mapping|array(string) d) {
    int async = 0;
    array(string) wvars, lvars;
    function check;

    P3(("PSYC.StageHandler", "add(%O)\n", handler))

    if (!has_index(table, mc)) table[mc] = ({ }); 

    if (mappingp(d)) {
	if (has_index(d, "async")) {
	    async = d["async"];
	} 
	
	if (has_index(d, "wvars")) {
	    wvars = d["wvars"];
	}

	if (has_index(d, "lock")) {
	    lvars = d["lock"];
	}

	if (has_index(d, "check")) {
	    check = `->(handler, d["check"]);
	    if (!functionp(check)) {
		THROW(sprintf("No method %s is defined in %O.\n", d["check"], handler));
	    }
	}

    } else {
	wvars = d;
    }

#if DEBUG
    if (arrayp(d) && !sizeof(d)) {
	THROW(sprintf("Method %s in %O with empty set of wanted vars!!\n", prefix+mc, handler));
    }
#endif

    function cb = `->(handler, prefix + mc);
    if (!functionp(cb)) {
	THROW(sprintf("No method %s defined in %O.\n", prefix+mc, handler));
    }

    table[mc] += ({ AR(cb, wvars, async, lvars, check) });

    P3(("StageHandler", "table: %O\n", table))
}

void handle(MMP.Packet p, mapping _m) {

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
    progress(liste, p, _m);
}


void fetched(string key, mixed value, MMP.Utils.Queue stack, MMP.Packet p,
	     mapping _m, multiset(string) wvars) {
    PT(("StageHandler", "fetched(%O, %O, %O, %O, %O)\n", key, value, stack,
	p, wvars))

    requested[p][key] = value;

    if (wvars[key]) while(--wvars[key]);

    if (!sizeof(wvars)) {
	call_handler(stack, p, m_delete(requested, p), _m);
    }
}

void progress(MMP.Utils.Queue stack, MMP.Packet p, mapping _m) {
    PT(("StageHandler", "progressing %O.\n", stack))

    if (stack->isEmpty()) {
	call_out(go_on, 0, p, _m);

	return;
    }
    
    AR o = stack->shift_();

    if (o->check && !o->check(p, _m)) {
	PT(("StageHandler", "%O->check() returned Null.\n", o))
	stack->shift();
	call_out(progress, 0, stack, p, _m);
	return;
    }

    array wvars = o->wvars;
    array lvars = o->lvars;

    if (wvars || lvars) {
	multiset rvars;
	if (wvars && lvars) {
	    rvars = (multiset)wvars;
	    rvars += (multiset)lvars;
	} else {
	    rvars = (multiset)(wvars || lvars);
	}

	requested[p] = ([ ]);

	if (wvars) foreach(wvars;; string key) {
	    storage->get(key, fetched, stack, p, _m, rvars);
	}

	if (lvars) foreach(lvars;; string key) {
	    storage->get_lock(key, fetched, stack, p, _m, rvars);
	}

    } else {
	call_out(call_handler, 0, stack, p, ([]), _m);	
    }

}

void call_handler(MMP.Utils.Queue stack, MMP.Packet p, mapping _v, mapping _m) {
    int in_progress = 1;

    AR o = stack->shift();
    PT(("StageHandler", "Calling %O for %O with misc: %O.\n", o->handler, p, _m))
    if (o->async) {
	void callback(int i) {
	    if (in_progress) {
		throw(({ "callback called, but handler didn't yet return. "
			 "use call_out, stupid!", backtrace() }));
	    }

	    if (i == PSYC.Handler.GOON) {
		progress(stack, p, _m);
	    } else {
		stop(p, _m);
	    }
	};

	P3(("PSYC.StageHandler", "attempting to call %O.\n", o->handler))

	o->handler(p, _v, _m, callback);
	in_progress = 0;
    } else {
	if (o->handler(p, _v, _m) == PSYC.Handler.GOON) {
	    progress(stack, p, _m);
	} else {
	    stop(p, _m);
	}
    }

}
